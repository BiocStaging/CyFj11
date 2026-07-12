

# autoplot(gh, c("NK1_1+", "NK1_1-"), bins = 264) +
#   ggcyto_par_set(limits = list(x = c(0, 12000), y = c(0, 250000)))


ff = read.FCS("flowjo_export_tests/test14/68983.fcs")
kw <- keyword(ff)
kw[grep("SPILL|COMP", names(kw), ignore.case = TRUE)]

# Get current matrix
spill_orig <- keyword(ff, "SPILL")[[1]]
cat("Original spillover matrix:\n")
print(spill_orig)

spill_new = spill_orig *100
keyword(ff)[["SPILL"]]      <- spill_new

write.FCS(ff, "flowjo_export_tests/test14/68983_modified.fcs")

ff_check <- read.FCS("flowjo_export_tests/test14/68983_modified.fcs",
                     transformation = FALSE)

spill_check <- keyword(ff_check, "SPILL")[[1]]
cat("Spillover in resaved file:\n")
print(spill_check)

fj_path = "flowjo_export_tests/test14/test14.compensation.flowjo"
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


autoplot(gs[[1]], bins = 264) +
  ggcyto_par_set(limits = "data")


