library(readr)
library(tidyverse) # Data wrangling 
library (usethis)
library(devtools)
library(ggman)
library(TwoSampleMR) # MR 
library(R.utils) #To read in Gz data? 
library(RadialMR) # Radial MR sensitivity analysis 
library(LDlinkR) # LD and proxy snps
library(lhcMR)
library(janitor)
library(parallel)
library(ieugwasr)

# Define column types for summary statistics GWAS
coltypes = cols(
  ID = col_character(),
  CHROM = col_double(),
  POS = col_double(),
  REF = col_character(),
  ALT = col_character(),
  AF = col_double(),
  TRAIT = col_character(),
  BETA = col_double(),
  SE = col_double(),
  Z = col_double(),
  P = col_double(),
  N = col_double(),
  OR = col_double(),
  OR_L95 = col_double(),
  OR_U95 = col_double(),
  DIR = col_character(),
  G1000_ID = col_character(),
  G1000_VARIANT = col_character(),
  DBSNP_ID = col_character(),
  DBSNP_VARIANT = col_character(),
  OLD_ID = col_character(),
  OLD_VARIANT = col_character()
)


## Step 1: Importing Exposure and Outcome Data
LD.filepath = "/wynton/group/andrews/data/LDscores_filtered.csv" # LD scores
rho.filepath = "/wynton/group/andrews/data/LD_GM2_2prm.csv" # local/SNP-specific LD scores
ld = "/wynton/group/andrews/data/eur_w_ld_chr/"
hm3 = "/wynton/group/andrews/data/w_hm3.snplist"
b_file = '/wynton/group/andrews/data/reference_panels/EUR_All_Chr'
plink_path = '/wynton/home/andrews/achatterjee/plink'

exposure_path = "/wynton/group/andrews/data/summary_stats/results/Longchamps2021mtdnacn.chrall.CPRA_b37.tsv.gz"
exposure_ss_Longchamps <- read_tsv(exposure_path, comment = "##", col_types = coltypes, 
                                   col_select = c(DBSNP_ID, CHROM, POS, REF, ALT, AF, BETA, SE, Z, P, N)) %>%
  dplyr::rename(SNP = DBSNP_ID)

outcome_path = "/wynton/group/andrews/data/summary_stats/results/Nalls2019PD/Nalls2019PD.b37.chrall.tsv.gz"
outcome_ss_Nalls <- read_tsv(outcome_path) %>%
  mutate(
    N = 1460059,
    Z = ES / SE, 
    P = 10^(-LP)) %>%
  dplyr::rename(CHROM = CHR, BETA = ES) %>% 
  dplyr::select(DBSNP_ID, CHROM, POS, ALT, REF, AF, BETA, SE, Z, P, N) %>% 
  dplyr::rename(SNP = DBSNP_ID)


longchamps_apoe <- filter(exposure_ss_Longchamps , !(CHROM == 19 & between(POS, 44912079, 45912079)))
nalls_apoe <- filter(outcome_ss_Nalls , !(CHROM == 19 & between(POS, 44912079, 45912079)))
 
## Step 1: Merging Longchamps and Nalls datasets (X and Y) 
trait.names=c("Longchamps_mtDNAcn_Apoe_removed","Nalls_PD")
input.files = list(longchamps_apoe, nalls_apoe)

df = merge_sumstats(input.files, trait.names, LD.filepath, rho.filepath)

## Step 2: Calculating smart starting points for the likelihood optimisation
SP_list = calculate_SP(df,trait.names,run_ldsc=TRUE,run_MR=TRUE,hm3=hm3,ld="/wynton/group/andrews/data/eur_w_ld_chr/",nStep = 2,
                       SP_single=3,SP_pair=50,SNP_filter=10, nCores = 1, b_file = b_file, plink_path = plink_path)

message(paste0("importing SP_list", length(SP_list)))

#Run LHC-MR
res_Longchamps_Nalls  = lhc_mr(SP_list, trait.names, paral_method="lapply", nCores = 1, nBlock=200)

message(paste0("completed LHC-MR"))

res_Longchamps_Nalls  %>% as_tibble() %>% write_csv(.,
                    "/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/LHC-MR/Aadrita's_LHC-MR_analyses/LHC_MR_Longchamps_Nalls/lhcmr_Longchamps_Nalls.csv")




#Filter APOE
longchamps_apoe <- filter(exposure_ss_Longchamps , !(CHROM == 19 & between(POS, 44912079, 45912079)))
nalls_apoe <- filter(outcome_ss_Nalls , !(CHROM == 19 & between(POS, 44912079, 45912079)))