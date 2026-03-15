#' @title Population Functions for FlowJo v11
#' @name populations
#' @keywords internal
#' @importFrom flowWorkspace gs_pop_add gs_get_pop_paths gs_pop_get_gate recompute
NULL

#' Add Populations to GatingSet
#'
#' Adds population nodes and gates to GatingSet based on gating trees
#'
#' @param gs GatingSet object
#' @param gating_trees List of gating trees (one per sample)
#' @param gates List of gate objects
#' @param sample_uuids Vector of sample UUIDs
#' @keywords internal
#' @importFrom flowWorkspace gs_pop_add
add_populations_to_gatingset <- function(gs, gating_trees, gates, sample_uuids) {
  
  # Process each sample
  for (i in seq_along(sample_uuids)) {
    sample_uuid <- sample_uuids[i]
    tree <- gating_trees[[i]]
    gh <- gs[[i]]
    
    # Recursively add populations
    add_population_node(
      gh = gh,
      node = tree,
      gates = gates,
      sample_uuid = sample_uuid
    )
  }
}

#' Compare and adjust gate transformations to match gating hierarchy
#' @keywords internal
adjust_gate_transformations <- function(gh, gate_obj) {
  
  # Get transformations from gating hierarchy
  gh_trans <- flowWorkspace::gh_get_transformations(gh)
  
  # Get parameters from the gate
  gate_params <- flowCore::parameters(gate_obj)
  
  # Check if we need to adjust transformations
  needs_adjustment <- FALSE
  trans_to_apply <- list()
  
  for (param in gate_params) {
    # Get transformation from hierarchy
    gh_trans_func <- gh_trans[[param]]
    
    # Skip if no transformation in hierarchy
    if (is.null(gh_trans_func)) {
      next
    }
    
    # Get transformation type from hierarchy
    gh_trans_type <- attr(gh_trans_func, "type")
    
    # TODO:
    # not sure this is correct. But it seems to be working for the current case.
    # and I don't know how to create a flowjo space with different parameters.
    # If hierarchy has a transformation (not "none"), we need to apply it to gate coords
    if (!is.null(gh_trans_type)) {
      # Gate coordinates are in raw space, need to convert to transformed space
      needs_adjustment <- TRUE
      trans_to_apply[[param]] <- gh_trans_func
      
      if (.pkgenv$verbose) {
        message("Parameter '", param, "' needs adjustment:")
        message("  Gate coords in: raw data space")
        message("  Hierarchy expects: ", gh_trans_type, " transformed space")
      }
    }
  }
  
  # If no adjustment needed, return original gate
  if (!needs_adjustment) {
    return(gate_obj)
  }
  
  # Apply transformations to convert from raw space to transformed space
  gate_obj_adjusted <- apply_transforms_to_gate(gate_obj, trans_to_apply)
  
  return(gate_obj_adjusted)
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
add_population_node <- function(gh, node, gates, sample_uuid, parent = "root") {
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
        # browser()
        add_population_node(gh, child, gates, sample_uuid, parent = "root")
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
    # browser()
    warning("No gate found for population: ", node_name, " (sample: ", sample_uuid, ")\n",
            "parent:", parent,"\npop paths:\n")
    # ,
    # paste(gh_get_pop_paths(gh), collapse = "\n"))
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
        warning("Could not find population: ", comp_name)
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
      warning("Could not resolve all component paths for logical gate: ", node_name)
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
      warning("Unknown logical operator: ", operator)
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
      warning("Failed to add logical gate ", node_name, ": ", e$message)
      message("  Parent: ", parent)
      message("  Components: ", paste(component_refs, collapse = ", "))
      message("  Expression: ", bool_expr)
    })
    
    # Recursively add children
    if (!is.null(node$children)) {
      for (child in node$children) {
        child_parent <- paste0(parent, "/", node_name)
        add_population_node(gh, child, gates, sample_uuid, parent = child_parent)
      }
    }
  }  else{
    # And gate:
    # those are the populations where this definition should be applied to 
    node$pop_def$children$populations
    # Add population node
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
        # Replace the section where you add the gate with:
        transformations <- flowWorkspace::gh_get_transformations(gh)
        gate_params <- flowCore::parameters(gate_obj)
        
        if (.pkgenv$verbose) {
          message("Checking transformations for gate: ", node_name[1])
          print(str(transformations[gate_params]))
        }
        
        # Adjust gate transformations if needed
        gate_obj_adjusted <- adjust_gate_transformations(gh, gate_obj)
        
        # Add this debug code temporarily:
        transformations <- flowWorkspace::gh_get_transformations(gh)
        gate_params <- flowCore::parameters(gate_obj)
        
        # browser()
        tryCatch({
          flowWorkspace::gs_pop_add(
            gh,
            gate = gate_obj_adjusted,
            parent = parent,
            name = node_name
          )
        }, error = function(e) {
          warning("Failed to add population ", node_name, ": ", e$message)
        })
      }
      
      # Recursively add children
      if (!is.null(node$children)) {
        for (child in node$children) {
          parent = sub("^[^/]+/", "", child$parent)
          add_population_node(gh, child, gates, sample_uuid, parent = parent)
        }
      }
    }, error = function(e) {
      warning("something else went wrong ", node_name, ": ", e$message)
    })
  }
}

