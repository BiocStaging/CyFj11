#!/usr/bin/env Rscript

# Script to add gates for a single sample type
# Arguments: sample_type (Adaptive or Innate)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript add_gates_single.R <sample_type>")
}

sample_type <- args[1]
if (!sample_type %in% c("Adaptive", "Innate")) {
  stop("sample_type must be either 'Adaptive' or 'Innate'")
}

library(tidyverse)
library(jsonlite)
library(digest)
library(waldo)
library(flowCore)
library(flowWorkspace)
library(tictoc)
library(CytoML)
library(RProtoBufLib)
library(cytolib)
library(openCyto)
library(ggcyto)
library(ggplot2)
library(gridExtra)
library(grid)
library(CytoExploreR)
library(xml2)
devtools::load_all()

# Source the helper functions from add_mi_gates.R
source("export_approaches/add_mi_gates_helpers.R")

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
  mac_paths <- Sys.glob("/Volumes/")
  if (length(mac_paths) > 0) {
    mac_paths[1]
  } else {
    setwd("/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/")
    "/pasteur/helix/projects/LabExMI/USERS/bernd/cytometry"
  }
}

exclude_keywords <- c("Unstained", "Compensation", "LiveDeadFixableBlue", "Control", "FMO", "Stabilized")

# Helper to check exclusion
should_exclude_sample <- function(sample_name, keywords) {
  any(sapply(keywords, function(kw) grepl(kw, sample_name, ignore.case = TRUE)))
}

cat(sprintf("========================================\n"))
cat(sprintf("Processing %s gates\n", sample_type))
cat(sprintf("========================================\n"))

if (sample_type == "Adaptive") {
  # ADAPTIVE GATE DEFINITIONS
  new_gate_defs <- get_adaptive_gate_defs()

  ws_files <- dir(file.path(base_data_path, "analysis", "MIV3.01.30.26", "Analysis"),
                  pattern = "*.wsp", recursive = TRUE, full.names = TRUE)

  flowjo_root <- file.path(base_data_path, "analysis", "MIV3.01.30.26", "Analysis", sample_type, "Flowjo")
  gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)

  for (gs_dir in gs_dirs) {
    if (endsWith(gs_dir, "_BJ")) next()
    outDir <- paste0(gs_dir, "_BJ")

    if (dir.exists(outDir)) next()

    gs <- load_gs(gs_dir)
    rmSamples <- lapply(sampleNames(gs), FUN = function(x) should_exclude_sample(x, exclude_keywords)) %>% unlist()
    gs <- gs[!rmSamples]

    # cd4 / CD8 for MAIT and NK
    target_channel <- "APC-Fire810-A"
    target_channel_y <- "BV480-A"

    if (!all(c(target_channel, target_channel_y) %in% names(gh_get_transformations(gs[[1]])))) {
      next()
    }

    parent_pop <- "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT"
    if (!parent_pop %in% gs_get_pop_paths(gs)) {
      next()
    }

    tryCatch({
      gs_add_gating_method(gs,
                           pop = "-/+",
                           gating_method = "gate_mindensity",
                           dims = target_channel,
                           parent = parent_pop)

      pops <- gs_get_pop_paths(gs)
      parentPos1 <- length(pops)
      parentPos2 <- length(pops) - 1

      gs_add_gating_method(gs,
                           pop = "-/+",
                           gating_method = "mindensity",
                           dims = target_channel_y,
                           parent = pops[parentPos1])
      gs_add_gating_method(gs,
                           pop = "-/+",
                           gating_method = "gate_mindensity",
                           dims = target_channel_y,
                           parent = pops[parentPos2])

      gs_pop_set_name(gs, "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/BV480-A-", "MAIT_CD4P")
      gs_pop_set_name(gs, "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A-/BV480-A+", "MAIT_CD8P")
      gs_pop_set_name(gs, "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A-/BV480-A-", "MAIT_CD8nCD4n")

      parent_pop <- "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT"
      if (!parent_pop %in% gs_get_pop_paths(gs)) {
        next
      }

      gs_add_gating_method(gs,
                           pop = "-/+",
                           gating_method = "gate_mindensity",
                           dims = target_channel,
                           parent = parent_pop)

      pops <- gs_get_pop_paths(gs)
      parentPos1 <- length(pops)
      parentPos2 <- length(pops) - 1

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

      gs_pop_set_name(gs, "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/BV480-A-", "NKT_CD4P")
      gs_pop_set_name(gs, "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A-/BV480-A+", "NKT_CD8P")
      gs_pop_set_name(gs, "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A-/BV480-A-", "NKT_CD8nCD4n")

      for (ngd in new_gate_defs) {
        cat(file = stderr(), paste(ngd, collapse = " : "), "\n")
        tryCatch({
          SSCH_1D_gate(ngd, gs, exclude_keywords)
        }, error = function(e) {
          warning("Failed to add gate: ", e$message)
        })
      }

      if (dir.exists(outDir)) {
        unlink(outDir, recursive = TRUE)
      }
      save_gs(gs = gs, backend_opt = "copy", path = outDir)
      gs_cleanup_temp(gs)
      rm("gs")
    }, error = function(e) {
      cat(file = stderr(), "Error with ", outDir, "\n", e, "\n")
    })
  }

} else if (sample_type == "Innate") {
  # INNATE GATE DEFINITIONS
  new_gate_defs <- get_innate_gate_defs()

  flowjo_root <- file.path(base_data_path, "analysis", "MIV3.01.30.26", "Analysis", sample_type, "Flowjo")
  gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)

  for (gs_dir in gs_dirs) {
    if (endsWith(gs_dir, "_BJ")) next()
    outDir <- paste0(gs_dir, "_BJ")

    if (dir.exists(outDir)) next()

    gs <- load_gs(gs_dir)
    rmSamples <- lapply(sampleNames(gs), FUN = function(x) should_exclude_sample(x, exclude_keywords)) %>% unlist()
    gs <- gs[!rmSamples]

    tryCatch({
      for (ngd in new_gate_defs) {
        cat(file = stderr(), paste(ngd, collapse = " : "), "\n")
        tryCatch({
          SSCH_1D_gate(ngd, gs, exclude_keywords)
        }, error = function(e) {
          warning("Failed to add gate: ", e$message)
        })
      }

      if (dir.exists(outDir)) {
        unlink(outDir, recursive = TRUE)
      }
      save_gs(gs = gs, backend_opt = "copy", path = outDir)
      gs_cleanup_temp(gs)
      rm("gs")
    }, error = function(e) {
      cat(file = stderr(), "Error with ", outDir, "\n", e, "\n")
    })
  }
}

cat(sprintf("Completed %s processing\n", sample_type))
