#!/bin/bash
#SBATCH --job-name=cytometry_plots
#SBATCH --partition=long
#SBATCH --time=24:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --array=0-%array_size%
#SBATCH -A hubbioit
#SBATCH --partition=hubbioit,common  
#SBATCH --output=slurm_output/cytometry_plot_%A_%a.out
#SBATCH --error=slurm_output/cytometry_plot_%A_%a.err

# Create output directory for SLURM logs
mkdir -p slurm_output

# Define all tasks - this will be populated by the setup script
TASKS=(
%tasks%
)

# Get the current task
TASK="${TASKS[$SLURM_ARRAY_TASK_ID]}"
IFS='|' read -r SAMPLE_TYPE TARGET_POPULATION <<< "$TASK"

echo "Processing Sample Type: $SAMPLE_TYPE"
echo "Processing Population: $TARGET_POPULATION"

# Run the population plot script with the specific parameters
Rscript export_approaches/population_plot_single.R "$SAMPLE_TYPE" "$TARGET_POPULATION"
