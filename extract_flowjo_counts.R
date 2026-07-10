#!/usr/bin/env Rscript

# extract_flowjo_counts.R
# Extract population event counts from FlowJo v11 .flowjo files in
# flowjo_export_tests using CyFj11 and flowWorkspace.
#
# For each .flowjo file found under flowjo_export_tests/<testNN>/, the script:
#   1. Parses the workspace with CyFj11::read_flowjo11_workspace()
#   2. Converts it to a per-sample GatingSet list with fj11_to_gatingset()
#   3. Collects population paths and event counts per sample
#   4. Writes a single TSV with counts for all files/populations/samples
#
# Run from the repo root:
#   Rscript extract_flowjo_counts.R
# or inside R:
#   source("extract_flowjo_counts.R")

suppressPackageStartupMessages({
  library(CyFj11)
  library(flowWorkspace)
})

root_dir <- normalizePath("flowjo_export_tests", mustWork = TRUE)
out_file <- "flowjo_export_tests_counts.2.tsv"

# Locate all .flowjo files -----------------------------------------------------
flowjo_files <- list.files(
  path       = root_dir,
  pattern    = "\\.flowjo$",
  recursive  = TRUE,
  full.names = TRUE
)

if (length(flowjo_files) == 0) {
  stop("No .flowjo files found under ", root_dir)
}

message("Found ", length(flowjo_files), " .flowjo file(s)")

# Helper to collect counts from one GatingSet ----------------------------------
get_counts_from_gs <- function(gs, test_name, flowjo_path) {
  samples <- sampleNames(gs)
  rows <- list()

  for (sample_name in samples) {
    gh <- gs[[sample_name]]
    pop_paths <- tryCatch(
      gs_get_pop_paths(gh, path = "auto"),
      error = function(e) character(0)
    )

    for (pop_path in pop_paths) {
      count <- tryCatch(
        flowWorkspace::gh_pop_get_count(gh, pop_path),
        error = function(e) NA_integer_
      )

      rows[[length(rows) + 1]] <- data.frame(
        test        = test_name,
        flowjo_file = basename(flowjo_path),
        sample      = sample_name,
        population  = pop_path,
        count       = as.integer(count),
        stringsAsFactors = FALSE
      )
    }
  }

  do.call(rbind, rows)
}
devtools::load_all()
set_verbose(T)
fj_path = flowjo_files[7]
# Process every .flowjo file ---------------------------------------------------
all_counts <- lapply(flowjo_files, function(fj_path) {
  test_name <- basename(dirname(fj_path))
  message("\n--- Processing: ", test_name, " -> ", basename(fj_path))

  # Parse workspace
  ws <- tryCatch(
    read_flowjo11_workspace(fj_path),
    error = function(e) {
      warning("Failed to parse ", fj_path, ": ", e$message)
      return(NULL)
    }
  )
  if (is.null(ws)) return(NULL)

  # Determine search path for FCS files (same directory as the .flowjo file)
  fcs_search_path <- dirname(fj_path)

  # Convert to GatingSet list.  We request execution so counts are computed.
  gs_list <- tryCatch(
    fj11_to_gatingset(
      fj11_workspace = ws,
      group_name         = 1,
      path               = fcs_search_path,
      execute            = TRUE,
      stop_on_multiple   = FALSE,
      include_empty_tree = FALSE
    ),
    error = function(e) {
      warning("Failed to convert ", fj_path, " to GatingSet: ", e$message)
      return(NULL)
    }
  )
  if (is.null(gs_list) || length(gs_list) == 0) return(NULL)

  # Merge per-sample GatingSets into a single GatingSet
  gs <- tryCatch(
    flowWorkspace::merge_list_to_gs(gs_list),
    error = function(e) {
      warning("Failed to merge GatingSet list for ", fj_path, ": ", e$message)
      return(NULL)
    }
  )
  if (is.null(gs)) return(NULL)

  get_counts_from_gs(gs, test_name, fj_path)
})

# Combine and write output -----------------------------------------------------
all_counts <- do.call(rbind, all_counts)
all_counts
if (is.null(all_counts) || nrow(all_counts) == 0) {
  stop("No counts extracted.")
}

rownames(all_counts) <- NULL
write.table(
  all_counts,
  file      = out_file,
  sep       = "\t",
  row.names = FALSE,
  quote     = FALSE
)

message("\nWrote ", nrow(all_counts), " rows to ", normalizePath(out_file))
