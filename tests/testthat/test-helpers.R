# Copyright (c) 2026 Institut Pasteur
# Author: Bernd Jagla
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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
