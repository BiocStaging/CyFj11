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

# Unit tests for internal FlowJo v10 export helpers.

test_that("convert_rectangle_to_flowjo10 handles 1D and 2D gates", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  gate_1d <- rectangleGate(
    `FSC-A` = c(1000, 100000),
    filterId = "1D"
  )
  out <- CyFj11:::convert_rectangle_to_flowjo10(gate_1d, "1D")
  expect_equal(out$type, "rectangle")
  expect_length(out$dimensions, 1)

  gate_2d <- rectangleGate(
    list(`FSC-A` = c(1000, 100000), `SSC-A` = c(1000, 100000)),
    filterId = "2D"
  )
  out <- CyFj11:::convert_rectangle_to_flowjo10(gate_2d, "2D")
  expect_equal(out$type, "rectangle")
  expect_length(out$dimensions, 2)
})

test_that("convert_rectangle_to_flowjo10 applies inverse transform with gh", {
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:100, ncol = 2, dimnames = list(NULL, c("FSC-A", "FITC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logtGml2_trans()))

  gate <- rectangleGate(`FITC-A` = c(1, 3), filterId = "log_pos")
  out <- CyFj11:::convert_rectangle_to_flowjo10(gate, "log_pos", gs[[1]])
  expect_equal(out$type, "rectangle")
})

test_that("convert_polygon_to_flowjo10 returns polygon structure", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  boundaries <- matrix(
    c(0, 0, 100, 0, 100, 100, 0, 100),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FSC-A", "SSC-A"))
  )
  gate <- polygonGate(boundaries, filterId = "poly")

  out <- CyFj11:::convert_polygon_to_flowjo10(gate, "poly")
  expect_equal(out$type, "polygon")
  expect_length(out$dimensions, 2)
  expect_length(out$vertices, 4)
})

test_that("convert_ellipsoid_to_flowjo10 returns ellipsoid structure", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  cov <- matrix(c(1000, 0, 0, 1000), nrow = 2,
                dimnames = list(c("FSC-A", "SSC-A"), c("FSC-A", "SSC-A")))
  gate <- ellipsoidGate(cov, mean = c(50000, 50000), distance = 1, filterId = "ellipse")

  out <- CyFj11:::convert_ellipsoid_to_flowjo10(gate, "ellipse")
  expect_equal(out$type, "ellipsoid")
  expect_equal(unname(out$x_param), "FSC-A")
  expect_equal(unname(out$y_param), "SSC-A")
  expect_true(is.numeric(out$distance))
})

test_that("convert_ellipsoid_to_flowjo10 returns NULL for invalid gate", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  bad_gate <- rectangleGate(`FSC-A` = c(1, 2), filterId = "not_ellipse")
  out <- CyFj11:::convert_ellipsoid_to_flowjo10(bad_gate, "not_ellipse")
  expect_null(out)
})

test_that("convert_boolean_to_flowjo10 parses AND, OR, NOT expressions", {
  skip_if_not_installed("flowWorkspace")
  library(flowWorkspace)

  bf_and <- booleanFilter(`CD4+` & `CD8+`, filterId = "and_gate")
  out <- CyFj11:::convert_boolean_to_flowjo10(bf_and, "and_gate")
  expect_equal(out$type, "boolean")
  expect_equal(out$op_type, "and")

  bf_or <- booleanFilter(`CD4+` | `CD8+`, filterId = "or_gate")
  out <- CyFj11:::convert_boolean_to_flowjo10(bf_or, "or_gate")
  expect_equal(out$op_type, "or")

  bf_not <- booleanFilter(!`CD4+`, filterId = "not_gate")
  out <- CyFj11:::convert_boolean_to_flowjo10(bf_not, "not_gate")
  expect_equal(out$op_type, "not")
})

test_that("convert_boolean_to_flowjo10 handles negated components", {
  skip_if_not_installed("flowWorkspace")
  library(flowWorkspace)

  bf <- booleanFilter(`CD4+` & !`CD8+`, filterId = "mixed")
  out <- CyFj11:::convert_boolean_to_flowjo10(bf, "mixed")
  expect_equal(out$type, "boolean")
  expect_equal(out$negated, c(FALSE, TRUE))
})

test_that("build_sample_keywords merges keyword lists", {
  fcs_kw <- list(`$TOT` = "10000", `$DATE` = "01-Jan-2024")
  gs_kw <- list(`PATIENT ID` = "P001", TUBE = "1")
  out <- CyFj11:::build_sample_keywords(fcs_kw, gs_kw, "sample.fcs")

  expect_equal(out$FILENAME, "sample.fcs")
  expect_equal(out$`$TOT`, "10000")
  expect_equal(out$`PATIENT ID`, "P001")
})

test_that("parse_spill_keyword parses SPILL string", {
  spill <- "3,FITC-A,PE-A,APC-A,1,0.1,0.2,0.05,1,0.15,0.1,0.05,1"
  out <- CyFj11:::parse_spill_keyword(list(SPILL = spill))
  expect_equal(dim(out), c(3, 3))
  expect_equal(colnames(out), c("FITC-A", "PE-A", "APC-A"))
})

test_that("parse_spill_keyword handles matrix input", {
  mat <- matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  out <- CyFj11:::parse_spill_keyword(list(SPILL = mat))
  expect_equal(dim(out), c(2, 2))
})

test_that("parse_spill_keyword returns NULL when SPILL missing", {
  expect_null(CyFj11:::parse_spill_keyword(list()))
})

test_that("write_fcs_files_to_dir writes files and respects overwrite", {
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  mat <- matrix(1:20, ncol = 2, dimnames = list(NULL, c("FSC-A", "SSC-A")))
  cs <- flowSet(flowFrame(mat))
  gs <- GatingSet(cs)

  paths <- CyFj11:::write_fcs_files_to_dir(gs, tmp, overwrite = FALSE)
  expect_true(all(file.exists(paths)))

  expect_warning(
    paths2 <- CyFj11:::write_fcs_files_to_dir(gs, tmp, overwrite = TRUE),
    "overwritten"
  )
  expect_equal(paths, paths2)
})

test_that("get_transform_spec handles explicit transforms", {
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  mat <- matrix(1:100, ncol = 2, dimnames = list(NULL, c("FSC-A", "FITC-A")))
  gs <- GatingSet(flowSet(flowFrame(mat)))

  logicle_trans <- logicle_trans(t = 262144, w = 0.5, m = 4.5, a = 0)
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logicle_trans))

  out <- CyFj11:::get_transform_spec(gs[[1]], "FITC-A")
  expect_equal(out$transformType, "Logicle")
})

test_that("get_display_range returns numeric range", {
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  mat <- matrix(1:100, ncol = 2, dimnames = list(NULL, c("FSC-A", "SSC-A")))
  gs <- GatingSet(flowSet(flowFrame(mat)))

  out <- CyFj11:::get_display_range(gs[[1]], "FSC-A")
  expect_length(out, 2)
  expect_true(is.numeric(out))
})

# Tests for sanitize_channel_label() function
test_that("sanitize_channel_label replaces slash with underscore", {
  expect_equal(CyFj11:::sanitize_channel_label("NK1/1"), "NK1_1")
  expect_equal(CyFj11:::sanitize_channel_label("CD4/CD8"), "CD4_CD8")
})

test_that("sanitize_channel_label replaces backslash", {
  expect_equal(CyFj11:::sanitize_channel_label("test\\value"), "test_value")
})

test_that("sanitize_channel_label replaces colon", {
  expect_equal(CyFj11:::sanitize_channel_label("Time:01"), "Time_01")
})

test_that("sanitize_channel_label replaces XML special characters", {
  expect_equal(CyFj11:::sanitize_channel_label("test<gt>"), "test_gt_")
  expect_equal(CyFj11:::sanitize_channel_label("a|b"), "a_b")
})

test_that("sanitize_channel_label replaces Windows reserved characters", {
  expect_equal(CyFj11:::sanitize_channel_label("file*name"), "file_name")
  expect_equal(CyFj11:::sanitize_channel_label("what?"), "what_")
  expect_equal(CyFj11:::sanitize_channel_label('test"quote'), "test_quote")
})

test_that("sanitize_channel_label handles multiple problematic chars", {
  expect_equal(CyFj11:::sanitize_channel_label("NK1/1:sub"), "NK1_1_sub")
  expect_equal(CyFj11:::sanitize_channel_label("a/b\\c:d"), "a_b_c_d")
  expect_equal(CyFj11:::sanitize_channel_label("test<gt>|*?"), "test_gt____")
})

test_that("sanitize_channel_label handles edge cases", {
  expect_equal(CyFj11:::sanitize_channel_label(""), "")
  expect_equal(CyFj11:::sanitize_channel_label(NULL), "")
  expect_equal(CyFj11:::sanitize_channel_label(NA), "")
  expect_equal(CyFj11:::sanitize_channel_label("normal_label"), "normal_label")
})

# Tests for build_sample_keywords() with problematic channel labels
test_that("build_sample_keywords sanitizes $PnS channel labels", {
  fcs_kw <- list(
    `$TOT` = "10000",
    `$P1S` = "NK1/1",      # slash should be sanitized
    `$P2S` = "CD4/CD8",    # slash should be sanitized
    `$P3S` = "normal"      # no sanitization needed
  )
  gs_kw <- list()
  out <- CyFj11:::build_sample_keywords(fcs_kw, gs_kw, "sample.fcs")

  expect_equal(out$`$P1S`, "NK1_1")
  expect_equal(out$`$P2S`, "CD4_CD8")
  expect_equal(out$`$P3S`, "normal")
  expect_equal(out$FILENAME, "sample.fcs")
})

test_that("build_sample_keywords sanitizes $PnS with multiple problematic chars", {
  fcs_kw <- list(
    `$P1S` = "test<gt>|*?",  # multiple problematic chars
    `$P2S` = "a:b\\c"        # colon and backslash
  )
  gs_kw <- list()
  out <- CyFj11:::build_sample_keywords(fcs_kw, gs_kw, "sample.fcs")

  expect_equal(out$`$P1S`, "test_gt____")
  expect_equal(out$`$P2S`, "a_b_c")
})

test_that("build_sample_keywords handles compensated channels with sanitized labels", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  # Create a simple spillover matrix
  spill_mat <- matrix(c(1, 0.1, 0.1, 1), nrow = 2,
                      dimnames = list(c("FITC-A", "PE-A"), c("FITC-A", "PE-A")))

  fcs_kw <- list(
    `$PAR` = "2",
    `$P1N` = "FITC-A",
    `$P1S` = "NK1/1",        # problematic label with slash
    `$P1R` = "262144",
    `$P2N` = "PE-A",
    `$P2S` = "CD4/CD8",      # problematic label with slash
    `$P2R` = "262144",
    SPILL = "2,FITC-A,PE-A,1,0.1,0.1,1"
  )
  gs_kw <- list(SPILL = spill_mat)
  out <- CyFj11:::build_sample_keywords(fcs_kw, gs_kw, "sample.fcs")

  # Original channels should be sanitized
  expect_equal(out$`$P1S`, "NK1_1")
  expect_equal(out$`$P2S`, "CD4_CD8")

  # Compensated channels (P3, P4) should also have sanitized labels
  expect_equal(out$`$P3S`, "NK1_1")  # sanitized copy of P1S
  expect_equal(out$`$P4S`, "CD4_CD8")  # sanitized copy of P2S

  # Compensated channel names
  expect_equal(out$`$P3N`, "Comp-FITC-A")
  expect_equal(out$`$P4N`, "Comp-PE-A")
})
