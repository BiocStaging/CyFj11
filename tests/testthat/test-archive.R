#' @title Tests for Archive Functionality
#' @name test-archive
#' @keywords internal
NULL

# Load required packages
skip_if_not_installed("jsonlite")
library(jsonlite)

test_that("process_zip_archive handles missing file", {
  # Test with non-existent file
  expect_error(process_zip_archive("/nonexistent/file.flowjo"), 
               "Workspace file does not exist: /nonexistent/file.flowjo")
})

test_that("read_flowjo11_workspace validates input", {
  # Test with non-existent file
  expect_error(read_flowjo11_workspace("/nonexistent/file.flowjo"), 
               "Workspace file does not exist: /nonexistent/file.flowjo")
  
  # Test with wrong extension (warning, not error)
  # This would require mocking or a real file to test properly
})

test_that("process_zip_archive returns correct structure", {
  # This test would require a real .flowjo file to test properly
  # For now, we'll just check that the function exists
  expect_true(exists("process_zip_archive", where = asNamespace("CyFj11")))
})

test_that("read_flowjo11_workspace processes real FlowJo v11 file correctly", {
  # Skip if the test file doesn't exist
  test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if_not(file.exists(test_file), "Test FlowJo v11 file not found")
  
  # Process the real FlowJo v11 file
  workspace <- read_flowjo11_workspace(test_file)
  
  # Check that we get the expected structure
  expect_s3_class(workspace, "flowjo11_workspace")
  expect_true(file.exists(workspace$path))
  
  # Check that we have the expected components
  expect_type(workspace$manifest, "list")
  expect_type(workspace$json, "list")
  
  # Check that we have at least one analysis JSON
  expect_gt(length(workspace$json), 0)
  
  # Check that we have the key components
  expect_type(workspace$groups, "list")
  expect_type(workspace$dataSources, "list")
  expect_type(workspace$populationDefinitions, "list")
  expect_type(workspace$populations, "list")
})

test_that("process_zip_archive handles real FlowJo v11 file correctly", {
  # Skip if the test file doesn't exist
  test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if_not(file.exists(test_file), "Test FlowJo v11 file not found")
  
  # Process the archive directly
  results <- process_zip_archive(test_file)
  
  # Check structure
  expect_type(results, "list")
  expect_named(results, c("manifests", "json"))
  expect_type(results$manifests, "list")
  expect_type(results$json, "list")
  
  # Should have at least one manifest and one JSON file
  expect_gt(length(results$manifests), 0)
  expect_gt(length(results$json), 0)
})

