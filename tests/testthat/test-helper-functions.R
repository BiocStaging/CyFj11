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

#' @title Tests for Helper Functions
#' @name test-helper-functions
#' @keywords internal
NULL



test_that("load_example_workspace loads the example data correctly", {
  # This test verifies that our helper function works
  workspace <- load_example_workspace()
  
  # Check that we get the expected structure
  expect_s3_class(workspace, "flowjo11_workspace")
  expect_true(grepl("test.data.flowjo$", workspace$path))
  
  # Check that we have the expected components
  expect_type(workspace$manifest, "list")
  expect_type(workspace$json, "list")
  expect_type(workspace$groups, "list")
  expect_type(workspace$dataSources, "list")
  expect_type(workspace$populationDefinitions, "list")
  expect_type(workspace$populations, "list")
  
  # Report basic statistics
  cat("Example workspace contains:\n")
  cat("  -", length(workspace$groups), "groups\n")
  cat("  -", length(workspace$dataSources), "data sources\n")
  cat("  -", length(workspace$populationDefinitions), "population definitions\n")
  cat("  -", length(workspace$populations), "populations\n")
})

test_that("load_example_workspace provides access to real gate data", {
  # Load the workspace
  workspace <- load_example_workspace()
  
  # Check that we have population definitions
  expect_gt(length(workspace$populationDefinitions), 0)
  
  # Look at the first few population definitions
  pop_defs <- workspace$populationDefinitions
  first_pop_names <- sapply(head(pop_defs, 3), function(pop) {
    pop$definition$name
  })
  
  cat("First few populations:", paste(first_pop_names, collapse = ", "), "\n")
})
