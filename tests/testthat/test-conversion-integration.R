#' @title Integration Tests for Conversion Functions
#' @name test-conversion-integration
#' @keywords internal
NULL



test_that("Can analyze workspace structure for conversion", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check that we have the required components for conversion
  expect_true("groups" %in% names(workspace))
  expect_true("dataSources" %in% names(workspace))
  expect_true("populationDefinitions" %in% names(workspace))
  expect_true("populations" %in% names(workspace))
  
  cat("Workspace has all required components for conversion\n")
})

test_that("Groups contain necessary information", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check groups
  expect_gt(length(workspace$groups), 0)
  
  # Check that groups have structure
  first_group_uuid <- names(workspace$groups)[1]
  first_group <- workspace$groups[[first_group_uuid]]
  
  # Groups should have some structure even if not exactly as expected
  expect_true(is.list(first_group))
  expect_gt(length(first_group), 0)
  
  cat("First group has", length(first_group), "elements\n")
})

test_that("Data sources have URIs for FCS files", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check data sources
  expect_gt(length(workspace$dataSources), 0)
  
  # Check that data sources have URIs
  uri_count <- 0
  for (source_uuid in names(workspace$dataSources)) {
    source <- workspace$dataSources[[source_uuid]]
    if ("definition" %in% names(source) && 
        "uri" %in% names(source$definition)) {
      uri <- source$definition$uri
      if (nchar(uri) > 0) {
        uri_count <- uri_count + 1
      }
    }
  }
  
  cat("Found", uri_count, "data sources with valid URIs\n")
  expect_gt(uri_count, 0)
})

test_that("Population definitions have names", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check population definitions
  expect_gt(length(workspace$populationDefinitions), 0)
  
  # Check that population definitions have names
  name_count <- 0
  for (pop_uuid in names(workspace$populationDefinitions)) {
    pop_def <- workspace$populationDefinitions[[pop_uuid]]
    if ("definition" %in% names(pop_def) && 
        "name" %in% names(pop_def$definition)) {
      name <- pop_def$definition$name
      if (length(name) > 0 && !is.null(name[[1]]) && nchar(as.character(name[[1]])) > 0) {
        name_count <- name_count + 1
      }
    }
  }
  
  cat("Found", name_count, "population definitions with names\n")
  expect_gt(name_count, 0)
})

test_that("Can identify gate types in population definitions", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check that population definitions have types
  type_count <- 0
  for (pop_uuid in names(workspace$populationDefinitions)) {
    pop_def <- workspace$populationDefinitions[[pop_uuid]]
    if ("definition" %in% names(pop_def) && 
        "type" %in% names(pop_def$definition)) {
      gate_type <- pop_def$definition$type
      if (length(gate_type) > 0 && !is.null(gate_type) && nchar(as.character(gate_type)) > 0) {
        type_count <- type_count + 1
      }
    }
  }
  
  cat("Found", type_count, "population definitions with gate types\n")
  expect_gt(type_count, 0)
})

test_that("Workspace has hierarchical population structure", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check that populations have parent-child relationships
  parent_count <- 0
  child_count <- 0
  
  for (pop_uuid in names(workspace$populations)) {
    pop <- workspace$populations[[pop_uuid]]
    if ("parents" %in% names(pop)) {
      parents <- pop$parents
      if (length(parents) > 0) {
        parent_count <- parent_count + 1
      }
    }
    if ("children" %in% names(pop)) {
      children <- pop$children
      if (length(children) > 0) {
        child_count <- child_count + 1
      }
    }
  }
  
  cat("Found", parent_count, "populations with parents\n")
  cat("Found", child_count, "populations with children\n")
  
  # Should have some hierarchical structure
  expect_gt(parent_count + child_count, 0)
})

test_that("Can extract sample UUIDs from data sources", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Extract sample UUIDs
  sample_uuids <- names(workspace$dataSources)
  
  cat("Found", length(sample_uuids), "sample UUIDs\n")
  expect_gt(length(sample_uuids), 0)
  
  # Check that they look like UUIDs
  first_uuid <- sample_uuids[1]
  expect_match(first_uuid, "^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$")
})

test_that("Population definitions contain gate parameters", {
  # Load the example workspace
  workspace <- load_example_workspace()
  
  # Check for gate parameters in population definitions
  param_count <- 0
  for (pop_uuid in names(workspace$populationDefinitions)) {
    pop_def <- workspace$populationDefinitions[[pop_uuid]]
    if ("definition" %in% names(pop_def) && 
        "gateDefinition" %in% names(pop_def$definition)) {
      gate_def <- pop_def$definition$gateDefinition
      # Check for common gate parameters
      if ("xParameter" %in% names(gate_def) || 
          "yParameter" %in% names(gate_def) ||
          "xAxis" %in% names(gate_def) ||
          "yAxis" %in% names(gate_def)) {
        param_count <- param_count + 1
      }
    }
  }
  
  cat("Found", param_count, "population definitions with gate parameters\n")
  expect_gt(param_count, 0)
})
