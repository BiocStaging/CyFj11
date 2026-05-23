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

pretty_print_flowjo("inst/oneSample.1gate.org.flowjo")

emptyJson = jsonlite::fromJSON("empty.org_pretty.json", simplifyVector = F)
oneSample = jsonlite::fromJSON("oneSample.org_pretty.json", simplifyVector = F)
oneSampleoneGate = jsonlite::fromJSON("oneSample.1gate.org_pretty.json", simplifyVector = F)

# Parse the workspace file
ws <- read_flowjo11_workspace("inst/oneSample.1gate.org.flowjo")
devtools::load_all()

gs <- fj11_to_gatingset(fj11_workspace = ws,
                        group_name = "Experiment Data",  # Use the correct group name
                        stop_on_multiple=FALSE,
                        keywords = c("File Name", "File URI", "Compensation Matrix"),
                        path = file.path("./inst/data")
)

gh = gs[[1]]
tr = gh_get_transformations(gs[[1]])
attributes(tr[[1]])

options(error = recover)
options(warn = 0)  # Turn warnings into errors
devtools::load_all()

export_flowjo11_workspace(gs, "test.3.flowjo",
                          template_json_data = NULL,
                          workbench_data = NULL)
pretty_print_flowjo("test.3.flowjo")

pretty_print_flowjo("./inst/mi.11samples.2gates.flowjo")
pretty_print_flowjo("inst/mi.3samples.2gates.flowjo")