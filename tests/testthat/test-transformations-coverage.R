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

#' @title Coverage Tests for transformations.R
#' @name test-transformations-coverage
#' @keywords internal
NULL

skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

# ============================================================================
# Tests for parse_transformation_info - log transform branch (lines 186-195)
# ============================================================================

test_that("parse_transformation_info handles log transform with default values", {
  # Lines 190-194: log transform parameter extraction
  trans_info <- list(
    transformType = "log",
    channel = "FITC-A"
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$type, "log")
  expect_equal(params$channel, "FITC-A")
  # Default values from lines 190-194
  expect_equal(params$decadesOffset, 1)
  expect_equal(params$numberDecades, 4)
  expect_equal(params$shift, 0)
  expect_equal(params$base, 10)
  expect_equal(params$vectorLength, 256)
})

test_that("parse_transformation_info handles log transform with custom values", {
  # Lines 190-194: log transform with custom parameters
  trans_info <- list(
    transformType = "log",
    channel = "SSC-H",
    decadesOffset = 2,
    numberDecades = 5,
    shift = 100,
    base = 2.718,  # Natural log
    vectorLength = 512
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$type, "log")
  expect_equal(params$channel, "SSC-H")
  expect_equal(params$decadesOffset, 2)
  expect_equal(params$numberDecades, 5)
  expect_equal(params$shift, 100)
  expect_equal(params$base, 2.718)
  expect_equal(params$vectorLength, 512)
})

test_that("parse_transformation_info handles log transform with 'Log' type (capitalized)", {
  # Line 141: "Log" = "log" normalization
  trans_info <- list(
    transformType = "Log",  # Capitalized
    channel = "APC-H"
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$type, "log")
  expect_equal(params$channel, "APC-H")
})

test_that("parse_transformation_info handles log transform with 'base' field (alternative capitalization)", {
  # Line 193: params$base <- trans_info[["base"]] %||% trans_info[["Base"]] %||% 10
  trans_info <- list(
    transformType = "log",
    channel = "PE-H",
    Base = 2  # Alternative capitalization
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$base, 2)
})

test_that("parse_transformation_info handles log transform with partial parameters", {
  # Test that only specified parameters are used, others get defaults
  trans_info <- list(
    transformType = "log",
    channel = "FSC-H",
    decadesOffset = 3  # Only specify one parameter
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$decadesOffset, 3)  # Custom value
  expect_equal(params$numberDecades, 4)  # Default
  expect_equal(params$shift, 0)           # Default
  expect_equal(params$base, 10)           # Default
})

# ============================================================================
# Tests for parse_transformation_info - biexponential branch (lines 173-179)
# ============================================================================

test_that("parse_transformation_info handles biexponential transform with default values", {
  # Lines 173-179: biexponential transform parameter extraction
  trans_info <- list(
    transformType = "biexponential",
    channel = "FITC-A"
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$type, "biexponential")
  expect_equal(params$channel, "FITC-A")
  # Default values from lines 175-178
  expect_equal(params$t, 262144)
  expect_equal(params$a, 0)
  expect_equal(params$m, 3.55)
  expect_equal(params$w, -25.11886)
})

test_that("parse_transformation_info handles biexponential transform with custom values", {
  # Lines 173-179: biexponential with custom parameters
  trans_info <- list(
    transformType = "biexponential",
    channel = "SSC-H",
    t = 100000,
    a = 50,
    m = 4.0,
    w = -20
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$t, 100000)
  expect_equal(params$a, 50)
  expect_equal(params$m, 4.0)
  expect_equal(params$w, -20)
})

test_that("parse_transformation_info handles Biex transform type (alternative name)", {
  # Line 139: "Biex" = "biexponential" normalization
  trans_info <- list(
    transformType = "Biex",  # Alternative name used in FlowJo
    channel = "APC-H"
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$type, "biexponential")
  expect_equal(params$channel, "APC-H")
})

test_that("parse_transformation_info handles biex transform type (lowercase)", {
  # Line 140: "biex" = "biexponential" normalization
  trans_info <- list(
    transformType = "biex",  # Lowercase alternative
    channel = "PE-H"
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$type, "biexponential")
  expect_equal(params$channel, "PE-H")
})

# ============================================================================
# Tests for parse_transformation_info - linear branch (lines 196-199)
# ============================================================================

test_that("parse_transformation_info handles linear transform with default values", {
  # Lines 196-199: linear transform parameter extraction
  trans_info <- list(
    transformType = "linear",
    channel = "FSC-H"
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$type, "linear")
  expect_equal(params$channel, "FSC-H")
  # Default values from lines 197-198
  expect_equal(params$a, 1)
  expect_equal(params$b, 0)
})

test_that("parse_transformation_info handles linear transform with custom values", {
  # Lines 196-199: linear with custom parameters
  trans_info <- list(
    transformType = "linear",
    channel = "SSC-H",
    a = 1000,
    b = 100
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$a, 1000)
  expect_equal(params$b, 100)
})

test_that("parse_transformation_info handles linear transform with maxRange/minRange", {
  # Lines 197-198: Alternative parameter names
  trans_info <- list(
    transformType = "linear",
    channel = "FSC-H",
    maxRange = 2000,
    minRange = 50
  )

  params <- CyFj11:::parse_transformation_info(trans_info)

  expect_equal(params$a, 2000)  # From maxRange
  expect_equal(params$b, 50)    # From minRange
})

# ============================================================================
# Tests for parse_transformation_info - unknown transform type (lines 153-156)
# ============================================================================

test_that("parse_transformation_info warns and replaces unknown transform type", {
  # Lines 153-156: Unknown transform type handling
  trans_info <- list(
    transformType = "unknown_type",
    channel = "FITC-A"
  )

  expect_warning(
    params <- CyFj11:::parse_transformation_info(trans_info),
    "Unknown transformation type 'unknown_type' replaced with biexponential"
  )

  expect_equal(params$type, "biexponential")
  expect_equal(params$channel, "FITC-A")
})

# ============================================================================
# Tests for create_transformation_list - log transform (lines 224)
# ============================================================================

test_that("create_transformation_list handles log transform", {
  # Line 224: "log" = create_log_transform(spec)
  trans_spec <- list(
    `FITC-A` = list(
      type = "log",
      channel = "FITC-A",
      decadesOffset = 1,
      numberDecades = 4,
      shift = 0,
      base = 10,
      vectorLength = 256
    )
  )

  trans_list <- CyFj11:::create_transformation_list(trans_spec)

  expect_named(trans_list, "FITC-A")
  expect_s3_class(trans_list[[1]], "transform")
})

# ============================================================================
# Tests for create_log_transform helper
# ============================================================================

test_that("create_log_transform creates log10 transform by default", {
  spec <- list(
    channel = "FITC-A",
    base = 10,
    decadesOffset = 1,
    numberDecades = 4
  )

  trans <- CyFj11:::create_log_transform(spec)

  expect_s3_class(trans, "transform")
  # Just verify the transform object was created - actual application
  # requires a flowFrame or numeric vector with proper method dispatch
})

test_that("create_log_transform handles natural log (base = exp(1))", {
  spec <- list(
    channel = "SSC-H",
    base = exp(1),
    decadesOffset = 1,
    numberDecades = 4
  )

  trans <- CyFj11:::create_log_transform(spec)

  expect_s3_class(trans, "transform")
})
