# Testing Guide

This directory contains tests for the CyFj11 package. Tests are written using the testthat framework.

## Running Tests

To run all tests:

```r
devtools::test()
```

To run specific test files:

```r
devtools::test_file("tests/testthat/test-archive.R")
```

## Test Data

### Example FlowJo v11 Workspace

We include an example FlowJo v11 workspace file at `inst/extdata/test.data.flowjo` that can be used for testing purposes.

#### Loading the Example Data

```r
# Load the example workspace
workspace <- load_example_workspace()

# Or load directly
test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
workspace <- read_flowjo11_workspace(test_file)
```

#### Using in Tests

See `tests/testthat/test-example-data.R` and `tests/testthat/test-helper-functions.R` for examples of how to use the example data in tests.

### Mock Data

The `helper-data.R` file contains functions to create mock data for testing when you don't want to rely on external files:

- `create_mock_workspace()` - Creates a minimal mock FlowJo v11 workspace structure
- `create_mock_fcs_files()` - Creates mock FCS files (requires flowCore)
- `load_example_workspace()` - Loads the real example FlowJo v11 workspace

## Test Organization

Tests are organized by functionality:

- `test-archive.R` - Tests for archive processing functions
- `test-conversion.R` - Tests for data conversion functions
- `test-example-data.R` - Tests specifically for the example data
- `test-export-flowjo10.R` - Tests for FlowJo v10 export functionality
- `test-file-search.R` - Tests for FCS file search functions
- `test-helper-functions.R` - Tests for helper functions
- `test-helpers.R` - Tests for utility functions
- `test-package.R` - Tests for package-level functions
- `test-pretty-print.R` - Tests for pretty printing functions

## Writing New Tests

When writing new tests that need FlowJo workspace data, you can either:

1. Use the mock data functions for unit tests that don't depend on specific gate structures
2. Use the example workspace for integration tests that need real FlowJo data
3. Create specific test data for edge cases

Example of using the example data in a test:

```r
test_that("my function works with real FlowJo data", {
  # Skip if the test file doesn't exist
  test_file <- system.file("extdata", "test.data.flowjo", package = "CyFj11")
  skip_if_not(file.exists(test_file), "Test FlowJo v11 file not found")
  
  # Load the workspace
  workspace <- read_flowjo11_workspace(test_file)
  
  # Test your function
  result <- my_function(workspace)
  
  # Make assertions
  expect_type(result, "list")
})