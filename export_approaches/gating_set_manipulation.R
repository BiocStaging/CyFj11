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



sample_type = "Adaptive"
flowjo_root <- file.path(base_data_path, "MIV3", "3.6.2025", "Analysis", sample_type, "Flowjo")
gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
gs_dir = gs_dirs[10]
gs <- load_gs(gs_dir)


target_channel = "APC-Fire810-A"
target_channel_y ="BV480-A"
source("export_approaches/gating_comparison_framework.R")
results <- compare_gating_methods(
  gs = gs,
  parent_pop = parent_pop,
  target_marker = "CD4", 
  methods = c("mindensity", "flowclust_1d", "quantile"),
  plot_types = c("1d", "2d"),
  output_dir = "results/gating_comparison"

)

gh=gs[[1]]
parent_data <- gh_pop_get_data(gh, parent_pop)

gate_mindensity(parent_data, channel = c(target_channel, target_channel_y))
gate_mindensity(parent_data, channel = target_channel, filterId = "test")

gs <- load_gs(gs_dir)
# CCR7_gate,+,CD45_neg,CCR7,flowClust,"neg=1,pos=1",,,,
# activated cd4,++,cd4+cd8-,"CD38,HLA",gate_mindensity,,,,standardize_flowset,

pops = gs_get_pop_paths(gs)
pops
parentPos1 = length(pops)
parentPos2 = length(pops)-1

gate = gs_pop_get_gate(gs[[1]], pops[length(pops)-1])

gs_add_gating_method(gs, 
                     pop = "-/+",
                     gating_method = "gate_mindensity", 
                     dims = target_channel_y,
                     parent = pops[parentPos1])
gs_add_gating_method(gs, 
                     pop = "-/+",
                     gating_method = "gate_mindensity", 
                     dims = target_channel_y,
                     parent = pops[parentPos2])
gs_pop_set_name(gs,"/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/APC-Fire810-A+/BV480-A-", "")
gate = gs_pop_get_gate(gs[[1]], pops[length(pops)-3])

cyto_plot(gs[[1]], 
          alias = "",
          gate = gate,
          parent = pops[parentPos1], 
          channels = c(target_channel, target_channel_y))


# Parse the workspace file
ws <- read_flowjo11_workspace("")

# Process the gating set with the correct group
gs <- NULL
devtools::load_all()

gs <- fj11_to_gatingset(fj11_workspace = ws,
                        group_name = "Experiment Data",  # Use the correct group name
                        stop_on_multiple=FALSE,
                        keywords = c("File Name", "File URI", "Compensation Matrix"),
                        path = file.path(base_data_path, "analysis/MIV3.01.30.26/FCS_files/")
                        # path = file.path("./inst/data")
)

save_gs(gs, 'gs_dev')

gh = gs[[1]]
gh_get_transformations(gh)

plot(gs)

gh_pop_get_children(gh, "root")
gh_pop_get_parent(gh, "/CD45+")
all_pops <- flowWorkspace::gs_get_pop_paths(gs)
gh_pop_get_count(gh, "root")

pop_counts = gs_pop_get_count_fast(gs)
pop_counts$Population %>% unique()
library(flowWorkspace)
library(flowCore)
all_pops <- gs_get_pop_paths(gs)

##############################################################################

if (!is.null(gs)) {
  all_pops <- flowWorkspace::gs_get_pop_paths(gs)
  # to_remove <- all_pops[!all_pops %in% c("root", "/CD45+", "/Count Beads" )]
  if("/CD45+/Single Cells" %in% all_pops)
    flowWorkspace::gs_pop_remove(gs, "/CD45+/Single Cells")
  # Check the GatingSet groups
  cat("\nChecking GatingSet group information:\n")
  cat("GatingSet class:", class(gs), "\n")
  
  try({
    sample_names <- sampleNames(gs)
    cat("GatingSet sample names count:", length(sample_names), "\n")
    cat("First few sample names:\n")
    print(head(sample_names))
  }, silent = FALSE)
}

# Improved channel mapping function
create_channel_map <- function(gs) {
  gh <- gs[[1]]
  fr <- gh_pop_get_data(gh)
  
  markers <- markernames(fr)
  channels <- names(markers)
  
  # Extract marker names more carefully
  channel_map <- data.frame(
    Marker_Full = markers,
    Channel = channels,
    stringsAsFactors = FALSE
  ) %>%
    filter(grepl("-A$", Channel)) %>%  # Only Area channels
    mutate(
      # Extract just the marker name (before the first colon)
      Marker = trimws(gsub(" :.*", "", Marker_Full))
    ) %>%
    select(Marker, Channel)
  
  return(channel_map)
}

# Create the mapping
channel_map <- create_channel_map(gs)
print(channel_map)

marker_to_channel <- function(marker_string, channel_map = channel_map_manual) {
  if(is.na(marker_string) || marker_string == "") return(NA)
  
  markers <- strsplit(marker_string, ",")[[1]]
  channels <- sapply(markers, function(m) {
    m_trim <- trimws(m)
    ch <- channel_map$Channel[channel_map$Marker == m_trim]
    
    if(length(ch) == 0) {
      warning("Marker '", m_trim, "' not found in channel map")
      return(NA)
    }
    return(ch[1])
  })
  
  if(any(is.na(channels))) {
    return(NA)
  }
  
  return(paste(channels, collapse = ","))
}

# Test again
marker_to_channel("CD45RA,HLA-DR")  # Should return "AF532-A,AF700-A"
marker_to_channel("CD95")            # Should return "PerCP-eFluor710-A"

# Test the mapping
test_markers <- c("CD45RA", "HLA-DR", "CD27", "CD95", "CCR7", "PD1")
for(m in test_markers) {
  ch <- marker_to_channel(m, channel_map)
  cat(m, "->", ch, "\n")
}

library(openCyto)
library(flowWorkspace)
library(dplyr)
gs_add_gating_method(gs,
                     alias = "Naive",
                     pop = "+/-",
                     parent = "CXCR5- CD45RA-",
                     dims = "AF532-A,AF700-A",
                     gating_method = "flowClust",
                     gating_args = "K=4,quantile=0.9")

# Check results
new_pops <- gs_get_pop_paths(gs)
print(tail(new_pops, 30))

trans_list <- gh_get_transformations(gs[[1]])  # For first sample
trans_list[["FSC-A"]]
gh=gs[[1]]
flowCore::keyword(gh)

# Get alias from full path
get_alias <- function(full_path) {
  gsub(".*/", "", full_path)
}

# Example
full_path <- "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD4+/CD127+ CD25- CD4+/CXCR5- CD45RA-"
get_alias(full_path)  # Returns "CXCR5- CD45RA-"
