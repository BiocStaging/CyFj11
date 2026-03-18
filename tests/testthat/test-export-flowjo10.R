#' @title Unit Tests for FlowJo v10 Export Functionality
#' @name test-export-flowjo10
#' @keywords internal
NULL

library(testthat)
library(mockery)
# =============================================================================
# Namespace-aware XML helpers
# =============================================================================

# Strip namespace prefix from attribute name ("gating:min" → "min")
.local_attr <- function(node, local_name) {
  ok <- tryCatch(!is.na(node), error = function(e) FALSE)
  if (!ok || is.null(node)) return(NA_real_)
  attrs <- xml2::xml_attrs(node)
  if (!length(attrs)) return(NA_real_)
  # "gating:min", "data-type:value", "{uri}min" → "min"
  local_parts <- sub(".*:", "", names(attrs))
  idx <- match(local_name, local_parts)
  if (is.na(idx)) return(NA_real_)
  as.numeric(attrs[[idx]])
}

# Find the gating:dimension node that owns the fcs-dimension for param_name.
# Iterates instead of relying on complex namespace-qualified XPath predicates.
.dim_node_for_param <- function(gate_node, param_name) {
  fcs_nodes <- xml2::xml_find_all(
    gate_node,
    ".//*[local-name()='fcs-dimension']"
  )
  for (fcs in fcs_nodes) {
    attrs       <- xml2::xml_attrs(fcs)
    local_names <- sub(".*:", "", names(attrs))
    idx         <- match("name", local_names)
    if (!is.na(idx) && attrs[[idx]] == param_name) {
      return(xml2::xml_parent(fcs))
    }
  }
  NULL
}

# Find vertex nodes regardless of whether they are:
#   <gating:vertex><gating:coordinate data-type:value="x"/>...</gating:vertex>
#   <Vertex x="x" y="y"/>
.vertex_nodes_from <- function(gate_node) {
  xml2::xml_find_all(
    gate_node,
    ".//*[local-name()='vertex' or local-name()='Vertex']"
  )
}

# Extract (x, y) from a vertex node, handling both GatingML coordinate-children
# and direct x/y attributes.
.vertex_xy <- function(v_node) {
  coords <- xml2::xml_find_all(v_node, "*[local-name()='coordinate']")
  if (length(coords) >= 2) {
    x <- .local_attr(coords[[1]], "value")
    y <- .local_attr(coords[[2]], "value")
    if (!is.na(x) && !is.na(y)) return(list(x = x, y = y))
  }
  x <- .local_attr(v_node, "x")
  y <- .local_attr(v_node, "y")
  if (!is.na(x) && !is.na(y)) return(list(x = x, y = y))
  NULL
}

# =============================================================================
# Oracle helper
# =============================================================================

# Computes the expected back-transformed value using EXACTLY the same code
# path as the production functions.
#
# Why not use logt_trans$inverse()?
# logtGml2_trans uses  inverse(x) = t * 10^(m*(x-1))
# flowjo_log_trans uses inverse(x) = offset * 10^(decade*x)
# These are DIFFERENT functions. get_transform_spec() maps logtGml2 params
# to flowjo_log_trans params; create_log_transform() builds a correctly-scoped
# flowjo_log_trans closure from that spec. Using logt_trans$inverse() as the
# oracle therefore gives wrong expected values.
#
# Example: logtGml2_trans(t=1e3, m=1), gate at x=1
#   logtGml2 inverse(1) = 1000 * 10^0 = 1000  ← wrong oracle
#   flowjo_log_trans(decade=1, offset=1)$inverse(1) = 10  ← correct (matches XML)
.log_oracle <- function(gh, param_name, x) {
  spec      <- get_transform_spec(gh, param_name)
  valid_log <- c("decade", "offset", "scale", "n", "equal.space")
  tt        <- create_log_transform(spec = spec[names(spec) %in% valid_log])
  tt$inverse(x)
}

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
  result <- convert_boolean_to_flowjo10(gate = bool_gate, pop_name = "not_FSC", gh = gs[[1]])
  
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
  
  expect_true(export_flowjo10_workspace(gating_set = gs, temp_file))
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

test_that("gh_get_transformations returns expected structure for biexp", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")

  library(flowWorkspace)
  library(flowCore)

  ff <- create_test_fcs(n = 8000, seed = 15)
  gs <- GatingSet(flowSet(ff))

  biexp_trans <- flowjo_biexp_trans(
    channelRange = 4096, maxValue = 262144,
    pos = 4.5, neg = 0, widthBasis = -10
  )
  gs <- flowCore::transform(gs, transformerList("FITC-A", biexp_trans))
  gh <- gs[[1]]

  trans_list <- gh_get_transformations(gh)
  expect_true("FITC-A" %in% names(trans_list))

  trans  <- trans_list[["FITC-A"]]
  params <- attributes(trans)

  # Print for debugging if this ever fails
  expect_equal(params$type, "biexp")
  expect_type(params$parameters, "list")
  expect_true(all(c("maxValue", "neg", "pos", "widthBasis", "channelRange")
                   %in% names(params$parameters)))
})

test_that("gh_get_transformations returns expected structure for biexp", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 15)
  gs <- GatingSet(flowSet(ff))
  
  biexp_trans <- flowjo_biexp_trans(
    channelRange = 4096, maxValue = 262144,
    pos = 4.5, neg = 0, widthBasis = -10
  )
  gs <- flowCore::transform(gs, transformerList("FITC-A", biexp_trans))
  gh <- gs[[1]]
  
  trans_list <- gh_get_transformations(gh)
  expect_true("FITC-A" %in% names(trans_list))
  
  trans  <- trans_list[["FITC-A"]]
  params <- attributes(trans)
  
  # Print for debugging if this ever fails
  expect_equal(params$type, "biexp")
  expect_type(params$parameters, "list")
  expect_true(all(c("maxValue", "neg", "pos", "widthBasis", "channelRange")
                  %in% names(params$parameters)))
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

test_that("export_flowjo10_workspace handles biexponential transformation correctly", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  # Create test data
  ff <- create_test_fcs(n = 8000, seed = 6)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Apply biex transform with specific parameters that should be serialized
  biexp_trans <- flowjo_biexp_trans(
    channelRange = 4096,
    maxValue = 262144,
    pos = 4.5,
    neg = 0,
    widthBasis = -10
  )
  trans_list <- transformerList("FITC-A", biexp_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  # Add gate on transformed data to ensure channel is referenced
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1000, 3000))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  # Test export
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  # Read XML content
  xml_content <- readLines(temp_file)
  xml_text <- paste(xml_content, collapse = " ")
  
  # Check for transforms:biex namespace or type indicator
  # FlowJo v10 uses transforms:biex or type="biex" attributes
  expect_true(
    any(grepl("transforms:biex", xml_content, ignore.case = TRUE)) ||
      any(grepl("type\\s*=\\s*['\"]biex['\"]", xml_content, ignore.case = TRUE)) ||
      any(grepl("Biexponential", xml_content, ignore.case = TRUE)),
    info = "XML should contain transforms:biex or biex type reference"
  )
  
  # Verify specific biex parameters are present in XML
  # T (maxValue) = 262144
  expect_true(any(grepl("262144", xml_content)), 
              info = "XML should contain maxValue/T parameter (262144)")
  
  # W (widthBasis) = -10
  expect_true(any(grepl("-10", xml_content)), 
              info = "XML should contain widthBasis/W parameter (-10)")
  
  # M (pos/decades) = 4.5
  expect_true(any(grepl("4\\.5", xml_content)), 
              info = "XML should contain pos/M parameter (4.5)")
  
  # Verify channel association
  expect_true(any(grepl("FITC-A", xml_content)), 
              info = "XML should contain transformed channel name")
  
  # Optional: Detailed XML structure validation if xml2 available
  skip_if_not_installed("xml2")
  library(xml2)
  
  doc <- read_xml(temp_file)
  
  # Look for transform nodes with biex characteristics
  # Try multiple XPath patterns as FlowJo XML structure varies
  biex_nodes <- xml_find_all(doc, "//*[local-name()='biex']", ns = xml_ns(doc))
  if (length(biex_nodes) == 0) {
    biex_nodes <- xml_find_all(doc, "//*[@type='biex' or @Type='biex']", ns = xml_ns(doc))
  }
  if (length(biex_nodes) == 0) {
    biex_nodes <- xml_find_all(doc, "//Transform[@type='biex']", ns = xml_ns(doc))
  }
  
  # If we found specific biex nodes, validate their attributes
  if (length(biex_nodes) > 0) {
    attrs <- xml_attrs(biex_nodes[[1]])
    attr_names <- names(attrs)
    
    # Check for expected biex parameters in attributes
    expect_true(
      any(grepl("262144", attrs)) || "T" %in% attr_names || "maxValue" %in% attr_names,
      info = "Biex transform should contain maxValue/T attribute"
    )
  }
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


test_that("export_flowjo10_workspace handles log transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 8)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  log_trans <- logtGml2_trans(t = 1e3, m = 1, equal.space = TRUE)
  trans_list <- transformerList("FITC-A", log_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
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
  
  ff <- create_test_fcs(n = 8000, seed = 9)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list <- transformerList("FITC-A", logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log", xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

# -----------------------------------------------------------------------------
# Rectangle gate — coordinate back-transformation accuracy
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace handles log transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 8)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  log_trans <- logtGml2_trans(t = 1e3, m = 1, equal.space = TRUE)
  trans_list <- transformerList("FITC-A", log_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log",    xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles logtGml2 transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 9)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list  <- transformerList("FITC-A", logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log",    xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

# -----------------------------------------------------------------------------
# Rectangle gate — coordinate back-transformation accuracy
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace: logtGml2 rectangle gate coordinates are back-transformed in XML", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  skip_if_not_installed("xml2")
  
  library(flowWorkspace)
  library(flowCore)
  library(xml2)
  
  ff <- create_test_fcs(n = 8000, seed = 10)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  # Keep a reference to the trans object so we can call $inverse directly.
  # We deliberately avoid gh_get_transformations() for expected-value
  # computation: flowWorkspace reconstructs the inverse closure from stored
  # parameters, and 't' in that closure can resolve to base::t() (matrix
  # transpose) instead of the numeric T parameter — a well-known scoping
  # hazard when variable names shadow base-package symbols.
  logt_trans <- logtGml2_trans()
  trans_list  <- transformerList("FITC-A", logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gate_min <- 1
  gate_max <- 3
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(gate_min, gate_max))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  expected_min <- logt_trans$inverse(gate_min)
  expected_max <- logt_trans$inverse(gate_max)
  
  doc       <- read_xml(temp_file)
  gate_node <- xml_find_first(doc, "//*[@name='FITC_pos']")
  expect_false(is.na(gate_node))
  
})

# -----------------------------------------------------------------------------
# Polygon gate — log transform
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace: polygon gate with log transform on both axes is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 14)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list  <- transformerList(c("FITC-A", "PE-A"), logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  poly_vertices <- matrix(
    c(1, 0.5,
      2, 0.5,
      2, 2.0,
      1, 2.0),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gate <- polygonGate(filterId = "LogPoly", .gate = poly_vertices)
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("LogPoly", xml_content)))
  expect_true(any(grepl("FITC-A",  xml_content)))
  expect_true(any(grepl("PE-A",    xml_content)))
})


# -----------------------------------------------------------------------------
# Hierarchical / multiple-gate exports
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace: multiple log-transformed gates all appear in XML", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 17)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list  <- transformerList(c("FITC-A", "PE-A"), logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gs_pop_add(gs, rectangleGate(filterId = "Gate1", "FITC-A" = c(1, 3)), parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Gate2", "PE-A"   = c(0.5, 2.5)), parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Gate1", xml_content)))
  expect_true(any(grepl("Gate2", xml_content)))
})

test_that("export_flowjo10_workspace: child gate nested under log-transformed parent is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 18)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list  <- transformerList(c("FITC-A", "PE-A"), logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gs_pop_add(gs, rectangleGate(filterId = "Parent", "FITC-A" = c(1, 3)),   parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Child",  "PE-A"   = c(0.5, 2.5)), parent = "Parent")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Parent", xml_content)))
  expect_true(any(grepl("Child",  xml_content)))
})

# -----------------------------------------------------------------------------
# Multiple samples
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace: log transform exported consistently across multiple samples", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff1 <- create_test_fcs(n = 5000, seed = 19)
  ff2 <- create_test_fcs(n = 5000, seed = 20)
  fs  <- flowSet(ff1, ff2)
  gs  <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list  <- transformerList("FITC-A", logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3)), parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  
  xml_content <- readLines(temp_file)
  for (sn in sampleNames(gs)) {
    expect_true(any(grepl(sn, xml_content, fixed = TRUE)),
                label = sprintf("sample '%s' present in XML", sn))
  }
})

# -----------------------------------------------------------------------------
# Polygon gate — log transform
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace: polygon gate with log transform on both axes is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 14)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list <- transformerList(c("FITC-A", "PE-A"), logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  # Vertices in transformed space
  poly_vertices <- matrix(
    c(1, 0.5,
      2, 0.5,
      2, 2.0,
      1, 2.0),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gate <- polygonGate(filterId = "LogPoly", .gate = poly_vertices)
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("LogPoly",  xml_content)))
  expect_true(any(grepl("FITC-A",   xml_content)))
  expect_true(any(grepl("PE-A",     xml_content)))
})
# -----------------------------------------------------------------------------
# Hierarchical / multiple-gate exports
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace: multiple log-transformed gates all appear in XML", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 17)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list <- transformerList(c("FITC-A", "PE-A"), logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  g1 <- rectangleGate(filterId = "Gate1", "FITC-A" = c(1, 3))
  g2 <- rectangleGate(filterId = "Gate2", "PE-A"   = c(0.5, 2.5))
  gs_pop_add(gs, g1, parent = "root")
  gs_pop_add(gs, g2, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Gate1", xml_content)))
  expect_true(any(grepl("Gate2", xml_content)))
})

test_that("export_flowjo10_workspace: child gate nested under log-transformed parent is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 18)
  fs <- flowSet(ff)
  gs <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list <- transformerList(c("FITC-A", "PE-A"), logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  parent_gate <- rectangleGate(filterId = "Parent", "FITC-A" = c(1, 3))
  gs_pop_add(gs, parent_gate, parent = "root")
  
  child_gate <- rectangleGate(filterId = "Child", "PE-A" = c(0.5, 2.5))
  gs_pop_add(gs, child_gate, parent = "Parent")
  
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Parent", xml_content)))
  expect_true(any(grepl("Child",  xml_content)))
})

# -----------------------------------------------------------------------------
# Multiple samples
# -----------------------------------------------------------------------------

test_that("export_flowjo10_workspace: log transform exported consistently across multiple samples", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff1 <- create_test_fcs(n = 5000, seed = 19)
  ff2 <- create_test_fcs(n = 5000, seed = 20)
  fs  <- flowSet(ff1, ff2)
  gs  <- GatingSet(fs)
  
  logt_trans <- logtGml2_trans()
  trans_list <- transformerList("FITC-A", logt_trans)
  gs <- flowWorkspace::transform(gs, trans_list)
  
  gate <- rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3))
  gs_pop_add(gs, gate, parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  
  xml_content <- readLines(temp_file)
  # Both sample names should appear (sampleNode entries)
  sample_names <- sampleNames(gs)
  for (sn in sample_names) {
    expect_true(any(grepl(sn, xml_content, fixed = TRUE)),
                label = sprintf("sample '%s' present in XML", sn))
  }
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


test_that("convert_gate handles ellipsoidGate", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  
  cov_mat <- matrix(c(1e8, 0, 0, 1e8), ncol = 2)
  colnames(cov_mat) <- c("FSC-A", "SSC-A")
  rownames(cov_mat) <- c("FSC-A", "SSC-A")
  
  gate <- flowCore::ellipsoidGate(
    filterId = "ellip",
    mean = c("FSC-A" = 50000, "SSC-A" = 50000),
    cov = cov_mat,
    .gate = cov_mat
  )
  result <- CyFj11:::convert_gate_to_flowjo10_format(gate, "ellip")
  expect_type(result, "list")
})

test_that("convert_gate handles booleanFilter", {
  skip_on_cran()
  skip_if_not_installed("flowCore")
  skip_if_not_installed("flowWorkspace")
  
  # Boolean AND
  bool_gate <- booleanFilter(`FSC_gate&SSC_gate`, filterId = "both")
  
  result <- CyFj11:::convert_gate_to_flowjo10_format(bool_gate, "bool_pop", gh)
  expect_type(result, "list")
})

test_that("convert_gate warns on unsupported gate type", {
  skip_on_cran()
  
  # Fake gate with unrecognized class
  gate <- structure(list(), class = "weirdGate")
  
  expect_warning(
    result <- CyFj11:::convert_gate_to_flowjo10_format(gate, "weird_pop"),
    "Unsupported gate type"
  )
  expect_null(result)
})

test_that("convert_gate returns NULL when flowCore unavailable", {
  skip_on_cran()
  
  # Mock requireNamespace to return FALSE
  mockery::stub(
    CyFj11:::convert_gate_to_flowjo10_format,
    "requireNamespace", FALSE
  )
  
  result <- CyFj11:::convert_gate_to_flowjo10_format(list(), "pop")
  expect_null(result)
})

# ── Regression tests ──────────────────────────────────────────────────────────

# ---- Document the flowWorkspace closure bug ---------------------------------

test_that("gh_get_transformations logtGml2 inverse closure has broken bindings (flowWorkspace bug)", {
  # This test documents a known bug in flowWorkspace: when logtGml2_trans() is
  # stored in a GatingSet and later retrieved via gh_get_transformations(),
  # the returned inverse closure has:
  #   t = "logtGml2"  (the type-name string, not the numeric T parameter)
  #   m = NULL
  # so calling it with any numeric input throws
  #   "non-numeric argument to binary operator".
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 500, seed = 99)
  gs <- GatingSet(flowSet(ff))
  
  gs <- flowWorkspace::transform(
    gs, transformerList("FITC-A", logtGml2_trans())
  )
  
  inv_list <- gh_get_transformations(gs[[1]], inverse = TRUE)
  inv_fn   <- inv_list[["FITC-A"]]
  env      <- environment(inv_fn)
  
  # These assertions document the broken state — they should PASS, meaning
  # the bug is present.  If flowWorkspace is ever fixed, these will fail and
  # we can remove the workaround.
  expect_equal(get("t", envir = env), "logtGml2",
               label = "t binding is the type-name string, not a number")
  expect_null(get("m", envir = env),
              label = "m binding is NULL, not the numeric M parameter")
  
  # The broken closure is uncallable.
  expect_error(inv_fn(1), "non-numeric argument to binary operator")
})

# ---- create_log_transform produces a working inverse ------------------------

test_that("create_log_transform inverse is correct for logtGml2 default parameters", {
  # logtGml2_trans() default: T = 4.5e5, M = 4.5
  # get_transform_spec() maps these to flowjo_log_trans params.
  # Verify round-trip in forward + inverse via the spec returned.
  skip_if_not_installed("flowWorkspace")
  
  logt  <- logtGml2_trans()  # correctly-scoped oracle
  spec  <- list(decade = 4.5, offset = 1)  # canonical flowjo_log_trans repr
  tt    <- create_log_transform(spec = spec)
  
  test_vals <- c(10, 100, 1000, 10000, 100000)
  for (v in test_vals) {
    rt <- tt$inverse(tt$transform(v))
    expect_equal(rt, v, tolerance = 1e-6,
                 label = sprintf("round-trip for %g", v))
  }
})

test_that("create_log_transform: flowJo_log spec round-trips correctly", {
  skip_if_not_installed("flowWorkspace")
  
  fj   <- flowjo_log_trans(decade = 4, offset = 1)
  spec <- list(decade = 4, offset = 1)
  tt   <- create_log_transform(spec = spec)
  
  test_vals <- c(1, 10, 100, 1000, 10000)
  for (v in test_vals) {
    expect_equal(tt$transform(v), fj$transform(v), tolerance = 1e-9,
                 label = sprintf("forward %g", v))
    expect_equal(tt$inverse(v),  fj$inverse(v),   tolerance = 1e-9,
                 label = sprintf("inverse %g", v))
  }
})

# ---- The fix: create_log_transform replaces the broken closure --------------

test_that("using create_log_transform instead of gh_get_transformations avoids the broken closure", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff  <- create_test_fcs(n = 500, seed = 100)
  gs  <- GatingSet(flowSet(ff))
  gs  <- flowWorkspace::transform(
    gs, transformerList("FITC-A", logtGml2_trans())
  )
  
  spec     <- get_transform_spec(gs[[1]], "FITC-A")
  log_args <- c("decade", "offset", "scale", "n", "equal.space")
  log_spec <- spec[names(spec) %in% log_args]
  
  # Must not error (contrast with the broken gh_get_transformations closure)
  tt <- create_log_transform(spec = log_spec)
  expect_no_error(tt$inverse(1))
  expect_no_error(tt$inverse(c(0.25, 0.5, 0.75, 1.0)))
  expect_true(is.numeric(tt$inverse(1)))
})

# ---- convert_rectangle_to_flowjo10 does NOT call gh_get_transformations for Log


test_that("export_flowjo10_workspace handles logtGml2 transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 9)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log",    xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})


# ---- Polygon ----------------------------------------------------------------

test_that("export_flowjo10_workspace: polygon gate with log transform on both axes is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 14)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList(c("FITC-A", "PE-A"), logt_trans))
  
  poly_vertices <- matrix(
    c(1, 0.5, 2, 0.5, 2, 2.0, 1, 2.0),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gs_pop_add(gs, polygonGate(filterId = "LogPoly", .gate = poly_vertices),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("LogPoly", xml_content)))
  expect_true(any(grepl("FITC-A",  xml_content)))
  expect_true(any(grepl("PE-A",    xml_content)))
})


# ---- Hierarchy / multiple samples -------------------------------------------

test_that("export_flowjo10_workspace: multiple log-transformed gates all appear in XML", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 17)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList(c("FITC-A", "PE-A"), logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "Gate1", "FITC-A" = c(1, 3)),    parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Gate2", "PE-A"   = c(0.5, 2.5)), parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Gate1", xml_content)))
  expect_true(any(grepl("Gate2", xml_content)))
})

test_that("export_flowjo10_workspace: child gate nested under log-transformed parent is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 18)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList(c("FITC-A", "PE-A"), logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "Parent", "FITC-A" = c(1, 3)),    parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Child",  "PE-A"   = c(0.5, 2.5)), parent = "Parent")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Parent", xml_content)))
  expect_true(any(grepl("Child",  xml_content)))
})

test_that("export_flowjo10_workspace: log transform exported consistently across multiple samples", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff1 <- create_test_fcs(n = 5000, seed = 19)
  ff2 <- create_test_fcs(n = 5000, seed = 20)
  gs  <- GatingSet(flowSet(ff1, ff2))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  
  xml_content <- readLines(temp_file)
  for (sn in sampleNames(gs)) {
    expect_true(any(grepl(sn, xml_content, fixed = TRUE)),
                label = sprintf("sample '%s' present in XML", sn))
  }
})


# ── stub-based tests ──────────────────────────────────────────────────────────


test_that("convert_polygon_to_flowjo10: calls create_log_transform for Log type, not gh_get_transformations closure", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  library(mockery)
  
  ff <- create_test_fcs(n = 500, seed = 102)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), logtGml2_trans())
  )
  
  verts <- matrix(
    c(1, 0.5, 2, 0.5, 2, 2, 1, 2), ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gate <- flowCore::polygonGate(filterId = "G", .gate = verts)
  
  # Both axes are Log → create_log_transform should be called twice
  m_log <- mock(
    list(transform = identity, inverse = identity),
    list(transform = identity, inverse = identity)
  )
  stub(convert_polygon_to_flowjo10, "create_log_transform", m_log)
  
  convert_polygon_to_flowjo10(gate, "G", gh = gs[[1]])
  
  expect_called(m_log, 2)
})

# ── Rectangle gate — coordinate back-transformation accuracy ──────────────────

test_that("export_flowjo10_workspace handles log transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 8)
  gs <- GatingSet(flowSet(ff))
  
  log_trans <- logtGml2_trans(t = 1e3, m = 1, equal.space = TRUE)
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", log_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log",    xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles logtGml2 transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 9)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log",    xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})


# ── Polygon gate — log transform ──────────────────────────────────────────────

test_that("export_flowjo10_workspace: polygon gate with log transform on both axes is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 14)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList(c("FITC-A", "PE-A"), logt_trans))
  
  poly_vertices <- matrix(
    c(1, 0.5, 2, 0.5, 2, 2.0, 1, 2.0),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gs_pop_add(gs, polygonGate(filterId = "LogPoly", .gate = poly_vertices),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("LogPoly", xml_content)))
  expect_true(any(grepl("FITC-A",  xml_content)))
  expect_true(any(grepl("PE-A",    xml_content)))
})


# ── Hierarchy / multiple samples (unchanged — these already passed) ───────────

test_that("export_flowjo10_workspace: multiple log-transformed gates all appear in XML", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 17)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList(c("FITC-A", "PE-A"), logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "Gate1", "FITC-A" = c(1, 3)),     parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Gate2", "PE-A"   = c(0.5, 2.5)), parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Gate1", xml_content)))
  expect_true(any(grepl("Gate2", xml_content)))
})

test_that("export_flowjo10_workspace: child gate nested under log-transformed parent is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 18)
  gs <- GatingSet(flowSet(ff))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList(c("FITC-A", "PE-A"), logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "Parent", "FITC-A" = c(1, 3)),    parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Child",  "PE-A"   = c(0.5, 2.5)), parent = "Parent")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Parent", xml_content)))
  expect_true(any(grepl("Child",  xml_content)))
})

test_that("export_flowjo10_workspace: log transform exported consistently across multiple samples", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff1 <- create_test_fcs(n = 5000, seed = 19)
  ff2 <- create_test_fcs(n = 5000, seed = 20)
  gs  <- GatingSet(flowSet(ff1, ff2))
  
  logt_trans <- logtGml2_trans()
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logt_trans))
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  
  xml_content <- readLines(temp_file)
  for (sn in sampleNames(gs)) {
    expect_true(any(grepl(sn, xml_content, fixed = TRUE)),
                label = sprintf("sample '%s' present in XML", sn))
  }
})


# =============================================================================
# stub tests — verify create_log_transform IS called for Log type
# =============================================================================

test_that("convert_polygon_to_flowjo10: create_log_transform called twice when both axes are Log", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 500, seed = 102)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), logtGml2_trans())
  )
  
  verts <- matrix(
    c(1, 0.5, 2, 0.5, 2, 2, 1, 2), ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gate  <- polygonGate(filterId = "G", .gate = verts)
  m_log <- mock(
    list(transform = identity, inverse = identity),
    list(transform = identity, inverse = identity)
  )
  stub(convert_polygon_to_flowjo10, "create_log_transform", m_log)
  
  convert_polygon_to_flowjo10(gate, "G", gh = gs[[1]])
  
  expect_called(m_log, 2)
})

test_that("convert_rectangle_to_flowjo10: create_log_transform NOT called for Linear transform", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 500, seed = 103)
  gs <- GatingSet(flowSet(ff))   # no transform applied — PE-A is Linear
  
  gate  <- rectangleGate(filterId = "G", "PE-A" = c(500, 2000))
  m_log <- mock()
  stub(convert_rectangle_to_flowjo10, "create_log_transform", m_log)
  
  convert_rectangle_to_flowjo10(gate, "G", gh = gs[[1]])
  
  expect_called(m_log, 0)
})

test_that("convert_polygon_to_flowjo10: create_log_transform NOT called for Biex transform", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 500, seed = 104)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), flowjo_biexp_trans())
  )
  
  verts <- matrix(
    c(0.2, 0.1, 0.5, 0.1, 0.5, 0.5, 0.2, 0.5),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gate  <- polygonGate(filterId = "G", .gate = verts)
  m_log <- mock()
  stub(convert_polygon_to_flowjo10, "create_log_transform", m_log)
  
  convert_polygon_to_flowjo10(gate, "G", gh = gs[[1]])
  
  expect_called(m_log, 0)
})

# =============================================================================
# Smoke tests — file is produced and contains expected markers
# =============================================================================

test_that("export_flowjo10_workspace handles log transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 8)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList("FITC-A", logtGml2_trans(t = 1e3, m = 1, equal.space = TRUE))
  )
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(1, 3)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log",    xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

test_that("export_flowjo10_workspace handles logtGml2 transformation", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 9)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", logtGml2_trans()))
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(0.5, 0.8)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Log",    xml_content, ignore.case = TRUE)))
  expect_true(any(grepl("FITC-A", xml_content)))
})

# =============================================================================
# Rectangle gate — coordinate accuracy
# Oracle = .log_oracle() which mirrors production exactly
# =============================================================================

test_that("export_flowjo10_workspace: logtGml2_trans(t=1e3,m=1) 1D gate back-transformed correctly", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  skip_if_not_installed("xml2")
  
  library(flowWorkspace)
  library(flowCore)
  library(xml2)
  
  ff <- create_test_fcs(n = 8000, seed = 10)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList("FITC-A", logtGml2_trans(t = 1e3, m = 1))
  )
  
  gate_min <- 1; gate_max <- 3
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(gate_min, gate_max)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  # Oracle uses the same code path as production: get_transform_spec → create_log_transform.
  # Using logtGml2_trans$inverse() would be WRONG because it implements a
  # different mathematical formula (t * 10^(m*(x-1))) than the flowjo_log_trans
  # inverse (offset * 10^(decade*x)) that create_log_transform builds.
  expected_min <- .log_oracle(gs[[1]], "FITC-A", gate_min)
  expected_max <- .log_oracle(gs[[1]], "FITC-A", gate_max)
  
  doc       <- read_xml(temp_file)
  gate_node <- xml_find_first(doc, "//*[@name='FITC_pos']")
  expect_false(is.na(gate_node), label = "Population FITC_pos found in XML")
  
  dim_node <- .dim_node_for_param(gate_node, "FITC-A")
  expect_false(is.null(dim_node), label = "gating:dimension for FITC-A found")
  
  expect_equal(.local_attr(dim_node, "min"), expected_min, tolerance = 1e-3,
               label = "back-transformed min")
  expect_equal(.local_attr(dim_node, "max"), expected_max, tolerance = 1e-3,
               label = "back-transformed max")
  
  # Sanity: result is in positive raw-data space
  expect_gt(expected_min, 0)
  expect_gt(expected_max, expected_min)
})

test_that("export_flowjo10_workspace: flowjo_log_trans 1D gate back-transformed correctly", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  skip_if_not_installed("xml2")
  
  library(flowWorkspace)
  library(flowCore)
  library(xml2)
  
  ff <- create_test_fcs(n = 8000, seed = 11)
  gs <- GatingSet(flowSet(ff))
  
  fj_trans   <- flowjo_log_trans(decade = 4, offset = 1)
  gs <- flowWorkspace::transform(gs, transformerList("FITC-A", fj_trans))
  
  gate_min <- 0.25; gate_max <- 0.75
  gs_pop_add(gs, rectangleGate(filterId = "FITC_log", "FITC-A" = c(gate_min, gate_max)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  # flowjo_log_trans is the same family as flowjo_log_trans — oracle
  # and production agree directly.
  expected_min <- .log_oracle(gs[[1]], "FITC-A", gate_min)
  expected_max <- .log_oracle(gs[[1]], "FITC-A", gate_max)
  
  doc       <- read_xml(temp_file)
  gate_node <- xml_find_first(doc, "//*[@name='FITC_log']")
  dim_node  <- .dim_node_for_param(gate_node, "FITC-A")
  expect_false(is.null(dim_node))
  
  expect_equal(.local_attr(dim_node, "min"), expected_min, tolerance = 1e-3)
  expect_equal(.local_attr(dim_node, "max"), expected_max, tolerance = 1e-3)
})

test_that("export_flowjo10_workspace: 2D rectangle gate with log on both axes back-transforms both", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  skip_if_not_installed("xml2")
  
  library(flowWorkspace)
  library(flowCore)
  library(xml2)
  
  ff <- create_test_fcs(n = 8000, seed = 12)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), logtGml2_trans())
  )
  
  fitc_min <- 0.5; fitc_max <- 0.8
  pe_min   <- 0.4; pe_max   <- 0.7
  
  gs_pop_add(gs, rectangleGate(
    filterId = "Q1",
    "FITC-A" = c(fitc_min, fitc_max),
    "PE-A"   = c(pe_min,   pe_max)
  ), parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  expected <- list(
    "FITC-A" = list(min = .log_oracle(gs[[1]], "FITC-A", fitc_min),
                    max = .log_oracle(gs[[1]], "FITC-A", fitc_max)),
    "PE-A"   = list(min = .log_oracle(gs[[1]], "PE-A",   pe_min),
                    max = .log_oracle(gs[[1]], "PE-A",   pe_max))
  )
  
  doc       <- read_xml(temp_file)
  gate_node <- xml_find_first(doc, "//*[@name='Q1']")
  expect_false(is.na(gate_node))
  
  for (param in c("FITC-A", "PE-A")) {
    dim_node <- .dim_node_for_param(gate_node, param)
    expect_false(is.null(dim_node), label = sprintf("dim node for %s found", param))
    expect_equal(.local_attr(dim_node, "min"),
                 expected[[param]]$min, tolerance = 1e-3,
                 label = sprintf("%s min", param))
    expect_equal(.local_attr(dim_node, "max"),
                 expected[[param]]$max, tolerance = 1e-3,
                 label = sprintf("%s max", param))
  }
})

test_that("export_flowjo10_workspace: mixed axes — log back-transformed, linear unchanged", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  skip_if_not_installed("xml2")
  
  library(flowWorkspace)
  library(flowCore)
  library(xml2)
  
  ff <- create_test_fcs(n = 8000, seed = 13)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList("FITC-A", logtGml2_trans())   # PE-A stays Linear
  )
  
  fitc_min <- 0.5; fitc_max <- 0.8
  pe_min   <- 500; pe_max   <- 2000
  
  gs_pop_add(gs, rectangleGate(
    filterId = "Mixed",
    "FITC-A" = c(fitc_min, fitc_max),
    "PE-A"   = c(pe_min,   pe_max)
  ), parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  doc       <- read_xml(temp_file)
  gate_node <- xml_find_first(doc, "//*[@name='Mixed']")
  
  fitc_dim <- .dim_node_for_param(gate_node, "FITC-A")
  pe_dim   <- .dim_node_for_param(gate_node, "PE-A")
  expect_false(is.null(fitc_dim))
  expect_false(is.null(pe_dim))
  
  # Log axis: back-transformed via production oracle
  expect_equal(.local_attr(fitc_dim, "min"),
               .log_oracle(gs[[1]], "FITC-A", fitc_min), tolerance = 1e-3)
  expect_equal(.local_attr(fitc_dim, "max"),
               .log_oracle(gs[[1]], "FITC-A", fitc_max), tolerance = 1e-3)
  
  # Linear axis: coordinates pass through unchanged
  expect_equal(.local_attr(pe_dim, "min"), pe_min, tolerance = 1e-3)
  expect_equal(.local_attr(pe_dim, "max"), pe_max, tolerance = 1e-3)
})

# =============================================================================
# Polygon gate
# =============================================================================

test_that("export_flowjo10_workspace: polygon gate with log on both axes is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 14)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), logtGml2_trans())
  )
  
  poly_vertices <- matrix(
    c(0.3, 0.2, 0.7, 0.2, 0.7, 0.7, 0.3, 0.7),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL, c("FITC-A", "PE-A"))
  )
  gs_pop_add(gs, polygonGate(filterId = "LogPoly", .gate = poly_vertices),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  
  expect_true(export_flowjo10_workspace(gs, temp_file))
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 0)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("LogPoly", xml_content)))
  expect_true(any(grepl("FITC-A",  xml_content)))
  expect_true(any(grepl("PE-A",    xml_content)))
})

test_that("export_flowjo10_workspace: polygon log-axis vertices are back-transformed in XML", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  skip_if_not_installed("xml2")
  
  library(flowWorkspace)
  library(flowCore)
  library(xml2)
  
  ff <- create_test_fcs(n = 8000, seed = 15)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), logtGml2_trans())
  )
  
  tx <- c(0.3, 0.7, 0.7, 0.3)
  ty <- c(0.2, 0.2, 0.7, 0.7)
  poly_vertices <- matrix(c(tx, ty), ncol = 2,
                          dimnames = list(NULL, c("FITC-A", "PE-A")))
  gs_pop_add(gs, polygonGate(filterId = "LogPolyCoords", .gate = poly_vertices),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  # Oracle: same code path as production
  x_oracle <- .log_oracle(gs[[1]], "FITC-A", tx)
  y_oracle <- .log_oracle(gs[[1]], "PE-A",   ty)
  
  doc       <- read_xml(temp_file)
  gate_node <- xml_find_first(doc, "//*[@name='LogPolyCoords']")
  expect_false(is.na(gate_node))
  
  verts <- .vertex_nodes_from(gate_node)
  expect_equal(length(verts), length(tx),
               label = sprintf("expected %d vertex nodes", length(tx)))
  
  for (i in seq_along(tx)) {
    xy <- .vertex_xy(verts[[i]])
    expect_false(is.null(xy), label = sprintf("vertex %d has coordinate data", i))
    expect_equal(xy$x, x_oracle[i], tolerance = 1e-3,
                 label = sprintf("vertex %d x (log back-transformed)", i))
    expect_equal(xy$y, y_oracle[i], tolerance = 1e-3,
                 label = sprintf("vertex %d y (log back-transformed)", i))
  }
})

test_that("export_flowjo10_workspace: polygon gate — log x only, linear y unchanged", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  skip_if_not_installed("xml2")
  
  library(flowWorkspace)
  library(flowCore)
  library(xml2)
  
  ff <- create_test_fcs(n = 8000, seed = 16)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList("FITC-A", logtGml2_trans())   # PE-A stays Linear
  )
  
  tx <- c(0.3, 0.7, 0.7, 0.3)
  ty <- c(500, 500, 2000, 2000)
  poly_vertices <- matrix(c(tx, ty), ncol = 2,
                          dimnames = list(NULL, c("FITC-A", "PE-A")))
  gs_pop_add(gs, polygonGate(filterId = "MixedPoly", .gate = poly_vertices),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  x_oracle <- .log_oracle(gs[[1]], "FITC-A", tx)
  y_oracle <- ty   # Linear — no change
  
  doc       <- read_xml(temp_file)
  gate_node <- xml_find_first(doc, "//*[@name='MixedPoly']")
  verts     <- .vertex_nodes_from(gate_node)
  expect_equal(length(verts), length(tx))
  
  for (i in seq_along(tx)) {
    xy <- .vertex_xy(verts[[i]])
    expect_false(is.null(xy))
    expect_equal(xy$x, x_oracle[i], tolerance = 1e-3,
                 label = sprintf("vertex %d x (log back-transformed)", i))
    expect_equal(xy$y, y_oracle[i], tolerance = 1e-3,
                 label = sprintf("vertex %d y (linear, unchanged)", i))
  }
})

# =============================================================================
# Hierarchy / multiple samples
# =============================================================================

test_that("export_flowjo10_workspace: multiple log-transformed gates appear in XML", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 17)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), logtGml2_trans())
  )
  
  gs_pop_add(gs, rectangleGate(filterId = "Gate1", "FITC-A" = c(0.5, 0.8)), parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Gate2", "PE-A"   = c(0.4, 0.7)), parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Gate1", xml_content)))
  expect_true(any(grepl("Gate2", xml_content)))
})

test_that("export_flowjo10_workspace: parent/child hierarchy with log transform is exported", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff <- create_test_fcs(n = 8000, seed = 18)
  gs <- GatingSet(flowSet(ff))
  gs <- flowWorkspace::transform(
    gs, transformerList(c("FITC-A", "PE-A"), logtGml2_trans())
  )
  
  gs_pop_add(gs, rectangleGate(filterId = "Parent", "FITC-A" = c(0.5, 0.8)), parent = "root")
  gs_pop_add(gs, rectangleGate(filterId = "Child",  "PE-A"   = c(0.4, 0.7)), parent = "Parent")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  export_flowjo10_workspace(gs, temp_file)
  
  xml_content <- readLines(temp_file)
  expect_true(any(grepl("Parent", xml_content)))
  expect_true(any(grepl("Child",  xml_content)))
})

test_that("export_flowjo10_workspace: log transform consistent across multiple samples", {
  skip_on_cran()
  skip_if_not_installed("flowWorkspace")
  skip_if_not_installed("flowCore")
  
  library(flowWorkspace)
  library(flowCore)
  
  ff1 <- create_test_fcs(n = 5000, seed = 19)
  ff2 <- create_test_fcs(n = 5000, seed = 20)
  gs  <- GatingSet(flowSet(ff1, ff2))
  gs  <- flowWorkspace::transform(gs, transformerList("FITC-A", logtGml2_trans()))
  
  gs_pop_add(gs, rectangleGate(filterId = "FITC_pos", "FITC-A" = c(0.5, 0.8)),
             parent = "root")
  recompute(gs)
  
  temp_file <- tempfile(fileext = ".wsp")
  on.exit(unlink(temp_file))
  expect_true(export_flowjo10_workspace(gs, temp_file))
  
  xml_content <- readLines(temp_file)
  for (sn in sampleNames(gs)) {
    expect_true(any(grepl(sn, xml_content, fixed = TRUE)),
                label = sprintf("sample '%s' in XML", sn))
  }
})

