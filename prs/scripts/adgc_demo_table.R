library(dplyr)
library(gtsummary)
library(gt)

#CHONG mtdnacn

## Data Preparation
fam_file <- "/wynton/group/andrews/users/rakshyasharma/PRS/PRS-CS-Auto/resources/ADGC/adgc.fam"
covar_file <- "/wynton/group/andrews/data/adgc/ADGCdatasets/covar_covariates.tsv"
base_dir <- "/wynton/group/andrews/users/rakshyasharma/pgsc_calc/adgc/results/Aadrita/Chong2022mtdnacn_eur/adgc"

pca_file <- file.path(base_dir, "score", "adgc_popsimilarity.txt.gz")
prs_file <- file.path(base_dir, "score", "adgc_pgs.txt.gz")


## Read in the data
fam_data <- read.table(fam_file, header = FALSE,
                       col.names = c("FID", "IID", "PID", "MID", "Sex", "P"))
covar_data <- read.table(covar_file, header = TRUE, sep = "\t")
pca_data <- read_tsv(pca_file, show_col_types = FALSE)
prs_data <- read.table(prs_file, header = TRUE)

# Clean and prep
fam_data <- fam_data %>% distinct(IID, .keep_all = TRUE)
covar_data <- covar_data %>% distinct(ID_2, .keep_all = TRUE)
pca_data <- pca_data %>% distinct(IID, .keep_all = TRUE)
prs_data <- prs_data %>% distinct(IID, .keep_all = TRUE)

fam_data$IID <- sub("^0_", "", fam_data$IID)
fam_data$IID <- ifelse(grepl("^[0]+[0-9]+$", fam_data$IID),
                       sub("^0+", "", fam_data$IID),
                       fam_data$IID)

covar_data <- covar_data %>% mutate(ID_2 = as.character(ID_2))
pca_data <- pca_data %>% mutate(IID = as.character(IID))
prs_data <- prs_data %>% mutate(IID = as.character(IID))

# Merge data
merged_data <- covar_data %>%
  left_join(fam_data, by = c("ID_2" = "IID")) %>%
  left_join(prs_data, by = c("ID_2" = "IID")) %>%
  left_join(pca_data, by = c("ID_2" = "IID")) %>%
  distinct() %>%
  mutate(
    across(where(is.numeric), ~na_if(., -9)),
    status_binary = if_else(status == 2, 1, 0),  # AD = 1, Control = 0
    status_binary = factor(status_binary, levels = c(0,1))
  ) %>%
  filter(status %in% c(1,2)) %>%
  drop_na(MostSimilarPop, aaoaae, apoe4any, sex, status) 

merged_data$Sex <- factor(merged_data$Sex, levels = c(1, 2), labels = c("Male", "Female"))


# Clean and prepare the dataset
demo_data <- merged_data %>%
  filter(!is.na(status)) %>%
  mutate(
    Diagnosis = factor(status, levels = c(0, 1), labels = c("Unaffected", "Affected")),
    Sex = factor(Sex),
    Ancestry = MostSimilarPop,
    APOE4_Carrier = ifelse(apoe4any == 1, "Carrier", "Non-carrier"),
    age = as.numeric(aaoaae)  # Age at exam
  ) %>%
  select(Diagnosis, Sex, Ancestry, age, APOE4_Carrier)

#write.csv(demo_data, file = "/wynton/group/andrews/users/achatterjee/demo_data.csv", row.names = FALSE)

---#had to do this locally as gtsummary was not loading on wynton---
  
  demo_data_aadrita <- demo_data %>%
  filter(!MostSimilarPop %in% c("CSA", "MID")) %>% 
  mutate(
    status = factor(status, levels = c(1, 2), labels = c("Affected", "Unaffected")),
    Sex = factor(Sex),
    Ancestry = MostSimilarPop,
    APOE4_status = factor(apoe4any, levels = c(0, 1), labels = c("Non-carrier", "Carrier")),
    AGE = as.numeric(aaoaae)
  ) %>%
  select(AGE, Sex, status, Ancestry, APOE4_status)


# Create the formatted demographic summary table
demo_table_aadrita <- demo_data_aadrita %>%
  tbl_summary(
    by = status,
    statistic = list(
      all_continuous() ~ "{mean} ± {sd}",
      all_categorical() ~ "{n} ({p}%)"
    ),
    digits = all_continuous() ~ 1,
    label = list(
      AGE ~ "Age",
      Sex ~ "Sex",
      Ancestry ~ "Ancestry",
      APOE4_status ~ "APOE ε4 Carrier"
    )
  ) %>%
  modify_header(label = "**Variable**") %>%
  bold_labels()

# View the table
demo_table_aadrita

#Export table
# Create a temporary .docx file path
tf <- tempfile("adgc_demo_table", fileext = ".docx")

# Convert and save the gtsummary table as Word using gt
demo_table_aadrita %>%
  as_gt() %>%
  gt::gtsave(filename = "~/Desktop/adgc_demo_table.docx")