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

#' @title Unit Tests for Polygon and Logical Gate Handling
#' @name test-polygon-and-logical-gates
#' @keywords internal
NULL

skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

# ============================================================================
# Tests for update_gate_param_names with polygonGate
# ============================================================================

test_that("update_gate_param_names handles polygonGate boundaries", {
  # Create a simple polygon gate with two parameters (polygonGate requires exactly 2 columns)
  boundaries <- matrix(c(100, 200, 300, 150, 250, 350), ncol = 2)
  colnames(boundaries) <- c("FSC-H", "SSC-H")

  pg <- polygonGate(.gate = boundaries, filterId = "poly")

  # Mapping with Comp- prefix removal and slash sanitization
  mapping <- list(`FSC-H` = "FSC_H", `SSC-H` = "SSC_H")

  out <- CyFj11:::update_gate_param_names(pg, mapping)

  expect_s4_class(out, "polygonGate")
  # Check boundary column names which are updated by the function
  # Note: unname() is needed because colnames<- preserves names attribute from named vectors
  expect_equal(unname(colnames(out@boundaries)), c("FSC_H", "SSC_H"))
})

test_that("update_gate_param_names handles polygonGate with partial mapping", {
  # Create a polygon gate with two parameters
  boundaries <- matrix(c(100, 200, 300, 150, 250, 350), ncol = 2)
  colnames(boundaries) <- c("FSC-H", "SSC-H")

  pg <- polygonGate(.gate = boundaries, filterId = "poly")

  # Only map one of the two parameters
  mapping <- list(`FSC-H` = "FSC_H")

  out <- CyFj11:::update_gate_param_names(pg, mapping)

  expect_s4_class(out, "polygonGate")
  # Only mapped parameters should be renamed
  expect_equal(unname(colnames(out@boundaries)), c("FSC_H", "SSC-H"))
})

test_that("update_gate_param_names returns original when mapping is empty", {
  boundaries <- matrix(c(100, 200, 300, 150, 250, 350), ncol = 2)
  colnames(boundaries) <- c("FSC-H", "SSC-H")

  pg <- polygonGate(.gate = boundaries, filterId = "poly")

  # Empty mapping
  mapping <- list()

  out <- CyFj11:::update_gate_param_names(pg, mapping)

  expect_s4_class(out, "polygonGate")
  expect_equal(unname(colnames(out@boundaries)), c("FSC-H", "SSC-H"))
})

test_that("update_gate_param_names handles polygonGate with Comp- prefix", {
  boundaries <- matrix(c(100, 200, 300, 150, 250, 350), ncol = 2)
  colnames(boundaries) <- c("Comp-FSC-H", "Comp-SSC-H")

  pg <- polygonGate(.gate = boundaries, filterId = "poly")

  # Mapping strips Comp- prefix
  mapping <- list(`Comp-FSC-H` = "FSC-H", `Comp-SSC-H` = "SSC-H")

  out <- CyFj11:::update_gate_param_names(pg, mapping)

  expect_s4_class(out, "polygonGate")
  expect_equal(unname(colnames(out@boundaries)), c("FSC-H", "SSC-H"))
})

# ============================================================================
# Tests for update_gate_param_names with ellipsoidGate
# ============================================================================

test_that("update_gate_param_names handles ellipsoidGate mean and cov", {
  mean_vec <- c(`FSC-H` = 500, `SSC-H` = 200)
  cov_mat <- matrix(c(100, 10, 10, 50), ncol = 2)
  colnames(cov_mat) <- c("FSC-H", "SSC-H")
  rownames(cov_mat) <- c("FSC-H", "SSC-H")

  eg <- ellipsoidGate(.gate = cov_mat, mean = mean_vec, filterId = "ell")

  mapping <- list(`FSC-H` = "FSC_H", `SSC-H` = "SSC_H")

  out <- CyFj11:::update_gate_param_names(eg, mapping)

  expect_s4_class(out, "ellipsoidGate")
  # Check mean names and cov row/col names which are updated by the function
  expect_equal(unname(names(out@mean)), c("FSC_H", "SSC_H"))
  expect_equal(unname(colnames(out@cov)), c("FSC_H", "SSC_H"))
  expect_equal(unname(rownames(out@cov)), c("FSC_H", "SSC_H"))
})

# ============================================================================
# Tests for update_gate_param_names with rectangleGate
# ============================================================================

test_that("update_gate_param_names handles rectangleGate min/max", {
  rg <- rectangleGate(`FSC-H` = c(100, 500), `SSC-H` = c(50, 300), filterId = "rect")

  mapping <- list(`FSC-H` = "FSC_H", `SSC-H` = "SSC_H")

  out <- CyFj11:::update_gate_param_names(rg, mapping)

  expect_s4_class(out, "rectangleGate")
  # Check min/max names which are updated by the function
  expect_equal(unname(names(out@min)), c("FSC_H", "SSC_H"))
  expect_equal(unname(names(out@max)), c("FSC_H", "SSC_H"))
})

# ============================================================================
# Tests for logical gate handling in add_population_node
# ============================================================================

test_that("add_population_node handles logical AND gate", {
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # First add two base populations
  rg1 <- rectangleGate(`FSC-H` = c(100, 500), filterId = "fsc_high")
  rg2 <- rectangleGate(`SSC-H` = c(50, 300), filterId = "ssc_high")

  gs_pop_add(gh, rg1, parent = "root", name = "FSC_High")
  gs_pop_add(gh, rg2, parent = "root", name = "SSC_High")
  recompute(gh)

  # Now create a logical AND gate node
  sample_uuid <- "sample-1"
  def_uuid <- "and-gate-uuid"

  node <- list(
    name = "FSC_and_SSC_High",
    type = "and",
    definition_uuid = def_uuid,
    logical_gate_info = list(
      operator = "and",
      combined_populations = c("FSC_High", "SSC_High")
    ),
    children = list()
  )

  gates <- list()  # No gate needed for logical gates

  expect_no_error(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = gates,
      sample_uuid = sample_uuid,
      parent = "root"
    )
  )

  # Check that the logical gate population was added
  all_paths <- gs_get_pop_paths(gh)
  expect_true(any(grepl("FSC_and_SSC_High", all_paths)))
})

test_that("add_population_node handles logical OR gate", {
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # First add two base populations
  rg1 <- rectangleGate(`FSC-H` = c(100, 500), filterId = "fsc_high")
  rg2 <- rectangleGate(`SSC-H` = c(50, 300), filterId = "ssc_high")

  gs_pop_add(gh, rg1, parent = "root", name = "FSC_High")
  gs_pop_add(gh, rg2, parent = "root", name = "SSC_High")
  recompute(gh)

  # Create a logical OR gate node
  node <- list(
    name = "FSC_or_SSC_High",
    type = "or",
    definition_uuid = "or-gate-uuid",
    logical_gate_info = list(
      operator = "or",
      combined_populations = c("FSC_High", "SSC_High")
    ),
    children = list()
  )

  expect_no_error(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = list(),
      sample_uuid = "sample-1",
      parent = "root"
    )
  )

  all_paths <- gs_get_pop_paths(gh)
  expect_true(any(grepl("FSC_or_SSC_High", all_paths)))
})

test_that("add_population_node handles logical NOT gate", {
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # First add a base population
  rg <- rectangleGate(`FSC-H` = c(100, 500), filterId = "fsc_high")
  gs_pop_add(gh, rg, parent = "root", name = "FSC_High")
  recompute(gh)

  # Create a logical NOT gate node
  node <- list(
    name = "Not_FSC_High",
    type = "not",
    definition_uuid = "not-gate-uuid",
    logical_gate_info = list(
      operator = "not",
      combined_populations = c("FSC_High")
    ),
    children = list()
  )

  expect_no_error(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = list(),
      sample_uuid = "sample-1",
      parent = "root"
    )
  )

  all_paths <- gs_get_pop_paths(gh)
  expect_true(any(grepl("Not_FSC_High", all_paths)))
})

test_that("add_population_node defers logical gate when component is missing", {
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Add only one of two required populations
  rg <- rectangleGate(`FSC-H` = c(100, 500), filterId = "fsc_high")
  gs_pop_add(gh, rg, parent = "root", name = "FSC_High")
  recompute(gh)

  # Create a deferred environment
  deferred <- new.env(parent = emptyenv())
  deferred$gates <- list()

  # Create a logical AND gate with one missing component
  node <- list(
    name = "Missing_AND_Gate",
    type = "and",
    definition_uuid = "and-gate-uuid",
    logical_gate_info = list(
      operator = "and",
      combined_populations = c("FSC_High", "SSC_High")  # SSC_High doesn't exist
    ),
    children = list()
  )

  # Should defer the gate instead of failing
  expect_no_error(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = list(),
      sample_uuid = "sample-1",
      parent = "root",
      deferred = deferred
    )
  )

  # Check that the gate was deferred
  expect_equal(length(deferred$gates), 1)
  expect_equal(deferred$gates[[1]]$node$name, "Missing_AND_Gate")
})

test_that("add_population_node warns about unknown logical operator", {
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Add the populations first so they exist
  rg1 <- rectangleGate(`FSC-H` = c(100, 500), filterId = "fsc_high")
  rg2 <- rectangleGate(`SSC-H` = c(50, 300), filterId = "ssc_high")
  gs_pop_add(gh, rg1, parent = "root", name = "Pop1")
  gs_pop_add(gh, rg2, parent = "root", name = "Pop2")
  recompute(gh)

  node <- list(
    name = "Unknown_Op_Gate",
    type = "xor",
    definition_uuid = "xor-gate-uuid",
    logical_gate_info = list(
      operator = "xor",  # Not supported
      combined_populations = c("Pop1", "Pop2")
    ),
    children = list()
  )

  expect_warning(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = list(),
      sample_uuid = "sample-1",
      parent = "root"
    ),
    "Unknown logical operator"
  )
})

# ============================================================================
# Tests for apply_transforms_to_gate with polygonGate
# ============================================================================

test_that("apply_transforms_to_gate transforms polygonGate boundaries", {
  boundaries <- matrix(c(100, 200, 300, 150, 250, 350), ncol = 2)
  colnames(boundaries) <- c("FSC-H", "SSC-H")

  pg <- polygonGate(.gate = boundaries, filterId = "poly")

  # Apply log transformation to FSC-H only
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func)

  out <- CyFj11:::apply_transforms_to_gate(pg, trans_list)

  expect_s4_class(out, "polygonGate")
  # FSC-H should be transformed
  expect_equal(out@boundaries[, "FSC-H"], log10(boundaries[, "FSC-H"]))
  # SSC-H should be unchanged
  expect_equal(out@boundaries[, "SSC-H"], boundaries[, "SSC-H"])
})

test_that("apply_transforms_to_gate transforms ellipsoidGate mean", {
  # Lines 514-535: ellipsoidGate transformation path
  mean_vec <- c(`FSC-H` = 500, `SSC-H` = 200)
  cov_mat <- matrix(c(100, 10, 10, 50), ncol = 2)
  colnames(cov_mat) <- c("FSC-H", "SSC-H")
  rownames(cov_mat) <- c("FSC-H", "SSC-H")

  eg <- ellipsoidGate(.gate = cov_mat, mean = mean_vec, filterId = "ell")

  # Apply log transformation
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func, `SSC-H` = trans_func)

  # Suppress expected warning about ellipsoid shape
  out <- suppressWarnings(
    CyFj11:::apply_transforms_to_gate(eg, trans_list)
  )

  expect_s4_class(out, "ellipsoidGate")
  # Mean values should be transformed - use unname() to avoid names mismatch
  expect_equal(unname(out@mean["FSC-H"]), log10(500), tolerance = 0.01)
  expect_equal(unname(out@mean["SSC-H"]), log10(200), tolerance = 0.01)
})

test_that("apply_transforms_to_gate returns original when trans_list is empty", {
  boundaries <- matrix(c(100, 200, 300, 150, 250, 350), ncol = 2)
  colnames(boundaries) <- c("FSC-H", "SSC-H")

  pg <- polygonGate(.gate = boundaries, filterId = "poly")

  out <- CyFj11:::apply_transforms_to_gate(pg, list())

  expect_s4_class(out, "polygonGate")
  expect_equal(out@boundaries, boundaries)
})

test_that("add_population_node warns when gate is not found", {
  # Lines 693-705: Warning when no gate found for population
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Create a node with a gate reference that doesn't exist
  node <- list(
    name = "MissingGate",
    type = "rectangle",
    definition_uuid = "non-existent-uuid",
    children = list()
  )

  gates <- list()  # Empty gates list - gate won't be found

  # Expect warning about missing gate
  expect_warning(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = gates,
      sample_uuid = "sample-1",
      parent = "root"
    ),
    "No gate found for population"
  )
})

test_that("add_population_node handles child nodes with parent path", {
  # Lines 806-820: Processing children with parent path
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Create parent and child gates
  parent_uuid <- "parent-uuid"
  def_uuid <- "child-uuid"

  parent_gate <- rectangleGate(`FSC-H` = c(100, 500), filterId = "parent")
  child_gate <- rectangleGate(`SSC-H` = c(50, 300), filterId = "child")

  gates <- list()
  gates[[paste0(parent_uuid, "_sample-1")]] <- parent_gate
  gates[[paste0(def_uuid, "_sample-1")]] <- child_gate

  node <- list(
    name = "ParentGate",
    type = "rectangle",
    definition_uuid = parent_uuid,
    children = list(
      list(
        name = "ChildGate",
        type = "rectangle",
        definition_uuid = def_uuid,
        parent = "ParentGate",  # Child has explicit parent path
        children = list()
      )
    )
  )

  # Should process child with explicit parent path (line 807)
  expect_no_error(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = gates,
      sample_uuid = "sample-1",
      parent = "root"
    )
  )

  # Check that both populations were added
  all_paths <- gs_get_pop_paths(gh)
  expect_true(any(grepl("ParentGate", all_paths)))
  expect_true(any(grepl("ChildGate", all_paths)))
})

test_that("add_population_node handles child nodes without parent path", {
  # Lines 809-820: Processing children without parent path (builds from sanitized names)
  # Also tests lines 903-906: child path processing for regular gates
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Create parent and child gates
  parent_uuid <- "parent-uuid"
  def_uuid <- "child-uuid-2"

  parent_gate <- rectangleGate(`FSC-H` = c(100, 500), filterId = "parent")
  child_gate <- rectangleGate(`SSC-H` = c(50, 300), filterId = "child")

  gates <- list()
  gates[[paste0(parent_uuid, "_sample-1")]] <- parent_gate
  gates[[paste0(def_uuid, "_sample-1")]] <- child_gate

  # For regular gates (non-logical), the child's parent field is expected to be
  # a full path like "root/ParentGate", and line 903 strips the first component.
  node <- list(
    name = "ParentGate",
    type = "rectangle",
    definition_uuid = parent_uuid,
    children = list(
      list(
        name = "ChildGate",
        type = "rectangle",
        definition_uuid = def_uuid,
        # Parent path format expected by line 903: "root/ParentGate" -> strips to "ParentGate"
        parent = "root/ParentGate",
        children = list()
      )
    )
  )

  # Should process child with path stripping (line 903)
  expect_no_error(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = gates,
      sample_uuid = "sample-1",
      parent = "root"
    )
  )

  # Check that both populations were added
  all_paths <- gs_get_pop_paths(gh)
  expect_true(any(grepl("ParentGate", all_paths)))
  expect_true(any(grepl("ChildGate", all_paths)))
})
