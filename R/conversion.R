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
#' @return A \code{GatingSet} object containing the gating hierarchy, gates, and optionally
#'   the gated data and population statistics.
#'
#' @examples
#' \dontrun{
#' # Parse FlowJo v11 workspace
#' ws <- read_flowjo11_workspace("workspace.flowjo")
#'
#' # Convert to GatingSet (simplest form)
#' gs <- fj11_to_gatingset(ws, group_name = 1, path = "/path/to/fcs/files")
#'
#' # Subset samples
#' gs <- fj11_to_gatingset(ws, group_name = 1,
#'                         subset = c("sample1.fcs", "sample2.fcs"),
#'                         path = "/path/to/fcs")
#'
#' # Extract keywords as pData
#' gs <- fj11_to_gatingset(ws, group_name = 1,
#'                         keywords = c("$DATE", "$BTIM", "PATIENT ID"),
#'                         path = "/path/to/fcs")
#'
#' # Parse without executing (faster for structure inspection)
#' gs <- fj11_to_gatingset(ws, group_name = 1,
#'                         execute = FALSE,
#'                         path = "/path/to/fcs")
#'
#' # Filter samples by pData
#' gs <- fj11_to_gatingset(ws, group_name = 1,
#'                         subset = PATIENT == "P001",
#'                         keywords = "PATIENT",
#'                         path = "/path/to/fcs")
#'
#' # Custom compensation
#' comp_matrix <- matrix(...)
#' gs <- fj11_to_gatingset(ws, group_name = 1,
#'                         compensation = comp_matrix,
#'                         path = "/path/to/fcs")
#' }
#'
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
                              max_search_depth = 5,
                              stop_on_multiple = TRUE,
                              mc.cores = 1,
                              ...) {
  
  backend <- match.arg(backend)
  # Extract workspace components
  # The workspace already has the components extracted at the top level
  groups <- fj11_workspace$groups
  dataSources <- fj11_workspace$dataSources
  populationDefinitions <- fj11_workspace$populationDefinitions
  populations <- fj11_workspace$populations
  
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
      extend_to = extend_to, correct_faulty_gate = correct_faulty_gate
    )
  }
  # browser()
  # Step 7: Extract compensation ----
  if (.pkgenv$verbose) cat("\nExtracting compensation matrices...\n")
  comp_list <- extract_compensation(
    dataSources = dataSources,
    sample_uuids = sample_uuids,
    custom_compensation = compensation
  )
  
  # browser()
  # Step 9: Create GatingSet ----
  if (.pkgenv$verbose) cat("\nCreating GatingSet...\n")
  # this is now a GatingsetList!!
  gs <- create_gatingset_from_cytoset(
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
    keyword.ignore.case = keyword.ignore.case
  )
  
  # Debug: Check if GatingSet was created successfully
  if (.pkgenv$verbose) {
    cat("DEBUG: After creating GatingSet\n")
    cat("DEBUG: gs is null:", is.null(gs), "\n")
    
    if (!is.null(gs)) {
      cat("DEBUG: gs length:", length(gs), "\n")
      if (length(gs) > 0) {
        cat("DEBUG: gs[[1]] is null:", is.null(gs[[1]]), "\n")
      }
    }
  }
  # browser()
  # Step 10: Execute gating ----
  if (execute && include_gates) {
    if (.pkgenv$verbose) cat("\nExecuting gates...\n")
    
    lapply(gs,flowWorkspace::recompute)
    
    if (.pkgenv$verbose) cat("Gating complete\n")
  } else {
    if (.pkgenv$verbose) cat("Gating not executed (set execute=TRUE to compute cell counts)\n")
  }
  
  # # Step 11: Compute boolean gates ----
  if (.pkgenv$verbose) {
    cat("\n")
    cat("========================================\n")
    cat("  GatingSet Created Successfully\n")
    cat("========================================\n")
    cat("Samples:     ", length(gs), "\n")
    
    # Safely get population count
    if (!is.null(gs) && length(gs) > 0 && !is.null(gs[[1]])) {
      cat("Populations: ", length(flowWorkspace::gs_get_pop_paths(gs[[1]])), "\n")
    } else {
      cat("Populations: 0 (GatingSet is empty)\n")
    }
    
    cat("Execute:     ", execute, "\n")
    cat("======================================\n\n")
    
    # Debug information before returning
    cat("DEBUG: About to return GatingSet\n")
    cat("DEBUG: gs is null:", is.null(gs), "\n")
    if (!is.null(gs)) {
      cat("DEBUG: gs length:", length(gs), "\n")
      if (length(gs) > 0) {
        cat("DEBUG: gs[[1]] is null:", is.null(gs[[1]]), "\n")
      }
    }
  }
  return(gs)
}