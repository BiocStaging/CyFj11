# Updated SLURM Batch Script Solution for Population Plotting

## Overview

This document describes the updated SLURM batch script solution for parallelizing the processing of cytometry population plots. The solution has been improved to dynamically detect populations from the data rather than using hardcoded lists.

## Key Improvements

### 1. Dynamic Population Detection
- The setup script now scans actual gating sets to identify all populations
- No longer relies on predefined population lists
- Automatically adapts to the data structure in each sample type

### 2. Template-Based SLURM Script Generation
- Uses a template file (`export_approaches/population_plot_mi_slurm.sh`) with placeholders
- Dynamically populates the template with actual tasks
- Easier to maintain and modify

### 3. Simplified Architecture
- Removed the embedded R script from the SLURM script
- Uses a separate, standalone R script for each task
- Cleaner separation of concerns

## Solution Components

### 1. Template SLURM Script
File: `export_approaches/population_plot_mi_slurm.sh`

This script contains placeholders that are populated by the setup script:
- `%array_size%` - Number of tasks minus 1 (for 0-based indexing)
- `%tasks%` - List of all sample_type|population combinations

### 2. Setup Script
File: `export_approaches/setup_slurm_jobs.R`

This script:
1. Dynamically detects all populations from the gating sets
2. Creates task combinations for each sample type/population pair
3. Populates the SLURM template with the actual tasks
4. Generates the final SLURM script

### 3. Single Population Processing Script
File: `export_approaches/population_plot_single.R`

This script:
1. Processes a single sample type and target population combination
2. Contains all the functionality from the original script
3. Accepts sample type and population as command-line arguments
4. Produces the same outputs (PDF plots and CSV statistics)

## How It Works

### Step 1: Setup
Run the setup script to generate the SLURM script:
```bash
Rscript export_approaches/setup_slurm_jobs.R
```

This script:
1. Scans the data directories for Innate and Adaptive sample types
2. Loads a few gating sets from each type to identify all populations
3. Creates a list of all sample type/population combinations
4. Populates the SLURM template with these tasks
5. Writes the final SLURM script

### Step 2: Job Submission
Submit the generated SLURM script:
```bash
sbatch export_approaches/population_plot_mi_slurm.sh
```

### Step 3: Parallel Execution
SLURM will:
1. Execute one job per sample type/population combination
2. Distribute jobs across available cluster nodes
3. Manage output and error logging for each task
4. Limit concurrent jobs to 32 (configurable) to avoid resource contention

## Benefits

1. **Dynamic Adaptation**: Automatically works with any data structure
2. **Parallel Processing**: Multiple combinations are processed simultaneously
3. **Resource Efficiency**: Each task requests only the resources it needs
4. **Fault Tolerance**: If one task fails, others continue unaffected
5. **Maintainability**: Clear separation between SLURM configuration and R processing logic
6. **Monitoring**: Individual job output and error logs for easy debugging

## Configuration Options

### Resource Allocation
Modify these SBATCH directives in the SLURM template as needed:
- `--mem`: Memory allocation per task (currently 8G)
- `--cpus-per-task`: CPU cores per task (currently 1)
- `--time`: Maximum execution time per task (currently 24 hours)
- `--partition`: Cluster partition to use (currently "long")

### Concurrency Control
The `%32` in `--array=0-%array_size%%32` limits concurrent jobs to 32. Adjust this number based on:
- Available cluster resources
- Desired level of parallelism
- Resource requirements of each task

## Output Organization

Each task produces:
1. A PDF file with plots for the specific sample type/population combination
2. A CSV file with statistics for that combination
3. Individual output/error logs in the `slurm_output/` directory

## Troubleshooting

### Checking Job Status
```bash
squeue -u $USER
```

### Viewing Job Output
```bash
# View output for a specific job array task
cat slurm_output/cytometry_plot_[job_id]_[task_id].out

# View errors for a specific job array task
cat slurm_output/cytometry_plot_[job_id]_[task_id].err
```

### Resubmitting Failed Tasks
Identify failed tasks from error logs and resubmit:
```bash
# Resubmit specific array indices (e.g., tasks 5, 10, and 15)
sbatch --array=5,10,15 export_approaches/population_plot_mi_slurm.sh