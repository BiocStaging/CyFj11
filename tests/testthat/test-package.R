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

#' @title Package-level Tests
#' @name test-package
#' @keywords internal
NULL



test_that("Package loads correctly", {
  expect_true(requireNamespace("CyFj11", quietly = TRUE))
  
  # Test that exported functions are available
  expect_true(exists("export_flowjo10_workspace", where = asNamespace("CyFj11")))
  expect_true(exists("read_flowjo11_workspace", where = asNamespace("CyFj11")))
  expect_true(exists("fj11_to_gatingset", where = asNamespace("CyFj11")))
  expect_true(exists("pretty_print_flowjo", where = asNamespace("CyFj11")))
  expect_true(exists("set_verbose", where = asNamespace("CyFj11")))
  expect_true(exists("get_verbose", where = asNamespace("CyFj11")))
})

test_that("Verbose mode functions work", {
  # Test initial state
  initial_state <- get_verbose()
  expect_false(initial_state)
  
  # Test setting to TRUE
  set_verbose(TRUE)
  expect_true(get_verbose())
  
  # Test setting to FALSE
  set_verbose(FALSE)
  expect_false(get_verbose())
  
  # Restore initial state
  set_verbose(initial_state)
})
