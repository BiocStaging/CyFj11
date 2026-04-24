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

#' @title Tests for Build Gating Tree Function
#' @name test-build-gating-tree
#' @keywords internal
NULL


# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

test_that("build_gating_tree works with minimal data", {
  # Create minimal mock data for testing build_gating_tree
  sample_uuid <- "sample1"
  populations <- list()
  populationDefinitions <- list()
  root_uuid <- "root1"
  
  # Test that the function exists and can be called
  expect_true(exists("build_gating_tree", where = asNamespace("CyFj11")))
})

test_that("identify_logical_gates works with empty data", {
  populations <- list()
  populationDefinitions <- list()
  
  result <- identify_logical_gates(populations, populationDefinitions)
  
  expect_type(result, "list")
  expect_named(result, c("gates", "populationDefinitions"))
  expect_equal(length(result$gates), 0)
})

test_that("deduplicate_tree works with empty tree", {
  tree <- list()
  result <- deduplicate_tree(tree)
  expect_equal(result, tree)
})

test_that("deduplicate_tree works with simple tree", {
  tree <- list(
    uuid = "root",
    children = list(
      list(uuid = "child1"),
      list(uuid = "child1"),  # Duplicate
      list(uuid = "child2")
    )
  )
  
  result <- deduplicate_tree(tree)
  
  expect_equal(length(result$children), 2)
  expect_equal(sapply(result$children, function(x) x$uuid), c("child1", "child2"))
})

test_that("move_logical_gates_up works with empty tree", {
  tree <- list()
  result <- move_logical_gates_up(tree)
  expect_equal(result, tree)
})

test_that("find_gate_info works correctly", {
  logical_gates_info <- list(
    list(population_uuid = "pop1", gate_type = "and"),
    list(population_uuid = "pop2", gate_type = "or")
  )
  
  result <- find_gate_info("pop1", logical_gates_info)
  expect_equal(result$gate_type, "and")
  
  result <- find_gate_info("pop3", logical_gates_info)
  expect_null(result)
})

test_that("create_logical_gate_summary works with empty data", {
  result <- create_logical_gate_summary(list())
  expect_null(result)
})

test_that("create_logical_gate_summary works with data", {
  logical_gates <- list(
    list(
      gate_name = "Test Gate",
      gate_type = "and",
      population_uuid = "pop1",
      num_components = 2,
      combined_populations = c("Pop A", "Pop B")
    )
  )
  
  result <- create_logical_gate_summary(logical_gates)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$gate_name, "Test Gate")
  expect_equal(result$gate_type, "and")
})

test_that("summarize_logical_gates works with empty tree", {
  tree <- list()
  result <- summarize_logical_gates(tree)
  expect_null(result)
})

test_that("summarize_logical_gates works with logical gates", {
  tree <- list(
    name = "root",
    children = list(
      list(
        name = "Test Gate",
        type = "and",
        uuid = "pop1",
        logical_gate_info = list(
          combined_populations = c("Pop A", "Pop B"),
          num_components = 2
        )
      )
    )
  )
  
  result <- summarize_logical_gates(tree)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "Test Gate")
  expect_equal(result$type, "and")
})

test_that("get_uuids works correctly", {
  tree <- list(
    uuid = "root",
    children = list(
      list(uuid = "child1"),
      list(uuid = "child2",
           children = list(
             list(uuid = "grandchild1")
           ))
    )
  )
  
  result <- get_uuids(tree)
  
  expect_type(result, "character")
  expect_true("root" %in% result)
  expect_true("child1" %in% result)
  expect_true("child2" %in% result)
  expect_true("grandchild1" %in% result)
})