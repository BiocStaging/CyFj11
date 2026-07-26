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
  # Don't assume initial state - set known state and restore on exit
  on.exit(set_verbose(FALSE))

  # Test FALSE
  set_verbose(FALSE)
  expect_false(get_verbose())

  # Test TRUE
  set_verbose(TRUE)
  expect_true(get_verbose())

  # Test back to FALSE
  set_verbose(FALSE)
  expect_false(get_verbose())
})

test_that(".onLoad initializes package settings correctly", {
  # Save current state
  old_verbose <- get_verbose()
  old_sanitize <- get_sanitize_slashes()
  on.exit({
    set_verbose(old_verbose)
    set_sanitize_slashes(old_sanitize)
  })

  # Call .onLoad directly to test initialization
  # This simulates package load behavior
  CyFj11:::.onLoad("libname", "CyFj11")

  # Check that .onLoad sets verbose to FALSE
  expect_false(get_verbose())

  # Check that .onLoad sets sanitize_slashes to TRUE
  expect_true(get_sanitize_slashes())
})

test_that("set_sanitize_slashes and get_sanitize_slashes work correctly", {
  # Save current state
  old_sanitize <- get_sanitize_slashes()
  on.exit(set_sanitize_slashes(old_sanitize))

  # Test default (TRUE)
  set_sanitize_slashes(TRUE)
  expect_true(get_sanitize_slashes())

  # Test FALSE
  set_sanitize_slashes(FALSE)
  expect_false(get_sanitize_slashes())

  # Test back to TRUE
  set_sanitize_slashes(TRUE)
  expect_true(get_sanitize_slashes())
})
