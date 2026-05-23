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

###################### flowjo 10 ###############
workspaceFile = "MIV3_T-B_15-03-2022_TD.wsp"
ws_files = dir(file.path(base_data_path,"MIV3","3.6.2025", "Analysis"),pattern = "*.wsp", recursive = T, full.names = T)
devtools::load_all()

for (workspaceFile in ws_files){
  cat(file = stderr(), workspaceFile, "\n")
  
  if(!file.exists(tools::file_path_sans_ext(workspaceFile))){
    gs <- tryCatch({
      ws <- CytoML::open_flowjo_xml(workspaceFile)
      flowjo_to_gatingset(ws, 
                          name = "All Samples", 
                          path = file.path(base_data_path, "analysis/MIV3.01.30.26/FCS_files/"),
                          greedy_match = T)
    }, error = function(e) {
      message("Error loading gatingset: ", e$message)
      return(NULL)
    })
    
    if (!is.null(gs)) {
      tryCatch({
        save_gs(gs, path = tools::file_path_sans_ext(workspaceFile))
        message("Successfully saved: ", workspaceFile)
      }, error = function(e) {
        message("Error saving gatingset: ", e$message)
      })
    }
  }
}
# problem with Flowjo/MIV3_T-B_20-06-2022_SC.wsp

for(sample_type in c("Adaptive", "Innate")){
  flowjo_root = file.path(base_data_path, "MIV3", "3.6.2025", "Analysis", sample_type, "Flowjo")
  if(!file.exists(flowjo_root)){
    stop("directory doesn't exist: ", flowjo_root)
  }
  print( list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE))
}

gh = gs[[1]]
gh_get_transformations(gh)

plot(gs)

devtools::load_all()

export_flowjo10_workspace(gating_set = gs, output_path="test.wsp", workspace_name = NULL)

ws3 = CytoML::open_flowjo_xml("test.wsp")
gs3 <- flowjo_to_gatingset(ws3, 
                           name = "All Samples", 
                           path = file.path(base_data_path, "analysis/MIV3.01.30.26/FCS_files/"),
                           greedy_match = T)
plot(gs3)

gh_pop_get_children(gh, "root")
gh_pop_get_parent(gh, "/CD45+")
all_pops <- flowWorkspace::gs_get_pop_paths(gs)
gh_pop_get_count(gh, "root")

pop_counts = gs_pop_get_count_fast(gs)
pop_counts$Population %>% unique()
library(flowWorkspace)
library(flowCore)
all_pops <- gs_get_pop_paths(gs)
