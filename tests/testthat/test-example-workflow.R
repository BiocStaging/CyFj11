#' @title Example Workflow Test
#' @name test-example-workflow
#' @keywords internal
NULL



# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")
skip_if_not_installed("ggcyto")

library(flowCore)
library(flowWorkspace)

test_that("Example workflow runs without errors", {
  # Set the path to your FlowJo workspace file
  workspace_path <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  
  # Skip if file doesn't exist
  skip_if(!file.exists(workspace_path), "Example workspace file not found")
  
  # Read the FlowJo v11 workspace
  ws <- read_flowjo11_workspace(workspace_path)
  
  # Test that we can examine the workspace structure
  expect_true(is.list(ws))
  expect_true("groups" %in% names(ws))
  expect_true("dataSources" %in% names(ws))
  expect_true("populationDefinitions" %in% names(ws))
  expect_true("populations" %in% names(ws))
  
  # Test pretty printing (should not error)
  expect_error(pretty_print_flowjo(workspace_path), NA)
  
  # Note: We're not testing the full conversion workflow here because
  # it requires FCS files and has environmental dependencies that
  # may not be available in all test environments
})
