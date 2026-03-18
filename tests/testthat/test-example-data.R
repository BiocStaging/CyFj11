#' @title Tests using Example FlowJo v11 Data
#' @name test-example-data
#' @keywords internal
NULL



test_that("Example FlowJo v11 file can be loaded and examined", {
  # Load the example data file
  test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if_not(file.exists(test_file), "Test FlowJo v11 file not found")
  
  # Show that we can load it
  workspace <- read_flowjo11_workspace(test_file)
  
  # Basic structure checks
  expect_s3_class(workspace, "flowjo11_workspace")
  expect_true(grepl("test.data.flowjo$", workspace$path))
  
  # Report what we found
  cat("Loaded FlowJo v11 workspace with:\n")
  cat("  -", length(workspace$groups), "groups\n")
  cat("  -", length(workspace$dataSources), "data sources\n")
  cat("  -", length(workspace$populationDefinitions), "population definitions\n")
  cat("  -", length(workspace$populations), "populations\n")
})

test_that("Example data can be used for gate extraction", {
  # Load the example data file
  test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if_not(file.exists(test_file), "Test FlowJo v11 file not found")
  
  # Load workspace
  workspace <- read_flowjo11_workspace(test_file)
  
  # Check that we can access population definitions
  expect_gt(length(workspace$populationDefinitions), 0)
  
  # Show how to iterate through populations
  population_names <- sapply(workspace$populationDefinitions, function(pop) {
    pop$definition$name
  })
  
  cat("Found populations:", paste(population_names, collapse = ", "), "\n")
})
