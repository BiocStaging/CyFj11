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
library(ggplot2)
library(gridExtra)
library(grid)
library(CytoExploreR)
library(xml2)
devtools::load_all()
library(data.table)
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
exclude_keywords <- c("Unstained", "Compensation", "LiveDead", "Control", "FMO", "Stabilized", "stained_Live")

# Create a helper function to check if a sample should be excluded
should_exclude_sample <- function(sample_name, keywords) {
  any(sapply(keywords, function(kw) grepl(kw, sample_name, ignore.case = TRUE)))
}


SSCH_1D_gate <- function(ngd, gs, exclude_keywords) {
  ra = list(c(200,400000))
  names(ra) = ngd[[2]]
  rg <- rectangleGate(ra, "SSC-H"=c(-Inf, Inf),
                      filterId=ngd[[3]])
  
  nodeID<-gs_pop_add(gs = gs, gate = rg,parent = ngd[[1]])#it is added to root node by default if parent is not specified
  nodeID
  gs_get_pop_paths(gs[[1]])
  recompute(gs)
  
  autoplot(gs[[1]],gate = ngd[[3]])
  # gs_pop_remove(ngd[[3]], gs = gs)
  
  gs_name = sampleNames(gs)[1]
  for(gs_name in sampleNames(gs)){
    if(should_exclude_sample(gs_name, exclude_keywords)) next()
    gh = gs[[gs_name]]
    # tr = gh_get_transformations(gh, ngd[[2]], inverse = T)
    dat <- Biobase::exprs(gh_pop_get_data(gh, y=ngd[[1]], inverse.transform = F))[,ngd[[2]]] 
    nr_dat = length(dat)
    val = c(0, 10000)
    # browser()
    if (nr_dat > 2){
      med = median(dat)
      std_dev = sd(dat)
      val = c(med - 4 * std_dev, med + 4 * std_dev)
    }else if (nr_dat==2){
      val = c(dat[1] - dat[1]/2, dat[2] + dat[2]/2)
    }else if (nr_dat==1){
      val = c(dat - dat/2, dat + dat/2)
    } 
    gate = gh_pop_get_gate(gh, ngd[[3]])
    attributes(gate)$min = val[1]
    attributes(gate)$max = val[2]
    gate@min = val[1]
    gate@max = val[2]
    message(str(gate), val[1], " : ",  val[2])
    gh_pop_set_gate(gh, ngd[[3]], gate)
    
  }
  recompute(gs)
}

robust_mindensity_dg_wrapper <- function(gs, pops, parentPos, 
                                         target_channel_y, min_cells = 3) {
  require(flowWorkspace)
  require(Biobase)
  
  # Helper to extract cutoff from gate (works for rectangleGate/boundaryGate)
  extract_cutoff <- function(gate, dim) {
    if (inherits(gate, "rectangleGate")) {
      # For positive gate: min is the cutoff
      # For negative gate: max is the cutoff
      if (dim %in% names(gate@min)) return(gate@min[[dim]])
      if (dim %in% names(gate@max)) return(gate@max[[dim]])
    } else if (inherits(gate, "boundaryGate")) {
      return(gate@boundary)
    }
    return(NA)
  }
  
  # 1. Get cell counts for iterative removal (prioritize removing lowest count first)
  ncount <- vapply(seq_along(gs), function(i) {
    gh_pop_get_count(gs[[i]], pops[parentPos])
  }, numeric(1))
  names(ncount) <- sampleNames(gs)
  
  # 2. Iteratively remove samples until gating succeeds
  working_samples <- sampleNames(gs)
  excluded_samples <- character(0)
  gated_gs <- NULL
  
  while (length(working_samples) > 0) {
    result <- tryCatch({
      gs_tmp <- gs_clone(gs)
      gs_tmp <- gs_tmp[working_samples]
      
      gs_add_gating_method(gs_tmp, 
                           pop = "-/+",
                           gating_method = "gate_mindensity", 
                           dims = target_channel_y,
                           parent = pops[parentPos])
      list(success = TRUE, gs = gs_tmp)
    }, error = function(e) {
      if(grepl("incorrect number of dimensions", e$message)){
        return(list(success = FALSE, error = e))
      } else {
        browser()
      }
    })
    
    if (result$success) {
      gated_gs <- result$gs
      break
    } else {
      # Remove sample with minimum count among remaining
      remove_candidate <- names(which.min(ncount[working_samples]))
      excluded_samples <- c(excluded_samples, remove_candidate)
      working_samples <- setdiff(working_samples, remove_candidate)
      message(sprintf("Removed %s (n=%d), retrying...", 
                      remove_candidate, ncount[remove_candidate]))
    }
  }
  
  if (is.null(gated_gs)) {
    stop(sprintf("Failed to apply gate_mindensity even after excluding %d samples", 
                 length(excluded_samples)))
  }
  
  message(sprintf("Gating succeeded with %d samples. Excluded: %s", 
                  length(working_samples), 
                  paste(excluded_samples, collapse = ", ")))
  
  # 3. Identify the two new populations (negative and positive)
  # They should be the last two paths added
  pop_paths <- gs_get_pop_paths(gated_gs, path = 'full')
  new_pops <- tail(pop_paths, 2)
  
  # Verify we have two (could check names contain +/- patterns)
  if (length(new_pops) != 2) {
    warning("Expected 2 populations from '-/+', found ", length(new_pops))
  }
  
  # Determine which is negative and which is positive by inspecting the first sample
  # (we'll use the gate bounds to identify them)
  first_sn <- working_samples[1]
  gate1 <- gh_pop_get_gate(gated_gs[[first_sn]], new_pops[1])
  gate2 <- gh_pop_get_gate(gated_gs[[first_sn]], new_pops[2])
  
  # For 1D gates: negative has (-Inf, X), positive has (X, Inf)
  # Identify by checking which one has -Inf as min (that's the negative gate)
  is_neg_gate <- function(g) {
    if(is.list(g)) g = g[[1]]
    if (inherits(g, "rectangleGate")) {
      return(any(g@min == -Inf, na.rm = TRUE))
    }
    return(FALSE)
  }
  
  neg_pop <- ifelse(is_neg_gate(gate1), new_pops[1], new_pops[2])
  pos_pop <- ifelse(is_neg_gate(gate2), new_pops[1], new_pops[2])
  
  message(sprintf("Negative pop: %s, Positive pop: %s", basename(neg_pop), basename(pos_pop)))
  
  # 4. Extract cutoffs from working samples (using the boundary between them)
  # The cutoff is the max of the negative gate or the min of the positive gate
  get_finite_bound <- function(gate, dim) {
    if(is.list(gate)) gate = gate[[1]]
    if (!inherits(gate, "rectangleGate")) return(NA)
    
    # Get bounds for the specific dimension
    min_val <- gate@min[[dim]]
    max_val <- gate@max[[dim]]
    
    # Return the finite one (the cutoff), or NA if both are finite (shouldn't happen for 1D +/-)
    if (!is.finite(min_val) && is.finite(max_val)) return(max_val)
    if (is.finite(min_val) && !is.finite(max_val)) return(min_val)
    
    # If both finite or both infinite, return the one that's not -Inf/Inf
    # or the midpoint if something weird happened
    return(ifelse(is.finite(min_val), min_val, max_val))
  }
  
  working_cutoffs <- sapply(working_samples, function(sn) {
    # Can use either neg_pop (max) or pos_pop (min) - should be same
    gate <- gh_pop_get_gate(gated_gs[[sn]], pos_pop)
    get_finite_bound(gate, target_channel_y)
  })
  
  median_cutoff <- median(working_cutoffs, na.rm = TRUE)
  message(sprintf("Median cutoff from %d working samples: %.2f", 
                  length(working_samples), median_cutoff))
  
  
  median_cutoff <- median(working_cutoffs, na.rm = TRUE)
  
  # 5. Apply to original GatingSet
  # First, add the gate structure to ALL samples using a template from working samples
  first_sn <- working_samples[1]
  
  # Get template gates from the successful gating run
  neg_gate_template <- gh_pop_get_gate(gated_gs[[first_sn]], neg_pop)
  pos_gate_template <- gh_pop_get_gate(gated_gs[[first_sn]], pos_pop)
  
  # Extract population names (node names)
  neg_name <- paste0(target_channel_y, "-")
  pos_name <- paste0(target_channel_y, "+")
  
  # Add gates to the full GatingSet (creates nodes in all samples)
  suppressMessages({
    gs_pop_add(gs, gate = neg_gate_template, parent = pops[parentPos], name = neg_name)
    gs_pop_add(gs, gate = pos_gate_template, parent = pops[parentPos], name = pos_name)
  })
  pop_paths <- gs_get_pop_paths(gated_gs, path = 'full')
  neg_name_full = paste0(pops[parentPos], "/", neg_name)
  pos_name_full = paste0(pops[parentPos], "/", pos_name)
  # Initial recompute to create the tree structure
  recompute(gs)
  
  # Now iterate through ALL samples and set individual gate parameters
  for (sn in sampleNames(gs)) {
    gh <- gs[[sn]]
    
    if (sn %in% working_samples) {
      # Use the optimized gates from the successful run
      neg_gate <- gh_pop_get_gate(gated_gs[[sn]], neg_pop)
      pos_gate <- gh_pop_get_gate(gated_gs[[sn]], pos_pop)
      
      # Set gates for this specific sample
      gh_pop_set_gate(gh, neg_name_full, neg_gate)
      gh_pop_set_gate(gh, pos_name_full, pos_gate)
    } else {
      # For excluded samples: Create median-based gates
      
      # Create negative gate (-Inf to cutoff)
      neg_params <- list(c(-Inf, median_cutoff))
      names(neg_params) <- target_channel_y
      
      # Create positive gate (cutoff to Inf)  
      pos_params <- list(c(median_cutoff, Inf))
      names(pos_params) <- target_channel_y

      # Create the actual gates with (potentially adjusted) cutoff
      neg_gate <- rectangleGate(neg_params, filterId = neg_name)
      pos_gate <- rectangleGate(pos_params, filterId = pos_name)
      
      # Update the actual bound values in the gate objects (SSCH_1D_gate pattern)
      # For rectangleGate, we need to set the specific coordinate
      # neg_gate: max is the cutoff, pos_gate: min is the cutoff
      neg_gate@max[[target_channel_y]] <- median_cutoff
      pos_gate@min[[target_channel_y]] <- median_cutoff
      
      # Set gates for this specific sample
      gh_pop_set_gate(gh, neg_name_full, neg_gate)
      gh_pop_set_gate(gh, pos_name_full, pos_gate)
    }
  }
  
  
  # 6. Recompute the gating tree
  recompute(gs)
  
  invisible(list(
    gs = gs,
    excluded_samples = excluded_samples,
    n_excluded = length(excluded_samples),
    working_samples = working_samples,
    median_cutoff = median_cutoff,
    working_cutoffs = working_cutoffs,
    pop_names = new_pops
  ))
}


################ ADAPTIVE ####################


new_gate_defs = list(
  # page 3
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd+", "APC-A", "Tgd_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd+", "PE-Cy5.5-A", "Tgd_CD127", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd+", "BUV661-A", "Tgd_CXCR5", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A-/MAIT_CD8P", "AF700-A", "MAIT_CD8P_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A-/MAIT_CD8P", "APC-A", "MAIT_CD8P_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A-/MAIT_CD8P", "PE-Cy5.5-A", "MAIT_CD8P_CD127", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/MAIT_CD4P", "AF700-A", "MAIT_CD4P_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/MAIT_CD4P", "APC-A", "MAIT_CD4P_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/MAIT_CD4P", "PE-Cy5.5-A", "MAIT_CD4P_CD127", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/MAIT_CD8nCD4n", "AF700-A", "MAIT_CD8nCD4n_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/MAIT_CD8nCD4n", "APC-A", "MAIT_CD8nCD4n_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/MAIT_CD8nCD4n", "PE-Cy5.5-A", "MAIT_CD8nCD4n_CD127", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A-/NKT_CD8P", "AF700-A", "NKT_CD8P_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A-/NKT_CD8P", "APC-A", "NKT_CD8P_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A-/NKT_CD8P", "PE-Cy5.5-A", "NKT_CD8P_CD127", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/NKT_CD4P", "AF700-A", "NKT_CD4P_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/NKT_CD4P", "APC-A", "NKT_CD4P_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/NKT_CD4P", "PE-Cy5.5-A", "NKT_CD4P_CD127", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/NKT_CD8nCD4n", "AF700-A", "NKT_CD8nCD4n_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/NKT_CD8nCD4n", "APC-A", "NKT_CD8nCD4n_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/NKT_CD8nCD4n", "PE-Cy5.5-A", "NKT_CD8nCD4n_CD127", "mindensity", "1d"),
  
  
  # page 4
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/CM CD8+", "BV785-A", "CM CD8+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/CM CD8+", "AF700-A", "CM CD8+_HLA-DR", "mindensity", "1d"), 
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/CM CD8+", "BB700-A", "CM CD8+_PD1", "mindensity", "1d"), 
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EM CD8+", "BV785-A", "EM CD8+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EM CD8+", "AF700-A", "EM CD8+_HLA-DR", "mindensity", "1d"), 
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EM CD8+", "BB700-A", "EM CD8+_PD1", "mindensity", "1d"), 
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EMRA CD8+", "BV785-A", "EMRA CD8+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EMRA CD8+", "AF700-A", "EMRA CD8+_HLA-DR", "mindensity", "1d"), 
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EMRA CD8+", "BB700-A", "EMRA CD8+_PD1", "mindensity", "1d"), 
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/Naive CD8+", "BV785-A", "Naive CD8+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/Naive CD8+", "AF700-A", "Naive CD8+_HLA-DR", "mindensity", "1d"), 
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/Naive CD8+", "BB700-A", "Naive CD8+_PD1", "mindensity", "1d"), 
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/CM CD4+", "BV785-A", "CM CD4+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/CM CD4+", "AF700-A", "CM CD4+_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/CM CD4+", "BB700-A", "CM CD4+_PD1", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EM CD4+", "BV785-A", "EM CD4+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EM CD4+", "AF700-A", "EM CD4+_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EM CD4+", "BB700-A", "EM CD4+_PD1", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EMRA CD4+", "BV785-A", "EMRA CD4+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EMRA CD4+", "AF700-A", "EMRA CD4+_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/EMRA CD4+", "BB700-A", "EMRA CD4+_PD1", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/Naive CD4+", "BV785-A", "Naive CD4+_CCR7", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/Naive CD4+", "AF700-A", "Naive CD4+_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD8+/Naive CD4+", "BB700-A", "Naive CD4+_PD1", "mindensity", "1d"),
  
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD4+/CD127- CD25+ CD4+/Treg/Activated T reg", "APC-A", "Activated T reg_icos", "mindensity", "1d"), 
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD4+/CD127- CD25+ CD4+/Treg/Memory T reg", "APC-A", "Memory T reg_icos", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/Not NKT/CD4+/CD127- CD25+ CD4+/Treg/Naive T reg", "APC-A", "Naive T reg_icos", "mindensity", "1d"),
  
  # page 6
  ## GC
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/GC", "BUV615-A", "GC_CD21", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/GC", "APC-Cy7-A", "GC_CD24", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/GC", "PE-Fire810-A", "GC_CD38", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/GC", "BV510-A", "GC_IgM", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/GC", "AF700-A", "GC_HLA_DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/GC", "BUV661-A", "GC_CXCR5", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/GC", "PE-Dazzle594-A", "GC_CD25", "mindensity", "1d"),
  
  ## Plasmocytes
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/Plasmocytes", "BUV615-A", "Plasmocytes_CD21", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/Plasmocytes", "APC-Cy7-A", "Plasmocytes_CD24", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/Plasmocytes", "PE-Fire810-A", "Plasmocytes_CD38", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/Plasmocytes", "BV510-A", "Plasmocytes_IgM", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/Plasmocytes", "AF700-A", "Plasmocytes_HLA_DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/Plasmocytes", "BUV661-A", "Plasmocytes_CXCR5", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/Plasmocytes", "PE-Dazzle594-A", "Plasmocytes_CD25", "mindensity", "1d"),
  
  ## mB
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/mB/","BUV615-A", "mB_CD21", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/mB/","APC-Cy7-A", "mB_CD24", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/mB/","PE-Fire810-A", "mB_CD38", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/mB/","BV510-A", "mB_IgM", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/mB/","AF700-A", "mB_HLA_DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/mB/","BUV661-A", "mB_CXCR5", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27+ IgD- B/mB/","PE-Dazzle594-A", "mB_CD25", "mindensity", "1d"),
  
  ## Naive B
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27- IgD+ B/Naive B", "BUV615-A", "Naive B_CD21", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27- IgD+ B/Naive B", "APC-Cy7-A", "Naive B_CD24", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27- IgD+ B/Naive B", "PE-Fire810-A", "Naive B_CD38", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27- IgD+ B/Naive B", "BV510-A", "Naive B_IgM", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27- IgD+ B/Naive B", "AF700-A", "Naive B_HLA_DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27- IgD+ B/Naive B", "BUV661-A", "Naive B_CXCR5", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD19+/CD27- IgD+ B/Naive B", "PE-Dazzle594-A", "Naive B_CD25", "mindensity", "1d")
)


ws_files = dir(file.path(base_data_path,"analysis","MIV3.01.30.26", "Analysis"),pattern = "*.wsp", recursive = T, full.names = T)


sample_type = "Adaptive"
flowjo_root <- file.path(base_data_path,"analysis","MIV3.01.30.26", "Analysis", sample_type, "Flowjo")
gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
gs_dir = gs_dirs[10]


for (gs_dir in gs_dirs){
  if(endsWith(gs_dir, "_BJ")) next()
  outDir = paste0(gs_dir, "_BJ")
  message(gs_dir)
  if(dir.exists(outDir))next()
  gs <- load_gs(gs_dir)
  rmSamples = lapply(sampleNames(gs), FUN = function(x)should_exclude_sample(x, exclude_keywords)) %>% unlist()
  gs = gs[!rmSamples]
  sampleNames(gs)
  ## cd4 / CD8 for MAIT and NK
  target_channel = "APC-Fire810-A"
  target_channel_y ="BV480-A"
  
  # gs_get_pop_paths(gs)
  if(!all(c(target_channel, target_channel_y) %in% (gh_get_transformations(gs[[1]]) %>% names()))){
    next()
  }
  parent_pop = "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT"
  if(!parent_pop %in% gs_get_pop_paths(gs)){
    next()
  }
  tryCatch({
    # gs_add_gating_method(gs, 
    #                      pop = "-/+",
    #                      gating_method = "gate_mindensity", 
    #                      dims = target_channel,
    #                      parent = parent_pop)
    
    pops = gs_get_pop_paths(gs)
    parentPos = which (pops == parent_pop)
    robust_mindensity_dg_wrapper(gs = gs, 
                                 pops = pops, 
                                 parentPos = parentPos, 
                                 target_channel_y = target_channel, 
                                 min_cells = 3) 
    pops = gs_get_pop_paths(gs)
    parentPos1 = length(pops)
    parentPos2 = length(pops)-1
    
    robust_mindensity_dg_wrapper(gs = gs, 
                                 pops = pops, 
                                 parentPos = parentPos1,
                                 target_channel_y = target_channel_y, 
                                 min_cells = 3) 
    robust_mindensity_dg_wrapper(gs = gs, 
                                 pops = pops, 
                                 parentPos = parentPos2, 
                                 target_channel_y = target_channel_y, 
                                 min_cells = 3) 
    gs_get_pop_paths(gs)
    gs_pop_set_name(gs,"/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A+/BV480-A-", "MAIT_CD4P")
    gs_pop_set_name(gs,"/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A-/BV480-A+", "MAIT_CD8P")
    gs_pop_set_name(gs,"/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT/APC-Fire810-A-/BV480-A-", "MAIT_CD8nCD4n")
    
    pops = gs_get_pop_paths(gs)
    
    parent_pop = "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT"
    if(!parent_pop %in% gs_get_pop_paths(gs)){
      next
    }
    parentPos = which(pops == parent_pop)
    robust_mindensity_dg_wrapper(gs = gs, 
                                 pops = pops, 
                                 parentPos = parentPos, 
                                 target_channel_y = target_channel, 
                                 min_cells = 3) 
    
    pops = gs_get_pop_paths(gs)
    parentPos1 = length(pops)
    parentPos2 = length(pops)-1
    
    gate = gs_pop_get_gate(gs[[1]], pops[length(pops)-1])
    
    robust_mindensity_dg_wrapper(gs = gs, 
                                 pops = pops, 
                                 parentPos = parentPos1, 
                                 target_channel_y = target_channel_y, 
                                 min_cells = 3) 
    robust_mindensity_dg_wrapper(gs = gs, 
                                 pops = pops, 
                                 parentPos = parentPos2, 
                                 target_channel_y = target_channel_y, 
                                 min_cells = 3) 
    
    gs_pop_set_name(gs,"/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A+/BV480-A-", "NKT_CD4P")
    gs_pop_set_name(gs,"/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A-/BV480-A+", "NKT_CD8P")
    gs_pop_set_name(gs,"/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/Not MAIT/NKT/APC-Fire810-A-/BV480-A-", "NKT_CD8nCD4n")
    
    
    for(ngd in new_gate_defs){
      cat(file = stderr(), paste(ngd, collapse = " : "),"\n")
      tryCatch({
        SSCH_1D_gate(ngd, gs, exclude_keywords)
       }, error = function(e) {
        warning("Failed to get population paths from sample ", e$message)
        
      })
    }
    if(dir.exists(outDir)){
      unlink(outDir, recursive = T)
    }
    save_gs(gs = gs, backend_opt = "copy", path = outDir)
    gs_cleanup_temp(gs)
    rm("gs")
  }, error = function(e){
    cat(file = stderr(), message("Error with ", outDir, "\n", e, "\n"))
  })
  
}

gs = load_gs("/pasteur/helix/projects/LabExMI/USERS/bernd/cytometry/MIV3/3.6.2025/Analysis/Adaptive/Flowjo/MIV3_T-B_02-05-2022_TD_BJ")
autoplot(gs[[1]], "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT")


devtools::load_all()
export_flowjo10_workspace(gating_set = gs, output_path="test.wsp", workspace_name = NULL)
ws3 = CytoML::open_flowjo_xml("test.wsp")
gs3 <- flowjo_to_gatingset(ws3, 
                           name = "All Samples", 
                           path = file.path(base_data_path, "analysis/MIV3.01.30.26/FCS_files/"),
                           greedy_match = T)
autoplot(gs3[[1]], "/CD45+/Single Cells")
autoplot(gs3[[1]], "/CD45+/Single Cells/Single Cells 2/Viable Cells/CD14- CD16- CD66b-/CD3+/TCRgd-/MAIT")


gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
gs_dir = gs_dirs[10]


for (gs_dir in gs_dirs){
  if(endsWith(gs_dir, "_BJ")) {
    gs = load_gs(gs_dir)
    
    export_flowjo10_workspace(gating_set = gs, output_path=paste0(gs_dir, ".wsp"), workspace_name = NULL)
    
  }
}








################### Innate ##########################

new_gate_defs = list(
  # page 10
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD16+ CD66b+/Neutrophils", "PacBlue-A", "Neutrophils_CD66b", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD16+ CD66b+/Neutrophils", "BV711-A", "Neutrophils_CD63", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD16+ CD66b+/Neutrophils", "BUV737-A", "Neutrophils_CD62L", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD16+ CD66b+/Neutrophils", "BB630-A", "Neutrophils_CD32", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD16+ CD66b+/Neutrophils", "BUV615-A", "Neutrophils_CD16", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD16+ CD66b+/Neutrophils", "BUV805-A", "Neutrophils_FceRI", "mindensity", "1d"),
  
  # "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD66b+/Eosinophils"
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD66b+/Eosinophils", "PacBlue-A", "Eosinophils_CD66b", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD66b+/Eosinophils", "BV711-A", "Eosinophils_CD63", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD66b+/Eosinophils", "BUV737-A", "Eosinophils_CD62L", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD66b+/Eosinophils", "BB630-A", "Eosinophils_CD32", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD66b+/Eosinophils", "BUV615-A", "Eosinophils_CD16", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/CD66b+/Eosinophils", "BUV805-A", "Eosinophils_FceRI", "mindensity", "1d"),
  
  
  # "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR-/CD123+ CD45low/Basophils"
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR-/CD123+ CD45low/Basophils", "PacBlue-A", "Basophils_CD66b", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR-/CD123+ CD45low/Basophils", "BV711-A", "Basophils_CD63", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR-/CD123+ CD45low/Basophils", "BUV737-A", "Basophils_CD62L", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR-/CD123+ CD45low/Basophils", "BB630-A", "Basophils_CD32", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR-/CD123+ CD45low/Basophils", "BUV615-A", "Basophils_CD16", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR-/CD123+ CD45low/Basophils", "BUV805-A", "Basophils_FceRI", "mindensity", "1d"),
  
  # page 11
  # "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK"
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK", "BV750-A", "CD56dim CD16hi NK_CD56", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK", "PerCP-eFluor710-A", "CD56dim CD16hi NK_CD69", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK", "PerCP-A", "CD56dim CD16hi NK_CD8a", "mindensity", "1d"),
  
  # "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56hi CD16dim NK"
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56hi CD16dim NK", "BV750-A", "CD56hi CD16dim NK_CD56", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56hi CD16dim NK", "PerCP-eFluor710-A", "CD56hi CD16dim NK_CD69", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56hi CD16dim NK", "PerCP-A", "CD56hi CD16dim NK_CD8a", "mindensity", "1d"),
  
  # "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK/NKG2C+ CD56dim CD16hi NK/Adaptive NK"
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK/NKG2C+ CD56dim CD16hi NK/Adaptive NK", "BV750-A", "Adaptive NK_CD56", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK/NKG2C+ CD56dim CD16hi NK/Adaptive NK", "PerCP-eFluor710-A", "Adaptive NK_CD69", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7+/NK cells/CD56dim CD16hi NK/NKG2C+ CD56dim CD16hi NK/Adaptive NK", "PerCP-A", "Adaptive NK_CD8a", "mindensity", "1d"),
  
  # page 12  
  # page 12  
  # [27] "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14hi CD16low Monocytes"                             
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14hi CD16low Monocytes", "AF700-A", "CD14hi CD16low Monocytes_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14hi CD16low Monocytes", "APC-Fire810-A", "CD14hi CD16low Monocytes_CD4", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14hi CD16low Monocytes", "APC-A", "CD14hi CD16low Monocytes_PD-L1", "mindensity", "1d"),
  
  # [28] "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14low CD16hi Monocytes"                             
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14low CD16hi Monocytes", "AF700-A", "CD14low CD16hi Monocytes_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14low CD16hi Monocytes", "APC-Fire810-A", "CD14low CD16hi Monocytes_CD4", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/CD14low CD16hi Monocytes", "APC-A", "CD14low CD16hi Monocytes_PD-L1", "mindensity", "1d"),
  
  # [29] "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/Int Monocytes"                                        
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/Int Monocytes", "AF700-A", "Int Monocytes_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/Int Monocytes", "APC-Fire810-A", "Int Monocytes_CCD4", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Monocytes/Int Monocytes", "APC-A", "Int Monocytes_PD-L1", "mindensity", "1d"),
  
  # [33] "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD141+ cDC"                            
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD141+ cDC", "AF700-A", "CD141+ cDC_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD141+ cDC", "BUV661-A", "CD141+ cDC_CD86", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD141+ cDC", "APC-Fire810-A", "CD141+ cDC_CD4", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD141+ cDC", "BV650-A", "CD141+ cDC_CXCR4", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD141+ cDC", "APC-A", "CD141+ cDC_PD-L1", "mindensity", "1d"),
  
  # [34] "/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD1c+ cDC"                             
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD1c+ cDC", "AF700-A", "CD1c+ cDC_HLA-DR", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD1c+ cDC", "BUV661-A", "CD1c+ cDC_CD86", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD1c+ cDC", "APC-Fire810-A", "CD1c+ cDC_CD4", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD1c+ cDC", "BV650-A", "CD1c+ cDC_CXCR4", "mindensity", "1d"),
  list("/CD45+/Single Cells/Single Cells 2/Viable Cells/Not CD3+ CD19+/Not CD66b+ /CD7-/Not Monocytes/HLADR+/cDC/CD1c+ cDC", "APC-A", "CD1c+ cDC_PD-L1", "mindensity", "1d")
  
)

sample_type = "Innate"
flowjo_root <- file.path(base_data_path,"analysis","MIV3.01.30.26", "Analysis", sample_type, "Flowjo")
gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
gs_dir = gs_dirs[10]

gs = load_gs(gs_dir)
gs_get_pop_paths(gs)
markernames(gs[[1]])
markernames(gs[[1]])[grep("cd8a", markernames(gs[[1]]),ignore.case = T)]

for (gs_dir in gs_dirs){
  if(endsWith(gs_dir, "_BJ")) next()
  outDir = paste0(gs_dir, "_BJ")
  
  if(dir.exists(outDir))next()
  gs <- load_gs(gs_dir)
  rmSamples = lapply(sampleNames(gs), FUN = function(x)should_exclude_sample(x, exclude_keywords)) %>% unlist()
  gs = gs[!rmSamples]
  
  tryCatch({
    for(ngd in new_gate_defs){
      cat(file = stderr(), paste(ngd, collapse = " : "),"\n")
      tryCatch({
        SSCH_1D_gate(ngd, gs, exclude_keywords)
        # 
        # gs_add_gating_method(gs, 
        #                      alias = ngd[[3]],
        #                      pop = "+",
        #                      gating_method = ngd[[4]], 
        #                      dims = ngd[[2]],
        #                      parent = ngd[[1]])
      }, error = function(e) {
        warning("Failed to get population paths from sample ", e$message)
        
      })
    }
    if(dir.exists(outDir)){
      unlink(outDir, recursive = T)
    }
    save_gs(gs = gs, backend_opt = "copy", path = outDir)
  }, error = function(e){
    cat(file = stderr(), message("Error with ", outDir, "\n", e, "\n"))
  })
  
}

sample_type = "Innate"
flowjo_root <- file.path(base_data_path, "analysis", "MIV3.01.30.26", "Analysis", sample_type, "Flowjo")
gs_dirs <- list.dirs(path = flowjo_root, full.names = TRUE, recursive = FALSE)
# -rwxrwx--- 1 bernd cifs-labexmi-zeus 2417251 Jan 30 13:55  /pasteur/helix/projects/LabExMI/USERS/bernd/cytometry/analysis/MIV3.01.30.26/Analysis/Innate/Flowjo/MIV3_Innate_02-05-2022_TD.wsp
for (gs_dir in gs_dirs){
  if(endsWith(gs_dir, "_BJ")) {
    gs = load_gs(gs_dir)
    
    export_flowjo10_workspace(gating_set = gs, output_path=paste0(gs_dir, ".wsp"), workspace_name = NULL)
    
  }
}

gs = load_gs("/pasteur/helix/projects/LabExMI/USERS/bernd/cytometry/MIV3/3.6.2025/Analysis/Innate/Flowjo/MIV3_Innate_01-06-2022_EK_BJ")
gs_get_pop_paths(gs)
################### Innate END #####attributes()################### Innate END ##########################



