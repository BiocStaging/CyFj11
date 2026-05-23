library(tidyverse)
library(jsonlite)
library(digest)
library(waldo)
source("pretty_print_flowjo.R")
library(flowCore)
library(flowWorkspace)
library(tictoc)
library(CytoML)
library(RProtoBufLib)
library(cytolib)
library(openCyto)
library(ggcyto)
library(ggplot2)
library(gridExtra)
library(grid)
devtools::load_all()

# Environment detection pattern (use this in all scripts)
base_path <- {
  mac_paths <- Sys.glob("/Volumes/scBiomarkers*/bernd")
  if (length(mac_paths) > 0) {
    dirname(mac_paths[1])  # Remove /bernd and use first match
  } else {
    "/pasteur/helix/projects/scBiomarkers/bernd"  # Server environment
  }
}

base_data_path <- {
  mac_paths <- Sys.glob("/Volumes/bernd*/cytometry")
  if (length(mac_paths) > 0) {
    mac_paths[1]  # Use the full path directly
  } else {
    setwd("/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/")
    "/pasteur/helix/projects/LabExMI/USERS/bernd/cytometry"  # Server environment
  }
}

base_data_path <- {
  mac_paths <- Sys.glob("/Volumes/")
  if (length(mac_paths) > 0) {
    mac_paths[1]  # Use the full path directly
  } else {
    setwd("/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/")
    "/pasteur/helix/projects/LabExMI/USERS/bernd/cytometry"  # Server environment
  }
}
library(CytoExploreR)


# Specify the population/projection you want to analyze
target_population <- "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-"  # Change this to your target population
target_population <- "CD45+"
all_transformations <- list()


for(sample_type in c("Adaptive", "Innate")){
  flowjo_root = file.path(base_data_path, "MIV3", "3.6.2025", "Analysis", sample_type, "Flowjo")
  
  if(!file.exists(flowjo_root)){
    stop("directory doesn't exist: ", flowjo_root)
  }
  
  # Get all gatingset directories
  gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
  cat(sprintf("\nProcessing %s - Found %d gatingsets\n", sample_type, length(gs_dirs)))
  
   # Load each gatingset
  for(gs_dir in gs_dirs){
    cat(sprintf("Loading: %s\n", basename(gs_dir)))
    
    tryCatch({
      # Load gatingset
      gs <- load_gs(gs_dir)
      trans <- cyto_transformer_extract(gs)
      all_transformations[[gs_dir]] <- trans
      # Clean up
      rm(gs)
      gc()
      
    }, error = function(e) {
      message(sprintf("Error processing %s: %s", gs_dir, e$message))
    })
  }
  
}

