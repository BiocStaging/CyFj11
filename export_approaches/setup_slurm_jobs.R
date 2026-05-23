#!/usr/bin/env Rscript

# Setup script to determine populations and create appropriate SLURM array jobs

library(tidyverse)
library(jsonlite)
library(flowWorkspace)
devtools::load_all()


# Environment detection pattern
base_path <- {
  mac_paths <- Sys.glob("/Volumes/scBiomarkers*/bernd")
  if (length(mac_paths) > 0) {
    dirname(mac_paths[1])
  } else {
    "/pasteur/helix/projects/scBiomarkers/bernd"
  }
}

base_data_path <- {
  mac_paths <- Sys.glob("/Volumes/")
  if (length(mac_paths) > 0) {
    mac_paths[1]
  } else {
    setwd("/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/")
    "/pasteur/helix/projects/scBiomarkers/bernd/cytometry"
  }
}

# Function to get all unique populations from gating sets
get_unique_populations <- function(gs_dirs) {
  all_populations <- c()
  
  # Process a subset of gs_dirs to identify populations efficiently
  # Using just the first few to get the population structure
  dirs_to_check <- head(gs_dirs, min(3, length(gs_dirs)))
  
  for (gs_dir in dirs_to_check) {
    tryCatch({
      gs <- load_gs(gs_dir)
      pops <- gs_get_pop_paths(gs, path = "full")
      all_populations <- c(all_populations, pops)
      gs_cleanup_temp(gs)
      rm(gs)
      gc()
    }, error = function(e) {
      message(sprintf("Error loading %s: %s", gs_dir, e$message))
    })
  }
  
  # Get unique populations
  unique_populations <- unique(all_populations)
  # Remove root population (empty path)
  unique_populations <- unique_populations[unique_populations != ""]
  
  return(unique_populations)
}

# Main function to create SLURM job arrays
create_slurm_script <- function() {
  # Sample types
  sample_types <- c("Innate", "Adaptive")
  
  # Create tasks list
  tasks <- c()
  
  # For each sample type, get the populations
  for (sample_type in sample_types) {
    # Convert to lowercase for directory names
    sample_type_lower <- sample_type
    flowjo_root <- file.path(base_data_path, "analysis", "MIV3.01.30.26", "Analysis", sample_type_lower, "Flowjo")
    
    if (!file.exists(flowjo_root)) {
      cat(sprintf("Directory doesn't exist: %s\n", flowjo_root))
      next
    }
    
    gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
    if (length(gs_dirs) == 0) {
      cat(sprintf("No gating sets found in: %s\n", flowjo_root))
      next
    }
    
    # Get unique populations for this sample type
    populations <- get_unique_populations(gs_dirs)
    
    # Create task strings
    for (pop in populations) {
      tasks <- c(tasks, sprintf("%s|%s", sample_type, pop))
    }
  }
  
  # Create the SLURM script
  slurm_script <- readLines("export_approaches/population_plot_mi_slurm.template.sh")
  
  # Replace placeholders
  slurm_script <- gsub("%array_size%", length(tasks) - 1, slurm_script)
  
  # Format the tasks for the bash array
  tasks_formatted <- paste(sprintf('  "%s"', tasks), collapse = '\n')
  slurm_script <- gsub("%tasks%", tasks_formatted, slurm_script)
  
  # Write the SLURM script
  writeLines(slurm_script, "export_approaches/population_plot_mi_slurm.sh")
  cat(sprintf("Created SLURM script with %d tasks\n", length(tasks)))
  
  return(length(tasks))
}

# Run the functions
cat("Setting up SLURM jobs for population plotting...\n")
num_tasks <- create_slurm_script()
cat(sprintf("Setup complete! Created SLURM script with %d tasks.\n", num_tasks))
cat("To submit the jobs, run: sbatch export_approaches/population_plot_mi_slurm.sh\n")
