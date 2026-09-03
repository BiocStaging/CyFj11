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

#' Search for FCS files in directory tree
#' 
#' Builds an index of all FCS files in a directory tree.
#' 
#' @param root_dir Character vector of root directories to search
#' @param pattern Character. File pattern to match (default: "\\.fcs$")
#' @return Data frame with columns: filename, full_path, size_bytes, mtime
#' @keywords internal
search_fcs_files <- function(root_dir, pattern = "\\.fcs$") {
  
  # Validate inputs
  if (missing(root_dir) || is.null(root_dir)) {
    stop("root_dir must be provided")
  }
  
  if (!is.character(root_dir)) {
    stop("root_dir must be character")
  }
  
  # Expand paths
  root_dir <- path.expand(root_dir)
  
  # Validate root directories exist
  missing_dirs <- root_dir[!dir.exists(root_dir)]
  if (length(missing_dirs) > 0) {
    warning("The following root directories do not exist: ", 
            paste(missing_dirs, collapse = ", "))
    root_dir <- root_dir[dir.exists(root_dir)]
    if (length(root_dir) == 0) {
      stop("No valid root directories provided")
    }
  }
  
  # Search for FCS files
  if (.pkgenv$verbose) { # nocov
    message("Searching for FCS files in", length(root_dir), "directories...\n")
  }
  
  # Find all FCS files
  all_files <- unlist(lapply(root_dir, function(root) {
    if (.pkgenv$verbose) { # nocov
      message("  Searching in:", root, "\n")
    }
    list.files(
      path = root,
      pattern = pattern,
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE
    )
  }))
  
  if (length(all_files) == 0) {
    if (.pkgenv$verbose) { # nocov
      message("Found 0 FCS files\n")
    }
    return(data.frame(
      filename = character(),
      full_path = character(),
      size_bytes = numeric(),
      mtime = as.POSIXct(character()),
      stringsAsFactors = FALSE
    ))
  }
  
  # Deduplicate identical full paths (e.g. from overlapping root_dirs)
  all_files <- unique(all_files)
  
  # Get file info
  file_info <- file.info(all_files)
  
  # Build results
  results <- data.frame(
    filename = basename(all_files),
    full_path = all_files,
    size_bytes = file_info$size,
    mtime = file_info$mtime,
    stringsAsFactors = FALSE
  )
  
  n_dupes <- sum(duplicated(results$filename))
  if (n_dupes > 0 && .pkgenv$verbose) { # nocov
    message("  Note:", n_dupes, "duplicate filename(s) found in different directories\n")
  }
  
  if (.pkgenv$verbose) { # nocov
    message("Found", nrow(results), "FCS files\n")
  }
  
  return(results)
}

#' Resolve All FCS File Paths from FlowJo Workspace
#'
#' Resolves all FCS file paths from a FlowJo workspace, mapping FlowJo URIs
#' to actual file locations on the current system.
#'
#' @param dataSources Data sources from FlowJo workspace (from JSON)
#' @param root_dir Root directory to search for FCS files
#' @param stop_on_multiple Stop if any duplicate filenames found (default: FALSE)
#' @param stop_on_missing Stop if any files not found (default: TRUE)
#' @return Data frame with columns: sample_id, flowjo_uri, filename, resolved_path, status
#' @keywords internal
resolve_all_fcs_paths <- function(dataSources, 
                                  root_dir, 
                                  stop_on_multiple = FALSE,
                                  stop_on_missing = TRUE) {
  
  message("===========================================\n")
  message("  Resolving FCS File Paths\n")
  message("===========================================\n\n")
  
  # Build FCS file index once
  fcs_index <- search_fcs_files(root_dir)
  
  # Initialize results
  resolution_results <- vector("list", length(dataSources))
  
  # Track statistics
  n_total <- length(dataSources)
  n_found <- 0
  n_missing <- 0
  n_multiple <- 0
  
  message("\nResolving", n_total, "sample paths...\n\n")
  
  # Process each data source
  for (i in seq_along(dataSources)) {
    sample_id <- names(dataSources)[i]
    sample <- dataSources[[i]]
    
    # Extract URI
    flowjo_uri <- sample$definition$uri %||% 
      sample$definition$customKeywords$`File Name` %||%
      NA_character_
    
    if (is.na(flowjo_uri)) {
      resolution_results[[i]] <- data.frame(
        sample_id = sample_id,
        flowjo_uri = NA_character_,
        filename = NA_character_,
        resolved_path = NA_character_,
        status = "NO_URI",
        stringsAsFactors = FALSE
      )
      n_missing <- n_missing + 1
      next
    }
    
    # Extract filename
    filename <- basename(flowjo_uri)
    
    # Search in index
    match_idx <- which(fcs_index$filename == filename)
    
    if (length(match_idx) == 0) {
      # Not found
      message("x ", filename, " - NOT FOUND\n", sep = "")
      resolution_results[[i]] <- data.frame(
        sample_id = sample_id,
        flowjo_uri = flowjo_uri,
        filename = filename,
        resolved_path = NA_character_,
        status = "NOT_FOUND",
        stringsAsFactors = FALSE
      )
      n_missing <- n_missing + 1
      
    } else if (length(match_idx) == 1) {
      # Single match
      message("OK ", filename, "\n", sep = "")
      resolution_results[[i]] <- data.frame(
        sample_id = sample_id,
        flowjo_uri = flowjo_uri,
        filename = filename,
        resolved_path = fcs_index$full_path[match_idx],
        status = "FOUND",
        stringsAsFactors = FALSE
      )
      n_found <- n_found + 1
      
    } else {
      # Multiple matches
      message("!! ", filename, " - MULTIPLE MATCHES (", length(match_idx), ")\n", sep = "")
      resolution_results[[i]] <- data.frame(
        sample_id = sample_id,
        flowjo_uri = flowjo_uri,
        filename = filename,
        resolved_path = paste(fcs_index$full_path[match_idx], collapse = " | "),
        status = "MULTIPLE",
        stringsAsFactors = FALSE
      )
      n_multiple <- n_multiple + 1
    }
  }
  
  # Combine results
  resolution_results <- do.call(rbind, resolution_results)
  
  # Print summary
  message("\n===========================================\n")
  message("  Resolution Summary\n")
  message("===========================================\n")
  message("Total samples:  ", n_total, "\n")
  message("  Found:        ", n_found, sprintf(" (%.1f%%)\n", n_found/n_total*100))
  message("  Missing:      ", n_missing, sprintf(" (%.1f%%)\n", n_missing/n_total*100))
  message("  Multiple:     ", n_multiple, sprintf(" (%.1f%%)\n", n_multiple/n_total*100))
  message("===========================================\n\n")
  
  # Handle errors based on settings
  if (stop_on_missing && n_missing > 0) {
    stop("Missing FCS files detected. Set stop_on_missing=FALSE to continue anyway.")
  }
  
  if (stop_on_multiple && n_multiple > 0) {
    stop("Multiple FCS file matches detected. Set stop_on_multiple=FALSE to continue anyway.")
  }
  
  return(resolution_results)
}

#' Get Sample-to-File Mapping
#'
#' Creates a simple lookup table mapping sample UUIDs to FCS file paths
#'
#' @param resolution_results Output from resolve_all_fcs_paths()
#' @param include_status Include only samples with specific status (default: "FOUND")
#' @return Named vector where names are sample_ids and values are resolved_paths
#' @keywords internal
get_sample_file_map <- function(resolution_results, include_status = "FOUND") {
  
  # Filter by status
  filtered <- resolution_results[resolution_results$status %in% include_status, ]
  
  # Create named vector
  file_map <- setNames(filtered$resolved_path, filtered$sample_id)
  
  message("Created mapping for", length(file_map), "samples\n")
  
  return(file_map)
}