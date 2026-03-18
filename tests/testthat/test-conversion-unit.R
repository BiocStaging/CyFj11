#' @title Unit Tests for Conversion Functions
#' @name test-conversion-unit
#' @keywords internal
NULL



# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

test_that("fj11_to_gatingset handles missing parameters correctly", {
  # Test missing fj11_workspace parameter
  expect_error(fj11_to_gatingset(), "argument \"fj11_workspace\" is missing")
})

test_that("fj11_to_gatingset requires valid group", {
  # Test with minimal workspace structure that has a group
  workspace <- list(
    groups = list(
      "group1" = list(
        definition = list(name = "Test Group"),
        results = list(dataSources = list())
      )
    ),
    dataSources = list(),
    populationDefinitions = list(),
    populations = list()
  )
  
  # Test missing path when no cytoset provided
  expect_error(
    fj11_to_gatingset(workspace, group_name = 1, execute = FALSE),
    "Either 'path' or 'cytoset' must be provided"
  )
})

test_that("fj11_to_gatingset handles group selection errors", {
  # Test with workspace that has no groups
  workspace <- list(
    groups = list(),
    dataSources = list(),
    populationDefinitions = list(),
    populations = list()
  )
  

  # Test with non-existent group name
  expect_error(
    fj11_to_gatingset(workspace, group_name = "NonExistent", execute = FALSE, path = "."),
    "Group not found"
  )
})

test_that("Helper functions in conversion work correctly", {
  # Test filter_samples with various inputs
  sample_uuids <- c("sample1", "sample2", "sample3", "sample4")
  
  # Test with empty subset
  result <- filter_samples(sample_uuids, list(), list(), list())
  expect_equal(result, sample_uuids)
  
  # Test with numeric indices
  result <- filter_samples(sample_uuids, c(1, 3), list(), list())
  expect_equal(result, c("sample1", "sample3"))
  
  # Test with character vector (should be treated as filenames)
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/file1.fcs",
        customKeywords = list(`File Name` = "file1.fcs")
      )
    ),
    "sample2" = list(
      definition = list(
        uri = "/path/to/file2.fcs",
        customKeywords = list(`File Name` = "file2.fcs")
      )
    )
  )
  
  result <- filter_samples(c("sample1", "sample2"), c("file1.fcs"), dataSources, list())
  expect_equal(result, "sample1")
  
  # Test create_sample_names
  sample_uuids <- c("sample1", "sample2")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample1.fcs",
        customKeywords = list(`$TOT` = "10000")
      )
    ),
    "sample2" = list(
      definition = list(
        uri = "/path/to/sample2.fcs",
        customKeywords = list(`$TOT` = "15000")
      )
    )
  )
  
  # Basic naming
  result <- create_sample_names(sample_uuids, dataSources, character(), FALSE)
  expect_equal(as.vector(result), c("sample1.fcs", "sample2.fcs"))
  
  # With additional keys
  result <- create_sample_names(sample_uuids, dataSources, "$TOT", FALSE)
  expect_equal(as.vector(result), c("sample1.fcs_10000", "sample2.fcs_15000"))
  
  # Test extract_pdata
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
  expect_true(any(grepl("DATE", names(result))))
  expect_true(any(grepl("PATIENT", names(result))))
})

test_that("get_group_info handles various group structures", {
  # Test with empty groups
  groups <- list()
  result <- get_group_info(groups)
  expect_null(result)
  
  # Test with single group
  groups <- list(
    "group1" = list(
      definition = list(name = "Test Group 1"),
      results = list(dataSources = list("sample1", "sample2"))
    )
  )
  
  result <- get_group_info(groups)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "Test Group 1")
  expect_equal(result$n_samples, 2)
  
  # Test with group missing name
  groups <- list(
    "group1" = list(
      definition = list(),
      results = list(dataSources = list("sample1"))
    )
  )
  
  result <- get_group_info(groups)
  expect_s3_class(result, "data.frame")
  expect_equal(result$name, "Unnamed Group")
})

test_that("extract_keywords_for_samples works with different inputs", {
  sample_uuids <- c("sample1")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample1.fcs",
        customKeywords = list(`$DATE` = "01-Jan-2024", `PATIENT ID` = "P001")
      )
    )
  )
  
  # Test with valid keywords
  keywords <- c("$DATE", "PATIENT ID")
  result <- extract_keywords_for_samples(sample_uuids, dataSources, keywords)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_true(any(grepl("DATE", names(result))))
  expect_true(any(grepl("PATIENT", names(result))))
  expect_true("sample_uuid" %in% names(result))
  expect_true("filename" %in% names(result))
  
  # Test error with empty keywords
  expect_error(
    extract_keywords_for_samples(sample_uuids, dataSources, character()),
    "'keywords' must be specified"
  )
})

