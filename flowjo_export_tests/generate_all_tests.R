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

#!/usr/bin/env Rscript
# generate_all_tests.R
#
# Regenerate all 13 test WSP files under flowjo_export_tests/testNN/.
# Each WSP is written as testNN_export.wsp (not export.wsp).
#
# Run from the package root:
#   Rscript flowjo_export_tests/generate_all_tests.R
#
# Or from R:
#   source("flowjo_export_tests/generate_all_tests.R")

suppressPackageStartupMessages({
  library(Biobase)       # AnnotatedDataFrame
  library(flowCore)
  library(flowWorkspace)
  devtools::load_all()
})

# ── Resolve base directory ────────────────────────────────────────────────────
args <- commandArgs(trailingOnly = FALSE)
m    <- regmatches(args, regexpr("(?<=--file=).+", args, perl = TRUE))
BASE_TEST_DIR <- if (length(m) == 1L) {
  dirname(normalizePath(m))          # directory containing this script
} else {
  file.path(getwd(), "flowjo_export_tests")
}
cat("Base test directory:", BASE_TEST_DIR, "\n\n")

# ── Configuration for FCS file paths ──────────────────────────────────────────
# Set this to the absolute path where test files will be located on the target
# system (e.g., the Mac where FlowJo will open these files).
# Default uses the current system path; override for cross-platform use.
TARGET_ROOT <- Sys.getenv("CYFJ11_TARGET_ROOT")
if (TARGET_ROOT == "") {
  # Default: use current system path
  TARGET_ROOT <- BASE_TEST_DIR
}
TARGET_ROOT="./flowjo_export_tests"
cat("Target root for FCS paths:", TARGET_ROOT, "\n\n")

# ── Helper: create synthetic FCS with biologically realistic distributions ─────
# Generates biologically meaningful cell population data:
# - Scatter (FSC/SSC): Normal distributions with typical cell size/granularity
# - Fluorescence: Log-normal with negative and positive subpopulations
# This produces realistic flow cytometry data for visual validation
create_test_fcs <- function(n = 10000, seed = 123) {
  set.seed(seed)

  # Scatter channels: normal distributions (cell size/granularity)
  fsc_a <- rnorm(n, mean = 120000, sd = 30000)
  fsc_h <- fsc_a * runif(n, 0.9, 1.1)
  ssc_a <- rnorm(n, mean = 80000,  sd = 20000)
  ssc_h <- ssc_a * runif(n, 0.9, 1.1)

  # Fluorescence channels: log-normal with negative (~30%) and positive (~70%) populations
  fitc_a      <- c(rlnorm(n * 0.7, 2, 0.8),  rlnorm(n * 0.3, 8, 0.5))[1:n]
  pe_a        <- c(rlnorm(n * 0.6, 2.5, 0.7), rlnorm(n * 0.4, 7.5, 0.6))[1:n]
  apc_a       <- c(rlnorm(n * 0.8, 1.8, 0.9), rlnorm(n * 0.2, 7.2, 0.5))[1:n]
  percpcy55_a <- c(rlnorm(n * 0.75, 2.2, 0.75), rlnorm(n * 0.25, 7.8, 0.55))[1:n]

  # Clamp to valid 18-bit range
  clamp <- function(x) pmin(pmax(x, 0), 262144)

  mat <- cbind(
    clamp(fsc_a), clamp(fsc_h), clamp(ssc_a), clamp(ssc_h),
    clamp(fitc_a), clamp(pe_a), clamp(apc_a), clamp(percpcy55_a)
  )
  colnames(mat) <- c("FSC-A", "FSC-H", "SSC-A", "SSC-H",
                     "FITC-A", "PE-A", "APC-A", "PerCP-Cy5-5-A")

  params <- AnnotatedDataFrame(data = data.frame(
    name      = colnames(mat),
    desc      = c("FSC-A", "FSC-H", "SSC-A", "SSC-H", "CD3", "CD4", "CD8", "CD14"),
    range     = rep(262144, ncol(mat)),
    minRange  = rep(0,      ncol(mat)),
    maxRange  = rep(262144, ncol(mat)),
    row.names = colnames(mat),
    stringsAsFactors = FALSE
  ))

  new("flowFrame",
      exprs       = mat,
      parameters  = params,
      description = list(
        `$FIL`   = sprintf("test_sample_%03d.fcs", seed),
        FILENAME  = sprintf("test_sample_%03d.fcs", seed),
        `$TOT`   = as.character(n),
        `$PAR`   = as.character(ncol(mat))
      ))
}

# ── Run one test, catching errors ─────────────────────────────────────────────
run_test <- function(num, expr) {
  cat(sprintf("\n%s\n  TEST %02d\n%s\n", strrep("=", 60), num, strrep("=", 60)))
  tryCatch(
    { expr; cat(sprintf("✓ test%02d done\n", num)) },
    error = function(e) cat(sprintf("✗ test%02d FAILED: %s\n", num, e$message))
  )
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST 01 — No gates, linear only -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(1, {
  test_dir <- file.path(BASE_TEST_DIR, "test01")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 5000, seed = 1)
  write.FCS(ff, file.path(test_dir, "sample01.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample01.fcs")))
  export_flowjo10_workspace(gs, file.path(test_dir, "test01_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 02 — 1D rectangle, linear -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(2, {
  test_dir <- file.path(BASE_TEST_DIR, "test02")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 5000, seed = 2)
  write.FCS(ff, file.path(test_dir, "sample02.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample02.fcs")))
  gs_pop_add(gs, rectangleGate(filterId = "FSC_filter", "FSC-A" = c(60000, 180000)), parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test02_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 03 — 2D rectangle, linear -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(3, {
  test_dir <- file.path(BASE_TEST_DIR, "test03")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 5000, seed = 3)
  write.FCS(ff, file.path(test_dir, "sample03.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample03.fcs")))
  gs_pop_add(gs, rectangleGate(
    filterId = "cells", "FSC-A" = c(60000, 180000), "SSC-A" = c(40000, 130000)
  ), parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test03_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 04 — Polygon gate, linear -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(4, {
  test_dir <- file.path(BASE_TEST_DIR, "test04")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 8000, seed = 4)
  write.FCS(ff, file.path(test_dir, "sample04.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample04.fcs")))
  gs_pop_add(gs, polygonGate(
    filterId = "singlets",
    "FSC-A" = c(50000, 70000, 160000, 190000, 180000,  60000),
    "FSC-H" = c(45000, 40000, 140000, 180000, 190000,  80000)
  ), parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test04_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 05 — Ellipsoid gate, linear -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(5, {
  test_dir <- file.path(BASE_TEST_DIR, "test05")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 8000, seed = 5)
  write.FCS(ff, file.path(test_dir, "sample05.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample05.fcs")))
  ellipse_cov <- matrix(c(1.5e9, 7e8, 7e8, 1e9), ncol = 2)
  colnames(ellipse_cov) <- rownames(ellipse_cov) <- c("FSC-A", "SSC-A")
  gs_pop_add(gs, ellipsoidGate(
    filterId = "ellipse_cells", .gate = ellipse_cov,
    mean = c("FSC-A" = 120000, "SSC-A" = 80000), distance = 2
  ), parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test05_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 06 — 1D rectangle, biexponential (FITC-A) -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(6, {
  test_dir <- file.path(BASE_TEST_DIR, "test06")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 8000, seed = 6)
  write.FCS(ff, file.path(test_dir, "sample06.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample06.fcs")))
  biexp_trans <- flowjo_biexp_trans(channelRange = 4096, maxValue = 262144,
                                    pos = 4.5, neg = 0, widthBasis = -10)
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", biexp_trans))
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1000, 3000)),
             parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test06_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 07 — 1D rectangle, log (PE-A) -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(7, {
  test_dir <- file.path(BASE_TEST_DIR, "test07")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 8000, seed = 7)
  write.FCS(ff, file.path(test_dir, "sample07.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample07.fcs")))
  log_trans <- flowjo_log_trans(decade = 6, offset = 1, scale = 1, n = 6)
  gs <- flowWorkspace::transform(gs, transformerList("PE-A", log_trans))
  gs_pop_add(gs, rectangleGate(filterId = "PE_pos", "PE-A" = c(0.4, 0.8)),
             parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test07_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 08 — 1D rectangle, arcsinh (APC-A) -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(8, {
  test_dir <- file.path(BASE_TEST_DIR, "test08")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 8000, seed = 8)
  write.FCS(ff, file.path(test_dir, "sample08.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample08.fcs")))
  asinh_trans <- asinhtGml2_trans(T = 262144, M = 4.5, A = 0)
  gs <- flowWorkspace::transform(gs, transformerList("APC-A", asinh_trans))
  gs_pop_add(gs, rectangleGate(filterId = "APC_pos", "APC-A" = c(0.25, 0.92)),
             parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test08_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 09 — Hierarchical (2 levels), linear -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(9, {
  test_dir <- file.path(BASE_TEST_DIR, "test09")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 10000, seed = 9)
  write.FCS(ff, file.path(test_dir, "sample09.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample09.fcs")))
  gs_pop_add(gs, rectangleGate(
    filterId = "cells", "FSC-A" = c(60000, 190000), "SSC-A" = c(40000, 140000)
  ), parent = "root")
  recompute(gs)
  gs_pop_add(gs, rectangleGate(
    filterId = "singlets", "FSC-A" = c(70000, 180000), "FSC-H" = c(60000, 170000)
  ), parent = "/cells")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test09_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 10 — Boolean AND/OR/NOT, linear -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(10, {
  test_dir <- file.path(BASE_TEST_DIR, "test10")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 8000, seed = 10)
  write.FCS(ff, file.path(test_dir, "sample10.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample10.fcs")))
  gs_pop_add(gs, rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000)),
             parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "SSC_gate", "SSC-A" = c(50000, 130000)),
             parent = "root")
  recompute(gs)
  gs_pop_add(gs, booleanFilter(`FSC_gate&SSC_gate`, filterId = "both"),    parent = "root")
  gs_pop_add(gs, booleanFilter(`FSC_gate|SSC_gate`, filterId = "bothOR"),  parent = "root")
  gs_pop_add(gs, booleanFilter(`!both`,             filterId = "bothNOT"), parent = "root")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test10_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 11 — Mixed biexp+arcsinh, hierarchy + boolean -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(11, {
  test_dir <- file.path(BASE_TEST_DIR, "test11")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 10000, seed = 11)
  write.FCS(ff, file.path(test_dir, "sample11.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample11.fcs")))
  biexp_trans <- flowjo_biexp_trans(channelRange = 4096, maxValue = 262144,
                                    pos = 4.5, neg = 0, widthBasis = -10)
  asinh_trans <- asinhtGml2_trans(T = 262144, M = 4.5, A = 0)
  gs <- flowWorkspace::transform(gs, transformerList(
    from  = c("FITC-A", "APC-A"),
    trans = list(biexp_trans, asinh_trans)
  ))
  gs_pop_add(gs, rectangleGate(
    filterId = "cells", "FSC-A" = c(60000, 200000), "SSC-A" = c(30000, 150000)
  ), parent = "root")
  recompute(gs)
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1000, 3500)),
             parent = "/cells")
  gs_pop_add(gs, rectangleGate(filterId = "APC_pos",  "APC-A"  = c(0.28, 0.95)),
             parent = "/cells")
  gs_pop_add(gs, polygonGate(
    filterId = "singlets",
    "FSC-A"  = c(55000,  75000, 185000, 205000, 195000,  65000),
    "FSC-H"  = c(50000,  45000, 165000, 195000, 205000,  85000)
  ), parent = "/cells")
  gs_pop_add(gs, booleanFilter(`FITC_pos&APC_pos`, filterId = "double_pos"),
             parent = "/cells")
  gs_pop_add(gs, booleanFilter(`FITC_pos|APC_pos`, filterId = "either_pos"),
             parent = "/cells")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test11_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 12 — Biexp+log, ellipse + full boolean set -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(12, {
  test_dir <- file.path(BASE_TEST_DIR, "test12")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 10000, seed = 12)
  write.FCS(ff, file.path(test_dir, "sample12.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample12.fcs")))
  log_trans   <- flowjo_log_trans(decade = 6, offset = 1, scale = 1, n = 6)
  biexp_trans <- flowjo_biexp_trans(channelRange = 4096, maxValue = 262144,
                                    pos = 4.5, neg = 0, widthBasis = -10)
  gs <- flowWorkspace::transform(gs, transformerList(
    from  = c("PE-A", "FITC-A"),
    trans = list(log_trans, biexp_trans)
  ))
  gs_pop_add(gs, rectangleGate(
    filterId = "cells", "FSC-A" = c(55000, 195000), "SSC-A" = c(25000, 145000)
  ), parent = "root")
  ellipse_cov <- matrix(c(2e9, 8e8, 8e8, 1.5e9), ncol = 2)
  colnames(ellipse_cov) <- rownames(ellipse_cov) <- c("FSC-A", "SSC-A")
  gs_pop_add(gs, ellipsoidGate(
    filterId = "scatter_ellipse", .gate = ellipse_cov,
    mean = c("FSC-A" = 120000, "SSC-A" = 80000), distance = 2
  ), parent = "root")
  recompute(gs)
  gs_pop_add(gs, rectangleGate(filterId = "FITC_hi", "FITC-A" = c(1500, 4096)),
             parent = "/cells")
  gs_pop_add(gs, rectangleGate(filterId = "PE_hi",   "PE-A"   = c(0.45, 1.0)),
             parent = "/cells")
  gs_pop_add(gs, booleanFilter(`FITC_hi&PE_hi`,       filterId = "double_hi"),
             parent = "/cells")
  gs_pop_add(gs, booleanFilter(`FITC_hi|PE_hi`,       filterId = "either_hi"),
             parent = "/cells")
  gs_pop_add(gs, booleanFilter(`cells&!either_hi`,    filterId = "neither"),
             parent = "/cells")
  recompute(gs)
  export_flowjo10_workspace(gs, file.path(test_dir, "test12_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 13 — Arcsinh × 3 channels, 3-level hierarchy + boolean -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(13, {
  test_dir <- file.path(BASE_TEST_DIR, "test13")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  ff <- create_test_fcs(n = 10000, seed = 13)
  write.FCS(ff, file.path(test_dir, "sample13.fcs"))
  gs <- GatingSet(read.flowSet(file.path(test_dir, "sample13.fcs")))
  asinh_trans <- asinhtGml2_trans(T = 262144, M = 4.5, A = 0)
  gs <- flowWorkspace::transform(gs, transformerList(c("FITC-A", "PE-A", "APC-A"), asinh_trans))

  # Level 1 — polygon (linear scatter)
  gs_pop_add(gs, polygonGate(
    filterId = "live",
    "FSC-A"  = c(35000,  55000, 195000, 215000, 205000,  45000),
    "SSC-A"  = c(12000,   8000,   8000,  55000, 148000, 148000)
  ), parent = "root")
  recompute(gs)

  # Level 2a — 2D rectangle singlets (linear)
  gs_pop_add(gs, rectangleGate(
    filterId = "singlets", "FSC-A" = c(65000, 195000), "FSC-H" = c(60000, 185000)
  ), parent = "/live")

  # Level 2b — ellipse on arcsinh FITC-A vs PE-A
  ellipse_cov_asinh <- matrix(c(0.025, 0.008, 0.008, 0.020), ncol = 2)
  colnames(ellipse_cov_asinh) <- rownames(ellipse_cov_asinh) <- c("FITC-A", "PE-A")
  gs_pop_add(gs, ellipsoidGate(
    filterId = "FITC_PE_gate", .gate = ellipse_cov_asinh,
    mean = c("FITC-A" = 0.62, "PE-A" = 0.57), distance = 2
  ), parent = "/live")
  recompute(gs)

  # Level 3 — children of singlets
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(0.25, 0.95)),
             parent = "/live/singlets")
  gs_pop_add(gs, rectangleGate(filterId = "APC_pos",  "APC-A"  = c(0.28, 0.92)),
             parent = "/live/singlets")
  gs_pop_add(gs, booleanFilter(`FITC_pos&APC_pos`, filterId = "double_pos"),
             parent = "/live/singlets")
  gs_pop_add(gs, booleanFilter(`/live/singlets&!double_pos`, filterId = "not_double"),
             parent = "/live/singlets")
  recompute(gs)

  stats <- gs_pop_get_count_fast(gs)
  cat("  Counts:\n")
  for (i in seq_len(nrow(stats))) {
    cat(sprintf("    %-30s %d\n", stats$Population[i], stats$Count[i]))
  }

  export_flowjo10_workspace(gs, file.path(test_dir, "test13_export.wsp"),
                            fcs_root = test_dir)
})

# ─────────────────────────────────────────────────────────────────────────────
# TEST 14 — FlowSOM real-world validation (v10 import/export) -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(14, {
  test_dir <- file.path(BASE_TEST_DIR, "test14")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)

  # Copy FCS file for test14 from the public FlowSOM example data.
  # The parser reads the file named "68983.fcs" from test_dir (matching the
  # workspace subset), so we always restore it from the original FlowSOM data
  # to prevent a previously exported/compensated copy from being reused.
  flowsom_fcs <- system.file("extdata", "68983.fcs", package = "FlowSOM")
  if (flowsom_fcs == "" || !file.exists(flowsom_fcs)) {
    stop("FlowSOM example data 68983.fcs not found. Install FlowSOM to run test 14.")
  }
  fcs_src <- file.path(BASE_TEST_DIR, "test14", "sample14.fcs")
  fcs_src_org <- file.path(BASE_TEST_DIR, "sample14.org.fcs")
  fcs_main <- file.path(test_dir, "68983.fcs")
  file.copy(flowsom_fcs, fcs_src,     overwrite = TRUE)
  file.copy(flowsom_fcs, fcs_src_org, overwrite = TRUE)
  file.copy(flowsom_fcs, fcs_main,     overwrite = TRUE)

  # Use the existing test14_flowsom.wsp file (or copy from FlowSOM example data)
  flowsom_wsp <- file.path(test_dir, "test14_flowsom.wsp")
  if (!file.exists(flowsom_wsp)) {
    flowsom_pkg_wsp <- system.file("extdata", "gating.wsp", package = "FlowSOM")
    if (flowsom_pkg_wsp != "" && file.exists(flowsom_pkg_wsp)) {
      file.copy(flowsom_pkg_wsp, flowsom_wsp, overwrite = TRUE)
    } else {
      stop("FlowSOM example data gating.wsp not found. Install FlowSOM to run test 14.")
    }
  }

  cat("  Importing FlowSOM wsp:", flowsom_wsp, "\n")

  # Use CytoML to import v10 workspace
  ws <- CytoML::open_flowjo_xml(flowsom_wsp)
  gs <- CytoML::flowjo_to_gatingset(ws,
                                    path = test_dir,
                                    name = "All Samples",
                                    subset = "68983.fcs",
                                    sample_names_from = "sampleID")

  cat("  Imported GatingSet with", length(gs), "samples\n")

  # Print population counts
  stats <- flowWorkspace::gs_pop_get_count_fast(gs)
  cat("  FlowSOM population counts:\n")
  for (i in seq_len(nrow(stats))) {
    cat(sprintf("    %-30s %d\n", stats$Population[i], stats$Count[i]))
  }

  # Export to v10 format using CyFj11
  export_flowjo10_workspace(gs, file.path(test_dir, "test14_export.wsp"))

  cat("  Exported to test14_export.wsp\n")
})

cat("\n", strrep("=", 60), "\n")
cat("All tests complete. WSP files written to:\n")
cat(" ", BASE_TEST_DIR, "\n\n")
cat("Each testNN/testNN_export.wsp can be opened directly in FlowJo.\n")

# Copy all .wsp files to .llm.wsp for comparison/testing
cat("\n", strrep("=", 60), "\n")
cat("Copying .wsp files to .llm.wsp versions...\n")
for (i in 1:14) {
  test_dir <- file.path(BASE_TEST_DIR, sprintf("test%02d", i))
  wsp_file <- file.path(test_dir, sprintf("test%02d_export.wsp", i))
  llm_file <- file.path(test_dir, sprintf("test%02d_export.llm.wsp", i))
  if (file.exists(wsp_file)) {
    file.copy(wsp_file, llm_file, overwrite = TRUE)
    cat(sprintf("  test%02d_export.wsp → test%02d_export.llm.wsp\n", i, i))
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST 15 — FlowSOM extreme compensation -----
# ─────────────────────────────────────────────────────────────────────────────
run_test(15, {
  test_dir <- file.path(BASE_TEST_DIR, "test14")
  dir.create(test_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Copy FCS file for test14 from the public FlowSOM example data.
  # The parser reads the file named "68983.fcs" from test_dir (matching the
  # workspace subset), so we always restore it from the original FlowSOM data
  # to prevent a previously exported/compensated copy from being reused.
  flowsom_fcs <- system.file("extdata", "68983.fcs", package = "FlowSOM")
  if (flowsom_fcs == "" || !file.exists(flowsom_fcs)) {
    stop("FlowSOM example data 68983.fcs not found. Install FlowSOM to run test 14.")
  }
  fcs_src <- file.path(BASE_TEST_DIR, "test14", "sample14.fcs")
  fcs_src_org <- file.path(BASE_TEST_DIR, "sample14.org.fcs")
  fcs_main <- file.path(test_dir, "68983.fcs")
   cat("  Importing FlowSOM wsp:", flowsom_wsp, "\n")
   fj_path = "flowjo_export_tests/test14/test14_export.llm.extreme.compensation.flowjo"
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
  cat("  Imported GatingSet with", length(gs_list), "samples\n")
  
  # Print population counts
  stats <- flowWorkspace::gs_pop_get_count_fast(gs_list[[1]])
  cat("  FlowSOM population counts:\n")
  for (i in seq_len(nrow(stats))) {
    cat(sprintf("    %-30s %d\n", stats$Population[i], stats$Count[i]))
  }
  
  # Export to v10 format using CyFj11
  export_flowjo10_workspace(gs, file.path(test_dir, "test14_export.wsp"))
  
  cat("  Exported to test14_export.wsp\n")
})

cat("\n", strrep("=", 60), "\n")
cat("All tests complete. WSP files written to:\n")
cat(" ", BASE_TEST_DIR, "\n\n")
cat("Each testNN/testNN_export.wsp can be opened directly in FlowJo.\n")

# Copy all .wsp files to .llm.wsp for comparison/testing
cat("\n", strrep("=", 60), "\n")
cat("Copying .wsp files to .llm.wsp versions...\n")
for (i in 1:14) {
  test_dir <- file.path(BASE_TEST_DIR, sprintf("test%02d", i))
  wsp_file <- file.path(test_dir, sprintf("test%02d_export.wsp", i))
  llm_file <- file.path(test_dir, sprintf("test%02d_export.llm.wsp", i))
  if (file.exists(wsp_file)) {
    file.copy(wsp_file, llm_file, overwrite = TRUE)
    cat(sprintf("  test%02d_export.wsp → test%02d_export.llm.wsp\n", i, i))
  }
}




cat("Done!\n")

# # Update file paths in all WSP files for Mac/FlowJo compatibility
# update_script <- file.path(BASE_TEST_DIR, "update_paths.sh")
# if (file.exists(update_script)) {
#   cat("\n", strrep("=", 60), "\n")
#   cat("Updating file paths in WSP files for FlowJo compatibility...\n")
#   cat("Using TARGET_ROOT:", TARGET_ROOT, "\n")
#   # Pass TARGET_ROOT as environment variable to the script
#   system(paste0("export TARGET_ROOT=\"", TARGET_ROOT, "\"; bash ", update_script))
#   cat("Done!\n")
# } else {
#   cat("\nNote: update_paths.sh not found, skipping path updates.\n")
# }
