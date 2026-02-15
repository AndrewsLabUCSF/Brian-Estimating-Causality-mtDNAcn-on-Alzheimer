#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l mem_free=16G
#$ -l h_rt=24:00:00
#$ -r y

# Activate conda environment
conda activate mtdnacn  # Use source to ensure the environment is activated correctly

# Load necessary modules
module load CBI

# Run the R Markdown file with explicit library loading
Rscript /wynton/group/andrews/users/achatterjee/mtdnacn/Brian-Estimating-Causality-mtDNAcn-on-Alzheimer/Scripts/LHC-MR/Hagg_Kunkle/Hagg_Kunkle_step_3_LHC-MR_script.R