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

##############################################################################
channel_map_manual <- tribble(
  ~Marker, ~Channel,
  "CXCR3", "BUV395-A",
  "Live-Dead", "LiveDeadFixableBlue-A",
  "CCR6", "BUV496-A",
  "CD19", "BUV563-A",
  "CD21", "BUV615-A",
  "CXCR5", "BUV661-A",
  "CD27", "BUV737-A",
  "CD3", "BUV805-A",
  "MR1 5-OP-RU", "BV421-A",
  "IgD", "PacBlue-A",
  "CD8b", "BV480-A",
  "IgM", "BV510-A",
  "CCR4", "BV605-A",
  "TCRgd", "BV650-A",
  "IgG", "BV711-A",
  "CD56", "BV750-A",
  "CCR7", "BV785-A",
  "IgA", "FITC-A",
  "CD45RA", "AF532-A",
  "CD8a", "PerCP-A",
  "PD1", "BB700-A",
  "PD-1", "BB700-A",
  "CD95", "PerCP-eFluor710-A",
  "CD1d PBS-57", "PE-A",
  "CD45", "SparkYG-593-A",
  "CD25", "PE-Dazzle594-A",
  "CXCR4", "PE-Cy5-A",
  "CD127", "PE-Cy5.5-A",
  "CD14-CD66b-CD16", "PE-Cy7-A",
  "CD38", "PE-Fire810-A",
  "ICOS", "APC-A",
  "CRTh2", "AF647-A",
  "HLA-DR", "AF700-A",
  "CD24", "APC-Cy7-A",
  "CD4", "APC-Fire810-A"
)

# Save for reference
write.csv(channel_map_manual, "channel_mapping.csv", row.names = FALSE)

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