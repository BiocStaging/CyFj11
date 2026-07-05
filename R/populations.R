# Copyright (c) 2026 Institut Pasteur
# Author: Bernd Jagla
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#' @title Population Functions for FlowJo v11
#' @name populations
#' @keywords internal
#' @importFrom flowWorkspace gs_pop_add gs_get_pop_paths gs_pop_get_gate recompute markernames
NULL

#' Add Populations to GatingSet
#'
#' Adds population nodes and gates to GatingSet based on gating trees
#'
#' @param gs GatingSet object
#' @param gating_trees List of gating trees (one per sample)
#' @param gates List of gate objects
#' @param sample_uuids Vector of sample UUIDs
#' @param strip_comp_prefix Logical. Strip "Comp-" prefix from gate parameter names
#'   when matching to GatingSet parameters? Default TRUE.
#' @param verbose Logical. Print verbose messages? Default FALSE.
#' @keywords internal
#' @importFrom flowWorkspace gs_pop_add
add_populations_to_gatingset <- function(gs, gating_trees, gates, sample_uuids,
                                         strip_comp_prefix = TRUE, verbose = FALSE) {

  for (i in seq_along(sample_uuids)) {
    sample_uuid <- sample_uuids[i]
    tree        <- gating_trees[[i]]
    gh          <- gs[[i]]

    deferred <- new.env(parent = emptyenv())
    deferred$gates <- list()

    add_population_node(gh, tree, gates, sample_uuid,
                        strip_comp_prefix = strip_comp_prefix,
                        verbose = verbose, deferred = deferred)

    # Retry loop: keep trying until no more progress (handles chained logic gates)
    repeat {
      if (length(deferred$gates) == 0) break
      n_before     <- length(deferred$gates)
      new_deferred <- new.env(parent = emptyenv())
      new_deferred$gates <- list()

      for (lg in deferred$gates) {
        add_population_node(gh, lg$node, gates, sample_uuid,
                            parent = lg$parent,
                            strip_comp_prefix = strip_comp_prefix,
                            verbose = verbose, deferred = new_deferred)
      }

      deferred <- new_deferred
      if (length(deferred$gates) == n_before) break   # no progress — give up
    }

    # Warn only about permanently unresolvable logical gates
    for (lg in deferred$gates) {
      node_name <- if (is.list(lg$node$name)) unlist(lg$node$name) else lg$node$name
      component_names <- lg$node$logical_gate_info$combined_populations
      all_paths <- tryCatch(flowWorkspace::gs_get_pop_paths(gh), error = function(e) character(0))
      missing <- setdiff(component_names, sub(".*/", "", all_paths))
      warning("Could not resolve all component paths for logical gate: ", node_name, "\n",
              "  Missing components: ", paste(missing, collapse = ", "))
    }
  }
}

#' Compare and adjust gate transformations to match gating hierarchy
#' @param gh GatingHierarchy object
#' @param gate_obj flowCore gate object
#' @param strip_comp_prefix Logical. Strip "Comp-" prefix from gate parameter names?
#' @keywords internal
adjust_gate_transformations <- function(gh, gate_obj, strip_comp_prefix = TRUE) {

  # Get transformations from gating hierarchy
  gh_trans <- flowWorkspace::gh_get_transformations(gh)
  gh_param_names <- names(gh_trans)

  # Get parameters from the gate
  gate_params <- flowCore::parameters(gate_obj)

  # If the hierarchy has no stored transformations (e.g. because we keep the
  # cytoframe raw and skip permanent transforms), fall back to the actual
  # flowFrame column names so that "Comp-" prefixed gate parameters can still
  # be mapped to the compensated/raw parameter names.
  if (length(gh_param_names) == 0) {
    gh_param_names <- colnames(flowWorkspace::gh_pop_get_data(gh, "root"))
  }

  # Map gate parameter names to GatingSet parameter names
  # Gate params may have "Comp-" prefix or different sanitization
  mapped_params <- map_gate_params_to_gh(gate_params, gh_param_names, strip_comp_prefix = strip_comp_prefix)

  # Check if we need to adjust transformations
  # With the current pipeline the cytoframe is kept in raw space and gate
  # coordinates are already converted to raw space by display_to_raw().  There
  # is therefore no need to forward-transform gate coordinates before gating.
  needs_adjustment <- FALSE
  trans_to_apply <- list()

  if (FALSE) {
    for (i in seq_along(gate_params)) {
      gate_param <- gate_params[i]
      gh_param <- mapped_params[[gate_param]]

      # Skip if no mapping found
      if (is.null(gh_param)) {
        warning("Could not map gate parameter '", gate_param, "' to GatingSet parameters")
        next
      }

      # Get transformation from hierarchy using mapped name
      gh_trans_func <- gh_trans[[gh_param]]

      # Skip if no transformation in hierarchy
      if (is.null(gh_trans_func)) {
        next
      }

      # Get transformation type from hierarchy
      gh_trans_type <- attr(gh_trans_func, "type")

      # If hierarchy has a transformation (not "none"), we need to apply it to gate coords
      if (!is.null(gh_trans_type)) {
        # Gate coordinates are in raw space, need to convert to transformed space
        needs_adjustment <- TRUE
        trans_to_apply[[gh_param]] <- gh_trans_func

        if (.pkgenv$verbose) {
          message("Parameter '", gate_param, "' -> '", gh_param, "' needs adjustment:")
          message("  Gate coords in: raw data space")
          message("  Hierarchy expects: ", gh_trans_type, " transformed space")
        }
      }
    }
  }

  # If no mapping found at all, return original gate
  if (all(sapply(mapped_params, is.null))) {
    return(gate_obj)
  }

  # Always update parameter names to match flowFrame (critical for compensated data)
  gate_obj <- update_gate_param_names(gate_obj, mapped_params)

  # If no transformation adjustment needed, return gate with updated names
  if (!needs_adjustment) {
    return(gate_obj)
  }

  # Apply transformations to convert from raw space to transformed space
  gate_obj_adjusted <- apply_transforms_to_gate(gate_obj, trans_to_apply)

  return(gate_obj_adjusted)
}


#' Map gate parameter names to GatingSet parameter names
#'
#' Gate parameter names may have "Comp-" prefix or different sanitization.
#' This function maps them to the actual GatingSet parameter names.
#'
#' @param gate_params Character vector of gate parameter names
#' @param gh_param_names Character vector of GatingSet parameter names
#' @param strip_comp_prefix Logical. Strip "Comp-" prefix from gate parameter names?
#'   Default TRUE. Set to FALSE if compensation has already been applied with
#'   matching parameter names.
#' @return Named list mapping gate params to GatingSet params
#' @keywords internal
map_gate_params_to_gh <- function(gate_params, gh_param_names, strip_comp_prefix = TRUE) {
  # Use unified parameter name mapping
  # Gate params may have "Comp-" prefix from flowCore compensation
  # and "/" may be sanitized to "_"
  map_param_names(
    source_names = gate_params,
    target_names = gh_param_names,
    strip_comp_prefix = strip_comp_prefix,
    case_insensitive = FALSE
  )
}

#' Update gate parameter names to match flowFrame
#'
#' After compensation, flowFrame parameter names may have "Comp-" prefix.
#' This function updates gate parameter names to match.
#'
#' @param gate_obj flowCore gate object
#' @param mapped_params Named list mapping old param names to new param names
#' @return Gate object with updated parameter names
#' @keywords internal
update_gate_param_names <- function(gate_obj, mapped_params) {
  
  # Filter out NULL mappings
  valid_mapping <- mapped_params[!sapply(mapped_params, is.null)]
  
  if (length(valid_mapping) == 0) {
    return(gate_obj)
  }
  
  # Handle different gate types
  if (inherits(gate_obj, "rectangleGate")) {
    # Update min/max names
    old_names <- names(gate_obj@min)
    new_names <- sapply(old_names, function(n) {
      if (n %in% names(valid_mapping)) valid_mapping[[n]] else n
    })
    names(gate_obj@min) <- new_names
    names(gate_obj@max) <- new_names
    
  } else if (inherits(gate_obj, "quadGate")) {
    # Update boundary names - critical for quadGate!
    old_names <- names(gate_obj@boundary)
    new_names <- sapply(old_names, function(n) {
      if (n %in% names(valid_mapping)) valid_mapping[[n]] else n
    })
    names(gate_obj@boundary) <- new_names
    
    if (.pkgenv$verbose) {
      message("  Updated quadGate boundary names: ", paste(old_names, collapse = ", "),
              " -> ", paste(new_names, collapse = ", "))
    }
    
  } else if (inherits(gate_obj, "polygonGate")) {
    # Update boundary column names
    old_names <- colnames(gate_obj@boundaries)
    new_names <- sapply(old_names, function(n) {
      if (n %in% names(valid_mapping)) valid_mapping[[n]] else n
    })
    colnames(gate_obj@boundaries) <- new_names
    
  } else if (inherits(gate_obj, "ellipsoidGate")) {
    # Update mean and covariance names
    old_names <- names(gate_obj@mean)
    new_names <- sapply(old_names, function(n) {
      if (n %in% names(valid_mapping)) valid_mapping[[n]] else n
    })
    names(gate_obj@mean) <- new_names
    colnames(gate_obj@cov) <- new_names
    rownames(gate_obj@cov) <- new_names
  }
  
  # Update the parameters slot
  flowCore::parameters(gate_obj) <- unlist(valid_mapping)
  
  return(gate_obj)
}

#' Apply transformations to gate coordinates
#' @keywords internal
apply_transforms_to_gate <- function(gate_obj, trans_list) {
  
  if (length(trans_list) == 0) {
    return(gate_obj)
  }
  
  # Handle rectangleGate
  if (inherits(gate_obj, "rectangleGate")) {
    
    for (param in names(trans_list)) {
      trans_func <- trans_list[[param]]
      
      # Apply transformation to min and max values
      if (param %in% names(gate_obj@min)) {
        old_val <- gate_obj@min[param]
        gate_obj@min[param] <- trans_func(old_val)
        if (.pkgenv$verbose) {
          message("  Transformed ", param, " min: ", old_val, " -> ", gate_obj@min[param])
        }
      }
      
      if (param %in% names(gate_obj@max)) {
        old_val <- gate_obj@max[param]
        gate_obj@max[param] <- trans_func(old_val)
        if (.pkgenv$verbose) {
          message("  Transformed ", param, " max: ", old_val, " -> ", gate_obj@max[param])
        }
      }
    }
    
  } else if (inherits(gate_obj, "quadGate")) {
    # browser()
    # Quadrant gates have boundary (divider positions) that need transformation
    # Note: slot is "boundary" (singular), not "boundaries"
    boundary <- gate_obj@boundary
    
    for (param in names(trans_list)) {
      if (param %in% names(boundary)) {
        trans_func <- trans_list[[param]]
        old_val <- boundary[param]
        boundary[param] <- trans_func(old_val)
        
        if (.pkgenv$verbose) {
          message("  Transformed ", param, " quad divider: ", old_val, " -> ", boundary[param])
        }
      }
    }
    
    gate_obj@boundary <- boundary
    
  } else if (inherits(gate_obj, "polygonGate")) {
    
    boundaries <- gate_obj@boundaries
    
    for (param in names(trans_list)) {
      if (param %in% colnames(boundaries)) {
        trans_func <- trans_list[[param]]
        old_vals <- boundaries[, param]
        boundaries[, param] <- trans_func(old_vals)
        
        if (.pkgenv$verbose) {
          message("  Transformed ", param, " polygon boundaries")
          message("    Range: ", min(old_vals), "-", max(old_vals), 
                  " -> ", min(boundaries[, param]), "-", max(boundaries[, param]))
        }
      }
    }
    
    gate_obj@boundaries <- boundaries
    
  } else if (inherits(gate_obj, "ellipsoidGate")) {
    
    # For ellipsoid gates, need to transform mean and possibly adjust covariance
    for (param in names(trans_list)) {
      param_idx <- which(names(gate_obj@mean) == param)
      
      if (length(param_idx) > 0) {
        trans_func <- trans_list[[param]]
        old_val <- gate_obj@mean[param_idx]
        gate_obj@mean[param_idx] <- trans_func(old_val)
        
        if (.pkgenv$verbose) {
          message("  Transformed ", param, " ellipse mean: ", old_val, " -> ", gate_obj@mean[param_idx])
        }
        
        # Note: transforming an ellipsoid properly requires transforming the covariance matrix
        # This is complex and may not preserve the ellipsoid shape
        warning("Ellipsoid gate transformation may not preserve exact shape")
      }
    }
    
  }
  
  return(gate_obj)
}

#' Add Population Node Recursively
#' @keywords internal
#' @importFrom flowWorkspace gs_pop_add
#' @importFrom utils str
#' @importFrom magrittr %>%
#' @param strip_comp_prefix Logical. Strip "Comp-" prefix from gate parameter names?
#' @param verbose Logical. Print verbose messages?
add_population_node <- function(gh, node, gates, sample_uuid, parent = "root",
                                strip_comp_prefix = TRUE, verbose = FALSE,
                                deferred = NULL) {
  if (.pkgenv$verbose) message(node$name, "\n")
  # if(stringr::str_starts(node$name, "TNF")) {
  # browser()
  # }
  # Extract node name correctly (it's a list in FlowJo v11)
  node_name <- if (is.list(node$name) && length(node$name) > 0) {
    node$name %>% unlist()
  } else if (is.character(node$name)) {
    node$name
  } else {
    "Unnamed"
  }
  if (.pkgenv$verbose) message(node$type)
  # browser()
  # Skip root node (already exists)
  if (.pkgenv$verbose) message("parent: ", paste(parent, collapse = " : "),"\n")
  if (parent[1] == "root" && (node_name[1] == "root" || node_name[1] == "Ungated")) {
    if (!is.null(node$children)) {
      for (child in node$children) {
        add_population_node(
          gh = gh,
          node = child,
          gates = gates,
          sample_uuid = sample_uuid,
          parent = "root",
          strip_comp_prefix = strip_comp_prefix,
          verbose = verbose,
          deferred = deferred
        )
      }
    }
    return()
  }
  
  # Get gate for this population-sample combination
  # Extract definition_uuid correctly (it's also a list)
  definition_uuid <- if (is.list(node$definition_uuid) && length(node$definition_uuid) > 0) {
    node$definition_uuid[[1]]
  } else if (is.character(node$definition_uuid)) {
    node$definition_uuid
  } else {
    NULL
  }
  
  if (is.null(definition_uuid)) {
    warning("No definition UUID found for population: ", node_name)
    return()
  }
  
  gate_key <- paste0(definition_uuid, "_", sample_uuid)
  gate_obj <- gates[[gate_key]]
  is_logica_gate <- !is.null(node$logical_gate_info)
  if (.pkgenv$verbose) message(node_name, " (sample: ", sample_uuid, ")\n")
  # browser()
  if (is.null(gate_obj) && ! is_logica_gate) {
    # Get available population paths for debugging
    all_pop_paths <- tryCatch(flowWorkspace::gs_get_pop_paths(gh), error = function(e) NULL)
    pop_paths_str <- if (!is.null(all_pop_paths)) {
      paste("\n  Available populations:", paste(all_pop_paths, collapse = "\n  "))
    } else {
      ""
    }
    
    warning("No gate found for population: ", node_name, " (sample: ", sample_uuid, ")\n",
            "  Parent: ", paste(parent, collapse = " : "),
            "  Definition UUID: ", definition_uuid,
            pop_paths_str)
    return()
  }
  if(is_logica_gate){
    # Create boolean filter for logical gate
    # browser()
    # Create boolean filter for logical gate
    operator <- node$logical_gate_info$operator
    component_names <- node$logical_gate_info$combined_populations
    
    if (.pkgenv$verbose) message("Building logical gate: ", node_name, " (", operator, ")")
    if (.pkgenv$verbose) message("  Components: ", paste(component_names, collapse = ", "))
    
    # Get all existing populations in the gating hierarchy
    all_paths <- flowWorkspace::gs_get_pop_paths(gh)
    if (.pkgenv$verbose) message("  Available paths: ", paste(all_paths, collapse = ", "))
    
    # For each component, find its path in the hierarchy
    component_refs <- sapply(component_names, function(comp_name) {
      # Search for exact match in population names
      matching_paths <- grep(paste0("/", comp_name, "$"), all_paths, value = TRUE)
      
      if (length(matching_paths) == 0) {
        if (is.null(deferred)) {
          warning("Could not find population '", comp_name, "' for logical gate '", node_name, "'\n",
                  "  Available populations: ", paste(all_paths, collapse = ", "))
        }
        return(NULL)
      }
      
      # Use the first matching path
      path <- matching_paths[1]
      if (.pkgenv$verbose) message("    Found: ", comp_name, " -> ", path)
      return(path)
    })
    
    # Remove NULLs
    component_refs <- component_refs[!sapply(component_refs, is.null)]
    
    if (length(component_refs) < length(component_names)) {
      if (!is.null(deferred)) {
        deferred$gates <- c(deferred$gates,
                            list(list(node = node, parent = parent)))
      } else {
        missing_components <- setdiff(component_names, names(component_refs))
        warning("Could not resolve all component paths for logical gate: ", node_name, "\n",
                "  Missing components: ", paste(missing_components, collapse = ", "), "\n",
                "  Resolved: ", paste(names(component_refs), collapse = ", "))
      }
      return()
    }
    
    # Clean paths - remove leading slash as per booleanFilter examples
    clean_refs <- gsub("^/", "", component_refs)
    
    # Build boolean expression - NO SPACES!
    if (operator == "and") {
      bool_expr <- paste(clean_refs, collapse = "&")  # No spaces
    } else if (operator == "or") {
      bool_expr <- paste(clean_refs, collapse = "|")  # No spaces
    } else if (operator == "not") {
      bool_expr <- paste0("!", clean_refs[1])  # No spaces
    } else {
      warning("Unknown logical operator '", operator, "' for gate: ", node_name,
              ". Expected 'and', 'or', or 'not'")
      return()
    }
    
    if (.pkgenv$verbose) message("  Boolean expression: ", bool_expr)
    tryCatch({
      # Use the programmatic approach from the documentation
      # Create as symbol and substitute into booleanFilter call
      call_expr <- substitute(booleanFilter(v), list(v = as.symbol(bool_expr)))
      bool_filter <- eval(call_expr)
      
      if (.pkgenv$verbose) message("  Created filter: ", class(bool_filter))
      
      flowWorkspace::gs_pop_add(
        gh,
        bool_filter,
        parent = parent,
        name = node_name
      )
      
      if (.pkgenv$verbose) message("  Successfully added logical gate: ", node_name)
      
      # Recompute immediately to verify it works
      # flowWorkspace::recompute(gh)
      # message("  Recomputed successfully")
      
    }, error = function(e) {
      warning("Failed to add logical gate '", node_name, "': ", e$message, "\n",
              "  Parent: ", paste(parent, collapse = " : "), "\n",
              "  Components: ", paste(component_refs, collapse = ", "), "\n",
              "  Expression: ", bool_expr)
    })
    
    # Recursively add children
    if (!is.null(node$children)) {
      for (child in node$children) {
        child_parent <- paste0(parent, "/", node_name)
        add_population_node(
          gh = gh,
          node = child,
          gates = gates,
          sample_uuid = sample_uuid,
          parent = child_parent,
          strip_comp_prefix = strip_comp_prefix,
          verbose = verbose,
          deferred = deferred
        )
      }
    }
  }  else{
    # And gate:
    # those are the populations where this definition should be applied to 
    node$pop_def$children$populations
    # Add population node
    #
    tryCatch({
      # for now we ignore tsne gates
      if(!startsWith(node_name[1], "tsne")){
        # name for quadrant should be of length 4
        if (.pkgenv$verbose) message("parent: ", parent, " ", node_name[1], "\n")
        # browser()
        # this seems to be working for the current case but should 
        if(inherits(gate_obj, "quadGate")){
          node_name = node_name[c(3,4,2,1)]
        }
        # quad gate is tried to be added multiple times.
        # Get flowFrame parameter names from the GatingHierarchy
        flowframe_params <- markernames(gh)
        gate_params <- flowCore::parameters(gate_obj)
        
        if (.pkgenv$verbose) {
          message("Verifying marker name consistency for gate: ", node_name[1])
          message("  Gate params: ", paste(gate_params, collapse = ", "))
          message("  FlowFrame params: ", paste(flowframe_params, collapse = ", "))
        }
        
        # Verify marker name consistency
        verification <- verify_gate_marker_names(
          gate_obj = gate_obj,
          flowframe_params = flowframe_params,
          gate_source = paste(node_name, collapse = "/")
        )
        
        if (!verification$valid && .pkgenv$verbose) {
          for (warn in verification$warnings) {
            message("  WARNING: ", warn)
          }
        }
        
        # Adjust gate transformations if needed
        gate_obj_adjusted <- adjust_gate_transformations(gh, gate_obj, strip_comp_prefix = strip_comp_prefix)
        
        # Verify marker names again after adjustment
        if (.pkgenv$verbose) {
          gate_params_adjusted <- flowCore::parameters(gate_obj_adjusted)
          message("  Gate params after adjustment: ", paste(gate_params_adjusted, collapse = ", "))
        }
        
        tryCatch({
          flowWorkspace::gs_pop_add(
            gh,
            gate = gate_obj_adjusted,
            parent = parent,
            name = node_name
          )
          if (.pkgenv$verbose) {
            message("  Successfully added gate: ", paste(node_name, collapse = "/"))
          }
        }, error = function(e) {
          # Ignore "already exists" errors - this can happen with quadGates
          # when the population was already added in a previous step
          if (grepl("already exists", e$message, ignore.case = TRUE)) {
            if (.pkgenv$verbose) {
              message("  Population already exists, skipping: ", paste(node_name, collapse = "/"))
            }
          } else {
            warning("Failed to add population '", paste(node_name, collapse = "/"), "': ", e$message, "\n",
                    "  Parent: ", paste(parent, collapse = " : "), "\n",
                    "  Gate type: ", class(gate_obj_adjusted)[1])
          }
        })
      }
      
      # Recursively add children
      if (!is.null(node$children)) {
        for (child in node$children) {
          parent = sub("^[^/]+/", "", child$parent)
          add_population_node(
            gh = gh,
            node = child,
            gates = gates,
            sample_uuid = sample_uuid,
            parent = parent,
            strip_comp_prefix = strip_comp_prefix,
            verbose = verbose,
            deferred = deferred
          )
        }
      }
    }, error = function(e) {
      warning("Failed to process gate for population '", paste(node_name, collapse = "/"), "': ", e$message, "\n",
              "  Parent: ", paste(parent, collapse = " : "), "\n",
              "  Sample UUID: ", sample_uuid)
    })
  }
}

