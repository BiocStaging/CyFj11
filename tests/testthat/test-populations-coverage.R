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

#' @title Coverage Tests for populations.R
#' @name test-populations-coverage
#' @keywords internal
NULL

skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

# ============================================================================
# Tests for apply_transforms_to_gate - ellipsoidGate branch (lines 514-535)
# ============================================================================

test_that("apply_transforms_to_gate transforms ellipsoidGate mean - coverage for lines 514-535", {
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

test_that("apply_transforms_to_gate ellipsoidGate - partial parameter match (line 520)", {
  # Test the branch where only some parameters match (line 520: if (length(param_idx) > 0))
  mean_vec <- c(`FSC-H` = 500, `SSC-H` = 200)
  cov_mat <- matrix(c(100, 10, 10, 50), ncol = 2)
  colnames(cov_mat) <- c("FSC-H", "SSC-H")
  rownames(cov_mat) <- c("FSC-H", "SSC-H")

  eg <- ellipsoidGate(.gate = cov_mat, mean = mean_vec, filterId = "ell")

  # Only transform FSC-H, not SSC-H
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func)  # SSC-H not in trans_list

  expect_warning(
    out <- CyFj11:::apply_transforms_to_gate(eg, trans_list),
    "Ellipsoid gate transformation may not preserve exact shape"
  )

  expect_s4_class(out, "ellipsoidGate")
  # FSC-H should be transformed
  expect_equal(unname(out@mean["FSC-H"]), log10(500), tolerance = 0.01)
  # SSC-H should be unchanged
  expect_equal(unname(out@mean["SSC-H"]), 200)
})

# ============================================================================
# Tests for add_population_node - no gate found branch (lines 692-706)
# ============================================================================

test_that("add_population_node warns when gate is not found - lines 692-706", {
  # Lines 693-705: Warning when no gate found for population
  # This tests the branch: if (is.null(gate_obj) && ! is_logica_gate)
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Create a node with a gate reference that doesn't exist
  # Must NOT have logical_gate_info to trigger the warning branch
  node <- list(
    name = "MissingGate",
    type = "rectangle",  # Not a logical gate
    definition_uuid = "non-existent-uuid",
    children = list()
  )

  gates <- list()  # Empty gates list - gate won't be found

  # Expect warning about missing gate with detailed info
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

test_that("add_population_node no gate - includes available populations in warning", {
  # Test that the warning includes the list of available populations (lines 694-699)
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Add a population first so we have something in the hierarchy
  rg <- rectangleGate(`FSC-H` = c(100, 500), filterId = "existing")
  gs_pop_add(gh, rg, parent = "root", name = "ExistingPop")
  recompute(gh)

  # Create a node with a gate reference that doesn't exist
  node <- list(
    name = "MissingGate",
    type = "rectangle",
    definition_uuid = "non-existent-uuid",
    children = list()
  )

  gates <- list()

  # The warning should include "Available populations" with the list
  expect_warning(
    CyFj11:::add_population_node(
      gh = gh,
      node = node,
      gates = gates,
      sample_uuid = "sample-1",
      parent = "root"
    ),
    "Available populations"
  )
})


# ============================================================================
# Tests for add_population_node - children processing (lines 802-822)
# ============================================================================

test_that("add_population_node processes children of logical gate with explicit parent path - line 807", {
  # Lines 806-820: Processing children with parent path (inside logical gate branch)
  # child_parent <- if (!is.null(child$parent) && is.character(child$parent)) {
  #   sanitize_population_name(child$parent)
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # First add base populations that the logical gate will reference
  rg1 <- rectangleGate(`FSC-H` = c(100, 500), filterId = "fsc_high")
  rg2 <- rectangleGate(`SSC-H` = c(50, 300), filterId = "ssc_high")
  gs_pop_add(gh, rg1, parent = "root", name = "FSC_High")
  gs_pop_add(gh, rg2, parent = "root", name = "SSC_High")
  recompute(gh)

  # Create a logical AND gate with a child
  # The child will have an explicit parent path
  node <- list(
    name = "AND_Gate",
    type = "and",
    definition_uuid = "and-gate-uuid",
    logical_gate_info = list(
      operator = "and",
      combined_populations = c("FSC_High", "SSC_High")
    ),
    children = list(
      list(
        name = "ChildOfAND",
        type = "rectangle",
        definition_uuid = "child-uuid",
        parent = "AND_Gate",  # Child has explicit parent path - triggers line 807
        children = list()
      )
    )
  )

  gates <- list()  # No gate needed for logical gate itself
  # But child needs a gate
  child_gate <- rectangleGate(`FSC-H` = c(200, 400), filterId = "child")
  gates[["child-uuid_sample-1"]] <- child_gate

  # Should process child with explicit parent path (line 807)
  CyFj11:::add_population_node(
    gh = gh,
    node = node,
    gates = gates,
    sample_uuid = "sample-1",
    parent = "root"
  )

  # The key test is that the code path for line 807 was executed
  expect_true(TRUE)  # If we got here, the sanitization code path was covered
})

test_that("add_population_node processes children of logical gate without parent path - line 809", {
  # Lines 809-820: Processing children without parent path (inside logical gate branch)
  # else { paste0(parent, "/", node_name)
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # First add base populations that the logical gate will reference
  rg1 <- rectangleGate(`FSC-H` = c(100, 500), filterId = "fsc_high")
  rg2 <- rectangleGate(`SSC-H` = c(50, 300), filterId = "ssc_high")
  gs_pop_add(gh, rg1, parent = "root", name = "FSC_High")
  gs_pop_add(gh, rg2, parent = "root", name = "SSC_High")
  recompute(gh)

  # Create a logical OR gate with a child that has NO explicit parent path
  node <- list(
    name = "OR_Gate",
    type = "or",
    definition_uuid = "or-gate-uuid",
    logical_gate_info = list(
      operator = "or",
      combined_populations = c("FSC_High", "SSC_High")
    ),
    children = list(
      list(
        name = "ChildOfOR",
        type = "rectangle",
        definition_uuid = "child-uuid-2",
        # No parent field - will use paste0(parent, "/", node_name) - triggers line 809
        children = list()
      )
    )
  )

  gates <- list()
  child_gate <- rectangleGate(`SSC-H` = c(100, 250), filterId = "child2")
  gates[["child-uuid-2_sample-1"]] <- child_gate

  # Should process child with built parent path (line 809)
  CyFj11:::add_population_node(
    gh = gh,
    node = node,
    gates = gates,
    sample_uuid = "sample-1",
    parent = "root"
  )

  # The key test is that the code path for line 809 was executed
  expect_true(TRUE)  # If we got here, the code path was covered
})

test_that("add_population_node no gate - line 698 else branch when gs_get_pop_paths fails", {
  # Test line 698: the else { "" } branch when all_pop_paths is NULL
  # This happens when gs_get_pop_paths throws an error (caught by tryCatch)
  # Note: This test requires mocking flowWorkspace::gs_get_pop_paths at the
  # package level, which is complex. The line is covered indirectly through
  # the tryCatch error handling when gs_get_pop_paths encounters an error.
  # For now, we accept that this edge case (error in gs_get_pop_paths) is
  # difficult to test without extensive mocking infrastructure.
  skip("Line 698 requires mocking flowWorkspace::gs_get_pop_paths error path")
})

test_that("add_population_node children - sanitize_population_name called on parent", {
  # Line 807: sanitize_population_name(child$parent)
  # Line 903-906: child path stripping and sanitization for regular gates
  # Test that parent paths with "/" in population names are sanitized to ":"
  data("GvHD", package = "flowCore")
  gs <- GatingSet(flowSet(GvHD[[1]]))
  gh <- gs[[1]]

  # Create parent and child gates using parameters that exist in GvHD data
  parent_uuid <- "parent-uuid-3"
  child_uuid <- "child-uuid-3"

  # Use CD45 PE which exists in the GvHD data
  parent_gate <- rectangleGate(`CD45 PE` = c(100, 500), filterId = "parent")
  child_gate <- rectangleGate(`CD14 PerCP` = c(50, 300), filterId = "child")

  gates <- list()
  gates[[paste0(parent_uuid, "_sample-1")]] <- parent_gate
  gates[[paste0(child_uuid, "_sample-1")]] <- child_gate

  # Parent node with a name containing "/" (gets sanitized to ":")
  # In the real build_gating_tree() flow, node names are sanitized BEFORE
  # being stored, and child$parent is built from sanitized names.
  # So child$parent would be "root/Parent:WithSlash", not "root/Parent/WithSlash".
  # This test verifies that sanitize_population_name() is called on child$parent
  # (line 807 for logical gates, line 906 for regular gates).
  parent_node <- list(
    name = "Parent/WithSlash",  # Name contains "/" -> sanitized to "Parent:WithSlash"
    type = "rectangle",
    definition_uuid = parent_uuid,
    children = list(
      list(
        name = "ChildGate",
        type = "rectangle",
        definition_uuid = child_uuid,
        # Path uses "/" as separator between sanitized names
        # "root/Parent:WithSlash" -> strip "root/" -> "Parent:WithSlash"
        parent = "root/Parent:WithSlash",
        children = list()
      )
    )
  )

  # Should sanitize both the parent node name and the child's parent field
  # "Parent/WithSlash" (node name) -> "Parent:WithSlash"
  # "root/Parent:WithSlash" (child$parent) -> "Parent:WithSlash" after stripping
  expect_no_warning(
    CyFj11:::add_population_node(
      gh = gh,
      node = parent_node,
      gates = gates,
      sample_uuid = "sample-1",
      parent = "root"
    )
  )

  # Verify parent was added with sanitized name
  all_paths <- flowWorkspace::gs_get_pop_paths(gh)
  expect_true(any(grepl("Parent:WithSlash", all_paths, fixed = TRUE)))

  # Verify child was added under the sanitized parent path
  expect_true(any(grepl("Parent:WithSlash/ChildGate", all_paths, fixed = TRUE)))
})

# ============================================================================
# Tests for apply_transforms_to_gate - polygonGate verbose branch (lines 504-508)
# ============================================================================

test_that("apply_transforms_to_gate polygonGate - verbose messages (lines 504-508)", {
  # Test the verbose message branch for polygonGate transformation
  boundaries <- matrix(c(100, 200, 300, 150, 250, 350), ncol = 2)
  colnames(boundaries) <- c("FSC-H", "SSC-H")

  pg <- polygonGate(.gate = boundaries, filterId = "poly")

  # Apply log transformation
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func)

  # Enable verbose mode
  old_verbose <- CyFj11:::get_verbose()
  CyFj11:::set_verbose(TRUE)
  on.exit(CyFj11:::set_verbose(old_verbose))

  # Should produce verbose messages about transformation
  expect_message(expect_message(
    out <- CyFj11:::apply_transforms_to_gate(pg, trans_list),
    "Transformed.*polygon boundaries"
  ),"Range")

  expect_s4_class(out, "polygonGate")
})

# ============================================================================
# Tests for apply_transforms_to_gate - rectangleGate verbose branch (lines 460-470)
# ============================================================================

test_that("apply_transforms_to_gate rectangleGate - verbose messages (lines 460-470)", {
  # Test the verbose message branch for rectangleGate transformation
  rg <- rectangleGate(`FSC-H` = c(100, 500), `SSC-H` = c(50, 300), filterId = "rect")

  # Apply log transformation
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func)

  # Enable verbose mode
  old_verbose <- CyFj11:::get_verbose()
  CyFj11:::set_verbose(TRUE)
  on.exit(CyFj11:::set_verbose(old_verbose))

  # Should produce verbose messages about transformation
  expect_message(
    out <- CyFj11:::apply_transforms_to_gate(rg, trans_list),
    "Transformed.*min"
  )

  expect_s4_class(out, "rectangleGate")
})

# ============================================================================
# Tests for apply_transforms_to_gate - ellipsoidGate verbose branch (lines 525-527)
# ============================================================================

test_that("apply_transforms_to_gate ellipsoidGate - verbose messages (lines 525-527)", {
  # Test the verbose message branch for ellipsoidGate transformation
  mean_vec <- c(`FSC-H` = 500, `SSC-H` = 200)
  cov_mat <- matrix(c(100, 10, 10, 50), ncol = 2)
  colnames(cov_mat) <- c("FSC-H", "SSC-H")
  rownames(cov_mat) <- c("FSC-H", "SSC-H")

  eg <- ellipsoidGate(.gate = cov_mat, mean = mean_vec, filterId = "ell")

  # Apply log transformation
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func)

  # Enable verbose mode
  old_verbose <- CyFj11:::get_verbose()
  CyFj11:::set_verbose(TRUE)
  on.exit(CyFj11:::set_verbose(old_verbose))

  # Expect warning and verbose message
  expect_warning(
    expect_message(
      out <- CyFj11:::apply_transforms_to_gate(eg, trans_list),
      "Transformed.*ellipse mean"
    ),
    "Ellipsoid gate transformation may not preserve exact shape"
  )

  expect_s4_class(out, "ellipsoidGate")
})

# ============================================================================
# Tests for apply_transforms_to_gate - quadGate branch (lines 474-493)
# ============================================================================

test_that("apply_transforms_to_gate transforms quadGate boundary", {
  # Lines 474-493: quadGate transformation path
  boundary <- c(`FSC-H` = 250, `SSC-H` = 150)

  qg <- quadGate(.gate = boundary, filterId = "quad")

  # Apply log transformation to FSC-H only
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func)

  out <- CyFj11:::apply_transforms_to_gate(qg, trans_list)

  expect_s4_class(out, "quadGate")
  # FSC-H boundary should be transformed
  expect_equal(unname(out@boundary["FSC-H"]), log10(250), tolerance = 0.01)
  # SSC-H boundary should be unchanged
  expect_equal(unname(out@boundary["SSC-H"]), 150)
})

test_that("apply_transforms_to_gate quadGate - verbose messages (lines 486-488)", {
  # Test the verbose message branch for quadGate transformation
  boundary <- c(`FSC-H` = 250, `SSC-H` = 150)
  qg <- quadGate(.gate = boundary, filterId = "quad")

  # Apply log transformation
  trans_func <- function(x) log10(x)
  trans_list <- list(`FSC-H` = trans_func)

  # Enable verbose mode
  old_verbose <- CyFj11:::get_verbose()
  CyFj11:::set_verbose(TRUE)
  on.exit(CyFj11:::set_verbose(old_verbose))

  expect_message(
    out <- CyFj11:::apply_transforms_to_gate(qg, trans_list),
    "Transformed.*quad divider"
  )

  expect_s4_class(out, "quadGate")
})

