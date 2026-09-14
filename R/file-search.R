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

#' Validate and expand root directories for the FCS search
#'
#' Stops when the input is absent or non-character, warns about directories
#' that do not exist, and stops when no valid directory remains.
#'
#' @param root_dir Character vector of candidate directories
#' @return Expanded character vector of existing directories
#' @noRd
fcs_validate_root_dirs <- function(root_dir) {
    if (missing(root_dir) || is.null(root_dir)) {
        stop("root_dir must be provided")
    }

    if (!is.character(root_dir)) {
        stop("root_dir must be character")
    }

    root_dir <- path.expand(root_dir)

    missing_dirs <- root_dir[!dir.exists(root_dir)]
    if (length(missing_dirs) > 0) {
        warning(
            "The following root directories do not exist: ",
            paste(missing_dirs, collapse = ", ")
        )
        root_dir <- root_dir[dir.exists(root_dir)]
        if (length(root_dir) == 0) {
            stop("No valid root directories provided")
        }
    }

    root_dir
}

#' Empty FCS index data frame
#'
#' Column layout matches the non-empty index produced by search_fcs_files().
#'
#' @return Empty data frame with filename, full_path, size_bytes, mtime
#' @noRd
fcs_empty_index <- function() {
    data.frame(
        filename = character(),
        full_path = character(),
        size_bytes = numeric(),
        mtime = as.POSIXct(character()),
        stringsAsFactors = FALSE
    )
}

#' List FCS files under each root directory
#'
#' @param root_dir Expanded character vector of existing directories
#' @param pattern File pattern passed to list.files()
#' @return Character vector of unique full paths (NULL when nothing matched)
#' @noRd
fcs_list_in_roots <- function(root_dir, pattern) {
    unlist(lapply(root_dir, function(root) {
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
}

#' Search for FCS files in directory tree
#'
#' Builds an index of all FCS files in a directory tree.
#'
#' @param root_dir Character vector of root directories to search
#' @param pattern Character. File pattern to match (default: "\\.fcs$")
#' @return Data frame with columns: filename, full_path, size_bytes, mtime
#' @keywords internal
search_fcs_files <- function(root_dir, pattern = "\\.fcs$") {
    root_dir <- fcs_validate_root_dirs(root_dir)

    if (.pkgenv$verbose) { # nocov
        message("Searching for FCS files in", length(root_dir),
            "directories...\n")
    }

    all_files <- fcs_list_in_roots(root_dir, pattern)

    if (length(all_files) == 0) {
        if (.pkgenv$verbose) { # nocov
            message("Found 0 FCS files\n")
        }
        return(fcs_empty_index())
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
        message("  Note:", n_dupes,
            "duplicate filename(s) found in different directories\n")
    }

    if (.pkgenv$verbose) { # nocov
        message("Found", nrow(results), "FCS files\n")
    }

    results
}

#' One row of the FCS path resolution result table
#'
#' Single constructor shared by every resolution status so all rows keep
#' the same columns and types.
#'
#' @param sample_id Sample identifier
#' @param flowjo_uri URI recorded in the workspace (NA when absent)
#' @param filename Basename of the URI (NA when the URI is absent)
#' @param resolved_path Path on disk or pipe-separated candidates
#' @param status One of NO_URI, NOT_FOUND, FOUND, MULTIPLE
#' @return Single-row data frame with the five resolution columns
#' @noRd
fcs_result_row <- function(sample_id, flowjo_uri, filename,
    resolved_path, status) {
    data.frame(
        sample_id = sample_id,
        flowjo_uri = flowjo_uri,
        filename = filename,
        resolved_path = resolved_path,
        status = status,
        stringsAsFactors = FALSE
    )
}

#' Resolve one sample's FCS path against the file index
#'
#' Matches the sample's URI basename against the index built by
#' search_fcs_files() and reports the outcome through the verbose channel.
#'
#' @param sample_id Sample identifier
#' @param sample Data source entry from the FlowJo workspace
#' @param fcs_index Index data frame from search_fcs_files()
#' @return list(row = one-row data frame, n_found, n_missing, n_multiple)
#' @noRd
fcs_resolve_one_sample <- function(sample_id, sample, fcs_index) {
    flowjo_uri <- sample$definition$uri %||%
        sample$definition$customKeywords$`File Name` %||%
        NA_character_

    if (is.na(flowjo_uri)) {
        return(list(
            row = fcs_result_row(sample_id, NA_character_,
                NA_character_, NA_character_, "NO_URI"),
            n_found = 0L, n_missing = 1L, n_multiple = 0L
        ))
    }

    filename <- basename(flowjo_uri)
    match_idx <- which(fcs_index$filename == filename)

    if (length(match_idx) == 0) {
        message("x ", filename, " - NOT FOUND\n", sep = "")
        return(list(
            row = fcs_result_row(sample_id, flowjo_uri, filename,
                NA_character_, "NOT_FOUND"),
            n_found = 0L, n_missing = 1L, n_multiple = 0L
        ))
    }

    if (length(match_idx) == 1) {
        message("OK ", filename, "\n", sep = "")
        return(list(
            row = fcs_result_row(sample_id, flowjo_uri, filename,
                fcs_index$full_path[match_idx], "FOUND"),
            n_found = 1L, n_missing = 0L, n_multiple = 0L
        ))
    }

    message("!! ", filename, " - MULTIPLE MATCHES (",
        length(match_idx), ")\n", sep = "")
    list(
        row = fcs_result_row(sample_id, flowjo_uri, filename,
            paste(fcs_index$full_path[match_idx], collapse = " | "),
            "MULTIPLE"),
        n_found = 0L, n_missing = 0L, n_multiple = 1L
    )
}

#' Print the FCS path resolution summary block
#'
#' @param n_total Number of samples processed
#' @param n_found Samples with a single match
#' @param n_missing Samples without a URI or without any match
#' @param n_multiple Samples with several filename matches
#' @noRd
fcs_resolution_summary <- function(n_total, n_found, n_missing,
    n_multiple) {
    message("\n===========================================\n")
    message("  Resolution Summary\n")
    message("===========================================\n")
    message("Total samples:  ", n_total, "\n")
    message("  Found:        ", n_found,
        sprintf(" (%.1f%%)\n", n_found / n_total * 100))
    message("  Missing:      ", n_missing,
        sprintf(" (%.1f%%)\n", n_missing / n_total * 100))
    message("  Multiple:     ", n_multiple,
        sprintf(" (%.1f%%)\n", n_multiple / n_total * 100))
    message("===========================================\n\n")
}

#' Stop when unresolved FCS path issues remain
#'
#' @param n_missing Number of NOT_FOUND/NO_URI samples
#' @param n_multiple Number of MULTIPLE samples
#' @param stop_on_missing Stop when any file is missing
#' @param stop_on_multiple Stop when any filename matched several files
#' @noRd
fcs_stop_on_issues <- function(n_missing, n_multiple, stop_on_missing,
    stop_on_multiple) {
    if (stop_on_missing && n_missing > 0) {
        stop(
            "Missing FCS files detected. Set stop_on_missing=FALSE to",
            " continue anyway."
        )
    }

    if (stop_on_multiple && n_multiple > 0) {
        stop(
            "Multiple FCS file matches detected. Set",
            " stop_on_multiple=FALSE to continue anyway."
        )
    }
}

#' Resolve All FCS File Paths from FlowJo Workspace
#'
#' Resolves all FCS file paths from a FlowJo workspace, mapping FlowJo URIs
#' to actual file locations on the current system.
#'
#' @param dataSources Data sources from FlowJo workspace (from JSON)
#' @param root_dir Root directory to search for FCS files
#' @param stop_on_multiple Stop if any duplicate filenames found (default:
#  FALSE)
#' @param stop_on_missing Stop if any files not found (default: TRUE)
#' @return Data frame with columns: sample_id, flowjo_uri, filename,
#  resolved_path, status
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

    # Track statistics
    n_total <- length(dataSources)
    n_found <- 0
    n_missing <- 0
    n_multiple <- 0

    message("\nResolving", n_total, "sample paths...\n\n")

    # Process each data source
    resolution_results <- vector("list", length(dataSources))
    for (i in seq_along(dataSources)) {
        res <- fcs_resolve_one_sample(names(dataSources)[i],
            dataSources[[i]], fcs_index)
        resolution_results[[i]] <- res$row
        n_found <- n_found + res$n_found
        n_missing <- n_missing + res$n_missing
        n_multiple <- n_multiple + res$n_multiple
    }

    # Combine results
    resolution_results <- do.call(rbind, resolution_results)

    # Print summary and handle errors based on settings
    fcs_resolution_summary(n_total, n_found, n_missing, n_multiple)
    fcs_stop_on_issues(n_missing, n_multiple, stop_on_missing,
        stop_on_multiple)

    resolution_results
}

#' Get Sample-to-File Mapping
#'
#' Creates a simple lookup table mapping sample UUIDs to FCS file paths
#'
#' @param resolution_results Output from resolve_all_fcs_paths()
#' @param include_status Include only samples with specific status (default:
#  "FOUND")
#' @return Named vector where names are sample_ids and values are resolved_paths
#' @keywords internal
get_sample_file_map <- function(resolution_results, include_status = "FOUND") {
    # Filter by status
    filtered <- resolution_results[
        resolution_results$status %in% include_status,
    ]

    # Create named vector
    file_map <- setNames(filtered$resolved_path, filtered$sample_id)

    message("Created mapping for", length(file_map), "samples\n")

    return(file_map)
}
