## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(CyFj11)
library(flowWorkspace)
library(flowCore)
library(CytoML)
library(ggcyto)

## ----install, eval=FALSE------------------------------------------------------
# # Install from GitHub (or CRAN if available)
# # devtools::install_github("baj12/CyFj11")
# 
# # Load the package
# library(CyFj11)

## ----read-workspace, eval=TRUE------------------------------------------------
# Set the path to your FlowJo workspace file
workspace_path <- system.file("extdata", "test.data.flowjo", package = "CyFj11")

# Read the FlowJo v11 workspace
ws <- read_flowjo11_workspace(workspace_path)

# Examine the workspace structure
print(names(ws))

## ----convert-gs, eval=TRUE----------------------------------------------------
workspace_fcs <- system.file("extdata", "", package = "CyFj11")
# fj11_to_gatingset() returns a named list of GatingSet objects, one per sample
gsList <- fj11_to_gatingset(
  fj11_workspace = ws,
  group_name = 1,
  path = workspace_fcs
)

pretty_print_flowjo(workspace_path)
# Check the number of samples
length(gsList)

# View sample names for the first sample
flowCore::sampleNames(gsList[[1]])

# Work with a single sample directly
gs <- gsList[[1]]

# Or merge all samples into one GatingSet (may overwrite per-sample transform settings)
# gs_merged <- flowWorkspace::merge_list_to_gs(gsList)

## ----examine-gs, eval=T-------------------------------------------------------
# View the population hierarchy
gs_get_pop_paths(gs)

# Get population statistics
stats <- gs_pop_get_stats(gs)
head(stats)

plot(gs)
autoplot(gs, "cells", bins = 80)
autoplot(gs, "cd8Pos", bins = 80, axis_inverse_trans = T)

gate = gh_pop_get_gate(gs, "cd8Pos")
gh = gs[[1]][[1]]
gh_get_transformations(gh,channel = "APC-A")



## ----export, eval=TRUE--------------------------------------------------------
# Export to FlowJo v10 format
export_path <- tempfile(fileext = ".wsp")
export_flowjo10_workspace(gs[[1]], export_path)

# Verify the export was successful
file.exists(export_path)

## ----help, eval=FALSE---------------------------------------------------------
# ?read_flowjo11_workspace
# ?fj11_to_gatingset
# ?export_flowjo10_workspace

## ----cytoML read xml, eval=FALSE----------------------------------------------
# library(CytoML)
# ws <- CytoML::open_flowjo_xml(export_path)
# gs_back <- CytoML::flowjo_to_gatingset(ws, name = "All Samples",
#                                             path = workspace_fcs)
# 
# # Get population statistics
# stats <- gs_pop_get_stats(gs_back)
# head(stats)
# 
# plot(gs_back)
# ggcyto::autoplot(gs_back, "cells", bins = 80)
# autoplot(gs_back, "cd8Pos", bins = 80)
# 
# 

