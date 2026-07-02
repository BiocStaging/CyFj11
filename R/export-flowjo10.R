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

#' @title Export FlowJo v10 Workspace
#' @name export-flowjo10
#' @keywords internal
NULL

#' Export GatingSet to FlowJo v10 Workspace
#'
#' @param gating_set GatingSet object to export
#' @param output_path Path where the .xml file should be created
#' @param workspace_name Optional name for the workspace
#' @param fcs_root Optional base directory for FCS files. 
#'        If provided, URIs in the WSP will be calculated relative to this path 
#'        (or absolute paths rooted here). If NULL, uses the actual paths found in the GatingSet.
#' @return Logical indicating success
#' @export
export_flowjo10_workspace <- function(gating_set, output_path, workspace_name = NULL, fcs_root = NULL) {
  # Validate inputs
  if (missing(gating_set) || missing(output_path)) {
    stop("Missing required parameters: gating_set, output_path")
  }
  
  if (!is.character(output_path) || length(output_path) != 1) {
    stop("output_path must be a single character string")
  }
  
  # Check if gating_set is a valid GatingSet object
  if (!requireNamespace("flowWorkspace", quietly = TRUE)) {
    stop("flowWorkspace package required for GatingSet operations")
  }

  # Determine the directory for path calculations
  # If fcs_root is provided, we use it. Otherwise, we default to the WSP's directory 
  # to attempt relative paths, or use absolute paths from the GatingSet.
  target_fcs_dir <- if (!is.null(fcs_root)) {
    normalizePath(fcs_root, mustWork = FALSE)
  } else {
    dirname(normalizePath(output_path, mustWork = FALSE))
  }
  
  # Extract components from GatingSet
  samples_data <- extract_samples_from_gatingset_v10(gating_set, target_fcs_dir = target_fcs_dir)
  gates_data <- extract_gates_from_gatingset_v10(gating_set)
  populations_data <- extract_populations_from_gatingset_v10(gating_set, samples_data, gates_data)
  groups_data <- create_default_groups_v10(samples_data)
  
  # Generate workspace name if not provided
  if (is.null(workspace_name)) {
    workspace_name <- tools::file_path_sans_ext(basename(output_path))
  }

  # Generate XML content
  xml_content <- generate_flowjo10_xml(
    gating_set = gating_set,
    samples = samples_data,
    gates = gates_data,
    populations = populations_data,
    groups = groups_data,
    workspace_name = workspace_name,
    output_path = output_path,
    force_XSC_linear = TRUE
  )
  
  # Write to file
  result <- tryCatch({
    writeLines(xml_content, output_path)
    TRUE
  }, error = function(e) {
    warning("Failed to write FlowJo v10 workspace: ", e$message)
    FALSE
  })
  
  if (result) {
    message("Successfully exported FlowJo v10 workspace to: ", output_path)
  }
  
  return(result)
}

#' Extract Samples from GatingSet for FlowJo v10
#'
#' @param gating_set GatingSet object
#' @param target_fcs_dir The base directory that the WSP should assume the FCS files are in.
#' @return List of sample data
#' @keywords internal
extract_samples_from_gatingset_v10 <- function(gating_set, target_fcs_dir = NULL) {
  samples <- list()
  sample_names <- flowWorkspace::sampleNames(gating_set)
  
  for (i in seq_along(sample_names)) {
    sample_name <- sample_names[i]
    gh <- gating_set[[sample_name]]
    sample_id <- as.numeric(i)
    
    # Get original metadata
    keywords <- list()
    original_basename <- NA
    
    if (requireNamespace("flowCore", quietly = TRUE)) {
      tryCatch({
        keyword_list <- flowCore::keyword(gh)
        if (!is.null(keyword_list$FILENAME)) {
          # Just extract the filename (e.g., "sample01.fcs")
          original_basename <- basename(keyword_list$FILENAME)
        }
        # ... (extract other keywords) ...
        if (length(keyword_list) > 0) {
          if (is.list(keyword_list) && !is.null(names(keyword_list))) {
            keywords <- keyword_list
          } else if (is.vector(keyword_list) && !is.null(names(keyword_list))) {
            for (kw_name in names(keyword_list)) {
              keywords[[kw_name]] <- keyword_list[[kw_name]]
            }
          }
        }
      }, error = function(e) { warning("problem with keywords ", sample_name, "\n") })
    }
    
    # --- CONSTRUCT THE NEW URI ---
    final_uri <- NA
    
    if (!is.na(original_basename) && !is.null(target_fcs_dir)) {
      # Strategy: Construct the path as: target_fcs_dir / basename
      # This effectively "re-roots" the file path.
      
      # Option A: Absolute Path (Safe for network drives)
      # final_uri <- file.path(target_fcs_dir, original_basename)
      
      # Option B: Relative Path (Best for portability if WSP and FCS move together)
      # If target_fcs_dir is the same as the WSP dir, this becomes just "sample01.fcs"
      # We need to know where the WSP is to calculate relative. 
      # BUT, usually, if user provides fcs_root, they often want the WSP to point 
      # to that specific location absolutely, OR they expect the folder structure to match.
      
      # Let's assume the user wants the URI to be relative to the WSP file location,
      # BUT assuming the FCS file is located inside 'target_fcs_dir'.
      # This is tricky without knowing the WSP path here.
      
      # SIMPLER APPROACH for 'fcs_root':
      # If fcs_root is provided, we assume the FCS files are located there.
      # We construct the URI as: file:///path/to/fcs_root/sample01.fcs
      # OR if the user wants relative, they should ensure fcs_root matches the WSP dir.
      
      # Let's go with the most common use case for 'fcs_root':
      # The user wants the WSP to point to a specific standardized location.
      final_uri <- file.path(target_fcs_dir, original_basename)
      
       
    } 
    
    samples[[sample_id]] <- list(
      id = sample_id,
      name = sample_name,
      uri = final_uri,
      keywords = keywords,
      count = tryCatch({ nrow(flowCore::exprs(flowWorkspace::gh_pop_get_data(gh))) }, error = function(e) 0)
    )
  }
  return(samples)
}
#' Extract Gates from GatingSet for FlowJo v10
#'
#' @param gating_set GatingSet object
#' @return List of gate data in FlowJo v10 format
#' @keywords internal
extract_gates_from_gatingset_v10 <- function(gating_set) {
  # Initialize gates list and lookup table
  gates <- list()
  id_lookup <- list()  # Maps pop_path to FlowJo ID
  id_counter <- as.integer(Sys.time())  # Starting point for IDs
  
  # Helper function to generate FlowJo-style ID
  generate_flowjo_id <- function() {
    id_counter <<- id_counter + 1
    return(paste0("ID", id_counter))
  }
  
  # Helper function to get or create FlowJo ID for a sample/population combination
  get_or_create_flowjo_id <- function(sample_name, pop_path) {
    lookup_key <- paste0(sample_name, "::", pop_path)
    
    if (!lookup_key %in% names(id_lookup)) {
      id_lookup[[lookup_key]] <<- generate_flowjo_id()
    }
    
    return(id_lookup[[lookup_key]])
  }

  # Get all population paths
  sample_names <- flowWorkspace::sampleNames(gating_set)
  
  if (length(sample_names) > 0) {
    # Process all samples to collect gates
    for (i in seq_along(sample_names)) {
      sample_name <- sample_names[i]
      gh <- gating_set[[sample_name]]
      # Get population paths for this sample
      pop_paths <- tryCatch({
        flowWorkspace::gs_get_pop_paths(gh, path = "auto")
      }, error = function(e) {
        warning("Failed to get population paths for sample ", sample_name, ": ", e$message)
        character(0)
      })

      # Extract gate information for each population
      for (pop_path in pop_paths) {
        if (pop_path == "root") {
          # Skip root population as it doesn't have a gate, but add to lookup
          get_or_create_flowjo_id(sample_name, pop_path)
          next
        }
        tryCatch({
          # Get gate object
          gate_list <- flowWorkspace::gs_pop_get_gate(gh, pop_path)
          if (length(gate_list) > 0) {
            gate <- gate_list[[1]]
            # Convert flowCore gate to FlowJo v10 format
            gate_definition <- convert_gate_to_flowjo10_format(gate, pop_path, gh)
            
            if (!is.null(gate_definition)) {
              # Generate internal gate ID (for reference)
              gate_id <- paste0("gate_", sample_name, "_", gsub("/", "_", pop_path))
              
              # Create lookup key
              lookup_key <- paste0(sample_name, "::", pop_path)
              
              # Generate or retrieve FlowJo ID
              flowjo_id <- get_or_create_flowjo_id(sample_name, pop_path)
              
              # Get parent information
              parent_path <- flowWorkspace::gh_pop_get_parent(gh, pop_path, path = "auto")
              parent_flowjo_id <- get_or_create_flowjo_id(sample_name, parent_path)
              
              # Store gate with both IDs
              gates[[gate_id]] <- list(
                id = flowjo_id,                    # FlowJo-style ID
                internal_id = gate_id,             # Internal reference ID
                parent = parent_path,
                parent_id = parent_flowjo_id,      # FlowJo-style parent ID
                name = pop_path,         # Gate name (without path)
                population_path = pop_path,        # Full path
                sample_id = as.integer(i),
                sample_name = sample_name,
                definition = gate_definition,
                lookup_key = lookup_key            # For debugging/reference
              )
            }
          }
        }, error = function(e) {
          warning("Failed to extract gate for population ", pop_path, ": ", e$message)
        })
      }
    }
  }
  
  # Return both gates and lookup table
  return(list(
    gates = gates,
    id_lookup = id_lookup
  ))
}

#' Extract Populations from GatingSet for FlowJo v10
#'
#' @param gating_set GatingSet object
#' @param samples_data Sample data
#' @param gates_data Gate data
#' @return List of population data in FlowJo v10 format
#' @keywords internal
extract_populations_from_gatingset_v10 <- function(gating_set, samples_data, gates_data) {
  # Initialize populations list
  populations <- list()
  
  # Get sample information
  sample_names <- flowWorkspace::sampleNames(gating_set)
  
  # Extract population information for each sample
  for (i in seq_along(samples_data)) {
    sample_name <- sample_names[i]
    sample_data <- samples_data[[i]]
    sample_id <- sample_data$id
    gh <- gating_set[[sample_name]]
    
    # Get population paths
    pop_paths <- tryCatch({

      flowWorkspace::gs_get_pop_paths(gh, path = "auto")
    }, error = function(e) {
      warning("Failed to get population paths for sample ", sample_name, ": ", e$message)
      character(0)
    })
    
    # Extract population information
    for (pop_path in pop_paths) {
      # Get parent population path
      # cat(file = stderr(), pop_path,"\n")
      parent_path = "root"
      if(pop_path != "root"){
        parent_path <- trimws(flowWorkspace::gs_pop_get_parent(gh, pop_path, path = "auto"))
      }
      # Count cells in population
      nCells <- tryCatch({
        gh_pop_get_count(gh, pop_path)
      }, error = function(e) {
        0
      })
      
      # Generate population ID
      pop_id <- paste0("pop_", sample_id, "_", gsub("/", "_", pop_path))
      
      # Find corresponding gate if not root
      gate_id <- NULL
      if (pop_path != "root") {
        gate_id <- paste0("gate_", sample_name, "_", gsub("/", "_", pop_path))
      }
      
      populations[[pop_id]] <- list(
        id = pop_id,
        name = if (pop_path == "root") "Ungated" else pop_path,
        sample_id = sample_id,
        parent_path = parent_path,
        gate_id = gate_id,
        count = nCells
      )
    }
  }
  
  return(populations)
}

#' Create Default Groups for FlowJo v10
#'
#' @param samples List of sample data
#' @return List of group data in FlowJo v10 format
#' @keywords internal
create_default_groups_v10 <- function(samples) {
  # Create a default "All Samples" group
  groups <- list()
  
  # Get all sample IDs
  sample_ids <- sapply(samples, function(s) s$id)
  
  groups[["all_samples"]] <- list(
    name = "All Samples",
    sample_ids = sample_ids,
    criteria = list(
      list(
        connector = "And",
        keyword = "",
        "function" = "Contains",
        value = ""
      )
    )
  )
  
  return(groups)
}

#' Convert flowCore Gate to FlowJo v10 Format
#'
#' @param gate flowCore gate object
#' @param pop_name Population name
#' @return List representing gate in FlowJo v10 format
#' @keywords internal
convert_gate_to_flowjo10_format <- function(gate, pop_name, gh = NULL) {
  # Handle different gate types
  if (requireNamespace("flowCore", quietly = TRUE)) {
    gate_class <- class(gate)[1]
    if (methods::is(gate, "rectangleGate")) {
      return(convert_rectangle_to_flowjo10(gate, pop_name, gh))
    } else if (methods::is(gate, "polygonGate")) {
      return(convert_polygon_to_flowjo10(gate, pop_name, gh))
    } else if (methods::is(gate, "ellipsoidGate")) {
      return(convert_ellipsoid_to_flowjo10(gate, pop_name, gh))
    } else if (methods::is(gate, "booleanFilter")) {
      return(convert_boolean_to_flowjo10(gate, pop_name, gh))
    } else {
      warning("Unsupported gate type for population: ", pop_name, " (class: ", gate_class, ")")
      return(NULL)
    }
  }
  

    return(NULL)
}

#' Get Transform Specification for Export
#'
#' Extracts transformation specification from gating hierarchy for export
#' to FlowJo format. Handles biexponential, linear, log, logicle, and arcsinh.
#'
#' @param gh GatingHierarchy object
#' @param dim Character string naming the channel (e.g. "FITC-A")
#' @return Named list representing FlowJo transformation specification, or NULL
#' @keywords internal
get_transform_spec <- function(gh, dim = "SSC-A") {
  trans_list <- gh_get_transformations(gh)
  
  if (is.null(trans_list) || length(trans_list) == 0) {
    if (.pkgenv$verbose) warning("No transformations found in gating hierarchy for dimension ", dim)
    return(NULL)
  }
  
  trans <- trans_list[[dim]]
  
  if (is.null(trans)) {
    # No transformation recorded → treat as linear passthrough
    return(list(
      transformType = "Linear",
      minRange = -Inf,
      maxRange = Inf
    ))
  }
  
  params <- attributes(trans)
  
  if (is.null(params) || is.null(params$type)) {
    return(NULL)
  }
  
  type <- params$type
  p    <- params$parameters  # may be NULL for some types
  
  # --- biexponential ---
  if (type == "biexp") {
    return(list(
      transformType   = "Biex",
      T               = p$maxValue,
      A               = p$neg,
      M               = p$pos,
      W               = p$widthBasis,
      vectorLength    = p$channelRange,
      autoWidthBasis  = FALSE
    ))
  }
  
  # --- linear ---
  if (type == "linear") {
    return(list(
      transformType = "Linear",
      minRange      = p$minRange,
      maxRange      = p$maxRange
    ))
  }
  
  # --- log (includes logtGml2) ---
  if (type %in% c("log", "logtGml2")) {
    return(list(
      transformType = "Log",
      base          = p$base   %||% 10,
      offset        = p$offset %||% 1,
      decade        = p$decade %||% 1
    ))
  }
  
  # --- logicle ---
  if (type == "logicle") {
    return(list(
      transformType = "Logicle",
      T = p$t %||% p$T %||% 262144,
      M = p$m %||% p$M %||% 4.5,
      W = p$w %||% p$W %||% 0.5,
      A = p$a %||% p$A %||% 0
    ))
  }
  
  # --- arcsinh / fasinh ---
  if (type %in% c("fasinh", "arcsinh")) {
    return(list(
      transformType = "Arcsinh",
      a = p$a %||% 0,
      b = p$b %||% (1 / 150),
      c = p$c %||% 0
    ))
  }
  
  # --- unsupported ---
  warning("Unsupported transformation type: ", type, " for dimension ", dim)
  NULL
}

#' Collect all channel names referenced by gates in the workspace
#'
#' @param gates Gate data list as returned by \code{extract_gates_from_gatingset_v10}
#' @return Character vector of unique channel names referenced by gates.
#' @keywords internal
get_referenced_channels <- function(gates) {
  channels <- character(0)
  if (is.null(gates) || is.null(gates$gates)) {
    return(channels)
  }
  for (gate in gates$gates) {
    def <- gate$definition
    if (is.null(def)) next
    dims <- def$dimensions
    if (!is.null(dims)) {
      for (dim in dims) {
        if (!is.null(dim$parameter)) {
          channels <- c(channels, dim$parameter)
        }
      }
    }
    if (!is.null(def$x_param)) channels <- c(channels, def$x_param)
    if (!is.null(def$y_param)) channels <- c(channels, def$y_param)
  }
  unique(channels)
}

#' Format Gate Value for XML Output
#'
#' Formats gate values for XML output, replacing Inf with appropriate values
#' and rounding to appropriate precision.
#'
#' @param val Gate value
#' @param channel_max Maximum channel value (default 262144)
#' @return Formatted value
#' @keywords internal
format_gate_value <- function(val, channel_max = 262144) {
  if (is.infinite(val) && val > 0) return(channel_max)
  if (is.infinite(val) && val < 0) return(0)
  return(val)
}

#' Safely get graph axis parameters for a population
#'
#' Walks the hierarchy to find appropriate axes for the graph display.
#' Handles boolean gates (no parameters) by checking children, self, parent.
#'
#' @param gh GatingHierarchy
#' @param pop_path Population path
#' @return Character vector of length 1-2 with channel names
#' @keywords internal
get_graph_axes <- function(gh, pop_path) {
  
  # Strategy: try children first, then self, then parent, then defaults
  candidates <- character(0)
  
  # 1. Try children of this population
  children <- tryCatch(gh_pop_get_children(gh, pop_path), error = function(e) character(0))
  for (ch in children) {
    gate <- tryCatch(gh_pop_get_gate(gh, ch), error = function(e) NULL)
    if (!is.null(gate) && !methods::is(gate, "booleanFilter")) {
      dims <- tryCatch(parameters(gate), error = function(e) NULL)
      if (!is.null(dims) && length(dims) >= 1) return(dims)
    }
  }
  
  # 2. Try self
  if (pop_path != "root") {
    gate <- tryCatch(gh_pop_get_gate(gh, pop_path), error = function(e) NULL)
    if (!is.null(gate) && !methods::is(gate, "booleanFilter")) {
      dims <- tryCatch(parameters(gate), error = function(e) NULL)
      if (!is.null(dims) && length(dims) >= 1) return(dims)
    }
  }
  
  # 3. Try parent
  if (pop_path != "root") {
    parent <- tryCatch(gh_pop_get_parent(gh, pop_path, path = "auto"), error = function(e) "root")
    if (parent != "root") {
      gate <- tryCatch(gh_pop_get_gate(gh, parent), error = function(e) NULL)
      if (!is.null(gate) && !methods::is(gate, "booleanFilter")) {
        dims <- tryCatch(parameters(gate), error = function(e) NULL)
        if (!is.null(dims) && length(dims) >= 1) return(dims)
      }
    }
  }
  
  # 4. Default fallback
  return(c("FSC-A", "SSC-A"))
}

#' Convert Rectangle Gate to FlowJo v10 Format
#' @keywords internal
convert_rectangle_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
  
  # ---- extract parameters --------------------------------------------------
  params <- NULL
  if (!is.null(gate@parameters)) {
    params <- names(gate@parameters)
  }
  
  min_vals <- gate@min
  max_vals <- gate@max
  
  # ---- validate ------------------------------------------------------------
  if (is.null(params) || is.null(min_vals) || is.null(max_vals)) {
    return(NULL)
  }
  if (length(params) != length(min_vals) || length(params) != length(max_vals)) {
    return(NULL)
  }
  
  # ---- apply inverse transformations (if gating hierarchy supplied) ---------
  if (!is.null(gh) ) {

    # Fetch once for non-log types (log closures from gh_get_transformations
    # are broken — they capture `t` as base::t() instead of the numeric param).
    trans_list     <- gh_get_transformations(gh, inverse = TRUE)
    valid_log_args <- c("decade", "offset", "scale", "n", "equal.space")

    .apply_inverse_val <- function(val, param_name) {
      spec <- get_transform_spec(gh, param_name)
      if (is.null(spec)) return(val)
      switch(
        spec$transformType,
        "Linear" = val,
        # "Log"        = ,
        # "logtGml2"   = ,
        "flowJo_log" = {
          log_spec <- spec[names(spec) %in% valid_log_args]
          tt <- create_log_transform(spec = log_spec)
          tt$inverse(val)
        },
        {
          inv_fn <- trans_list[[param_name]]
          if (is.function(inv_fn)) inv_fn(val) else val
        }
      )
    }

    for (i in seq_along(params)) {
      min_vals[i] <- .apply_inverse_val(min_vals[i], params[i])
      max_vals[i] <- .apply_inverse_val(max_vals[i], params[i])
    }
  }
  
  # ---- build output --------------------------------------------------------
  if (length(params) == 1) {
    return(list(
      type = "rectangle",
      dimensions = list(
        list(parameter = params[1], min = min_vals[1], max = max_vals[1])
      )
    ))
  } else if (length(params) >= 2) {
    return(list(
      type = "rectangle",
      dimensions = list(
        list(parameter = params[1], min = min_vals[1], max = max_vals[1]),
        list(parameter = params[2], min = min_vals[2], max = max_vals[2])
      )
    ))
  }
  
  NULL
}


#' Convert Polygon Gate to FlowJo v10 Format
#' @keywords internal
convert_polygon_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
  
  # ---- extract parameters --------------------------------------------------
  params <- NULL
  if (!is.null(gate@parameters)) {
    params <- names(gate@parameters)
  }
  
  vertices <- NULL
  if (!is.null(gate@boundaries)) {
    vertices <- gate@boundaries
  }
  
  # ---- validate ------------------------------------------------------------
  if (is.null(params) || length(params) < 2 ||
      is.null(vertices)  || nrow(vertices)  < 3) {
    return(NULL)
  }
  
  x_coords <- vertices[, 1]
  y_coords <- vertices[, 2]
  
  # ---- apply inverse transformations (if gating hierarchy supplied) ---------
  if (!is.null(gh) && requireNamespace("flowWorkspace", quietly = TRUE)) {
    
    # Fetch once.  Log-type closures inside this list are broken (see below),
    # but we avoid calling them — they are only referenced for other types.
    trans_list <- gh_get_transformations(gh, inverse = TRUE)
    
    # Valid args for create_log_transform / flowjo_log_trans
    valid_log_args <- c("decade", "offset", "scale", "n", "equal.space")
    
    .apply_inverse <- function(coords, param_name) {
      spec <- get_transform_spec(gh, param_name)
      
      if (is.null(spec)) return(coords)
      
      switch(
        spec$transformType,
        
        # Linear — no back-transformation needed.
        "Linear" = coords,
        
        # Log types: broken gh_get_transformations closure (t → base::t()).
        # Reconstruct via create_log_transform / flowjo_log_trans instead.
        "Log"        = ,
        "logtGml2"   = ,
        "flowJo_log" = {
          log_spec <- spec[names(spec) %in% valid_log_args]
          tt <- create_log_transform(spec = log_spec)
          tt$inverse(coords)
        },
        
        # All other non-linear types: gh_get_transformations is correct.
        "Biex"    = ,
        "Logicle" = ,
        "Arcsinh" = ,
        "fasinh"  = {
          inv_fn <- trans_list[[param_name]]
          if (is.function(inv_fn)) inv_fn(coords) else coords
        },
        
        # Unknown / unsupported type — leave coordinates unchanged.
        coords
      )
    }
    
    x_coords <- .apply_inverse(x_coords, params[1])
    y_coords <- .apply_inverse(y_coords, params[2])
  }
  
  # ---- build vertex list ---------------------------------------------------
  vertex_list <- lapply(seq_along(x_coords), function(i) {
    list(x = x_coords[i], y = y_coords[i])
  })
  
  # ---- return ---------------------------------------------------------------
  list(
    type = "polygon",
    dimensions = list(
      list(parameter = params[1], values = x_coords),
      list(parameter = params[2], values = y_coords)
    ),
    vertices = vertex_list
  )
}


#' Convert Ellipsoid Gate to FlowJo v10 Format
#'
#' @param gate ellipsoidGate object
#' @param pop_name Population name
#' @return List representing ellipsoid gate in FlowJo v10 format
#' @keywords internal
convert_ellipsoid_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
  # Get parameters
  params <- tryCatch({
    flowCore::parameters(gate)
  }, error = function(e) {
    NULL
  })
  # browser()
  if (is.null(params) || length(params) < 2) {
    return(NULL)
  }
  # browser()
  # Get ellipse parameters
  mean_vals <- tryCatch({
    gate@mean
  }, error = function(e) {
    return(NULL)
  })
  
  cov_mat <- tryCatch({
    gate@cov
  }, error = function(e) {
    return(NULL)
  })
  
  # Get distance parameter (Mahalanobis distance)
  distance <- tryCatch({
    gate@distance
  }, error = function(e) {
    1  # Default to 1 if not available
  })
  
  if (is.null(mean_vals) || is.null(cov_mat)) {
    return(NULL)
  }
  
  # Extract parameters
  x_param <- params[1]
  y_param <- params[2]
  center_x <- mean_vals[1]
  center_y <- mean_vals[2]
  
  # Calculate eigenvalues and eigenvectors
  eigen_decomp <- eigen(cov_mat)
  eigenvals <- eigen_decomp$values
  eigenvecs <- eigen_decomp$vectors
  
  # Calculate rotation angle
  major_axis_vec <- eigenvecs[, 1]
  rotation_angle_rad <- atan2(major_axis_vec[2], major_axis_vec[1])

  # Calculate semi-major and semi-minor axes
  # Use sqrt(distance) because Mahalanobis distance is already squared in the formula
  semi_major <- sqrt(eigenvals[1]) * distance
  semi_minor <- sqrt(eigenvals[2]) * distance
  
  # Calculate distance between foci
  c <- sqrt(abs(semi_major^2 - semi_minor^2))
  
  # Calculate the two foci positions (along major axis)
  focus1_x <- center_x + c * cos(rotation_angle_rad)
  focus1_y <- center_y + c * sin(rotation_angle_rad)
  focus2_x <- center_x - c * cos(rotation_angle_rad)
  focus2_y <- center_y - c * sin(rotation_angle_rad)
  
  # Calculate edge points - these should be at 0°, 90°, 180°, 270° on the rotated ellipse
  # Rightmost point (0°)
  edge1_x <- center_x + semi_major * cos(rotation_angle_rad)
  edge1_y <- center_y + semi_major * sin(rotation_angle_rad)
  
  # Topmost point (90°) - perpendicular to major axis
  edge2_x <- center_x - semi_minor * sin(rotation_angle_rad)
  edge2_y <- center_y + semi_minor * cos(rotation_angle_rad)
  
  # Leftmost point (180°)
  edge3_x <- center_x - semi_major * cos(rotation_angle_rad)
  edge3_y <- center_y - semi_major * sin(rotation_angle_rad)
  
  # Bottommost point (270°)
  edge4_x <- center_x + semi_minor * sin(rotation_angle_rad)
  edge4_y <- center_y - semi_minor * cos(rotation_angle_rad)
  
  
  # FlowJo v10 ellipse gates use normalized display coordinates
  # Need to convert from data space to display space using transform range
  if (!is.null(gh)) {
    transF <- gh_get_transformations(gh, inverse = TRUE)
    # Get the display ranges that WILL BE WRITTEN to the XML
    x_range <- get_display_range(gh, x_param)
    y_range <- get_display_range(gh, y_param)
    
    # Helper function using these ranges
    valid_log_args <- c("decade", "offset", "scale", "n", "equal.space")
    
    to_display_coords <- function(value, range_vals, param) {
      if (!is.null(transF[[param]])) {
        # Transformed channel: value is in the forward-transform output space.
        # Normalise to [0, 256] using the transform's output at raw ceiling.
        fwd_fn    <- fwdF[[param]]
        trans_max <- if (is.function(fwd_fn)) {
          out <- tryCatch(fwd_fn(262144), error = function(e) NA_real_)
          if (is.finite(out) && out > 0) out else 1.0
        } else {
          1.0   # arcsinh fallback: output range is [0, 1]
        }
        return((value / trans_max) * 256)
      } else {
        # Linear channel: normalise raw value by channel range
        min_val    <- range_vals[1]
        max_val    <- range_vals[2]
        range_span <- max_val - min_val
        if (range_span == 0) return(50)
        return(((value - min_val) / range_span) * 256)
      }
    }
    
    # Convert all x coordinates
    center_x <- to_display_coords(center_x, x_range, x_param)
    focus1_x  <- to_display_coords(focus1_x,  x_range, x_param)
    focus2_x  <- to_display_coords(focus2_x,  x_range, x_param)
    edge1_x   <- to_display_coords(edge1_x,   x_range, x_param)
    edge2_x   <- to_display_coords(edge2_x,   x_range, x_param)
    edge3_x   <- to_display_coords(edge3_x,   x_range, x_param)
    edge4_x   <- to_display_coords(edge4_x,   x_range, x_param)
    
    # Convert all y coordinates
    center_y <- to_display_coords(center_y, y_range, y_param)
    focus1_y  <- to_display_coords(focus1_y,  y_range, y_param)
    focus2_y  <- to_display_coords(focus2_y,  y_range, y_param)
    edge1_y   <- to_display_coords(edge1_y,   y_range, y_param)
    edge2_y   <- to_display_coords(edge2_y,   y_range, y_param)
    edge3_y   <- to_display_coords(edge3_y,   y_range, y_param)
    edge4_y   <- to_display_coords(edge4_y,   y_range, y_param)
  }
  
  # Recalculate distance in display space
  foci_distance <- sqrt((focus2_x - focus1_x)^2 + (focus2_y - focus1_y)^2)
  
  
  return(list(
    type = "ellipsoid",
    x_param = x_param,
    y_param = y_param,
    distance = foci_distance,
    foci = list(
      focus1 = list(x = focus1_x, y = focus1_y),
      focus2 = list(x = focus2_x, y = focus2_y)
    ),
    edge = list(
      list(x = edge1_x, y = edge1_y),  # major axis +
      list(x = edge3_x, y = edge3_y),  # major axis -
      list(x = edge2_x, y = edge2_y),  # minor axis +
      list(x = edge4_x, y = edge4_y)   # minor axis -
    )
  ))
}

#' Convert Boolean Gate to FlowJo v10 Format
#'
#' @param gate booleanFilter object
#' @param pop_name Population name
#' @param gh GatingHierarchy object
#' @return List representing boolean gate in FlowJo v10 format
#' @keywords internal
convert_boolean_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
  expr <- tryCatch({
    attr(gate, "expr")
  }, error = function(e) {
    warning("Failed to extract expression from boolean gate: ", pop_name)
    return(NULL)
  })
  
  if (is.null(expr)) return(NULL)
  
  expr_str <- if (is.character(expr)) expr else deparse(expr, width.cutoff = 500L)[1]
  
  expr_clean <- sub("^expression\\((.*)\\)$", "\\1", expr_str)
  expr_clean <- gsub("`", "", expr_clean)
  expr_clean <- trimws(expr_clean)
  
  resolve_full_path <- function(name) {
    if (!is.null(gh)) {
      tryCatch(
        sub("^/", "", flowWorkspace::gh_pop_get_full_path(gh, name)),
        error = function(e) { warning("Could not resolve full path for '", name, "'"); name }
      )
    } else { name }
  }
  
  resolve_parent_path <- function() {
    if (!is.null(gh)) {
      tryCatch({
        parent <- flowWorkspace::gh_pop_get_parent(gh, pop_name)
        if (identical(parent, "root")) "root"
        else sub("^/", "", flowWorkspace::gh_pop_get_full_path(gh, parent))
      }, error = function(e) {
        warning("Could not get parent for '", pop_name, "'; falling back to 'root'")
        "root"
      })
    } else { "root" }
  }
  
  parse_component <- function(comp) {
    comp    <- trimws(comp)
    negated <- startsWith(comp, "!")
    raw     <- if (negated) trimws(sub("^!", "", comp)) else comp
    list(name = resolve_full_path(raw), negated = negated)
  }
  
  if (grepl("&", expr_clean)) {
    parts  <- trimws(strsplit(expr_clean, "\\s*&+\\s*")[[1]])
    parts  <- parts[nzchar(parts)]
    parsed <- lapply(parts, parse_component)
    
    dep_names <- vapply(parsed, `[[`, character(1), "name")
    dep_neg   <- vapply(parsed, `[[`, logical(1),   "negated")
    
    # ── KEY FIX: "parent & !dep" is a FlowJo NotNode, not AndNode ──────────────
    non_neg_idx <- which(!dep_neg)
    neg_idx     <- which(dep_neg)
    if (length(non_neg_idx) == 1 && length(neg_idx) >= 1 && !is.null(gh)) {
      if (identical(dep_names[non_neg_idx], resolve_parent_path())) {
        return(list(
          type       = "boolean",
          op_type    = "not",
          expression = expr_str,
          dependents = dep_names[neg_idx],   # only the negated pop(s)
          negated    = rep(TRUE, length(neg_idx))
        ))
      }
    }
    
    return(list(
      type       = "boolean",
      op_type    = "and",
      expression = expr_str,
      dependents = dep_names,
      negated    = dep_neg
    ))
    
  } else if (grepl("\\|", expr_clean)) {
    parts  <- trimws(strsplit(expr_clean, "\\s*\\|+\\s*")[[1]])
    parts  <- parts[nzchar(parts)]
    parsed <- lapply(parts, parse_component)
    
    return(list(
      type       = "boolean",
      op_type    = "or",
      expression = expr_str,
      dependents = vapply(parsed, `[[`, character(1), "name"),
      negated    = vapply(parsed, `[[`, logical(1),   "negated")
    ))
    
  } else if (startsWith(expr_clean, "!")) {
    # ── KEY FIX: pure NOT — just the negated dep, no parent in dependents ───────
    dep_path <- resolve_full_path(trimws(sub("^!", "", expr_clean)))
    return(list(
      type       = "boolean",
      op_type    = "not",
      expression = expr_str,
      dependents = dep_path,   # single string, not c(parent, dep)
      negated    = TRUE
    ))
    
  } else {
    warning("Could not determine boolean operation type for: ", pop_name)
    return(NULL)
  }
}



#' Generate Logical Node XML (AndNode, OrNode, NotNode)
#'
#' @param gate Gate data containing boolean definition
#' @param pop_name Original population name (for fallback)
#' @param child_path Full path to the population
#' @param indent XML indentation string
#' @param gh GatingHierarchy object
#' @param gates Full gates list (for looking up dependent gates if needed)
#' @return Character vector of XML lines
#' @keywords internal
generate_logical_node_xml <- function(gate, pop_name, child_path, indent, gh, gates = NULL) {
  xml_lines <- character(0)
  def <- gate$definition
  
  if (is.null(def) || def$type != "boolean") {
    return(xml_lines)
  }
  # Determine node type
  node_type <- switch(def$op_type,
                      "and" = "AndNode",
                      "or" = "OrNode",
                      "not" = "NotNode",
                      "Population")
  
  if (node_type == "Population") {
    return(xml_lines)  # Fallback if unknown type
  }
  # browser()
  # Format display name according to FlowJo conventions
  display_name <- pop_name
  # if (length(def$dependents) > 0) {
  #   if (def$op_type == "and") {
  #     display_name <- paste0(paste0(def$dependents, collapse = "+ &amp; "), "+")
  #   } else if (def$op_type == "or") {
  #     display_name <- paste0(paste0(def$dependents, collapse = "+ or "), "+")
  #   } else if (def$op_type == "not") {
  #     display_name <- paste0(def$dependents[1], "-")
  #   }
  # }
  
  # Get event count
  count <- 0
  tryCatch({
    count <- flowWorkspace::gh_pop_get_count(gh, child_path)
  }, error = function(e) { })
  
  # Start node element
  xml_lines <- c(xml_lines,
                 sprintf('%s<%s name="%s" annotation="" owningGroup="" expanded="1" sortPriority="10" count="%d">',
                         indent, node_type, xml_encode(pop_name), count))
  
  # Add Graph for AndNode and OrNode (NotNode typically doesn't have one in the example)
  if (def$op_type %in% c("and", "or")) {
    # Try to get axes from first dependent
    axes <- tryCatch({
      get_graph_axes(gh, def$dependents[1])
    }, error = function(e) c("FSC-A", "SSC-A"))
    
    xml_lines <- c(xml_lines,
                   sprintf('%s  <Graph smoothing="0" backColor="#ffffff" foreColor="#000000" heatMapStatParameter="BUV395-A" type="Pseudocolor" fast="1">', indent),
                   sprintf('%s    <Axis dimension="x" name="%s" label="" auto="auto" />', indent, axes[1]),
                   sprintf('%s    <Axis dimension="y" name="%s" label="" auto="auto" />', indent, if(length(axes) > 1) axes[2] else ""),
                   sprintf('%s    <GraphSettings level="5%%" smoothingHighResolution="1" contourHighResolution="1" histogramSmoothingCount="0" graphResolution="256" showOutliers="0" drawLargeDots="0" dotsToDraw="8000" tint="le.chartfill.tinted.40" lineWeight="le.lineweight.normal" lineStyle="le.linestyle.solid" />', indent),
                   sprintf('%s    <GraphEnvironment showGrid="0" showAxes="tnlTNL" showGates="1" showFreqOnPlots="1" showGateNameOnPlots="1" showMedians="0" showUncomped="0" addEventParam="0" lastYAxisName="">', indent),
                   sprintf('%s      <TextTraits font="SansSerif" size="11" name="Labels" style="plain" color="#000000" background="#00ffffff" just="left" />', indent),
                   sprintf('%s      <TextTraits font="SansSerif" size="11" name="LayoutGates" style="plain" color="#000000" background="#00ffffff" just="left" />', indent),
                   sprintf('%s      <TextTraits font="SansSerif" size="9" name="Numbers" style="plain" color="#000000" background="#00ffffff" just="left" />', indent),
                   sprintf('%s      <TextTraits font="SansSerif" size="9" name="Legend" style="plain" color="#000000" background="#00ffffff" just="left" />', indent),
                   sprintf('%s      <WindowPosition x="247" y="-1415" width="390" height="679" displayed="0" panelState="---" />', indent),
                   sprintf('%s    </GraphEnvironment>', indent),
                   sprintf('%s  </Graph>', indent)
    )
  }
  
  # For NotNode, optionally include the gate definition from the dependent
  # (as shown in your example where NotNode contains a RectangleGate)
  if (def$op_type == "not" && !is.null(gates) && length(def$dependents) > 0 && !is.na(def$dependents[1])) {
    # Try to find the gate for the dependent population
    dep_name <- def$dependents[1]
    # Search for the gate in the gates list that belongs to this dependent
    for (g_id in names(gates$gates)) {
      g <- gates$gates[[g_id]]
      # browser()
      if (!is.na(g$name) && !is.na(dep_name) && 
          (g$name == dep_name || basename(g$population_path) == dep_name)) {
        # Found the dependent's gate, copy its definition
        if (!is.null(g$definition) && g$definition$type %in% c("rectangle", "polygon", "ellipsoid")) {
          # Add gate wrapper
          xml_lines <- c(xml_lines, sprintf('%s  <Gate gating:id="%s">', indent, xml_encode(gate$id)))
          
          gate_def <- g$definition
          if (gate_def$type == "rectangle") {
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:RectangleGate eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="Hairline" userDefined="1">', indent))
            for (dim in gate_def$dimensions) {
              xml_lines <- c(xml_lines,
                             sprintf('%s      <gating:dimension gating:min="%f" gating:max="%f" yRatio="0.5">', indent, dim$min, dim$max),
                             sprintf('%s        <data-type:fcs-dimension data-type:name="%s"/>', indent, xml_encode(dim$parameter)),
                             sprintf('%s      </gating:dimension>', indent))
            }
            xml_lines <- c(xml_lines, sprintf('%s    </gating:RectangleGate>', indent))
          }
          # Could add polygon/ellipsoid handling here too
          
          xml_lines <- c(xml_lines, sprintf('%s  </Gate>', indent))
        }
        break
      }
    }
  }
  
  # Add Dependents section
  xml_lines <- c(xml_lines, sprintf('%s  <Dependents>', indent))
  for (dep in def$dependents) {
    # message(xml_encode(dep))
    # browser()
    xml_lines <- c(xml_lines, sprintf('%s    <Dependent name="%s" />', indent, xml_encode(dep)))
  }
  xml_lines <- c(xml_lines, sprintf('%s  </Dependents>', indent))
  
  # Close node
  xml_lines <- c(xml_lines, sprintf('%s</%s>', indent, node_type))
  
  return(xml_lines)
}


#' Generate FlowJo v10 XML Content
#'
#' @param samples List of sample data
#' @param gates List of gate data
#' @param populations List of population data
#' @param groups List of group data
#' @param workspace_name Name of the workspace
#' @importFrom flowWorkspace gh_pop_get_data
#' @return Character string containing XML content
#' @keywords internal
generate_flowjo10_xml <- function(gating_set, samples, gates, populations, groups, workspace_name, output_path, force_XSC_linear=FALSE, minimal_fj11=FALSE) {

  if (minimal_fj11) {
    # Minimal FJ11 format - very simple structure
    xml_lines <- c(
      '<?xml version="1.0" encoding="UTF-8"?><Workspace flowJoVersion="10.10.0">',
      '<Matrices />'
    )
  } else {
    # Full FJ10 format with all attributes
    current_time <- format(Sys.time(), "%a %b %d %H:%M:%S %Z %Y")
    client_ts <- as.character(as.integer(as.numeric(Sys.time()) * 1000))

    xml_lines <- c(
      '<?xml version="1.0" encoding="UTF-8"?>',
      ' <Workspace',
      '   version="20.0"',
      sprintf('   modDate="%s"', current_time),
      sprintf('   clientTimestamp="%s"', client_ts),
      '   flowJoVersion="10.10.1"',
      '   drawRowBorders="1"',
      '   drawColumnBorders="1"',
      '   curGroup="All Samples"',
      '   groupPaneHeight="80"',
      '   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
      '   xmlns:gating="http://www.isac-net.org/std/Gating-ML/v2.0/gating"',
      '   xmlns:transforms="http://www.isac-net.org/std/Gating-ML/v2.0/transformations"',
      '   xmlns:data-type="http://www.isac-net.org/std/Gating-ML/v2.0/datatypes"',
      '   xsi:schemaLocation="http://www.isac-net.org/std/Gating-ML/v2.0/gating http://www.isac-net.org/std/Gating-ML/v2.0/gating/Gating-ML.v2.0.xsd http://www.isac-net.org/std/Gating-ML/v2.0/transformations http://www.isac-net.org/std/Gating-ML/v2.0/gating/Transformations.v2.0.xsd http://www.isac-net.org/std/Gating-ML/v2.0/datatypes http://www.isac-net.org/std/Gating-ML/v2.0/gating/DataTypes.v2.0.xsd "',
      sprintf('   nonAutoSaveFileName="file:%s"', xml_encode(output_path)),
      ' >'
    )
    # Add window position
    xml_lines <- c(xml_lines,
                   '   <WindowPosition x="100" y="100" width="800" height="600" displayed="1" panelState="" />'
    )

    # Add workspace-level TextTraits
    xml_lines <- c(xml_lines,
                   '   <TextTraits font="SansSerif" size="11" name="" style="plain" color="#000000" background="#00ffffff" just="left" />'
    )

    # Add Columns section
    xml_lines <- c(xml_lines,
                   '   <Columns>',
                   '     <TColumn width="371" >',
                   '       <Property key="fj.appnode.prop.name" />',
                   '     </TColumn>',
                   '     <TColumn width="211" >',
                   '       <Property key="fj.appnode.prop.statistic" />',
                   '     </TColumn>',
                   '     <TColumn width="210" >',
                   '       <Property key="fj.appnode.prop.ncells" />',
                   '     </TColumn>',
                   '   </Columns>'
    )

    # Add empty Matrices
    xml_lines <- c(xml_lines, '   <Matrices/>')

    # Add Cytometers section
    xml_lines <- c(xml_lines,
                   '   <Cytometers>',
                   '     <Cytometer name="GENERIC" cyt="" useFCS3="1" extraNegs="0" widthBasis="-10" linMin="0" logMin="1" linMax="10000" logMax="10000" linearRescale="1" logRescale="1" linFromKW="1" logFromKW="1" useGain="0" useTransform="0" transformType="LOG" manufacturer="" serialnumber="" homepage="workspaces-and-samples/flowjo-and-your-cytometer/ws-instrumentation/" icon="generic.png" >',
                   '       <LinParams>',
                   '         <Param>time</Param>',
                   '       </LinParams>',
                   '       <LogParams/>',
                   '       <FilterParams/>',
                   '       <TransformStore/>',
                   '     </Cytometer>',
                   '   </Cytometers>'
    )
  }

  # Add groups
  xml_lines <- c(xml_lines, '   <Groups>')
  # Add group nodes
  xml_lines <- c(xml_lines, '     <GroupNode name="All Samples" annotation="" owningGroup="All Samples" expanded="1" sortPriority="10" count="-1" >')
  xml_lines <- c(xml_lines, '       <Graph smoothing="0" backColor="#ffffff" foreColor="#000000" type="Pseudocolor" fast="1" >')
  xml_lines <- c(xml_lines, '         <Axis dimension="x" name="" label="" auto="auto" />')
  xml_lines <- c(xml_lines, '         <Axis dimension="y" name="" label="" auto="auto" />')
  xml_lines <- c(xml_lines, '         <GraphSettings level="5%" smoothingHighResolution="1" contourHighResolution="1" histogramSmoothingCount="0" graphResolution="256" showOutliers="0" drawLargeDots="0" dotsToDraw="8000" tint="le.chartfill.tinted.40" lineWeight="le.lineweight.normal" lineStyle="le.linestyle.solid" />')
  xml_lines <- c(xml_lines, '         <GraphEnvironment showGrid="0" showAxes="tnlTNL" showGates="1" showFreqOnPlots="1" showGateNameOnPlots="1" showMedians="0" showUncomped="0" addEventParam="0" lastYAxisName="" >')
  xml_lines <- c(xml_lines, '           <TextTraits font="SansSerif" size="11" name="Labels" style="plain" color="#000000" background="#00ffffff" just="left" />')
  xml_lines <- c(xml_lines, '           <TextTraits font="SansSerif" size="11" name="LayoutGates" style="plain" color="#000000" background="#00ffffff" just="left" />')
  xml_lines <- c(xml_lines, '           <TextTraits font="SansSerif" size="9" name="Numbers" style="plain" color="#000000" background="#00ffffff" just="left" />')
  xml_lines <- c(xml_lines, '           <TextTraits font="SansSerif" size="9" name="Legend" style="plain" color="#000000" background="#00ffffff" just="left" />')
  xml_lines <- c(xml_lines, '         </GraphEnvironment>')
  xml_lines <- c(xml_lines, '       </Graph>')
  xml_lines <- c(xml_lines, '       <Subpopulations>')
  subpop_xml <- generate_group_subpopulations_xml(populations = populations[names(populations)[startsWith(names(populations), "pop_1_")]],
                                                  gates = gates, 
                                                  parent_path = "root", 
                                                  indent = "      ",
                                                  visited_paths =  NULL)
  xml_lines <- c(xml_lines, subpop_xml)
  
  xml_lines <- c(xml_lines, '  </Subpopulations>')
  for (group_id in names(groups)) {
    group <- groups[[group_id]]
    xml_lines <- c(xml_lines,
                   sprintf('    <Group name="%s"  live="1"  role="ws.group.dlog.test"  key=""  synchronized="0"  foreground="#000000"  fontStyle="bold" >', group$name),
                   '      <Criteria/>',
                   '      <SampleRefs>'
    )
    
    # Add sample references
    for (sample_id in group$sample_ids) {
      xml_lines <- c(xml_lines, sprintf('        <SampleRef sampleID="%d"/>', sample_id))
    }
    
    xml_lines <- c(xml_lines,
                   '         </SampleRefs>',
                   '         <Keywords/>',
                   '       </Group>'
    )
  }
  xml_lines <- c(xml_lines, '     </GroupNode>')

  # Add Compensation group node
  xml_lines <- c(xml_lines,
                 '     <GroupNode name="Compensation" annotation="" owningGroup="Compensation" expanded="1" sortPriority="10" count="-1" >',
                 '       <Graph smoothing="0" backColor="#ffffff" foreColor="#000000" type="Pseudocolor" fast="1" >',
                 '         <Axis dimension="x" name="" label="" auto="auto" />',
                 '         <Axis dimension="y" name="" label="" auto="auto" />',
                 '         <GraphSettings level="5%" smoothingHighResolution="1" contourHighResolution="1" histogramSmoothingCount="0" graphResolution="256" showOutliers="0" drawLargeDots="0" dotsToDraw="8000" tint="le.chartfill.tinted.40" lineWeight="le.lineweight.normal" lineStyle="le.linestyle.solid" />',
                 '         <GraphEnvironment showGrid="0" showAxes="tnlTNL" showGates="1" showFreqOnPlots="1" showGateNameOnPlots="1" showMedians="0" showUncomped="0" addEventParam="0" lastYAxisName="" >',
                 '           <TextTraits font="SansSerif" size="11" name="Labels" style="plain" color="#000000" background="#00ffffff" just="left" />',
                 '           <TextTraits font="SansSerif" size="11" name="LayoutGates" style="plain" color="#000000" background="#00ffffff" just="left" />',
                 '           <TextTraits font="SansSerif" size="9" name="Numbers" style="plain" color="#000000" background="#00ffffff" just="left" />',
                 '           <TextTraits font="SansSerif" size="9" name="Legend" style="plain" color="#000000" background="#00ffffff" just="left" />',
                 '         </GraphEnvironment>',
                 '       </Graph>',
                 '       <Group name="Compensation" live="1" role="ws.group.dlog.compensation" key="" synchronized="0" foreground="#bc1900" fontStyle="bold" >',
                 '         <Criteria>',
                 '           <Criterion connector="And" keyword="$FIL" function="Contains" value="unstained" />',
                 '           <Criterion connector="Or" keyword="$FIL" function="Contains" value="comp" />',
                 '         </Criteria>',
                 '         <Keywords/>',
                 '       </Group>',
                 '     </GroupNode>'
  )

  xml_lines <- c(xml_lines, '   </Groups>')
  
  # Add sample list
  xml_lines <- c(xml_lines, '   <SampleList>')
  # Add samples (each containing DataSet, Transformations, Keywords, and SampleNode)
  for (sample_id in seq_along(samples)) {
    sample <- samples[[sample_id]]

    # Get gating hierarchy for this sample if available
    sample_gh <- NULL
    if (requireNamespace("flowWorkspace", quietly = TRUE)) {
      tryCatch({
        sample_gh <- gating_set[[sample$name]]
      }, error = function(e) {
        # Continue without sample_gh if not available
      })
    }

    xml_lines <- c(xml_lines,
                   sprintf('     <Sample>'),
                   sprintf('       <DataSet uri="file:%s" sampleID="%d" />',
                           xml_encode(sample$uri), sample_id)
    )
    # Transformations
    all_transforms = flowWorkspace::gh_get_transformations(sample_gh)
    # Only emit transformations for channels actually referenced by gates or axes.
    # This avoids forcing scatter channels to linear and matches FlowJo 11's
    # serialization behaviour, which drops unused channels from <Transformations>.
    referenced_channels <- get_referenced_channels(gates)
    transforms <- all_transforms[names(all_transforms) %in% referenced_channels]
    if (force_XSC_linear) {
      lin_trans = flowCore::linearTransform(transformationId = "defaultLin", a = 1, b = 0)
      # FlowJo 11 requires an explicit transformation for every channel used by a
      # gate. gh_get_transformations() only returns transforms that were
      # explicitly applied (e.g. log/biexp); linear scatter channels are omitted.
      # Ensure every referenced channel has at least a linear transform.
      for (marker in referenced_channels) {
        if (is.null(transforms[[marker]])) {
          transforms[[marker]] = lin_trans@.Data
          attr(transforms[[marker]], "type") = "Linear"
        }
      }
    }
    xml_lines <- c(xml_lines, '      <Transformations>')
    # browser()
    for (tr_idx in seq(transforms)) {
      atr_tr = attributes(transforms[[tr_idx]])
      channel = names(transforms)[tr_idx]
      # Get actual data range for this channel
      data_range <- tryCatch({
        # Get the flowFrame to ensure consistent data access
        fr <- gh_pop_get_data(sample_gh, "root")
        kw <- flowCore::keyword(fr)
        
        # Find which $PnN matches the channel name
        # keyword() returns a named list, so we compare values to channel
        param_matches <- which(sapply(kw, function(x) identical(as.character(x), channel)))
        
        if (length(param_matches) > 0) {
          # Get the parameter name (e.g., "$P6N") and extract number
          param_name <- names(param_matches)[1]  # Take first match if multiple
          param_num <- gsub("\\$|P|N", "", param_name)
          r_keyword <- paste0("$P", param_num, "R")
          
          if (!is.null(kw[[r_keyword]])) {
            max_val <- as.numeric(kw[[r_keyword]])
            min_val <- 0
            
            # Check for negative values in scatter channels
            if (grepl("FSC|SSC", channel, ignore.case = TRUE)) {
              data_vals <- flowCore::exprs(fr)[, channel]
              actual_min <- min(data_vals, na.rm = TRUE)
              if (actual_min < 0) {
                min_val <- actual_min
              }
            }
            
            # NO return() here - just the last expression
            c(min_val, max_val)
          } else {
            # Fallback: $PnR not found in keywords
            data_vals <- flowCore::exprs(fr)[, channel]
            c(min(data_vals, na.rm = TRUE), max(data_vals, na.rm = TRUE))
          }
        } else {
          # Fallback: channel name not found in $PnN keywords
          data_vals <- flowCore::exprs(fr)[, channel]
          c(min(data_vals, na.rm = TRUE), max(data_vals, na.rm = TRUE))
        }
        
      }, error = function(e) {
        # If anything fails, return default range
        c(0, 262144)
      })
      if(is.null(atr_tr$type)){
        atr_tr$type = "Linear"
      }
      switch(atr_tr$type,
             "biexp" = {
               # browser()
               type = "biex"
               param_str = sprintf("transforms:length=\"%d\" transforms:maxRange=\"%d\" transforms:neg=\"%d\" transforms:width=\"%d\" transforms:pos=\"%.8g\"",
                                   atr_tr$parameters$channelRange %>% as.integer(), 
                                   atr_tr$parameters$maxValue %>% as.integer(), 
                                   atr_tr$parameters$neg %>% as.integer(), 
                                   atr_tr$parameters$widthBasis %>% as.integer(), 
                                   atr_tr$parameters$pos)
               d_type_str = sprintf("<data-type:parameter data-type:name=\"%s\"/>",
                                    channel)
               
             },
             "log" = , "logtGml2" =, "flowJo_log" = {
               type = "log"
               fn_env <- environment(transforms[[tr_idx]])
               param_str = sprintf("transforms:offset=\"%d\" transforms:decades=\"%d\"",
                                   fn_env$m %||% fn_env$offset %||% 1 %>% as.integer(), 
                                   fn_env$n %||% fn_env$decade %||% 6.0 %>% as.integer())
               d_type_str = sprintf("<data-type:parameter data-type:name=\"%s\"/>",
                                    channel)
             },
             "fasinh" = {
               type = "fasinh"
               fn_env <- environment(transforms[[tr_idx]])
               # ls(envir = fn_env)
               param_str = sprintf("transforms:length=\"%d\" transforms:maxRange=\"262144\" transforms:T=\"%d\" transforms:A=\"%.0f\" transforms:M=\"%.0f\"  transforms:W=\"-%.0f\"",
                                   fn_env$length %>% as.integer(),
                                   fn_env$t, 
                                   fn_env$a,
                                   fn_env$m,
                                   fn_env$t)
               d_type_str = sprintf("<data-type:parameter data-type:name=\"%s\"/>",
                                    channel)
             },
             "Linear" = {
               type = "linear"
               data_range <- get_display_range(sample_gh, channel)
               param_str = sprintf("transforms:minRange=\"%.1f\" transforms:maxRange=\"%.1f\" gain=\"1\"",
                                   data_range[1], data_range[2])
               d_type_str = sprintf("<data-type:parameter data-type:name=\"%s\"/>", channel)
             },
             {
               
               warning("not implemented: ", atr_tr$type)
             }
      )
      
      xml_lines <- c(xml_lines,
                     sprintf('        <transforms:%s %s >\n          %s\n        </transforms:%s >',
                             xml_encode(type), 
                             xml_encode(param_str),
                             xml_encode(d_type_str),
                             xml_encode(type)
                     )
      )
    }
    xml_lines <- c(xml_lines, '      </Transformations>')
    
    
    # Add keywords
    xml_lines <- c(xml_lines, '      <Keywords>')
    for (kw_name in names(sample$keywords)) {
      xml_lines <- c(xml_lines,
                     sprintf('        <Keyword name="%s" value="%s"/>',
                             xml_encode(kw_name), xml_encode(sample$keywords[[kw_name]]))
      )
    }
    xml_lines <- c(xml_lines, '      </Keywords>')
    
    # Get root population count
    root_count <- sample$count  # default to sample count
    if (!is.null(sample_gh)) {
      root_count <- tryCatch({
        flowWorkspace::gh_pop_get_count(sample_gh, "root")
      }, error = function(e) {
        sample$count  # fallback to sample count
      })
    }
    # save(file = "generate_flowjo10_xml.debug.RData", list = ls())
    gate_dims = tryCatch({
      parameters(gh_pop_get_gate(sample_gh, gh_get_pop_paths(sample_gh)[2]))
    }, error = function(e) {
      NULL
    })
    # Only add y-axis if second dimension exists
    # Use $FIL keyword for sample name if available, otherwise use sample$name
    sample_display_name <- sample$keywords[["$FIL"]] %||% sample$name
    xml_lines <- c(xml_lines,
                   sprintf('       <SampleNode name="%s" annotation="" owningGroup="" expanded="1" sortPriority="10" count="%d" sampleID="%d" >',
                           xml_encode(sample_display_name), root_count, sample_id),
                   '         <Graph smoothing="0" backColor="#ffffff" foreColor="#000000" heatMapStatParameter="BUV395-A" type="Pseudocolor" fast="1" >',
                   sprintf('           <Axis dimension="x" name="%s" label="" auto="auto" />', if(is.null(gate_dims) || length(gate_dims) < 1) "FSC-A" else gate_dims[[1]])
    )
    # Always add y-axis - empty name for 1D gates
    xml_lines <- c(xml_lines,
                   sprintf('           <Axis dimension="y" name="%s" label="" auto="auto" />', if(is.null(gate_dims) || length(gate_dims) < 2) "" else gate_dims[[2]])
    )
    xml_lines <- c(xml_lines,
                   '           <GraphSettings level="5%" smoothingHighResolution="1" contourHighResolution="1" histogramSmoothingCount="0" graphResolution="256" showOutliers="0" drawLargeDots="0" dotsToDraw="8000" tint="le.chartfill.tinted.40" lineWeight="le.lineweight.normal" lineStyle="le.linestyle.solid" />',
                   '           <GraphEnvironment showGrid="0" showAxes="tnlTNL" showGates="1" showFreqOnPlots="1" showGateNameOnPlots="1" showMedians="0" showUncomped="0" addEventParam="0" lastYAxisName="" >',
                   '             <TextTraits font="SansSerif" size="11" name="Labels" style="plain" color="#000000" background="#00ffffff" just="left" />',
                   '             <TextTraits font="SansSerif" size="11" name="LayoutGates" style="plain" color="#000000" background="#00ffffff" just="left" />',
                   '             <TextTraits font="SansSerif" size="9" name="Numbers" style="plain" color="#000000" background="#00ffffff" just="left" />',
                   '             <TextTraits font="SansSerif" size="9" name="Legend" style="plain" color="#000000" background="#00ffffff" just="left" />',
                   '             <WindowPosition x="247" y="-1415" width="390" height="679" displayed="0" panelState="---" />',
                   '           </GraphEnvironment>',
                   '         </Graph>'
    )

    # Add sample-specific subpopulations using flowWorkspace functions
    if (requireNamespace("flowWorkspace", quietly = TRUE) && !is.null(sample_gh)) {
      xml_lines <- c(xml_lines, '         <Subpopulations>')

      # Generate subpopulations starting from root
      subpop_xml <- generate_sample_subpopulations_xml(
        sample_gh,
        gates,
        populations = populations[names(populations)[startsWith(names(populations), paste0("pop_", sample_id, "_"))]],
        "root",
        "           "
      )
      xml_lines <- c(xml_lines, subpop_xml)

      xml_lines <- c(xml_lines, '         </Subpopulations>')
    }

    xml_lines <- c(xml_lines, '       </SampleNode>', '     </Sample>')
  }

  xml_lines <- c(xml_lines, '   </SampleList>')

  # Add TableEditor section
  xml_lines <- c(xml_lines,
                 '   <TableEditor title="FlowJo Tables" current="Table" >',
                 '     <Table name="Table" outputFile="" color="#00ffffff" isBatch="0" quickclose="0" destination="toDisplay" outputFormat="fj.document.type.table" >',
                 '       <PrintLayout flipPattern0="0" rows="1" columns="1" padding="36" header="" footer="" headerActive="0" footerActive="0" scalingMode="fj.print.scale.none" scaling="1" orientation="1" width="595.2744" height="841.8888" imageableX="72" imageableY="72" imageableWidth="451.2744" imageableHeight="697.8888" />',
                 '       <PageSection sectionName="header" >&lt;table width=&quot;100%&quot;&gt;&lt;tr&gt;&lt;td align=&quot;left&quot; valign=&quot;top&quot;&gt;&amp;NBSP&amp;NBSP&amp;NBSP&amp;NBSP&lt;IMG SRC=&quot;file:/Applications/FlowJo.app/Contents/Resources/Java/images/fj_icon.png&quot;&gt;&lt;/IMG&gt;&lt;br/&gt;FlowJo, LLC&lt;/td&gt;&lt;td align=&quot;right&quot; valign=&quot;top&quot;&gt;Page &lt;PageNumber/&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;</PageSection>',
                 '       <PageSection sectionName="footer" >&lt;table width=&quot;100%&quot;&gt;&lt;tr&gt;&lt;td align=&quot;left&quot;  valign=&quot;bottom&quot;&gt;&lt;LongDate/&gt;&lt;/td&gt;&lt;td align=&quot;right&quot; valign=&quot;bottom&quot;&gt;&lt;Version/&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;</PageSection>',
                 '       <Iteration iterationType="SAMPLE" iterationValue="1" iterationKeyword="" discriminator="" panelSize="1" groupName="workspaceSelection" />',
                 '     </Table>',
                 '   </TableEditor>'
  )

  # Add LayoutEditor section
  xml_lines <- c(xml_lines,
                 '   <LayoutEditor title="FlowJo Layouts" current="Layout" showGrid="0" showPageBreaks="0" showGuides="0" showDebugOutput="0" >',
                 '     <Layout name="Layout" outputFile="" color="#00ffffff" isBatch="0" showGrid="0" showRulers="1" showDebugOutput="0" showGuides="0" showPageBreaks="1" scale="1" >',
                 '       <PrintLayout flipPattern0="0" rows="1" columns="1" padding="36" header="" footer="" headerActive="0" footerActive="0" scalingMode="fj.print.scale.none" scaling="1" orientation="1" width="595.2744" height="841.8888" imageableX="72" imageableY="72" imageableWidth="451.2744" imageableHeight="697.8888" />',
                 '       <PageSection sectionName="header" >&lt;table width=&quot;100%&quot;&gt;&lt;tr&gt;&lt;td align=&quot;left&quot; valign=&quot;top&quot;&gt;&amp;NBSP&amp;NBSP&amp;NBSP&amp;NBSP&lt;IMG SRC=&quot;file:/Applications/FlowJo.app/Contents/Resources/Java/images/fj_icon.png&quot;&gt;&lt;/IMG&gt;&lt;br/&gt;FlowJo, LLC&lt;/td&gt;&lt;td align=&quot;right&quot; valign=&quot;top&quot;&gt;Page &lt;PageNumber/&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;</PageSection>',
                 '       <PageSection sectionName="footer" >&lt;table width=&quot;100%&quot;&gt;&lt;tr&gt;&lt;td align=&quot;left&quot;  valign=&quot;bottom&quot;&gt;&lt;LongDate/&gt;&lt;/td&gt;&lt;td align=&quot;right&quot; valign=&quot;bottom&quot;&gt;&lt;Version/&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;</PageSection>',
                 '       <Iteration iterationType="OFF" iterationValue="1" iterationKeyword="" discriminator="" panelSize="1" groupName="workspaceSelection" />',
                 '       <BatchSettings useCurrentGroup="1" length="3" name="" order="ACROSS" direction="COLUMNS" append="0" destination="toLayout" separatePages="0" launchApp="1" header="0" footer="0" commandLineBatch="0" />',
                 '       <FigList/>',
                 '     </Layout>',
                 '     <WindowPosition x="0" y="3" width="900" height="600" />',
                 '   </LayoutEditor>'
  )

  # Add Scripts section
  xml_lines <- c(xml_lines,
                 '   <Scripts>',
                 '     <Script lang="text/javascript" name="New Script 		 " />',
                 '   </Scripts>'
  )

  # Add Experiment section
  xml_lines <- c(xml_lines,
                 '   <Experiment>',
                 '     <PlateModel name="Plate" color="#00ffffff" rows="8" columns="12" plateID="00000" expID="000-00000" format="Plate" showNEntries="1" peHeatmap="1" peShowEnums="1" peThickBorders="1" >',
                 '       <PrintLayout flipPattern0="0" rows="1" columns="1" padding="36" header="" footer="" headerActive="0" footerActive="0" scalingMode="fj.print.scale.none" scaling="1" orientation="1" width="595.2744" height="841.8888" imageableX="72" imageableY="72" imageableWidth="451.2744" imageableHeight="697.8888" />',
                 '     </PlateModel>',
                 '     <PlateEditorState>',
                 '       <KeywordList>',
                 '         <Keyword attribute="Assay" value="GFP Reporter" />',
                 '         <Keyword attribute="Time point" value="24hr" />',
                 '         <Keyword attribute="Treatment &quot;Drug A&quot;" value="10ug/L" />',
                 '       </KeywordList>',
                 '       <StagingArea>',
                 '         <StagingWell/>',
                 '         <StagingWell/>',
                 '         <StagingWell/>',
                 '         <StagingWell/>',
                 '       </StagingArea>',
                 '     </PlateEditorState>',
                 '   </Experiment>'
  )

  # Add Exports section
  xml_lines <- c(xml_lines, '   <Exports/>')

  # Add SOPS section
  xml_lines <- c(xml_lines, '   <SOPS/>')

  # Add NA section
  xml_lines <- c(xml_lines, '   <NA/>')

  # Add weights section
  xml_lines <- c(xml_lines, '   <weights/>')

  # Close workspace
  xml_lines <- c(xml_lines, ' </Workspace>')

  return(paste(xml_lines, collapse = "\n"))
}

#' Generate Sample Subpopulations XML
#'
#' Recursively generates XML for sample-specific population hierarchy
#'
#' @param gating_hierarchy Gating hierarchy object
#' @param gates List of gate data
#' @param populations List of population data
#' @param parent_path Parent population path (default "root")
#' @param indent Current indentation level for XML formatting
#' @return Character vector of XML lines
#' @keywords internal
generate_sample_subpopulations_xml <- function(gating_hierarchy, gates, populations, parent_path = "root", indent = "        ") {
  xml_lines <- character(0)
  # Get children of the current parent population using flowWorkspace function
  children_paths <- tryCatch({
    flowWorkspace::gs_pop_get_children(gating_hierarchy, parent_path, path="auto")
  }, error = function(e) {
    character(0)
  })
  # save(file = "generate_sample_subpopulations_xml.debug.RData", list = ls())

  # Process each child population
  for (child_path in children_paths) {
    # Get population name for display
    pop_display_name <- basename(child_path)
    
    # Find matching population in our data
    matching_pop <- NULL
    for (pop_id in names(populations)) {
      pop <- populations[[pop_id]]
      # Match by path
      if (pop$name == child_path) {
        matching_pop <- pop
        break
      }
    }
    
    # Get population count
    pop_count <- 0
    if (!is.null(matching_pop)) {
      pop_count <- matching_pop$count
    } else {
      # Try to get count directly from gating hierarchy
      tryCatch({
        pop_count <- flowWorkspace::gh_pop_get_count(gating_hierarchy, child_path)
      }, error = function(e) {
        # Ignore errors, keep count as 0
      })
    }

    # Check if this is a boolean gate
    is_boolean_gate <- FALSE
    if (!is.null(matching_pop) && !is.null(matching_pop$gate_id)) {
      gate_id <- matching_pop$gate_id
      if (gate_id %in% names(gates$gates)) {
        gate <- gates$gates[[gate_id]]
        if (!is.null(gate$definition) && gate$definition$type == "boolean") {
          is_boolean_gate <- TRUE
          # Generate logical node instead of Population
          logical_xml <- generate_logical_node_xml(
            gate = gate,
            pop_name = pop_display_name,
            child_path = child_path,
            indent = indent,
            gh = gating_hierarchy,
            gates = gates
          )
          xml_lines <- c(xml_lines, logical_xml)
          # Skip to next child - logical nodes don't have recursive subpopulations in this context
          next
        }
      }
    }
    # Continue with regular Population handling if not boolean
    if (!is_boolean_gate) {
      # Add population element with correct attributes
      xml_lines <- c(xml_lines,
                     sprintf('%s<Population name="%s" annotation="" owningGroup="All Samples" expanded="1" sortPriority="10" count="%d">',
                             indent, xml_encode(pop_display_name), pop_count)
      )
      
      # Add empty Graph element
      # xml_lines <- c(xml_lines, sprintf('%s  <Graph/>', indent))
      parent_path = gh_pop_get_parent(gating_hierarchy, child_path)
      
      grandchild_path = gh_pop_get_children(gating_hierarchy, child_path)[1]
      if(parent_path == "root"){
        parent_path = child_path
      }
      if(is.na(grandchild_path)){
        grandchild_path = child_path
      }
      gate_dims = tryCatch({
        parameters(gh_pop_get_gate(gating_hierarchy, grandchild_path))
      }, error = function(e) {
        NULL
      })
      xml_lines <- c(xml_lines,
                     '        <Graph smoothing="0" backColor="#ffffff" foreColor="#000000" heatMapStatParameter="BUV395-A" type="Pseudocolor" fast="1">',
                     sprintf('          <Axis dimension="x" name="%s" label="" auto="auto" />', if(is.null(gate_dims) || length(gate_dims) < 1) "FSC-A" else gate_dims[[1]])
      )
      # Always add y-axis - empty name for 1D gates
      xml_lines <- c(xml_lines,
                     sprintf('          <Axis dimension="y" name="%s" label="" auto="auto" />', if(is.null(gate_dims) || length(gate_dims) < 2) "" else gate_dims[[2]])
      )
      xml_lines <- c(xml_lines,
                     '          <GraphSettings level="5%" smoothingHighResolution="1" contourHighResolution="1" histogramSmoothingCount="0" graphResolution="256" showOutliers="0" drawLargeDots="0" dotsToDraw="8000" tint="le.chartfill.tinted.40" lineWeight="le.lineweight.normal" lineStyle="le.linestyle.solid" />',
                     '          <GraphEnvironment showGrid="0" showAxes="tnlTNL" showGates="1" showFreqOnPlots="1" showGateNameOnPlots="1" showMedians="0" showUncomped="0" addEventParam="0" lastYAxisName="">',
                     '            <TextTraits font="SansSerif" size="11" name="Labels" style="plain" color="#000000" background="#00ffffff" just="left" />',
                     '            <TextTraits font="SansSerif" size="11" name="LayoutGates" style="plain" color="#000000" background="#00ffffff" just="left" />',
                     '            <TextTraits font="SansSerif" size="9" name="Numbers" style="plain" color="#000000" background="#00ffffff" just="left" />',
                     '            <TextTraits font="SansSerif" size="9" name="Legend" style="plain" color="#000000" background="#00ffffff" just="left" />',
                     '            <WindowPosition x="247" y="-1415" width="390" height="582" displayed="0" panelState="---" />',
                     '          </GraphEnvironment>',
                     '        </Graph>'
      )
      
      # Add gate information if exists
      if (!is.null(matching_pop) && !is.null(matching_pop$gate_id)) {
        gate_id <- matching_pop$gate_id
        if (gate_id %in% names(gates$gates)) {
          gate <- gates$gates[[gate_id]]
          gating_parent_str = ""
          if(gate$parent != "root"){
            gating_parent_str = sprintf('gating:parent_id=\"%s\" ', gate$parent_id)
          }
          
          xml_lines <- c(xml_lines, sprintf('%s  <Gate gating:id=\"%s\" %s>', indent, gate$id, gating_parent_str))
          # Add gate definition based on type with proper attributes
          gate_def <- gate$definition
          if (gate_def$type == "rectangle") {
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:RectangleGate gating:id="%s" eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="1" userDefined="1" percentX="0" percentY="0">', indent, xml_encode(gate$id))
            )
            # yRatio is a display hint for histogram-style (1-D) gates. It should only
            # be emitted when the rectangle gate has a single dimension.
            is_1d_rect <- length(gate_def$dimensions) == 1L
            # Add dimensions
            for (dim in gate_def$dimensions) {
              if (is_1d_rect) {
                xml_lines <- c(xml_lines,
                               sprintf('%s      <gating:dimension gating:min="%f" gating:max="%f" yRatio="0.5">', indent, dim$min, dim$max),
                               sprintf('%s        <data-type:fcs-dimension data-type:name="%s"/>', indent, xml_encode(dim$parameter)),
                               sprintf('%s      </gating:dimension>', indent)
                )
              } else {
                xml_lines <- c(xml_lines,
                               sprintf('%s      <gating:dimension gating:min="%f" gating:max="%f">', indent, dim$min, dim$max),
                               sprintf('%s        <data-type:fcs-dimension data-type:name="%s"/>', indent, xml_encode(dim$parameter)),
                               sprintf('%s      </gating:dimension>', indent)
                )
              }
            }

            xml_lines <- c(xml_lines, sprintf('%s    </gating:RectangleGate>', indent))
          } else if (gate_def$type == "polygon") {
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:PolygonGate gating:id="%s" eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="1" userDefined="1" percentX="0" percentY="0">', indent, xml_encode(gate$id))
            )
            # Add dimensions
            for (dim in gate_def$dimensions) {
              xml_lines <- c(xml_lines,
                             sprintf('%s      <gating:dimension>', indent),
                             sprintf('%s        <data-type:fcs-dimension data-type:name="%s"/>', indent, xml_encode(dim$parameter)),
                             sprintf('%s      </gating:dimension>', indent)
              )
            }
            # Add vertices
            for (vertex in gate_def$vertices) {
              xml_lines <- c(xml_lines,
                             sprintf('%s      <gating:vertex>', indent),
                             sprintf('%s        <gating:coordinate data-type:value="%f"/>', indent, vertex$x),
                             sprintf('%s        <gating:coordinate data-type:value="%f"/>', indent, vertex$y),
                             sprintf('%s      </gating:vertex>', indent)
              )
            }
            
            xml_lines <- c(xml_lines, sprintf('%s    </gating:PolygonGate>', indent))
            
          } else if (gate_def$type == "ellipsoid") {
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:EllipsoidGate eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="Normal" userDefined="1" gating:distance="%f">', 
                                   indent, gate_def$distance)
            )
            
            # Add dimensions
            xml_lines <- c(xml_lines,
                           sprintf('%s      <gating:dimension>', indent),
                           sprintf('%s        <data-type:fcs-dimension data-type:name="%s" />', indent, xml_encode(gate_def$x_param)),
                           sprintf('%s      </gating:dimension>', indent),
                           sprintf('%s      <gating:dimension>', indent),
                           sprintf('%s        <data-type:fcs-dimension data-type:name="%s" />', indent, xml_encode(gate_def$y_param)),
                           sprintf('%s      </gating:dimension>', indent)
            )
            
            # Add foci
            xml_lines <- c(xml_lines,
                           sprintf('%s      <gating:foci>', indent),
                           sprintf('%s        <gating:vertex>', indent),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', indent, gate_def$foci$focus1$x),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', indent, gate_def$foci$focus1$y),
                           sprintf('%s        </gating:vertex>', indent),
                           sprintf('%s        <gating:vertex>', indent),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', indent, gate_def$foci$focus2$x),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', indent, gate_def$foci$focus2$y),
                           sprintf('%s        </gating:vertex>', indent),
                           sprintf('%s      </gating:foci>', indent)
            )
            
            # Add edge points
            xml_lines <- c(xml_lines, sprintf('%s      <gating:edge>', indent))
            for (edge_point in gate_def$edge) {
              xml_lines <- c(xml_lines,
                             sprintf('%s        <gating:vertex>', indent),
                             sprintf('%s          <gating:coordinate data-type:value="%f" />', indent, edge_point$x),
                             sprintf('%s          <gating:coordinate data-type:value="%f" />', indent, edge_point$y),
                             sprintf('%s        </gating:vertex>', indent)
              )
            }
            xml_lines <- c(xml_lines, sprintf('%s      </gating:edge>', indent))
            
            xml_lines <- c(xml_lines, sprintf('%s    </gating:EllipsoidGate>', indent))
          } else if (gate_def$type == "boolean") {
            # browser()
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:BooleanGate gating:id="%s" eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="1" userDefined="1">', indent, xml_encode(gate$id))
            )
            
            # Add parameter references if available
            if (!is.null(gate_def$parameters)) {
              for (param in gate_def$parameters) {
                xml_lines <- c(xml_lines,
                               sprintf('%s      <data-type:parameter data-type:name="%s" />', indent, xml_encode(param))
                )
              }
            }
            
            # Add expression if available
            if (!is.null(gate_def$expression)) {
              xml_lines <- c(xml_lines,
                             sprintf('%s      <gating:expression>%s</gating:expression>', indent, xml_encode(gate_def$expression))
              )
            }
            
            xml_lines <- c(xml_lines, sprintf('%s    </gating:BooleanGate>', indent))
          }
          xml_lines <- c(xml_lines, sprintf('%s  </Gate>', indent))
        }
      }
      
      # Recursively process child populations
      xml_lines <- c(xml_lines, sprintf('%s  <Subpopulations>', indent))
      subpop_xml <- generate_sample_subpopulations_xml(gating_hierarchy, gates, populations, child_path, paste0(indent, "    "))
      xml_lines <- c(xml_lines, subpop_xml)
      xml_lines <- c(xml_lines, sprintf('%s  </Subpopulations>', indent))
      
      # Close population element
      xml_lines <- c(xml_lines, sprintf('%s</Population>', indent))
    }
  }
  return(xml_lines)
}

#' Generate Group Node Subpopulations XML
#'
#' Recursively generates XML for group node population hierarchy
#'
#' @param populations List of population data
#' @param gates List of gate data
#' @param parent_path Parent population path (default "root")
#' @param indent Current indentation level for XML formatting
#' @param visited_paths Character vector to track visited paths (for cycle detection)
#' @param gh Optional GatingHierarchy object (for boolean gate processing)
#' @return Character vector of XML lines
#' @keywords internal
#' @importFrom magrittr %>%
generate_group_subpopulations_xml <- function(populations, gates, parent_path = "root",
                                              indent = "        ", visited_paths = NULL, 
                                              gh = NULL) {
  # Safety check to prevent infinite recursion
  if (is.null(visited_paths)) {
    visited_paths <- character(0)
  }
  
  # Check if we've already visited this parent_path (cycle detection)
  if (parent_path %in% visited_paths) {
    # cat(file = stderr(), "WARNING: Cycle detected in population hierarchy at parent_path='", parent_path, "'\n")
    return(character(0))
  }
  
  visited_paths <- c(visited_paths, parent_path)
  parent_path <- trimws(parent_path)
  
  xml_lines <- character(0)
  
  # Find all populations that have the current parent path
  child_populations <- list()
  for (pop_id in names(populations)) {
    pop <- populations[[pop_id]]
    if (pop$parent_path == parent_path) {
      child_populations[[pop_id]] <- pop
    }
  }
  
  # cat(file = stderr(), parent_path, ":", 
  #     sapply(child_populations, function(x) x$name) %>% unlist() %>% paste(collapse = " "), "\n")
  
  # Process each child population
  for (pop_id in names(child_populations)) {
    population <- child_populations[[pop_id]]
    

    if(population$name == "Ungated") 
      next()
    
    # Check if this is a boolean gate
    is_boolean_gate <- FALSE
    if (!is.null(population$gate_id) && population$gate_id %in% names(gates$gates)) {
      gate <- gates$gates[[population$gate_id]]
      if (!is.null(gate$definition) && gate$definition$type == "boolean") {
        is_boolean_gate <- TRUE
        
        # Generate logical node instead of Population
        # Use population$name as the path, and basename for display
        pop_display_name <- basename(population$name)
        
        logical_xml <- generate_logical_node_xml(
          gate = gate,
          pop_name = pop_display_name,
          child_path = population$name,
          indent = indent,
          gh = gh,
          gates = gates
        )
        xml_lines <- c(xml_lines, logical_xml)
        
        # Skip to next child - logical nodes don't have recursive subpopulations here
        next
      }
    }
    
    # Continue with regular Population handling if not boolean
    if (!is_boolean_gate) {
      
      # Add population element with correct attributes
      xml_lines <- c(xml_lines,
                     sprintf('%s<Population name="%s" annotation="" owningGroup="All Samples" expanded="1" sortPriority="10" count="%d">',
                             indent, xml_encode(basename(population$name)), population$count)
      )
      
      # Add gate if exists
      if (!is.null(population$gate_id) && population$gate_id %in% names(gates$gates)) {
        gate <- gates$gates[[population$gate_id]]
        xml_lines <- c(xml_lines, sprintf('%s  <Gate gating:id="%s">', indent, xml_encode(gate$id)))
        
        # Add gate definition based on type with proper attributes
        gate_def <- gate$definition
        
        if (!is.null(gate_def)) {
          if (gate_def$type == "rectangle") {
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:RectangleGate eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="Hairline" userDefined="1">',
                                   indent)
            )

            # yRatio is a display hint for histogram-style (1-D) gates. It should only
            # be emitted when the rectangle gate has a single dimension.
            is_1d_rect <- length(gate_def$dimensions) == 1L
            # Add dimensions
            for (dim in gate_def$dimensions) {
              if (is_1d_rect) {
                xml_lines <- c(xml_lines,
                               sprintf('%s      <gating:dimension gating:min="%f" gating:max="%f" yRatio="0.5">',
                                       indent, dim$min, dim$max),
                               sprintf('%s        <data-type:fcs-dimension data-type:name="%s"/>',
                                       indent, xml_encode(dim$parameter)),
                               sprintf('%s      </gating:dimension>', indent)
                )
              } else {
                xml_lines <- c(xml_lines,
                               sprintf('%s      <gating:dimension gating:min="%f" gating:max="%f">',
                                       indent, dim$min, dim$max),
                               sprintf('%s        <data-type:fcs-dimension data-type:name="%s"/>',
                                       indent, xml_encode(dim$parameter)),
                               sprintf('%s      </gating:dimension>', indent)
                )
              }
            }

            xml_lines <- c(xml_lines, sprintf('%s    </gating:RectangleGate>', indent))

          } else if (gate_def$type == "polygon") {
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:PolygonGate eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="Hairline" userDefined="1">', 
                                   indent)
            )
            
            # Add dimensions
            for (dim in gate_def$dimensions) {
              xml_lines <- c(xml_lines,
                             sprintf('%s      <gating:dimension>', indent),
                             sprintf('%s        <data-type:fcs-dimension data-type:name="%s"/>', 
                                     indent, xml_encode(dim$parameter)),
                             sprintf('%s      </gating:dimension>', indent)
              )
            }
            
            # Add vertices
            for (vertex in gate_def$vertices) {
              xml_lines <- c(xml_lines,
                             sprintf('%s      <gating:vertex>', indent),
                             sprintf('%s        <gating:coordinate data-type:value="%f"/>', indent, vertex$x),
                             sprintf('%s        <gating:coordinate data-type:value="%f"/>', indent, vertex$y),
                             sprintf('%s      </gating:vertex>', indent)
              )
            }
            
            xml_lines <- c(xml_lines, sprintf('%s    </gating:PolygonGate>', indent))
            
          } else if (gate_def$type == "ellipsoid") {
            xml_lines <- c(xml_lines,
                           sprintf('%s    <gating:EllipsoidGate eventsInside="1" annoOffsetX="0" annoOffsetY="0" tint="#000000" isTinted="0" lineWeight="Normal" userDefined="1" gating:distance="%f">', 
                                   indent, gate_def$distance)
            )
            
            # Add dimensions
            xml_lines <- c(xml_lines,
                           sprintf('%s      <gating:dimension>', indent),
                           sprintf('%s        <data-type:fcs-dimension data-type:name="%s" />', 
                                   indent, xml_encode(gate_def$x_param)),
                           sprintf('%s      </gating:dimension>', indent),
                           sprintf('%s      <gating:dimension>', indent),
                           sprintf('%s        <data-type:fcs-dimension data-type:name="%s" />', 
                                   indent, xml_encode(gate_def$y_param)),
                           sprintf('%s      </gating:dimension>', indent)
            )
            
            # Add foci
            xml_lines <- c(xml_lines,
                           sprintf('%s      <gating:foci>', indent),
                           sprintf('%s        <gating:vertex>', indent),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', 
                                   indent, gate_def$foci$focus1$x),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', 
                                   indent, gate_def$foci$focus1$y),
                           sprintf('%s        </gating:vertex>', indent),
                           sprintf('%s        <gating:vertex>', indent),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', 
                                   indent, gate_def$foci$focus2$x),
                           sprintf('%s          <gating:coordinate data-type:value="%f" />', 
                                   indent, gate_def$foci$focus2$y),
                           sprintf('%s        </gating:vertex>', indent),
                           sprintf('%s      </gating:foci>', indent)
            )
            
            # Add edge points
            xml_lines <- c(xml_lines, sprintf('%s      <gating:edge>', indent))
            for (edge_point in gate_def$edge) {
              xml_lines <- c(xml_lines,
                             sprintf('%s        <gating:vertex>', indent),
                             sprintf('%s          <gating:coordinate data-type:value="%f" />', 
                                     indent, edge_point$x),
                             sprintf('%s          <gating:coordinate data-type:value="%f" />', 
                                     indent, edge_point$y),
                             sprintf('%s        </gating:vertex>', indent)
              )
            }
            xml_lines <- c(xml_lines, sprintf('%s      </gating:edge>', indent))
            
            xml_lines <- c(xml_lines, sprintf('%s    </gating:EllipsoidGate>', indent))
          }
        }
        
        xml_lines <- c(xml_lines, sprintf('%s  </Gate>', indent))
      }
      
      # Recursively process child populations
      xml_lines <- c(xml_lines, sprintf('%s  <Subpopulations>', indent))
      
      # Prevent a population from being its own parent (cycle detection)
      if (population$name == parent_path) {
        cat(file = stderr(), "WARNING: Population '", population$name, 
            "' cannot be its own parent. Skipping recursion.\n")
      } else {
        # Check if we've already visited this population
        if (population$name %in% visited_paths) {
          cat(file = stderr(), "WARNING: Cycle detected - population '", 
              population$name, "' already visited. Skipping recursion.\n")
        } else {
          new_visited_paths <- unique(c(visited_paths, population$name))
          subpop_xml <- generate_group_subpopulations_xml(
            populations = populations, 
            gates = gates, 
            parent_path = population$name, 
            indent = paste0(indent, "    "), 
            visited_paths = new_visited_paths,
            gh = gh  # Pass gh down for boolean gate processing
          )
          xml_lines <- c(xml_lines, subpop_xml)
        }
      }
      xml_lines <- c(xml_lines, sprintf('%s  </Subpopulations>', indent))
      
      # Close population element
      xml_lines <- c(xml_lines, sprintf('%s</Population>', indent))
    }
  }
  return(xml_lines)
}



#' XML Encode Special Characters
#'
#' @param text Text to encode
#' @return Encoded text
#' @keywords internal
xml_encode <- function(text) {
  if (is.null(text) || length(text) == 0) {
    return("")
  }
  
  # Convert to character if needed
  text <- as.character(text)
  
  # Encode special XML characters
  text <- gsub("&", "&", text)
  text <- gsub("<", "<", text)
  text <- gsub(">", ">", text)
  text <- gsub('"', "\"", text)
  text <- gsub("'", "'", text)
  
  return(text)
}



#' Get Display Range for Parameter
#'
#' Determines the min/max range for a parameter that will be used in the XML
#' @keywords internal
get_display_range <- function(gh, param_name) {
  tryCatch({
    # Extract flowFrame from GatingHierarchy if needed
    if (inherits(gh, "GatingHierarchy")) {
      fr <- flowWorkspace::gh_pop_get_data(gh, "root")
    } else {
      fr <- gh
    }
    
    kw <- flowCore::keyword(fr)
    
    # Find parameter number by matching $PnN to param_name
    n_pattern <- paste0("^\\$P[0-9]+N$")
    n_keys <- grep(n_pattern, names(kw), value = TRUE)
    n_values <- sapply(n_keys, function(k) as.character(kw[[k]]))
    param_match <- which(n_values == param_name)
    
    if (length(param_match) > 0) {
      # Extract number from $P6N -> 6
      param_num <- gsub("\\$|P|N", "", names(param_match)[1])
      range_key <- paste0("$P", param_num, "R")
      
      if (!is.null(kw[[range_key]])) {
        max_val <- as.numeric(kw[[range_key]])
        min_val <- 0
        
        # Check for negative values in scatter channels
        if (grepl("FSC|SSC", param_name, ignore.case = TRUE)) {
          data_vals <- flowCore::exprs(fr)[, param_name]
          actual_min <- min(data_vals, na.rm = TRUE)
          if (actual_min < 0) {
            min_val <- floor(actual_min / 10000) * 10000
          }
        }
        
        c(min_val, max_val)  # No explicit return needed
      } else {
        # Keyword missing, fall through to data range
        data_vals <- flowCore::exprs(fr)[, param_name]
        min_val <- min(data_vals, na.rm = TRUE)
        max_val <- max(data_vals, na.rm = TRUE)
        
        range_span <- max_val - min_val
        c(min_val - 0.1 * range_span, max_val + 0.1 * range_span)
      }
    } else {
      # Parameter not found in keywords, use actual data
      data_vals <- flowCore::exprs(fr)[, param_name]
      min_val <- min(data_vals, na.rm = TRUE)
      max_val <- max(data_vals, na.rm = TRUE)
      
      range_span <- max_val - min_val
      c(min_val - 0.1 * range_span, max_val + 0.1 * range_span)
    }
    
  }, error = function(e) {
    c(0, 262144)
  })
}
