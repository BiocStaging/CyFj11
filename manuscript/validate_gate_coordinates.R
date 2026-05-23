#!/usr/bin/env Rscript
# validate_gate_coordinates.R
#
# Compares gate coordinates in exported WSP files to the original gate
# definitions from roundtrip_experiment.Rmd.  Reports deviation as % of axis
# range so it can be put directly into manuscript Table 3.
#
# Strategy:
#  - Linear gates: XML coordinates (data space) are compared directly to the
#    original flowCore gate coordinates (also in data space).
#  - Transformed gates: XML coordinates (data space) are re-transformed with
#    the forward transform function and compared to the original gate
#    coordinates in transformed space.  This avoids implementing inverse
#    transforms and matches the validation that matters: does the exported
#    gate represent the same cells?
#
# Ellipsoid gates (tests 05, 12, 13) use a fundamentally different XML
# parameterization (FlowJo foci + distance in display space vs. flowCore
# covariance matrix in data space) and are excluded from coordinate
# comparison.  Their fidelity is assessed via population count concordance.
#
# Boolean gates (tests 10-13) have no coordinates of their own; their
# operand gates are covered by other tests.
#
# Usage:
#   Rscript manuscript/validate_gate_coordinates.R
#   # or, interactively:
#   source("manuscript/validate_gate_coordinates.R")
#
# Output:
#   Printed summary to stdout.
#   CSV written to manuscript/gate_coordinate_validation.csv.

suppressPackageStartupMessages({
  library(xml2)
})
has_flowws <- requireNamespace("flowWorkspace", quietly = TRUE)
has_flowco <- requireNamespace("flowCore",      quietly = TRUE)

BASE_DIR <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests"
OUT_CSV  <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/manuscript/gate_coordinate_validation.csv"

# ─── XML namespaces ────────────────────────────────────────────────────────
NS <- c(
  gating       = "http://www.isac-net.org/std/Gating-ML/v2.0/gating",
  transforms   = "http://www.isac-net.org/std/Gating-ML/v2.0/transformations",
  `data-type`  = "http://www.isac-net.org/std/Gating-ML/v2.0/data-types"
)

# ─── Ground-truth gate definitions ────────────────────────────────────────
# Sourced from roundtrip_experiment.Rmd (each test##_setup chunk).
# For transformed gates: coordinates are in TRANSFORMED space (as passed to
# flowCore rectangleGate / polygonGate after transform() was called).
# For linear gates: coordinates are in raw data space.
EXPECTED <- list(

  # ── Test 02: 1D rectangle, FSC-A, linear ───────────────────────────
  test02 = list(
    wsp_dir    = "test02",
    pop        = "FSC_filter",
    gate_type  = "rectangle",
    transform  = "linear",
    axis_range = 262144,          # denominator for % deviation
    dims = list(
      list(channel = "FSC-A", min = 60000, max = 180000)
    )
  ),

  # ── Test 03: 2D rectangle, FSC-A / SSC-A, linear ───────────────────
  test03 = list(
    wsp_dir    = "test03",
    pop        = "cells",
    gate_type  = "rectangle",
    transform  = "linear",
    axis_range = 262144,
    dims = list(
      list(channel = "FSC-A", min =  60000, max = 180000),
      list(channel = "SSC-A", min =  40000, max = 130000)
    )
  ),

  # ── Test 04: polygon, FSC-A / FSC-H, linear ────────────────────────
  test04 = list(
    wsp_dir    = "test04",
    pop        = "singlets",
    gate_type  = "polygon",
    transform  = "linear",
    axis_range = 262144,
    channels   = c("FSC-A", "FSC-H"),
    vertices   = matrix(c(
       50000,  45000,
       70000,  40000,
      160000, 140000,
      190000, 180000,
      180000, 190000,
       60000,  80000
    ), ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FSC-A", "FSC-H")))
  ),

  # ── Test 06: 1D rectangle, FITC-A, biexponential ───────────────────
  # Gate: c(1000, 3000) in biexp-transformed space [0, 4096]
  # Transform: flowjo_biexp_trans(channelRange=4096, maxValue=262144,
  #                               pos=4.5, neg=0, widthBasis=-10)
  # Validation: apply forward biexp to XML data-space coords,
  #             compare result to (1000, 3000).
  # Axis range for % deviation: channelRange = 4096.
  test06 = list(
    wsp_dir    = "test06",
    pop        = "FITC_pos",
    gate_type  = "rectangle",
    transform  = "biexp",
    axis_range = 4096,            # biexp channelRange
    trans_params = list(channelRange = 4096, maxValue = 262144,
                        pos = 4.5, neg = 0, widthBasis = -10),
    dims = list(
      list(channel = "FITC-A", min = 1000, max = 3000)
    )
  ),

  # ── Test 07: 1D rectangle, PE-A, FlowJo log ────────────────────────
  # Gate: c(0.4, 0.8) in log-transformed space [0, ~1]
  # Transform: flowjo_log_trans(decade=6, offset=1, scale=1, n=6)
  # NOTE: This test is expected to exhibit coordinate drift on round-trip.
  # Axis range for % deviation: 1 (log transform output range).
  test07 = list(
    wsp_dir      = "test07",
    pop          = "PE_pos",
    gate_type    = "rectangle",
    transform    = "log",
    axis_range   = 1,             # log output is in [0, 1]
    known_drift  = TRUE,
    trans_params = list(decade = 6, offset = 1, scale = 1, n = 6),
    dims = list(
      list(channel = "PE-A", min = 0.4, max = 0.8)
    )
  ),

  # ── Test 08: 1D rectangle, APC-A, arcsinh (GML2) ───────────────────
  # Gate: c(0.25, 0.92) in arcsinh-transformed space [0, ~1]
  # Transform: asinhtGml2_trans(T=262144, M=4.5, A=0)
  # Axis range for % deviation: 1 (arcsinh output range).
  test08 = list(
    wsp_dir    = "test08",
    pop        = "APC_pos",
    gate_type  = "rectangle",
    transform  = "arcsinh",
    axis_range = 1,
    trans_params = list(T = 262144, M = 4.5, A = 0),
    dims = list(
      list(channel = "APC-A", min = 0.25, max = 0.92)
    )
  ),

  # ── Test 09 level-1: cells, 2D rectangle, linear ───────────────────
  test09_cells = list(
    wsp_dir    = "test09",
    pop        = "cells",
    gate_type  = "rectangle",
    transform  = "linear",
    axis_range = 262144,
    dims = list(
      list(channel = "FSC-A", min =  60000, max = 190000),
      list(channel = "SSC-A", min =  40000, max = 140000)
    )
  ),

  # ── Test 09 level-2: singlets, 2D rectangle, linear ────────────────
  test09_singlets = list(
    wsp_dir    = "test09",
    pop        = "singlets",
    gate_type  = "rectangle",
    transform  = "linear",
    axis_range = 262144,
    dims = list(
      list(channel = "FSC-A", min =  70000, max = 180000),
      list(channel = "FSC-H", min =  60000, max = 170000)
    )
  )
)

# ─── XML extraction helpers ────────────────────────────────────────────────

#' Extract rectangle gate dimensions for pop_name from a WSP xml_document.
#' Returns a list of lists (one per dimension): channel, min, max.
#' Uses the SampleNode copy of the gate (more specific than the GroupNode copy).
extract_rect <- function(doc, pop_name) {
  xpath <- sprintf(
    ".//SampleNode//Population[@name='%s']//gating:RectangleGate/gating:dimension",
    pop_name)
  dim_nodes <- xml_find_all(doc, xpath, ns = NS)

  if (length(dim_nodes) == 0) {
    # Fallback: GroupNode copy
    xpath2 <- sprintf(
      ".//GroupNode//Population[@name='%s']//gating:RectangleGate/gating:dimension",
      pop_name)
    dim_nodes <- xml_find_all(doc, xpath2, ns = NS)
  }
  if (length(dim_nodes) == 0) return(NULL)

  lapply(dim_nodes, function(d) {
    fcs_node <- xml_find_first(d, "data-type:fcs-dimension", ns = NS)
    ch  <- xml_attr(fcs_node, "name")   # attribute has no namespace prefix
    list(
      channel = ch,
      min     = as.numeric(xml_attr(d, "gating:min", ns = NS)),
      max     = as.numeric(xml_attr(d, "gating:max", ns = NS))
    )
  })
}

#' Extract polygon gate vertices for pop_name.
#' Returns an n × 2 matrix with channel names as column names.
extract_poly <- function(doc, pop_name) {
  # Prefer SampleNode copy; fall back to any Population node.
  for (parent in c(".//SampleNode", ".//GroupNode", "")) {
    sep        <- if (nchar(parent) > 0) "//" else ".//"
    base_xpath <- sprintf("%s%sPopulation[@name='%s']/Gate/gating:PolygonGate",
                          parent, sep, pop_name)
    gate_nodes <- xml_find_all(doc, base_xpath, ns = NS)
    if (length(gate_nodes) > 0) break
    # Also try without the intermediate Gate element
    base_xpath <- sprintf("%s%sPopulation[@name='%s']//gating:PolygonGate",
                          parent, sep, pop_name)
    gate_nodes <- xml_find_all(doc, base_xpath, ns = NS)
    if (length(gate_nodes) > 0) break
  }
  if (length(gate_nodes) == 0) return(NULL)

  # Use the first match only (avoids duplicate GroupNode/SampleNode hits)
  gate_node <- gate_nodes[[1]]

  dim_nodes <- xml_find_all(gate_node, "gating:dimension", ns = NS)
  channels  <- sapply(dim_nodes, function(d) {
    xml_attr(xml_find_first(d, "data-type:fcs-dimension", ns = NS), "name")
  })

  vert_nodes <- xml_find_all(gate_node, "gating:vertex", ns = NS)
  if (length(vert_nodes) == 0) return(NULL)

  vmat <- do.call(rbind, lapply(vert_nodes, function(v) {
    coords <- xml_find_all(v, "gating:coordinate", ns = NS)
    as.numeric(sapply(coords,
                      function(c) xml_attr(c, "data-type:value", ns = NS)))
  }))
  colnames(vmat) <- channels
  vmat
}

# ─── Forward transform functions ──────────────────────────────────────────
# Applied to XML data-space coordinates to recover transformed-space values
# for comparison with the original gate coordinates.

make_biexp_fn <- function(p) {
  if (has_flowws) {
    trans <- flowWorkspace::flowjo_biexp_trans(
      channelRange = p$channelRange, maxValue = p$maxValue,
      pos = p$pos, neg = p$neg, widthBasis = p$widthBasis
    )
    # flowjo_biexp_trans returns an S3 "transform" with a $transform function
    trans$transform
  } else {
    stop("flowWorkspace required for biexp transform validation")
  }
}

make_log_fn <- function(p) {
  if (has_flowws) {
    trans <- flowWorkspace::flowjo_log_trans(
      decade = p$decade, offset = p$offset, scale = p$scale, n = p$n
    )
    trans$transform
  } else {
    # FlowJo log: f(x) = log10(x + offset) / decade * scale
    function(x) log10(x + p$offset) / p$decade * p$scale
  }
}

make_arcsinh_fn <- function(p) {
  if (has_flowws) {
    trans <- flowWorkspace::asinhtGml2_trans(T = p$T, M = p$M, A = p$A)
    trans$transform  # S3 "transform" object, same as biexp/log
  } else {
    # GML2 arcsinh: f(x) = asinh(x * sinh(M*ln10) / T) / (M + A)
    function(x) asinh(x * sinh(p$M * log(10)) / p$T) / (p$M + p$A)
  }
}

# ─── Deviation computation ─────────────────────────────────────────────────

#' Compare one rectangle dimension (observed vs expected).
#' Returns a 2-row data frame (min, max) with abs_dev and pct_dev.
rect_dim_dev <- function(exp_dim, obs_dim, axis_range, trans_fn = NULL) {
  if (is.null(trans_fn)) {
    # Linear: compare directly in data space
    exp_vals <- c(exp_dim$min, exp_dim$max)
    obs_vals <- c(obs_dim$min, obs_dim$max)
  } else {
    # Transformed: apply forward transform to XML data-space coords
    obs_t    <- trans_fn(c(obs_dim$min, obs_dim$max))
    exp_vals <- c(exp_dim$min, exp_dim$max)
    obs_vals <- obs_t
  }
  abs_dev <- abs(obs_vals - exp_vals)
  pct_dev <- abs_dev / axis_range * 100
  data.frame(
    channel   = exp_dim$channel,
    coord     = c("min", "max"),
    expected  = exp_vals,
    observed  = obs_vals,
    abs_dev   = abs_dev,
    pct_dev   = pct_dev,
    stringsAsFactors = FALSE
  )
}

# ─── Main validation loop ──────────────────────────────────────────────────

results     <- list()
summary_rows <- list()

for (test_id in names(EXPECTED)) {
  exp     <- EXPECTED[[test_id]]
  wsp_path <- file.path(BASE_DIR, exp$wsp_dir, "export.wsp")

  cat(sprintf("\n── %s  pop='%s'  transform=%s ──\n",
              test_id, exp$pop, exp$transform))

  if (!file.exists(wsp_path)) {
    cat("  SKIP: WSP not found:", wsp_path, "\n"); next
  }

  doc <- tryCatch(read_xml(wsp_path), error = function(e) {
    cat("  ERROR: XML parse failed:", e$message, "\n"); NULL
  })
  if (is.null(doc)) next

  # Build transform function (NULL for linear)
  trans_fn <- switch(exp$transform,
    biexp   = make_biexp_fn(exp$trans_params),
    log     = make_log_fn(exp$trans_params),
    arcsinh = make_arcsinh_fn(exp$trans_params),
    NULL
  )

  if (exp$gate_type == "rectangle") {
    obs_dims <- extract_rect(doc, exp$pop)

    if (is.null(obs_dims)) {
      cat("  Gate not found in XML\n"); next
    }

    # Match observed dims to expected by channel name
    detail_rows <- lapply(exp$dims, function(exp_dim) {
      obs_dim <- Filter(function(d) d$channel == exp_dim$channel, obs_dims)
      if (length(obs_dim) == 0) {
        cat(sprintf("  WARNING: channel '%s' not found in XML\n", exp_dim$channel))
        return(NULL)
      }
      rect_dim_dev(exp_dim, obs_dim[[1]], exp$axis_range, trans_fn)
    })
    detail_rows <- do.call(rbind, Filter(Negate(is.null), detail_rows))
    detail_rows$test        <- test_id
    detail_rows$gate        <- exp$pop
    detail_rows$gate_type   <- "rectangle"
    detail_rows$transform   <- exp$transform
    detail_rows$known_drift <- isTRUE(exp$known_drift)

    max_pct <- max(detail_rows$pct_dev, na.rm = TRUE)
    pass    <- max_pct <= 0.1
    cat(sprintf("  Max deviation: %.6f%% of axis range  [%s]%s\n",
                max_pct,
                if (pass) "PASS" else "FAIL",
                if (isTRUE(exp$known_drift)) " (known drift)" else ""))

    results[[test_id]] <- detail_rows
    summary_rows[[test_id]] <- data.frame(
      test        = test_id,
      population  = exp$pop,
      gate_type   = "rectangle",
      transform   = exp$transform,
      n_coords    = nrow(detail_rows),
      mean_pct    = round(mean(detail_rows$pct_dev, na.rm = TRUE), 6),
      max_pct     = round(max_pct, 6),
      pass        = pass || isTRUE(exp$known_drift),
      known_drift = isTRUE(exp$known_drift),
      stringsAsFactors = FALSE
    )

  } else if (exp$gate_type == "polygon") {
    obs_verts <- extract_poly(doc, exp$pop)

    if (is.null(obs_verts)) {
      cat("  Polygon gate not found in XML\n"); next
    }

    n   <- min(nrow(exp$vertices), nrow(obs_verts))
    dev <- sapply(seq_len(n), function(i) {
      sqrt(sum((exp$vertices[i, ] - obs_verts[i, ])^2))
    })
    pct     <- dev / exp$axis_range * 100
    max_pct <- max(pct)
    pass    <- max_pct <= 0.1

    cat(sprintf("  Max vertex deviation: %.6f%% of axis range  [%s]\n",
                max_pct, if (pass) "PASS" else "FAIL"))

    detail <- data.frame(
      test        = test_id,
      gate        = exp$pop,
      gate_type   = "polygon",
      transform   = "linear",
      vertex      = seq_len(n),
      channel     = "FSC-A/FSC-H",
      coord       = "vertex",
      expected_x  = exp$vertices[seq_len(n), 1],
      expected_y  = exp$vertices[seq_len(n), 2],
      observed_x  = obs_verts[seq_len(n), 1],
      observed_y  = obs_verts[seq_len(n), 2],
      eucl_dev    = dev,
      pct_dev     = pct,
      known_drift = FALSE,
      stringsAsFactors = FALSE
    )
    results[[test_id]] <- detail
    summary_rows[[test_id]] <- data.frame(
      test        = test_id,
      population  = exp$pop,
      gate_type   = "polygon",
      transform   = "linear",
      n_coords    = n,
      mean_pct    = round(mean(pct), 6),
      max_pct     = round(max_pct, 6),
      pass        = pass,
      known_drift = FALSE,
      stringsAsFactors = FALSE
    )
  }
}

# ─── Summary table ────────────────────────────────────────────────────────

cat("\n\n", strrep("=", 70), "\n")
cat("TABLE 3 — GATE COORDINATE ACCURACY SUMMARY\n")
cat(strrep("=", 70), "\n\n")
cat("Acceptance criterion: max deviation ≤ 0.1% of axis range\n")
cat("(Axis range = 262144 for linear/biexp; 1 for log/arcsinh)\n\n")

if (length(summary_rows) > 0) {
  tbl <- do.call(rbind, summary_rows)
  # Friendly formatting
  tbl$mean_pct_fmt <- sprintf("%.6f", tbl$mean_pct)
  tbl$max_pct_fmt  <- sprintf("%.6f", tbl$max_pct)
  tbl$status <- ifelse(tbl$known_drift, "known drift",
                       ifelse(tbl$pass, "PASS", "FAIL"))
  print(tbl[, c("test", "population", "gate_type", "transform",
                "n_coords", "mean_pct_fmt", "max_pct_fmt", "status")],
        row.names = FALSE)

  n_tests       <- nrow(tbl)
  n_drift       <- sum(tbl$known_drift)
  n_pass        <- sum(tbl$pass & !tbl$known_drift)
  n_non_drift   <- n_tests - n_drift
  cat(sprintf("\nResult: %d / %d pass (excl. %d known-drift test)\n",
              n_pass, n_non_drift, n_drift))

  # Write CSV
  write.csv(tbl[, c("test", "population", "gate_type", "transform",
                     "n_coords", "mean_pct", "max_pct", "known_drift", "pass")],
            OUT_CSV, row.names = FALSE)
  cat(sprintf("Summary written to: %s\n", OUT_CSV))
} else {
  cat("No results — check that WSP files exist in:\n  ", BASE_DIR, "\n")
}

cat("\nNote: Tests 01, 05, 10-13 not covered by coordinate comparison.\n")
cat("  01: no gates\n")
cat("  05: ellipsoid gate — different XML parameterization\n")
cat("  10-13: boolean operand gates covered via tests 02/03/06/08\n")
cat("\nDone.\n")
