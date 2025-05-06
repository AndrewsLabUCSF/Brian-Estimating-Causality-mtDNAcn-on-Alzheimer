# Load library
library(dplyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)


# Set the path
folder_path <- "/wynton/group/andrews/users/achatterjee/genetic_correlations/results/"

# List all txt files
files <- list.files(folder_path, pattern = "*.txt", full.names = TRUE)

# Function to read and extract info
read_correlation_file <- function(file_path) {
  # Read the data
  data <- read.table(file_path, header = TRUE)
  
  # Get trait names from the filename
  file_name <- basename(file_path)
  traits <- strsplit(file_name, "_vs_|\\.txt")[[1]]
  
  # Create the output tibble
  tibble(
    trait_1 = traits[1],
    trait_2 = traits[2],
    corr_corrected = data$corr_corrected[1],
    se_rho = data$se_rho[1],
    pvalue_corrected = data$pvalue_corrected[1]
  )
}

# Apply across all files and combine
combined_df <- files %>%
  lapply(read_correlation_file) %>%
  bind_rows()

# View
print(combined_df)

# (Optional) Save it as a CSV
#write_csv(combined_df, "/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/genetic_correlations/gnova_genetic_correlations.csv")

# Step 1: Clean up trait names (if necessary)
combined_df_clean <- read_csv("/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/genetic_correlations/gnova_genetic_correlations.csv") %>%
  dplyr::rename(Pearson_correlation = corr_corrected) # <- Important: Rename `corr` to `Pearson_correlation`


# Step 1: Recoding trait names (optional, based on your plotting preference)
combined_df_clean <- combined_df_clean %>%
  mutate(
    trait_1 = case_when(
      trait_1 == "Bellenguez" ~ "AD/dementia",
      trait_1 == "Kunkle" ~ "AD",
      trait_1 == "Nalls" ~ "PD",
      TRUE ~ trait_1
    ),
    trait_2 = case_when(
      trait_2 == "Bellenguez" ~ "AD/dementia",
      trait_2 == "Kunkle" ~ "AD",
      trait_2 == "Nalls" ~ "PD",
      TRUE ~ trait_2
    )
  )

# Step 2: Expand the full grid of traits
traits_order <- c("Hagg", "Longchamps", "Gupta", "Chong", "AD", "AD/dementia", "PD")

genetic_cor_dfp <- expand_grid(trait_1 = traits_order,
                               trait_2 = traits_order) %>%
  left_join(combined_df_clean, by = c("trait_1", "trait_2")) %>%
  mutate(rg.p_cat = case_when(
    pvalue_corrected <= 0.05 ~ 1,
    pvalue_corrected <= 0.1 ~ 0.75,
    pvalue_corrected <= 0.5 ~ 0.5,
    pvalue_corrected <= 1 ~ 0.25
  )) 

----#Had to edit in R#-----

#Import edited dataframe (edited outside R)
genetic_cor_dfp <- read_tsv("/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/data/genetic_correlations/gnova_genetic_cor_edited.tsv")

# Define trait list based on your data
traits <- c("Hagg", "Longchamps", "Chong", "Gupta", "Kunkle", "Bellenguez", "Nalls")

# Step 3: Make sure trait order is correct
genetic_cor_dfp$trait_1 <- factor(genetic_cor_dfp$trait_1, levels = traits_order)
genetic_cor_dfp$trait_2 <- factor(genetic_cor_dfp$trait_2, levels = traits_order)

# Step 4: Plot
the_palette = "RdBu"

genetic_cor_plot <- ggplot(genetic_cor_dfp, aes(x = trait_1, y = trait_2, fill = Pearson_correlation, height = rg.p_cat, width = rg.p_cat)) +
  geom_tile() +
  scale_fill_distiller(palette = the_palette, limits = c(-1, 1)) +
  theme_classic() +
  geom_vline(xintercept = seq(0.5, length(traits_order)+0.5, 1), color = "grey90") +
  geom_hline(yintercept = seq(0.5, length(traits_order)+0.5, 1), color = "grey90") +
  theme(
    legend.position = 'bottom',
    axis.text.x = element_text(angle = 35, hjust = 1),
    aspect.ratio = 1,
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    text = element_text(size = 8)
  )

# Show the plot
print(genetic_cor_plot)

#Export
ggsave("/wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/results/Aadrita_results/plots/gnova_genetic_cor_plot.png", genetic_cor_plot, units = "in", width = 6, height = 6, dpi = 300) 


