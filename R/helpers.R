#' @title Helper Functions for the Package
#' @name helpers
#' @keywords internal
NULL

#' Custom Null Coalescing Operator
#'
#' Provides a null coalescing operator that returns the second argument if the first is NULL.
#'
#' @param x First value to check
#' @param y Second value to return if first is NULL
#' @return Either x if not NULL, or y
#' @name null-coalesce
#' @rdname null-coalesce
#' @keywords internal
#' @examples
#' NULL %||% "default"  # Returns "default"
#' "value" %||% "default"  # Returns "value"
#' @export
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Unified Parameter Name Mapping Function
#'
#' Creates a mapping between source parameter names (e.g., from compensation, gates, transformations)
#' and target parameter names (e.g., cytoframe flowFrame column names).
#'
#' This function handles common naming discrepancies:
#' - "Comp-" prefix (e.g., "Comp-APC-Ax700-A" vs "APC-Ax700-A")
#' - "/" vs "_" sanitization (flowCore converts "/" to "_")
#' - Case sensitivity (optional)
#'
#' @param source_names Character vector of source parameter names
#' @param target_names Character vector of target parameter names (e.g., flowFrame colnames)
#' @param strip_comp_prefix Logical. Strip "Comp-" prefix from source names? Default TRUE.
#' @param case_insensitive Logical. Case-insensitive matching? Default FALSE.
#' @return Named list mapping source names to target names. Unmapped names have NULL values.
#' @keywords internal
map_param_names <- function(source_names,
                            target_names,
                            strip_comp_prefix = FALSE,
                            case_insensitive = FALSE) {
  
  if (is.null(source_names) || length(source_names) == 0) {
    return(list())
  }
  
  if (is.null(target_names) || length(target_names) == 0) {
    return(setNames(lapply(source_names, function(x) NULL), source_names))
  }
  
  # Sanitization function
  sanitize_name <- function(x) {
    # Strip "Comp-" prefix if requested
    if (strip_comp_prefix) {
      x <- sub("^Comp-", "", x)
    }
    # Replace "/" with "_" (flowCore compensation sanitization)
    x <- gsub("/", "_", x)
    # Apply case normalization if requested
    if (case_insensitive) {
      x <- tolower(x)
    }
    x
  }
  
  # Create sanitized versions for matching
  sanitized_source <- sapply(source_names, sanitize_name)
  sanitized_target <- sapply(target_names, sanitize_name)
  
  # Create mapping
  mapping <- list()
  
  for (i in seq_along(source_names)) {
    source_name <- source_names[i]
    sanitized_s <- sanitized_source[i]
    
    # Direct match (original names)
    if (source_name %in% target_names) {
      mapping[[source_name]] <- source_name
      next
    }
    
    # Match via sanitized names
    match_idx <- which(sanitized_target == sanitized_s)
    
    if (length(match_idx) > 0) {
      # Use the original target name
      mapping[[source_name]] <- target_names[match_idx[1]]
    } else {
      # No match found
      mapping[[source_name]] <- NULL
    }
  }
  
  return(mapping)
}

#' Apply Parameter Name Mapping to Names Vector
#'
#' Applies a parameter name mapping to convert source names to target names.
#'
#' @param source_names Character vector of source names
#' @param mapping Named list from \code{map_param_names()}
#' @param on_no_match Character. What to do with unmapped names:
#'   "keep" - keep original name (default)
#'   "drop" - remove from result
#'   "warn" - keep with warning
#' @return Character vector of mapped names
#' @keywords internal
apply_param_mapping <- function(source_names, mapping, on_no_match = "keep") {
  result <- character(length(source_names))
  names(result) <- names(source_names)
  
  for (i in seq_along(source_names)) {
    source_name <- source_names[i]
    mapped <- mapping[[source_name]]
    
    if (is.null(mapped)) {
      if (on_no_match == "keep") {
        result[i] <- source_name
      } else if (on_no_match == "drop") {
        result[i] <- NA_character_
      } else if (on_no_match == "warn") {
        warning("Could not map parameter name '", source_name, "' to target names")
        result[i] <- source_name
      }
    } else {
      result[i] <- mapped
    }
  }
  
  # Remove NA values (dropped names)
  result[!is.na(result)]
}

#' Verify Marker Name Consistency After Gate Creation
#'
#' This function checks that marker names in gates match the parameter names
#' in the GatingSet/flowFrame after compensation and transformations have been applied.
#' It helps detect issues where automated routines may have changed marker names.
#'
#' @param gate_obj A flowCore gate object (rectangleGate, polygonGate, etc.)
#' @param flowframe_params Character vector of parameter names from the flowFrame
#' @param gate_source Character. Description of gate source for error messages
#' @return List with components:
#'   \describe{
#'     \item{valid}{Logical. Are all gate parameters mappable to flowFrame params?}
#'     \item{mapping}{Named list of parameter name mappings}
#'     \item{warnings}{Character vector of warning messages for unmapped params}
#'   }
#' @keywords internal
verify_gate_marker_names <- function(gate_obj, flowframe_params, gate_source = "") {
  warnings <- character()
  
  # Get gate parameters
  gate_params <- tryCatch({
    flowCore::parameters(gate_obj)
  }, error = function(e) {
    warnings <<- c(warnings, paste("Could not extract parameters from gate:", e$message))
    return(character())
  })
  
  if (length(gate_params) == 0) {
    return(list(
      valid = FALSE,
      mapping = list(),
      warnings = warnings
    ))
  }
  
  # Create parameter name mapping
  name_mapping <- map_param_names(
    source_names = gate_params,
    target_names = flowframe_params,
    strip_comp_prefix = TRUE,
    case_insensitive = FALSE
  )
  
  # Check for unmapped parameters
  for (param in gate_params) {
    if (is.null(name_mapping[[param]])) {
      msg <- paste0("Gate parameter '", param, "' does not match any flowFrame parameter")
      if (gate_source != "") {
        msg <- paste0(msg, " (gate: ", gate_source, ")")
      }
      warnings <- c(warnings, msg)
    }
  }
  
  list(
    valid = length(warnings) == 0,
    mapping = name_mapping,
    warnings = warnings
  )
}

#' Restore Marker Names After Automated Routine Changes
#'
#' When an automated routine (like compensation) changes marker names,
#' this function helps restore the original names for consistency.
#'
#' @param gate_obj A flowCore gate object
#' @param name_mapping Named list mapping current names to original names
#' @return Gate object with restored parameter names
#' @keywords internal
restore_gate_marker_names <- function(gate_obj, name_mapping) {
  # Get current gate parameters
  gate_params <- flowCore::parameters(gate_obj)
  
  # Create reverse mapping (target -> source)
  reverse_mapping <- setNames(names(name_mapping), unlist(name_mapping))
  
  # Map gate parameters back to original names
  original_params <- character(length(gate_params))
  for (i in seq_along(gate_params)) {
    original_params[i] <- reverse_mapping[gate_params[i]] %||% gate_params[i]
  }
  
  # Set the original parameter names on the gate
  flowCore::parameters(gate_obj) <- original_params
  
  gate_obj
}
