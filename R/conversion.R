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

#' @title Convert FlowJo v11 Workspace to GatingSet
#' @name conversion
#' @keywords internal
#' @importFrom flowWorkspace GatingSet cytoset load_cytoset_from_fcs gs_pop_add gs_get_pop_paths recompute sampleNames gs_pop_get_gate
#' @importFrom dplyr filter enquo
NULL

#' Convert FlowJo v11 Workspace to GatingSet
#'
#' Parses a FlowJo v11 workspace and creates a GatingSet object with gating hierarchy,
#' compensation, and transformations. Supports biexponential (Biex) transformations
#' which are mapped to logicle transforms.
#'
#' @param fj11_workspace List returned by \code{read_flowjo11_workspace()} containing
#'   the complete workspace structure
#' @param group_name Character or numeric. Name or index of the sample group to import.
#'   If NULL, will list available groups interactively.
#' @param subset Numeric vector, character vector of FCS filenames, or expression
#'   to filter samples. See Details.
#' @param execute Logical. Should gates be executed immediately? Default TRUE.
#'   If FALSE, creates GatingSet structure without computing cell counts.
#' @param path Character. Root directory to search for FCS files. Required if
#'   FCS files are not in workspace location.
#' @param cytoset A cytoset object providing alternative data source (instead of FCS files).
#'   Useful for preprocessed data.
#' @param backend_dir Directory for storing h5 backend data. Default is tempdir().
#' @param backend Character. Storage backend, either "h5" or "tile". Default "h5".
#' @param include_gates Logical. Should gates be imported? Default TRUE.
#' @param compensation Compensation object, matrix, data.frame, or named list of these.
#'   Overrides workspace compensation. Names should match sample GUIDs.
#' @param additional.keys Character vector of FCS keywords to include in sample GUID
#'   (concatenated with filename). Default is "$TOT".
#' @param additional.sampleID Logical. Include FlowJo sample ID in GUID? Default FALSE.
#' @param keywords Character vector of keywords to extract as pData.
#' @param keyword.ignore.case Logical. Case-insensitive keyword matching? Default FALSE.
#' @param channel.ignore.case Logical. Case-insensitive channel matching? Default FALSE.
#' @param extend_val Numeric. Threshold for extending gate coordinates. Default 0.
#' @param extend_to Numeric. Value to extend gates to. Default -4000.
#' @param leaf.bool Logical. Compute leaf boolean gates? Default TRUE.
#' @param include_empty_tree Logical. Include samples without gates? Default FALSE.
#' @param correct_faulty_gate Numerical, zero = don't correct, otherwise use this value as transformation max value and Try to correct faulty gates instead of erroring? Default TRUE.
#' @param transform Logical. Apply transformations? Default TRUE.
#' @param use_transformed_coords Logical. Keep gate coordinates in FlowJo display
#'   (transformed) space rather than raw space? Default is the value of \code{transform}.
#'   Only relevant when \code{transform = TRUE}.
#' @param max_search_depth Integer. Maximum directory depth when searching for FCS files.
#'   Default 5.
#' @param stop_on_multiple Logical. Stop if multiple FCS files match a sample?
#'   When TRUE, stops on both missing files and multiple matches.
#'   When FALSE, only stops on missing files and continues with multiple matches.
#'   Default TRUE.
#' @param mc.cores Integer. Number of cores for parallel processing. Default 1.
#' @param ... Additional arguments passed to FCS parser.
#'
#' @details
#' The \code{subset} argument can be:
#' \describe{
#'   \item{Numeric vector: }{Sample indices to import}
#'   \item{Character vector: }{FCS filenames to import}
#'   \item{Expression: }{Logical expression to filter pData (requires \code{keywords} argument)}
#' }
#'
#' FlowJo v11 stores data differently than v10:
#' \describe{
#'   \item{populationDefinitions: }{Master gate definitions}
#'   \item{desyncTable: }{Per-sample gate variations (tailored gates)}
#'   \item{groups: }{Sample groupings}
#'   \item{dataSources: }{FCS file references}
#' }
#'
#' @return A named list of \code{GatingSet} objects, one per sample. Each element
#'   contains the full gating hierarchy, gates, compensation, and transformations for
#'   that sample. To obtain a single merged \code{GatingSet} for downstream analysis,
#'   call \code{flowWorkspace::merge_list_to_gs(gsList)} on the returned list.
#'
#' @examples
#' \dontrun{
#' # Parse FlowJo v11 workspace
#' ws <- read_flowjo11_workspace("workspace.flowjo")
#'
#' # Convert to a list of per-sample GatingSets
#' gsList <- fj11_to_gatingset(ws, group_name = 1, path = "/path/to/fcs/files")
#'
#' # Merge into a single GatingSet for downstream analysis
#' gs <- flowWorkspace::merge_list_to_gs(gsList)
#'
#' # Subset samples
#' gsList <- fj11_to_gatingset(ws, group_name = 1,
#'                             subset = c("sample1.fcs", "sample2.fcs"),
#'                             path = "/path/to/fcs")
#'
#' # Extract keywords as pData
#' gsList <- fj11_to_gatingset(ws, group_name = 1,
#'                             keywords = c("$DATE", "$BTIM", "PATIENT ID"),
#'                             path = "/path/to/fcs")
#'
#' # Parse without executing (faster for structure inspection)
#' gsList <- fj11_to_gatingset(ws, group_name = 1,
#'                             execute = FALSE,
#'                             path = "/path/to/fcs")
#'
#' # Filter samples by pData
#' gsList <- fj11_to_gatingset(ws, group_name = 1,
#'                             subset = PATIENT == "P001",
#'                             keywords = "PATIENT",
#'                             path = "/path/to/fcs")
#'
#' # Custom compensation
#' comp_matrix <- matrix(...)
#' gsList <- fj11_to_gatingset(ws, group_name = 1,
#'                             compensation = comp_matrix,
#'                             path = "/path/to/fcs")
#' }
#'
#' @param strip_comp_prefix Logical. Strip "Comp-" prefix from gate parameter names
#'   when adding populations? Default TRUE. Set to FALSE if compensation has already
#'   been applied and gate names should match the compensated parameter names.
#' @export
#' @importFrom flowWorkspace GatingSet cytoset load_cytoset_from_fcs gs_pop_add gs_get_pop_paths recompute
#' @importFrom dplyr filter enquo
#' @importFrom utils menu
fj11_to_gatingset <- function(fj11_workspace,
                              group_name = NULL,
                              subset = list(),
                              execute = TRUE,
                              path = NULL,
                              cytoset = NULL,
                              backend_dir = tempdir(),
                              backend = c("h5", "tile"),
                              include_gates = TRUE,
                              compensation = NULL,
                              additional.keys = "$TOT",
                              additional.sampleID = FALSE,
                              keywords = character(),
                              keyword.ignore.case = FALSE,
                              channel.ignore.case = FALSE,
                              extend_val = 0,
                              extend_to = -4000,
                              leaf.bool = TRUE,
                              include_empty_tree = FALSE,
                              correct_faulty_gate = 0,
                              transform = TRUE,
                              use_transformed_coords = transform,
                              max_search_depth = 5,
                              stop_on_multiple = TRUE,
                              mc.cores = 1,
                              strip_comp_prefix = TRUE,
                              ...) {
  backend <- match.arg(backend)
  # Extract workspace components
  # The workspace already has the components extracted at the top level
  groups <- fj11_workspace$groups
  dataSources <- fj11_workspace$dataSources
  populationDefinitions <- fj11_workspace$populationDefinitions
  populations <- fj11_workspace$populations
  platforms <- fj11_workspace$platforms
  
  # Step 1: Select group ----
  group_info <- get_group_info(groups)
  
  if (is.null(group_name)) {
    group_idx <- menu(group_info$name, graphics = FALSE,
                      title = "Choose which group of samples to import:")
    if (group_idx == 0) stop("No group selected")
  } else if (is.numeric(group_name)) {
    if (group_name > nrow(group_info)) {
      stop("Invalid group index: ", group_name)
    }
    group_idx <- group_name
  } else if (is.character(group_name)) {
    group_idx <- which(group_info$name == group_name)
    if (length(group_idx) == 0) {
      stop("Group not found: ", group_name)
    }
  }
  
  selected_group_uuid <- group_info$uuid[group_idx]
  selected_group <- groups[[selected_group_uuid]]
  
  if (.pkgenv$verbose) {
    cat("Selected group:", group_info$name[group_idx], "\n")
    cat("Contains", length(selected_group$results$dataSources), "samples\n")
  }
  # Step 2: Get samples in group ----
  sample_uuids <- selected_group$results$dataSources
  
  # Filter samples based on subset argument
  sample_uuids <- filter_samples(sample_uuids, subset, dataSources, keywords)
  
  if (.pkgenv$verbose) cat("Processing", length(sample_uuids), "samples\n\n")
  
  # Step 3: Resolve FCS file paths ----
  if (is.null(cytoset)) {
    if (is.null(path)) {
      stop("Either 'path' or 'cytoset' must be provided")
    }
    
    if (.pkgenv$verbose) cat("Resolving FCS file paths...\n")
    path_resolution <- resolve_all_fcs_paths(
      dataSources = dataSources,
      root_dir = path,
      stop_on_multiple = stop_on_multiple,
      stop_on_missing = TRUE
    )
    
    # Filter to selected samples
    path_resolution <- path_resolution[path_resolution$sample_id %in% sample_uuids, ]
    
    # Check for resolution failures
    # Only stop on missing files when stop_on_multiple=FALSE
    # When stop_on_multiple=TRUE, stop on both missing and multiple matches
    if (stop_on_multiple) {
      # Strict mode: stop on any failure (missing or multiple)
      failed <- path_resolution[path_resolution$status != "FOUND", ]
      if (nrow(failed) > 0) {
        stop("Could not resolve ", nrow(failed), " FCS file(s). See path_resolution for details.")
      }
    } else {
      # Permissive mode: only stop on truly missing files, allow multiple matches
      failed <- path_resolution[path_resolution$status == "NOT_FOUND" | path_resolution$status == "NO_URI", ]
      if (nrow(failed) > 0) {
        stop("Could not resolve ", nrow(failed), " FCS file(s). Missing files detected. See path_resolution for details.")
      }
    }
    
    # Create sample file map
    if (stop_on_multiple) {
      # Strict mode: only include FOUND samples
      sample_file_map <- get_sample_file_map(path_resolution)
    } else {
      # Permissive mode: include both FOUND and MULTIPLE samples
      # For FOUND samples, use resolved_path directly
      found_rows <- path_resolution$status == "FOUND"
      sample_file_map <- setNames(path_resolution$resolved_path[found_rows], path_resolution$sample_id[found_rows])
      
      # For MULTIPLE samples, extract the first path from the resolved_path field
      multiple_rows <- path_resolution$status == "MULTIPLE"
      if (any(multiple_rows)) {
        # Split the resolved_path by " | " and take the first path
        first_paths <- sapply(strsplit(path_resolution$resolved_path[multiple_rows], " \\| "), `[`, 1)
        names(first_paths) <- path_resolution$sample_id[multiple_rows]
        sample_file_map <- c(sample_file_map, first_paths)
      }
    }
  }
  
  # Step 4: Load data into cytoset ----
  if (is.null(cytoset)) {
    if (.pkgenv$verbose) cat("\nLoading FCS files into cytoset...\n")
    fcs_files <- sample_file_map[unlist(sample_uuids)]
    
    # Create cytoset from FCS files
    cytoset <- flowWorkspace::load_cytoset_from_fcs(
      files = fcs_files,
      transformation = FALSE,
      backend_dir = backend_dir,
      backend = backend,
      ...
    )
  }
  
  # Step 5: Build gating hierarchy ----
  if (.pkgenv$verbose) cat("\nBuilding gating hierarchy...\n")
  
  # Get root population (usually the ungated data)
  root_pop_uuid <- find_root_population(populations, populationDefinitions, sample_uuids[1])
  # browser()
  # Build hierarchy tree for each sample
  # browser()
  gating_trees <- lapply(sample_uuids, function(sample_uuid) {
    build_gating_tree(
      sample_uuid = sample_uuid,
      populations = populations,
      populationDefinitions = populationDefinitions,
      root_uuid = root_pop_uuid
    )
  })
  # Step 8: Extract transformations ----
  if (.pkgenv$verbose) cat("\nExtracting transformations...\n")
  trans_list <- extract_transformations(
    populationDefinitions = populationDefinitions,
    sample_uuids = sample_uuids
  )
  
  # Step 6: Extract gates ----
  if (include_gates) {
    if (.pkgenv$verbose) cat("\nExtracting gates...\n")

    # save(file = "extract_all_gates.Rdata", list = ls())
    # load("extract_all_gates.Rdata")
    gates_list <- extract_all_gates(
      populationDefinitions = populationDefinitions,
      sample_uuids = sample_uuids,
      channel.ignore.case = channel.ignore.case,
      extend_val = extend_val,
      extend_to = extend_to,
      correct_faulty_gate = correct_faulty_gate,
      use_transformed_coords = use_transformed_coords
    )
  }
  # browser()
  # Step 7: Extract compensation ----
  if (.pkgenv$verbose) cat("\nExtracting compensation matrices...\n")
  comp_list <- extract_compensation(
    dataSources = dataSources,
    sample_uuids = sample_uuids,
    custom_compensation = compensation,
    platforms = platforms
  )
  cat("\n=== COMPENSATION DIAGNOSTIC ===\n")
  cat("Number of samples:", length(sample_uuids), "\n")
  cat("Number of comp matrices found:", length(comp_list), "\n")
  cat("Comp list names:", paste(names(comp_list), collapse="\n  "), "\n")
  cat("Sample UUIDs:\n  ", paste(unlist(sample_uuids), collapse="\n  "), "\n")
  
  # Check if UUIDs match
  for (uuid in unlist(sample_uuids)) {
    found <- !is.null(comp_list[[uuid]])
    cat("UUID", substr(uuid,1,8), "... → comp found:", found, "\n")
  }
  cat("================================\n\n")
  
  # browser()
  # Step 9: Create per-sample GatingSet list ----
  if (.pkgenv$verbose) cat("\nCreating GatingSet list...\n")
  gsList <- create_gatingset_from_cytoset(
    cytoset = cytoset,
    gating_trees = gating_trees,
    gates = if (include_gates) gates_list else NULL,
    compensations = comp_list,
    transformations = if (transform) trans_list else NULL,
    sample_uuids = sample_uuids,
    dataSources = dataSources,
    keywords = keywords,
    additional.keys = additional.keys,
    additional.sampleID = additional.sampleID,
    keyword.ignore.case = keyword.ignore.case,
    strip_comp_prefix = strip_comp_prefix
  )

  # browser()
  # Step 10: Execute gating ----
  if (execute && include_gates) {
    if (.pkgenv$verbose) cat("\nExecuting gates...\n")

    lapply(gsList, flowWorkspace::recompute)

    if (.pkgenv$verbose) cat("Gating complete\n")
  } else {
    if (.pkgenv$verbose) cat("Gating not executed (set execute=TRUE to compute cell counts)\n")
  }

  # # Step 11: Compute boolean gates ----
  if (.pkgenv$verbose) {
    cat("\n")
    cat("========================================\n")
    cat("  GatingSet List Created Successfully\n")
    cat("========================================\n")
    cat("Samples:     ", length(gsList), "\n")

    # Safely get population count
    if (!is.null(gsList) && length(gsList) > 0 && !is.null(gsList[[1]])) {
      cat("Populations: ", length(flowWorkspace::gs_get_pop_paths(gsList[[1]])), "\n")
    } else {
      cat("Populations: 0 (GatingSet list is empty)\n")
    }

    cat("Execute:     ", execute, "\n")
    cat("======================================\n\n")

    # Debug information before returning
    cat("DEBUG: About to return GatingSet\n")
    cat("DEBUG: gs is null:", is.null(gs), "\n")
  }
  return(gsList)
}


#' Export GatingSet to FlowJo v11 Workspace
#'
#' Converts a GatingSet object to FlowJo v11 workspace format (.flowjo file)
#'
#' @param gs GatingSet object to export
#' @param output_file Path to output .flowjo file
#' @param workspace_name Name for the workspace (default: derived from filename)
#' @param group_name Name for the sample group (default: "All Samples")
#' @return Invisible NULL. Creates the output file as a side effect.
#' @export
#' @importFrom jsonlite toJSON write_json
#' @importFrom flowWorkspace gs_get_compensations sampleNames
gatingset_to_fj11 <- function(gs,
                              output_file,
                              workspace_name = NULL,
                              group_name = "All Samples") {
  
  if (!inherits(gs, "GatingSet")) {
    stop("gs must be a GatingSet object")
  }
  
  # Set workspace name
  if (is.null(workspace_name)) {
    workspace_name <- tools::file_path_sans_ext(basename(output_file))
  }
  
  # Create workspace structure
  message("Creating FlowJo v11 workspace structure...")
  workspace <- create_fj11_workspace_structure(workspace_name)
  
  # Extract and format compensation
  message("Extracting compensation matrices...")
  comp_data <- export_compensation_platforms(gs)
  workspace$platforms$spilloverMatrix <- comp_data$platforms
  
  # Export samples/dataSources
  message("Exporting samples...")
  samples_data <- export_datasources_fj11(gs, comp_data$comp_uuids)
  workspace$dataSources <- samples_data$dataSources
  
  # Create sample group
  message("Creating sample groups...")
  group_data <- create_sample_group_fj11(samples_data$sample_uuids, group_name)
  workspace$groups <- group_data
  
  # Export populations
  message("Exporting population hierarchy...")
  pop_data <- export_populations_fj11(gs, samples_data$sample_uuids)
  workspace$populationDefinitions <- pop_data$populationDefinitions
  workspace$populations <- pop_data$populations
  
  # Write to file
  message("Writing to file: ", output_file)
  jsonlite::write_json(
    workspace,
    output_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )
  
  message("Export complete!")
  invisible(NULL)
}


#' Create FlowJo v11 Workspace Structure
#' @keywords internal
create_fj11_workspace_structure <- function(workspace_name) {
  analysis_uuid <- generate_flowjo11_uuid()
  
  list(
    schemaVersion = 3,
    analysisUUID = analysis_uuid,
    uri = paste0("file:///", workspace_name, ".flowjo"),
    version = "11.0",
    workspace = list(
      name = workspace_name,
      modificationTime = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
    ),
    analysisRoot = list(
      uuid = analysis_uuid,
      properties = list(),
      definition = list(),
      parents = list(),
      children = list(
        groups = list(),
        populationDefinitions = list(),
        populations = list(),
        platforms = list(),
        dataSources = list()
      ),
      results = list(),
      definitionVersion = 2,
      resultsVersion = 2,
      stableSince = 0,
      recalcVersion = 0
    ),
    groups = list(),
    populationDefinitions = list(),
    populations = list(),
    dataSources = list(),
    platforms = list(
      spilloverMatrix = list()
    )
  )
}


#' Export Compensation Platforms from GatingSet
#' @keywords internal
export_compensation_platforms <- function(gs) {
  # Get compensation matrices
  comp_list <- flowWorkspace::gs_get_compensations(gs)
  
  platforms <- list()
  comp_uuids <- list()
  
  # Handle NULL compensation list
  if (is.null(comp_list) || length(comp_list) == 0) {
    message("No compensation found in GatingSet")
    return(list(platforms = list(), comp_uuids = list()))
  }
  
  # Check if all samples have the same compensation
  comp_matrices <- lapply(comp_list, function(x) {
    if (is.null(x)) return(NULL)
    if (methods::is(x, "compensation")) return(x@spillover)
    return(x)
  })
  
  # Remove NULL matrices
  valid_indices <- !sapply(comp_matrices, is.null)
  comp_matrices <- comp_matrices[valid_indices]
  comp_list <- comp_list[valid_indices]
  
  if (length(comp_matrices) == 0) {
    message("No valid compensation matrices found")
    return(list(platforms = list(), comp_uuids = list()))
  }
  
  # Check if all compensation matrices are identical
  is_shared <- FALSE
  if (length(comp_matrices) > 0) {
    first_matrix_str <- paste(comp_matrices[[1]], collapse = ",")
    is_shared <- all(sapply(comp_matrices, function(m) {
      if (is.null(m)) return(FALSE)
      paste(m, collapse = ",") == first_matrix_str
    }))
  }
  
  if (is_shared) {
    # Single shared compensation
    comp_uuid <- generate_flowjo11_uuid()
    platforms[[comp_uuid]] <- format_compensation_for_flowjo11(
      comp_list[[1]],
      comp_uuid = comp_uuid,
      comp_name = "Acquisition-defined"
    )
    
    # Map all samples to this compensation
    for (sample_name in names(comp_list)) {
      comp_uuids[[sample_name]] <- comp_uuid
    }
  } else {
    # Per-sample compensation
    for (sample_name in names(comp_list)) {
      comp_uuid <- generate_flowjo11_uuid()
      platforms[[comp_uuid]] <- format_compensation_for_flowjo11(
        comp_list[[sample_name]],
        comp_uuid = comp_uuid,
        comp_name = paste0("Compensation-", sample_name)
      )
      comp_uuids[[sample_name]] <- comp_uuid
    }
  }
  
  list(
    platforms = platforms,
    comp_uuids = comp_uuids
  )
}


#' Export Data Sources for FlowJo v11
#' @keywords internal
export_datasources_fj11 <- function(gs, comp_uuids) {
  sample_names <- flowWorkspace::sampleNames(gs)
  dataSources <- list()
  sample_uuids <- list()
  
  for (sample_name in sample_names) {
    sample_uuid <- generate_flowjo11_uuid()
    sample_uuids[[sample_name]] <- sample_uuid
    
    # Get FCS file path
    fcs_path <- tryCatch({
      gs[[sample_name]]@data@file
    }, error = function(e) {
      paste0(sample_name, ".fcs")
    })
    
    # Get compensation UUID for this sample
    comp_uuid <- comp_uuids[[sample_name]]
    
    dataSources[[sample_uuid]] <- list(
      uuid = sample_uuid,
      properties = list(),
      definition = list(
        uri = fcs_path,
        customKeywords = list(
          "File Name" = basename(fcs_path)
        )
      ),
      parents = list(
        platforms = list(comp_uuid)
      ),
      children = list(),
      results = list(),
      definitionVersion = 1,
      resultsVersion = 1
    )
  }
  
  list(
    dataSources = dataSources,
    sample_uuids = sample_uuids
  )
}


#' Create Sample Group for FlowJo v11
#' @keywords internal
create_sample_group_fj11 <- function(sample_uuids, group_name) {
  group_uuid <- generate_flowjo11_uuid()
  
  groups <- list()
  groups[[group_uuid]] <- list(
    uuid = group_uuid,
    properties = list(),
    definition = list(
      name = group_name
    ),
    parents = list(),
    children = list(),
    results = list(
      dataSources = unname(sample_uuids)
    ),
    definitionVersion = 1,
    resultsVersion = 1
  )
  
  groups
}


#' Export Population Hierarchy for FlowJo v11
#' @keywords internal
export_populations_fj11 <- function(gs, sample_uuids) {
  # This is a simplified implementation
  # A full implementation would need to extract the complete gating hierarchy
  
  populationDefinitions <- list()
  populations <- list()
  
  # Get root population for each sample
  sample_names <- flowWorkspace::sampleNames(gs)
  
  for (i in seq_along(sample_names)) {
    sample_name <- sample_names[i]
    sample_uuid <- sample_uuids[[sample_name]]
    
    # Create root population definition
    root_popdef_uuid <- generate_flowjo11_uuid()
    populationDefinitions[[root_popdef_uuid]] <- list(
      uuid = root_popdef_uuid,
      properties = list(),
      definition = list(
        name = "root",
        type = "root"
      ),
      parents = list(),
      children = list(),
      results = list(),
      definitionVersion = 1,
      resultsVersion = 1
    )
    
    # Create root population instance
    root_pop_uuid <- generate_flowjo11_uuid()
    populations[[root_pop_uuid]] <- list(
      uuid = root_pop_uuid,
      properties = list(),
      definition = list(),
      parents = list(
        "_dataSource" = list(sample_uuid),
        populationDefinitions = list(root_popdef_uuid)
      ),
      children = list(
        populations = list()
      ),
      results = list(),
      definitionVersion = 1,
      resultsVersion = 1
    )
  }
  
  list(
    populationDefinitions = populationDefinitions,
    populations = populations
  )
}