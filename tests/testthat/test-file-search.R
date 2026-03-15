#' @title Tests for File Search Functionality
#' @name test-file-search
#' @keywords internal
NULL

context("File Search")

# Load required packages
skip_if_not_installed("digest")
library(digest)

test_that("search_fcs_files handles missing directory", {
  # Test with non-existent directory (should handle gracefully)
  expect_error(
    search_fcs_files("/nonexistent/directory"),
    "No valid root directories provided",
    fixed = TRUE
  )
})

test_that("search_fcs_files handles invalid inputs", {
  # Test with NULL root_dir
  expect_error(search_fcs_files(NULL), "root_dir must be provided")
  
  # Test with non-character root_dir
  expect_error(search_fcs_files(123), "root_dir must be character")
})

test_that("search_fcs_files returns correct structure", {
  # Test with current directory
  result <- search_fcs_files(".")
  expect_s3_class(result, "data.frame")
  
  # Check expected columns
  expected_cols <- c("filename", "full_path", "size_bytes", "mtime")
  expect_true(all(expected_cols %in% colnames(result)))
})

test_that("resolve_all_fcs_paths handles basic case", {
  # Create mock dataSources
  dataSources <- list(
    "sample1" = list(
      definition = list(
        uri = "/path/to/sample1.fcs",
        customKeywords = list(
          `File Name` = "sample1.fcs"
        )
      )
    )
  )
  
  # Test with nonexistent directory (should handle gracefully)
  expect_error(
    resolve_all_fcs_paths(dataSources, "/nonexistent/path"),
    "No valid root directories provided",
    fixed = TRUE
  )
})

test_that("get_sample_file_map works correctly", {
  # Create mock resolution results
  resolution_results <- data.frame(
    sample_id = c("sample1", "sample2", "sample3"),
    flowjo_uri = c("uri1", "uri2", "uri3"),
    filename = c("file1.fcs", "file2.fcs", "file3.fcs"),
    resolved_path = c("/path/file1.fcs", "/path/file2.fcs", "/path/file3.fcs"),
    status = c("FOUND", "FOUND", "NOT_FOUND"),
    stringsAsFactors = FALSE
  )
  
  # Test with default status (FOUND)
  result <- get_sample_file_map(resolution_results)
  expect_type(result, "character")
  expect_equal(length(result), 2)  # Only 2 FOUND samples
  expect_named(result, c("sample1", "sample2"))
  
  # Test with custom status
  result <- get_sample_file_map(resolution_results, include_status = c("FOUND", "NOT_FOUND"))
  expect_equal(length(result), 3)  # All 3 samples
})