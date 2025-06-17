
#load library
library(lhcMR)
library(tidyverse)  

#Trait names
trait.names=c("gupta_mtDNAcn_Apoe_removed","Bellenguez_AD")

message(paste0("running ",trait.names))

#Import SP_list
SP_list <- readRDS("/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/LHC-MR/Aadrita's_LHC-MR_analyses/LHC_MR_Gupta_Bellenguez/Gupta_Bellenguez_SP_list.rds")

message(paste0("importing SP_list", length(SP_list)))

#Run LHC-MR
res_Gupta_Bellenguez  = lhc_mr(SP_list, trait.names, paral_method="lapply", nCores = 1, nBlock=200)

message(paste0("completed LHC-MR"))

res_Gupta_Bellenguez  %>% as_tibble() %>% write_csv(.,
"/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/LHC-MR/Aadrita's_LHC-MR_analyses/LHC_MR_Gupta_Bellenguez/lhcmr_Gupta_Bellenguez_apoe_removed_Aadrita.csv")

