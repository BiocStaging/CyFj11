#' @title Tests for Main Conversion Function
#' @name test-conversion-main
#' @keywords internal
NULL

context("Main Conversion Function")

# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

test_that("fj11_to_gatingset handles missing parameters", {
  # Test with missing required parameters
  expect_error(fj11_to_gatingset(), 
               "argument \"fj11_workspace\" is missing")
})

test_that("fj11_to_gatingset validates group_name parameter", {
  # Create a minimal mock workspace
  workspace <- list(
    groups = list(),
    dataSources = list(),
    populationDefinitions = list(),
    populations = list()
  )
  
  # Test with non-existent group name (this should fail differently)
  expect_error(
    fj11_to_gatingset(workspace, group_name = "NonExistentGroup"),
    "Group not found"
  )
})

test_that("fj11_to_gatingset requires path or cytoset", {
  # Create a minimal mock workspace
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
  
  # Test without path or cytoset
  expect_error(
    fj11_to_gatingset(workspace, group_name = 1, execute = FALSE),
    "Either 'path' or 'cytoset' must be provided"
  )
})

test_that("get_group_info returns correct structure", {
  # Test with empty groups
  groups <- list()
  result <- get_group_info(groups)
  expect_null(result)
  
  # Test with valid groups
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
})

test_that("filter_samples handles different input types", {
  sample_uuids <- c("sample1", "sample2", "sample3")
  
  # Test with empty subset
  result <- filter_samples(sample_uuids, list(), list(), list())
  expect_equal(result, sample_uuids)
  
  # Test with numeric indices
  result <- filter_samples(sample_uuids, c(1, 3), list(), list())
  expect_equal(result, c("sample1", "sample3"))
})

test_that("create_sample_names works with different configurations", {
  sample_uuids <- c("sample1")
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample1.fcs",
        customKeywords = list(`$TOT` = "10000")
      )
    )
  )
  
  # Test with no additional keys
  result <- create_sample_names(sample_uuids, dataSources, character(), FALSE)
  expect_equal(as.vector(result), "sample1.fcs")
  
  # Test with additional keys
  result <- create_sample_names(sample_uuids, dataSources, "$TOT", FALSE)
  expect_equal(as.vector(result), "sample1.fcs_10000")
})

test_that("extract_pdata works correctly", {
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
  expect_true("X.DATE" %in% names(result))
  expect_true("PATIENT.ID" %in% names(result))
})