#!/usr/bin/env Rscript
# Copyright (c) 2026 Institut Pasteur
# Author: Bernd Jagla
#
# Script to read FlowJo v11 workspace and export to FlowJo v10 format
# Output filenames are descriptive and include:
#   - Source workspace name
#   - Group name (if available)
#   - Number of samples
#   - Sample names (abbreviated)
#   - Timestamp
#
# Usage:
#   Rscript export_test14.R [--workspace <path>] [--fcs-dir <path>] [--output-dir <path>] [--group <n>]
#
# Defaults:
#   --workspace:  test14_export.flowjo in test14 directory
#   --fcs-dir:    Same directory as workspace
#   --output-dir: ./output subdirectory
#   --group:      1 (first group)

# =============================================================================
# Parse command line arguments
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)

# Default configuration
TEST14_DIR <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test14"
FLOWJO11_WS <- file.path(TEST14_DIR, "test14_export.flowjo")
FCS_DIR <- TEST14_DIR
OUTPUT_DIR <- file.path(TEST14_DIR, "output")
SELECTED_GROUP <- 1

# Parse arguments
i <- 1
while (i <= length(args)) {
  if (args[i] == "--workspace" && i < length(args)) {
    FLOWJO11_WS <- args[i + 1]
    i <- i + 2
  } else if (args[i] == "--fcs-dir" && i < length(args)) {
    FCS_DIR <- args[i + 1]
    i <- i + 2
  } else if (args[i] == "--output-dir" && i < length(args)) {
    OUTPUT_DIR <- args[i + 1]
    i <- i + 2
  } else if (args[i] == "--group" && i < length(args)) {
    SELECTED_GROUP <- as.integer(args[i + 1])
    i <- i + 2
  } else if (args[i] %in% c("--help", "-h")) {
    cat("
FlowJo v11 to v10 Export Script

Usage:
  Rscript export_test14.R [options]

Options:
  --workspace <path>   Path to FlowJo v11 workspace (.flowjo file)
  --fcs-dir <path>     Directory containing FCS files
  --output-dir <path>  Output directory for exported files
  --group <n>          Group number to export (default: 1)
  --help, -h           Show this help message

Default values:
  --workspace:  test14_export.flowjo in test14 directory
  --fcs-dir:    Same as workspace directory
  --output-dir: ./output subdirectory
  --group:      1

Examples:
  # Use all defaults (test14 data)
  Rscript export_test14.R

  # Export different workspace
  Rscript export_test14.R --workspace /path/to/workspace.flowjo --fcs-dir /path/to/fcs

  # Export specific group
  Rscript export_test14.R --group 2
")
    quit(status = 0)
  } else {
    i <- i + 1
  }
}

# =============================================================================
# Load packages
# =============================================================================

suppressPackageStartupMessages({
  library(CyFj11)
  library(flowWorkspace)
  library(flowCore)
})

# =============================================================================
# Helper functions
# =============================================================================

#' Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Generate informative filename with timestamp and metadata
#' @param prefix Descriptive prefix
#' @param ext File extension
#' @param timestamp POSIXct timestamp (default: current time)
#' @return Character string with filename
make_output_filename <- function(prefix, ext, timestamp = NULL) {
  if (is.null(timestamp)) {
    timestamp <- Sys.time()
  }
  # Format: YYYYMMDD_HHMMSS
  ts_str <- format(timestamp, "%Y%m%d_%H%M%S")
  sprintf("%s_%s.%s", prefix, ts_str, ext)
}

#' Ensure directory exists
ensure_dir <- function(dir) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    message("Created output directory: ", dir)
  }
}

#' Sanitize string for use in filename
sanitize_filename <- function(s) {
  s <- gsub("[^a-zA-Z0-9._-]", "_", s)
  s <- gsub("_+", "_", s)  # Collapse multiple underscores
  s <- gsub("^_|_$", "", s)  # Remove leading/trailing underscores
  s
}

# =============================================================================
# Main script
# =============================================================================

main <- function() {

  cat("\n")
  cat("================================================================================\n")
  cat("FlowJo v11 to v10 Export Script\n")
  cat("================================================================================\n")
  cat("\n")
  cat("Configuration:\n")
  cat("  Workspace:  ", FLOWJO11_WS, "\n", sep = "")
  cat("  FCS dir:    ", FCS_DIR, "\n", sep = "")
  cat("  Output dir: ", OUTPUT_DIR, "\n", sep = "")
  cat("  Group:      ", SELECTED_GROUP, "\n", sep = "")
  cat("\n")

  # ---- Verify input files exist ---------------------------------------------
  cat("Checking input files...\n")
  if (!file.exists(FLOWJO11_WS)) {
    stop("FlowJo v11 workspace not found: ", FLOWJO11_WS)
  }
  cat("  [OK] FlowJo v11 workspace: ", basename(FLOWJO11_WS), "\n", sep = "")

  fcs_files <- list.files(FCS_DIR, pattern = "\\.fcs$", full.names = TRUE)
  if (length(fcs_files) == 0) {
    stop("No FCS files found in: ", FCS_DIR)
  }
  cat("  [OK] Found ", length(fcs_files), " FCS file(s) available\n", sep = "")
  cat("\n")

  # ---- Create output directory ----------------------------------------------
  ensure_dir(OUTPUT_DIR)
  cat("Output directory: ", OUTPUT_DIR, "\n", sep = "")
  cat("\n")

  # ---- Record timestamp for filenames ---------------------------------------
  start_time <- Sys.time()

  # ---- Step 1: Read FlowJo v11 workspace ------------------------------------
  cat("Step 1: Reading FlowJo v11 workspace...\n")
  ws <- read_flowjo11_workspace(FLOWJO11_WS)
  cat("  [OK] Workspace loaded\n")
  cat("       - Schema version: ", ws$schemaVersion, "\n", sep = "")
  cat("       - Groups: ", length(ws$groups), "\n", sep = "")
  cat("       - DataSources: ", length(ws$dataSources), "\n", sep = "")
  cat("       - PopulationDefinitions: ", length(ws$populationDefinitions), "\n", sep = "")
  cat("\n")

  # ---- Step 2: Convert to GatingSet -----------------------------------------
  cat("Step 2: Converting to GatingSet...\n")

  # List available groups
  cat("  Available groups:\n")
  for (i in seq_along(ws$groups)) {
    grp <- ws$groups[[i]]
    grp_name <- grp$name %||% sprintf("Group_%d", i)
    cat("    ", i, ": ", grp_name, " (", length(grp$results$dataSources), " samples)\n", sep = "")
  }

  if (SELECTED_GROUP > length(ws$groups)) {
    stop("Invalid group number: ", SELECTED_GROUP)
  }

  # Get group name for filename
  selected_group_name <- ws$groups[[SELECTED_GROUP]]$name %||% sprintf("Group_%d", SELECTED_GROUP)
  cat("  Selecting group ", SELECTED_GROUP, ": ", selected_group_name, "\n", sep = "")

  # Use backend_dir for persistent storage (avoids tempdir issues)
  # Note: tile backend is simpler and doesn't require HDF5
  backend_dir <- file.path(OUTPUT_DIR, "tile_backend")
  ensure_dir(backend_dir)

  gs_list <- fj11_to_gatingset(
    ws,
    group_name = SELECTED_GROUP,
    path = FCS_DIR,
    backend_dir = backend_dir,
    backend = "tile",
    execute = TRUE  # Actually execute gates
  )
  cat("  [OK] GatingSet list created\n")

  # fj11_to_gatingset returns a list of GatingSets (one per sample)
  # For export, we need a single GatingSet, so combine them
  if (length(gs_list) == 1) {
    gs <- gs_list[[1]]
  } else if (length(gs_list) > 1) {
    # Combine multiple GatingSets into one
    gs <- gs_list[[1]]
    for (i in 2:length(gs_list)) {
      gs <- c(gs, gs_list[[i]])
    }
  } else {
    stop("No GatingSets were created")
  }

  # Get sample names safely
  sn <- tryCatch(sampleNames(gs), error = function(e) {
    warning("Could not get sample names: ", e$message)
    character(0)
  })
  cat("       - Samples: ", length(sn), "\n", sep = "")
  for (s in sn) {
    cat("       - Sample: ", s, "\n", sep = "")
  }
  cat("\n")

  # ---- Step 3: Export to FlowJo v10 XML -------------------------------------
  cat("Step 3: Exporting to FlowJo v10 XML format...\n")

  # Generate informative output filename
  # Format: <workspace>_<group>_n<samples>_<samples>_exported_<timestamp>.xml
  ws_basename <- tools::file_path_sans_ext(basename(FLOWJO11_WS))
  n_samples <- length(sn)

  # Create abbreviated sample names for filename
  sample_suffix <- if (n_samples > 0) {
    # Take first 2-3 samples, abbreviate if many
    if (n_samples <= 3) {
      paste(sapply(sn, function(s) sanitize_filename(tools::file_path_sans_ext(s))), collapse = "_")
    } else {
      paste0(
        paste(sapply(sn[1:2], function(s) sanitize_filename(tools::file_path_sans_ext(s))), collapse = "_"),
        "_and_", n_samples - 2, "_more"
      )
    }
  } else {
    "no_samples"
  }

  # Build informative prefix
  group_suffix <- sanitize_filename(selected_group_name)
  prefix <- sprintf("%s_group%s_%s_n%d",
                    ws_basename,
                    group_suffix,
                    sample_suffix,
                    n_samples)

  xml_filename <- make_output_filename(
    prefix = prefix,
    ext = "wsp",
    timestamp = start_time
  )
  xml_output_path <- file.path(OUTPUT_DIR, xml_filename)

  # FCS output directory with informative name
  fcs_output_dir <- file.path(
    OUTPUT_DIR,
    sprintf("%s_group%s_n%d_fcs", ws_basename, group_suffix, n_samples)
  )
  ensure_dir(fcs_output_dir)

  cat("  - XML output: ", xml_filename, "\n", sep = "")
  cat("  - FCS output: ", basename(fcs_output_dir), "/\n", sep = "")
  cat("\n")

  # Export with FCS files copied to output directory
  cat("  Writing FCS files and XML workspace...\n")
  success <- export_flowjo10_workspace(
    gating_set = gs,
    output_path = xml_output_path,
    fcs_root = fcs_output_dir,
    overwrite = TRUE,
    workspace_name = ws_basename
  )

  if (success) {
    cat("\n")
    cat("================================================================================\n")
    cat("Export completed successfully!\n")
    cat("================================================================================\n")
    cat("\n")
    cat("Output files:\n")
    cat("  XML workspace: ", xml_output_path, "\n", sep = "")
    cat("  FCS files:     ", fcs_output_dir, "/\n", sep = "")
    cat("\n")

    # List exported FCS files
    exported_fcs <- list.files(fcs_output_dir, pattern = "\\.fcs$", full.names = TRUE)
    if (length(exported_fcs) > 0) {
      cat("Exported FCS files:\n")
      for (f in basename(exported_fcs)) {
        cat("    - ", f, "\n", sep = "")
      }
      cat("\n")
    }

    # Show file sizes
    cat("File sizes:\n")
    xml_size <- file.info(xml_output_path)$size
    cat("  XML: ", format(xml_size, big.mark = ","), " bytes\n", sep = "")
    fcs_total <- sum(file.info(exported_fcs)$size)
    cat("  FCS: ", format(fcs_total, big.mark = ","), " bytes (total)\n", sep = "")
    cat("\n")
  } else {
    cat("\n")
    cat("================================================================================\n")
    cat("Export FAILED!\n")
    cat("================================================================================\n")
    stop("Export failed - check warnings above")
  }

  invisible(list(
    xml_path = xml_output_path,
    fcs_dir = fcs_output_dir,
    gating_set = gs,
    success = success,
    config = list(
      workspace = FLOWJO11_WS,
      fcs_dir = FCS_DIR,
      output_dir = OUTPUT_DIR,
      group = SELECTED_GROUP
    )
  ))
}

# =============================================================================
# Run main
# =============================================================================

if (!interactive() || TRUE) {
  result <- main()
}
