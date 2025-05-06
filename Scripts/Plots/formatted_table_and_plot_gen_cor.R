#! bin/bash
library(tidyr)
library(readr)
library(dplyr)
library(plyr)
library(stringr)

args = commandArgs(trailingOnly = TRUE) # Set arguments from the command line
input = "/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/genetic_correlations/Hagg_mtDNAcn.sumstats.gz_Longchamps_mtDNAcn.sumstats.gz_Gupta_mtDNAcn.sumstats.gz_Chong_mtDNAcn.sums_ldsc.log"

dat <- read_lines(input)

#Create a dataframe with LD information
g_cov <- dat[which(str_detect(dat, "g_cov Z"))] %>%
  str_split(., pattern = "\\s+") %>%
  map(., as_tibble) %>% 
  do.call(bind_rows, .) %>% 
  filter(value != "g_cov", value != "Z:") %>% 
  dplyr::rename(g_cov_Z = value)

traits <- dat[which(str_detect(dat, "Results for genetic covariance between:"))] %>% 
  map_df(., as_tibble) %>% 
  separate(value, c("prefix", "traits"), sep= ": ") %>% 
  separate(traits, c("trait_1", "trait_2"), sep= " and ") %>% 
  mutate(
    trait_1 = str_replace(trait_1, ".sumstats.gz", ""), 
    trait_2 = str_replace(trait_2, ".sumstats.gz", "")
  ) %>% 
  select(-prefix) 

p_val <- dat[which(str_detect(dat, "g_cov P-value"))] %>% 
  map_df(., as_tibble) %>% 
  separate(value, c("P", "P-value"), sep= ": ") %>% 
  select(-P)

ZtimesZ <- dat[which(str_detect(dat, "Mean Z*Z"))] %>% 
  map_df(., as_tibble) %>% 
  separate(value, c("Z", "Z*Z"), sep= ": ") %>% 
  select(-Z)

Cross_trait_intercept <- dat[which(str_detect(dat, "Cross trait Intercept"))] %>% 
  map_df(., as_tibble) %>% 
  separate(value, c("cross_trait", "cross_trait_intercept"), sep= ": ") %>% 
  separate(cross_trait_intercept, c("cross_trait interecept", "standard_error_cross_trait_intercept"), sep = " ") %>% 
  mutate(standard_error_cross_trait_intercept = gsub("\\(|\\)", "", standard_error_cross_trait_intercept)) %>% 
  select(-cross_trait)

observed_scale_genetic_covariance <- dat[which(str_detect(dat, "Total Observed Scale Genetic Covariance"))] %>% 
  map_df(., as_tibble) %>% 
  separate(value, c("ignore", "Total_Observed_Scale_Genetic_Covariance"), sep= ": ") %>% 
  separate(Total_Observed_Scale_Genetic_Covariance, c("Total Observed Scale Genetic Covariance", "standard_error_gen_covariance"), sep = " ") %>% 
  mutate(standard_error_gen_covariance = gsub("\\(|\\)", "", standard_error_gen_covariance)) %>% 
  select(-ignore)

df <- bind_cols(traits, g_cov, p_val, ZtimesZ, Cross_trait_intercept, observed_scale_genetic_covariance)


#Create genetic correlation dataframe
genetic_cor <- dat[which(str_detect(dat, "Genetic Correlation between"))] %>% 
  map_df(., as_tibble) %>% 
  separate(value, c("traits", "gen_cor"), sep= ": ") %>% 
  separate(traits, c("trait__1", "trait_2"), sep = " and ") %>%
  separate(trait__1, c("ignore", "trait_1"), sep = " between ") %>% 
  separate(gen_cor, c("genetic_cor", "standard_error"), sep = " ") %>% 
  mutate(standard_error = gsub("\\(|\\)", "", standard_error)) %>% 
  select(-ignore) 

genetic_cor_df <- bind_cols(genetic_cor, p_val)

write_tsv(genetic_cor_df, '/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/genetic_correlations/genetic_cor_df.tsv')

#Edit genetic correlation dataframe
genetic_cor_df <- read_tsv('/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/genetic_correlations/genetic_cor_df.tsv') %>% 
  janitor::clean_names() %>% 
  dplyr::rename("Pearson_correlation" = genetic_cor) %>% 
  mutate(trait_1 = case_when(
    trait_1 == "Hagg_mtDNAcn" ~ "Hagg",
    trait_1 == "Longchamps_mtDNAcn" ~ "Longchamps",
    trait_1 == "Chong_mtDNAcn" ~ "Chong",
    trait_1 == "Gupta_mtDNAcn" ~ "Gupta",
    trait_1 == "AD_Kunkle" ~ "AD",
    trait_1 == "AD_Bellenguez" ~ "AD/dementia",
    trait_1 == "PD_Nalls" ~ "PD",
    TRUE ~ trait_1
  ),
  trait_2 = case_when(
    trait_2 == "Hagg_mtDNAcn" ~ "Hagg",
    trait_2 == "Longchamps_mtDNAcn" ~ "Longchamps",
    trait_2 == "Chong_mtDNAcn" ~ "Chong",
    trait_2 == "Gupta_mtDNAcn" ~ "Gupta",
    trait_2 == "AD_Kunkle" ~ "AD",
    trait_2 == "AD_Bellenguez" ~ "AD/dementia",
    trait_2 == "PD_Nalls" ~ "PD",
    TRUE ~ trait_2
  )
  ) 

traits <- c("Hagg", "Longchamps", "Chong", "Gupta", "PD", "AD", "AD/dementia")
genetic_cor_dfp <- expand_grid(trait_1 = traits,
                               trait_2 = traits) %>% 
  left_join(genetic_cor_df) %>% mutate(rg.p_cat= case_when(
    p_value <= 0.05 ~ 1,
    p_value <= 0.1 ~ 0.75,
    p_value <= 0.5 ~ 0.5,
    p_value <= 1 ~ 0.25,
   # TRUE ~ NA_real_,
  )) 
the_palette = "RdBu"

## Specifying the desired order of traits
traits_order <- c("Hagg", "Longchamps", "Gupta", "Chong", "AD", "AD/dementia", "PD")

## Convert trait_1 and trait_2 to factors with custom levels
genetic_cor_dfp$trait_1 <- factor(genetic_cor_dfp$trait_1, levels = traits_order)
genetic_cor_dfp$trait_2 <- factor(genetic_cor_dfp$trait_2, levels = traits_order)

#Plot 
genetic_cor_plot <- ggplot(genetic_cor_dfp, aes(x= trait_1, y= trait_2, fill=Pearson_correlation, height=rg.p_cat, width=rg.p_cat)) +
  geom_tile() +
  scale_fill_distiller(palette = rev(the_palette), limits = c(-1,1)) +
  theme_classic() +
  geom_vline(xintercept=seq(0.5, 43.5, 1),color="grey90") +
  geom_hline(yintercept=seq(0.5, 11.5, 1),color="grey90") +
  theme(legend.position = 'bottom',
        axis.text.x = element_text(angle = 35, hjust = 1),
        aspect.ratio=1, 
        axis.title.x = element_blank(),
        axis.title.y = element_blank(), 
        text = element_text(size=8))

genetic_cor_plot

#ggsave("/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/results/Aadrita_results/plots/formatted_genetic_cor_plot.png", genetic_cor_plot, units = "in", width = 6, height = 6, dpi = 300) 


