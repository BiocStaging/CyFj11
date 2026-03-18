#' @title Tests for Population-related Conversion Functions
#' @name test-conversion-populations
#' @keywords internal
NULL



# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

test_that("find_root_population handles missing root population", {
  # Create mock populations and populationDefinitions where population doesn't match sample
  populations <- list(
    "pop1" = list(
      populationReference = "popdef-root",
      parents = list(
        `_dataSource` = list("sample2")  # Different sample
      )
    )
  )
  
  populationDefinitions <- list(
    "popdef-root" = list(
      definition = list(
        type = "root"
      )
    )
  )
  
  sample_uuid <- "sample1"  # Different sample
  
  expect_error(
    find_root_population(populations, populationDefinitions, sample_uuid),
    "Could not find root population for sample: sample1"
  )
})

test_that("find_root_population handles missing root", {
  populations <- list()
  populationDefinitions <- list()
  sample_uuid <- "sample1"
  
  expect_error(
    find_root_population(populations, populationDefinitions, sample_uuid),
    "Could not find root population definition"
  )
})

test_that("find_root_population works with parentPopulation = NULL", {
  # Create mock populations with parentPopulation = NULL for root but different sample
  populations <- list(
    "pop1" = list(
      parentPopulation = NULL,
      parents = list(
        `_dataSource` = list("sample2")  # Different sample
      )
    )
  )
  
  populationDefinitions <- list(
    "popdef-root" = list(
      definition = list(
        type = "root"
      )
    )
  )
  
  sample_uuid <- "sample1"  # Different sample
  
  expect_error(
    find_root_population(populations, populationDefinitions, sample_uuid),
    "Could not find root population for sample: sample1"
  )
})

# Test the gating tree building functions
test_that("identify_logical_gates works with empty data", {
  populations <- list()
  populationDefinitions <- list()
  
  result <- identify_logical_gates(populations, populationDefinitions)
  
  expect_type(result, "list")
  expect_named(result, c("gates", "populationDefinitions"))
  expect_equal(length(result$gates), 0)
})

test_that("deduplicate_tree works with empty tree", {
  tree <- list()
  result <- deduplicate_tree(tree)
  expect_equal(result, tree)
})

test_that("deduplicate_tree works with simple tree", {
  tree <- list(
    uuid = "root",
    children = list(
      list(uuid = "child1"),
      list(uuid = "child1"),  # Duplicate
      list(uuid = "child2")
    )
  )
  
  result <- deduplicate_tree(tree)
  
  expect_equal(length(result$children), 2)
  expect_equal(sapply(result$children, function(x) x$uuid), c("child1", "child2"))
})

test_that("find_gate_info works correctly", {
  logical_gates_info <- list(
    list(population_uuid = "pop1", gate_type = "and"),
    list(population_uuid = "pop2", gate_type = "or")
  )
  
  result <- find_gate_info("pop1", logical_gates_info)
  expect_equal(result$gate_type, "and")
  
  result <- find_gate_info("pop3", logical_gates_info)
  expect_null(result)
})

test_that("create_logical_gate_summary works with empty data", {
  result <- create_logical_gate_summary(list())
  expect_null(result)
})

test_that("create_logical_gate_summary works with data", {
  logical_gates <- list(
    list(
      gate_name = "Test Gate",
      gate_type = "and",
      population_uuid = "pop1",
      num_components = 2,
      combined_populations = c("Pop A", "Pop B")
    )
  )
  
  result <- create_logical_gate_summary(logical_gates)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$gate_name, "Test Gate")
  expect_equal(result$gate_type, "and")
})

test_that("summarize_logical_gates works with empty tree", {
  tree <- list()
  result <- summarize_logical_gates(tree)
  expect_null(result)
})

test_that("summarize_logical_gates works with logical gates", {
  tree <- list(
    name = "root",
    children = list(
      list(
        name = "Test Gate",
        type = "and",
        uuid = "pop1",
        logical_gate_info = list(
          combined_populations = c("Pop A", "Pop B"),
          num_components = 2
        )
      )
    )
  )
  
  result <- summarize_logical_gates(tree)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "Test Gate")
  expect_equal(result$type, "and")
})

test_that("move_logical_gates_up works with empty tree", {
  tree <- list()
  result <- move_logical_gates_up(tree)
  expect_equal(result, tree)
})

test_that("get_uuids works correctly", {
  tree <- list(
    uuid = "root",
    children = list(
      list(uuid = "child1"),
      list(uuid = "child2",
           children = list(
             list(uuid = "grandchild1")
           ))
    )
  )
  
  result <- get_uuids(tree)
  
  expect_type(result, "character")
  expect_true("root" %in% result)
  expect_true("child1" %in% result)
  expect_true("child2" %in% result)
  expect_true("grandchild1" %in% result)
})
