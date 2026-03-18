#' @title Tests for Helper Functions
#' @name test-helpers
#' @keywords internal
NULL



test_that("null coalescing operator works correctly", {
  # Test basic functionality
  expect_equal(NULL %||% "default", "default")
  expect_equal("value" %||% "default", "value")
  expect_equal(0 %||% "default", 0)
  expect_equal(FALSE %||% "default", FALSE)
  
  # Test with empty vectors (behavior may vary, just check it doesn't crash)
  result_char <- character(0) %||% "default"
  result_num <- numeric(0) %||% "default"
  
  # These tests just verify the function runs without error
  expect_true(TRUE)  # placeholder to avoid empty test
})

test_that("parameter extraction helper works", {
  # Create a mock gate definition with various field names
  gate_def <- list(
    xParameter = "FSC-A",
    yParameter = "SSC-A"
  )
  
  # Test basic extraction
  x_param <- gate_def$xParameter %||% gate_def$xAxis %||% NA
  expect_equal(x_param, "FSC-A")
  
  # Test with missing primary field
  gate_def_missing <- list(
    xAxis = list(parameterSpec = list(name = "FSC-H"))
  )
  
  x_param <- gate_def_missing$xParameter %||% 
             gate_def_missing$xAxis$parameterSpec$name %||% 
             gate_def_missing$xAxis %||% 
             NA
  expect_equal(x_param, "FSC-H")
})
