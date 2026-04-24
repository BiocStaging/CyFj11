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

#' @title Gate Extraction Tests Using Example Data
#' @name test-extract-gates
#' @keywords internal
NULL



test_that("Can extract gates from population definitions", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check that we have population definitions
  expect_gt(length(workspace$populationDefinitions), 0)
  
  # Count how many have gate definitions
  gate_count <- 0
  for (pop_uuid in names(workspace$populationDefinitions)) {
    pop_def <- workspace$populationDefinitions[[pop_uuid]]
    if ("definition" %in% names(pop_def) && 
        "gateDefinition" %in% names(pop_def$definition)) {
      gate_count <- gate_count + 1
    }
  }
  
  cat("Found", gate_count, "population definitions with gates\n")
  expect_gt(gate_count, 0)
})

test_that("Different gate types are represented", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Collect gate types
  gate_types <- c()
  for (pop_uuid in names(workspace$populationDefinitions)) {
    pop_def <- workspace$populationDefinitions[[pop_uuid]]
    if ("definition" %in% names(pop_def) && 
        "type" %in% names(pop_def$definition)) {
      gate_type <- pop_def$definition$type
      gate_types <- c(gate_types, as.character(gate_type))
    }
  }
  
  unique_gate_types <- unique(gate_types)
  cat("Found gate types:", paste(unique_gate_types, collapse = ", "), "\n")
  
  # Should have multiple gate types
  expect_gt(length(unique_gate_types), 1)
})

test_that("Workspace contains sample information", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check data sources
  expect_gt(length(workspace$dataSources), 0)
  
  # Look at data source structure
  first_source_uuid <- names(workspace$dataSources)[1]
  first_source <- workspace$dataSources[[first_source_uuid]]
  
  # Check that we have definition information
  expect_true("definition" %in% names(first_source))
  expect_type(first_source$definition, "list")
  
  cat("Found", length(workspace$dataSources), "data sources\n")
})

test_that("Population hierarchy can be analyzed", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check populations
  expect_gt(length(workspace$populations), 0)
  
  # Look at population structure
  first_pop_uuid <- names(workspace$populations)[1]
  first_pop <- workspace$populations[[first_pop_uuid]]
  
  # Check that we have uuid
  expect_true("uuid" %in% names(first_pop))
  expect_type(first_pop$uuid, "character")
  
  cat("Found", length(workspace$populations), "population instances\n")
})

test_that("Can identify gated populations", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Count populations with parent information (indicating they're gated)
  gated_count <- 0
  for (pop_uuid in names(workspace$populations)) {
    pop <- workspace$populations[[pop_uuid]]
    if ("parents" %in% names(pop)) {
      # Check if this population has meaningful parent information
      parents <- pop$parents
      if (length(parents) > 0) {
        gated_count <- gated_count + 1
      }
    }
  }
  
  cat("Found", gated_count, "populations with parent information\n")
  expect_gt(gated_count, 0)
})

test_that("Workspace contains statistical information", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Look for populations with results/statistics
  stat_count <- 0
  for (pop_uuid in names(workspace$populations)) {
    pop <- workspace$populations[[pop_uuid]]
    if ("results" %in% names(pop)) {
      results <- pop$results
      if ("statistics" %in% names(results) || "count" %in% names(results)) {
        stat_count <- stat_count + 1
      }
    }
  }
  
  cat("Found", stat_count, "populations with statistical information\n")
  expect_gt(stat_count, 0)
})
