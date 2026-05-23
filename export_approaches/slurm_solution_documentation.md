# SLURM Batch Script Solution for Population Plotting

## Overview

This document describes the SLURM batch script solution created to parallelize the processing of cytometry population plots. The solution breaks down the original sequential processing into individual tasks that can be executed in parallel on a SLURM cluster.

## Solution Components

### 1. Task Decomposition

The original script processed all combinations of:
- Sample types: "Innate" and "Adaptive"
- Target populations: All populations found in the gating sets

These combinations are now split into individual tasks, with each task responsible for processing one sample type and one target population.

### 2. Key Files

1. `export_approaches/setup_slurm_jobs.R` - Driver script that:
   - Dynamically identifies populations from the gating sets
   - Creates the SLURM batch script with appropriate array size
   - Generates a single-population processing script

2. `export_approaches/population_plot_single.R` - Individual task script that:
   - Processes a single sample type and target population combination
   - Contains all necessary functions from the original script
   - Accepts sample type and population as command-line arguments

3. `export_approaches/population_plot_mi_slurm.sh` - Generated SLURM batch script that:
   - Uses array jobs to process all combinations in parallel
   - Manages job submission and output/error logging
   - Calls the single-population script for each task

## How It Works

### Step 1: Setup
Run the setup script to generate the SLURM batch script:
```bash
Rscript export_approaches/setup_slurm_jobs.R
```

This script:
1. Scans the data directories to identify all populations
2. Creates a list of all sample type/population combinations
3. Generates the SLURM batch script with the correct array size
4. Creates the single-population processing script

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

1. **Parallel Processing**: Multiple combinations are processed simultaneously, significantly reducing total execution time
2. **Resource Efficiency**: Each task requests only the resources it needs (8GB memory, 1 CPU)
3. **Fault Tolerance**: If one task fails, others continue unaffected
4. **Scalability**: Automatically adapts to the number of populations in the data
5. **Monitoring**: Individual job output and error logs for easy debugging

## Configuration Options

### Resource Allocation
Modify these SBATCH directives in the generated script as needed:
- `--mem`: Memory allocation per task (currently 8G)
- `--cpus-per-task`: CPU cores per task (currently 1)
- `--time`: Maximum execution time per task (currently 24 hours)
- `--partition`: Cluster partition to use (currently "long")

### Concurrency Control
The `%32` in `--array=0-%d%%%32` limits concurrent jobs to 32. Adjust this number based on:
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