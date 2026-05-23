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

# compare 2 json files
library(jsonlite)
library(waldo)

emptyJson = jsonlite::fromJSON("empty.org_pretty.json", simplifyVector = F)
oneSample = jsonlite::fromJSON("oneSample.org_pretty.json", simplifyVector = F)
compare(emptyJson, oneSample, max_diffs = Inf)

devtools::load_all()
source("pretty_print_flowjo.R")
pretty_print_flowjo("inst/mi.3samples.2gates.flowjo")

pretty_print_flowjo("inst/oneSample.org.flowjo")

devtools::load_all()
source("pretty_print_flowjo.R")
pretty_print_flowjo("inst/mi.3samples.2gates.flowjo")
# convert_json_to_flowjo(json_path = "mi.3samples.2gates_pretty copy.json",
convert_json_to_flowjo(json_path = "mi.3samples.2gates_pretty.json",
                       output_path = "inst/mi.3samples.2gates.1.flowjo",
                       original_flowjo_path = "inst/mi.3samples.2gates.flowjo")
unzip(zipfile = "inst/mi.3samples.2gates.1.flowjo", exdir = "tempTest.2", overwrite = T)
unzip(zipfile = "inst/mi.3samples.2gates.flowjo", exdir = "tempTest", overwrite = T)