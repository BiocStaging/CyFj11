#' @title Tests for Helper Functions
#' @name test-helper-functions
#' @keywords internal
NULL

context("Helper Functions")

test_that("load_example_workspace loads the example data correctly", {
  # This test verifies that our helper function works
  workspace <- load_example_workspace()
  
  # Check that we get the expected structure
  expect_s3_class(workspace, "flowjo11_workspace")
  expect_true(grepl("test.data.flowjo$", workspace$path))
  
  # Check that we have the expected components
  expect_type(workspace$manifest, "list")
  expect_type(workspace$json, "list")
  expect_type(workspace$groups, "list")
  expect_type(workspace$dataSources, "list")
  expect_type(workspace$populationDefinitions, "list")
  expect_type(workspace$populations, "list")
  
  # Report basic statistics
  cat("Example workspace contains:\n")
  cat("  -", length(workspace$groups), "groups\n")
  cat("  -", length(workspace$dataSources), "data sources\n")
  cat("  -", length(workspace$populationDefinitions), "population definitions\n")
  cat("  -", length(workspace$populations), "populations\n")
})

test_that("load_example_workspace provides access to real gate data", {
  # Load the workspace
  workspace <- load_example_workspace()
  
  # Check that we have population definitions
  expect_gt(length(workspace$populationDefinitions), 0)
  
  # Look at the first few population definitions
  pop_defs <- workspace$populationDefinitions
  first_pop_names <- sapply(head(pop_defs, 3), function(pop) {
    pop$definition$name
  })
  
  cat("First few populations:", paste(first_pop_names, collapse = ", "), "\n")
})