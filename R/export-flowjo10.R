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
#' @param gating_set A GatingSet object to export. A named list of GatingSets,
#'        as returned by \code{\link{fj11_to_gatingset}}, is also accepted and
#'        merged with \code{flowWorkspace::merge_list_to_gs()} before export.
#' @param output_path Path where the .xml file should be created
#' @param workspace_name Optional name for the workspace
#' @param fcs_root Optional base directory for FCS files.
#'        If provided, FCS files will be written there and URIs in the WSP will
#'        reference that location.  If NULL, uses the actual paths found in the
#'        GatingSet.
#' @param overwrite Logical. When \code{fcs_root} is supplied and FCS files
#'        already exist in that directory, \code{FALSE} (default) aborts with an
#'        error; \code{TRUE} silently replaces existing files.
#' @return Logical indicating success
#' @export
#' @examples
#' # Export a GatingSet to FlowJo v10 XML format
#' ws_path <- system.file("extdata", "min_test.flowjo", package = "CyFj11")
#' fcs_path <- system.file("extdata", package = "CyFj11")
#' ws <- read_flowjo11_workspace(ws_path)
#' gs <- fj11_to_gatingset(ws, group_name = 1, path = fcs_path)
#' out_file <- tempfile(fileext = ".xml")
#' export_flowjo10_workspace(gs, out_file)
#' file.exists(out_file)
#' Validate export_flowjo10_workspace arguments
#'
#' @param gating_set GatingSet argument (may be missing)
#' @param output_path Output path argument (may be missing)
#' @noRd
fj10_validate_export_args <- function(gating_set, output_path) {
    if (missing(gating_set) || missing(output_path)) {
        stop("Missing required parameters: gating_set, output_path")
    }
    if (!is.character(output_path) || length(output_path) != 1) {
        stop("output_path must be a single character string")
    }
    if (!requireNamespace("flowWorkspace", quietly = TRUE)) {
        stop("flowWorkspace package required for GatingSet operations")
    }
}

#' Accept a single GatingSet or merge a list of them
#'
#' fj11_to_gatingset() returns a named list of GatingSets (one per sample);
#' merge them so the export path always sees one GatingSet.
#'
#' @param gating_set GatingSet or list of GatingSets
#' @return A single GatingSet
#' @noRd
fj10_merge_gatingsets <- function(gating_set) {
    if (is.list(gating_set) && !methods::is(
        gating_set,
        "GatingSet"
    )) {
        if (length(gating_set) == 0 || !all(vapply(gating_set, methods::is,
            logical(1),
            class2 = "GatingSet"
        ))) {
            stop("gating_set must be a GatingSet or a list of GatingSets")
        }
        if (length(gating_set) > 1) {
            warning(
                "gating_set is a list of ", length(gating_set),
                " GatingSets; merging with flowWorkspace::merge_list_to_gs() ",
                "(per-sample transformations may be discarded)"
            )
        }
        gating_set <- flowWorkspace::merge_list_to_gs(gating_set)
    }
    gating_set
}

#' Write the generated workspace XML, warning on failure
#'
#' @param xml_content Character vector of XML lines
#' @param output_path Destination path
#' @return TRUE on success, FALSE on failure (with a warning)
#' @noRd
fj10_write_workspace <- function(xml_content, output_path) {
    result <- tryCatch(
        {
            writeLines(xml_content, output_path)
            TRUE
        },
        error = function(e) {
            warning("Failed to write FlowJo v10 workspace: ", e$message)
            FALSE
        }
    )
    result
}

#' Resolve the FCS target directory and write FCS files when requested
#'
#' @param gating_set Validated GatingSet
#' @param output_path Workspace output path
#' @param fcs_root Explicit FCS directory or NULL
#' @param overwrite Overwrite existing FCS files?
#' @return Target FCS directory
#' @noRd
fj10_target_fcs_dir <- function(gating_set, output_path, fcs_root,
    overwrite) {
    target_fcs_dir <- if (!is.null(fcs_root)) {
        outDir <- fcs_root
        if (!dir.exists(outDir)) {
            stop(
                "fcs_root directory does not exist: ", outDir
            )
        }
        outDir
    } else {
        dirname(output_path)
    }

    # ---- Write FCS files when an explicit fcs_root is supplied --------------
    if (!is.null(fcs_root)) {
        write_fcs_files_to_dir(gating_set, target_fcs_dir,
            overwrite = overwrite
        )
    }

    target_fcs_dir
}

export_flowjo10_workspace <- function(
    gating_set, output_path,
    workspace_name = NULL,
    fcs_root = NULL,
    overwrite = FALSE
) {
    # Validate inputs
    fj10_validate_export_args(gating_set, output_path)
    gating_set <- fj10_merge_gatingsets(gating_set)

    # ---- Determine the directory for FCS path calculations ------------------
    target_fcs_dir <- fj10_target_fcs_dir(gating_set, output_path, fcs_root,
        overwrite)

    # ---- Extract components from GatingSet ----------------------------------
    samples_data <- extract_samples_from_gatingset_v10(gating_set,
        target_fcs_dir = target_fcs_dir
    )
    gates_data <- extract_gates_from_gatingset_v10(gating_set)
    populations_data <- extract_populations_from_gatingset_v10(gating_set,
        samples_data, gates_data)
    groups_data <- create_default_groups_v10(samples_data)

    if (is.null(workspace_name)) {
        workspace_name <- tools::file_path_sans_ext(basename(output_path))
    }

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

    result <- fj10_write_workspace(xml_content, output_path)

    if (result) {
        message("Successfully exported FlowJo v10 workspace to: ", output_path)
    }
    return(result)
}

#' Resolve the original FCS path for a sample
#'
#' Tries the FILENAME keyword, the target location, and the basename next to
#' FILENAME, in that order.
#'
#' @param original_basename Basename from the FILENAME keyword (or NA)
#' @param original_fcs_path FILENAME keyword value (or NA)
#' @param final_uri Target URI under the export directory (or NA)
#' @return Existing file path or NULL
#' @noRd
fj10_resolve_fcs_path <- function(original_basename, original_fcs_path,
    final_uri) {
    # First try: the FILENAME keyword points to an existing file
    if (!is.na(original_fcs_path) && file.exists(original_fcs_path)) {
        return(original_fcs_path)
    }
    # Second try: the final_uri (target location) already exists
    if (!is.na(final_uri) && file.exists(final_uri)) {
        return(final_uri)
    }
    # Third try: look for the basename in the same directory as FILENAME
    if (!is.na(original_fcs_path) && !is.na(original_basename)) {
        alt_path <- file.path(dirname(original_fcs_path), original_basename)
        if (file.exists(alt_path)) {
            return(alt_path)
        }
    }
    NULL
}

#' Collect a sample's original basename/path and its reconstructed URI
#'
#' @param gh GatingHierarchy for the sample
#' @param sample_name Sample name (for warnings)
#' @param target_fcs_dir The base directory that the WSP should assume the FCS
#'   files are in.
#' @return list(original_basename, original_fcs_path, final_uri)
#' @noRd
fj10_sample_uri_info <- function(gh, sample_name, target_fcs_dir) {
    # Get original metadata
    original_basename <- NA
    original_fcs_path <- NA

    if (requireNamespace("flowCore", quietly = TRUE)) {
        tryCatch(
            {
                keyword_list <- flowCore::keyword(gh)
                if (!is.null(keyword_list$`$FIL`)) {
                    # Just extract the filename (e.g., "sample01.fcs")
                    original_basename <- basename(keyword_list$`$FIL`)
                    original_fcs_path <- keyword_list$FILENAME
                }
            },
            error = function(e) {
                warning("problem with keywords ", sample_name, "\n")
            }
        )
    }

    # --- CONSTRUCT THE NEW URI ---
    final_uri <- NA

    if (!is.na(original_basename) && !is.null(target_fcs_dir)) {
        final_uri <- file.path(target_fcs_dir, original_basename)
    }

    list(
        original_basename = original_basename,
        original_fcs_path = original_fcs_path,
        final_uri = final_uri
    )
}

#' Read Original FCS Header Keywords
#'
#' @param fcs_path Path to an FCS file.
#' @return Named list of header keywords, or NULL if unavailable.
#' @keywords internal
get_fcs_header_keywords <- function(fcs_path) {
    if (is.null(fcs_path) || !file.exists(fcs_path)) {
        return(NULL)
    }
    tryCatch(
        {
            flowCore::read.FCSheader(fcs_path)[[1]]
        },
        error = function(e) NULL
    )
}

#' Build one sample's keyword set and spillover matrix
#'
#' Reads the original FCS header (resolved from the FILENAME keyword, the
#' target URI, or the FILENAME directory), overlays the GatingSet keywords,
#' and parses the SPILL matrix.
#'
#' @param gh GatingHierarchy for the sample
#' @param uri_info Output of fj10_sample_uri_info()
#' @return list(keywords, spill_matrix, fcs_header)
#' @noRd
fj10_sample_keywords <- function(gh, uri_info) {
    # --- RECONSTRUCT KEYWORDS FROM ORIGINAL FCS HEADER ---
    # flowWorkspace/CytoML rename compensated channels to "Comp-..." in the
    # GatingSet keywords. FlowJo expects the original FCS parameter names
    #   plus
    # the compensated duplicates ($P{18+i}N). Read the original header to
    #   recover
    # the acquisition keywords.
    fcs_path <- fj10_resolve_fcs_path(uri_info$original_basename,
        uri_info$original_fcs_path, uri_info$final_uri)

    fcs_header <- if (!is.null(fcs_path)) {
        get_fcs_header_keywords(fcs_path)
    } else {
        NULL
    }

    # GatingSet-derived keywords that should be preserved/overlaid
    gs_keywords <- tryCatch(
        {
            flowCore::keyword(gh)
        },
        error = function(e) NULL
    )

    keywords <- build_sample_keywords(
        fcs_keywords = fcs_header,
        gs_keywords = gs_keywords,
        final_filename = uri_info$final_uri
    )

    # --- EXTRACT COMPENSATION MATRIX ---
    spill_matrix <- tryCatch(
        {
            parse_spill_keyword(keywords)
        },
        error = function(e) NULL
    )

    list(
        keywords = keywords,
        spill_matrix = spill_matrix,
        fcs_header = fcs_header
    )
}

#' Extract Samples from GatingSet for FlowJo v10
#'
#' @param gating_set GatingSet object
#' @param target_fcs_dir The base directory that the WSP should assume the FCS
#  files are in.
#' @return List of sample data
#' @keywords internal
extract_samples_from_gatingset_v10 <- function(
    gating_set,
    target_fcs_dir = NULL
) {
    samples <- list()
    sample_names <- flowWorkspace::sampleNames(gating_set)

    for (i in seq_along(sample_names)) {
        sample_name <- sample_names[i]
        gh <- gating_set[[sample_name]]
        sample_id <- as.numeric(i)

        uri_info <- fj10_sample_uri_info(gh, sample_name, target_fcs_dir)
        kw_info <- fj10_sample_keywords(gh, uri_info)

        samples[[sample_id]] <- list(
            id = sample_id,
            name = sample_name,
            uri = uri_info$final_uri,
            keywords = kw_info$keywords,
            count = tryCatch(
                {
                    nrow(flowCore::exprs(flowWorkspace::gh_pop_get_data(gh)))
                },
                error = function(e) 0
            ),
            spill_matrix = kw_info$spill_matrix,
            fcs_header = kw_info$fcs_header
        )
    }
    return(samples)
}

#' Read Original FCS Header Keywords
#'
#' @param fcs_path Path to an FCS file.
#' @return Named list of header keywords, or NULL if unavailable.
#' @keywords internal
get_fcs_header_keywords <- function(fcs_path) {
    if (is.null(fcs_path) || !file.exists(fcs_path)) {
        return(NULL)
    }
    tryCatch(
        {
            flowCore::read.FCSheader(fcs_path)[[1]]
        },
        error = function(e) NULL
    )
}

#' Parse SPILL Keyword into Matrix
#'
#' @param keywords Named list of FCS keywords.
#' @return A matrix with dimnames, or NULL if no SPILL keyword.
#' @keywords internal
parse_spill_keyword <- function(keywords) {
    spill <- keywords[["SPILL"]]
    if (is.null(spill)) {
        return(NULL)
    }

    if (is.matrix(spill)) {
        if (is.null(rownames(spill)) && !is.null(colnames(spill))) {
            rownames(spill) <- colnames(spill)
        }
        if (is.null(colnames(spill)) && !is.null(rownames(spill))) {
            colnames(spill) <- rownames(spill)
        }
        return(spill)
    }

    # SPILL may be a single comma-separated string or a character vector.
    if (is.character(spill) && length(spill) == 1) {
        spill <- strsplit(spill, ",")[[1]]
    }

    # FCS SPILL keyword is a flat vector: first value is the number of
    # parameters, followed by the parameter names, then the column-major matrix
    # values.
    vals <- as_num_quiet(as.character(spill))
    tokens <- as.character(spill)

    n <- as_int_quiet(vals[1])
    if (is.na(n) || n <= 0) {
        return(NULL)
    }

    needed_total <- 1 + n + n * n
    if (length(spill) < needed_total) {
        return(NULL)
    }

    col_names <- tokens[2:(n + 1)]
    mat_vals <- vals[(n + 2):needed_total]
    if (any(is.na(mat_vals))) {
        return(NULL)
    }

    mat <- matrix(mat_vals, nrow = n, ncol = n, dimnames = list(
        col_names,
        col_names
    ), byrow = TRUE)
    mat
}

#' Build Sample Keywords from Original FCS Header and GatingSet Overlay
#'
#' Build FlowJo v10 Workspace Keywords
#'
#' @param fcs_keywords Keywords from the original FCS header.
#' @param gs_keywords Keywords from the GatingSet.
#' @param final_filename The value to set for FILENAME.
#' @return Named list of keywords for the exported workspace.
#' @keywords internal
#' Ensure SPILL is serialized in FCS flat format: n, names, values.
#'
#' GatingSet keywords may store SPILL as a matrix even when the original
#' FCS header had a flat string, so normalize both forms.
#' The FCS SPILL keyword must use the original (unprefixed) channel
#'   names;
#' flowWorkspace may rename them to "Comp-..." after compensation is
#'   applied.
#'
#' @param sp SPILL keyword value (matrix or character)
#' @return SPILL keyword value in FCS flat format
#' @noRd
fj10_flatten_spill <- function(sp) {
    if (is.matrix(sp)) {
        if (is.null(rownames(sp)) && !is.null(colnames(sp))) {
            rownames(sp) <- colnames(sp)
        }
        if (is.null(colnames(sp)) && !is.null(rownames(sp))) {
            colnames(sp) <- rownames(sp)
        }
        col_names <- sub("^Comp-", "", colnames(sp))
        flat_spill <- paste(c(ncol(sp), col_names, as.vector(sp)),
            collapse = ","
        )
        return(flat_spill)
    }

    # Already a flat string (possibly a single element). Strip any
    #   Comp- prefix
    # from the channel names so it matches the original FCS parameters.
    if (length(sp) == 1) {
        parts <- strsplit(sp, ",")[[1]]
        n <- as_int_quiet(parts[1])
        if (!is.na(n) && length(parts) >= 1 + n) {
            parts[2:(n + 1)] <- sub("^Comp-", "", parts[2:(n + 1)])
            sp <- paste(parts, collapse = ",")
        }
    } else if (length(sp) > 1) {
        sp <- paste(sp, collapse = ",")
    }
    sp
}

#' Add $P{par_val + i}N/S/R entries for each compensated channel.
#'
#' flowWorkspace adds "Comp-" prefix to compensated channel names.
#' We add another "Comp-" prefix here, resulting in
#'   "Comp-Comp-<channel>".
#' NOTE: This double prefix appears to be required by FlowJo 11.2 (and
#'   FlowJo 10)
#' to read the exported WSP file correctly. Without it, FlowJo fails to
#'   parse
#' the workspace. This may be a FlowJo bug, but for now we keep the
#'   double prefix.
#'
#' @param keywords Named keyword list (modified in place, R copy semantics)
#' @param comp_names Compensated channel names from the SPILL matrix
#' @return Updated keywords list
#' @noRd
fj10_add_comp_params <- function(keywords, comp_names) {
    n_orig <- length(comp_names)
    # Determine existing $PAR
    par_val <- as_int_quiet(keywords[["$PAR"]])
    if (length(par_val) == 0L || is.na(par_val)) par_val <- n_orig

    for (i in seq_along(comp_names)) {
        orig_name <- comp_names[i]
        comp_name <- paste0("Comp-", orig_name)
        idx <- par_val + i

        # Find original parameter index for this channel
        orig_idx <- which(comp_names == orig_name)[1]
        if (is.na(orig_idx)) orig_idx <- i
        orig_s <- keywords[[sprintf("$P%dS", orig_idx)]] %||% ""
        orig_r <- keywords[[sprintf("$P%dR", orig_idx)]] %||% "262144"

        keywords[[sprintf("$P%dN", idx)]] <- comp_name
        keywords[[sprintf("$P%dS", idx)]] <- orig_s
        keywords[[sprintf("$P%dR", idx)]] <- as.character(orig_r)
    }

    keywords
}

build_sample_keywords <- function(fcs_keywords, gs_keywords, final_filename) {
    # Start from GatingSet keywords as base (contains SPILL matrix if
    #   compensation exists)
    keywords <- if (!is.null(gs_keywords)) as.list(gs_keywords) else list()

    # Overlay original FCS header keywords if available (these have the
    #   original acquisition values)
    if (!is.null(fcs_keywords) && length(fcs_keywords) > 0) {
        fcs_list <- as.list(fcs_keywords)
        # Copy FCS keywords, but skip SPILL (we'll handle it specially below)
        # NOTE: We do NOT sanitize $PnS channel labels here - FlowJo uses these
        # exact values to match against descriptive names in population
        #   definitions.
        # Changing them (e.g., NK1/1 -> NK1_1) breaks FlowJo's ability to read
        #   the file.
        for (k in names(fcs_list)) {
            if (k != "SPILL") {
                keywords[[k]] <- fcs_list[[k]]
            }
        }
    }

    # Rewrite FILENAME as requested
    keywords[["FILENAME"]] <- final_filename

    # Add compensated duplicate parameters when compensation is present
    spill <- parse_spill_keyword(keywords)
    if (!is.null(spill)) {
        keywords <- fj10_add_comp_params(keywords, colnames(spill))
        keywords[["SPILL"]] <- fj10_flatten_spill(keywords[["SPILL"]])
    }

    keywords
}

#' Build FlowJo Spillover Matrix XML
#'
#' @param spill_matrix Compensation matrix with column/row names.
#' @param matrix_id UUID for the matrix.
#' @param indent Indentation string.
#' @return Character vector of XML lines.
#' @keywords internal
#' Build the spillover coefficient lines for one parameter
#'
#' @param spill_matrix Compensation matrix with unprefixed dimnames
#' @param param_names Parameter names (rows and columns)
#' @param indent Indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_spillover_lines <- function(spill_matrix, param_names, indent) {
    vapply(param_names, function(p) {
        coef_lines <- vapply(param_names, function(q) {
            val <- spill_matrix[q, p]
            if (is.na(val)) val <- 0
            sprintf(
                paste0(
                    '%s    <transforms:coefficient data-type:parameter="%s"',
                    ' transforms:value="%.10g" />'
                ),
                indent, xml_encode(q), val
            )
        }, character(1))
        paste(c(
            sprintf(
                paste0(
                    '%s  <transforms:spillover data-type:parameter="%s"',
                    ' userProvidedCompInfix="Comp-%s" >'
                ),
                indent, xml_encode(p), xml_encode(p)
            ),
            coef_lines,
            sprintf("%s  </transforms:spillover>", indent)
        ), collapse = "\n")
    }, character(1))
}

#' Normalize a spillover matrix's dimnames to unprefixed parameter names
#'
#' Fills missing dimnames from the other side and strips "Comp-" prefixes.
#'
#' @param spill_matrix Compensation matrix
#' @param param_names Unprefixed parameter names to fill in when a side is
#'   unnamed
#' @return The matrix with both dimnames normalized
#' @noRd
fj10_normalize_spill_dimnames <- function(spill_matrix, param_names) {
    if (is.null(rownames(spill_matrix))) {
        rownames(spill_matrix) <- param_names
    } else {
        rownames(spill_matrix) <- sub("^Comp-", "", rownames(spill_matrix))
    }
    if (is.null(colnames(spill_matrix))) {
        colnames(spill_matrix) <- param_names
    } else {
        colnames(spill_matrix) <- sub("^Comp-", "", colnames(spill_matrix))
    }
    spill_matrix
}

#' Build FlowJo Spillover Matrix XML
#'
#' @param spill_matrix Compensation matrix with column/row names.
#' @param matrix_id UUID for the matrix.
#' @param indent Indentation string.
#' @return Character vector of XML lines.
#' @keywords internal
build_spillover_matrix_xml <- function(
    spill_matrix, matrix_id,
    indent = "     "
) {
    if (is.null(spill_matrix)) {
        return(character(0))
    }

    param_names <- colnames(spill_matrix)
    if (is.null(param_names)) param_names <- rownames(spill_matrix)

    param_names <- fj10_spill_param_names(param_names)
    param_lines <- fj10_spill_param_lines(param_names, indent)
    spill_matrix <- fj10_normalize_spill_dimnames(spill_matrix, param_names)
    spillover_lines <- fj10_spillover_lines(spill_matrix, param_names,
        indent)

    # Combine all lines
    lines <- c(
        sprintf(
            paste0(
                '%s<transforms:spilloverMatrix spectral="0"',
                ' weightOptAlgorithmType="OLS" prefix="Comp-"',
                ' name="Acquisition-defined" editable="0"',
                ' matrixType="wizardDefined" color="#c0c0c0"',
                ' version="FlowJo-10.10.1" status="FINALIZED"',
                ' transforms:id="%s" suffix="" >'
            ),
            indent, xml_encode(matrix_id)
        ),
        sprintf("%s  <data-type:parameters>", indent),
        param_lines,
        sprintf("%s  </data-type:parameters>", indent),
        spillover_lines,
        sprintf("%s</transforms:spilloverMatrix>", indent)
    )
    lines
}

#' Original parameter names for the spillover matrix
#'
#' FlowJo uses the prefix="Comp-" attribute to create compensated channels.
#' The spilloverMatrix must therefore reference the ORIGINAL (unprefixed)
#' parameter names; otherwise CytoML re-import fails with
#' "compensation parameter 'Comp-FITC-A' not found in cytoframe parameters".
#'
#' @param param_names Column/row names from the compensation matrix
#' @return Names with the "Comp-" prefix stripped
#' @noRd
fj10_spill_param_names <- function(param_names) {
    sub("^Comp-", "", param_names)
}

#' data-type:parameter lines for the spillover matrix
#'
#' @param param_names Original (unprefixed) parameter names
#' @param indent Indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_spill_param_lines <- function(param_names, indent) {
    vapply(param_names, function(p) {
        sprintf(
            paste0(
                '%s    <data-type:parameter data-type:name="%s"',
                ' userProvidedCompInfix="Comp-%s" />'
            ),
            indent, xml_encode(p), xml_encode(p)
        )
    }, character(1))
}
#' Extract Gates from GatingSet for FlowJo v10
#'
#' @param gating_set GatingSet object
#' @return List of gate data in FlowJo v10 format
#' @keywords internal
#' Generate the next FlowJo-style ID from the counter environment
#'
#' @param id_env Environment holding the integer counter
#' @return New "ID<counter>" string
#' @noRd
fj10_next_id <- function(id_env) {
    id_env$counter <- id_env$counter + 1L
    paste0("ID", id_env$counter)
}

#' Get or create the FlowJo ID for a sample/population combination
#'
#' @param id_lookup Map of "sample::path" to FlowJo ID
#' @param id_env Counter environment for new IDs
#' @param sample_name Sample name
#' @param pop_path Population path
#' @return list(id, id_lookup)
#' @noRd
fj10_get_or_create_id <- function(id_lookup, id_env, sample_name, pop_path) {
    lookup_key <- paste0(sample_name, "::", pop_path)
    id <- id_lookup[[lookup_key]]
    if (is.null(id)) {
        id <- fj10_next_id(id_env)
        id_lookup[[lookup_key]] <- id
    }
    list(id = id, id_lookup = id_lookup)
}

#' Build one gate's entry for the gates list
#'
#' @param flowjo_id FlowJo-style ID for this population
#' @param parent_flowjo_id FlowJo-style ID for the parent
#' @param parent_path Parent population path
#' @param i Sample index
#' @param sample_name Sample name
#' @param pop_path Population path
#' @param gate_definition Converted FlowJo v10 gate definition
#' @return The gate entry list
#' @noRd
fj10_gate_entry <- function(flowjo_id, parent_flowjo_id, parent_path, i,
    sample_name, pop_path, gate_definition) {
    gate_id <- paste0(
        "gate_", sample_name, "_",
        gsub("/", "_", pop_path)
    )

    # Store gate with both IDs
    list(
        id = flowjo_id, # FlowJo-style ID
        internal_id = gate_id,
        # Internal reference ID
        parent = parent_path,
        parent_id = parent_flowjo_id,
        # FlowJo-style parent ID
        name = pop_path, # Gate name (without path)
        population_path = pop_path, # Full path
        sample_id = as.integer(i),
        sample_name = sample_name,
        definition = gate_definition,
        lookup_key = paste0(sample_name, "::", pop_path)
        # For debugging/reference
    )
}

#' Store one extracted gate in the gates list
#'
#' @param gates Gates list (modified via R copy semantics)
#' @param gh GatingHierarchy for the sample
#' @param i Sample index
#' @param sample_name Sample name
#' @param pop_path Population path
#' @param id_lookup FlowJo ID lookup (modified via R copy semantics)
#' @param id_env Counter environment for new IDs
#' @return list(gates, id_lookup)
#' @noRd
fj10_store_gate <- function(gates, gh, i, sample_name, pop_path, id_lookup,
    id_env) {
    gate_list <- flowWorkspace::gs_pop_get_gate(
        gh,
        pop_path
    )
    if (length(gate_list) == 0) {
        return(list(gates = gates, id_lookup = id_lookup))
    }

    gate <- gate_list[[1]]
    # Convert flowCore gate to FlowJo v10 format
    gate_definition <- convert_gate_to_flowjo10_format(
        gate, pop_path, gh
    )

    if (is.null(gate_definition)) {
        return(list(gates = gates, id_lookup = id_lookup))
    }

    # Generate or retrieve FlowJo ID
    id_out <- fj10_get_or_create_id(id_lookup, id_env, sample_name, pop_path)
    id_lookup <- id_out$id_lookup
    flowjo_id <- id_out$id

    # Get parent information
    parent_path <- flowWorkspace::gh_pop_get_parent(
        gh, pop_path, path = "auto"
    )
    parent_out <- fj10_get_or_create_id(id_lookup, id_env, sample_name,
        parent_path)
    id_lookup <- parent_out$id_lookup
    parent_flowjo_id <- parent_out$id

    # Store gate with both IDs
    entry <- fj10_gate_entry(
        flowjo_id, parent_flowjo_id, parent_path, i, sample_name,
        pop_path, gate_definition
    )
    gates[[entry$internal_id]] <- entry

    list(gates = gates, id_lookup = id_lookup)
}

#' Collect the gates of one sample into the shared lists
#'
#' @param gates Gates list so far
#' @param id_lookup FlowJo ID lookup so far
#' @param id_env Counter environment for new IDs
#' @param gating_set GatingSet holding the sample
#' @param i Sample index
#' @param sample_name Sample name
#' @return list(gates, id_lookup)
#' @noRd
fj10_collect_sample_gates <- function(gates, id_lookup, id_env, gating_set,
    i, sample_name) {
    gh <- gating_set[[sample_name]]
    # Get population paths for this sample
    pop_paths <- tryCatch(
        {
            flowWorkspace::gs_get_pop_paths(gh, path = "auto")
        },
        error = function(e) {
            warning(
                "Failed to get population paths for sample ",
                sample_name, ": ", e$message
            )
            character(0)
        }
    )

    # Extract gate information for each population
    for (pop_path in pop_paths) {
        if (pop_path == "root") {
            # Skip root population as it doesn't have a gate, but add to
            #   lookup
            root_out <- fj10_get_or_create_id(id_lookup, id_env,
                sample_name, pop_path)
            id_lookup <- root_out$id_lookup
            next
        }
        out <- tryCatch(
            fj10_store_gate(gates, gh, i, sample_name,
                pop_path, id_lookup, id_env),
            error = function(e) {
                warning(
                    "Failed to extract gate for population ",
                    pop_path, ": ", e$message
                )
                NULL
            }
        )
        if (!is.null(out)) {
            gates <- out$gates
            id_lookup <- out$id_lookup
        }
    }

    list(gates = gates, id_lookup = id_lookup)
}

extract_gates_from_gatingset_v10 <- function(gating_set) {
    # Initialize gates list and lookup table
    gates <- list()
    id_lookup <- list() # Maps pop_path to FlowJo ID
    id_counter <- as.integer(Sys.time()) # Starting point for IDs

    # Counter environment so extracted helpers can advance it by reference
    id_env <- new.env(parent = emptyenv())
    id_env$counter <- id_counter

    # Get all population paths
    sample_names <- flowWorkspace::sampleNames(gating_set)

    # Process all samples to collect gates
    for (i in seq_along(sample_names)) {
        sample_name <- sample_names[i]
        out <- fj10_collect_sample_gates(
            gates, id_lookup, id_env, gating_set, i, sample_name
        )
        gates <- out$gates
        id_lookup <- out$id_lookup
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
extract_populations_from_gatingset_v10 <- function(
    gating_set, samples_data,
    gates_data
) {
    # Initialize populations list
    populations <- list()

    # Get sample information
    sample_names <- flowWorkspace::sampleNames(gating_set)

    # Extract population information for each sample
    for (i in seq_along(samples_data)) {
        sample_name <- sample_names[i]
        sample_id <- samples_data[[i]]$id
        gh <- gating_set[[sample_name]]

        # Get population paths
        pop_paths <- tryCatch(
            {
                flowWorkspace::gs_get_pop_paths(gh, path = "auto")
            },
            error = function(e) {
                warning(
                    "Failed to get population paths for sample ",
                    sample_name, ": ", e$message
                )
                character(0)
            }
        )

        for (pop_path in pop_paths) {
            populations <- fj10_add_pop_record(
                populations, gh, sample_id, sample_name, pop_path
            )
        }
    }

    return(populations)
}

#' Append one population record to the populations list
#'
#' @param populations Population list being accumulated
#' @param gh GatingHierarchy object
#' @param sample_id 1-based sample index
#' @param sample_name Sample name
#' @param pop_path Population path
#' @return Updated populations list
#' @noRd
fj10_add_pop_record <- function(populations, gh, sample_id, sample_name,
                                 pop_path) {
    pop_id <- paste0("pop_", sample_id, "_", gsub("/", "_", pop_path))

    # Find corresponding gate if not root
    gate_id <- NULL
    if (pop_path != "root") {
        gate_id <- paste0("gate_", sample_name, "_", gsub(
            "/", "_",
            pop_path
        ))
    }

    populations[[pop_id]] <- list(
        id = pop_id,
        name = if (pop_path == "root") "Ungated" else pop_path,
        sample_id = sample_id,
        parent_path = fj10_pop_parent_path(gh, pop_path),
        gate_id = gate_id,
        count = fj10_pop_count_n(gh, pop_path)
    )
    populations
}

#' Parent population path for one population
#'
#' @param gh GatingHierarchy object
#' @param pop_path Population path
#' @return Trimmed parent path, or "root" for the root itself
#' @noRd
fj10_pop_parent_path <- function(gh, pop_path) {
    # Get parent population path
    # cat(file = stderr(), pop_path,"\n")
    if (pop_path == "root") {
        return("root")
    }
    trimws(flowWorkspace::gs_pop_get_parent(gh,
        pop_path,
        path = "auto"
    ))
}

#' Cell count for one population
#'
#' @param gh GatingHierarchy object
#' @param pop_path Population path
#' @return Integer cell count (0 when unavailable)
#' @noRd
fj10_pop_count_n <- function(gh, pop_path) {
    # Count cells in population
    tryCatch(
        {
            gh_pop_get_count(gh, pop_path)
        },
        error = function(e) {
            0
        }
    )
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
    sample_ids <- vapply(samples, function(s) s$id, numeric(1))

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
            warning(
                "Unsupported gate type for population: ", pop_name,
                " (class: ", gate_class, ")"
            )
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
        if (.pkgenv$verbose) {
            warning(
                "No transformations found in gating hierarchy ",
                "for dimension ", dim
            )
        } # nocov
        return(NULL)
    }

    trans <- trans_list[[dim]]

    if (is.null(trans)) {
        # No transformation recorded -> treat as linear passthrough
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

    fj10_transform_spec_by_type(params$type, trans, params$parameters, dim)
}

#' Log-type spec built from parameters or the transform function environment
#'
#' @param trans Transformation object
#' @param p Parameters of the transformation
#' @return Named list representing the FlowJo Log transformation spec
#' @noRd
fj10_log_spec_from_params <- function(trans, p) {
    fn_env <- tryCatch(environment(trans), error = function(e) new.env())

    decade <- p$decade %||% p$n %||%
        fn_env$n %||% fn_env$decade %||% 1
    offset <- p$offset %||% p$m %||%
        fn_env$m %||% fn_env$offset %||% 1
    scale <- p$scale %||% fn_env$scale %||% 1

    list(
        transformType = "Log",
        base          = p$base %||% 10,
        offset        = offset,
        decade        = decade, # now correctly 6, not 1
        scale         = scale
    )
}

#' Build the FlowJo transform spec for one transformation type
#'
#' @param type Transformation type attribute
#' @param trans Transformation object (used to inspect function environments
#'   for log transforms)
#' @param p Parameters of the transformation (may be NULL)
#' @param dim Channel name (for the unsupported-type warning)
#' @return Named list representing the FlowJo transformation specification,
#'   or NULL when the type is unsupported
#' @noRd
fj10_transform_spec_by_type <- function(type, trans, p, dim) {
    spec <- switch(type,
        "biexp" = list(
            transformType   = "Biex",
            T               = p$maxValue,
            A               = p$neg,
            M               = p$pos,
            W               = p$widthBasis,
            vectorLength    = p$channelRange,
            autoWidthBasis  = FALSE
        ),
        "linear" = list(
            transformType = "Linear",
            minRange      = p$minRange,
            maxRange      = p$maxRange
        ),
        "log" = ,
        "logtGml2" = ,
        "flowJo_log" = fj10_log_spec_from_params(trans, p),
        "logicle" = list(
            transformType = "Logicle",
            T = p$t %||% p$T %||% 262144,
            M = p$m %||% p$M %||% 4.5,
            W = p$w %||% p$W %||% 0.5,
            A = p$a %||% p$A %||% 0
        ),
        "fasinh" = ,
        "arcsinh" = list(
            transformType = "Arcsinh",
            a = p$a %||% 0,
            b = p$b %||% (1 / 150),
            c = p$c %||% 0
        ),
        NULL
    )
    if (is.null(spec)) {
        warning("Unsupported transformation type: ", type,
            " for dimension ", dim)
    }
    spec
}

#' Collect all channel names referenced by gates in the workspace
#'
#' @param gates Gate data list as returned by
#  \code{extract_gates_from_gatingset_v10}
#' @return Character vector of unique channel names referenced by gates.
#' @keywords internal
get_referenced_channels <- function(gates) {
    if (is.null(gates) || is.null(gates$gates)) {
        return(character(0))
    }

    # Extract all channel names using lapply and unlist (vectorized)
    all_channels <- unlist(lapply(gates$gates, function(gate) {
        def <- gate$definition
        if (is.null(def)) {
            return(character(0))
        }

        dims <- def$dimensions
        dim_params <- if (!is.null(dims)) {
            vapply(dims, function(dim) dim$parameter, character(1))
        } else {
            character(0)
        }

        c(
            dim_params[!is.na(dim_params)],
            if (!is.null(def$x_param)) def$x_param else character(0),
            if (!is.null(def$y_param)) def$y_param else character(0)
        )
    }), use.names = FALSE)

    unique(all_channels)
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
    children <- tryCatch(gh_pop_get_children(gh, pop_path),
        error = function(e) character(0)
    )
    for (ch in children) {
        dims <- fj10_gate_dims_of(gh, ch)
        if (!is.null(dims)) {
            return(dims)
        }
    }

    # 2. Try self
    if (pop_path != "root") {
        dims <- fj10_gate_dims_of(gh, pop_path)
        if (!is.null(dims)) {
            return(dims)
        }
    }

    # 3. Try parent
    if (pop_path != "root") {
        parent <- tryCatch(gh_pop_get_parent(gh, pop_path, path = "auto"),
            error = function(e) "root"
        )
        if (parent != "root") {
            dims <- fj10_gate_dims_of(gh, parent)
            if (!is.null(dims)) {
                return(dims)
            }
        }
    }

    # 4. Default fallback
    return(c("FSC-A", "SSC-A"))
}

#' Dimensions of a population's non-boolean gate, or NULL
#'
#' @param gh GatingHierarchy object
#' @param pop_path Population path
#' @return Parameter names from the gate, or NULL
#' @noRd
fj10_gate_dims_of <- function(gh, pop_path) {
    gate <- tryCatch(gh_pop_get_gate(gh, pop_path), error = function(e) NULL)
    if (is.null(gate) || methods::is(gate, "booleanFilter")) {
        return(NULL)
    }
    dims <- tryCatch(parameters(gate), error = function(e) NULL)
    if (!is.null(dims) && length(dims) >= 1) {
        return(dims)
    }
    NULL
}

#' Build a rectangle-gate dimension list from parameters and value vectors
#'
#' @param params Parameter names (length 1 or 2)
#' @param min_vals Parameter minima
#' @param max_vals Parameter maxima
#' @return list(type = "rectangle", dimensions = ...) or NULL
#' @noRd
fj10_rect_dimensions <- function(params, min_vals, max_vals) {
    if (length(params) == 1) {
        return(list(
            type = "rectangle",
            dimensions = list(
                list(
                    parameter = params[1], min = min_vals[1],
                    max = max_vals[1]
                )
            )
        ))
    } else if (length(params) >= 2) {
        return(list(
            type = "rectangle",
            dimensions = list(
                list(
                    parameter = params[1], min = min_vals[1],
                    max = max_vals[1]
                ),
                list(
                    parameter = params[2], min = min_vals[2],
                    max = max_vals[2]
                )
            )
        ))
    }

    NULL
}

#' Invert one gate value from display space to raw space
#'
#' Log-type inverse closures from gh_get_transformations are broken (they
#' capture `t` as base::t() instead of the numeric param), so they are
#' rebuilt via create_log_transform; other types use the fetched inverses.
#'
#' @param val Value to invert (scalar)
#' @param param_name Channel name
#' @param gh GatingHierarchy (non-NULL)
#' @param trans_list Pre-fetched inverse transformations
#' @return Inverted value
#' @noRd
fj10_inverse_value <- function(val, param_name, gh, trans_list) {
    spec <- get_transform_spec(gh, param_name)
    if (is.null(spec)) {
        return(val)
    }
    valid_log_args <- c(
        "decade", "offset", "scale", "shift", "n",
        "equal.space"
    )
    switch(spec$transformType,
        "Linear" = val,
        "Log" = ,
        "logtGml2" = ,
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

#' Convert Rectangle Gate to FlowJo v10 Format
#' @keywords internal
convert_rectangle_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
    # ---- extract parameters --------------------------------------------------
    params <- NULL
    if (!is.null(gate@parameters)) {
        params <- flowCore::parameters(gate)
    }

    min_vals <- gate@min
    max_vals <- gate@max

    # ---- validate ------------------------------------------------------------
    if (is.null(params) || is.null(min_vals) || is.null(max_vals)) {
        return(NULL)
    }
    if (length(params) != length(min_vals) ||
        length(params) != length(max_vals)) {
        return(NULL)
    }

    # ---- apply inverse transformations (if gating hierarchy supplied)
    #   ---------
    if (!is.null(gh)) {
        # Fetch once for non-log types (log closures from gh_get_transformations
        # are broken -- they capture `t` as base::t() instead of the
        #   numeric param).
        trans_list <- gh_get_transformations(gh, inverse = TRUE)

        for (i in seq_along(params)) {
            min_vals[i] <- fj10_inverse_value(min_vals[i], params[i], gh,
                trans_list)
            max_vals[i] <- fj10_inverse_value(max_vals[i], params[i], gh,
                trans_list)
        }
    }

    # ---- build output --------------------------------------------------------
    fj10_rect_dimensions(params, min_vals, max_vals)
}


#' Invert polygon coordinates from display space to raw space
#'
#' Log-type inverse closures from gh_get_transformations are broken (they
#' capture `t` as base::t() instead of the numeric param), so they are
#' rebuilt via create_log_transform; other non-linear types use the fetched
#' inverses.
#'
#' @param coords Coordinate vector to invert
#' @param param_name Channel name
#' @param gh GatingHierarchy (non-NULL)
#' @param trans_list Pre-fetched inverse transformations
#' @return Inverted coordinates
#' @noRd
fj10_inverse_coords <- function(coords, param_name, gh, trans_list) {
    spec <- get_transform_spec(gh, param_name)

    if (is.null(spec)) {
        return(coords)
    }

    # Valid args for create_log_transform / flowjo_log_trans
    valid_log_args <- c("decade", "offset", "scale", "n", "equal.space")

    switch(spec$transformType,

        # Linear -- no back-transformation needed.
        "Linear" = coords,

        # Log types: broken gh_get_transformations closure (t ->
        #   base::t()).
        # Reconstruct via create_log_transform / flowjo_log_trans
        #   instead.
        "Log" = ,
        "logtGml2" = ,
        "flowJo_log" = {
            log_spec <- spec[names(spec) %in% valid_log_args]
            tt <- create_log_transform(spec = log_spec)
            tt$inverse(coords)
        },

        # All other non-linear types: gh_get_transformations is correct.
        "Biex" = ,
        "Logicle" = ,
        "Arcsinh" = ,
        "fasinh" = {
            inv_fn <- trans_list[[param_name]]
            if (is.function(inv_fn)) inv_fn(coords) else coords
        },

        # Unknown / unsupported type -- leave coordinates
        #   unchanged.
        coords
    )
}

#' Convert Polygon Gate to FlowJo v10 Format
#' @keywords internal
convert_polygon_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
    # ---- extract parameters --------------------------------------------------
    params <- NULL
    if (!is.null(gate@parameters)) {
        params <- flowCore::parameters(gate)
    }

    vertices <- NULL
    if (!is.null(gate@boundaries)) {
        vertices <- gate@boundaries
    }

    # ---- validate ------------------------------------------------------------
    if (is.null(params) || length(params) < 2 ||
        is.null(vertices) || nrow(vertices) < 3) {
        return(NULL)
    }

    x_coords <- vertices[, 1]
    y_coords <- vertices[, 2]

    # ---- apply inverse transformations (if gating hierarchy supplied)
    #   ---------
    if (!is.null(gh) && requireNamespace("flowWorkspace", quietly = TRUE)) {
        # Fetch once. Log-type closures inside this list are broken (see
        #   below),
        # but we avoid calling them -- they are only referenced for
        #   other types.
        trans_list <- gh_get_transformations(gh, inverse = TRUE)

        x_coords <- fj10_inverse_coords(x_coords, params[1], gh, trans_list)
        y_coords <- fj10_inverse_coords(y_coords, params[2], gh, trans_list)
    }

    # ---- build vertex list ---------------------------------------------------
    vertex_list <- lapply(seq_along(x_coords), function(i) {
        list(x = x_coords[i], y = y_coords[i])
    })

    # ---- return
    #   ---------------------------------------------------------------
    list(
        type = "polygon",
        dimensions = list(
            list(parameter = params[1], values = x_coords),
            list(parameter = params[2], values = y_coords)
        ),
        vertices = vertex_list
    )
}


#' Compute raw-space ellipse geometry from a covariance matrix
#'
#' @param cov_mat 2x2 covariance matrix
#' @param center_x Center x in raw space
#' @param center_y Center y in raw space
#' @param distance Mahalanobis distance
#' @return list(center_x, center_y, focus1_x, focus1_y, focus2_x, focus2_y,
#'   edge1_x, edge1_y, edge2_x, edge2_y, edge3_x, edge3_y, edge4_x, edge4_y)
#' @noRd
fj10_ellipse_raw_geometry <- function(cov_mat, center_x, center_y,
    distance) {
    # Calculate eigenvalues and eigenvectors
    eigen_decomp <- eigen(cov_mat)
    eigenvals <- eigen_decomp$values
    eigenvecs <- eigen_decomp$vectors

    # Calculate rotation angle
    major_axis_vec <- eigenvecs[, 1]
    rotation_angle_rad <- atan2(major_axis_vec[2], major_axis_vec[1])

    # Calculate semi-major and semi-minor axes
    # Use sqrt(distance) because Mahalanobis distance is already squared in
    #   the formula
    semi_major <- sqrt(eigenvals[1]) * distance
    semi_minor <- sqrt(eigenvals[2]) * distance

    # Calculate distance between foci
    c <- sqrt(abs(semi_major^2 - semi_minor^2))

    fj10_ellipse_points(center_x, center_y, rotation_angle_rad,
        semi_major, semi_minor, c)
}

#' Assemble foci and edge points of the rotated ellipse
#'
#' @param center_x Ellipse center x
#' @param center_y Ellipse center y
#' @param rotation_angle_rad Rotation of the major axis in radians
#' @param semi_major Semi-major axis length
#' @param semi_minor Semi-minor axis length
#' @param c Focal distance
#' @return List of foci and edge point coordinates
#' @noRd
fj10_ellipse_points <- function(center_x, center_y, rotation_angle_rad,
                                 semi_major, semi_minor, c) {
    # Calculate the two foci positions (along major axis)
    focus1_x <- center_x + c * cos(rotation_angle_rad)
    focus1_y <- center_y + c * sin(rotation_angle_rad)
    focus2_x <- center_x - c * cos(rotation_angle_rad)
    focus2_y <- center_y - c * sin(rotation_angle_rad)

    # Calculate edge points - these should be at 0deg, 90deg,
    #   180deg, 270deg on the rotated ellipse
    # Rightmost point (0deg)
    edge1_x <- center_x + semi_major * cos(rotation_angle_rad)
    edge1_y <- center_y + semi_major * sin(rotation_angle_rad)

    # Topmost point (90deg) - perpendicular to major axis
    edge2_x <- center_x - semi_minor * sin(rotation_angle_rad)
    edge2_y <- center_y + semi_minor * cos(rotation_angle_rad)

    # Leftmost point (180deg)
    edge3_x <- center_x - semi_major * cos(rotation_angle_rad)
    edge3_y <- center_y - semi_major * sin(rotation_angle_rad)

    # Bottommost point (270deg)
    edge4_x <- center_x + semi_minor * sin(rotation_angle_rad)
    edge4_y <- center_y - semi_minor * cos(rotation_angle_rad)

    list(
        center_x = center_x,
        center_y = center_y,
        focus1_x = focus1_x,
        focus1_y = focus1_y,
        focus2_x = focus2_x,
        focus2_y = focus2_y,
        edge1_x = edge1_x,
        edge1_y = edge1_y,
        edge2_x = edge2_x,
        edge2_y = edge2_y,
        edge3_x = edge3_x,
        edge3_y = edge3_y,
        edge4_x = edge4_x,
        edge4_y = edge4_y
    )
}

#' Map a raw value to FlowJo display units [0, 256]
#'
#' Transformed channels are normalised by the transform's maximum output
#' value (forward_transform(262144)); linear channels by the channel range.
#'
#' @param value Value to map
#' @param range_vals Display range c(min, max) for linear channels
#' @param param Channel name
#' @param transF Inverse transformations (used to detect transformed channels)
#' @param fwdF Forward transformations
#' @return Display-space value
#' @noRd
fj10_to_display_coords <- function(value, range_vals, param, transF, fwdF) {
    if (!is.null(transF[[param]])) {
        # Transformed channel: value is in the forward-transform
        #   output space.
        # Normalise to [0, 256] using the transform's output at raw
        #   ceiling.
        fwd_fn <- fwdF[[param]]
        trans_max <- if (is.function(fwd_fn)) {
            out <- tryCatch(fwd_fn(262144),
                error = function(e) NA_real_
            )
            if (is.finite(out) && out > 0) out else 1.0
        } else {
            1.0 # arcsinh fallback: output range is [0, 1]
        }
        return((value / trans_max) * 256)
    }

    # Linear channel: normalise raw value to [0, 256] by channel
    #   range.
    min_val <- range_vals[1]
    max_val <- range_vals[2]
    range_span <- max_val - min_val
    if (range_span == 0) {
        return(50)
    }
    (value - min_val) / range_span * 256
}

#' Convert ellipse geometry to FlowJo display coordinates
#'
#' FlowJo v10 ellipse gates use normalized display coordinates [0, 256].
#' For linear channels the raw value is divided by the channel's $PnR range.
#' For transformed channels (arcsinh, biex, log) the gate coordinates are
#' already in the transform's output space.  We normalise to [0, 256] by
#' dividing by the transform's maximum output value, which equals
#' forward_transform(262144).  For GML2 arcsinh that is 1.0 (so multiply by
#' 256).  For biex with channelRange=4096 that is 4096 (so divide by 16).
#'
#' @param geom Raw-space ellipse geometry from fj10_ellipse_raw_geometry()
#' @param x_param X channel name
#' @param y_param Y channel name
#' @param gh GatingHierarchy (non-NULL)
#' @return list of 14 display-space coordinates named like geom
#' @noRd
fj10_ellipse_display_coords <- function(geom, x_param, y_param, gh) {
    transF <- gh_get_transformations(gh, inverse = TRUE)
    fwdF <- gh_get_transformations(gh) # forward transforms
    # Get the display ranges that WILL BE WRITTEN to the XML
    x_range <- get_display_range(gh, x_param)
    y_range <- get_display_range(gh, y_param)

    x_coords <- c("center_x", "focus1_x", "focus2_x", "edge1_x", "edge2_x",
        "edge3_x", "edge4_x")
    y_coords <- c("center_y", "focus1_y", "focus2_y", "edge1_y", "edge2_y",
        "edge3_y", "edge4_y")

    for (nm in x_coords) {
        geom[[nm]] <- fj10_to_display_coords(geom[[nm]], x_range, x_param,
            transF, fwdF)
    }
    for (nm in y_coords) {
        geom[[nm]] <- fj10_to_display_coords(geom[[nm]], y_range, y_param,
            transF, fwdF)
    }

    geom
}

#' Convert Ellipsoid Gate to FlowJo v10 Format
#'
#' @param gate ellipsoidGate object
#' @param pop_name Population name
#' @return List representing ellipsoid gate in FlowJo v10 format
#' @keywords internal
convert_ellipsoid_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
    # Get parameters
    params <- tryCatch(
        {
            flowCore::parameters(gate)
        },
        error = function(e) {
            NULL
        }
    )
    # browser() # nocov
    if (is.null(params) || length(params) < 2) {
        return(NULL)
    }
    # browser() # nocov
    raw <- fj10_ellipse_raw_inputs(gate)
    if (is.null(raw)) {
        return(NULL)
    }

    # Extract parameters
    x_param <- params[1]
    y_param <- params[2]

    geom <- fj10_ellipse_raw_geometry(raw$cov_mat, raw$mean_vals[1],
        raw$mean_vals[2],
        raw$distance)

    if (!is.null(gh)) {
        geom <- fj10_ellipse_display_coords(geom, x_param, y_param, gh)
    }

    fj10_ellipsoid_result(x_param, y_param, geom)
}

#' Pull mean/covariance/distance off an EllipsoidGate
#'
#' @param gate EllipsoidGate object
#' @return List with mean_vals, cov_mat, distance; NULL when unusable
#' @noRd
fj10_ellipse_raw_inputs <- function(gate) {
    # Get ellipse parameters
    mean_vals <- tryCatch(
        {
            gate@mean
        },
        error = function(e) {
            return(NULL)
        }
    )

    cov_mat <- tryCatch(
        {
            gate@cov
        },
        error = function(e) {
            return(NULL)
        }
    )

    # Get distance parameter (Mahalanobis distance)
    distance <- tryCatch(
        {
            gate@distance
        },
        error = function(e) {
            1 # Default to 1 if not available
        }
    )

    if (is.null(mean_vals) || is.null(cov_mat)) {
        return(NULL)
    }

    list(mean_vals = mean_vals, cov_mat = cov_mat, distance = distance)
}

#' Assemble the FlowJo ellipsoid gate result from raw geometry
#'
#' Recalculates the foci distance in display space and packages the
#' foci/edge points.
#'
#' @param x_param X channel name
#' @param y_param Y channel name
#' @param geom Geometry list from fj10_ellipse_raw_geometry (possibly
#'   display-transformed)
#' @return List in FlowJo v10 ellipsoid format
#' @noRd
fj10_ellipsoid_result <- function(x_param, y_param, geom) {
    # Recalculate distance in display space
    foci_distance <- sqrt(
        (geom$focus2_x - geom$focus1_x)^2 +
            (geom$focus2_y - geom$focus1_y)^2
    )

    list(
        type = "ellipsoid",
        x_param = x_param,
        y_param = y_param,
        distance = foci_distance,
        foci = list(
            focus1 = list(x = geom$focus1_x, y = geom$focus1_y),
            focus2 = list(x = geom$focus2_x, y = geom$focus2_y)
        ),
        edge = list(
            list(x = geom$edge1_x, y = geom$edge1_y), # major axis +
            list(x = geom$edge3_x, y = geom$edge3_y), # major axis -
            list(x = geom$edge2_x, y = geom$edge2_y), # minor axis +
            list(x = geom$edge4_x, y = geom$edge4_y) # minor axis -
        )
    )
}

#' Convert Boolean Gate to FlowJo v10 Format
#'
#' @param gate booleanFilter object
#' @param pop_name Population name
#' @param gh GatingHierarchy object
#' @return List representing boolean gate in FlowJo v10 format
#' @keywords internal
#' Resolve a boolean-component name to its full population path
#'
#' @param name Component name
#' @param gh GatingHierarchy (may be NULL)
#' @return Full path without the leading slash
#' @noRd
fj10_resolve_component_path <- function(name, gh) {
    if (is.null(gh)) {
        return(name)
    }
    tryCatch(
        sub("^/", "", flowWorkspace::gh_pop_get_full_path(gh, name)),
        error = function(e) {
            warning("Could not resolve full path for '", name, "'")
            name
        }
    )
}

#' Resolve a boolean gate's parent population path
#'
#' @param pop_name Population name of the boolean gate
#' @param gh GatingHierarchy (may be NULL)
#' @return Full parent path without the leading slash, or "root"
#' @noRd
fj10_resolve_parent_path <- function(pop_name, gh) {
    if (is.null(gh)) {
        return("root")
    }
    tryCatch(
        {
            parent <- flowWorkspace::gh_pop_get_parent(gh, pop_name)
            if (identical(parent, "root")) {
                "root"
            } else {
                sub(
                    "^/", "",
                    flowWorkspace::gh_pop_get_full_path(gh, parent)
                )
            }
        },
        error = function(e) {
            warning(
                "Could not get parent for '", pop_name,
                "'; falling back to 'root'"
            )
            "root"
        }
    )
}

#' Split a boolean expression into (name, negated) components
#'
#' @param expr_clean Cleaned expression string
#' @param sep Separator regex for the operator
#' @param gh GatingHierarchy (may be NULL)
#' @return list(names, negated) vectors
#' @noRd
fj10_parse_bool_components <- function(expr_clean, sep, gh) {
    parts <- trimws(strsplit(expr_clean, sep)[[1]])
    parts <- parts[nzchar(parts)]

    names <- character(length(parts))
    negated <- logical(length(parts))
    for (i in seq_along(parts)) {
        comp <- trimws(parts[i])
        negated[i] <- startsWith(comp, "!")
        raw <- if (negated[i]) trimws(sub("^!", "", comp)) else comp
        names[i] <- fj10_resolve_component_path(raw, gh)
    }

    list(names = names, negated = negated)
}

#' Extract and clean the boolean expression string from a gate
#'
#' @param gate booleanFilter object
#' @param pop_name Population name (for the failure warning)
#' @return list(expr_str, expr_clean) or NULL when extraction fails
#' @noRd
fj10_boolean_expr <- function(gate, pop_name) {
    expr <- tryCatch(
        {
            attr(gate, "expr")
        },
        error = function(e) {
            warning(
                "Failed to extract expression from boolean gate: ",
                pop_name
            )
            return(NULL)
        }
    )

    if (is.null(expr)) {
        return(NULL)
    }

    expr_str <- if (is.character(expr)) {
        expr
    } else {
        deparse(expr,
            width.cutoff = 500L
        )[1]
    }

    expr_clean <- sub("^expression\\((.*)\\)$", "\\1", expr_str)
    expr_clean <- gsub("`", "", expr_clean)
    expr_clean <- trimws(expr_clean)

    list(expr_str = expr_str, expr_clean = expr_clean)
}

#' Build the boolean entry for an AND expression
#'
#' KEY FIX: "parent & !dep" is a FlowJo NotNode, not an AndNode.
#'
#' @param expr_str Raw expression string
#' @param expr_clean Cleaned expression string
#' @param pop_name Population name
#' @param gh GatingHierarchy (may be NULL)
#' @return The boolean gate entry list
#' @noRd
fj10_boolean_and_entry <- function(expr_str, expr_clean, pop_name, gh) {
    parsed <- fj10_parse_bool_components(expr_clean, "\\s*&+\\s*", gh)
    dep_names <- parsed$names
    dep_neg <- parsed$negated

    # -- KEY FIX: "parent & !dep" is a FlowJo NotNode, not
    # AndNode
    #   --------------
    non_neg_idx <- which(!dep_neg)
    neg_idx <- which(dep_neg)
    if (length(non_neg_idx) == 1 && length(neg_idx) >= 1 &&
        !is.null(gh)) {
        if (identical(dep_names[non_neg_idx],
            fj10_resolve_parent_path(pop_name, gh))) {
            return(list(
                type       = "boolean",
                op_type    = "not",
                expression = expr_str,
                dependents = dep_names[neg_idx], # only the negated pop(s)
                negated    = rep(TRUE, length(neg_idx))
            ))
        }
    }

    list(
        type       = "boolean",
        op_type    = "and",
        expression = expr_str,
        dependents = dep_names,
        negated    = dep_neg
    )
}

#' Convert Boolean Gate to FlowJo v10 Format
#'
#' @param gate booleanFilter object
#' @param pop_name Population name
#' @param gh GatingHierarchy object
#' @return List representing boolean gate in FlowJo v10 format
#' @keywords internal
convert_boolean_to_flowjo10 <- function(gate, pop_name, gh = NULL) {
    expr_info <- fj10_boolean_expr(gate, pop_name)

    if (is.null(expr_info)) {
        return(NULL)
    }

    expr_str <- expr_info$expr_str
    expr_clean <- expr_info$expr_clean

    if (grepl("&", expr_clean)) {
        fj10_boolean_and_entry(expr_str, expr_clean, pop_name, gh)
    } else if (grepl("\\|", expr_clean)) {
        parsed <- fj10_parse_bool_components(expr_clean, "\\s*\\|+\\s*", gh)

        list(
            type = "boolean",
            op_type = "or",
            expression = expr_str,
            dependents = parsed$names,
            negated = parsed$negated
        )
    } else if (startsWith(expr_clean, "!")) {
        # -- KEY FIX: pure NOT -- just the negated dep, no
        # parent in dependents
        #   -------
        dep_path <- fj10_resolve_component_path(
            trimws(sub("^!", "", expr_clean)), gh
        )
        list(
            type       = "boolean",
            op_type    = "not",
            expression = expr_str,
            dependents = dep_path, # single string, not c(parent, dep)
            negated    = TRUE
        )
    } else {
        warning("Could not determine boolean operation type for: ", pop_name)
        NULL
    }
}


#' TextTraits lines shared by GraphEnvironment blocks
#'
#' @param indent Inner indentation string
#' @return Character vector of four TextTraits lines
#' @noRd
fj10_text_traits_xml <- function(indent) {
    c(
        sprintf(paste0(
            '%s      <TextTraits font="SansSerif" size="11"',
            ' name="Labels" style="plain" color="#000000"',
            ' background="#00ffffff" just="left" />'
        ), indent),
        sprintf(paste0(
            '%s      <TextTraits font="SansSerif" size="11"',
            ' name="LayoutGates" style="plain" color="#000000"',
            ' background="#00ffffff" just="left" />'
        ), indent),
        sprintf(paste0(
            '%s      <TextTraits font="SansSerif" size="9"',
            ' name="Numbers" style="plain" color="#000000"',
            ' background="#00ffffff" just="left" />'
        ), indent),
        sprintf(paste0(
            '%s      <TextTraits font="SansSerif" size="9"',
            ' name="Legend" style="plain" color="#000000"',
            ' background="#00ffffff" just="left" />'
        ), indent)
    )
}

#' Graph block for AndNode/OrNode logical nodes
#'
#' NotNode typically doesn't have one in the example.
#'
#' @param indent XML indentation string
#' @param axes Axis names from get_graph_axes()
#' @return Character vector of XML lines
#' @noRd
fj10_logical_graph_xml <- function(indent, axes) {
    c(
        sprintf(paste0(
            '%s  <Graph smoothing="0" backColor="#ffffff"',
            ' foreColor="#000000"',
            ' heatMapStatParameter="BUV395-A"',
            ' type="Pseudocolor" fast="1">'
        ), indent),
        sprintf(paste0(
            '%s    <Axis dimension="x" name="%s" label=""',
            ' auto="auto" />'
        ), indent, axes[1]),
        sprintf(
            paste0(
                '%s    <Axis dimension="y" name="%s" label=""',
                ' auto="auto" />'
            ), indent,
            if (length(axes) > 1) axes[2] else ""
        ),
        sprintf(paste0(
            '%s    <GraphSettings level="5%%"',
            ' smoothingHighResolution="1"',
            ' contourHighResolution="1"',
            ' histogramSmoothingCount="0" graphResolution="256"',
            ' showOutliers="0" drawLargeDots="0"',
            ' dotsToDraw="8000" tint="le.chartfill.tinted.40"',
            ' lineWeight="le.lineweight.normal"',
            ' lineStyle="le.linestyle.solid" />'
        ), indent),
        sprintf(paste0(
            '%s    <GraphEnvironment showGrid="0"',
            ' showAxes="tnlTNL" showGates="1"',
            ' showFreqOnPlots="1" showGateNameOnPlots="1"',
            ' showMedians="0" showUncomped="0"',
            ' addEventParam="0" lastYAxisName="">'
        ), indent),
        fj10_text_traits_xml(indent),
        sprintf(paste0(
            '%s      <WindowPosition x="247" y="-1415"',
            ' width="390" height="679" displayed="0"',
            ' panelState="---" />'
        ), indent),
        sprintf("%s    </GraphEnvironment>", indent),
        sprintf("%s  </Graph>", indent)
    )
}

#' RectangleGate block embedded in a NotNode for its dependent
#'
#' @param indent XML indentation string
#' @param gate Gate data entry for the NotNode
#' @param g Dependent gate entry (with $definition and $id)
#' @return Character vector of XML lines
#' @noRd
fj10_notnode_gate_xml <- function(indent, gate, g) {
    gate_def <- g$definition
    xml_lines <- sprintf(
        '%s  <Gate gating:id="%s">', indent,
        xml_encode(gate$id)
    )

    if (gate_def$type == "rectangle") {
        xml_lines <- c(
            xml_lines,
            sprintf(paste0(
                "%s    <gating:RectangleGate",
                ' eventsInside="1" annoOffsetX="0"',
                ' annoOffsetY="0" tint="#000000"',
                ' isTinted="0"',
                ' lineWeight="Hairline"',
                ' userDefined="1">'
            ), indent)
        )
        for (dim in gate_def$dimensions) {
            xml_lines <- c(
                xml_lines,
                sprintf(
                    paste0(
                        "%s      <gating:dimension",
                        ' gating:min="%f"',
                        ' gating:max="%f" yRatio="0.5">'
                    ),
                    indent, dim$min, dim$max
                ),
                sprintf(
                    paste0(
                        "%s       ",
                        " <data-type:fcs-dimension",
                        ' data-type:name="%s"/>'
                    ), indent,
                    xml_encode(dim$parameter)
                ),
                sprintf("%s      </gating:dimension>", indent)
            )
        }
        xml_lines <- c(
            xml_lines,
            sprintf("%s    </gating:RectangleGate>", indent)
        )
    }
    # Could add polygon/ellipsoid handling here too

    c(xml_lines, sprintf("%s  </Gate>", indent))
}

#' Find the dependent's gate entry for a NotNode
#'
#' @param gates Full gates list (for looking up dependent gates if needed)
#' @param dep_name First dependent name
#' @return Gate entry or NULL
#' @noRd
fj10_find_dependent_gate <- function(gates, dep_name) {
    for (g_id in names(gates$gates)) {
        g <- gates$gates[[g_id]]
        if (!is.na(g$name) && !is.na(dep_name) &&
            (g$name == dep_name ||
                basename(g$population_path) == dep_name)) {
            return(g)
        }
    }
    NULL
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
generate_logical_node_xml <- function(gate, pop_name,
                                        child_path, indent, gh, gates = NULL) {
    xml_lines <- character(0)
    def <- gate$definition

    if (is.null(def) || def$type != "boolean") {
        return(xml_lines)
    }
    # Determine node type
    node_type <- fj10_logical_node_type(def$op_type)
    if (is.null(node_type)) {
        return(xml_lines) # Fallback if unknown type
    }

    count <- fj10_logical_pop_count(gh, child_path)

    # Start node element
    xml_lines <- sprintf(
        paste0(
            '%s<%s name="%s" annotation="" owningGroup="" expanded="1"',
            ' sortPriority="10" count="%d">'
        ),
        indent, node_type, xml_encode(pop_name), count
    )

    xml_lines <- c(xml_lines, fj10_logical_graph_section_xml(
        def$op_type, def$dependents, indent, gh
    ))
    xml_lines <- c(xml_lines, fj10_notnode_gate_section_xml(
        def$op_type, gates, def$dependents, indent, gate
    ))

    c(
        xml_lines,
        fj10_dependents_section_xml(def$dependents, indent),
        sprintf("%s</%s>", indent, node_type)
    )
}

#' Map a boolean operator to its FlowJo node element name
#'
#' @param op_type Boolean operator: "and", "or", or "not"
#' @return Node type string ("AndNode" etc.) or NULL for unknown types
#' @noRd
fj10_logical_node_type <- function(op_type) {
    switch(op_type,
        "and" = "AndNode",
        "or" = "OrNode",
        "not" = "NotNode",
        NULL
    )
}

#' Event count for a logical population, tolerating lookup errors
#'
#' @param gh GatingHierarchy object
#' @param child_path Path of the population node
#' @return Event count, 0 when unavailable
#' @noRd
fj10_logical_pop_count <- function(gh, child_path) {
    count <- 0
    tryCatch(
        {
            count <- flowWorkspace::gh_pop_get_count(gh, child_path)
        },
        error = function(e) {}
    )
    count
}

#' Graph block for an AndNode/OrNode
#'
#' @param op_type Boolean operator type
#' @param dependents Character vector of dependent names
#' @param indent XML indentation string
#' @param gh GatingHierarchy object
#' @return Character vector of XML lines (empty for NotNode)
#' @noRd
fj10_logical_graph_section_xml <- function(op_type, dependents, indent, gh) {
    if (!(op_type %in% c("and", "or"))) {
        return(character(0))
    }
    # Try to get axes from first dependent
    axes <- tryCatch(
        {
            get_graph_axes(gh, dependents[1])
        },
        error = function(e) c("FSC-A", "SSC-A")
    )

    fj10_logical_graph_xml(indent, axes)
}

#' Optional embedded gate for a NotNode
#'
#' @param op_type Boolean operator type
#' @param gates Full gates list (for looking up dependent gates if needed)
#' @param dependents Character vector of dependent names
#' @param indent XML indentation string
#' @param gate Gate data containing boolean definition
#' @return Character vector of XML lines (empty for non-NotNode)
#' @noRd
fj10_notnode_gate_section_xml <- function(op_type, gates, dependents,
                                            indent, gate) {
    # For NotNode, optionally include the gate definition from the dependent
    # (as shown in the example where NotNode contains a RectangleGate)
    if (op_type != "not" || is.null(gates) ||
        length(dependents) == 0 || is.na(dependents[1])) {
        return(character(0))
    }
    g <- fj10_find_dependent_gate(gates, dependents[1])

    if (!is.null(g) && !is.null(g$definition) &&
        g$definition$type %in% c(
            "rectangle", "polygon",
            "ellipsoid"
        )) {
        return(fj10_notnode_gate_xml(indent, gate, g))
    }
    character(0)
}

#' Dependents block for a logical node
#'
#' @param dependents Character vector of dependent names
#' @param indent XML indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_dependents_section_xml <- function(dependents, indent) {
    lines <- sprintf("%s  <Dependents>", indent)
    for (dep in dependents) {
        lines <- c(lines, sprintf(
            '%s    <Dependent name="%s" />',
            indent, xml_encode(dep)
        ))
    }
    c(lines, sprintf("%s  </Dependents>", indent))
}


#' Derive the data range for one channel from a sample's root frame
#'
#' Looks up the $P{n}R keyword matching the channel name to determine the
#' maximum data value; for scatter channels (FSC/SSC) also inspects the
#' expression matrix for a negative minimum. Returns c(0, 262144) when the
#' channel cannot be resolved.
#'
#' @param sample_gh GatingHierarchy for the sample (may be NULL)
#' @param channel Channel name to look up
#' @return Numeric vector c(min, max)
#' @importFrom flowWorkspace gh_pop_get_data
#' @keywords internal
fj10_channel_data_range <- function(sample_gh, channel) {
    tryCatch(
        {
            fr <- gh_pop_get_data(sample_gh, "root")
            kw <- flowCore::keyword(fr)
            n_pattern <- "^\\$P[0-9]+N$"
            n_keys <- grep(n_pattern, names(kw), value = TRUE)
            n_values <- vapply(
                n_keys,
                function(k) as.character(kw[[k]]), character(1)
            )
            param_match <- which(n_values == channel)
            if (length(param_match) > 0) {
                param_num <- gsub("\\$|P|N", "", names(param_match)[1])
                r_keyword <- paste0("$P", param_num, "R")
                max_val <- as.numeric(kw[[r_keyword]] %||% 262144)
                min_val <- 0
                if (grepl("FSC|SSC", channel, ignore.case = TRUE)) {
                    data_vals <- flowCore::exprs(fr)[, channel]
                    actual_min <- min(data_vals, na.rm = TRUE)
                    if (actual_min < 0) min_val <- actual_min
                }
                c(min_val, max_val)
            } else {
                c(0, 262144)
            }
        },
        error = function(e) c(0, 262144)
    )
}

#' Build the full FlowJo v10 workspace XML header block
#'
#' Produces the XML declaration, <Workspace> opening tag with all workspace
#' attributes, and the WindowPosition, TextTraits, and Columns sections.
#'
#' @param output_path Path used for the nonAutoSaveFileName attribute
#' @return Character vector of XML lines
#' @keywords internal
fj10_workspace_header <- function(output_path) {
    current_time <- format(Sys.time(), "%a %b %d %H:%M:%S %Z %Y")
    client_ts <- format(Sys.time(), "%s%OS3")
    client_ts <- gsub("\\.", "", client_ts)

    c(
        '<?xml version="1.0" encoding="UTF-8"?>',
        " <Workspace",
        '   version="20.0"',
        sprintf('   modDate="%s"', current_time),
        sprintf('   clientTimestamp="%s"', client_ts),
        fj10_workspace_attr_lines(),
        sprintf(
            '   nonAutoSaveFileName="file:%s"',
            xml_encode(output_path)
        ),
        " >",
        paste0(
            '   <WindowPosition x="100" y="100" width="800" height="',
            '600" displayed="1" panelState="" ',
            "/>"
        ),
        paste0(
            '   <TextTraits font="SansSerif" size="11" name="" style="',
            'plain" color="#000000" background="#00ffffff" just="left" ',
            "/>"
        ),
        fj10_workspace_columns_xml()
    )
}

#' XML namespace/schema attributes of the Workspace element
#'
#' @return Character vector of XML lines
#' @noRd
fj10_workspace_attr_lines <- function() {
    c(
        '   flowJoVersion="10.10.1"',
        '   drawRowBorders="1"',
        '   drawColumnBorders="1"',
        '   curGroup="All Samples"',
        '   groupPaneHeight="80"',
        '   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
        paste0(
            '   xmlns:gating="',
            'http://www.isac-net.org/std/Gating-ML/v2.0/gating"'
        ),
        paste0(
            '   xmlns:transforms="',
            'http://www.isac-net.org/std/Gating-ML/v2.0/transformations"'
        ),
        paste0(
            '   xmlns:data-type="',
            'http://www.isac-net.org/std/Gating-ML/v2.0/datatypes"'
        ),
        paste0(
            '   xsi:schemaLocation="',
            "http://www.isac-net.org/std/Gating-ML/v2.0/gating ",
            "http://www.isac-net.org/std/Gating-ML/v2.0/gating/",
            "Gating-ML.v2.0.xsd ",
            "http://www.isac-net.org/std/Gating-ML/v2.0/transformations ",
            "http://www.isac-net.org/std/Gating-ML/v2.0/gating/",
            "Transformations.v2.0.xsd ",
            "http://www.isac-net.org/std/Gating-ML/v2.0/datatypes ",
            "http://www.isac-net.org/std/Gating-ML/v2.0/gating/",
            "DataTypes.v2.0.xsd \""
        )
    )
}

#' Columns section of the workspace header
#'
#' @return Character vector of XML lines
#' @noRd
fj10_workspace_columns_xml <- function() {
    c(
        "   <Columns>",
        '     <TColumn width="371" >',
        '       <Property key="fj.appnode.prop.name" />',
        "     </TColumn>",
        '     <TColumn width="211" >',
        '       <Property key="fj.appnode.prop.statistic" />',
        "     </TColumn>",
        '     <TColumn width="210" >',
        '       <Property key="fj.appnode.prop.ncells" />',
        "     </TColumn>",
        "   </Columns>"
    )
}

#' Normalize a GatingHierarchy's transform list for the TransformStore
#'
#' Strips the "Comp-" prefix from transform names (first occurrence wins),
#' ensures scatter channels carry linear transforms when requested, and adds
#' a linear transform for Time.
#'
#' @param all_ts_transforms Named list of transformations from
#'   gh_get_transformations
#' @param force_XSC_linear Ensure scatter channels have linear transforms
#' @return Named list of transformations keyed by original channel name
#' @noRd
fj10_ts_normalize_transforms <- function(all_ts_transforms,
                                            force_XSC_linear) {
    # Strip "Comp-" prefix to map to original channel names
    # TODO verify that comp name has to be changed.
    ts_transforms <- list()
    for (nm in names(all_ts_transforms)) {
        orig_nm <- sub("^Comp-", "", nm)
        if (!(orig_nm %in% names(ts_transforms))) {
            ts_transforms[[orig_nm]] <- all_ts_transforms[[nm]]
        }
    }
    # Ensure scatter channels have linear transforms
    if (force_XSC_linear) {
        lin_trans <- flowCore::linearTransform(
            transformationId = "defaultLin", a = 1, b = 0
        )
        for (marker in c(
            "FSC-A", "FSC-H", "FSC-W", "SSC-A",
            "SSC-H", "SSC-W"
        )) {
            if (is.null(ts_transforms[[marker]])) {
                ts_transforms[[marker]] <- lin_trans@.Data
                attr(ts_transforms[[marker]], "type") <- "Linear"
            }
        }
    }
    # Ensure Time has a linear transform
    if (is.null(ts_transforms[["Time"]])) {
        ts_transforms[["Time"]] <- flowCore::linearTransform(
            transformationId = "defaultLin", a = 1, b = 0
        )@.Data
        attr(ts_transforms[["Time"]], "type") <- "Linear"
    }
    ts_transforms
}

#' Build the cytometer-level TransformStore XML
#'
#' Builds the <TransformStore> element from the first sample's transformations,
#' using the original (uncompensated) parameter names, adding linear transforms
#' for scatter channels and Time when missing.
#'
#' @param gating_set GatingSet (or list) holding sample hierarchies
#' @param samples List of sample data as built by build_sample_list
#' @param force_XSC_linear Ensure scatter channels have linear transforms
#' @return Character vector of XML lines (either the populated TransformStore
#'   or a self-closing <TransformStore/>)
#' @keywords internal
fj10_transform_store_xml <- function(gating_set, samples, force_XSC_linear) {
    if (length(samples) == 0 || is.null(samples[[1]])) {
        return("       <TransformStore/>")
    }
    sample_gh_for_ts <- NULL
    tryCatch(
        {
            sample_gh_for_ts <- gating_set[[samples[[1]]$name]]
        },
        error = function(e) {}
    )
    if (is.null(sample_gh_for_ts)) {
        return("       <TransformStore/>")
    }

    all_ts_transforms <-
        flowWorkspace::gh_get_transformations(sample_gh_for_ts)
    ts_transforms <- fj10_ts_normalize_transforms(
        all_ts_transforms, force_XSC_linear
    )

    if (length(ts_transforms) == 0) {
        return("       <TransformStore/>")
    }

    c(
        "       <TransformStore>",
        paste0(
            '         <MatrixID matrixId="',
            '18405cb6-3c7f-485d-a690-1690f98d59a8" ',
            ">"
        ),
        "           <Transforms>",
        fj10_ts_transform_lines(ts_transforms, sample_gh_for_ts),
        "           </Transforms>",
        "         </MatrixID>",
        "       </TransformStore>"
    )
}

#' Transform element lines for the cytometer TransformStore
#'
#' @param ts_transforms Normalized transform list
#' @param sample_gh_for_ts GatingHierarchy used for channel data ranges
#' @return Character vector of XML lines
#' @noRd
fj10_ts_transform_lines <- function(ts_transforms, sample_gh_for_ts) {
    # Build transform lines using lapply (vectorized)
    transform_xml_lines <- lapply(
        seq_along(ts_transforms),
        function(tr_idx) {
            channel <- names(ts_transforms)[tr_idx]
            atr_tr <- attributes(ts_transforms[[tr_idx]])
            if (is.null(atr_tr$type)) atr_tr$type <- "Linear"

            data_range <- fj10_channel_data_range(
                sample_gh_for_ts, channel
            )

            emit_transform_xml(atr_tr$type, channel,
                ts_transforms[[tr_idx]], atr_tr, data_range,
                indent = "             "
            )
        }
    )
    unlist(transform_xml_lines)
}

#' Render the <Cytometer> element
#'
#' Renders the opening <Cytometer ...> tag with all cytometer attributes and
#' the fixed LinParams/LogParams/FilterParams children.
#'
#' @param cyt_attrs Cytometer attributes as returned by
#'   derive_cytometer_attrs
#' @param transform_store_lines TransformStore XML lines
#' @return Character vector of XML lines
#' @keywords internal
fj10_cytometer_xml <- function(cyt_attrs, transform_store_lines) {
    c(
        "   <Cytometers>",
        sprintf(
            paste0(
                '     <Cytometer name="%s" cyt="%s" useFCS3="%s" ',
                'extraNegs="%s" widthBasis="%s" linMin="%s" logMin="%s"',
                ' linMax="%s" logMax="%s" linearRescale="%s" ',
                'logRescale="%s" linFromKW="%s" logFromKW="%s" useGain=',
                '"%s" useTransform="%s" transformType="%s" ',
                'manufacturer="%s" serialnumber="%s" homepage="%s" ',
                'icon="%s" ',
                ">"
            ),
            xml_encode(cyt_attrs$name),
            xml_encode(cyt_attrs$cyt),
            cyt_attrs$useFCS3,
            cyt_attrs$extraNegs,
            cyt_attrs$widthBasis,
            cyt_attrs$linMin,
            cyt_attrs$logMin,
            cyt_attrs$linMax,
            cyt_attrs$logMax,
            cyt_attrs$linearRescale,
            cyt_attrs$logRescale,
            cyt_attrs$linFromKW,
            cyt_attrs$logFromKW,
            cyt_attrs$useGain,
            cyt_attrs$useTransform,
            cyt_attrs$transformType,
            xml_encode(cyt_attrs$manufacturer),
            xml_encode(cyt_attrs$serialnumber),
            xml_encode(cyt_attrs$homepage),
            xml_encode(cyt_attrs$icon)
        ),
        "       <LinParams>",
        "         <Param>time</Param>",
        "       </LinParams>",
        "       <LogParams/>",
        "       <FilterParams/>",
        transform_store_lines,
        "     </Cytometer>",
        "   </Cytometers>"
    )
}

#' Build the workspace Matrices and Cytometers sections
#'
#' Emits the workspace-level compensation matrix (when the first sample has a
#' spillover matrix), derives cytometer attributes, builds the cytometer-level
#' TransformStore from the first sample's transformations, and renders the
#' <Cytometers> section.
#'
#' @param gating_set GatingSet (or list) holding sample hierarchies
#' @param samples List of sample data as built by build_sample_list
#' @param force_XSC_linear Ensure scatter channels have linear transforms
#' @return List with `lines` (XML lines) and `ws_matrix_id` (workspace matrix
#'   id, or NULL)
#' @keywords internal
fj10_workspace_cytometers_section <- function(gating_set, samples,
                                                force_XSC_linear) {
    lines <- character(0)

    # Add workspace-level compensation matrix if available
    ws_matrix_id <- NULL
    if (length(samples) > 0 && !is.null(samples[[1]]$spill_matrix)) {
        ws_matrix_id <- "18405cb6-3c7f-485d-a690-1690f98d59a8"
        lines <- c(
            lines,
            "   <Matrices>",
            build_spillover_matrix_xml(samples[[1]]$spill_matrix,
                ws_matrix_id,
                indent = "     "
            ),
            "   </Matrices>"
        )
    } else {
        lines <- c(lines, "   <Matrices/>")
    }

    # Derive cytometer attributes from the first sample's FCS header if
    #   possible
    first_header <- if (length(samples) > 0) samples[[1]]$fcs_header
    cyt_attrs <- derive_cytometer_attrs(first_header)

    # Build TransformStore content from all channel transforms that will be
    #   used in this workspace. We use the original (uncompensated) parameter
    #   names for the cytometer-level TransformStore, matching FlowJo's
    #   display transform list.
    transform_store_lines <- fj10_transform_store_xml(
        gating_set, samples, force_XSC_linear
    )

    lines <- c(
        lines,
        fj10_cytometer_xml(cyt_attrs, transform_store_lines)
    )

    list(lines = lines, ws_matrix_id = ws_matrix_id)
}

#' Graph chrome shared by group nodes
#'
#' Renders <GraphSettings>, <GraphEnvironment> with its TextTraits, and the
#' GraphEnvironment close tag at the given indentation.
#'
#' @param indent Leading indentation string for the outer elements
#' @return Character vector of XML lines
#' @keywords internal
fj10_graph_chrome_xml <- function(indent) {
    d2 <- paste0(indent, "  ")
    c(
        paste0(
            indent, '<GraphSettings level="5%" smoothingHighResolution="1"',
            ' contourHighResolution="1" histogramSmoothingCount="0" ',
            'graphResolution="256" showOutliers="0" drawLargeDots="0" ',
            'dotsToDraw="8000" tint="le.chartfill.tinted.40" lineWeight="',
            'le.lineweight.normal" lineStyle="le.linestyle.solid" ',
            "/>"
        ),
        paste0(
            indent, '<GraphEnvironment showGrid="0" showAxes="tnlTNL" ',
            'showGates="1" showFreqOnPlots="1" showGateNameOnPlots="1" ',
            'showMedians="0" showUncomped="0" addEventParam="0" ',
            'lastYAxisName="" ',
            ">"
        ),
        paste0(
            d2, '<TextTraits font="SansSerif" size="11" name="',
            'Labels" style="plain" color="#000000" background="#00ffffff" ',
            'just="left" ',
            "/>"
        ),
        paste0(
            d2, '<TextTraits font="SansSerif" size="11" name="',
            'LayoutGates" style="plain" color="#000000" background="',
            '#00ffffff" just="left" ',
            "/>"
        ),
        paste0(
            d2, '<TextTraits font="SansSerif" size="9" name="',
            'Numbers" style="plain" color="#000000" background="#00ffffff" ',
            'just="left" ',
            "/>"
        ),
        paste0(
            d2, '<TextTraits font="SansSerif" size="9" name="Legend"',
            ' style="plain" color="#000000" background="#00ffffff" just="',
            'left" ',
            "/>"
        ),
        paste0(indent, "</GraphEnvironment>")
    )
}

#' Graph block shared by group nodes
#'
#' Renders the <Graph> element (opening tag, axes, graph settings chrome, and
#' close tag) used inside both built-in group nodes.
#'
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_graph_xml <- function() {
    c(
        paste0(
            '       <Graph smoothing="0" backColor="#ffffff" foreColor="',
            '#000000" type="Pseudocolor" fast="1" ',
            ">"
        ),
        '         <Axis dimension="x" name="" label="" auto="auto" />',
        '         <Axis dimension="y" name="" label="" auto="auto" />',
        fj10_graph_chrome_xml("         "),
        "       </Graph>"
    )
}

#' User-defined groups XML
#'
#' Renders one <Group> element with Criteria and SampleRefs for each entry of
#' the groups list.
#'
#' @param groups List of group data as built by build_group_list
#' @return Character vector of XML lines
#' @keywords internal
fj10_user_groups_xml <- function(groups) {
    lines <- character(0)
    for (group_id in names(groups)) {
        group <- groups[[group_id]]
        lines <- c(
            lines,
            sprintf(paste0(
                '    <Group name="%s"  live="1"  role="',
                'ws.group.dlog.test"  key=""  synchronized="0"  ',
                'foreground="#000000"  fontStyle="bold" ',
                ">"
            ), group$name),
            "      <Criteria/>",
            "      <SampleRefs>"
        )

        # Add sample references
        for (sample_id in group$sample_ids) {
            lines <- c(
                lines,
                sprintf('        <SampleRef sampleID="%d"/>', sample_id)
            )
        }

        lines <- c(
            lines,
            "         </SampleRefs>",
            "         <Keywords/>",
            "       </Group>"
        )
    }
    lines
}

#' Compensation group XML
#'
#' Renders the <Group name="Compensation"> element with its unstained/comp
#' file criteria.
#'
#' @return Character vector of XML lines
#' @keywords internal
fj10_compensation_group_xml <- function() {
    c(
        paste0(
            '       <Group name="Compensation" live="1" role="',
            'ws.group.dlog.compensation" key="" synchronized="0" ',
            'foreground="#bc1900" fontStyle="bold" ',
            ">"
        ),
        "         <Criteria>",
        paste0(
            '           <Criterion connector="And" keyword="$FIL" function=',
            '"Contains" value="unstained" ',
            "/>"
        ),
        paste0(
            '           <Criterion connector="Or" keyword="$FIL" function="',
            'Contains" value="comp" ',
            "/>"
        ),
        "         </Criteria>",
        "         <Keywords/>",
        "       </Group>"
    )
}

#' Build one GroupNode element
#'
#' Renders a <GroupNode> with the given name (also used as owningGroup), the
#' shared graph block, and the provided inner content.
#'
#' @param name Group node name (also used as owningGroup)
#' @param inner_lines Character vector of XML lines placed before the close
#'   tag
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_node_xml <- function(name, inner_lines) {
    c(
        paste0(
            '     <GroupNode name="', name, '" annotation="" owningGroup=',
            '"', name, '" expanded="1" sortPriority="10" count="-1" ',
            ">"
        ),
        fj10_group_graph_xml(),
        inner_lines,
        "     </GroupNode>"
    )
}

#' Build the workspace Groups section
#'
#' Renders the "All Samples" and "Compensation" group nodes together with any
#' user-defined groups and their sample references.
#'
#' @param groups List of group data as built by build_group_list
#' @return Character vector of XML lines for the Groups section content
#' @keywords internal
fj10_groups_section <- function(groups) {
    c(
        fj10_group_node_xml("All Samples", fj10_user_groups_xml(groups)),
        fj10_group_node_xml(
            "Compensation", fj10_compensation_group_xml()
        )
    )
}

#' Derive the heatmap parameter for a sample
#'
#' Returns the "Comp-" prefixed name of the first compensated channel, or ""
#' when the sample has no spillover matrix.
#'
#' @param sample Sample data entry as built by build_sample_list
#' @return Single character string ("" when no compensation is present)
#' @keywords internal
heat_map_param_for_sample <- function(sample) {
    if (is.null(sample$spill_matrix)) {
        return("")
    }
    first_chan <- colnames(sample$spill_matrix)[1]
    if (!is.null(first_chan) && nzchar(first_chan)) {
        paste0("Comp-", first_chan)
    } else {
        ""
    }
}

#' Build the sample-level Transformations XML block
#'
#' Collects the sample's transformations restricted to the channels referenced
#' by gates, optionally adds linear transforms for missing scatter channels,
#' mirrors transforms between original and Comp- channel names when
#' compensation is present, and renders the <Transformations> block.
#'
#' @param sample_gh GatingHierarchy for the sample (may be NULL)
#' @param sample Sample data entry as built by build_sample_list
#' @param gates List of gate data
#' @param force_XSC_linear Ensure referenced channels have linear transforms
#' @return Character vector of XML lines for the Transformations block
#' @keywords internal
fj10_sample_transforms_section <- function(sample_gh, sample, gates,
                                            force_XSC_linear) {
    all_transforms <- flowWorkspace::gh_get_transformations(sample_gh)
    referenced_channels <- get_referenced_channels(gates)
    transforms <-
        all_transforms[names(all_transforms) %in% referenced_channels]

    transforms <- fj10_add_linear_transforms(transforms,
        referenced_channels, force_XSC_linear
    )

    # If compensation is present, add duplicate transforms for the original
    # (uncompensated) channel names as well.
    if (!is.null(sample$spill_matrix)) {
        transforms <- fj10_mirror_comp_transforms(transforms, sample)
    }

    lines <- c("      <Transformations>")
    for (tr_idx in seq_along(transforms)) {
        channel <- names(transforms)[tr_idx]
        transform_obj <- transforms[[tr_idx]]
        atr_tr <- attributes(transform_obj)
        if (is.null(atr_tr$type)) atr_tr$type <- "Linear"

        data_range <- fj10_channel_data_range(sample_gh, channel)

        lines <- c(
            lines,
            emit_transform_xml(atr_tr$type, channel, transform_obj,
                atr_tr, data_range,
                indent = "        "
            )
        )
    }
    lines <- c(lines, "      </Transformations>")

    lines
}

#' Add linear transforms for unreferenced scatter channels
#'
#' @param transforms Named list of transforms
#' @param referenced_channels Channel names referenced by gates
#' @param force_XSC_linear Ensure referenced channels have linear transforms
#' @return Possibly augmented transform list
#' @noRd
fj10_add_linear_transforms <- function(transforms, referenced_channels,
                                        force_XSC_linear) {
    if (!force_XSC_linear) {
        return(transforms)
    }
    lin_trans <- flowCore::linearTransform(
        transformationId = "defaultLin", a = 1, b = 0
    )
    for (marker in referenced_channels) {
        if (is.null(transforms[[marker]])) {
            transforms[[marker]] <- lin_trans@.Data
            attr(transforms[[marker]], "type") <- "Linear"
        }
    }
    transforms
}

#' Mirror transforms between Comp- and original channel names
#'
#' @param transforms Named list of transforms
#' @param sample Sample data entry (with $spill_matrix)
#' @return Possibly augmented transform list
#' @noRd
fj10_mirror_comp_transforms <- function(transforms, sample) {
    orig_names <- colnames(sample$spill_matrix)
    for (nm in orig_names) {
        # TODO verify that comp name has to be changed.
        comp_nm <- paste0("Comp-", nm)
        if (!is.null(transforms[[comp_nm]]) &&
            is.null(transforms[[nm]])) {
            transforms[[nm]] <- transforms[[comp_nm]]
        }
    }
    # Also ensure all Comp- channels are present
    for (nm in orig_names) {
        # TODO verify that comp name has to be changed.
        comp_nm <- paste0("Comp-", nm)
        if (is.null(transforms[[comp_nm]]) &&
            !is.null(transforms[[nm]])) {
            transforms[[comp_nm]] <- transforms[[nm]]
        }
    }
    transforms
}

#' Root population count and default gate dims for a sample node
#'
#' @param sample Sample data entry as built by build_sample_list
#' @param sample_gh GatingHierarchy for the sample (may be NULL)
#' @return list(root_count, gate_dims)
#' @noRd
fj10_sample_graph_inputs <- function(sample, sample_gh) {
    # Get root population count
    root_count <- sample$count # default to sample count
    if (!is.null(sample_gh)) {
        root_count <- tryCatch(
            {
                flowWorkspace::gh_pop_get_count(sample_gh, "root")
            },
            error = function(e) {
                sample$count # fallback to sample count
            }
        )
    }
    # save(file = "generate_flowjo10_xml.debug.RData", list = ls())
    gate_dims <- tryCatch(
        {
            parameters(gh_pop_get_gate(
                sample_gh,
                gh_get_pop_paths(sample_gh)[2]
            ))
        },
        error = function(e) {
            NULL
        }
    )

    list(root_count = root_count, gate_dims = gate_dims)
}

#' TextTraits line for the sample GraphEnvironment block
#'
#' @param size Font size attribute value
#' @param name Traits name attribute value
#' @return Single XML line
#' @noRd
fj10_graph_text_traits_xml <- function(size, name) {
    paste0(
        '             <TextTraits font="SansSerif" size="', size,
        '" name="', name, '" style="plain" color="#000000" ',
        'background="#00ffffff" just="left" ',
        "/>"
    )
}

#' Axis line for a sample Graph element
#'
#' @param dimension Axis dimension attribute ("x" or "y")
#' @param name Axis parameter name
#' @return Single XML line
#' @noRd
fj10_axis_xml <- function(dimension, name) {
    sprintf(
        paste0(
            '           <Axis dimension="%s" name="%s" label="" ',
            'auto="auto" ',
            "/>"
        ),
        dimension, name
    )
}

#' Graph-settings chrome for a sample node's Graph element
#'
#' Fixed indentation matching the sample-node layout.
#'
#' @return Character vector of XML lines
#' @noRd
fj10_sample_graph_chrome_xml <- function() {
    c(
        paste0(
            '           <GraphSettings level="5%" ',
            'smoothingHighResolution="1" contourHighResolution="1" ',
            'histogramSmoothingCount="0" graphResolution="256" ',
            'showOutliers="0" drawLargeDots="0" dotsToDraw="8000" tint=',
            '"le.chartfill.tinted.40" lineWeight="le.lineweight.normal"',
            ' lineStyle="le.linestyle.solid" ',
            "/>"
        ),
        paste0(
            '           <GraphEnvironment showGrid="0" showAxes="',
            'tnlTNL" showGates="1" showFreqOnPlots="1" ',
            'showGateNameOnPlots="1" showMedians="0" showUncomped="0" ',
            'addEventParam="0" lastYAxisName="" ',
            ">"
        ),
        fj10_graph_text_traits_xml(11, "Labels"),
        fj10_graph_text_traits_xml(11, "LayoutGates"),
        fj10_graph_text_traits_xml(9, "Numbers"),
        fj10_graph_text_traits_xml(9, "Legend"),
        paste0(
            '             <WindowPosition x="247" y="-1415" width="390"',
            ' height="679" displayed="0" panelState="---" ',
            "/>"
        ),
        "           </GraphEnvironment>",
        "         </Graph>"
    )
}

#' Build one sample's SampleNode/Graph XML block
#'
#' Renders the <SampleNode> opening tag, its <Graph> element with axes and
#' graph settings, and closes </Graph>.
#'
#' @param sample Sample data entry as built by build_sample_list
#' @param sample_gh GatingHierarchy for the sample (may be NULL)
#' @param sample_id 1-based index of the sample
#' @return Character vector of XML lines for the SampleNode/Graph block
#' @keywords internal
fj10_sample_graph_section <- function(sample, sample_gh, sample_id) {
    graph_inputs <- fj10_sample_graph_inputs(sample, sample_gh)
    root_count <- graph_inputs$root_count
    gate_dims <- graph_inputs$gate_dims
    # Only add y-axis if second dimension exists
    # Use $FIL keyword for sample name if available, otherwise use
    #   sample$name
    sample_display_name <- sample$keywords[["$FIL"]] %||% sample$name
    #######

    c(
        sprintf(
            paste0(
                '       <SampleNode name="%s" annotation="" ',
                'owningGroup="" expanded="1" sortPriority="10" count="',
                '%d" sampleID="%d" ',
                ">"
            ),
            xml_encode(sample_display_name), root_count, sample_id
        ),
        sprintf(
            paste0(
                '         <Graph smoothing="0" backColor="#ffffff" ',
                'foreColor="#000000" heatMapStatParameter="%s" type="',
                'Pseudocolor" fast="1" ',
                ">"
            ),
            heat_map_param_for_sample(sample)
        ),
        fj10_axis_xml("x", if (is.null(gate_dims) ||
            length(gate_dims) < 1) {
            "FSC-A"
        } else {
            gate_dims[[1]]
        }),
        fj10_axis_xml("y", if (is.null(gate_dims) ||
            length(gate_dims) < 2) {
            ""
        } else {
            gate_dims[[2]]
        }),
        fj10_sample_graph_chrome_xml()
    )
}

#' Build the XML for one sample's SampleList entry
#'
#' Renders DataSet, sample-level spillover matrix, sample-level
#' Transformations, Keywords, and the SampleNode/Graph block (including
#' subpopulations) for a single sample.
#'
#' @param gating_set GatingSet (or list) holding sample hierarchies
#' @param sample Sample data entry as built by build_sample_list
#' @param sample_id 1-based index of the sample
#' @param gates List of gate data
#' @param populations List of population data
#' @param ws_matrix_id Workspace-level matrix id, or NULL
#' @param force_XSC_linear Ensure referenced channels have linear transforms
#' @return Character vector of XML lines for this sample
#' @keywords internal
fj10_sample_section <- function(gating_set, sample, sample_id, gates,
                                populations, ws_matrix_id, force_XSC_linear) {
    # Get gating hierarchy for this sample if available
    sample_gh <- NULL
    if (requireNamespace("flowWorkspace", quietly = TRUE)) {
        tryCatch(
            {
                sample_gh <- gating_set[[sample$name]]
            },
            error = function(e) {
                # Continue without sample_gh if not available
            }
        )
    }

    lines <- c(
        sprintf("     <Sample>"),
        sprintf(
            '       <DataSet uri="file:%s" sampleID="%d" />',
            xml_encode(sample$uri), sample_id
        )
    )

    # Add sample-level spillover matrix if compensation is present
    if (!is.null(sample$spill_matrix) && !is.null(ws_matrix_id)) {
        lines <- c(
            lines,
            build_spillover_matrix_xml(sample$spill_matrix,
                ws_matrix_id,
                indent = "       "
            )
        )
    }

    lines <- c(
        lines,
        fj10_sample_transforms_section(sample_gh, sample,
            gates, force_XSC_linear
        ),
        fj10_sample_keywords_xml(sample)
    )

    lines <- c(lines, fj10_sample_node_xml(
        gating_set, sample, sample_gh, sample_id, gates, populations,
        force_XSC_linear
    ))

    lines
}

#' SampleNode block for one sample
#'
#' Emits the SampleNode opening tag, Graph block, subpopulations, and the
#' closing tags.
#'
#' @param gating_set GatingSet (or list) holding sample hierarchies
#' @param sample Sample data entry as built by build_sample_list
#' @param sample_gh GatingHierarchy for the sample (may be NULL)
#' @param sample_id 1-based index of the sample
#' @param gates List of gate data
#' @param populations List of population data
#' @param force_XSC_linear Ensure referenced channels have linear transforms
#' @return Character vector of XML lines for the SampleNode block
#' @noRd
fj10_sample_node_xml <- function(gating_set, sample, sample_gh, sample_id,
                                  gates, populations, force_XSC_linear) {
    # ---- SampleNode opening tag + Graph
    #   -----------------------------------
    heat_map_param <- heat_map_param_for_sample(sample)
    c(
        fj10_sample_graph_section(sample, sample_gh, sample_id),
        fj10_sample_subpops_xml(
            sample_gh, gates, populations, sample_id, heat_map_param
        ),
        "       </SampleNode>", "     </Sample>"
    )
}

#' Keyword lines for one sample
#'
#' @param sample Sample data entry as built by build_sample_list
#' @return Character vector of XML lines for the Keywords block
#' @noRd
fj10_sample_keywords_xml <- function(sample) {
    lines <- c("      <Keywords>")
    for (kw_name in names(sample$keywords)) {
        lines <- c(
            lines,
            sprintf(
                '        <Keyword name="%s" value="%s"/>',
                xml_encode(kw_name), xml_encode(sample$keywords[[kw_name]])
            )
        )
    }
    c(lines, "      </Keywords>")
}

#' Subpopulations block for one sample
#'
#' @param sample_gh GatingHierarchy for the sample (may be NULL)
#' @param gates List of gate data
#' @param populations List of population data (all samples)
#' @param sample_id 1-based index of the sample
#' @param heat_map_param Channel name for heatMapStatParameter
#' @return Character vector of XML lines (empty when no hierarchy)
#' @noRd
fj10_sample_subpops_xml <- function(sample_gh, gates, populations,
                                     sample_id, heat_map_param) {
    if (!(requireNamespace("flowWorkspace", quietly = TRUE) &&
        !is.null(sample_gh))) {
        return(character(0))
    }

    c(
        "         <Subpopulations>",
        generate_sample_subpopulations_xml(
            sample_gh,
            gates,
            populations = populations[
                names(populations)[startsWith(
                    names(populations),
                    paste0("pop_", sample_id, "_")
                )]
            ],
            parent_path = "root",
            indent = "           ",
            heat_map_param = heat_map_param # <-- threaded through
        ),
        "         </Subpopulations>"
    )
}

#' PrintLayout XML fragment
#'
#' Renders the standard <PrintLayout> self-closing element used by the
#' TableEditor, LayoutEditor, and Experiment sections.
#'
#' @param indent Leading indentation string
#' @return Character vector of one XML line
#' @keywords internal
fj10_print_layout_xml <- function(indent) {
    paste0(
        indent, "<PrintLayout flipPattern0=\"0\" rows=\"1\" columns=\"1\" ",
        "padding=\"36\" header=\"\" footer=\"\" headerActive=\"0\" ",
        "footerActive=\"0\" scalingMode=\"fj.print.scale.none\" scaling=\"1\"",
        " orientation=\"1\" width=\"595.2744\" height=\"841.8888\" ",
        "imageableX=\"72\" imageableY=\"72\" imageableWidth=\"451.2744\" ",
        "imageableHeight=\"697.8888\" ",
        "/>"
    )
}

#' PageSection header/footer XML pair
#'
#' Renders the standard <PageSection> header and footer pair used by the
#' TableEditor and LayoutEditor sections.
#'
#' @param indent Leading indentation string for both elements
#' @return Character vector of two XML lines
#' @keywords internal
fj10_page_sections_xml <- function(indent) {
    c(
        paste0(
            indent, '<PageSection sectionName="header" >&lt;table ',
            "width=&quot;100%&quot;&gt;&lt;tr&gt;&lt;td ",
            "align=&quot;left&quot; ",
            "valign=&quot;top&quot;&gt;&amp;NBSP&amp;NBSP&amp;NBSP&amp;NBSP",
            "&lt;IMG SRC=&quot;file:/Applications/FlowJo.app/Contents/",
            "Resources/Java/images/",
            "fj_icon.png&quot;&gt;&lt;/IMG&gt;",
            "&lt;br/&gt;FlowJo, LLC&lt;/td&gt;",
            "&lt;td align=&quot;right&quot; valign=&quot;top&quot;&gt;",
            "Page &lt;PageNumber/&gt;&lt;/td&gt;&lt;/tr&gt;",
            "&lt;/table&gt;</PageSection>"
        ),
        paste0(
            indent, '<PageSection sectionName="footer" >&lt;table ',
            "width=&quot;100%&quot;&gt;&lt;tr&gt;&lt;td ",
            "align=&quot;left&quot;  ",
            "valign=&quot;bottom&quot;&gt;&lt;LongDate/&gt;&lt;/td&gt;",
            "&lt;td align=&quot;right&quot; valign=&quot;bottom&quot;&gt;",
            "&lt;Version/&gt;&lt;/td&gt;&lt;/tr&gt;",
            "&lt;/table&gt;</PageSection>"
        )
    )
}

#' TableEditor section XML
#'
#' Renders the <TableEditor> block of the FlowJo v10 workspace.
#'
#' @return Character vector of XML lines
#' @keywords internal
fj10_table_editor_xml <- function() {
    c(
        '   <TableEditor title="FlowJo Tables" current="Table" >',
        paste0(
            '     <Table name="Table" outputFile="" color="#00ffffff" ',
            'isBatch="0" quickclose="0" destination="toDisplay" ',
            'outputFormat="fj.document.type.table" ',
            ">"
        ),
        fj10_print_layout_xml("       "),
        fj10_page_sections_xml("       "),
        paste0(
            '       <Iteration iterationType="SAMPLE" iterationValue="1" ',
            'iterationKeyword="" discriminator="" panelSize="1" groupName="',
            'workspaceSelection" ',
            "/>"
        ),
        "     </Table>",
        "   </TableEditor>"
    )
}

#' LayoutEditor section XML
#'
#' Renders the <LayoutEditor> block of the FlowJo v10 workspace.
#'
#' @return Character vector of XML lines
#' @keywords internal
fj10_layout_editor_xml <- function() {
    c(
        paste0(
            '   <LayoutEditor title="FlowJo Layouts" current="Layout" ',
            'showGrid="0" showPageBreaks="0" showGuides="0" ',
            'showDebugOutput="0" ',
            ">"
        ),
        paste0(
            '     <Layout name="Layout" outputFile="" color="#00ffffff" ',
            'isBatch="0" showGrid="0" showRulers="1" showDebugOutput="0" ',
            'showGuides="0" showPageBreaks="1" scale="1" ',
            ">"
        ),
        fj10_print_layout_xml("       "),
        fj10_page_sections_xml("       "),
        paste0(
            '       <Iteration iterationType="OFF" iterationValue="1" ',
            'iterationKeyword="" discriminator="" panelSize="1" groupName="',
            'workspaceSelection" ',
            "/>"
        ),
        paste0(
            '       <BatchSettings useCurrentGroup="1" length="3" name="" ',
            'order="ACROSS" direction="COLUMNS" append="0" destination="',
            'toLayout" separatePages="0" launchApp="1" header="0" footer="',
            '0" commandLineBatch="0" ',
            "/>"
        ),
        "       <FigList/>",
        "     </Layout>",
        '     <WindowPosition x="0" y="3" width="900" height="600" />',
        "   </LayoutEditor>"
    )
}

#' Experiment section XML
#'
#' Renders the <Experiment> block of the FlowJo v10 workspace.
#'
#' @return Character vector of XML lines
#' @keywords internal
fj10_experiment_xml <- function() {
    c(
        "   <Experiment>",
        paste0(
            '     <PlateModel name="Plate" color="#00ffffff" rows="8" ',
            'columns="12" plateID="00000" expID="000-00000" format="Plate" ',
            'showNEntries="1" peHeatmap="1" peShowEnums="1" peThickBorders=',
            '"1" ',
            ">"
        ),
        fj10_print_layout_xml("       "),
        "     </PlateModel>",
        "     <PlateEditorState>",
        "       <KeywordList>",
        '         <Keyword attribute="Assay" value="GFP Reporter" />',
        '         <Keyword attribute="Time point" value="24hr" />',
        paste0(
            '         <Keyword attribute="Treatment &quot;Drug A&quot;" ',
            'value="10ug/L" ',
            "/>"
        ),
        "       </KeywordList>",
        "       <StagingArea>",
        "         <StagingWell/>",
        "         <StagingWell/>",
        "         <StagingWell/>",
        "         <StagingWell/>",
        "       </StagingArea>",
        "     </PlateEditorState>",
        "   </Experiment>"
    )
}

#' Build the workspace report editor sections
#'
#' Renders the TableEditor, LayoutEditor, and Scripts sections of the FlowJo
#' v10 workspace XML (static template content).
#'
#' @return Character vector of XML lines
#' @keywords internal
fj10_report_sections <- function() {
    # Scripts section
    c(
        fj10_table_editor_xml(),
        fj10_layout_editor_xml(),
        "   <Scripts>",
        '     <Script lang="text/javascript" name="New Script     " />',
        "   </Scripts>",
        fj10_experiment_xml()
    )
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
generate_flowjo10_xml <- function(gating_set, samples, gates,
                                    populations, groups, workspace_name,
                                        output_path,
                                    force_XSC_linear = FALSE,
                                        minimal_fj11 = FALSE) {
    if (minimal_fj11) {
        # Minimal FJ11 format - very simple structure
        xml_lines <- c(
            paste0(
                '<?xml version="1.0" encoding="UTF-8"?><Workspace',
                ' flowJoVersion="10.10.0">'
            ),
            "<Matrices />"
        )
        ws_matrix_id <- NULL
    } else {
        xml_lines <- fj10_workspace_header(output_path)

        cyt_section <- fj10_workspace_cytometers_section(
            gating_set, samples, force_XSC_linear
        )
        xml_lines <- c(xml_lines, cyt_section$lines)
        ws_matrix_id <- cyt_section$ws_matrix_id
    }

    # Add groups
    xml_lines <- c(xml_lines, "   <Groups>")
    xml_lines <- c(xml_lines, fj10_groups_section(groups))
    xml_lines <- c(xml_lines, "   </Groups>")

    # Add sample list
    xml_lines <- c(xml_lines, "   <SampleList>")
    xml_lines <- c(
        xml_lines,
        fj10_all_sample_sections(
            gating_set, samples, gates, populations, ws_matrix_id,
            force_XSC_linear
        ),
        "   </SampleList>"
    )

    return(paste(c(xml_lines, fj10_workspace_tail_sections()),
        collapse = "\n"
    ))
}

#' XML sections for every sample in the SampleList
#'
#' @param gating_set GatingSet (or list) holding sample hierarchies
#' @param samples List of sample data as built by build_sample_list
#' @param gates List of gate data
#' @param populations List of population data
#' @param ws_matrix_id Workspace-level matrix id, or NULL
#' @param force_XSC_linear Ensure referenced channels have linear transforms
#' @return Character vector of XML lines
#' @noRd
fj10_all_sample_sections <- function(gating_set, samples, gates, populations,
                                      ws_matrix_id, force_XSC_linear) {
    # Add samples (each containing DataSet, Transformations, Keywords, and
    #   SampleNode)
    unlist(lapply(seq_along(samples), function(sample_id) {
        fj10_sample_section(
            gating_set,
            samples[[sample_id]],
            sample_id,
            gates,
            populations,
            ws_matrix_id,
            force_XSC_linear
        )
    }))
}

#' Fixed trailing sections of a FlowJo v10 workspace
#'
#' Reports, Exports, SOPS, weights, and the closing Workspace tag.
#'
#' @return Character vector of XML lines
#' @noRd
fj10_workspace_tail_sections <- function() {
    c(
        fj10_report_sections(),
        # Add Exports section
        "   <Exports/>",
        # Add SOPS section
        "   <SOPS/>",
        # Add weights section
        "   <weights/>",
        # Close workspace
        " </Workspace>"
    )
}

#' Build one subpopulation Graph block
#'
#' Renders the <Graph> element for a subpopulation node: derives the axes from
#' the node's first child gate (or its own gate when it is a leaf), and emits
#' the shared GraphSettings/GraphEnvironment/TextTraits chrome.
#'
#' @param gating_hierarchy GatingHierarchy object
#' @param child_path Path of the population whose graph is rendered
#' @param heat_map_param Channel name used for heatMapStatParameter
#' @return Character vector of XML lines for the Graph block
#' @keywords internal
fj10_subpop_graph_xml <- function(gating_hierarchy, child_path,
                                    heat_map_param) {
    gate_dims <- fj10_subpop_gate_dims(gating_hierarchy, child_path)
    x_axis <- if (is.null(gate_dims) || length(gate_dims) < 1) {
        "FSC-A"
    } else {
        gate_dims[[1]]
    }
    y_axis <- if (is.null(gate_dims) || length(gate_dims) < 2) {
        ""
    } else {
        gate_dims[[2]]
    }

    c(
        sprintf(
            paste0(
                '        <Graph smoothing="0" backColor="#ffffff" ',
                'foreColor="#000000" heatMapStatParameter="%s" type="',
                'Pseudocolor" fast="1"',
                ">"
            ),
            heat_map_param
        ),
        fj10_subpop_axis_xml("x", x_axis),
        fj10_subpop_axis_xml("y", y_axis),
        fj10_subpop_graph_chrome_xml()
    )
}

#' Fixed GraphSettings/GraphEnvironment chrome for a subpopulation Graph
#'
#' @return Character vector of XML lines
#' @noRd
fj10_subpop_graph_chrome_xml <- function() {
    c(
        paste0(
            '          <GraphSettings level="5%" ',
            'smoothingHighResolution="1" contourHighResolution="1" ',
            'histogramSmoothingCount="0" graphResolution="256" ',
            'showOutliers="0" drawLargeDots="0" dotsToDraw="8000" tint=',
            '"le.chartfill.tinted.40" lineWeight="le.lineweight.normal"',
            ' lineStyle="le.linestyle.solid" ',
            "/>"
        ),
        paste0(
            '          <GraphEnvironment showGrid="0" showAxes="tnlTNL"',
            ' showGates="1" showFreqOnPlots="1" showGateNameOnPlots="1"',
            ' showMedians="0" showUncomped="0" addEventParam="0" ',
            'lastYAxisName=""',
            ">"
        ),
        fj10_subpop_text_traits_xml(),
        paste0(
            '            <WindowPosition x="247" y="-1415" width="390" ',
            'height="582" displayed="0" panelState="---" ',
            "/>"
        ),
        "          </GraphEnvironment>",
        "        </Graph>"
    )
}

#' TextTraits lines inside a subpopulation GraphEnvironment
#'
#' @return Character vector of four TextTraits XML lines
#' @noRd
fj10_subpop_text_traits_xml <- function() {
    vapply(
        c("Labels:11", "LayoutGates:11", "Numbers:9", "Legend:9"),
        function(traits) {
            parts <- strsplit(traits, ":")[[1]]
            sprintf(
                paste0(
                    '            <TextTraits font="SansSerif" size="%s" ',
                    'name="%s" style="plain" color="#000000" ',
                    'background="#00ffffff" just="left" ',
                    "/>"
                ),
                parts[2], parts[1]
            )
        },
        character(1)
    )
}

#' Axis line inside a subpopulation Graph block
#'
#' @param dimension Axis dimension attribute ("x" or "y")
#' @param name Axis parameter name
#' @return Single XML line
#' @noRd
fj10_subpop_axis_xml <- function(dimension, name) {
    sprintf(
        paste0(
            '          <Axis dimension="%s" name="%s" label="" auto=',
            '"auto" ',
            "/>"
        ),
        dimension, name
    )
}

#' Gate dimensions shown in a subpopulation's Graph block
#'
#' Prefers the first child's gate (leaf nodes show their own gate).
#'
#' @param gating_hierarchy GatingHierarchy object
#' @param child_path Path of the population whose graph is rendered
#' @return Parameter names from the gate, or NULL
#' @noRd
fj10_subpop_gate_dims <- function(gating_hierarchy, child_path) {
    grandchild_path <- tryCatch(
        flowWorkspace::gs_pop_get_children(gating_hierarchy, child_path,
            path = "auto"
        )[[1]],
        error = function(e) NA_character_
    )
    if (is.na(grandchild_path)) {
        grandchild_path <- child_path # leaf -> show own gate
    }

    tryCatch(
        flowCore::parameters(
            flowWorkspace::gh_pop_get_gate(
                gating_hierarchy,
                grandchild_path
            )
        ),
        error = function(e) NULL
    )
}

#' Emit the inner content of one subpopulation Gate element
#'
#' Dispatches on the gate definition type and renders the matching
#' Gating-ML gate element (Rectangle, Polygon, or Ellipsoid).
#'
#' @param matching_pop Population record holding the gate id
#' @param gates List of gate data
#' @param indent Current indentation string
#' @return Character vector of XML lines for the gate content
#' @keywords internal
fj10_subpop_gate_xml <- function(matching_pop, gates, indent) {
    gate <- gates$gates[[matching_pop$gate_id]]
    gate_def <- gate$definition

    parent_id_attr <- if (gate$parent != "root") {
        sprintf('gating:parent_id="%s" ', gate$parent_id)
    } else {
        ""
    }

    lines <- c(
        sprintf(
            '%s  <Gate gating:id="%s" %s>', indent, gate$id,
            parent_id_attr
        )
    )

    # ---- RectangleGate
    #   ---------------------------------------------------
    if (!is.null(gate_def) && gate_def$type == "rectangle") {
        lines <- c(lines, fj10_subpop_rect_gate_xml(gate_def, indent))

        # ---- PolygonGate
        #   -----------------------------------------------------
    } else if (!is.null(gate_def) && gate_def$type == "polygon") {
        lines <- c(lines, fj10_subpop_poly_gate_xml(gate_def, indent))

        # ---- EllipsoidGate
        #   ---------------------------------------------------
    } else if (!is.null(gate_def) && gate_def$type == "ellipsoid") {
        lines <- c(lines, fj10_subpop_ellip_gate_xml(gate_def, indent))
    }

    lines <- c(lines, sprintf("%s  </Gate>", indent))

    lines
}

#' Emit a Gating-ML RectangleGate element
#'
#' @param gate_def Gate definition with dimensions
#' @param indent Current indentation string
#' @return Character vector of XML lines
#' @keywords internal
fj10_subpop_rect_gate_xml <- function(gate_def, indent) {
    lines <- c(
        sprintf(
            paste0(
                '%s    <gating:RectangleGate eventsInside="1"',
                ' annoOffsetX="0" annoOffsetY="0"',
                ' tint="#000000" isTinted="0"',
                ' lineWeight="Normal" userDefined="1"',
                ' percentX="0" percentY="0" >'
            ),
            indent
        )
    )

    is_1d <- length(gate_def$dimensions) == 1L
    for (dim in gate_def$dimensions) {
        range_attr <- if (is_1d) {
            sprintf(
                ' gating:min="%s" gating:max="%s" yRatio="0.5" >',
                format_gate_num(dim$min), format_gate_num(dim$max)
            )
        } else {
            sprintf(
                ' gating:min="%s" gating:max="%s" >',
                format_gate_num(dim$min), format_gate_num(dim$max)
            )
        }
        lines <- c(
            lines,
            sprintf(
                paste0(
                    "%s      <gating:dimension",
                    "%s"
                ),
                indent, range_attr
            ),
            sprintf(
                paste0(
                    "%s        <data-type:fcs-dimension",
                    ' data-type:name="%s" />'
                ),
                indent, xml_encode(dim$parameter)
            ),
            sprintf("%s      </gating:dimension>", indent)
        )
    }
    lines <- c(lines, sprintf("%s    </gating:RectangleGate>", indent))

    lines
}

#' Emit a Gating-ML PolygonGate element
#'
#' @param gate_def Gate definition with dimensions and vertices
#' @param indent Current indentation string
#' @return Character vector of XML lines
#' @keywords internal
fj10_subpop_poly_gate_xml <- function(gate_def, indent) {
    lines <- c(
        sprintf(
            paste0(
                '%s    <gating:PolygonGate eventsInside="1"',
                ' annoOffsetX="0" annoOffsetY="0"',
                ' tint="#000000" isTinted="0"',
                ' lineWeight="Normal" userDefined="1"',
                ' quadId="-1" gateResolution="256" >'
            ),
            indent
        )
    )
    for (dim in gate_def$dimensions) {
        lines <- c(
            lines,
            sprintf("%s      <gating:dimension>", indent),
            sprintf(
                paste0(
                    "%s        <data-type:fcs-dimension",
                    ' data-type:name="%s" />'
                ),
                indent, xml_encode(dim$parameter)
            ),
            sprintf("%s      </gating:dimension>", indent)
        )
    }
    for (vertex in gate_def$vertices) {
        lines <- c(lines, fj10_subpop_vertex_xml(indent, vertex))
    }
    lines <- c(lines, sprintf("%s    </gating:PolygonGate>", indent))

    lines
}

#' One gating:vertex for a subpop PolygonGate (%s formatting)
#'
#' @param indent XML indentation string
#' @param vertex Vertex with x/y values
#' @return Character vector of XML lines
#' @noRd
fj10_subpop_vertex_xml <- function(indent, vertex) {
    c(
        sprintf("%s      <gating:vertex>", indent),
        sprintf(
            paste0(
                "%s        <gating:coordinate",
                ' data-type:value="%s" />'
            ),
            indent, format_gate_num(vertex$x)
        ),
        sprintf(
            paste0(
                "%s        <gating:coordinate",
                ' data-type:value="%s" />'
            ),
            indent, format_gate_num(vertex$y)
        ),
        sprintf("%s      </gating:vertex>", indent)
    )
}

#' Emit a Gating-ML EllipsoidGate element
#'
#' @param gate_def Gate definition with x/y parameters, foci, and edge points
#' @param indent Current indentation string
#' @return Character vector of XML lines
#' @keywords internal
fj10_subpop_ellip_gate_xml <- function(gate_def, indent) {
    lines <- c(
        sprintf(
            paste0(
                '%s    <gating:EllipsoidGate eventsInside="1"',
                ' annoOffsetX="0" annoOffsetY="0"',
                ' tint="#000000" isTinted="0"',
                ' lineWeight="Normal" userDefined="1"',
                ' gating:distance="%s" >'
            ),
            indent, format_gate_num(gate_def$distance)
        ),
        fj10_ellip_dims_xml(gate_def, indent),
        fj10_ellip_foci_xml_sub(gate_def$foci, indent),
        sprintf("%s      <gating:edge>", indent)
    )
    for (ep in gate_def$edge) {
        lines <- c(lines, fj10_vertex_xy_xml_sub(indent, ep))
    }
    lines <- c(
        lines,
        sprintf("%s      </gating:edge>", indent),
        sprintf("%s    </gating:EllipsoidGate>", indent)
    )

    lines
}

#' One gating:vertex for a subpop EllipsoidGate (%s formatting)
#'
#' @param indent XML indentation string
#' @param point Point with x/y values
#' @return Character vector of XML lines
#' @noRd
fj10_vertex_xy_xml_sub <- function(indent, point) {
    c(
        sprintf("%s        <gating:vertex>", indent),
        sprintf(
            paste0(
                "%s          <gating:coordinate",
                ' data-type:value="%s" />'
            ),
            indent, format_gate_num(point$x)
        ),
        sprintf(
            paste0(
                "%s          <gating:coordinate",
                ' data-type:value="%s" />'
            ),
            indent, format_gate_num(point$y)
        ),
        sprintf("%s        </gating:vertex>", indent)
    )
}

#' Foci block for a subpop EllipsoidGate (%s formatting)
#'
#' @param foci List with focus1 and focus2 entries (each x/y)
#' @param indent XML indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_ellip_foci_xml_sub <- function(foci, indent) {
    lines <- sprintf("%s      <gating:foci>", indent)
    for (focus in list(foci$focus1, foci$focus2)) {
        lines <- c(lines, fj10_vertex_xy_xml_sub(indent, focus))
    }
    c(lines, sprintf("%s      </gating:foci>", indent))
}

#' Generate Sample Subpopulations XML
#'
#' Recursively generates XML for sample-specific population hierarchy.
#'
#' @param gating_hierarchy GatingHierarchy object
#' @param gates List of gate data
#' @param populations List of population data (pre-filtered to this sample)
#' @param parent_path Parent population path (default "root")
#' @param indent Current indentation string for XML formatting
#' @param heat_map_param Channel name used for heatMapStatParameter attribute
#' @return Character vector of XML lines
#' @keywords internal
generate_sample_subpopulations_xml <- function(
    gating_hierarchy, gates, populations,
    parent_path = "root",
    indent = "        ",
    heat_map_param = ""
) {
    xml_lines <- character(0)

    # Children of the current population
    children_paths <- tryCatch(
        flowWorkspace::gs_pop_get_children(gating_hierarchy, parent_path,
            path = "auto"
        ),
        error = function(e) character(0)
    )

    for (child_path in children_paths) {
        pop_display_name <- basename(child_path)
        matching_pop <- fj10_find_matching_pop(populations, child_path)

        # ---- boolean-gate check
        #   ------------------------------------------------
        if (fj10_pop_is_boolean(matching_pop, gates)) {
            g <- gates$gates[[matching_pop$gate_id]]
            xml_lines <- c(
                xml_lines,
                generate_logical_node_xml(
                    gate       = g,
                    pop_name   = pop_display_name,
                    child_path = child_path,
                    indent     = indent,
                    gh         = gating_hierarchy,
                    gates      = gates
                )
            )
            next
        }

        xml_lines <- c(
            xml_lines,
            fj10_regular_pop_xml(
                gating_hierarchy, gates, populations, child_path,
                matching_pop, pop_display_name, indent, heat_map_param
            )
        )
    } # end for child_path

    xml_lines
}

#' One regular (non-boolean) population's full XML block
#'
#' @param gating_hierarchy GatingHierarchy object
#' @param gates List of gate data
#' @param populations List of population data
#' @param child_path Population path being processed
#' @param matching_pop Matching population record (may be NULL)
#' @param pop_display_name Basename of the population path
#' @param indent Current indentation string
#' @param heat_map_param Channel name for heatMapStatParameter
#' @return Character vector of XML lines
#' @noRd
fj10_regular_pop_xml <- function(gating_hierarchy, gates, populations,
                                  child_path, matching_pop,
                                  pop_display_name, indent, heat_map_param) {
    xml_lines <- c(
        sprintf(
            paste0(
                '%s<Population name="%s" annotation="" owningGroup=""',
                ' expanded="1" sortPriority="10" count="%d">'
            ),
            indent, xml_encode(pop_display_name),
            fj10_pop_count(gating_hierarchy, child_path, matching_pop)
        ),
        fj10_subpop_graph_xml(gating_hierarchy, child_path, heat_map_param)
    )

    # ---- Gate element
    #   ------------------------------------------------------
    if (!is.null(matching_pop) && !is.null(matching_pop$gate_id) &&
        matching_pop$gate_id %in% names(gates$gates)) {
        xml_lines <- c(
            xml_lines,
            fj10_subpop_gate_xml(matching_pop, gates, indent)
        )
    } # end gate block

    c(
        xml_lines,
        fj10_subpop_children_xml(
            gating_hierarchy, gates, populations, child_path,
            indent, heat_map_param
        ),
        sprintf("%s</Population>", indent)
    )
}

#' Event count for one population, falling back to the record's count
#'
#' @param gating_hierarchy GatingHierarchy object
#' @param child_path Population path
#' @param matching_pop Population record (may be NULL)
#' @return Integer event count
#' @noRd
fj10_pop_count <- function(gating_hierarchy, child_path, matching_pop) {
    tryCatch(
        flowWorkspace::gh_pop_get_count(gating_hierarchy, child_path),
        error = function(e) {
            if (!is.null(matching_pop)) matching_pop$count else 0L
        }
    )
}

#' Nested Subpopulations block for one population
#'
#' Emits <Subpopulations>...</Subpopulations> only when the population
#' has children.
#'
#' @param gating_hierarchy GatingHierarchy object
#' @param gates List of gate data
#' @param populations List of population data
#' @param child_path Population path being processed
#' @param indent Current indentation string
#' @param heat_map_param Channel name for heatMapStatParameter
#' @return Character vector of XML lines
#' @noRd
fj10_subpop_children_xml <- function(gating_hierarchy, gates, populations,
                                      child_path, indent, heat_map_param) {
    grandchildren <- tryCatch(
        flowWorkspace::gs_pop_get_children(gating_hierarchy, child_path,
            path = "auto"
        ),
        error = function(e) character(0)
    )

    if (length(grandchildren) == 0) {
        return(character(0))
    }

    c(
        sprintf("%s  <Subpopulations>", indent),
        generate_sample_subpopulations_xml(
            gating_hierarchy, gates, populations,
            parent_path = child_path,
            indent = paste0(indent, "    "),
            heat_map_param = heat_map_param
        ),
        sprintf("%s  </Subpopulations>", indent)
    )
}

#' Locate the population record matching a hierarchy path
#'
#' @param populations List of population data
#' @param child_path Population path from the GatingHierarchy
#' @return Matching population record or NULL
#' @noRd
fj10_find_matching_pop <- function(populations, child_path) {
    matching_pop <- NULL
    for (pop_id in names(populations)) {
        if (populations[[pop_id]]$name == child_path) {
            matching_pop <- populations[[pop_id]]
            break
        }
    }
    matching_pop
}

#' Whether a population record carries a boolean gate
#'
#' @param matching_pop Population record (may be NULL)
#' @param gates List of gate data
#' @return TRUE when the record's gate is a boolean gate
#' @noRd
fj10_pop_is_boolean <- function(matching_pop, gates) {
    if (is.null(matching_pop) || is.null(matching_pop$gate_id) ||
        !(matching_pop$gate_id %in% names(gates$gates))) {
        return(FALSE)
    }
    g <- gates$gates[[matching_pop$gate_id]]
    !is.null(g$definition) && g$definition$type == "boolean"
}

#' Emit the Gate element for one group-level population
#'
#' Renders the <Gate> element with the population's gate definition,
#' dispatching on gate type.
#'
#' @param gate Gate record from the gates list
#' @param indent Current indentation string
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_gate_xml <- function(gate, indent) {
    lines <- c(
        sprintf(
            '%s  <Gate gating:id="%s">', indent,
            xml_encode(gate$id)
        )
    )

    # Add gate definition based on type with proper attributes
    gate_def <- gate$definition

    if (!is.null(gate_def)) {
        if (gate_def$type == "rectangle") {
            lines <- c(lines, fj10_group_rect_gate_xml(gate_def, indent))
        } else if (gate_def$type == "polygon") {
            lines <- c(lines, fj10_group_poly_gate_xml(gate_def, indent))
        } else if (gate_def$type == "ellipsoid") {
            lines <- c(lines, fj10_group_ellip_gate_xml(gate_def, indent))
        }
    }

    lines <- c(lines, sprintf("%s  </Gate>", indent))

    lines
}

#' Emit a Gating-ML RectangleGate element (group variant)
#'
#' Group-level rectangles use Hairline line weight and %f coordinate
#' formatting, matching the group-node shape FlowJo emits.
#'
#' @param gate_def Gate definition with dimensions
#' @param indent Current indentation string
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_rect_gate_xml <- function(gate_def, indent) {
    lines <- c(
        sprintf(
            paste0(
                "%s    <gating:RectangleGate",
                ' eventsInside="1" annoOffsetX="0"',
                ' annoOffsetY="0" tint="#000000"',
                ' isTinted="0" lineWeight="Hairline"',
                ' userDefined="1">'
            ),
            indent
        )
    )

    # yRatio is a display hint for histogram-style (1-D)
    #   gates. It should only
    # be emitted when the rectangle gate has a single
    #   dimension.
    is_1d_rect <- length(gate_def$dimensions) == 1L
    lines <- c(
        lines,
        unlist(lapply(gate_def$dimensions, function(dim) {
            fj10_rect_dimension_xml(indent, dim, is_1d_rect)
        }))
    )

    c(lines, sprintf("%s    </gating:RectangleGate>", indent))
}

#' Emit one gating:dimension block of a RectangleGate
#'
#' @param indent Current indentation string
#' @param dim Dimension entry with min/max/parameter
#' @param is_1d Whether the gate is one-dimensional (adds yRatio)
#' @return Character vector of XML lines
#' @noRd
fj10_rect_dimension_xml <- function(indent, dim, is_1d) {
    min_attr <- if (is_1d) {
        sprintf(' gating:max="%f" yRatio="0.5">', dim$max)
    } else {
        sprintf(' gating:max="%f">', dim$max)
    }
    c(
        sprintf(
            paste0(
                "%s      <gating:dimension",
                ' gating:min="%f"',
                "%s"
            ),
            indent, dim$min, min_attr
        ),
        sprintf(
            paste0(
                "%s       ",
                " <data-type:fcs-dimension",
                ' data-type:name="%s"/>'
            ),
            indent, xml_encode(dim$parameter)
        ),
        sprintf(
            "%s      </gating:dimension>",
            indent
        )
    )
}

#' Emit a Gating-ML PolygonGate element (group variant)
#'
#' @param gate_def Gate definition with dimensions and vertices
#' @param indent Current indentation string
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_poly_gate_xml <- function(gate_def, indent) {
    lines <- c(
        sprintf(
            paste0(
                "%s    <gating:PolygonGate",
                ' eventsInside="1" annoOffsetX="0"',
                ' annoOffsetY="0" tint="#000000"',
                ' isTinted="0" lineWeight="Hairline"',
                ' userDefined="1">'
            ),
            indent
        )
    )

    lines <- c(lines, fj10_group_poly_dims_xml(gate_def$dimensions, indent))
    lines <- c(lines, fj10_group_poly_vertices_xml(gate_def$vertices, indent))

    c(lines, sprintf("%s    </gating:PolygonGate>", indent))
}

#' Dimension block for a group PolygonGate
#'
#' @param dimensions Gate definition dimensions
#' @param indent XML indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_group_poly_dims_xml <- function(dimensions, indent) {
    lines <- character(0)
    for (dim in dimensions) {
        lines <- c(
            lines,
            sprintf("%s      <gating:dimension>", indent),
            sprintf(
                paste0(
                    "%s        <data-type:fcs-dimension",
                    ' data-type:name="%s"/>'
                ),
                indent, xml_encode(dim$parameter)
            ),
            sprintf("%s      </gating:dimension>", indent)
        )
    }
    lines
}

#' Vertices block for a group PolygonGate
#'
#' @param vertices List of vertices with x/y values
#' @param indent XML indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_group_poly_vertices_xml <- function(vertices, indent) {
    lines <- character(0)
    for (vertex in vertices) {
        lines <- c(
            lines,
            sprintf("%s      <gating:vertex>", indent),
            sprintf(
                paste0(
                    "%s        <gating:coordinate",
                    ' data-type:value="%f"/>'
                ),
                indent, vertex$x
            ),
            sprintf(
                paste0(
                    "%s        <gating:coordinate",
                    ' data-type:value="%f"/>'
                ),
                indent, vertex$y
            ),
            sprintf("%s      </gating:vertex>", indent)
        )
    }
    lines
}

#' Emit a Gating-ML EllipsoidGate element (group variant)
#'
#' @param gate_def Gate definition with x/y parameters, foci, and edge points
#' @param indent Current indentation string
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_ellip_gate_xml <- function(gate_def, indent) {
    lines <- c(
        sprintf(
            paste0(
                "%s    <gating:EllipsoidGate",
                ' eventsInside="1" annoOffsetX="0"',
                ' annoOffsetY="0" tint="#000000"',
                ' isTinted="0" lineWeight="Normal"',
                ' userDefined="1" gating:distance="%f">'
            ),
            indent, gate_def$distance
        )
    )

    # Add dimensions
    lines <- c(lines, fj10_ellip_dims_xml(gate_def, indent))

    # Add foci
    lines <- c(lines, fj10_ellip_foci_xml(gate_def$foci, indent))

    # Add edge points
    lines <- c(lines, fj10_ellip_edge_xml(gate_def$edge, indent))

    c(lines, sprintf("%s    </gating:EllipsoidGate>", indent))
}

#' Dimension block for an EllipsoidGate
#'
#' @param gate_def Ellipsoid gate definition
#' @param indent XML indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_ellip_dims_xml <- function(gate_def, indent) {
    unlist(lapply(c(gate_def$x_param, gate_def$y_param), function(param) {
        c(
            sprintf("%s      <gating:dimension>", indent),
            sprintf(
                paste0(
                    "%s        <data-type:fcs-dimension",
                    ' data-type:name="%s" />'
                ),
                indent, xml_encode(param)
            ),
            sprintf("%s      </gating:dimension>", indent)
        )
    }))
}

#' One gating:vertex with x/y coordinates
#'
#' @param indent XML indentation string
#' @param x X coordinate value
#' @param y Y coordinate value
#' @return Character vector of XML lines
#' @noRd
fj10_vertex_xy_xml <- function(indent, x, y) {
    c(
        sprintf("%s        <gating:vertex>", indent),
        sprintf(
            paste0(
                "%s          <gating:coordinate",
                ' data-type:value="%f" />'
            ),
            indent, x
        ),
        sprintf(
            paste0(
                "%s          <gating:coordinate",
                ' data-type:value="%f" />'
            ),
            indent, y
        ),
        sprintf("%s        </gating:vertex>", indent)
    )
}

#' Foci block for an EllipsoidGate
#'
#' @param foci List with focus1 and focus2 entries (each x/y)
#' @param indent XML indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_ellip_foci_xml <- function(foci, indent) {
    lines <- sprintf("%s      <gating:foci>", indent)
    for (focus in list(foci$focus1, foci$focus2)) {
        lines <- c(
            lines,
            fj10_vertex_xy_xml(indent, focus$x, focus$y)
        )
    }
    c(lines, sprintf("%s      </gating:foci>", indent))
}

#' Edge block for an EllipsoidGate
#'
#' @param edge List of edge points (each x/y)
#' @param indent XML indentation string
#' @return Character vector of XML lines
#' @noRd
fj10_ellip_edge_xml <- function(edge, indent) {
    lines <- sprintf("%s      <gating:edge>", indent)
    for (edge_point in edge) {
        lines <- c(
            lines,
            fj10_vertex_xy_xml(indent, edge_point$x, edge_point$y)
        )
    }
    c(lines, sprintf("%s      </gating:edge>", indent))
}

#' Collect group-level children of a parent path
#'
#' @param populations List of population data
#' @param parent_path Parent population path
#' @return Named list of child populations
#' @keywords internal
fj10_group_children_of <- function(populations, parent_path) {
    child_populations <- list()
    for (pop_id in names(populations)) {
        pop <- populations[[pop_id]]
        if (pop$parent_path == parent_path) {
            child_populations[[pop_id]] <- pop
        }
    }
    child_populations
}

#' Emit the XML for one group-node child population
#'
#' Dispatches to a logical node for boolean gates, or to the regular
#' Population element otherwise. Returns NULL for the Ungated
#' placeholder so the caller skips it.
#'
#' @param population Population record
#' @param gates List of gate data
#' @param parent_path Parent population path
#' @param indent Current indentation string
#' @param visited_paths Character vector of visited paths (cycle detection)
#' @param gh GatingHierarchy object (for boolean gate processing)
#' @return Character vector of XML lines, or NULL when nothing is emitted
#' @keywords internal
fj10_group_child_xml <- function(population, gates, parent_path, indent,
                                visited_paths, gh) {
    if (population$name == "Ungated") {
        return(NULL)
    }

    boolean_xml <- fj10_group_boolean_gate_xml(population, gates, indent, gh)
    if (!is.null(boolean_xml)) {
        return(boolean_xml)
    }

    fj10_group_population_xml(
        population, gates, parent_path, indent, visited_paths, gh
    )
}

#' Emit a boolean-gate logical node for a group population
#'
#' Returns the logical node XML when the population's gate is a boolean
#' gate, or NULL otherwise. Logical nodes have no recursive
#' subpopulations here.
#'
#' @param population Population record
#' @param gates List of gate data
#' @param indent Current indentation string
#' @param gh GatingHierarchy object (for boolean gate processing)
#' @return Character vector of XML lines, or NULL when not a boolean gate
#' @keywords internal
fj10_group_boolean_gate_xml <- function(population, gates, indent, gh) {
    if (is.null(population$gate_id) ||
        !(population$gate_id %in% names(gates$gates))) {
        return(NULL)
    }
    gate <- gates$gates[[population$gate_id]]
    if (is.null(gate$definition) || gate$definition$type != "boolean") {
        return(NULL)
    }

    # Generate logical node instead of Population
    # Use population$name as the path, and basename for display
    pop_display_name <- basename(population$name)

    generate_logical_node_xml(
        gate = gate,
        pop_name = pop_display_name,
        child_path = population$name,
        indent = indent,
        gh = gh,
        gates = gates
    )
}

#' Render one group-node population element
#'
#' Emits the <Population> element, its Gate, the recursive Subpopulations
#' block, and the closing tag.
#'
#' @param population Population record
#' @param gates List of gate data
#' @param parent_path Parent population path
#' @param indent Current indentation string
#' @param visited_paths Character vector of visited paths (cycle detection)
#' @param gh GatingHierarchy object (for boolean gate processing)
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_population_xml <- function(population, gates, parent_path, indent,
                                        visited_paths, gh) {
    # Add population element with correct attributes
    lines <- c(
        sprintf(
            paste0(
                '%s<Population name="%s" annotation=""',
                ' owningGroup="All Samples" expanded="1"',
                ' sortPriority="10" count="%d">'
            ),
            indent, xml_encode(basename(population$name)),
            population$count
        )
    )

    # Add gate if exists
    if (!is.null(population$gate_id) &&
        population$gate_id %in% names(gates$gates)) {
        gate <- gates$gates[[population$gate_id]]
        lines <- c(lines, fj10_group_gate_xml(gate, indent))
    }

    lines <- c(
        lines,
        fj10_group_subpop_recursion_xml(
            population, gates, parent_path, indent, visited_paths, gh
        ),
        # Close population element
        sprintf("%s</Population>", indent)
    )

    lines
}

#' Render the recursive Subpopulations block for a group population
#'
#' Opens <Subpopulations>, recurses into
#' generate_group_subpopulations_xml with cycle detection (self-parent
#' and previously-visited paths are skipped with a warning), and closes
#' the block.
#'
#' @param population Population record
#' @param gates List of gate data
#' @param parent_path Parent population path
#' @param indent Current indentation string
#' @param visited_paths Character vector of visited paths (cycle detection)
#' @param gh GatingHierarchy object (for boolean gate processing)
#' @return Character vector of XML lines
#' @keywords internal
fj10_group_subpop_recursion_xml <- function(population, gates, parent_path,
                                            indent, visited_paths, gh) {
    lines <- sprintf("%s  <Subpopulations>", indent)

    # Prevent a population from being its own parent (cycle detection)
    if (population$name == parent_path) {
        warning(
            "Population '", population$name,
            "' cannot be its own parent. Skipping recursion."
        )
    } else {
        # Check if we've already visited this population
        if (population$name %in% visited_paths) {
            warning(
                "Cycle detected - population '",
                population$name,
                "' already visited. Skipping recursion."
            )
        } else {
            new_visited_paths <- unique(c(
                visited_paths,
                population$name
            ))
            subpop_xml <- generate_group_subpopulations_xml(
                populations = populations,
                gates = gates,
                parent_path = population$name,
                indent = paste0(indent, "    "),
                visited_paths = new_visited_paths,
                gh = gh # Pass gh down for boolean gate processing
            )
            lines <- c(lines, subpop_xml)
        }
    }
    lines <- c(lines, sprintf("%s  </Subpopulations>", indent))

    lines
}

#' Generate Group Node Subpopulations XML
#'
#' Recursively generates XML for group node population hierarchy
#'
#' @param populations List of population data
#' @param gates List of gate data
#' @param parent_path Parent population path (default "root")
#' @param indent Current indentation level for XML formatting
#' @param visited_paths Character vector to track visited paths (for cycle
#  detection)
#' @param gh Optional GatingHierarchy object (for boolean gate processing)
#' @return Character vector of XML lines
#' @keywords internal
#' @importFrom magrittr %>%
generate_group_subpopulations_xml <- function(populations,
                                                gates, parent_path = "root",
                                                indent = "        ",
                                        visited_paths = NULL,
                                                gh = NULL) {
    # Safety check to prevent infinite recursion
    if (is.null(visited_paths)) {
        visited_paths <- character(0)
    }

    # Check if we've already visited this parent_path (cycle detection)
    if (parent_path %in% visited_paths) {
        # message("WARNING: Cycle detected in population hierarchy at
        #   parent_path='", parent_path, "'\n")
        return(character(0))
    }

    visited_paths <- c(visited_paths, parent_path)
    parent_path <- trimws(parent_path)

    xml_lines <- character(0)

    # Find all populations that have the current parent path
    child_populations <- fj10_group_children_of(populations, parent_path)

    # Process each child population
    for (pop_id in names(child_populations)) {
        population <- child_populations[[pop_id]]

        xml_lines <- c(
            xml_lines,
            fj10_group_child_xml(
                population, gates, parent_path, indent, visited_paths, gh
            )
        )
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

#' Format a gate coordinate or dimension value for XML output
#'
#' Uses 15 significant figures and strips trailing zeros, matching the
#' precision FlowJo stores gate boundaries in.
#'
#' @param x Numeric value.
#' @return Character string suitable for embedding in an XML attribute.
#' @keywords internal
format_gate_num <- function(x) {
    if (is.null(x) || is.na(x)) {
        return("0")
    }
    if (is.infinite(x) && x > 0) {
        return("262144")
    }
    if (is.infinite(x) && x <= 0) {
        return("0")
    }
    sprintf("%.15g", x)
}

#' Get Display Range for Parameter
#'
#' Determines the min/max range for a parameter that will be used in the XML
#' @keywords internal
get_display_range <- function(gh, param_name) {
    tryCatch(
        {
            # Extract flowFrame from GatingHierarchy if needed
            if (inherits(gh, "GatingHierarchy")) {
                fr <- flowWorkspace::gh_pop_get_data(gh, "root")
            } else {
                fr <- gh
            }

            kw <- flowCore::keyword(fr)
            range_key <- fj10_kw_range_key(kw, param_name)
            if (is.null(range_key)) {
                # Parameter not found or range keyword missing
                return(fj10_data_span_range(fr, param_name))
            }

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

            c(min_val, max_val) # No explicit return needed
        },
        error = function(e) {
            c(0, 262144)
        }
    )
}

#' Resolve the $PnR range keyword for a parameter, or NULL
#'
#' @param kw Named keyword list from a flowFrame
#' @param param_name Channel name to look up
#' @return Keyword name like "$P6R", or NULL when unresolvable
#' @noRd
fj10_kw_range_key <- function(kw, param_name) {
    # Find parameter number by matching $PnN to param_name
    n_pattern <- paste0("^\\$P[0-9]+N$")
    n_keys <- grep(n_pattern, names(kw), value = TRUE)
    n_values <- vapply(
        n_keys, function(k) as.character(kw[[k]]),
        character(1)
    )
    param_match <- which(n_values == param_name)

    if (length(param_match) == 0) {
        return(NULL)
    }

    # Extract number from $P6N -> 6
    param_num <- gsub("\\$|P|N", "", names(param_match)[1])
    range_key <- paste0("$P", param_num, "R")

    if (is.null(kw[[range_key]])) {
        return(NULL)
    }
    range_key
}

#' Data-derived range with 10% padding on both sides
#'
#' @param fr flowFrame
#' @param param_name Channel name
#' @return Numeric vector c(min, max)
#' @noRd
fj10_data_span_range <- function(fr, param_name) {
    data_vals <- flowCore::exprs(fr)[, param_name]
    min_val <- min(data_vals, na.rm = TRUE)
    max_val <- max(data_vals, na.rm = TRUE)

    range_span <- max_val - min_val
    c(min_val - 0.1 * range_span, max_val + 0.1 * range_span)
}

#' Emit a Single Channel Transform as XML
#'
#' @param type Transform type: "biex", "log", "fasinh", or "linear".
#' @param channel Parameter name for the transform.
#' @param transform_obj The transform function/object.
#' @param atr_tr Attributes list from the transform object.
#' @param data_range Numeric vector of length 2 (min, max) for linear
#  transforms.
#' @param indent Indentation string.
#' @return Character vector of XML lines.
#' @keywords internal
emit_transform_xml <- function(type, channel, transform_obj, atr_tr,
                                data_range, indent = "        ") {
    # Normalize FlowJo transform type names
    type <- tolower(type)
    if (type %in% c("biexp", "biexponential")) type <- "biex"
    if (type %in% c("logtgml2", "flowjo_log")) type <- "log"
    param_str <- fj10_transform_attr_string(
        type, transform_obj, atr_tr, data_range
    )
    if (is.null(param_str)) {
        warning("not implemented: ", type)
        return(character(0))
    }

    sprintf(
        paste0(
            "%s<transforms:%s %s >\n%s  <data-type:parameter",
            ' data-type:name="%s"/>\n%s</transforms:%s >'
        ),
        indent, xml_encode(type), xml_encode(param_str), indent,
        xml_encode(channel), indent, xml_encode(type)
    )
}

#' Build the transforms:* attribute string for one transform type
#'
#' @param type Lowercased FlowJo transform type ("biex", "log", "fasinh",
#'   "linear", or unknown)
#' @param transform_obj The transform function object
#' @param atr_tr Transform attributes (with $parameters)
#' @param data_range Numeric c(min, max) for linear transforms
#' @return Attribute string, or NULL when the type is not implemented
#' @noRd
fj10_transform_attr_string <- function(type, transform_obj, atr_tr,
                                        data_range) {
    fn_env <- environment(transform_obj)
    switch(type,
        "biex" = fj10_biex_attr_string(atr_tr),
        "log" = ,
        "logtGml2" = ,
        "flowJo_log" = fj10_log_attr_string(fn_env),
        "fasinh" = fj10_fasinh_attr_string(fn_env),
        "linear" = sprintf(
            paste0(
                "transforms:minRange=\"%.1f\" ",
                "transforms:maxRange=\"%.1f\" gain=\"1\""
            ),
            data_range[1], data_range[2]
        ),
        {
            NULL
        }
    )
}

#' Build the transforms:* attribute string for a biexponential transform
#'
#' @param atr_tr Transform entry holding parameters
#' @return Attribute string for the transform element
#' @noRd
fj10_biex_attr_string <- function(atr_tr) {
    sprintf(
        paste0(
            "transforms:length=\"%d\" ",
            "transforms:maxRange=\"%d\" ",
            "transforms:neg=\"%d\" ",
            "transforms:width=\"%d\" ",
            "transforms:pos=\"%.8g\""
        ),
        atr_tr$parameters$channelRange %>% as.integer(),
        atr_tr$parameters$maxValue %>% as.integer(),
        atr_tr$parameters$neg %>% as.integer(),
        atr_tr$parameters$widthBasis %>% as.integer(),
        atr_tr$parameters$pos
    )
}

#' Build the transforms:* attribute string for a log transform
#'
#' @param fn_env Environment of the transform function
#' @return Attribute string for the transform element
#' @noRd
fj10_log_attr_string <- function(fn_env) {
    sprintf(
        "transforms:offset=\"%d\" transforms:decades=\"%d\"",
        fn_env$m %||% fn_env$offset %||% 1 %>% as.integer(),
        fn_env$n %||% fn_env$decade %||% 6.0 %>% as.integer()
    )
}

#' Build the transforms:* attribute string for a fasinh transform
#'
#' @param fn_env Environment of the transform function
#' @return Attribute string for the transform element
#' @noRd
fj10_fasinh_attr_string <- function(fn_env) {
    sprintf(
        paste0(
            "transforms:length=\"%d\" ",
            "transforms:maxRange=\"262144\" ",
            "transforms:T=\"%d\" ",
            "transforms:A=\"%.0f\" ",
            "transforms:M=\"%.0f\"  ",
            "transforms:W=\"-%.0f\""
        ),
        fn_env$length %>% as.integer(),
        fn_env$t,
        fn_env$a,
        fn_env$m,
        fn_env$t
    )
}

#' Determine Cytometer Attributes from FCS Header
#'
#' @param fcs_keywords Named list of FCS header keywords.
#' @return Named list of Cytometer XML attributes.
#' @keywords internal
derive_cytometer_attrs <- function(fcs_keywords) {
    attrs <- list(
        name = "GENERIC",
        cyt = "",
        useFCS3 = "1",
        extraNegs = "0",
        widthBasis = "-10",
        linMin = "0",
        logMin = "1",
        linMax = "10000",
        logMax = "10000",
        linearRescale = "1",
        logRescale = "1",
        linFromKW = "1",
        logFromKW = "1",
        useGain = "0",
        useTransform = "0",
        transformType = "LOG",
        manufacturer = "",
        serialnumber = "",
        homepage = paste0(
            "workspaces-and-samples/flowjo-and-your-cytometer/",
            "ws-instrumentation/"
        ),
        icon = "generic.png"
    )

    if (is.null(fcs_keywords) || length(fcs_keywords) == 0) {
        return(attrs)
    }

    cyt_val <- tryCatch(fcs_keywords[["$CYT"]], error = function(e) NULL) %||%
        tryCatch(fcs_keywords[["CREATOR"]], error = function(e) NULL) %||% ""
    if (!is.null(cyt_val) && nzchar(cyt_val)) {
        attrs$cyt <- as.character(cyt_val)
        attrs <- fj10_apply_diva_overrides(attrs)
    }

    attrs
}

#' Apply BD FACSDiva cytometer attribute overrides
#'
#' FlowJo convention: BD FACSDiva -> DIVA cytometer name.
#'
#' @param attrs Cytometer attribute list
#' @return Updated attribute list
#' @noRd
fj10_apply_diva_overrides <- function(attrs) {
    if (!grepl("Diva", attrs$cyt, ignore.case = TRUE)) {
        return(attrs)
    }
    attrs$name <- "DIVA"
    attrs$homepage <- paste0(
        "workspaces-and-samples/flowjo-and-your-cytometer/",
        "ws-cytometer-bd/"
    )
    attrs$icon <- "bd.PNG"
    attrs$useTransform <- "1"
    attrs$transformType <- "BIEX"
    attrs$linMin <- "0"
    attrs$logMin <- "3"
    attrs$linMax <- "262144"
    attrs$logMax <- "262144"
    attrs$widthBasis <- "-100"
    attrs
}

#' Write FCS Files from a GatingSet to a Directory
#'
#' Copies (or re-exports) the FCS files backing a GatingSet to
#  \code{target_dir}.
#' When the original file is accessible on disk it is copied verbatim so that
#' all acquisition keywords are preserved exactly.  If the original cannot be
#' found, the flowFrame is extracted from the GatingSet with inverse transforms
#' applied and written as a new FCS file.
#'
#' @param gating_set GatingSet object.
#' @param target_dir Destination directory (must already exist).
#' @param overwrite Logical. \code{FALSE} (default) stops if any destination
#'   file already exists; \code{TRUE} replaces existing files after a warning.
#' @return Invisible character vector of file paths written successfully.
#' @keywords internal
write_fcs_files_to_dir <- function(gating_set, target_dir,
                                    overwrite = FALSE) {
    sample_names <- flowWorkspace::sampleNames(gating_set)

    fcs_info <- lapply(sample_names, function(sn) {
        fj10_fcs_entry_info(gating_set, target_dir, sn)
    })

    fj10_check_fcs_conflicts(fcs_info, target_dir, overwrite)

    written <- vapply(seq_along(fcs_info), function(i) {
        info <- fcs_info[[i]]
        tryCatch(
            {
                fj10_write_one_fcs(gating_set, info)
                info$dest
            },
            error = function(e) {
                warning(
                    "Failed to write FCS for sample '",
                    info$sample_name, "': ", e$message
                )
                NA_character_
            }
        )
    }, character(1))
    written <- written[!is.na(written)]

    message(
        "Wrote ", length(written), " / ", length(fcs_info),
        " FCS file(s) to: ", target_dir
    )
    invisible(written)
}

#' Flag (and stop on, unless overwriting) destination FCS conflicts
#'
#' @param fcs_info Path info list from fj10_fcs_entry_info
#' @param target_dir Destination directory (used in messages)
#' @param overwrite Logical; when FALSE existing files stop the export
#' @return Invisible NULL
#' @noRd
fj10_check_fcs_conflicts <- function(fcs_info, target_dir, overwrite) {
    dest_paths <- vapply(fcs_info, `[[`, character(1), "dest")
    already_exist <- dest_paths[
        file.exists(dest_paths) &
            !mapply(
                function(orig, dest) {
                    !is.na(orig) && file.exists(orig) &&
                        normalizePath(orig) == normalizePath(dest)
                }, vapply(fcs_info, `[[`, character(1), "orig_path"),
                dest_paths
            )
    ]

    if (length(already_exist) > 0L && !overwrite) {
        stop(
            length(already_exist), " FCS file(s) already exist in '",
            target_dir, "'.\n",
            "  Set overwrite = TRUE to replace them, ",
            "or choose a different fcs_root.\n",
            "  Conflicting file(s): ", paste(basename(already_exist),
                collapse = ", "
            )
        )
    }
    if (length(already_exist) > 0L) {
        warning(
            length(already_exist),
            " existing FCS file(s) will be overwritten in: ",
            target_dir
        )
    }
    invisible(NULL)
}

#' Collect path information for one sample's FCS file
#'
#' @param gating_set GatingSet object
#' @param target_dir Destination directory
#' @param sn Sample name
#' @return List with sample_name, orig_path, orig_basename, and dest
#' @noRd
fj10_fcs_entry_info <- function(gating_set, target_dir, sn) {
    gh <- gating_set[[sn]]
    kw <- tryCatch(flowCore::keyword(gh), error = function(e) list())

    # $FIL is the authoritative FCS filename keyword -- use it for the
    # destination basename, matching what extract_samples_from_gatingset_v10
    # does. Fall back to FILENAME (full path) and finally to the sample
    #   name.
    fil_kw <- kw[["$FIL"]] %||% NA_character_
    filename_kw <- kw[["FILENAME"]] %||% NA_character_

    orig_basename <- if (!is.na(fil_kw) && nzchar(fil_kw)) {
        basename(fil_kw)
    } else if (!is.na(filename_kw) && nzchar(filename_kw)) {
        basename(filename_kw)
    } else {
        paste0(sn, ".fcs") # sn is already "foo.fcs" from sampleNames
    }

    # The original file path (for verbatim copy, if it exists)
    orig_path <- if (!is.na(filename_kw) && nzchar(filename_kw)) {
        filename_kw
    } else {
        NA_character_
    }

    list(
        sample_name   = sn,
        orig_path     = orig_path,
        orig_basename = orig_basename,
        dest          = file.path(target_dir, orig_basename)
    )
}

#' Copy or re-export one sample's FCS file
#'
#' Verbatim-copies the original file when it exists on disk; otherwise
#' extracts the root flowFrame with inverse transforms applied and writes
#' a new FCS file.
#'
#' @param gating_set GatingSet object
#' @param info Path info list from fj10_fcs_entry_info
#' @return Invisible NULL; emits messages/warnings
#' @noRd
fj10_write_one_fcs <- function(gating_set, info) {
    if (!is.na(info$orig_path) && file.exists(info$orig_path)) {
        # Skip verbatim copy when the file is already in the right
        #   place
        if (normalizePath(info$orig_path) !=
            normalizePath(info$dest)) {
            file.copy(info$orig_path, info$dest, overwrite = TRUE)
            message("  Copied  FCS: ", info$orig_basename)
        } else {
            message(
                "  Skipped FCS (already in place): ",
                info$orig_basename
            )
        }
    } else {
        fj10_export_frame_as_fcs(gating_set, info)
    }
}

#' Extract the root flowFrame with inverse transforms and write it as FCS
#'
#' @param gating_set GatingSet object
#' @param info Path info list from fj10_fcs_entry_info
#' @return Invisible NULL
#' @noRd
fj10_export_frame_as_fcs <- function(gating_set, info) {
    gh <- gating_set[[info$sample_name]]
    fr <- flowWorkspace::gh_pop_get_data(gh, "root")
    inv_trans <- flowWorkspace::gh_get_transformations(gh,
        inverse = TRUE
    )
    if (length(inv_trans) > 0L) {
        valid_channels <- intersect(
            names(inv_trans),
            flowCore::colnames(fr)
        )
        if (length(valid_channels) > 0L) {
            tl <- flowCore::transformList(
                valid_channels,
                inv_trans[valid_channels]
            )
            fr <- flowCore::transform(fr, tl)
        }
    }
    flowCore::write.FCS(fr, filename = info$dest)
    message("  Exported FCS: ", info$orig_basename)
}
