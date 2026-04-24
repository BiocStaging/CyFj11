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

#' @title Tests using Example FlowJo v11 Data
#' @name test-example-data
#' @keywords internal
NULL



test_that("Example FlowJo v11 file can be loaded and examined", {
  # Load the example data file
  test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if_not(file.exists(test_file), "Test FlowJo v11 file not found")
  
  # Show that we can load it
  workspace <- read_flowjo11_workspace(test_file)
  
  # Basic structure checks
  expect_s3_class(workspace, "flowjo11_workspace")
  expect_true(grepl("test.data.flowjo$", workspace$path))
  
  # Report what we found
  cat("Loaded FlowJo v11 workspace with:\n")
  cat("  -", length(workspace$groups), "groups\n")
  cat("  -", length(workspace$dataSources), "data sources\n")
  cat("  -", length(workspace$populationDefinitions), "population definitions\n")
  cat("  -", length(workspace$populations), "populations\n")
})

test_that("Example data can be used for gate extraction", {
  # Load the example data file
  test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if_not(file.exists(test_file), "Test FlowJo v11 file not found")
  
  # Load workspace
  workspace <- read_flowjo11_workspace(test_file)
  
  # Check that we can access population definitions
  expect_gt(length(workspace$populationDefinitions), 0)
  
  # Show how to iterate through populations
  population_names <- sapply(workspace$populationDefinitions, function(pop) {
    pop$definition$name
  })
  
  cat("Found populations:", paste(population_names, collapse = ", "), "\n")
})
