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

#' @title Unit Tests for Quadrant Gate Handling
#' @name test-quad-gate
#' @keywords internal
NULL

skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

test_that("convert_quadrant_gate produces a valid quadGate object", {
  x_param <- "FSC-H"
  y_param <- "SSC-H"
  x_div <- 500
  y_div <- 200

  gate <- list(
    xParameter = x_param,
    yParameter = y_param,
    xDivider = x_div,
    yDivider = y_div
  )

  pop_names <- c("FSC-H+SSC-H+", "FSC-H+SSC-H-", "FSC-H-SSC-H+", "FSC-H-SSC-H-")

  qg <- CyFj11:::convert_quadrant_gate(
    gate = gate,
    pop_name = pop_names,
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(qg, "quadGate")
  expect_equal(names(qg@boundary), c(x_param, y_param))
  expect_equal(unname(qg@boundary), c(x_div, y_div))
  expect_equal(attr(qg, "pop_names"), rev(pop_names))
})

test_that("convert_quadrant_gate errors when parameters are missing", {
  bad_gate <- list(
    xParameter = "FSC-H",
    yParameter = "",
    xDivider = 500,
    yDivider = 200
  )

  expect_error(
    CyFj11:::convert_quadrant_gate(
      gate = bad_gate,
      pop_name = c("A", "B", "C", "D"),
      extend_val = 0,
      extend_to = -4000
    ),
    "missing valid parameters"
  )
})

test_that("convert_quadrant_gate errors without four population names", {
  gate <- list(
    xParameter = "FSC-H",
    yParameter = "SSC-H",
    xDivider = 500,
    yDivider = 200
  )

  expect_error(
    CyFj11:::convert_quadrant_gate(
      gate = gate,
      pop_name = c("A", "B", "C"),
      extend_val = 0,
      extend_to = -4000
    ),
    "exactly 4 populations"
  )
})

test_that("quadGate can be added to a GatingHierarchy with four populations", {
  data("GvHD", package = "flowCore")
  ff <- GvHD[[1]]

  # Use parameters that are present in the example data.
  x_param <- "FSC-H"
  y_param <- "SSC-H"
  x_div <- 500
  y_div <- 200

  gate <- list(
    xParameter = x_param,
    yParameter = y_param,
    xDivider = x_div,
    yDivider = y_div
  )

  pop_names <- c("FSC-H+SSC-H+", "FSC-H+SSC-H-", "FSC-H-SSC-H+", "FSC-H-SSC-H-")
  qg <- CyFj11:::convert_quadrant_gate(
    gate = gate,
    pop_name = pop_names,
    extend_val = 0,
    extend_to = -4000
  )

  gs <- GatingSet(flowSet(ff))
  node_ids <- gs_pop_add(gs, qg, parent = "root", name = pop_names)
  recompute(gs)

  expect_length(node_ids, 4L)
  expect_true(all(paste0("/", pop_names) %in% gs_get_pop_paths(gs[[1]])))

  counts <- gs_pop_get_count_fast(gs)
  expect_gt(sum(counts$Count), 0L)
})

test_that("update_gate_param_names handles quadGate boundaries", {
  mapping <- list(`FSC-H` = "FSC_H", `SSC-H` = "SSC_H")
  qg <- quadGate(`FSC-H` = 500, `SSC-H` = 200, filterId = "q")

  out <- CyFj11:::update_gate_param_names(qg, mapping)

  expect_s4_class(out, "quadGate")
  expect_equal(names(out@boundary), c("FSC_H", "SSC_H"))
})

test_that("apply_transforms_to_gate applies transformation to quadGate boundary", {
  qg <- quadGate(`FSC-H` = 500, `SSC-H` = 200, filterId = "q")
  trans <- function(x) x * 10
  trans_list <- list(`FSC-H` = trans)

  out <- CyFj11:::apply_transforms_to_gate(qg, trans_list)

  expect_s4_class(out, "quadGate")
  expect_equal(out@boundary[["FSC-H"]], 5000)
  expect_equal(out@boundary[["SSC-H"]], 200)
})

test_that("add_population_node adds a quadGate to a GatingHierarchy", {
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  sample_uuid <- "sample-1"
  def_uuid <- "quad-def-uuid"

  qg <- quadGate(`FSC-H` = 500, `SSC-H` = 200, filterId = "q")
  gates <- list()
  gates[[paste0(def_uuid, "_", sample_uuid)]] <- qg

  pop_names <- c("FSC-H+SSC-H+", "FSC-H+SSC-H-", "FSC-H-SSC-H+", "FSC-H-SSC-H-")
  node <- list(
    name = pop_names,
    type = "QuadrantGate",
    definition_uuid = def_uuid,
    children = list()
  )

  expect_no_error(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = gates,
      sample_uuid = sample_uuid,
      parent = "root"
    )
  )

  # add_population_node reorders quadGate names as node_name[c(3,4,2,1)]
  expected_order <- pop_names[c(3, 4, 2, 1)]
  expect_true(all(paste0("/", expected_order) %in% gs_get_pop_paths(gh)))
})
