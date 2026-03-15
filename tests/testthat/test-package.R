#' @title Package-level Tests
#' @name test-package
#' @keywords internal
NULL

context("Package Functions")

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