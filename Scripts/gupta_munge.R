library(readr)         # For read_tsv()
library(dplyr)         # For data manipulation
library(tibble)        # For as_tibble()
library(MungeSumstats) # For format_sumstats()

# Load in Gupta
exposure_path_gupta <- "/wynton/group/andrews/data/summary_stats/resources/gwas/Gupta2023/Gupta2023_mtdnacn_adjusted.tsv.gz"
mtDNAcn_gupta <- read_tsv(exposure_path_gupta, comment = "#")

# Rename columns
mtDNAcn_gupta_new <- mtDNAcn_gupta %>%
  dplyr::rename("CHR" = "chromosome",
                "BP" = "base_pair_location")

# Debugging: Check first few rows
cat("Renamed columns:\n")
print(colnames(mtDNAcn_gupta_new))
print(head(mtDNAcn_gupta_new))

# Filter and split dataset by chromosome (excluding sex chromosomes)
chromosome_groups <- mtDNAcn_gupta_new %>%
  filter(!(CHR %in% c("X", "Y"))) %>%
  group_split(CHR)

# Identify chromosomes in each group
group_chr <- sapply(chromosome_groups, function(df) unique(df$CHR))

# Keep only chromosomes 8–22 (assuming 1–7 are already done)
remaining_groups <- chromosome_groups[group_chr %in% as.character(8:22)]

# Optional: Confirm which chromosomes will be processed
print(paste("Processing chromosomes:", paste(sapply(remaining_groups, function(df) unique(df$CHR)), collapse = ", ")))

# Define a function to process and save each chromosome
process_chromosome <- function(data_chunk) {
  chrom <- unique(data_chunk$CHR)  # Get chromosome number
  cat("Processing chromosome:", chrom, "\n")
  
  formatted_chunk <- MungeSumstats::format_sumstats(
    data_chunk,
    ref_genome = "GRCh37",
    return_data = TRUE
  ) %>%
    as_tibble()
  
  # Define where to save
  processed_folder <- "/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/other/processed_chunks"
  output_file <- file.path(processed_folder, paste0("processed_mtDNAcn_chr", chrom, ".tsv"))
  
  write_tsv(formatted_chunk, output_file)
  cat("Saved:", output_file, "\n")
  return(formatted_chunk)
}

# Process remaining chromosomes and save
lapply(remaining_groups, process_chromosome)

# Reload processed chunks and combine
processed_folder <- "/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/other/processed_chunks"
processed_files <- list.files(path = processed_folder, pattern = "processed_mtDNAcn_chr.*\\.tsv$", full.names = TRUE)

# Function to read TSV files with consistent column types
read_with_types <- function(file) {
  read_tsv(file, col_types = cols(
    CHR  = col_character(),
    BP   = col_double(),
    BETA = col_double(),
    SE   = col_double(),
    FRQ  = col_double(),
    P    = col_double(),
    PVAL = col_double(),
    SNP  = col_character(),
    A1   = col_character(),
    A2   = col_character(),
    ID   = col_character()
  ), show_col_types = FALSE)
}

# Load and combine all processed chunks
combined_mtDNAcn <- processed_files %>%
  lapply(read_with_types) %>%
  bind_rows()

# Check the combined dataset
print(dim(combined_mtDNAcn))  # Print dimensions
print(head(combined_mtDNAcn)) # Preview first few rows

# Export Gupta GWAS
write_tsv(combined_mtDNAcn, "/wynton/group/andrews/data/summary_stats/results/Gupta2023mtDNAcn_adjusted.tsv")



