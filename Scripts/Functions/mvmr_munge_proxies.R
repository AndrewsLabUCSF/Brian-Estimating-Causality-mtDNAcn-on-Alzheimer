mvmr_munge_proxies <- function(LDLink_file, exposure){
  LDLink_file_path <- LDLink_file
  proxy_snps <- read_tsv(LDLink_file_path, skip = 1, col_names = F) %>%
    dplyr::rename(id = X1, func = X2, proxy_snp = X3, coord = X4, alleles = X5, maf = X6, 
           distance = X7, dprime = X8, rsq = X9, correlated_alleles = X10, FORGEdb = X11, RegulomeDB = X12) %>%
    separate(coord, c('chr', 'pos'), sep = ":") %>%
    mutate(snp = ifelse(id == 1, proxy_snp, NA), 
           chr = str_replace(chr, 'chr', ""), 
           chr = as.numeric(chr), 
           pos = as.numeric(pos)) %>%
    fill(snp, .direction = 'down') %>%
    relocate(snp, .before = proxy_snp) %>%
    dplyr::select(-id, -func, -FORGEdb, -RegulomeDB) %>%
    filter(rsq >= 0.8)
  
  # Rename columns 
  outcome <- exposure %>% 
    magrittr::set_colnames(str_replace_all(colnames(.), "exposure", "outcome"))
  
  # Munge proxy snp and outcome data
  proxy_outcome <- left_join(
    proxy_snps, outcome, by = c("proxy_snp" = "SNP")
  ) %>%
    separate(correlated_alleles, c("target_a1.outcome", "proxy_a1.outcome", 
                                   "target_a2.outcome", "proxy_a2.outcome"), sep = ",|=") %>%
    filter(!is.na(chr.outcome)) %>%
    arrange(snp, -rsq, abs(distance)) %>%
    group_by(snp) %>%
    dplyr::slice(1) %>%
    ungroup() %>%
    mutate(
      proxy.outcome = TRUE,
      target_snp.outcome = snp,
      proxy_snp.outcome = proxy_snp, 
    ) %>% 
    mutate(
      new_effect_allele.outcome = case_when(
        proxy_a1.outcome == effect_allele.outcome & proxy_a2.outcome == other_allele.outcome ~ target_a1.outcome,
        proxy_a2.outcome == effect_allele.outcome & proxy_a1.outcome == other_allele.outcome ~ target_a2.outcome,
        TRUE ~ NA_character_
      ), 
      new_other_allele.outcome = case_when(
        proxy_a1.outcome == effect_allele.outcome & proxy_a2.outcome == other_allele.outcome ~ target_a2.outcome,
        proxy_a2.outcome == effect_allele.outcome & proxy_a1.outcome == other_allele.outcome ~ target_a1.outcome,
        TRUE ~ NA_character_
      ), 
      effect_allele.outcome = new_effect_allele.outcome, 
      other_allele.outcome = new_other_allele.outcome
    ) %>%
    dplyr::select(-proxy_snp, -chr, -pos, -alleles, -maf, -distance, -rsq, -dprime,  
                  -new_effect_allele.outcome, -new_other_allele.outcome) %>%
    relocate(target_a1.outcome, proxy_a1.outcome, target_a2.outcome, proxy_a2.outcome, .after = proxy_snp.outcome) %>%
    dplyr::rename(SNP = snp) #%>%
    #relocate(SNP, .after = samplesize.outcome)
  
  # Merge outcome and proxy outcomes
  out <- proxy_outcome %>%
    arrange(chr.outcome, pos.outcome) %>%
    magrittr::set_colnames(str_replace_all(colnames(.), "outcome", "exposure")) 
  
  out
  
}



