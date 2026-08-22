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

# Internal helper tests for export-flowjo10.R aimed at increasing covr coverage.

skip_if_not_installed <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    skip(paste0(pkg, " package not available"))
  }
}

# =============================================================================
# export_flowjo10_workspace input validation
# =============================================================================

test_that("export_flowjo10_workspace validates required arguments", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")

  expect_error(CyFj11:::export_flowjo10_workspace(),
               "Missing required parameters: gating_set, output_path")

  expect_error(CyFj11:::export_flowjo10_workspace("not_a_gatingset", 123),
               "output_path must be a single character string")
})

# =============================================================================
# get_fcs_header_keywords
# =============================================================================

test_that("get_fcs_header_keywords handles edge cases", {
  skip_on_cran()
  skip_if_not_installed("flowCore")

  expect_null(CyFj11:::get_fcs_header_keywords(NULL))
  expect_null(CyFj11:::get_fcs_header_keywords("/nonexistent/path/file.fcs"))

  tmp <- tempfile(fileext = ".fcs")
  on.exit(unlink(tmp))
  ff <- flowCore::flowFrame(matrix(1:20, ncol = 2,
                                     dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  flowCore::write.FCS(ff, tmp)
  kw <- CyFj11:::get_fcs_header_keywords(tmp)
  expect_type(kw, "character")
  expect_true("$PAR" %in% names(kw))
})

# =============================================================================
# parse_spill_keyword
# =============================================================================

test_that("parse_spill_keyword handles all input forms", {
  skip_on_cran()

  # Standard flat string
  spill_str <- "3,FITC-A,PE-A,APC-A,1,0.1,0.2,0.05,1,0.15,0.1,0.05,1"
  mat <- CyFj11:::parse_spill_keyword(list(SPILL = spill_str))
  expect_equal(dim(mat), c(3, 3))
  expect_equal(colnames(mat), c("FITC-A", "PE-A", "APC-A"))

  # Matrix with only colnames
  mat_in <- matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                   dimnames = list(NULL, c("A", "B")))
  mat_out <- CyFj11:::parse_spill_keyword(list(SPILL = mat_in))
  expect_equal(rownames(mat_out), c("A", "B"))

  # Matrix with only rownames
  mat_in2 <- matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                    dimnames = list(c("A", "B"), NULL))
  mat_out2 <- CyFj11:::parse_spill_keyword(list(SPILL = mat_in2))
  expect_equal(colnames(mat_out2), c("A", "B"))

  # Character vector (length > 1)
  spill_vec <- c("2", "A", "B", "1", "0.1", "0.2", "1")
  mat_out3 <- CyFj11:::parse_spill_keyword(list(SPILL = spill_vec))
  expect_equal(dim(mat_out3), c(2, 2))

  # Invalid inputs
  expect_null(CyFj11:::parse_spill_keyword(list()))
  expect_null(CyFj11:::parse_spill_keyword(list(SPILL = "0,A,B")))
  expect_null(CyFj11:::parse_spill_keyword(list(SPILL = "2,A,B,1,0")))
  expect_null(CyFj11:::parse_spill_keyword(list(SPILL = "2,A,B,x,0,0,1")))
})

# =============================================================================
# build_sample_keywords
# =============================================================================

test_that("build_sample_keywords adds compensated parameters", {
  skip_on_cran()

  spill_mat <- matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                      dimnames = list(c("FITC-A", "PE-A"), c("FITC-A", "PE-A")))
  gs_kw <- list(`$PAR` = "2", SPILL = spill_mat)
  fcs_kw <- list(`$PAR` = "2", `$P1N` = "FITC-A", `$P2N` = "PE-A",
                 `$P1S` = "CD3", `$P1R` = "262144")

  out <- CyFj11:::build_sample_keywords(fcs_kw, gs_kw, "sample.fcs")
  expect_equal(out$FILENAME, "sample.fcs")
  expect_equal(out$`$P3N`, "Comp-FITC-A")
  expect_equal(out$`$P4N`, "Comp-PE-A")
  expect_equal(out$`$P3S`, "CD3")
  expect_equal(out$`$P3R`, "262144")
  expect_type(out$SPILL, "character")
})

test_that("build_sample_keywords strips Comp- prefix from SPILL string", {
  skip_on_cran()

  spill_str <- "2,Comp-FITC-A,Comp-PE-A,1,0.1,0.2,1"
  out <- CyFj11:::build_sample_keywords(list(), list(SPILL = spill_str), "s.fcs")
  expect_true(grepl("^2,FITC-A,PE-A", out$SPILL))
})

# =============================================================================
# build_spillover_matrix_xml
# =============================================================================

test_that("build_spillover_matrix_xml generates expected XML", {
  skip_on_cran()

  spill_mat <- matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                      dimnames = list(c("FITC-A", "PE-A"), c("FITC-A", "PE-A")))
  xml <- CyFj11:::build_spillover_matrix_xml(spill_mat, "mat-id", indent = "  ")
  expect_true(any(grepl("spilloverMatrix", xml, fixed = TRUE)))
  expect_true(any(grepl('parameter data-type:name="FITC-A"', xml, fixed = TRUE)))
  expect_true(any(grepl('coefficient data-type:parameter="PE-A"', xml, fixed = TRUE)))
  expect_true(any(grepl('transforms:value="0.1"', xml, fixed = TRUE)))
})

test_that("build_spillover_matrix_xml returns empty when input is NULL", {
  skip_on_cran()
  expect_length(CyFj11:::build_spillover_matrix_xml(NULL, "id"), 0)
})

# =============================================================================
# create_default_groups_v10
# =============================================================================

test_that("create_default_groups_v10 returns an All Samples group", {
  skip_on_cran()
  samples <- list(list(id = 1L), list(id = 2L))
  groups <- CyFj11:::create_default_groups_v10(samples)
  expect_equal(groups$all_samples$name, "All Samples")
  expect_equal(groups$all_samples$sample_ids, c(1L, 2L))
})

# =============================================================================
# get_referenced_channels
# =============================================================================

test_that("get_referenced_channels collects rectangle and polygon channels", {
  skip_on_cran()

  gates <- list(gates = list(
    gate1 = list(definition = list(
      type = "rectangle",
      dimensions = list(list(parameter = "FSC-A"), list(parameter = "SSC-A"))
    )),
    gate2 = list(definition = list(
      type = "polygon",
      x_param = "FITC-A", y_param = "PE-A"
    )),
    gate3 = list(definition = NULL)
  ))
  ch <- CyFj11:::get_referenced_channels(gates)
  expect_setequal(ch, c("FSC-A", "SSC-A", "FITC-A", "PE-A"))

  expect_length(CyFj11:::get_referenced_channels(list()), 0)
  expect_length(CyFj11:::get_referenced_channels(list(gates = list())), 0)
})

# =============================================================================
# get_graph_axes
# =============================================================================

test_that("get_graph_axes falls back through children, self, parent, default", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:30, ncol = 3,
                         dimnames = list(NULL, c("FSC-A", "SSC-A", "FITC-A"))))
  gs <- GatingSet(flowSet(ff))

  # Parent gate on FSC-A/SSC-A
  g_parent <- rectangleGate(list(`FSC-A` = c(1, 100), `SSC-A` = c(1, 100)),
                           filterId = "parent")
  gs_pop_add(gs, g_parent, parent = "root")

  # Child gate on FITC-A (histogram/1D)
  g_child <- rectangleGate(`FITC-A` = c(1, 100), filterId = "child")
  gs_pop_add(gs, g_child, parent = "parent")
  recompute(gs)

  axes <- CyFj11:::get_graph_axes(gs[[1]], "/parent/child")
  expect_true("FITC-A" %in% axes)

  # A leaf population with no children returns its own dimensions
  gs_pop_add(gs, rectangleGate(`FSC-A` = c(1, 100), filterId = "leaf"),
             parent = "root")
  recompute(gs)
  axes_leaf <- CyFj11:::get_graph_axes(gs[[1]], "/leaf")
  expect_setequal(as.character(axes_leaf), c("FSC-A"))
})

test_that("get_graph_axes returns defaults when nothing else works", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  expect_equal(CyFj11:::get_graph_axes(gs[[1]], "root"), c("FSC-A", "SSC-A"))
})

# =============================================================================
# convert_rectangle_to_flowjo10 validation branches
# =============================================================================

test_that("convert_rectangle_to_flowjo10 returns NULL for invalid rectangle gates", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  library(flowCore)

  # Length mismatch between parameters and min/max vectors
  bad <- rectangleGate(`FSC-A` = c(1, 2), filterId = "g")
  bad@max <- c(2, 3)
  expect_null(CyFj11:::convert_rectangle_to_flowjo10(bad, "bad"))
})

test_that("convert_rectangle_to_flowjo10 back-transforms non-log transforms", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:100, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "FITC-A"))))
  gs <- GatingSet(flowSet(ff))

  # logicle
  ltrans <- logicle_trans(t = 262144, w = 0.5, m = 4.5, a = 0)
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", ltrans))

  gate <- rectangleGate(`FITC-A` = c(0.1, 0.9), filterId = "logicle_rect")
  out <- CyFj11:::convert_rectangle_to_flowjo10(gate, "logicle_rect", gs[[1]])
  expect_equal(out$type, "rectangle")
})

# =============================================================================
# convert_polygon_to_flowjo10 validation and transform branches
# =============================================================================

test_that("convert_polygon_to_flowjo10 back-transforms with gating hierarchy", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:100, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "FITC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logtGml2_trans()))

  verts <- matrix(c(0.1, 0.1, 0.9, 0.1, 0.9, 0.9), ncol = 2,
                  dimnames = list(NULL, c("FSC-A", "FITC-A")))
  gate <- polygonGate(.gate = verts, filterId = "log_poly")
  out <- CyFj11:::convert_polygon_to_flowjo10(gate, "log_poly", gs[[1]])
  expect_equal(out$type, "polygon")
  expect_length(out$vertices, 3)
})

# =============================================================================
# convert_ellipsoid_to_flowjo10 branches
# =============================================================================

test_that("convert_ellipsoid_to_flowjo10 returns NULL for non-ellipsoid gates", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  library(flowCore)

  bad <- rectangleGate(`FSC-A` = c(1, 2), filterId = "rect")
  expect_null(CyFj11:::convert_ellipsoid_to_flowjo10(bad, "bad"))
})

test_that("convert_ellipsoid_to_flowjo10 converts display coordinates", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:100, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))

  cov <- matrix(c(1e8, 0, 0, 1e8), nrow = 2,
                dimnames = list(c("FSC-A", "SSC-A"), c("FSC-A", "SSC-A")))
  eg <- ellipsoidGate(cov, mean = c(50, 50), distance = 2, filterId = "e")
  out <- CyFj11:::convert_ellipsoid_to_flowjo10(eg, "e", gs[[1]])
  expect_equal(out$type, "ellipsoid")
  expect_true(all(vapply(out$foci, function(p) is.numeric(p$x) && is.numeric(p$y),
                         logical(1))))
})

# =============================================================================
# convert_boolean_to_flowjo10 branches
# =============================================================================

test_that("convert_boolean_to_flowjo10 returns NULL for missing expression", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  library(flowWorkspace)

  bf <- booleanFilter(`A` & `B`, filterId = "ok")
  attr(bf, "expr") <- NULL
  expect_null(CyFj11:::convert_boolean_to_flowjo10(bf, "ok"))
})

test_that("convert_boolean_to_flowjo10 resolves parent & !child expressions", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs_pop_add(gs, rectangleGate(`FSC-A` = c(1, 100), filterId = "parent"),
             parent = "root")
  gs_pop_add(gs, rectangleGate(`SSC-A` = c(1, 100), filterId = "child"),
             parent = "parent")

  # Add the boolean filter as a population under "parent" so its parent path is known
  bf <- booleanFilter(`parent` & !`child`, filterId = "not_child")
  gs_pop_add(gs, bf, parent = "parent")
  recompute(gs)

  out <- CyFj11:::convert_boolean_to_flowjo10(bf, "not_child", gs[[1]])
  expect_equal(out$type, "boolean")
  expect_equal(out$op_type, "not")
})

# =============================================================================
# generate_logical_node_xml
# =============================================================================

test_that("generate_logical_node_xml produces AndNode, OrNode, and NotNode", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs_pop_add(gs, rectangleGate(`FSC-A` = c(1, 100), filterId = "A"),
             parent = "root")
  gs_pop_add(gs, rectangleGate(`SSC-A` = c(1, 100), filterId = "B"),
             parent = "root")
  recompute(gs)

  for (op in c("and", "or", "not")) {
    def <- list(type = "boolean", op_type = op,
                dependents = if (op == "not") "A" else c("A", "B"),
                expression = "expr")
    gate <- list(definition = def, id = "ID1")
    xml <- CyFj11:::generate_logical_node_xml(
      gate, "bool_pop", "/bool_pop", indent = "  ", gh = gs[[1]]
    )
    expect_true(any(grepl(paste0(toupper(substring(op, 1, 1)),
                                 substring(op, 2), "Node"), xml)))
  }
})

# =============================================================================
# generate_flowjo10_xml minimal branch
# =============================================================================

test_that("generate_flowjo10_xml minimal_fj11 branch works", {
  skip_on_cran()
  xml <- CyFj11:::generate_flowjo10_xml(
    gating_set = NULL, samples = list(), gates = list(),
    populations = list(), groups = list(),
    workspace_name = "test", output_path = "test.wsp",
    minimal_fj11 = TRUE
  )
  expect_true(grepl("Workspace", xml))
  expect_true(grepl("Matrices", xml))
})

# =============================================================================
# format_gate_num
# =============================================================================

test_that("format_gate_num handles edge cases", {
  skip_on_cran()
  expect_equal(CyFj11:::format_gate_num(NULL), "0")
  expect_equal(CyFj11:::format_gate_num(NA_real_), "0")
  expect_equal(CyFj11:::format_gate_num(Inf), "262144")
  expect_equal(CyFj11:::format_gate_num(-Inf), "0")
  expect_equal(CyFj11:::format_gate_num(1.23456789012345), "1.23456789012345")
})

# =============================================================================
# get_display_range
# =============================================================================

test_that("get_display_range handles scatter channels with negative values", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  mat <- matrix(c(-100, 1, 200, 2), ncol = 2,
                dimnames = list(NULL, c("FSC-A", "SSC-A")))
  ff <- flowFrame(mat)
  gs <- GatingSet(flowSet(ff))
  rng <- CyFj11:::get_display_range(gs[[1]], "FSC-A")
  expect_length(rng, 2)
  expect_true(rng[1] < 0)
})

test_that("get_display_range falls back when parameter is missing", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  expect_equal(CyFj11:::get_display_range(gs[[1]], "MISSING"), c(0, 262144))
})

# =============================================================================
# emit_transform_xml
# =============================================================================

test_that("emit_transform_xml emits biex, log, fasinh, and linear XML", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  # biex
  bi <- flowjo_biexp_trans(channelRange = 4096, maxValue = 262144,
                           pos = 4.5, neg = 0, widthBasis = -10)
  xml <- CyFj11:::emit_transform_xml(
    "biexp", "FITC-A", bi, attributes(bi), c(0, 262144), indent = "  "
  )
  expect_true(any(grepl("transforms:biex", xml, fixed = TRUE)))

  # log
  lg <- flowjo_log_trans(decade = 4, offset = 1)
  xml <- CyFj11:::emit_transform_xml(
    "log", "FITC-A", lg, attributes(lg), c(0, 262144), indent = "  "
  )
  expect_true(any(grepl("transforms:log", xml, fixed = TRUE)))

  # fasinh
  fs <- flowjo_fasinh_trans(m = 1, t = 10, a = 1)
  xml <- CyFj11:::emit_transform_xml(
    "fasinh", "FITC-A", fs, attributes(fs), c(0, 262144), indent = "  "
  )
  expect_true(any(grepl("transforms:fasinh", xml, fixed = TRUE)))

  # linear
  xml <- CyFj11:::emit_transform_xml(
    "linear", "FSC-A", NULL, list(), c(0, 262144), indent = "  "
  )
  expect_true(any(grepl("transforms:linear", xml, fixed = TRUE)))
})

test_that("emit_transform_xml warns and returns empty for unsupported type", {
  skip_on_cran()
  expect_warning(
    out <- CyFj11:::emit_transform_xml("unknown", "X", NULL, list(), c(0, 1)),
    "not implemented"
  )
  expect_length(out, 0)
})

# =============================================================================
# derive_cytometer_attrs
# =============================================================================

test_that("derive_cytometer_attrs detects BD FACSDiva", {
  skip_on_cran()
  kw <- list(`$CYT` = "BD FACSDiva")
  attrs <- CyFj11:::derive_cytometer_attrs(kw)
  expect_equal(attrs$name, "DIVA")
  expect_equal(attrs$useTransform, "1")
  expect_equal(attrs$transformType, "BIEX")
})

test_that("derive_cytometer_attrs returns defaults for empty keywords", {
  skip_on_cran()
  attrs <- CyFj11:::derive_cytometer_attrs(list())
  expect_equal(attrs$name, "GENERIC")
  expect_equal(attrs$useTransform, "0")
})

# =============================================================================
# write_fcs_files_to_dir branches
# =============================================================================

test_that("write_fcs_files_to_dir copies when source file exists", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  tmp_src <- tempfile()
  dir.create(tmp_src)
  on.exit(unlink(tmp_src, recursive = TRUE))

  src_file <- file.path(tmp_src, "sample.fcs")
  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  flowCore::write.FCS(ff, src_file)

  # Create GatingSet with FILENAME pointing to the existing file
  gs <- GatingSet(flowSet(ff))
  keyword(ff)[["FILENAME"]] <- src_file
  keyword(ff)[["$FIL"]] <- "sample.fcs"
  cs <- flowSet(ff)
  sampleNames(cs) <- "sample.fcs"
  gs <- GatingSet(cs)

  dest_dir <- tempfile()
  dir.create(dest_dir)
  on.exit(unlink(dest_dir, recursive = TRUE), add = TRUE)

  paths <- CyFj11:::write_fcs_files_to_dir(gs, dest_dir, overwrite = FALSE)
  expect_true(file.exists(paths[1]))
})

test_that("write_fcs_files_to_dir errors on existing files without overwrite", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  cs <- flowSet(ff)
  sampleNames(cs) <- "sample.fcs"
  gs <- GatingSet(cs)

  # Write once
  CyFj11:::write_fcs_files_to_dir(gs, tmp, overwrite = FALSE)

  # Second call should error
  expect_error(
    CyFj11:::write_fcs_files_to_dir(gs, tmp, overwrite = FALSE),
    "FCS file\\(s\\) already exist"
  )
})

# =============================================================================
# generate_sample_subpopulations_xml recursion
# =============================================================================

test_that("generate_sample_subpopulations_xml recurses for nested gates", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:100, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs_pop_add(gs, rectangleGate(`FSC-A` = c(1, 100), filterId = "parent"),
             parent = "root")
  gs_pop_add(gs, rectangleGate(`SSC-A` = c(1, 100), filterId = "child"),
             parent = "parent")
  recompute(gs)

  # Suppress warnings about no transformations found (normal for synthetic data)
  gates <- suppressWarnings(
    CyFj11:::extract_gates_from_gatingset_v10(gs)
  )
  pops <- CyFj11:::extract_populations_from_gatingset_v10(
    gs,
    CyFj11:::extract_samples_from_gatingset_v10(gs),
    gates
  )

  xml <- CyFj11:::generate_sample_subpopulations_xml(
    gs[[1]], gates, pops, parent_path = "root", indent = "        ",
    heat_map_param = ""
  )
  expect_true(any(grepl("Population", xml, fixed = TRUE)))
  expect_true(any(grepl("Subpopulations", xml, fixed = TRUE)))
})

# =============================================================================
# generate_group_subpopulations_xml recursion and cycles
# =============================================================================

test_that("generate_group_subpopulations_xml detects cycles", {
  skip_on_cran()

  populations <- list(
    pop1 = list(id = "pop1", name = "A", sample_id = 1L,
                parent_path = "root", gate_id = NULL, count = 1L),
    pop2 = list(id = "pop2", name = "B", sample_id = 1L,
                parent_path = "A", gate_id = NULL, count = 1L)
  )
  # Force a cycle by making B its own parent
  populations$pop2$parent_path <- "B"

  xml <- CyFj11:::generate_group_subpopulations_xml(
    populations, list(gates = list()), parent_path = "B",
    visited_paths = c("A", "B"), gh = NULL
  )
  expect_length(xml, 0)
})

# =============================================================================
# extract_samples_from_gatingset_v10 keyword reconstruction
# =============================================================================

test_that("extract_samples_from_gatingset_v10 reconstructs keywords from FCS file", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  fcs_file <- file.path(tmp, "sample.fcs")
  flowCore::write.FCS(ff, fcs_file)

  # Read back into a GatingSet so FILENAME keyword points to a real file
  fs <- read.flowSet(fcs_file)
  gs <- GatingSet(fs)

  samples <- CyFj11:::extract_samples_from_gatingset_v10(gs, target_fcs_dir = tmp)
  expect_length(samples, 1)
  expect_equal(samples[[1]]$name, "sample.fcs")
  expect_type(samples[[1]]$keywords, "list")
  expect_true("$PAR" %in% names(samples[[1]]$keywords))
})

# =============================================================================
# export_flowjo10_workspace with fcs_root writes FCS files
# =============================================================================

test_that("export_flowjo10_workspace writes FCS files when fcs_root is supplied", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  tmp_src <- tempfile()
  dir.create(tmp_src)
  on.exit(unlink(tmp_src, recursive = TRUE))

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  fcs_file <- file.path(tmp_src, "sample.fcs")
  flowCore::write.FCS(ff, fcs_file)

  fs <- read.flowSet(fcs_file)
  gs <- GatingSet(fs)

  tmp_dest <- tempfile()
  dir.create(tmp_dest)
  on.exit(unlink(tmp_dest, recursive = TRUE), add = TRUE)

  out_wsp <- file.path(tmp_dest, "out.wsp")
  expect_true(CyFj11:::export_flowjo10_workspace(
    gs, out_wsp, fcs_root = tmp_dest, overwrite = FALSE
  ))
  expect_true(file.exists(out_wsp))
  expect_true(file.exists(file.path(tmp_dest, "sample.fcs")))
})

# =============================================================================
# generate_logical_node_xml direct calls
# =============================================================================

test_that("generate_logical_node_xml copies dependent gate for NotNode", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs_pop_add(gs, rectangleGate(`FSC-A` = c(1, 100), filterId = "dep"),
             parent = "root")
  recompute(gs)

  # Build a gates list that references the dependent rectangle gate
  gate_def <- list(type = "boolean", op_type = "not",
                   dependents = "dep", expression = "!dep")
  gates <- list(gates = list(
    dep_gate = list(
      id = "ID_dep",
      name = "dep",
      population_path = "/dep",
      definition = list(
        type = "rectangle",
        dimensions = list(list(parameter = "FSC-A", min = 1, max = 100))
      )
    ),
    bool_gate = list(definition = gate_def, id = "ID_bool")
  ))

  xml <- CyFj11:::generate_logical_node_xml(
    gate = gates$gates$bool_gate,
    pop_name = "not_dep",
    child_path = "/not_dep",
    indent = "  ",
    gh = gs[[1]],
    gates = gates
  )
  expect_true(any(grepl("NotNode", xml, fixed = TRUE)))
  expect_true(any(grepl("RectangleGate", xml, fixed = TRUE)))
})

# =============================================================================
# generate_sample_subpopulations_xml with polygon and ellipsoid gates
# =============================================================================

test_that("generate_sample_subpopulations_xml handles polygon and ellipsoid gates", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:100, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))

  # Polygon gate
  poly <- polygonGate(
    .gate = matrix(c(0, 0, 50, 0, 50, 50), ncol = 2,
                   dimnames = list(NULL, c("FSC-A", "SSC-A"))),
    filterId = "poly"
  )
  gs_pop_add(gs, poly, parent = "root")

  # Ellipsoid gate
  cov <- matrix(c(1e8, 0, 0, 1e8), nrow = 2,
                dimnames = list(c("FSC-A", "SSC-A"), c("FSC-A", "SSC-A")))
  eg <- ellipsoidGate(cov, mean = c(50, 50), distance = 2, filterId = "ellipse")
  gs_pop_add(gs, eg, parent = "root")
  recompute(gs)

  # Expect warnings about no transformations and ellipsoid transformation
  gates <- suppressWarnings(
    CyFj11:::extract_gates_from_gatingset_v10(gs)
  )
  pops <- CyFj11:::extract_populations_from_gatingset_v10(
    gs,
    CyFj11:::extract_samples_from_gatingset_v10(gs),
    gates
  )

  xml <- CyFj11:::generate_sample_subpopulations_xml(
    gs[[1]], gates, pops, parent_path = "root", indent = "        ",
    heat_map_param = ""
  )
  expect_true(any(grepl("PolygonGate", xml, fixed = TRUE)))
  expect_true(any(grepl("EllipsoidGate", xml, fixed = TRUE)))
})

# =============================================================================
# generate_group_subpopulations_xml direct calls
# =============================================================================

test_that("generate_group_subpopulations_xml emits regular and boolean populations", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs_pop_add(gs, rectangleGate(`FSC-A` = c(1, 100), filterId = "A"),
             parent = "root")
  recompute(gs)

  populations <- list(
    pop_A = list(id = "pop_A", name = "A", sample_id = 1L,
                 parent_path = "root", gate_id = "gate_A", count = 10L),
    pop_B = list(id = "pop_B", name = "B", sample_id = 1L,
                 parent_path = "A", gate_id = "gate_B", count = 5L)
  )
  gates <- list(gates = list(
    gate_A = list(
      id = "ID_A", name = "A", population_path = "/A",
      definition = list(
        type = "rectangle",
        dimensions = list(list(parameter = "FSC-A", min = 1, max = 100))
      )
    ),
    gate_B = list(
      id = "ID_B", name = "B", population_path = "/A/B",
      definition = list(type = "boolean", op_type = "not",
                        dependents = "A", expression = "!A")
    )
  ))

  xml_root <- CyFj11:::generate_group_subpopulations_xml(
    populations, gates, parent_path = "root", indent = "        ", gh = gs[[1]]
  )
  expect_true(any(grepl("Population", xml_root, fixed = TRUE)))

  # Call directly at level A to avoid cycle guard on visited paths
  xml_A <- CyFj11:::generate_group_subpopulations_xml(
    populations, gates, parent_path = "A", indent = "        ", gh = gs[[1]]
  )
  expect_true(any(grepl("NotNode", xml_A, fixed = TRUE)))
})

# =============================================================================
# generate_flowjo10_xml with compensation matrix
# =============================================================================

test_that("generate_flowjo10_xml includes spillover matrix when present", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FITC-A", "PE-A"))))
  fcs_file <- file.path(tmp, "sample.fcs")
  flowCore::write.FCS(ff, fcs_file)

  fs <- read.flowSet(fcs_file)
  gs <- GatingSet(fs)

  samples <- CyFj11:::extract_samples_from_gatingset_v10(gs, target_fcs_dir = tmp)
  # Inject a spill matrix so the XML path is exercised
  spill_mat <- matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                      dimnames = list(c("FITC-A", "PE-A"), c("FITC-A", "PE-A")))
  samples[[1]]$spill_matrix <- spill_mat

  gates <- CyFj11:::extract_gates_from_gatingset_v10(gs)
  pops <- CyFj11:::extract_populations_from_gatingset_v10(gs, samples, gates)
  groups <- CyFj11:::create_default_groups_v10(samples)

  xml <- CyFj11:::generate_flowjo10_xml(
    gating_set = gs, samples = samples, gates = gates,
    populations = pops, groups = groups,
    workspace_name = "test", output_path = "test.wsp"
  )
  expect_true(grepl("spilloverMatrix", xml, fixed = TRUE))
  expect_true(grepl("Comp-FITC-A", xml, fixed = TRUE))
})

# =============================================================================
# build_sample_keywords additional branches
# =============================================================================

test_that("build_sample_keywords handles missing gs or fcs keywords", {
  skip_on_cran()

  out1 <- CyFj11:::build_sample_keywords(NULL, list(`$PAR` = "1"), "s.fcs")
  expect_equal(out1$FILENAME, "s.fcs")

  out2 <- CyFj11:::build_sample_keywords(list(`$TOT` = "100"), NULL, "s.fcs")
  expect_equal(out2$FILENAME, "s.fcs")
  expect_equal(out2$`$TOT`, "100")
})

# =============================================================================
# get_transform_spec additional branches
# =============================================================================

test_that("get_transform_spec returns linear for untransformed channels", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "FITC-A"))))
  gs <- GatingSet(flowSet(ff))
  # Transform only FITC-A, then ask about FSC-A
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logtGml2_trans()))

  out <- CyFj11:::get_transform_spec(gs[[1]], "FSC-A")
  expect_equal(out$transformType, "Linear")
})

# =============================================================================
# convert_boolean_to_flowjo10 OR and parent resolution
# =============================================================================

test_that("convert_boolean_to_flowjo10 resolves full paths via gh", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  ff <- flowFrame(matrix(1:20, ncol = 2,
                         dimnames = list(NULL, c("FSC-A", "SSC-A"))))
  gs <- GatingSet(flowSet(ff))
  gs_pop_add(gs, rectangleGate(`FSC-A` = c(1, 100), filterId = "A"),
             parent = "root")
  gs_pop_add(gs, rectangleGate(`SSC-A` = c(1, 100), filterId = "B"),
             parent = "root")
  recompute(gs)

  bf <- booleanFilter(`A` | `B`, filterId = "AorB")
  out <- CyFj11:::convert_boolean_to_flowjo10(bf, "AorB", gs[[1]])
  expect_equal(out$op_type, "or")
  expect_true("A" %in% out$dependents && "B" %in% out$dependents)
})
