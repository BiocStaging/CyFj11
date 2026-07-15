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

# Unit tests for compensation and population helper functions.

test_that("extract_compensation_from_platforms extracts from compSpec", {
  spill <- list(
    comp_uuid_1 = list(
      definition = list(
        compSpec = list(
          CompensationSpec = list(
            coefficients = list(c(100, 10), c(20, 100)),
            detectors = list(list(name = "FSC-A"), list(name = "SSC-A"))
          )
        )
      )
    )
  )
  out <- CyFj11:::extract_compensation_from_platforms(spill)
  expect_s4_class(out, "compensation")
  expect_equal(colnames(out@spillover), c("FSC-A", "SSC-A"))
})

test_that("extract_compensation_from_platforms extracts from spillover", {
  spill <- list(
    comp_uuid_1 = list(
      spillover = list(
        columns = c("FSC-A", "SSC-A"),
        values = list(c(100, 10), c(20, 100))
      )
    )
  )
  out <- CyFj11:::extract_compensation_from_platforms(spill)
  expect_s4_class(out, "compensation")
  expect_equal(colnames(out@spillover), c("FSC-A", "SSC-A"))
})

test_that("extract_compensation_from_platforms maps samples via dataSources", {
  spill <- list(
    comp_uuid_1 = list(
      spillover = list(
        columns = c("FSC-A", "SSC-A"),
        values = list(c(1, 0), c(0, 1))
      )
    )
  )
  dataSources <- list(
    sample_1 = list(parents = list(platforms = list("comp_uuid_1")))
  )
  out <- CyFj11:::extract_compensation_from_platforms(
    spill, dataSources, "sample_1"
  )
  expect_s4_class(out[["sample_1"]], "compensation")
})

test_that("extract_compensation_from_platforms returns NULL when empty", {
  expect_null(CyFj11:::extract_compensation_from_platforms(list()))
})

test_that("extract_workspace_compensation extracts from customKeywords", {
  ds <- list(
    definition = list(
      customKeywords = list(
        SPILL = "2,F,G,1,0.1,0.2,1"
      )
    )
  )
  out <- CyFj11:::extract_workspace_compensation(ds)
  expect_s4_class(out, "compensation")
})

test_that("extract_compensation applies custom compensation per sample", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  dataSources <- list(
    sample_1 = list(definition = list(customKeywords = list())),
    sample_2 = list(definition = list(customKeywords = list()))
  )
  custom <- list(
    sample_1 = matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                      dimnames = list(c("A", "B"), c("A", "B")))
  )
  out <- expect_warning(
    CyFj11:::extract_compensation(
      dataSources, c("sample_1", "sample_2"), custom_compensation = custom
    ),
    "No compensation found for sample"
  )
  expect_s4_class(out[["sample_1"]], "compensation")
  expect_null(out[["sample_2"]])

  expect_warning(
    out2 <- CyFj11:::extract_compensation(
      dataSources, c("sample_1", "sample_2"), custom_compensation = list()
    ),
    "No compensation found for sample"
  )
  expect_null(out2[["sample_1"]])
  expect_null(out2[["sample_2"]])
})

test_that("adjust_gate_transformations updates parameter names", {
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  mat <- matrix(1:100, ncol = 2, dimnames = list(NULL, c("FSC-A", "SSC-A")))
  gs <- GatingSet(flowSet(flowFrame(mat)))
  gh <- gs[[1]]

  gate <- rectangleGate(`FSC-A` = c(10, 90), filterId = "rect")
  out <- CyFj11:::adjust_gate_transformations(gh, gate, strip_comp_prefix = TRUE)
  expect_s4_class(out, "rectangleGate")
})

test_that("update_gate_param_names handles rectangle, polygon, quad, and ellipsoid gates", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  mapping <- list(`FSC-A` = "FSC_A", `SSC-A` = "SSC_A")

  rect <- rectangleGate(list(`FSC-A` = c(1, 2), `SSC-A` = c(1, 2)), filterId = "r")
  out <- CyFj11:::update_gate_param_names(rect, mapping)
  expect_equal(names(out@min), c("FSC_A", "SSC_A"))

  poly <- polygonGate(
    matrix(c(0, 0, 1, 0, 1, 1, 0, 1), ncol = 2,
           dimnames = list(NULL, c("FSC-A", "SSC-A"))),
    filterId = "p"
  )
  out <- CyFj11:::update_gate_param_names(poly, mapping)
  expect_equal(unname(colnames(out@boundaries)), c("FSC_A", "SSC_A"))

  quad <- quadGate(`FSC-A` = 0.5, `SSC-A` = 0.5, filterId = "q")
  out <- CyFj11:::update_gate_param_names(quad, mapping)
  expect_equal(names(out@boundary), c("FSC_A", "SSC_A"))

  cov <- matrix(c(1, 0, 0, 1), nrow = 2,
                dimnames = list(c("FSC-A", "SSC-A"), c("FSC-A", "SSC-A")))
  ell <- ellipsoidGate(cov, mean = c(0, 0), distance = 1, filterId = "e")
  out <- CyFj11:::update_gate_param_names(ell, mapping)
  expect_equal(names(out@mean), c("FSC_A", "SSC_A"))
})

test_that("apply_transforms_to_gate applies linear transformation", {
  skip_if_not_installed("flowCore")
  library(flowCore)

  gate <- rectangleGate(`FSC-A` = c(0, 1), filterId = "r")
  trans <- function(x) x * 10
  trans_list <- list(`FSC-A` = trans)

  out <- CyFj11:::apply_transforms_to_gate(gate, trans_list)
  expect_equal(out@min[["FSC-A"]], 0)
  expect_equal(out@max[["FSC-A"]], 10)
})

test_that("add_populations_to_gatingset adds simple gate tree", {
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  library(flowCore)
  library(flowWorkspace)

  mat <- matrix(1:100, ncol = 2, dimnames = list(NULL, c("FSC-A", "SSC-A")))
  gs <- GatingSet(flowSet(flowFrame(mat)))

  gate <- rectangleGate(`FSC-A` = c(10, 90), filterId = "cells")
  gates <- list(`sample_1_cells_sample_1` = gate)
  tree <- list(
    name = "cells",
    definition_uuid = "sample_1_cells",
    type = "RectangleGate",
    children = list()
  )

  CyFj11:::add_populations_to_gatingset(
    gs, list(sample_1 = tree), gates, sample_uuids = "sample_1"
  )
  expect_true("/cells" %in% gs_get_pop_paths(gs[[1]]))
})
