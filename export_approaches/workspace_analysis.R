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

# Parse the workspace file
ws <- read_flowjo11_workspace("inst/mi.3samples.2gates.flowjo")
cat("Workspace loaded. Names in workspace:\n")
print(names(ws))

# Inspect available groups
groups <- CyFj11:::get_group_info(ws$json[[1]]$groups)
cat("Original groups:\n")
print(groups)

# Let's also look at the data sources to understand the relationship
cat("\nInspecting data sources and their group relationships:\n")
# Check how samples are assigned to groups in the original workspace
if (!is.null(ws$dataSources) && !is.null(ws$groups)) {
  cat("Data sources count:", length(ws$dataSources), "\n")
  cat("Groups count:", length(ws$groups), "\n")
  
  # Check group structure
  cat("\nDetailed group information:\n")
  for (group_uuid in names(ws$groups)) {
    group <- ws$groups[[group_uuid]]
    cat("Group:", group$definition$name, "(", group_uuid, ")\n")
    cat("  Sample count:", length(group$results$dataSources), "\n")
    if (length(group$results$dataSources) > 0) {
      cat("  First few sample UUIDs:\n")
      for (k in 1:min(3, length(group$results$dataSources))) {
        sample_uuid <- group$results$dataSources[[k]]
        if (sample_uuid %in% names(ws$dataSources)) {
          sample_name <- ws$dataSources[[sample_uuid]]$name
          cat("    ", k, ": ", sample_name, " (", sample_uuid, ")\n", sep="")
        } else {
          cat("    ", k, ": Unknown sample (", sample_uuid, ")\n", sep="")
        }
      }
    }
  }
}

# Read the exported workspace
ws2 <- read_flowjo11_workspace("test.3.flowjo")

diiflist = compare_flowjo_workspaces(ws,ws2)

cat("Comparing workspace names:\n")
all(names(ws2) == names(ws))

# Inspect available groups in exported workspace
groups2 <- CyFj11:::get_group_info(ws2$json[[1]]$groups)
cat("Original groups:\n")
print(groups)
cat("Exported groups:\n")
print(groups2)
cat("Group names comparison:\n")
print(data.frame(original = groups$name, exported = groups2$name))

# Let's also check the data sources in the exported workspace
cat("\nInspecting exported workspace data sources:\n")
if (!is.null(ws2$dataSources)) {
  cat("Exported data sources count:", length(ws2$dataSources), "\n")
}

# =============================================================================
# EXECUTE VALIDATIONS ON EXPORTED WORKSPACE
# =============================================================================

cat("\n=== VALIDATION RESULTS ===\n")

# Validate the exported workspace
validation_result <- validate_exported_workspace(ws2)
cat("\nWorkspace validation summary:\n")
cat("  Valid:", validation_result$valid, "\n")
if (length(validation_result$errors) > 0) {
  cat("  Errors:\n")
  for (error in validation_result$errors) {
    cat("    -", error, "\n")
  }
}
if (length(validation_result$warnings) > 0) {
  cat("  Warnings:\n")
  for (warning in validation_result$warnings) {
    cat("    -", warning, "\n")
  }
}

# Validate reference consistency
consistency_result <- validate_reference_consistency(ws2)
cat("\nReference consistency validation:\n")
cat("  Consistent:", consistency_result$consistent, "\n")
cat("  Total compound parameter sets:", consistency_result$total_compound_parameter_sets, "\n")
cat("  Unique patterns:", consistency_result$pattern_count, "\n")
if (length(consistency_result$issues) > 0) {
  cat("  Issues:\n")
  for (issue in consistency_result$issues) {
    cat("    -", issue, "\n")
  }
}

# Create a test workspace with standardized references for comparison
cat("\n=== CREATING TEST WORKSPACE ===\n")
test_workspace_path <- tempfile(fileext = ".flowjo")
test_result <- create_test_workspace_with_standardized_references(test_workspace_path)

if (test_result) {
  cat("Test workspace created successfully at:", test_workspace_path, "\n")
  
  # Validate the test workspace
  test_ws <- read_flowjo11_workspace(test_workspace_path)
  test_validation <- validate_exported_workspace(test_ws)
  test_consistency <- validate_reference_consistency(test_ws)
  
  cat("\nTest workspace validation:\n")
  cat("  Valid:", test_validation$valid, "\n")
  cat("  Reference consistency:", test_consistency$consistent, "\n")
  cat("  Compound parameter sets:", test_consistency$total_compound_parameter_sets, "\n")
  cat("  Unique patterns:", test_consistency$pattern_count, "\n")
} else {
  cat("Failed to create test workspace\n")
}

cat("\n=== ANALYSIS COMPLETE ===\n")