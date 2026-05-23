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
library(xml2)
library(htmltools)

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

create_xml_diff_report <- function(file1, file2, output = "diff_report.html") {
  xml1 <- read_xml(file1)
  xml2 <- read_xml(file2)
  
  str1 <- as.character(xml1)
  str2 <- as.character(xml2)
  
  html_content <- paste0(
    "<html><head><style>",
    ".diff { font-family: monospace; white-space: pre; }",
    ".file1 { background-color: #ffcccc; }",
    ".file2 { background-color: #ccffcc; }",
    "</style></head><body>",
    "<h2>File 1:</h2><div class='diff file1'>", htmlEscape(str1), "</div>",
    "<h2>File 2:</h2><div class='diff file2'>", htmlEscape(str2), "</div>",
    "</body></html>"
  )
  
  writeLines(html_content, output)
  message("Report saved to ", output)
}

# Usage
create_xml_diff_report("test.wsp", "MIV3_T-B_15-03-2022_TD.wsp")