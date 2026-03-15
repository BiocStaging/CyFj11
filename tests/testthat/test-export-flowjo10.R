#' @title Unit Tests for FlowJo v10 Export Functionality
#' @name test-export-flowjo10
#' @keywords internal
NULL

context("FlowJo v10 Export Tests")

# Skip tests if required packages are not available
skip_if_not_installed <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    skip(paste0(pkg, " package not available"))
  }
}

# Load required packages
skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

# Test utilities
create_test_fcs <- function(n = 10000, seed = 123) {
  skip_if_not_installed("flowCore")
  library(flowCore)
  
  set.seed(seed)
  
  # Base scatter channels
  fsc_a <- rnorm(n, mean = 120000, sd = 30000)
  fsc_h <- fsc_a * runif(n, 0.9, 1.1)
  ssc_a <- rnorm(n, mean = 80000, sd = 20000)
  ssc_h <- ssc_a * runif(n, 0.9, 1.1)
  
  # Fluorescence channels (bimodal)
  fitc_a <- c(rlnorm(n * 0.7, 2, 0.8), rlnorm(n * 0.3, 8, 0.5))[1:n]
  pe_a <- c(rlnorm(n * 0.6, 2.5, 0.7), rlnorm(n * 0.4, 7.5, 0.6))[1:n]
  apc_a <- c(rlnorm(n * 0.8, 1.8, 0.9), rlnorm(n * 0.2, 7.2, 0.5))[1:n]
  percpcy55_a <- c(rlnorm(n * 0.75, 2.2, 0.75), rlnorm(n * 0.25, 7.8, 0.55))[1:n]
  
  clamp <- function(x) pmin(pmax(x, 0), 262144)
  
  mat <- cbind(
    clamp(fsc_a), clamp(fsc_h), clamp(ssc_a), clamp(ssc_h),
    clamp(fitc_a), clamp(pe_a), clamp(apc_a), clamp(percpcy55_a)
  )
  colnames(mat) <- c("FSC-A", "FSC-H", "SSC-A", "SSC-H",
                     "FITC-A", "PE-A", "APC-A", "PerCP-Cy5-5-A")
  
  params <- new("AnnotatedDataFrame",
    data = data.frame(
      name = colnames(mat),
      desc = c("FSC-A", "FSC-H", "SSC-A", "SSC-H", "CD3", "CD4", "CD8", "CD14"),
      range = rep(262144, ncol(mat)),
      minRange = rep(0, ncol(mat)),
      maxRange = rep(262144, ncol(mat)),
      row.names = colnames(mat),
      stringsAsFactors = FALSE
    )
  )
  
  ff <- new("flowFrame",
            exprs = mat,
            parameters = params,
            description = list(
              `$FIL` = sprintf("test_sample_%03d.fcs", seed),
              FILENAME = sprintf("test_sample_%03d.fcs", seed),
              `$TOT` = as.character(n),
              `$PAR` = as.character(ncol(mat))
            ))
  return(ff)
}

test_that("export_flowjo10_workspace works with minimal GatingSet", {
  # skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create minimal test data
  ff <- create_test_fcs(n = 5000, seed = 1)
  
  # Create GatingSet with only root population
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Test export to temporary file
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
})

test_that("export_flowjo10_workspace handles 1D rectangle gate", {
  # skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 5000, seed = 2)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add 1D gate
  gate <- rectangleGate(filterId = "FSC_filter", "FSC-A" = c(60000, 180000))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("RectangleGate", xml_content)))
  expect_true(any(grepl("FSC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles 2D rectangle gate", {
  # skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 5000, seed = 3)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add 2D gate
  gate <- rectangleGate(
    filterId = "cells",
    "FSC-A" = c(60000, 180000),
    "SSC-A" = c(40000, 130000)
  )
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("RectangleGate", xml_content)))
  expect_true(any(grepl("FSC-A", xml_content)))
  expect_true(any(grepl("SSC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles polygon gate", {
  # skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 4)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add polygon gate
  gate <- polygonGate(
    filterId = "singlets",
    "FSC-A" = c(50000, 70000, 160000, 190000, 180000, 60000),
    "FSC-H" = c(45000, 40000, 140000, 180000, 190000, 80000)
  )
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("PolygonGate", xml_content)))
  expect_true(any(grepl("FSC-A", xml_content)))
  expect_true(any(grepl("FSC-H", xml_content)))
})

test_that("convert_ellipsoid_to_flowjo10 works with valid ellipsoid gate", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 13)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add ellipsoid gate
  ellipse_cov <- matrix(c(1.5e9, 7e8, 7e8, 1e9), ncol = 2)
  colnames(ellipse_cov) <- rownames(ellipse_cov) <- c("FSC-A", "SSC-A")
  
  gate <- ellipsoidGate(
    filterId = "ellipse_cells",
    .gate = ellipse_cov,
    mean = c("FSC-A" = 120000, "SSC-A" = 80000),
    distance = 2
  )
  
  # Test conversion function directly
  result <- CyFj11:::convert_ellipsoid_to_flowjo10(gate, "ellipse_cells", gs[[1]])
  
  expect_type(result, "list")
  expect_equal(result$type, "ellipsoid")
  expect_equal(names(result$x_param), "FSC-A")
  expect_equal(names(result$y_param), "SSC-A")
  expect_true(is.numeric(result$distance))
  expect_true(result$distance > 0)
  expect_type(result$foci, "list")
  expect_length(result$foci, 2)
  expect_type(result$edge, "list")
  expect_length(result$edge, 4)
})

test_that("convert_ellipsoid_to_flowjo10 handles invalid ellipsoid gate gracefully", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Test with NULL gate
  result <- convert_ellipsoid_to_flowjo10(NULL, "invalid_gate", NULL)
  expect_null(result)
  
  # Test with gate with missing parameters
  # Create a minimal gate-like object without required fields
  invalid_gate <- structure(list(), class = "ellipsoidGate")
  result <- convert_ellipsoid_to_flowjo10(invalid_gate, "invalid_gate", NULL)
  expect_null(result)
})

test_that("convert_boolean_to_flowjo10 works with AND boolean gate", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 14)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add two independent gates
  gate1 <- rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000))
  gs_pop_add(gs, gate1, parent = "root")
  
  gate2 <- rectangleGate(filterId = "SSC_gate", "SSC-A" = c(50000, 130000))
  gs_pop_add(gs, gate2, parent = "root")
  
  recompute(gs)
  
  # Boolean AND
  bool_gate <- booleanFilter(`FSC_gate&SSC_gate`, filterId = "both")
  
  # Test conversion function directly
  result <- convert_boolean_to_flowjo10(bool_gate, "both", gs[[1]])
  
  expect_type(result, "list")
  expect_equal(result$type, "boolean")
  expect_equal(result$op_type, "and")
  expect_true("FSC_gate" %in% result$dependents)
  expect_true("SSC_gate" %in% result$dependents)
  expect_false(is.null(result$expression))
})

test_that("convert_boolean_to_flowjo10 works with OR boolean gate", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 15)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add two independent gates
  gate1 <- rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000))
  gs_pop_add(gs, gate1, parent = "root")
  
  gate2 <- rectangleGate(filterId = "SSC_gate", "SSC-A" = c(50000, 130000))
  gs_pop_add(gs, gate2, parent = "root")
  
  recompute(gs)
  
  # Boolean OR
  bool_gate <- booleanFilter(`FSC_gate|SSC_gate`, filterId = "either")
  
  # Test conversion function directly
  result <- convert_boolean_to_flowjo10(bool_gate, "either", gs[[1]])
  
  expect_type(result, "list")
  expect_equal(result$type, "boolean")
  expect_equal(result$op_type, "or")
  expect_true("FSC_gate" %in% result$dependents)
  expect_true("SSC_gate" %in% result$dependents)
  expect_false(is.null(result$expression))
})

test_that("convert_boolean_to_flowjo10 works with NOT boolean gate", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 16)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add a gate to negate
  gate1 <- rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000))
  gs_pop_add(gs, gate1, parent = "root")
  
  recompute(gs)
  
  # Boolean NOT
  bool_gate <- booleanFilter(!`FSC_gate`, filterId = "not_FSC")
  
  # Test conversion function directly
  result <- convert_boolean_to_flowjo10(bool_gate, "not_FSC", gs[[1]])
  
  expect_type(result, "list")
  expect_equal(result$type, "boolean")
  expect_equal(result$op_type, "not")
  expect_true("FSC_gate" %in% result$dependents)
  expect_false(is.null(result$expression))
})

test_that("convert_boolean_to_flowjo10 handles invalid boolean gate gracefully", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Test with NULL gate
  result <- convert_boolean_to_flowjo10(NULL, "invalid_gate", NULL)
  expect_null(result)
  
  # Test with gate with missing expression
  # Create a minimal gate-like object without required fields
  invalid_gate <- structure(list(), class = "booleanFilter")
  result <- convert_boolean_to_flowjo10(invalid_gate, "invalid_gate", NULL)
  expect_null(result)
})

test_that("convert_boolean_to_flowjo10 handles complex boolean expressions", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Test with complex expression - this tests the parsing logic more thoroughly
  # We'll create a mock booleanFilter with a complex expression
  complex_expr <- expression(`gate1` & `gate2` | `gate3`)
  class(complex_expr) <- "booleanFilter"
  attr(complex_expr, "expr") <- complex_expr
  
  # Test conversion function with complex expression
  result <- convert_boolean_to_flowjo10(complex_expr, "complex_gate", NULL)
  
  # Should still return a list even if parsing is imperfect
  expect_type(result, "list")
  expect_equal(result$type, "boolean")
  expect_false(is.null(result$expression))
  
  # Test with another complex form
  complex_expr2 <- expression(!`gate1` & `gate2`)
  class(complex_expr2) <- "booleanFilter"
  attr(complex_expr2, "expr") <- complex_expr2
  
  result2 <- convert_boolean_to_flowjo10(complex_expr2, "complex_gate2", NULL)
  expect_type(result2, "list")
  expect_equal(result2$type, "boolean")
  expect_false(is.null(result2$expression))
})

test_that("export_flowjo10_workspace handles ellipsoid gate", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 5)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add ellipsoid gate
  ellipse_cov <- matrix(c(1.5e9, 7e8, 7e8, 1e9), ncol = 2)
  colnames(ellipse_cov) <- rownames(ellipse_cov) <- c("FSC-A", "SSC-A")
  
  gate <- ellipsoidGate(
    filterId = "ellipse_cells",
    .gate = ellipse_cov,
    mean = c("FSC-A" = 120000, "SSC-A" = 80000),
    distance = 2
  )
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("EllipsoidGate", xml_content)))
  expect_true(any(grepl("FSC-A", xml_content)))
  expect_true(any(grepl("SSC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles boolean gates", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 10)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add two independent gates
  gate1 <- rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000))
  gs_pop_add(gs, gate1, parent = "root")
  
  gate2 <- rectangleGate(filterId = "SSC_gate", "SSC-A" = c(50000, 130000))
  gs_pop_add(gs, gate2, parent = "root")
  
  recompute(gs)
  
  # Boolean AND
  bool_gate <- booleanFilter(`FSC_gate&SSC_gate`, filterId = "both")
  gs_pop_add(gs, bool_gate, parent = "root")
  
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("AndNode", xml_content)))
  expect_true(any(grepl("FSC_gate", xml_content)))
  expect_true(any(grepl("SSC_gate", xml_content)))
})

test_that("export_flowjo10_workspace handles OR boolean gates", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 11)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add two independent gates
  gate1 <- rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000))
  gs_pop_add(gs, gate1, parent = "root")
  
  gate2 <- rectangleGate(filterId = "SSC_gate", "SSC-A" = c(50000, 130000))
  gs_pop_add(gs, gate2, parent = "root")
  
  recompute(gs)
  
  # Boolean OR
  bool_gate <- booleanFilter(`FSC_gate|SSC_gate`, filterId = "either")
  gs_pop_add(gs, bool_gate, parent = "root")
  
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("OrNode", xml_content)))
  expect_true(any(grepl("FSC_gate", xml_content)))
  expect_true(any(grepl("SSC_gate", xml_content)))
})

test_that("export_flowjo10_workspace handles NOT boolean gates", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 12)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add a gate to negate
  gate1 <- rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000))
  gs_pop_add(gs, gate1, parent = "root")
  
  recompute(gs)
  
  # Boolean NOT
  bool_gate <- booleanFilter(!`FSC_gate`, filterId = "not_FSC")
  gs_pop_add(gs, bool_gate, parent = "root")
  
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("NotNode", xml_content)))
  expect_true(any(grepl("FSC_gate", xml_content)))
})

test_that("export_flowjo10_workspace handles NOT boolean gates with polygon gate", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 13)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add a polygon gate to negate
  polygon_gate <- polygonGate(
    filterId = "poly_gate",
    "FSC-A" = c(50000, 70000, 160000, 190000, 180000, 60000),
    "FSC-H" = c(45000, 40000, 140000, 180000, 190000, 80000)
  )
  gs_pop_add(gs, polygon_gate, parent = "root")
  
  recompute(gs)
  
  # Boolean NOT with polygon gate
  bool_gate <- booleanFilter(!`poly_gate`, filterId = "not_poly")
  gs_pop_add(gs, bool_gate, parent = "root")
  
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("NotNode", xml_content)))
  expect_true(any(grepl("poly_gate", xml_content)))
})

test_that("export_flowjo10_workspace handles NOT boolean gates with ellipsoid gate", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 14)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add an ellipsoid gate to negate
  ellipse_cov <- matrix(c(1.5e9, 7e8, 7e8, 1e9), ncol = 2)
  colnames(ellipse_cov) <- rownames(ellipse_cov) <- c("FSC-A", "SSC-A")
  
  ellipsoid_gate <- ellipsoidGate(
    filterId = "ellipse_gate",
    .gate = ellipse_cov,
    mean = c("FSC-A" = 120000, "SSC-A" = 80000),
    distance = 2
  )
  gs_pop_add(gs, ellipsoid_gate, parent = "root")
  
  recompute(gs)
  
  # Boolean NOT with ellipsoid gate
  bool_gate <- booleanFilter(!`ellipse_gate`, filterId = "not_ellipse")
  gs_pop_add(gs, bool_gate, parent = "root")
  
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("NotNode", xml_content)))
  expect_true(any(grepl("ellipse_gate", xml_content)))
})

test_that("get_transform_spec handles biexponential transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 15)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply biex transform
  biexp_trans <- flowjo_biexp_trans(
    channelRange = 4096,
    maxValue = 262144,
    pos = 4.5,
    neg = 0,
    widthBasis = -10
  )
  trans_list <- transformerList("FITC-A", biexp_trans)
  gs <- flowCore::transform(gs, trans_list)
  
  # Get gating hierarchy
  gh <- gs[[1]]
  
  # Test the function
  result <- CyFj11:::get_transform_spec(gh, "FITC-A")
  
  expect_type(result, "list")
  expect_equal(result$transformType, "Biex")
  expect_equal(result$T, 262144)
  expect_equal(result$A, 0)
  expect_equal(result$M, 4.5)
  expect_equal(result$W, -10)
  expect_equal(result$vectorLength, 4096)
  expect_false(result$autoWidthBasis)
})


test_that("get_transform_spec handles log transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 17)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply log transform
  log_trans <- logtGml2_trans(t = 1e3, m = 1, equal.space = TRUE)
  trans_list <- transformerList("FITC-A", log_trans)
  gs <- flowCore::transform(gs, trans_list)
  
  # Get gating hierarchy
  gh <- gs[[1]]
  
  # Test the function
  result <- CyFj11:::get_transform_spec(gh, "FITC-A")
  
  expect_type(result, "list")
  expect_equal(result$transformType, "Log")
  expect_equal(result$base, 10)
  expect_equal(result$offset, 1)
  expect_equal(result$decade, 1)
})

test_that("get_transform_spec handles logtGml2 transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 18)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply logtGml2 transform
  logt_trans <- logtGml2_trans()
  trans_list <- transformerList("FITC-A", logt_trans)
  gs <- flowCore::transform(gs, trans_list)
  
  # Get gating hierarchy
  gh <- gs[[1]]
  
  # Test the function
  result <- CyFj11:::get_transform_spec(gh, "FITC-A")
  
  expect_type(result, "list")
  expect_equal(result$transformType, "Log")
  expect_equal(result$base, 10)
  expect_equal(result$offset, 1)
  expect_equal(result$decade, 1)
})

test_that("get_transform_spec handles logicle transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 19)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply logicle transform
  logicle_trans <- logicle_trans(t = 262144, w = 0.5, m = 4.5, a = 0)
  trans_list <- transformerList("FITC-A", logicle_trans)
  gs <- flowCore::transform(gs, trans_list)
  
  # Get gating hierarchy
  gh <- gs[[1]]
  
  # Test the function
  result <- CyFj11:::get_transform_spec(gh, "FITC-A")
  
  expect_type(result, "list")
  expect_equal(result$transformType, "Logicle")
  expect_equal(result$T, 262144)
  expect_equal(result$M, 4.5)
  expect_equal(result$W, 0.5)
  expect_equal(result$A, 0)
})

test_that("get_transform_spec handles fasinh transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 20)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply fasinh transform
  fasinh_trans <- flowjo_fasinh_trans(m = 1, t = 10, a = 1)
  trans_list <- transformerList("FITC-A", fasinh_trans)
  gs <- flowCore::transform(gs, trans_list)
  
  # Get gating hierarchy
  gh <- gs[[1]]
  
  # Test the function
  result <- CyFj11:::get_transform_spec(gh, "FITC-A")
  
  expect_type(result, "list")
  expect_equal(result$transformType, "Arcsinh")
  expect_equal(result$a, 0)
  expect_equal(result$b, 1/150)
  expect_equal(result$c, 0)
})

test_that("get_transform_spec handles arcsinh transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 21)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply arcsinh transform (mock)
  # We'll create a mock transformation with arcsinh type
  arcsinh_trans <- flowjo_fasinh_trans(m = 1, t = 10, a = 1)
  # Manually set the type to "arcsinh" to test that path
  attr(arcsinh_trans, "type") <- "arcsinh"
  trans_list <- transformerList("FITC-A", arcsinh_trans)
  gs <- flowCore::transform(gs, trans_list)
  
  # Get gating hierarchy
  gh <- gs[[1]]
  
  # Test the function
  result <- CyFj11:::get_transform_spec(gh, "FITC-A")
  
  expect_type(result, "list")
  expect_equal(result$transformType, "Arcsinh")
  expect_equal(result$a, 0)
  expect_equal(result$b, 1/150)
  expect_equal(result$c, 0)
})


test_that("export_flowjo10_workspace handles biexponential transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 6)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply biex transform
  biexp_trans <- flowjo_biexp_trans(
    channelRange = 4096,
    maxValue = 262144,
    pos = 4.5,
    neg = 0,
    widthBasis = -10
  )
  trans_list <- transformerList("FITC-A", biexp_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  # Add gate on transformed data
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1000, 3000))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("biex", xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})


test_that("export_flowjo10_workspace handles log transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 8)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply log transform
  log_trans <- logtGml2_trans(t = 1e3, m = 1, equal.space = TRUE)
  trans_list <- transformerList("FITC-A", log_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  # Add gate on transformed data
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log", xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles logtGml2 transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 9)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply logtGml2 transform
  logt_trans <- logtGml2_trans()
  trans_list <- transformerList("FITC-A", logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  # Add gate on transformed data
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log", xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

# test_that("export_flowjo10_workspace handles logicle transformation", {
#   skip_on_cran()
#   skip_if_not_installed("flowWorkspace")
#   skip_if_not_installed("flowCore")
#   
#   library(flowWorkspace)
#   library(flowCore)
#   
#   # Create test data
#   ff <- create_test_fcs(n = 8000, seed = 10)
#   fs <- flowSet(ff)
#   gs <- GatingSet(fs)
#   
#   # Apply logicle transform
#   logicle_trans <- logicletGml2(parameters = "FSC-H", T = 1023, M = 4.5, 
#                                 W = 0.5, A = 0, transformationId="myLogicle")
#   trans_list <- transformerList("FITC-A", logicle_trans)
#   gs <- flowWorkspace::transform(gs, trans_list)
#   
#   # Add gate on transformed data
#   gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1000, 3000))
#   gs_pop_add(gs, gate, parent = "root")
#   recompute(gs)
#   
#   # Test export
#   temp_file <- tempfile(fileext = ".wsp")
#   on.exit(unlink(temp_file))
#   
#   expect_true(export_flowjo10_workspace(gs, temp_file))
#   expect_true(file.exists(temp_file))
#   expect_gt(file.size(temp_file), 0)
#   
#   # Check that XML contains expected elements
#   xml_content <- readLines(temp_file)
#   expect_true(any(grepl("Logicle", xml_content, ignore.case = TRUE)))
#   expect_true(any(grepl("FITC-A", xml_content)))
# })

test_that("export_flowjo10_workspace handles fasinh transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 11)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply fasinh transform
  fasinh_trans <- flowjo_fasinh_trans(m = 1, t = 10, a = 1)
  trans_list <- transformerList("FITC-A", fasinh_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  # Add gate on transformed data
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1000, 3000))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("fasinh", xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles hierarchical gates", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 10000, seed = 9)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Level 1: Parent gate
  parent_gate <- rectangleGate(
    filterId = "cells",
    "FSC-A" = c(60000, 190000),
    "SSC-A" = c(40000, 140000)
  )
  gs_pop_add(gs, parent_gate, parent = "root")
  recompute(gs)
  
  # Level 2: Child gate
  child_gate <- rectangleGate(
    filterId = "singlets",
    "FSC-A" = c(70000, 180000),
    "FSC-H" = c(60000, 170000)
  )
  gs_pop_add(gs, child_gate, parent = "/cells")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("cells", xml_content)))
  expect_true(any(grepl("singlets", xml_content)))
})

test_that("export_flowjo10_workspace handles boolean gates", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 10)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Add two independent gates
  gate1 <- rectangleGate(filterId = "FSC_gate", "FSC-A" = c(70000, 200000))
  gs_pop_add(gs, gate1, parent = "root")
  
  gate2 <- rectangleGate(filterId = "SSC_gate", "SSC-A" = c(50000, 130000))
  gs_pop_add(gs, gate2, parent = "root")
  
  recompute(gs)
  
  # Boolean AND
  bool_gate <- booleanFilter(`FSC_gate&SSC_gate`, filterId = "both")
  gs_pop_add(gs, bool_gate, parent = "root")
  
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("AndNode", xml_content)))
  expect_true(any(grepl("FSC_gate", xml_content)))
  expect_true(any(grepl("SSC_gate", xml_content)))
})

test_that("export_flowjo10_workspace validates input parameters", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Test missing required parameters
  expect_error(export_flowjo10_workspace(), 
               "Missing required parameters: gating_set, output_path")
  
  # Test invalid output_path
  ff <- create_test_fcs(n = 1000, seed = 11)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  expect_error(export_flowjo10_workspace(gs, 123), 
               "output_path must be a single character string")
})

test_that("xml_encode properly escapes special characters", {
  skip_on_cran()
  
  # Test basic functionality
  expect_equal(xml_encode(""), "")
  expect_equal(xml_encode(NULL), "")
  
  # Test special character encoding
  expect_equal(xml_encode("&"), "&")
  expect_equal(xml_encode("<"), "<")
  expect_equal(xml_encode(">"), ">")
  expect_equal(xml_encode("\""), '"')
  expect_equal(xml_encode("'"), "'")
  
  # Test mixed content
  expect_equal(xml_encode("A&T Cells"), "A&T Cells")
})

test_that("get_display_range handles various scenarios", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 1000, seed = 12)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Test with valid parameter
  range_result <- get_display_range(gs[[1]], "FSC-A")
  expect_type(range_result, "double")
  expect_length(range_result, 2)
  expect_true(range_result[1] <= range_result[2])
  
  # Test with invalid parameter (should fall back to default)
  range_result <- get_display_range(gs[[1]], "NONEXISTENT")
  expect_equal(range_result, c(0, 262144))
})

test_that("export_flowjo10_workspace handles polygon gate with biexponential transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 13)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply biex transform
  biexp_trans <- flowjo_biexp_trans(
    channelRange = 4096,
    maxValue = 262144,
    pos = 4.5,
    neg = 0,
    widthBasis = -10
  )
  trans_list <- transformerList(c("FSC-A", "SSC-A"), biexp_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  # Add polygon gate on transformed data
  gate <- polygonGate(
    filterId = "cell_region",
    .gate = matrix(c(500, 1000, 1500, 1200, 800, 600, 500, 800, 1200, 1400, 1300, 800),
                   ncol = 2, dimnames = list(NULL, c("FSC-A", "SSC-A")))
  )
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Check that XML contains expected elements
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("PolygonGate", xml_content)))
  expect_true(any(grepl("FSC-A", xml_content)))
  expect_true(any(grepl("SSC-A", xml_content)))
})

# test_that("export_flowjo10_workspace handles ellipsoid gate with logicle transformation", {
#   # skip_on_cran()
#   skip_if_not_installed("flowWorkspace")
#   skip_if_not_installed("flowCore")
#   
#   library(flowWorkspace)
#   library(flowCore)
#   
#   # Create test data
#   ff <- create_test_fcs(n = 8000, seed = 14)
#   fs <- flowSet(ff)
#   gs <- GatingSet(fs)
#   
#   # Apply logicle transform
#   logicle_trans <- logicle_trans(t = 262144, w = 0.5, m = 4.5, a = 0)
#   trans_list <- transformerList(c("FSC-A", "SSC-A"), logicle_trans)
#   gs <- flowWorkspace::transform(gs, trans_list)
#   
#   # Add ellipsoid gate on transformed data
#   ellipse_cov <- matrix(c(1.5e9, 7e8, 7e8, 1e9), ncol = 2)
#   colnames(ellipse_cov) <- rownames(ellipse_cov) <- c("FSC-A", "SSC-A")
#   
#   gate <- ellipsoidGate(
#     filterId = "ellipse_cells",
#     .gate = ellipse_cov,
#     mean = c("FSC-A" = 120000, "SSC-A" = 80000),
#     distance = 2
#   )
#   gs_pop_add(gs, gate, parent = "root")
#   recompute(gs)
#   
#   # Test export
#   temp_file <- tempfile(fileext = ".wsp")
#   on.exit(unlink(temp_file))
#   
#   expect_true(export_flowjo10_workspace(gs, temp_file))
#   expect_true(file.exists(temp_file))
#   expect_gt(file.size(temp_file), 0)
#   
#   # Check that XML contains expected elements
#   xml_content <- readLines(temp_file)
#   expect_true(any(grepl("EllipsoidGate", xml_content)))
#   expect_true(any(grepl("FSC-A", xml_content)))
#   expect_true(any(grepl("SSC-A", xml_content)))
# })

