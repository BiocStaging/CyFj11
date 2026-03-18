#' @title Tests for Conversion Helper Functions
#' @name test-conversion-helpers
#' @keywords internal
NULL



# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

test_that("get_group_info works with valid groups", {
  # Create mock groups structure
  groups <- list(
    "group1" = list(
      definition = list(
        name = "Test Group 1"
      ),
      results = list(
        dataSources = list("sample1", "sample2")
      )
    ),
    "group2" = list(
      definition = list(
        name = "Test Group 2"
      ),
      results = list(
        dataSources = list("sample3")
      )
    )
  )
  
  result <- get_group_info(groups)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)
  expect_equal(result$name, c("Test Group 1", "Test Group 2"))
  expect_equal(result$n_samples, c(2, 1))
})

test_that("get_group_info handles missing names", {
  # Create mock groups with missing names
  groups <- list(
    "group1" = list(
      definition = list(),
      results = list(
        dataSources = list("sample1")
      )
    )
  )
  
  result <- get_group_info(groups)
  
  expect_s3_class(result, "data.frame")
  expect_equal(result$name, "Unnamed Group")
})

test_that("filter_samples works with numeric indices", {
  sample_uuids <- c("sample1", "sample2", "sample3", "sample4")
  
  # Test with numeric subset
  result <- filter_samples(sample_uuids, c(1, 3), list(), list())
  expect_equal(result, c("sample1", "sample3"))
  
  # Test with empty subset
  result <- filter_samples(sample_uuids, list(), list(), list())
  expect_equal(result, sample_uuids)
})

test_that("filter_samples works with character vectors", {
  sample_uuids <- c("sample1", "sample2", "sample3")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample1.fcs",
        customKeywords = list(`File Name` = "sample1.fcs")
      )
    ),
    "sample2" = list(
      definition = list(
        uri = "/path/to/sample2.fcs",
        customKeywords = list(`File Name` = "sample2.fcs")
      )
    )
  )
  
  # Test with filenames
  result <- filter_samples(sample_uuids, c("sample1.fcs"), dataSources, list())
  expect_equal(result, "sample1")
})

test_that("create_sample_names works correctly", {
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
  
  # Test basic functionality
  result <- create_sample_names(sample_uuids, dataSources, character(), FALSE)
  expect_equal(as.vector(result), c("sample1.fcs", "sample2.fcs"))
  
  # Test with additional keys
  result <- create_sample_names(sample_uuids, dataSources, "$TOT", FALSE)
  expect_equal(as.vector(result), c("sample1.fcs_10000", "sample2.fcs_15000"))
})

test_that("extract_pdata works with keywords", {
  sample_uuids <- c("sample1", "sample2")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        customKeywords = list(
          `$DATE` = "01-Jan-2024",
          `PATIENT ID` = "P001"
        )
      )
    ),
    "sample2" = list(
      definition = list(
        customKeywords = list(
          `$DATE` = "02-Jan-2024",
          `PATIENT ID` = "P002"
        )
      )
    )
  )
  
  keywords <- c("$DATE", "PATIENT ID")
  result <- extract_pdata(sample_uuids, dataSources, keywords, FALSE)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  # Check that the keywords are present in the column names (handling R sanitization)
  expect_true("X.DATE" %in% names(result))
  expect_true("PATIENT.ID" %in% names(result))
})

test_that("extract_keywords_for_samples works correctly", {
  sample_uuids <- c("sample1")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample1.fcs",
        customKeywords = list(
          `$DATE` = "01-Jan-2024",
          `PATIENT ID` = "P001"
        )
      )
    )
  )
  keywords <- c("$DATE", "PATIENT ID")
  
  result <- extract_keywords_for_samples(sample_uuids, dataSources, keywords)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  # Check that the keywords are present in the column names (handling R sanitization)
  expect_true("X.DATE" %in% names(result))
  expect_true("PATIENT.ID" %in% names(result))
  expect_true("sample_uuid" %in% names(result))
  expect_true("filename" %in% names(result))
})

test_that("extract_keywords_for_samples handles missing keywords", {
  sample_uuids <- c("sample1")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample1.fcs",
        customKeywords = list()
      )
    )
  )
  keywords <- c("$DATE", "PATIENT ID")
  
  expect_error(
    extract_keywords_for_samples(sample_uuids, dataSources, character()),
    "'keywords' must be specified"
  )
})
