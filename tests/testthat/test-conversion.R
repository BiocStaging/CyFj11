#' @title Tests for Conversion Functionality
#' @name test-conversion
#' @keywords internal
NULL



# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

test_that("fj11_to_gatingset validates input parameters", {
  # Test with missing required parameters
  expect_error(fj11_to_gatingset(), 
               "argument \"fj11_workspace\" is missing")
})

test_that("fj11_to_gatingset handles missing workspace parameter", {
  # Test with missing fj11_workspace parameter
  expect_error(fj11_to_gatingset(),
               "argument \"fj11_workspace\" is missing",
               fixed = TRUE)
})

test_that("helper functions work correctly", {
  # Test get_group_info with empty groups
  # This would require mocking the groups structure
  
  # Test filter_samples with various inputs
  sample_uuids <- c("sample1", "sample2", "sample3")
  
  # With empty subset
  result <- filter_samples(sample_uuids, list(), list(), list())
  expect_equal(result, sample_uuids)
  
  # With numeric subset
  result <- filter_samples(sample_uuids, c(1, 3), list(), list())
  expect_equal(result, c("sample1", "sample3"))
})

test_that("build_gating_tree handles basic case", {
  # This function is complex and would require significant mocking
  # For now, just check that it exists
  expect_true(exists("build_gating_tree", where = asNamespace("CyFj11")))
})

test_that("find_root_population handles missing data", {
  # Test with empty populations
  populations <- list()
  populationDefinitions <- list()
  sample_uuid <- "sample1"
  
  expect_error(
    find_root_population(populations, populationDefinitions, sample_uuid),
    "Could not find root population definition"
  )
})
