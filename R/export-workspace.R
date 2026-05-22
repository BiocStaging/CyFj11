#' @title Export FlowJo v11 Workspace
#' @name export-workspace
#' @keywords internal
NULL

#' Export GatingSet to FlowJo v11 Workspace
#'
#' Converts a GatingSet object back to FlowJo v11 workspace format (.flowjo)
#'
#' @param gating_set GatingSet object to export
#' @param output_path Path where the .flowjo file should be created
#' @param groups Optional list of group definitions
#' @param workbench_data Optional workbench data to preserve IDs from original workspace
#' @param analysis_uuid Optional analysis UUID to preserve from original workspace
#' @param template_json_data Optional template JSON data to preserve structure from original workspace
#' @param ... Additional parameters for future expansion
#' @return Logical indicating success (TRUE) or failure (FALSE)
#' @export
#' @examples
#' \dontrun{
#' # Export a GatingSet to FlowJo workspace
#' export_flowjo11_workspace(my_gs, "exported_workspace.fjw")
#' }
export_flowjo11_workspace <- function(gating_set, output_path, groups = NULL, workbench_data = NULL, analysis_uuid = NULL, template_json_data = NULL, ...) {
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
  # browser()
  
  # Create or use provided groups
  if (is.null(groups)) {
    groups_data <- create_default_groups("ANALYSIS_UUID")
  } else {
    groups_data <- groups
  }
  
  # Extract components from GatingSet
  samples_data <- extract_samples_from_gatingset(gating_set, template_json_data)
  # browser()
  result <- extract_gates_from_gatingset(gating_set)
  gates_data <- result[[1]]
  sample_gate_uuids <- result[[2]]
  
  # Remove duplicates and get UUID mapping
  dedup_result <- remove_duplicate_entries(gates_data)
  gates_data <- dedup_result$unique_list
  uuid_mapping <- dedup_result$uuid_mapping
  
  # Update sample_gate_uuids with retained UUIDs
  sample_gate_uuids <- update_sample_gate_uuids(sample_gate_uuids, uuid_mapping)
  
  # remove duplicate UUIDs within each sample group
  sample_gate_uuids <- lapply(sample_gate_uuids, unique)
  
  populations_data <- extract_populations_from_gatingset(gating_set, samples_data, gates_data, sample_gate_uuids)
  
  # browser()
  # Assemble FlowJo workspace structure
  workspace_structure <- assemble_flowjo_json_structure(
    samples = samples_data,
    gates = gates_data,
    populations = populations_data,
    groups = groups_data,
    analysis_uuid = analysis_uuid
  )
  
  # Package into FlowJo workspace format with complete structure
  result <- create_flowjo_workspace(
    output_path = output_path,
    samples = workspace_structure$dataSources,
    gates = workspace_structure$populationDefinitions,
    populations = workspace_structure$populations,
    # Pass the complete workspace structure as template data
    template_workspace_data = if (is.null(template_json_data)) workspace_structure else template_json_data,
    # Pass workbench data if available (when converting from existing workspace)
    workbench_data = workbench_data,  # Will be set when converting from existing workspace
    # Preserve original structure when template_json_data is provided
    preserve_original_structure = !is.null(template_json_data)
  )
  
  if (result) {
    message("Successfully exported FlowJo workspace to: ", output_path)
  }
  
  return(result)
}

#' Extract Samples from GatingSet
#'
#' @param gating_set GatingSet object
#' @param template_json_data Optional template JSON data to preserve original UUIDs
#' @return List of sample data in FlowJo format
#' @keywords internal
extract_samples_from_gatingset <- function(gating_set, template_json_data = NULL) {
  # Initialize samples list
  samples <- list()
  
  # Get sample names and GUIDs
  sample_names <- flowWorkspace::sampleNames(gating_set)
  
  # Extract sample information
  for (i in seq_along(sample_names)) {
    sample_name <- sample_names[i]
    gh <- gating_set[[sample_name]]
    
    # Try to preserve original UUID and structure from template data if available
    sample_uuid <- NULL
    original_sample_data <- NULL
    if (!is.null(template_json_data) && !is.null(template_json_data$dataSources)) {
      # Look for matching sample in template data
      for (uuid in names(template_json_data$dataSources)) {
        sample_data <- template_json_data$dataSources[[uuid]]
        if (!is.null(sample_data$definition$customKeywords$`File Name`) &&
            sample_data$definition$customKeywords$`File Name` == sample_name) {
          sample_uuid <- uuid
          original_sample_data <- sample_data
          break
        }
      }
    }
    
    # If no matching UUID found, generate a new one
    if (is.null(sample_uuid)) {
      sample_uuid <- UUIDgenerate("BAJUUID_sample_ui")
    }
    
    # Extract file path if available
    file_path <- tryCatch({
      gh@data@file
    }, error = function(e) {
      NA
    })
    
    # If we have original sample data, preserve most of it but update the URI
    if (!is.null(original_sample_data)) {
      # Preserve the original structure but update the URI
      samples[[sample_uuid]] <- original_sample_data
      # Update the URI to the current file path
      if (!is.na(file_path)) {
        samples[[sample_uuid]]$definition$uri <- file_path
      }
    } else {
      # Create sample definition in FlowJo format
      # Extract keywords/metadata if available
      keywords <- list()
      if (requireNamespace("flowCore", quietly = TRUE)) {
        tryCatch({
          keywords <- flowCore::keyword(gh@data)
        }, error = function(e) {
          # Continue with empty keywords if extraction fails
        })
      }
      gh = gating_set[[sample_name]]
      
      time_param <- grep("time", colnames(gh_pop_get_data(gs[[sample_name]], "root")), 
                         ignore.case = TRUE, value = TRUE)[1]
      params = parameters(gh_pop_get_data(gh, "root"))
      minVal = params@data[params$name == time_param, "minRange"]  
      maxVal = params@data[params$name == time_param, "maxRange"]
      
      samples[[sample_uuid]] <- list(
        uuid = sample_uuid,
        definition = list(
          uri = ifelse(is.na(file_path), paste0("file://", sample_name), file_path),
          customKeywords = c(
            list("File Name" = sample_name),
            keywords,
            "Compensation Matrix" = ""
          )
        ),
        transforms = list(
          "parameterSpec" = list(
            name = time_param
          ),
          transform = list(
            "transformType"= "Linear",
            "minRange" = minVal,
            "maxRange" = maxVal
          ),
          "targetType" = "sample",
          "targetId" = sample_uuid
        ),
        parents = list(
          "_analysis" = list("ANALYSIS_UUID"),
          analysisRoot = list("ANALYSIS_UUID"),
          populationDefinitions = character(0),
          compoundPopulations = character(0),
          populations = character(0),
          paramsetDefinitions = character(0),
          compoundParameterSets = character(0),
          dataSources = character(0),
          cytometers = list("CYTOMETER_UUID"),
          platforms = character(0),
          reports = character(0)
        ),
        children = list(
          analysisRoot =  character(0),
          groups = list("groupAquired", "groupExperimentData"),
          populationDefinitions = character(0),
          "compoundPopulations" = character(0),
          "populations" = list(  paste0("ungated-@-", sample_name)),
          "paramsetDefinitions" =  character(0),
          "compoundParameterSets" =  character(0),
          "dataSources" =  character(0),
          "cytometers" =  character(0),
          "platforms" =  character(0),
          "reports" =  character(0)
        ),
        results = structure(list(), names = character(0)),
        "definitionVersion" = 35L,
        "resultsVersion" = 35L,
        "stableSince" = 0L,
        "recalcVersion" = 0L
      )
    }
  }
  
  return(samples)
}

library(flowCore)

# Main function to create parameter JSON from FCS file
create_parameter_json <- function(fr) {
  
  # Get parameters and keywords
  params <- parameters(fr)
  keywords <- keyword(fr)
  
  # Helper function to determine pulse type from parameter name
  get_pulse_type <- function(param_name) {
    if (grepl("-A$", param_name)) return("area")
    if (grepl("-H$", param_name)) return("height")
    if (grepl("-W$", param_name)) return("width")
    return("other")
  }
  
  # Helper function to determine parameter type
  get_param_type <- function(param_name, index) {
    if (grepl("^FSC|^SSC", param_name)) return("scatter")
    if (grepl("^TIME$|^Event", param_name)) return("metadata")
    return("rawData")
  }
  
  # Helper function to extract parameter keywords
  get_param_keywords <- function(index, keywords) {
    param_num <- index + 1  # FCS uses 1-based indexing
    
    keyword_list <- list()
    keyword_patterns <- c("N", "S", "R", "B", "E", "D")
    
    for (pattern in keyword_patterns) {
      key <- paste0("$P", param_num, pattern)
      if (key %in% names(keywords)) {
        keyword_list[[key]] <- keywords[[key]]
      }
    }
    
    return(keyword_list)
  }
  
  # Helper function to parse descriptive name
  parse_descriptive_name <- function(pns_value) {
    if (is.null(pns_value) || pns_value == "") {
      return(list(descriptiveName = "", analyteName = ""))
    }
    
    # Check if format is "Analyte : Fluorophore - PulseType"
    if (grepl(":", pns_value)) {
      parts <- strsplit(pns_value, ":")[[1]]
      analyte <- trimws(parts[1])
      rest <- trimws(parts[2])
      
      # Further split on " - "
      if (grepl(" - ", rest)) {
        rest_parts <- strsplit(rest, " - ")[[1]]
        return(list(descriptiveName = pns_value, analyteName = analyte))
      }
    }
    
    return(list(descriptiveName = pns_value, analyteName = ""))
  }
  
  # Function to create parameter object
  create_param_object <- function(idx, params, keywords) {
    param_name <- as.character(params$name[idx])
    param_desc <- as.character(params$desc[idx])
    param_range <- as.numeric(params$range[idx])
    
    # Parse descriptive name
    desc_info <- parse_descriptive_name(param_desc)
    
    # Get pulse type
    pulse_type <- get_pulse_type(param_name)
    
    # Get parameter type
    param_type <- get_param_type(param_name, idx)
    
    # Get keywords for this parameter
    param_keywords <- get_param_keywords(idx - 1, keywords)
    
    # Get parameter source (instrument name)
    param_source <- if ("$CYT" %in% names(keywords)) keywords[["$CYT"]] else "Unknown"
    
    # Build parameter object
    param_obj <- list(
      name = param_name,
      descriptiveName = desc_info$descriptiveName,
      analyteName = desc_info$analyteName,
      type = param_type,
      orientation = "parameter",
      index = idx - 1,  # 0-based indexing for output
      parameterSource = param_source,
      originalName = param_name,
      originalDescriptiveName = desc_info$descriptiveName,
      originalAnalyteName = desc_info$analyteName,
      representableRange = param_range,
      pulseType = pulse_type
    )
    
    # Add keywords if present
    if (length(param_keywords) > 0) {
      param_obj$keywords <- param_keywords
    }
    
    # Add defaultTransform for metadata parameters
    if (param_type == "metadata") {
      param_obj$defaultTransform <- list(
        transformType = "Linear",
        minRange = 0.0,
        maxRange = param_range
      )
    }
    
    return(param_obj)
  }
  
  # Create lists for each category
  rawData_list <- list()
  metadata_list <- list()
  scatter_list <- list()
  
  # Process each parameter
  for (i in 1:nrow(params)) {
    param_obj <- create_param_object(i, params, keywords)
    
    # Add to appropriate category
    if (param_obj$type == "scatter") {
      scatter_list[[length(scatter_list) + 1]] <- param_obj
    } else if (param_obj$type == "metadata") {
      metadata_list[[length(metadata_list) + 1]] <- param_obj
    } else {
      rawData_list[[length(rawData_list) + 1]] <- param_obj
    }
  }
  
  # Build final structure
  result <- list(
    parameters = list(
      rawData = rawData_list,
      metadata = metadata_list,
      scatter = scatter_list,
      unmixed = list(),
      imageDerived = list(),
      derived = list(),
      debug = list()
    )
  )
  
  return(result)
}




#' Extract Gates from GatingSet
#'
#' @param gating_set GatingSet object
#' @return List of gate data in FlowJo format
#' @keywords internal
extract_gates_from_gatingset <- function(gating_set) {
  # Initialize gates list
  gates <- list()
  
  # Keep track of gate names we've already seen to avoid duplicates
  seen_gate_names <- character(0)
  
  # Get all population paths
  sample_names <- flowWorkspace::sampleNames(gating_set)
  sample_gate_uuids = setNames(replicate(length(sample_names), character(0), simplify = FALSE), sample_names)
  
  if (length(sample_names) > 0) {
    # Process all samples to collect gates
    for (i in seq_along(sample_names)) {
      gh <- gating_set[[i]]
      sample_name = flowWorkspace::sampleNames(gh)
      # Get population paths for this sample
      pop_paths <- tryCatch({
        flowWorkspace::gs_get_pop_paths(gh, path = "auto")
      }, error = function(e) {
        warning("Failed to get population paths for sample ", sample_names[i], ": ", e$message)
        character(0)
      })
      # browser()
      # Extract gate information for each population
      for (pop_path in pop_paths) {
        
        gate_uuid <- UUIDgenerate("BAJUUID_gate_ui")
        sample_gate_uuids[[sample_name]] <- c(sample_gate_uuids[[sample_name]], gate_uuid)
        # browser()
        if (pop_path == "root"){
          gates[[gate_uuid]] <- create_root_pop(gate_uuid)
        } else{
          tryCatch({
            # Get gate object
            # browser()
            gate_list <- flowWorkspace::gs_pop_get_gate(gh, pop_path)
            if (length(gate_list) > 0) {
              gate <- gate_list[[1]]
              
              # Convert flowCore gate to FlowJo format
              gate_definition <- convert_gate_to_PopDef_definition(gate = gate, pop_name = pop_path, gh, gate_uuid)
              # browser()
              # i think we have to move parents, children etc a level up
              if (!is.null(gate_definition) && !is.null(gate_definition$type)) {
                gates[[gate_uuid]] <- list(
                  uuid = gate_uuid,
                  properties = structure(list(), names = character(0)),
                  definition = list(
                    name = list(pop_path),
                    type = "gate",
                    kind = "general",
                    gateDefinition = gate_definition
                  ),
                  parents = structure(list(), names = character(0)),
                  children = structure(list(), names = character(0)),
                  results = structure(list(), names = character(0)),
                  definitionVersion = 35L,
                  resultsVersion = 35L,
                  stableSince = 0L,
                  recalcVersion = 0L
                )
              }
            }
            
          }, error = function(e) {
            warning("Failed to extract gate for population ", pop_path, ": ", e$message)
          })
        }
      }
    }
  }
  
  return(list(gates, sample_gate_uuids))
}

create_root_pop <- function(gate_uuid){
  list(
    uuid = gate_uuid,
    properties = list(
      graphHistory = list(
        settings = list(
          backgroundColor = "#ffffff",
          plotType = "Pseudocolor",
          colorPalette = "FlowJoClassic",
          pointColor = "blue",
          contourLevels = 5,
          isSmooth = FALSE,
          resolution = "R_1024",
          xAxis = list(
            parameter = "FSC-A :: FSC - Area",
            type = "Parameter",
            statistic = "MEDIAN"
          ),
          yAxis = list(
            parameter = "SSC-A :: SSC - Area",
            type = "Parameter",
            statistic = "MEDIAN"
          ),
          histogramNorm = "none"
        ),
        lastViewedParameters = list(
          xAxis = list(
            parameter = "FSC-A :: FSC - Area",
            type = "Parameter",
            statistic = "MEDIAN"
          ),
          yAxis = list(
            parameter = "SSC-A :: SSC - Area",
            type = "Parameter",
            statistic = "MEDIAN"
          )
        )
      )
    ),
    definition = list(
      name = list("Ungated"),
      type = "root",
      kind = "ungated"
    ),
    parents = list(
      `_analysis` = c("ANALYSIS_UUID"),
      analysisRoot = c("ANALYSIS_UUID"),
      groups = c("Acquired Data UUID"),
      populationDefinitions = character(0),
      compoundPopulations = character(0),
      populations = character(0),
      paramsetDefinitions = character(0),
      compoundParameterSets = character(0),
      dataSources = character(0),
      cytometers = character(0),
      platforms = character(0),
      reports = character(0)
    ),
    children = list(
      analysisRoot = character(0),
      groups = character(0),
      populationDefinitions = character(0),
      compoundPopulations = character(0),
      populations = c(
        "List of Population that links dataSource with ungated popdefinitions"
      ),
      paramsetDefinitions = character(0),
      compoundParameterSets = character(0),
      dataSources = character(0),
      cytometers = character(0),
      platforms = character(0),
      reports = character(0)
    ),
    results = structure(list(), names = character(0)),
    definitionVersion = 35L,
    resultsVersion = 35L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
}

#' Extract Populations from GatingSet
#'
#' @param gating_set GatingSet object
#' @param template_json_data Optional template JSON data to preserve original populations
#' @return List of population data in FlowJo format
#' @keywords internal
extract_populations_from_gatingset <- function(gating_set, samples_data, gates_data, sample_gate_uuids) {

  # Initialize populations list
  populations <- list()
  # browser()      
  # Get sample information
  sample_names <- flowWorkspace::sampleNames(gating_set)
  
  gate_names = c()
  for (gate in gates_data){
    if(is.null(gate$definition)) {
      browser()
    }
    gate_names = c(gate_names, gate$definition$name)
  }
  # Extract population information for each sample
  for (i in seq_along(samples_data)) {
    sample_name <- sample_names[i]
    # TODO check that this works and warn if not but go to next i
    gs_idx = which(samples_data[[i]]$definition$customKeywords$`File Name` == sample_names)
    
    gh <- gating_set[[gs_idx]]
    
    # Get population paths
    pop_paths <- tryCatch({
      flowWorkspace::gs_get_pop_paths(gh, path = "auto")
    }, error = function(e) {
      warning("Failed to get population paths for sample ", sample_name, ": ", e$message)
      character(0)
    })
    
    # Extract population information
    for (pop_path in pop_paths) {
      # find corresponding population Definition in gates_data
      if(pop_path == "root"){
        pop_name = "Ungated"
        status = "empty"
        validPopulations = 0L
      } else {
        pop_name = pop_path
        status = "valid"
        validPopulations = 1L
        
      }
      # Generate UUID for population
      pop_uuid <- UUIDgenerate("BAJUUID_pop_ui")
      
      # Get parent population path
      parent_path <- get_parent_path(pop_path)
      nCells = gh_pop_get_count(gh, pop_path)
      # Create population definition in FlowJo format
      populations[[pop_uuid]] <- list(
        uuid = pop_uuid,
        "properties" = structure(list(), names = character(0)),
        "definition" = list(
          "populationNumber" = 0L
        ),
        parentPopulation = NULL,
        parents = list(
          "_analysis" = list("ANALYSIS_UUID"),
          "_dataSource" = list(sample_name),
          "analysisRoot" = list(),
          "groups" = list(),
          "populationDefinitions" =list(pop_path),
          "compoundPopulations" = list(),
          "populations" = list() , #reference to something
          "paramsetDefinitions" = list(),
          "compoundParameterSets" = list(),
          "dataSources" = list(),
          "cytometers" = list(),
          "platforms" = list(),
          "reports" = list()
        ),
        children = list(
          analysisRoot = list(),
          groups = list(),
          populationDefinitions = list(),
          compoundPopulations = list(), #"compoundPopulationsREF"
          populations = list(),
          paramsetDefinitions = list(),
          compoundParameterSets = list(),
          dataSources = list(),
          cytometers = list(),
          platforms = list(),
          reports = list()
        ),
        results = list(
          "status" = status,
          "validPopulations" = validPopulations,
          "invalidPopulations" = 0L,
          "count" = as.integer(nCells),
          "statistics" = list( 
            "CNT" = nCells
            )
        ),
        "definitionVersion" = 35L,
        "resultsVersion" = 35L,
        "stableSince" = 3L,
        "recalcVersion" = 3L
      )
    }
  }
  
  return(populations)
}


#' Convert flowCore Gate to FlowJo Format. This is used in populationDefinitions for non-root populations, i.e. gated structures 
#'
#' @param gate flowCore gate object
#' @param pop_name Population name
#' @param gh gating history of gate
#' @return List representing gate in FlowJo format
#' @keywords internal
convert_gate_to_PopDef_definition <- function(gate, pop_name, gh, gate_uuid) {
  # Extract leaf name from path
  leaf_name <- extract_leaf_name(pop_name)
  
  # Initialize gate definition
  if(pop_name == "root"){
    # this should not happen
    browser()
  }
  # browser()
  # Handle different gate types
  # gateDefinition
  if (requireNamespace("flowCore", quietly = TRUE)) {
    gate_class <- class(gate)[1]
    if (methods::is(gate, "rectangleGate")) {
      gate_def <- convert_rectangle_to_gateDefinition(gate, pop_name,  gate_uuid, gh)
    } else if (methods::is(gate, "polygonGate")) {
      gate_def <- convert_polygon_to_gateDefinition(gate, pop_name, gate_uuid, gh)
    } else if (methods::is(gate, "ellipsoidGate")) {
      gate_def <- convert_ellipsoid_to_gateDefinition(gate = gate, pop_name = pop_name,  gh, gate_uuid)
    } else if (requireNamespace("flowWorkspace", quietly = TRUE) &&
               methods::is(gate, "booleanFilter")) {
      gate_def <- convert_boolean_to_gateDefinition(gate, pop_name, gate_uuid, gh)
    } else {
      warning("Unsupported gate type for population: ", pop_name, " (class: ", gate_class, ")")
      return(NULL)
    }
    
    # Check if conversion was successful
    if (is.null(gate_def)) {
      warning("Gate conversion failed for population: ", pop_name, " (class: ", gate_class, ")")
    }
  }
  gate_def$desyncTable = structure(list(), names = character(0))
  return(gate_def)
}

#' Convert Rectangle Gate to FlowJo Format
#'
#' @param gate rectangleGate object
#' @param pop_name Population name
#' @param gate_def Base gate definition
#' @return Updated gate definition
#' @keywords internal
convert_rectangle_to_gateDefinition <- function(gate, pop_name, gate_uuid, gh) {
  # Debug information
  message("Converting rectangle gate: ", pop_name)
  message("  Gate class: ", class(gate)[1])
  # browser()
  # For flowCore rectangleGate objects, parameters are in the parameters slot
  params <- NULL
  if (!is.null(gate@parameters)) {
    # Get parameter names
    params <- names(gate@parameters)
    message("  Parameters: ", if (!is.null(params)) paste(params, collapse = ", ") else "NULL")
  }
  # todo y-axis is not correct  for SSC-a, but this is probably a problem when reading or creating the gate object
  # Get gate boundaries from min/max slots
  min_vals <- gate@min
  max_vals <- gate@max
  
  message("  Min values: ", if (!is.null(min_vals)) paste(min_vals, collapse = ", ") else "NULL")
  message("  Max values: ", if (!is.null(max_vals)) paste(max_vals, collapse = ", ") else "NULL")
  
  # Validate parameters
  if (is.null(params) || length(params) == 0) {
    warning("Rectangle gate has no parameters: ", pop_name)
    return(NULL)
  }
  
  # Validate boundaries
  if (is.null(min_vals) || is.null(max_vals)) {
    warning("Rectangle gate has NULL boundaries: ", pop_name)
    return(NULL)
  }
  
  if (length(min_vals) != length(params) || length(max_vals) != length(params)) {
    warning("Rectangle gate has mismatched boundary dimensions: ", pop_name)
    return(NULL)
  }
  gate_def = list()
  gate_def$uuid = gate_uuid
  # Update gate definition
  gate_def$type <- "rectangle"
  gate_def$recalcVersion <- 0L
  
  # Add properties with graphHistory, don't think it is needed
  # gate_def$properties <- structure(list(), names = character(0))
  
  # Handle 1D or 2D gate
  if (length(params) == 1) {
    # browser()
    #need to be verified
    # 1D gate (range gate)
    param <- params[1]
     min_val <- round_numeric(min_vals[1], digits = 4)
    max_val <- round_numeric(max_vals[1], digits = 4)
    
    # Add vertices for compatibility with import process
    gate_def$xVertices <- c(min_val, max_val)
    
    gate_def$parameter = param
    gate_def$min = min_val
    gate_def$max = max_val
    gate_def$xAxis = list(
      parameterSpec = list(
        name = param,
        descriptiveName = param
      )
    )
    
  } else if (length(params) >= 2) {
    
    # After setting up the axes (around line 688), add:
    # Convert min/max to vertices for compatibility with import process
      # 2D gate (rectangle gate)
      x_min <- round_numeric(min_vals[1], digits = 8)
      x_max <- round_numeric(max_vals[1], digits = 8)
      y_min <- round_numeric(min_vals[2], digits = 8)
      y_max <- round_numeric(max_vals[2], digits = 8)
      
    
    # 2D gate (rectangle gate)
    x_param <- params[1]
    y_param <- params[2]
    
    gate_def$xAxis = list(
      parameterSpec = list(
        name = x_param,
        descriptiveName = x_param
      ),
      transform = get_transform_spec(gh, x_param)
    )
    gate_def$yAxis = list(
      parameterSpec = list(
        name = y_param,
        descriptiveName = y_param
      ),
      transform = get_transform_spec(gh, y_param)
    )
    
    # Add vertices for compatibility with import process
    gate_def$xVertices <- c(x_min, x_max)
    gate_def$yVertices <- c(y_min, y_max)
    
    # Add desyncTable for per-sample gate variations (placeholder)
    gate_def$desyncTable <- structure(list(), names = character(0))
    
    
  } else {
    warning("Rectangle gate has unexpected number of parameters: ", pop_name, " (count: ", length(params), ")")
    return(NULL)
  }
  
  message("  Successfully converted rectangle gate: ", pop_name)
  return(gate_def)
}

#' Convert Polygon Gate to FlowJo Format
#'
#' @param gate polygonGate object
#' @param pop_name Population name
#' @param gate_def Base gate definition
#' @return Updated gate definition
#' @keywords internal
convert_polygon_to_gateDefinition <- function(gate, pop_name, gate_uuid, gh) {
  # Debug information
  message("Converting polygon gate: ", pop_name)
  message("  Gate class: ", class(gate)[1])
  # browser()
  # For flowCore polygonGate objects, parameters are in the parameters slot
  params <- NULL
  if (!is.null(gate@parameters)) {
    # Get parameter names
    params <- names(gate@parameters)
    message("  Parameters: ", if (!is.null(params)) paste(params, collapse = ", ") else "NULL")
  }
  
  # Get vertices from boundaries slot
  vertices <- NULL
  if (!is.null(gate@boundaries)) {
    vertices <- gate@boundaries
    message("  Vertices dimensions: ", if (!is.null(vertices)) paste(dim(vertices), collapse = "x") else "NULL")
  }
  
  # Validate parameters
  if (is.null(params) || length(params) < 2) {
    warning("Polygon gate missing parameters: ", pop_name, " (params: ", if (!is.null(params)) length(params) else "NULL", ")")
    return(NULL)
  }
  
  if (is.null(vertices)) {
    warning("Polygon gate has NULL vertices: ", pop_name)
    return(NULL)
  }
  
  if (nrow(vertices) < 3) {
    warning("Polygon gate has insufficient vertices: ", pop_name, " (rows: ", nrow(vertices), ")")
    return(NULL)
  }
  gate_def = list()
  gate_def$uuid = gate_uuid
  
  # Update gate definition
  gate_def$type <- "PolygonGate"
  gate_def$recalcVersion <- 0L
  
  # Extract x and y coordinates with precision control
  x_param <- params[1]
  y_param <- params[2]
  x_coords <- round_numeric(vertices[, 1], digits = 4)
  y_coords <- round_numeric(vertices[, 2], digits = 4)
  
  # Add properties with graphHistory
  # gate_def$properties <- list(
  #   graphHistory = list(
  #     settings = list(
  #       backgroundColor = "#ffffff",
  #       plotType = "Pseudocolor",
  #       colorPalette = "FlowJoClassic",
  #       pointColor = "blue",
  #       contourLevels = 5,
  #       isSmooth = FALSE,
  #       resolution = "R_1024",
  #       xAxis = list(
  #         parameter = paste0(x_param, " :: ", x_param),
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       ),
  #       yAxis = list(
  #         parameter = paste0(y_param, " :: ", y_param),
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       ),
  #       histogramNorm = "none"
  #     ),
  #     lastViewedParameters = list(
  #       xAxis = list(
  #         parameter = paste0(x_param, " :: ", x_param),
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       ),
  #       yAxis = list(
  #         parameter = paste0(y_param, " :: ", y_param),
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       )
  #     )
  #   )
  # )
  
  gate_def$type = "PolygonGate"
  gate_def$xAxis = list(
    parameterSpec = list(
      name = x_param,
      descriptiveName = x_param
    ),
    transform = get_transform_spec(gh, x_param)
  )
  gate_def$yAxis = list(
    parameterSpec = list(
      name = y_param,
      descriptiveName = y_param
    ),
    transform = get_transform_spec(gh, y_param)
  )
  
  
  # Add desyncTable for per-sample gate variations (placeholder)
  gate_def$desyncTable <- structure(list(), names = character(0))
  
  message("  Successfully converted polygon gate: ", pop_name)
  return(gate_def)
}


#' Convert Ellipsoid Gate to FlowJo Format
#'
#' @param gate ellipsoidGate object
#' @param pop_name Population name
#' @param gate_def Base gate definition
#' @return Updated gate definition
#' @keywords internal
convert_ellipsoid_to_gateDefinition <- function(gate, pop_name, gh, gate_uuid) {
  # Get gate parameters
  params <- tryCatch({
    flowCore::parameters(gate)
  }, error = function(e) {
    NULL
  })
  
  # Debug information
  message("Converting ellipsoid gate: ", pop_name)
  message("  Parameters: ", if (!is.null(params)) paste(params, collapse = ", ") else "NULL")
  
  if (is.null(params) || length(params) < 2) {
    warning("Ellipsoid gate missing parameters: ", pop_name, " (params: ", if (!is.null(params)) length(params) else "NULL", ")")
    return(NULL)
  }
  
  # Get ellipse parameters
  mean_vals <- tryCatch({
    gate@mean
  }, error = function(e) {
    warning("Failed to extract mean from ellipsoid gate: ", pop_name)
    return(NULL)
  })
  
  cov_mat <- tryCatch({
    gate@cov
  }, error = function(e) {
    warning("Failed to extract covariance from ellipsoid gate: ", pop_name)
    return(NULL)
  })
  
  if (is.null(mean_vals)) {
    warning("Ellipsoid gate has NULL mean values: ", pop_name)
    return(NULL)
  }
  
  if (is.null(cov_mat)) {
    warning("Ellipsoid gate has NULL covariance matrix: ", pop_name)
    return(NULL)
  }
  
  gate_def = list()
  gate_def$uuid = gate_uuid
  
  # Update gate definition
  gate_def$type <- "ellipse"
  
  # Extract parameters with precision control
  x_param <- params[1]
  y_param <- params[2]
  center_x <- round_numeric(mean_vals[1], digits = 8)
  center_y <- round_numeric(mean_vals[2], digits = 8)
  
  # Calculate eigenvalues and eigenvectors to get rotation angle
  eigen_decomp <- eigen(cov_mat)
  eigenvals <- eigen_decomp$values
  eigenvecs <- eigen_decomp$vectors
  
  # Calculate rotation angle from eigenvectors
  # The angle is determined by the direction of the major axis (first eigenvector)
  major_axis_vec <- eigenvecs[, 1]
  rotation_angle_rad <- atan2(major_axis_vec[2], major_axis_vec[1])
  rotation_angle_deg <- rotation_angle_rad * 180 / pi
  
  # Ensure angle is in [0, 360) range
  if (rotation_angle_deg < 0) {
    rotation_angle_deg <- rotation_angle_deg + 360
  }
  
  # Calculate semi-major and semi-minor axes lengths
  semi_major <- sqrt(eigenvals[1])
  semi_minor <- sqrt(eigenvals[2])
  
  # Calculate vertices for FlowJo
  # For ellipses, FlowJo typically uses 4 vertices:
  # Two on the major axis (to define length and angle)
  # Two on the minor axis (to define thickness)
  angle_rad <- rotation_angle_deg * pi / 180
  cos_a <- cos(angle_rad)
  sin_a <- sin(angle_rad)
  
  # Vertices on major axis
  x_vertex1 <- center_x + semi_major * cos_a
  x_vertex2 <- center_x - semi_major * cos_a
  y_vertex1 <- center_y + semi_major * sin_a
  y_vertex2 <- center_y - semi_major * sin_a
  
  # For FlowJo export, we typically just need the center vertices
  gate_def$recalcVersion = 0L
  gate_def$xAxis = list(
    parameterSpec = list(
      name = x_param,
      descriptiveName = names(x_param)
    ),
    transform = get_transform_spec(gh, dim=x_param)
  )
  gate_def$yAxis = list(
    parameterSpec = list(
      name = y_param,
      descriptiveName = names(y_param)
    ),
    transform = get_transform_spec(gh, dim=y_param)
  )
  gate_def$approximateGeometry = TRUE
  gate_def$xVertices = center_x
  gate_def$yVertices = center_y
  gate_def$rotationAngle = rotation_angle_deg  # Corrected rotation angle
  
  # Add desyncTable for per-sample gate variations (placeholder)
  gate_def$desyncTable <- structure(list(), names = character(0))
  
  message("  Successfully converted ellipsoid gate: ", pop_name)
  message("  Rotation angle: ", rotation_angle_deg, " degrees")
  return(gate_def)
}




#' Convert Boolean Gate to FlowJo Format
#' 
#' @param gate booleanFilter object
#' @param pop_name Population name
#' @param gate_def Base gate definition
#' @return Updated gate definition
#' @keywords internal
convert_boolean_to_gateDefinition <- function(gate, pop_name, gate_uuid, gh) {
  # Update gate definition
  gate_def$type <- "BooleanGate"
  gate_def$kind <- "Boolean"
  
  # Add properties with graphHistory (using default parameters for boolean gates)
  # gate_def$properties <- list(
  #   graphHistory = list(
  #     settings = list(
  #       backgroundColor = "#ffffff",
  #       plotType = "Pseudocolor",
  #       colorPalette = "FlowJoClassic",
  #       pointColor = "blue",
  #       contourLevels = 5,
  #       isSmooth = FALSE,
  #       resolution = "R_1024",
  #       xAxis = list(
  #         parameter = "FSC-A :: FSC - Area",
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       ),
  #       yAxis = list(
  #         parameter = "SSC-A :: SSC - Area",
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       ),
  #       histogramNorm = "none"
  #     ),
  #     lastViewedParameters = list(
  #       xAxis = list(
  #         parameter = "FSC-A :: FSC - Area",
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       ),
  #       yAxis = list(
  #         parameter = "SSC-A :: SSC - Area",
  #         type = "Parameter",
  #         statistic = "MEDIAN"
  #       )
  #     )
  #   )
  # )
  
  # Extract boolean expression
  expr <- tryCatch({
    attr(gate, "expr")
  }, error = function(e) {
    warning("Failed to extract expression from boolean gate: ", pop_name)
    return(NULL)
  })
  
  if (is.null(expr)) {
    return(NULL)
  }
  
  # Convert expression to string
  expr_string <- tryCatch({
    as.character(expr)
  }, error = function(e) {
    warning("Failed to convert boolean expression to string: ", pop_name)
    return("")
  })
  
  gate_def$gateDefinition <- list(
    type = "BooleanGate",
    expression = expr_string,
    specification = expr_string
  )
  
  # Add desyncTable for per-sample gate variations (placeholder)
  gate_def$desyncTable <- structure(list(), names = character(0))
  
  return(gate_def)
}

#' Assemble FlowJo JSON Structure
#'
#' @param samples List of sample data
#' @param gates List of gate data
#' @param populations List of population data
#' @param groups List of group data
#' @param analysis_uuid Optional analysis UUID to use
#' @return List representing complete FlowJo workspace structure
#' @keywords internal
assemble_flowjo_json_structure <- function(samples, gates, populations, groups, analysis_uuid = NULL) {
  # Use provided analysis UUID or generate a new one
  if (is.null(analysis_uuid)) {
    analysis_uuid <- UUIDgenerate("BAJUUID_analysis_ui")
  }
  # browser()
  UUID_groupAquired = names(groups)[startsWith(names(groups), "UUID_groupAquired:")]
  
  # Create base workspace structure with ALL required fields
  workspace <- list(
    schemaVersion = "2.0.0",
    analysisUUID = analysis_uuid,
    uri = paste0("file:///analyses/analysis-", analysis_uuid, "/analysis-", analysis_uuid, ".json"),
    # version = "11.0",
    reports = list(),
    populationDefinitions = list(),
    compoundParameterSets = list(),
    compoundPopulations = list(),
    paramsetDefinitions = list(),
    groups = list(),
    dataSources = list(),
    platforms = list(),
    cytometers = list(),
    analysisRoot = list()
  )
  
  # Add samples
  workspace$dataSources <- samples
  
  # create paramsetDefinitions
  paramsetDefinitions <- create_paramset_definitions(analysis_uuid, UUID_groupAquired)
  
  # Add gates with proper structure
  for (gate_uuid in names(gates)) {
    gate <- gates[[gate_uuid]]
    # browser()
    
    # Determine if this is an "Ungated" population
    is_ungated <- !is.null(gate$definition$name) &&
      (tolower(gate$definition$name) == "ungated")
    
    # Set the kind appropriately
    kind <- if (is_ungated) "ungated" else "general"
    
    # Move properties to the correct level (same as uuid)
    properties <- gate$definition$properties
    gate$definition$properties <- NULL  # Remove from definition
    
    # Extract gateDefinition and desyncTable if they exist
    # gate_definition_data <- gate$definition$gateDefinition
    # desync_table_data <- gate$definition$desyncTable
    gate$definition$kind = kind
    gate$definition$type = if (is_ungated) "root" else "gate"
    
    # Create the properly structured population definition
    workspace$populationDefinitions[[gate_uuid]] <- list(
      uuid = gate_uuid, # same as populationDefinitions UUID
      properties = properties,  # At the same level as uuid
      definition = gate$definition,
      parents = list(
        "_analysis" = list(analysis_uuid),
        "analysisRoot" = list(analysis_uuid),
        "groups" = list(names(groups)),
        "populationDefinitions" = list(),
        "compoundPopulations" = list(),
        "populations" = list(),
        "paramsetDefinitions" = list(),
        "compoundParameterSets" = list(),
        "dataSources" = list(),
        "cytometers" = list(),
        "platforms" = list(),
        "reports" = list()
      ),
      children = list(
        "analysisRoot" = list(),
        "groups" = list(),
        "populationDefinitions" = list(),
        "compoundPopulations" = list(),
        "populations" = list(),
        "paramsetDefinitions" = list(),
        "compoundParameterSets" = list(),
        "dataSources" = list(),
        "cytometers" = list(),
        "platforms" = list(),
        "reports" = list()
      ),
      results = structure(list(), names = character(0)),
      definitionVersion = 35L,
      resultsVersion = 35L,
      stableSince = 0L,
      recalcVersion = 0L
    )
  }
  
  # Add the "Ungated" population if it doesn't exist
  ungated_exists <- FALSE
  for (gate_uuid in names(workspace$populationDefinitions)) {
    gate <- workspace$populationDefinitions[[gate_uuid]]
    if (!is.null(gate$definition$name) &&
        tolower(gate$definition$name) == "ungated") {
      ungated_exists <- TRUE
      break
    }
  }
  
  # If no "Ungated" population exists, create one
  if (!ungated_exists) {
    ungated_uuid <- UUIDgenerate("BAJUUID_ungated_ui")
    workspace$populationDefinitions[[ungated_uuid]] <- list(
      uuid = ungated_uuid,
      definition = list(
        name = "Ungated",
        type = "root",
        kind = "ungated"
      ),
      parents = list(
        "_analysis" = list(analysis_uuid),
        "analysisRoot" = list(analysis_uuid),
        "groups" = list(),
        "populationDefinitions" = list(),
        "compoundPopulations" = list(),
        "populations" = list(),
        "paramsetDefinitions" = list(),
        "compoundParameterSets" = list(),
        "dataSources" = list(),
        "cytometers" = list(),
        "platforms" = list(),
        "reports" = list()
      ),
      children = list(
        "analysisRoot" = list(),
        "groups" = list(),
        "populationDefinitions" = list(),
        "compoundPopulations" = list(),
        "populations" = list(),
        "paramsetDefinitions" = list(),
        "compoundParameterSets" = list(),
        "dataSources" = list(),
        "cytometers" = list(),
        "platforms" = list(),
        "reports" = list()
      ),
      results = structure(list(), names = character(0)),
      definitionVersion = 35L,
      resultsVersion = 35L,
      stableSince = 0L,
      recalcVersion = 0L
    )
  }
  
  # Add populations
  workspace$populations <- populations
  
  # Add groups
  workspace$groups <- groups
  
  
  # Add placeholder structures for reports, platforms, cytometers
  workspace$reports <- create_placeholder_reports(analysis_uuid)
  workspace$platforms <- create_placeholder_platforms(analysis_uuid)
  workspace$cytometers <- create_cytometers(gs)
  workspace$compoundParameterSets <- create_compound_parameter_sets(analysis_uuid, groups, paramsetDefinitions)
  workspace$compoundPopulations <- create_compound_populations(analysis_uuid, gs, groups, populations, gates, samples)
  workspace$paramsetDefinitions <- paramsetDefinitions
  # Create complete analysisRoot structure
  workspace$analysisRoot <- create_analysis_root(workspace)
  
  # Establish relationships
  # Only establish relationships if we're not preserving original structure
  # When preserving original structure, the relationships should already be correct
  # workspace <- establish_relationships(workspace)
  
  return(workspace)
}

#' Establish Component Relationships
#' 
#' @param workspace Workspace structure
#' @return Updated workspace structure
#' @keywords internal
establish_relationships <- function(workspace) {
  # Connect samples to groups
  for (group_uuid in names(workspace$groups)) {
    group <- workspace$groups[[group_uuid]]
    sample_uuids <- group$results$dataSources
    
    # Add group reference to each sample
    for (sample_uuid in sample_uuids) {
      if (sample_uuid %in% names(workspace$dataSources)) {
        if (is.null(workspace$dataSources[[sample_uuid]]$parents$groups)) {
          workspace$dataSources[[sample_uuid]]$parents$groups <- list()
        }
        workspace$dataSources[[sample_uuid]]$parents$groups <- 
          c(workspace$dataSources[[sample_uuid]]$parents$groups, group_uuid)
      }
    }
  }
  
  return(workspace)
}

#' Get Parent Path
#' 
#' @param pop_path Population path
#' @return Parent path
#' @keywords internal
get_parent_path <- function(pop_path) {
  if (pop_path == "root" || !grepl("/", pop_path)) {
    return("root")
  }
  
  # Split path and remove last element
  path_parts <- strsplit(pop_path, "/")[[1]]
  if (length(path_parts) <= 1) {
    return("root")
  }
  
  parent_path <- paste(head(path_parts, -1), collapse = "/")
  return(if (nchar(parent_path) == 0) "root" else parent_path)
}

#' Find Gate Definition UUID
#' 
#' @param pop_path Population path
#' @return Gate definition UUID or NULL
#' @keywords internal
find_gate_definition_uuid <- function(pop_path) {
  # This is a placeholder - in a real implementation, we would need to
  # maintain a mapping between population paths and gate definition UUIDs
  return(UUIDgenerate("BAJUUID_find_gate_definition_uuid"))
}

remove_duplicate_entries <- function(list_of_lists = gates_data) {
  # Convert each list element to JSON string for comparison
  json_strings <- sapply(list_of_lists, function(x) {
    x$uuid <- "uuid"
    if (!is.null(x) && !is.null(x$definition)) {
      x$definition$uuid <- NULL
    }
    toJSON(x, auto_unbox = TRUE, digits = NA)
  })
  
  # Find unique entries
  unique_indices <- !duplicated(json_strings)
  
  # Create UUID mapping: map duplicates to the retained UUID
  uuid_mapping <- list()
  for (i in seq_along(json_strings)) {
    # Find first occurrence of this json_string
    first_occurrence <- which(json_strings == json_strings[i])[1]
    retained_uuid <- list_of_lists[[first_occurrence]]$uuid
    current_uuid <- list_of_lists[[i]]$uuid
    uuid_mapping[[current_uuid]] <- retained_uuid
  }
  
  return(list(
    unique_list = list_of_lists[unique_indices],
    uuid_mapping = uuid_mapping
  ))
}

update_sample_gate_uuids <- function(sample_gate_uuids, uuid_mapping) {
  lapply(sample_gate_uuids, function(uuid_vector) {
    sapply(uuid_vector, function(uuid) {
      # Replace with mapped UUID if exists, otherwise keep original
      if (uuid %in% names(uuid_mapping)) {
        uuid_mapping[[uuid]]
      } else {
        uuid
      }
    }, USE.NAMES = FALSE)
  })
}

