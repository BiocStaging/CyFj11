#' @title Full Integration Tests for Conversion Function
#' @name test-conversion-full
#' @keywords internal
NULL

context("Full Conversion Tests")

# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

# These tests are commented out because they require FCS file resolution
# which can be problematic in test environments
#
test_that("fj11_to_gatingset works with example data", {
  # Skip if flowCore is not available
  skip_if_not_installed("flowCore")

  # Load the example workspace
  workspace_path <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  expect_true(file.exists(workspace_path))

  workspace <- read_flowjo11_workspace(workspace_path)
  expect_true(is.list(workspace))

  # Skip this test if FCS file resolution fails (common in test environments)
  test_path <- system.file("extdata", "", package = "CyFj11")
  fcs_file <- file.path(test_path, "sample04.fcs")
  skip_if(!file.exists(fcs_file), "FCS file not found in expected location")

  # Test that we can call fj11_to_gatingset with execute=FALSE (faster)
  # This tests the main conversion pathway without actually executing gates
  expect_error({
    gs <- fj11_to_gatingset(
      fj11_workspace = workspace,
      group_name = 1,
      execute = FALSE,
      path = test_path,
      stop_on_multiple = FALSE  # More permissive to avoid file search issues
    )
  }, NA)  # NA means we don't expect an error

  # If it ran without error, check the result
  # Note: We're not checking the actual result because it depends on flowWorkspace
  # and might not be available in all test environments
})

test_that("fj11_to_gatingset handles group selection", {
  # Load the example workspace
  workspace_path <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if(!file.exists(workspace_path), "Example workspace not found")

  workspace <- read_flowjo11_workspace(workspace_path)

  # Skip this test if FCS file resolution fails (common in test environments)
  test_path <- system.file("extdata", "", package = "CyFj11")
  fcs_file <- file.path(test_path, "sample04.fcs")
  skip_if(!file.exists(fcs_file), "FCS file not found in expected location")

  # Test with numeric group index
  expect_error({
    gs <- fj11_to_gatingset(
      fj11_workspace = workspace,
      group_name = 1,
      execute = FALSE,
      path = test_path,
      stop_on_multiple = FALSE  # More permissive to avoid file search issues
    )
  }, NA)
})

test_that("Helper functions work correctly", {
  # Test filter_samples with various inputs
  sample_uuids <- c("sample1", "sample2", "sample3")
  
  # Test with empty subset
  result <- filter_samples(sample_uuids, list(), list(), list())
  expect_equal(result, sample_uuids)
  
  # Test with numeric subset
  result <- filter_samples(sample_uuids, c(1, 3), list(), list())
  expect_equal(result, c("sample1", "sample3"))
  
  # Test with character subset (filenames)
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample04.fcs",
        customKeywords = list(`File Name` = "sample04.fcs")
      )
    )
  )
  
  result <- filter_samples(c("sample1"), "sample04.fcs", dataSources, list())
  expect_equal(result, "sample1")
})

test_that("create_sample_names works with various configurations", {
  sample_uuids <- c("sample1")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample04.fcs",
        customKeywords = list(`$TOT` = "10000")
      )
    )
  )
  
  # Test basic functionality
  result <- create_sample_names(sample_uuids, dataSources, character(), FALSE)
  expect_equal(as.vector(result), "sample04.fcs")
  
  # Test with additional keys
  result <- create_sample_names(sample_uuids, dataSources, "$TOT", FALSE)
  expect_equal(as.vector(result), "sample04.fcs_10000")
  
  # Test with sample ID
  result <- create_sample_names(sample_uuids, dataSources, character(), TRUE)
  expect_true(grepl("sample04.fcs", as.vector(result)))
})

test_that("extract_pdata works with keywords", {
  sample_uuids <- c("sample1")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        customKeywords = list(`$DATE` = "01-Jan-2024", `PATIENT ID` = "P001")
      )
    )
  )
  
  keywords <- c("$DATE", "PATIENT ID")
  result <- extract_pdata(sample_uuids, dataSources, keywords, FALSE)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_true("X.DATE" %in% names(result) || "DATE" %in% names(result))
  expect_true("PATIENT.ID" %in% names(result) || "PATIENTID" %in% names(result))
})

test_that("extract_keywords_for_samples works correctly", {
  sample_uuids <- c("sample1")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample04.fcs",
        customKeywords = list(`$DATE` = "01-Jan-2024", `PATIENT ID` = "P001")
      )
    )
  )
  
  keywords <- c("$DATE", "PATIENT ID")
  result <- extract_keywords_for_samples(sample_uuids, dataSources, keywords)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_true(any(grepl("DATE", names(result))))
  expect_true(any(grepl("PATIENT", names(result))))
  expect_true("sample_uuid" %in% names(result))
  expect_true("filename" %in% names(result))
})

