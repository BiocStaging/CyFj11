#!/usr/bin/env Rscript

# Debug script to check paths

library(tidyverse)
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
  mac_paths <- Sys.glob("/Volumes/scBiomarkers*/bernd")
  if (length(mac_paths) > 0) {
    dirname(mac_paths[1])
  } else {
    "/pasteur/helix/projects/scBiomarkers/bernd"
  }
}

# Check the paths
flowjo_root <- file.path(base_data_path, "bernd", "cytometry", "analysis", "MIV3.01.30.26", "innate", "Flowjo")
cat(sprintf("Checking path: %s\n", flowjo_root))
cat(sprintf("Path exists: %s\n", file.exists(flowjo_root)))

# List contents
if (file.exists(flowjo_root)) {
  contents <- list.files(flowjo_root, full.names = TRUE)
  cat(sprintf("Contents (%d items):\n", length(contents)))
  for (item in contents) {
    cat(sprintf("  %s (%s)\n", item, ifelse(dir.exists(item), "dir", "file")))
  }
  
  # Try to load one wsp file as a gating set
  wsp_files <- contents[grep("\\.wsp$", contents)]
  if (length(wsp_files) > 0) {
    cat(sprintf("Found %d WSP files\n", length(wsp_files)))
    # Try to load the first one
    wsp_file <- wsp_files[1]
    cat(sprintf("Trying to load: %s\n", wsp_file))
    
    # Try to load as gating set
    tryCatch({
      gs <- load_gs(wsp_file)
      cat("Successfully loaded as gating set\n")
      pops <- gs_get_pop_paths(gs, path = "full")
      cat(sprintf("Found %d populations\n", length(pops)))
      print(head(pops))
      gs_cleanup_temp(gs)
      rm(gs)
    }, error = function(e) {
      cat(sprintf("Error loading %s: %s\n", wsp_file, e$message))
    })
  }
}
