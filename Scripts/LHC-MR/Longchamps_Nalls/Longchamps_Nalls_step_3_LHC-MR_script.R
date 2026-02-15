
#load library
library(lhcMR)
library(tidyverse)  

#Trait names
trait.names=c("Longchamps_mtDNAcn_Apoe_removed","Nalls_PD")

message(paste0("running ",trait.names))

#Import SP_list
SP_list <- readRDS("/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/LHC-MR/Aadrita's_LHC-MR_analyses/Longchamps_Nalls/Longchamps_Nalls_SP_list.rds")

message(paste0("importing SP_list", length(SP_list)))

#Run LHC-MR
res_Longchamps_Nalls  = lhc_mr(SP_list, trait.names, paral_method="lapply", nCores = 1, nBlock=200)

message(paste0("completed LHC-MR"))

res_Longchamps_Nalls  %>% as_tibble() %>% write_csv(.,
"/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/LHC-MR/Aadrita's_LHC-MR_analyses/Longchamps_Nalls/lhcmr_Longchamps_Nalls.csv")

