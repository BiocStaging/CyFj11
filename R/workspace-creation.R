#' @title Create FlowJo Workspace
#' @name workspace-creation
#' @keywords internal
NULL


#' Create Empty Workspace Structure
#' 
#' Creates the basic JSON structure for a FlowJo workspace
#' 
#' @return List representing empty workspace structure
#' @keywords internal
create_empty_workspace_structure <- function() {
  workspace <- list(
    version = "11.0",
    populationDefinitions = list(),
    populations = list(),
    dataSources = list(),
    groups = list(),
    desyncTable = list(),
    compensation = list(),
    transformations = list()
  )
  
  return(workspace)
}

#' Merge Template with Components
#' 
#' Merges a template workspace with new components
#' 
#' @param template Template workspace structure
#' @param samples New samples to add/replace
#' @param gates New gates to add/replace
#' @param populations New populations to add/replace
#' @return Merged workspace structure
#' @keywords internal
merge_template_with_components <- function(template, samples, gates, populations) {
  # Start with template as base
  workspace <- template
  
  # Replace/add samples if provided
  if (!is.null(samples)) {
    workspace$dataSources <- samples
  }
  
  # Replace/add gates if provided
  if (!is.null(gates)) {
    workspace$populationDefinitions <- gates
  }
  
  # Replace/add populations if provided
  if (!is.null(populations)) {
    workspace$populations <- populations
  }
  
  return(workspace)
}

#' Ensure Array Structure in FlowJo JSON
#'
#' Ensures that specific fields in FlowJo JSON structure are arrays rather than scalar values
#'
#' @param data JSON data structure
#' @return JSON data structure with proper array formatting
#' @keywords internal
ensure_array_structure <- function(data) {
  # Define fields that should always be arrays
  array_fields <- c(
    "pageOrder",
    "parents._analysis",
    "parents.analysisRoot",
    "parents.groups",
    "parents.populationDefinitions",
    "parents.compoundPopulations",
    "parents.populations",
    "parents.paramsetDefinitions",
    "parents.compoundParameterSets",
    "parents.dataSources",
    "parents.cytometers",
    "parents.platforms",
    "parents.reports",
    "children.analysisRoot",
    "children.groups",
    "children.populationDefinitions",
    "children.compoundPopulations",
    "children.populations",
    "children.paramsetDefinitions",
    "children.compoundParameterSets",
    "children.dataSources",
    "children.cytometers",
    "children.platforms",
    "children.reports",
    "results.dataSources"
  )
  
  # Recursive function to process nested lists
  process_element <- function(element) {
    if (is.list(element) && !is.data.frame(element)) {
      # Process each component of the list
      for (name in names(element)) {
        element[[name]] <- process_element(element[[name]])
      }
      return(element)
    } else {
      return(element)
    }
  }
  
  # Process the data structure
  return(process_element(data))
}

#' Convert Specific Scalar Values to Arrays
#'
#' Converts specific scalar values to single-element arrays to maintain FlowJo format
#' Only converts fields that should legitimately be arrays, not all scalar values
#'
#' @param obj Object to process
#' @return Object with proper array formatting
#' @keywords internal
convert_scalars_to_arrays <- function(obj) {
  # Fields that should always be arrays - these are specifically the relationship fields
  # that FlowJo uses to track connections between objects
  array_fields <- c(
    "pageOrder",
    "parents._analysis",
    "parents.analysisRoot",
    "parents.groups",
    "parents.populationDefinitions",
    "parents.compoundPopulations",
    "parents.populations",
    "parents.paramsetDefinitions",
    "parents.compoundParameterSets",
    "parents.dataSources",
    "parents.cytometers",
    "parents.platforms",
    "parents.reports",
    "children.analysisRoot",
    "children.groups",
    "children.populationDefinitions",
    "children.compoundPopulations",
    "children.populations",
    "children.paramsetDefinitions",
    "children.compoundParameterSets",
    "children.dataSources",
    "children.cytometers",
    "children.platforms",
    "children.reports",
    "results.dataSources",
    "_group"  # _group fields should be arrays
  )
  
  # Fields that should NEVER be converted to arrays - these should remain scalar
  scalar_fields <- c(
    "schemaVersion",
    "analysisUUID",
    "uri",
    "uuid",
    "definitionVersion",
    "resultsVersion",
    "stableSince",
    "recalcVersion",
    "type",
    "kind",
    "description",
    "color",
    "status",
    "validPopulations",
    "invalidPopulations",
    "count",
    "populationNumber",
    "transformType",
    "minRange",
    "maxRange",
    "decadesOffset",
    "numberDecades",
    "shift",
    "contourLevels",
    "gateResolution",
    "index",
    "representableRange",
    "width",
    "height",
    "value",
    "rows",
    "columns",
    "interval",
    "logRescale",
    "linearRescale"
  )
  
  # Recursive function to process nested lists and atomic values
  process_element <- function(element, path = "") {
    # If this is a list, process each element in the list
    if (is.list(element) && !is.data.frame(element)) {
      # Process each element in the list
      for (name in names(element)) {
        current_path <- if (path == "") name else paste0(path, ".", name)
        
        # Skip scalar fields entirely - they should never be converted
        if (name %in% scalar_fields) {
          # Recursively process nested lists but don't convert this field
          if (is.list(element[[name]]) && !is.data.frame(element[[name]])) {
            element[[name]] <- process_element(element[[name]], current_path)
          }
          next
        }
        
        # Check if this field should be an array using partial matching
        field_should_be_array <- FALSE
        for (array_field in array_fields) {
          # Regular partial matching for other fields
          if (grepl(array_field, current_path, fixed = TRUE)) {
            field_should_be_array <- TRUE
            break
          }
        }
        
        # Special handling for definition.name fields
        # Only convert definition.name fields within populationDefinitions to arrays
        if (endsWith(current_path, "definition.name")) {
          # Check if this is within a population definition
          # Look for paths like populationDefinitions.*.definition.name
          if (grepl("populationDefinitions\\.[^.]+\\.definition\\.name$", current_path)) {
            field_should_be_array <- TRUE
          }
        }
        
        if (field_should_be_array && !is.null(element[[name]])) {
          # Handle different cases for array conversion
          if (is.atomic(element[[name]]) && length(element[[name]]) == 1 && !is.na(element[[name]])) {
            # Single atomic value - convert to single-element array
            # For fields that should be arrays, convert to array
            # For other fields, only convert if it looks like a UUID or reference (contains dashes or is reasonably long)
            value <- element[[name]]
            element[[name]] <- list(value)
          } else if (is.list(element[[name]]) && length(element[[name]]) == 1 &&
                     is.list(element[[name]][[1]]) && is.atomic(element[[name]][[1]]) &&
                     length(element[[name]][[1]]) == 1) {
            # Nested single-element list - flatten it
            element[[name]] <- element[[name]][[1]]
          }
        }
        
        # Recursively process nested lists
        if (is.list(element[[name]]) && !is.data.frame(element[[name]])) {
          element[[name]] <- process_element(element[[name]], current_path)
        }
      }
    }
    
    return(element)
  }
  
  return(process_element(obj))
}

#' Create FlowJo Workspace
#'
create_flowjo_workspace <- function(output_path, template_workspace = NULL,
                                   samples = NULL, gates = NULL, populations = NULL,
                                   template_workspace_data = NULL,
                                   workbench_data = NULL,
                                   preserve_original_structure = FALSE) {
  # Validate inputs
  if (!is.character(output_path) || length(output_path) != 1) {
    stop("output_path must be a single character string")
  }
  
  # Create temporary directory for workspace construction
  temp_dir <- file.path(tempdir(), paste0("workspace_build_", Sys.getpid()))
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Ensure cleanup happens even if function errors
  on.exit({
    if (dir.exists(temp_dir)) {
      unlink(temp_dir, recursive = TRUE)
    }
  })
  
  # save(file = "create_flowjo_workspace.RData", list = ls())
  # browser()
  # Initialize workspace structure
  if (!is.null(template_workspace_data)) {
    # Use the complete workspace structure provided
    workspace_data <- template_workspace_data
    
    # If we're preserving original structure, merge with provided components
    # but preserve the original populationDefinitions if gates is empty/NULL
    if (preserve_original_structure) {
      # Preserve original populationDefinitions if we couldn't extract gates properly
      original_population_definitions <- workspace_data$populationDefinitions
      
      workspace_data <- merge_template_with_components(
        workspace_data, samples, gates, populations
      )
      
      # If gates extraction failed or resulted in empty gates, preserve original populationDefinitions
      if (is.null(gates) || length(gates) == 0 || length(workspace_data$populationDefinitions) == 0) {
        workspace_data$populationDefinitions <- original_population_definitions
      }
      
      # Ensure proper array structure for FlowJo format
      workspace_data <- convert_scalars_to_arrays(workspace_data)
    }
  } else if (is.null(template_workspace)) {
    # Create empty workspace
    workspace_data <- create_empty_workspace_structure()
    
    # Merge with provided components
    workspace_data <- merge_template_with_components(
      workspace_data, samples, gates, populations
    )
    
    # Ensure proper array structure for FlowJo format
    workspace_data <- convert_scalars_to_arrays(workspace_data)
  } else {
    # Load template workspace
    if (!file.exists(template_workspace)) {
      stop("Template workspace file does not exist: ", template_workspace)
    }
    
    # Process template workspace
    template_result <- tryCatch({
      process_zip_archive(template_workspace)
    }, error = function(e) {
      stop("Failed to process template workspace: ", e$message)
    })
    
    # Extract JSON data from template
    if (length(template_result$json) == 0) {
      stop("No JSON data found in template workspace")
    }
    
    # Get first JSON file (should be analysis-*.json)
    json_files <- names(template_result$json)
    workspace_data <- template_result$json[[json_files[1]]]
    
    # Merge with provided components
    workspace_data <- merge_template_with_components(
      workspace_data, samples, gates, populations
    )
    
    # Ensure proper array structure for FlowJo format
    workspace_data <- convert_scalars_to_arrays(workspace_data)
  }
  
  # Generate unique analysis filename or use existing one from template
  if (!is.null(template_workspace_data) && !is.null(template_workspace_data$analysisUUID)) {
    # Use the analysis UUID from the template data
    analysis_uuid <- template_workspace_data$analysisUUID
  } else {
    # Generate a new analysis UUID
    analysis_uuid = UUIDgenerate()
  }
  
  # workspace_data <- update_data_sources(workspace_data)
  
  json_string <- toJSON(workspace_data, auto_unbox = TRUE, pretty = T, always_decimal = TRUE)
  json_string <- stringr::str_replace_all(json_string, 'ANALYSIS_UUID', analysis_uuid)
  # browser()
  json_string <- stringr::str_replace_all(json_string, 'PLATFORMS_UUID', names(workspace_data$platforms[[1]])[1])
  json_string <- stringr::str_replace_all(json_string, 'BAJUUID_analysis_ui:', "")
  
  
  json_string <- update_compoundPopulations(json_string, workspace_data)
  json_string <- update_data_sources(json_string, workspace_data)
 
  # populations children compoundPopulations "compoundPopulationsREF"
  # populations parents populations "reference to something"
  # populations
  
  json_string <- stringr::str_replace_all(json_string, '\"BAJUUID_[^:]+:', '\"')
  real_analysis_uuid = stringr::str_replace_all(analysis_uuid, "BAJUUID_analysis_ui:", "")
  
  analysis_filename <- paste0("analysis-", real_analysis_uuid, ".json")
  # Create analysis directory structure
  analysis_dir_name <- paste0("analyses/analysis-", real_analysis_uuid)
  analysis_dir <- file.path(temp_dir, analysis_dir_name)
  dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)

  analysis_path <- file.path(analysis_dir, analysis_filename)

  write(json_string, analysis_path)
  
  # Create manifest file
  manifest_path <- file.path(analysis_dir, paste0("analysis-", real_analysis_uuid,"_manifest.txt"))
  writeLines("[]", manifest_path)
  
  
  # Create ZIP archive
  zip_files <- c(manifest_path, analysis_path)
  # Check if additional files exist in template
  if (!is.null(template_workspace) && file.exists(template_workspace)) {
    # Extract any additional files from template
    template_dir <- file.path(tempdir(), paste0("template_extract_", Sys.getpid()))
    dir.create(template_dir, recursive = TRUE, showWarnings = FALSE)
    on.exit({
      if (dir.exists(template_dir)) {
        unlink(template_dir, recursive = TRUE)
      }
      if (dir.exists(temp_dir)) {
        unlink(temp_dir, recursive = TRUE)
      }
    }, add = TRUE)
    
    # Extract template files
    utils::unzip(template_workspace, exdir = template_dir)
    template_files <- list.files(template_dir, full.names = TRUE, recursive = TRUE)
    
    # Filter out manifest and analysis files (we're creating new ones)
    additional_files <- template_files[!grepl("manifest\\.txt$|analysis-.*\\.json$", template_files)]
    
    # Copy additional files to our temp directory
    for (file_path in additional_files) {
      rel_path <- substr(file_path, nchar(template_dir) + 2, nchar(file_path))
      dest_path <- file.path(temp_dir, rel_path)
      dir.create(dirname(dest_path), recursive = TRUE, showWarnings = FALSE)
      file.copy(file_path, dest_path, overwrite = TRUE)
    }
    
    # Update zip_files to include additional files
    zip_files <- c(zip_files, list.files(temp_dir, full.names = TRUE, recursive = TRUE)[
      !grepl("manifest\\.txt$|analysis-.*\\.json$", list.files(temp_dir, full.names = TRUE, recursive = TRUE))
    ])
  } else {
    # Create required FlowJo workspace files when no template is provided
    # Create workbench.json
    # browser()
    if (is.null(workbench_data)) {
      # Generate new workbench data if none provided
      workbench_data <- list(
        id = UUIDgenerate(),  # Generate a separate workbench ID
        name = basename(output_path),
        analyses = list(real_analysis_uuid),
        uri = file.path(getwd(), output_path)
      )
    } else {
      # Update existing workbench data with correct values
      workbench_data$name <- basename(output_path)
      workbench_data$analyses <- list(real_analysis_uuid)  # Ensure it's a list
      workbench_data$uri <- file.path(getwd(), output_path)
    }
    workbench_path <- file.path(temp_dir, "workbench.json")
    jsonlite::write_json(workbench_data, workbench_path, auto_unbox = TRUE, pretty = FALSE, always_decimal = TRUE)
    
    # Create preferences.json
    preferences_data <- list(version = "2.0.0")
    preferences_path <- file.path(temp_dir, "preferences.json")
    jsonlite::write_json(preferences_data, preferences_path, auto_unbox = TRUE, pretty = FALSE, always_decimal = TRUE)

    # Create analysis manifest with empty array
    analysis_manifest_path <- file.path(analysis_dir, paste0("analysis-", real_analysis_uuid, "_manifest.txt"))
    writeLines("[]", analysis_manifest_path)
  }
  
  # Collect all files for ZIP creation, preserving directory structure
  all_files <- list.files(temp_dir, full.names = TRUE, recursive = TRUE)
  
  # Change to temp directory to ensure relative paths
  original_wd <- getwd()
  on.exit(setwd(original_wd), add = TRUE)
  setwd(temp_dir)
  
  # Get relative paths for ZIP creation
  relative_paths <- substring(all_files, nchar(temp_dir) + 2)
  
  # Check if output_path is absolute, if not, make it relative to original working directory
  final_output_path <- if (grepl("^(/|[A-Za-z]:)", output_path)) {
    # output_path is absolute, use as is
    output_path
  } else {
    # output_path is relative, make it relative to original working directory
    file.path(original_wd, output_path)
  }
  
  zip_result <- tryCatch({
    zip::zip(final_output_path, relative_paths)
  }, error = function(e) {
    stop("Failed to create workspace ZIP archive: ", e$message)
  })
  
  # Verify file was created
  if (!file.exists(final_output_path)) {
    stop("Failed to create workspace file")
  }
  
  message("Successfully created FlowJo workspace: ", final_output_path)
  return(TRUE)
}


update_compoundPopulations <- function(json_str, workspace_data){
  compound_pops <- names(workspace_data$compoundPopulations)
  for (pop in compound_pops) {
    parts <- strsplit(pop, ":")[[1]]
    prefix <- parts[1]  
    uuid <- parts[2] 
    search_pattern <- paste0('"', prefix, '"')
    replacement <- paste0('"', uuid, '"')
    json_str <- gsub(search_pattern, replacement, json_str, fixed = TRUE)
  }
   json_str
}

update_data_sources <- function(json_str, workspace_data){
  # "_dataSource": [
  #   "A06 MIv3_Donor_0996_Innate_09-05-2022 WLSM.fcs"
  # ]
  for(ds in seq(workspace_data$dataSources)){
    file_name = workspace_data$dataSources[[ds]]$definition$customKeywords$`File Name`
    search_pattern <- paste0('"', file_name, '"')
    uuid <- workspace_data$dataSources[[ds]]$uuid
    replacement <- paste0('"', uuid, '"')
    json_str <- gsub(search_pattern, replacement, json_str, fixed = TRUE)
  }
  json_str
}