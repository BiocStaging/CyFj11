#' @title Tests for Pretty Print Function
#' @name test-pretty-print
#' @keywords internal
NULL



test_that("pretty_print_flowjo handles missing file", {
  # Test with non-existent file
  expect_error(pretty_print_flowjo("nonexistent.flowjo"),
               "File not found: nonexistent.flowjo")
})

test_that("pretty_print_flowjo works with example data", {
  # Skip if required packages are not available
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("ggcyto")
  
  # Set the path to your FlowJo workspace file
  workspace_path <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  
  # Skip if file doesn't exist
  skip_if(!file.exists(workspace_path), "Example workspace file not found")
  
  # Read the FlowJo v11 workspace
  ws <- read_flowjo11_workspace(workspace_path)
  
  # Test pretty printing (should not error)
  expect_error(pretty_print_flowjo(workspace_path), NA)
  
  # Examine the workspace structure
  expect_true(is.list(ws))
  expect_true(all(c("groups", "dataSources", "populationDefinitions", "populations") %in% names(ws)))
})
