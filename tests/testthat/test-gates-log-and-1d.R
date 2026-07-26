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

#' @title Unit Tests for Log Transform and 1D Gate Conversion
#' @name test-gates-log-and-1d
#' @keywords internal
NULL

skip_if_not_installed("flowCore")
skip_if_not_installed("flowWorkspace")

library(flowCore)
library(flowWorkspace)

# ============================================================================
# Tests for display_to_raw with Log transform
# ============================================================================

test_that("display_to_raw handles Log transform - basic conversion", {
  # Log transform: raw = 10^(display * numberDecades / vectorLength + decadesOffset - 1) - shift
  # With default params (decadesOffset=1, numberDecades=4, shift=0, vectorLength=256):
  # display=0 -> 10^(0 + 1 - 1) = 10^0 = 1
  # display=128 -> 10^(128*4/256 + 1 - 1) = 10^2 = 100
  # display=256 -> 10^(256*4/256 + 1 - 1) = 10^4 = 10000

  result <- CyFj11:::display_to_raw(
    c(0, 128, 256),
    list(
      transformType = "Log",
      decadesOffset = 1,
      numberDecades = 4,
      vectorLength = 256,
      shift = 0
    )
  )

  expect_equal(result[1], 1)        # 10^0
  expect_equal(result[2], 100)      # 10^2
  expect_equal(result[3], 10000)    # 10^4
})

test_that("display_to_raw handles Log transform with custom decadesOffset", {
  # decadesOffset = 2: raw = 10^(display * 4/256 + 2 - 1) = 10^(display*4/256 + 1)
  # display=0 -> 10^1 = 10
  # display=256 -> 10^(4+1) = 10^5 = 100000

  result <- CyFj11:::display_to_raw(
    c(0, 256),
    list(
      transformType = "Log",
      decadesOffset = 2,
      numberDecades = 4,
      vectorLength = 256,
      shift = 0
    )
  )

  expect_equal(result[1], 10)       # 10^1
  expect_equal(result[2], 100000)   # 10^5
})

test_that("display_to_raw handles Log transform with shift", {
  # shift = 100: raw = 10^(display * 4/256 + 1 - 1) - 100 = 10^(display*4/256) - 100
  # display=0 -> 10^0 - 100 = 1 - 100 = -99
  # display=256 -> 10^4 - 100 = 10000 - 100 = 9900

  result <- CyFj11:::display_to_raw(
    c(0, 256),
    list(
      transformType = "Log",
      decadesOffset = 1,
      numberDecades = 4,
      vectorLength = 256,
      shift = 100
    )
  )

  expect_equal(result[1], -99)      # 10^0 - 100
  expect_equal(result[2], 9900)     # 10^4 - 100
})

test_that("display_to_raw handles Log transform with use_transformed_coords=TRUE", {
  # When use_transformed_coords=TRUE, display coords are rescaled but not inverse-transformed
  # scale_factor = target_scale / source_scale

  result <- CyFj11:::display_to_raw(
    c(0, 128, 256),
    list(
      transformType = "Log",
      vectorLength = 512  # target scale
    ),
    gate_resolution = 256,  # source scale
    use_transformed_coords = TRUE
  )

  # scale_factor = 512/256 = 2
  # result = display_coords * 2
  expect_equal(result, c(0, 256, 512))
})

test_that("display_to_raw handles Log transform with default parameters", {
  # Test with missing parameters (should use defaults)
  result <- CyFj11:::display_to_raw(
    c(0, 256),
    list(
      transformType = "Log"
      # Missing: decadesOffset, numberDecades, shift, vectorLength
    )
  )

  # Defaults: decadesOffset=1, numberDecades=4, shift=0, vectorLength=256
  # display=0 -> 10^(0*4/256 + 1 - 1) = 10^0 = 1
  # display=256 -> 10^(256*4/256 + 1 - 1) = 10^4 = 10000
  expect_equal(result[1], 1)
  expect_equal(result[2], 10000)
})

test_that("display_to_raw handles Log transform with zero vectorLength", {
  # Should warn and use default vectorLength=256
  expect_warning(
    result <- CyFj11:::display_to_raw(
      c(0, 256),
      list(
        transformType = "Log",
        vectorLength = 0
      )
    ),
    "invalid vectorLength"
  )

  # Should still work with default vectorLength
  expect_equal(result[1], 1)
  expect_equal(result[2], 10000)
})

# ============================================================================
# Tests for convert_range_gate (1D gate)
# ============================================================================

test_that("convert_range_gate converts 1D range gate", {
  gate <- list(
    parameter = "FSC-A",
    xVertices = c(50, 200),
    xAxis = list(
      parameterSpec = list(name = "FSC-A"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    )
  )

  result <- CyFj11:::convert_range_gate(
    gate = gate,
    pop_name = "Test1D",
    extend_val = 0,
    extend_to = -4000,
    correct_faulty_gate = 0,
    use_transformed_coords = FALSE
  )

  expect_s4_class(result, "rectangleGate")
  # For 1D gates, @min and @max are single numeric values
  # Parameter name is in parameters() slot
  expect_equal(unname(flowCore::parameters(result)), "FSC-A")
  expect_true(length(result@min) == 1)
  expect_equal(result@min, 51200)  # 50/256 * 262144
  expect_equal(result@max, 204800) # 200/256 * 262144
})

test_that("convert_range_gate handles gate with xParameter instead of parameter", {
  gate <- list(
    xParameter = "SSC-A",
    xVertices = c(100, 300),
    xAxis = list(
      parameterSpec = list(name = "SSC-A"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    )
  )

  result <- CyFj11:::convert_range_gate(
    gate = gate,
    pop_name = "Test1D_xParam",
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), "SSC-A")
})

test_that("convert_range_gate handles gate with xAxis only", {
  gate <- list(
    xAxis = list(
      parameterSpec = list(name = "CD3"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    ),
    xVertices = c(0.2, 0.8)
  )

  result <- CyFj11:::convert_range_gate(
    gate = gate,
    pop_name = "Test1D_xAxis",
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), "CD3")
})

test_that("convert_range_gate handles 1D gate with Log transform", {
  gate <- list(
    parameter = "APC-A",
    xVertices = c(0, 128, 256),  # Display space coordinates
    xAxis = list(
      parameterSpec = list(name = "APC-A"),
      transform = list(
        transformType = "Log",
        decadesOffset = 1,
        numberDecades = 4,
        vectorLength = 256,
        shift = 0
      )
    )
  )

  result <- CyFj11:::convert_range_gate(
    gate = gate,
    pop_name = "Test1D_Log",
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), "APC-A")

  # Check that coordinates were inverse-transformed correctly
  # display=0 -> raw=1, display=256 -> raw=10000
  # min should be ~1, max should be ~10000
  expect_equal(result@min, 1, tolerance = 0.1)
  expect_equal(result@max, 10000, tolerance = 0.1)
})

test_that("convert_range_gate handles 1D gate with Log transform and use_transformed_coords=TRUE", {
  gate <- list(
    parameter = "FITC-A",
    xVertices = c(0, 128, 256),
    xAxis = list(
      parameterSpec = list(name = "FITC-A"),
      transform = list(
        transformType = "Log",
        vectorLength = 256
      )
    ),
    gateResolution = 256
  )

  result <- CyFj11:::convert_range_gate(
    gate = gate,
    pop_name = "Test1D_LogTransformed",
    extend_val = 0,
    extend_to = -4000,
    use_transformed_coords = TRUE
  )

  expect_s4_class(result, "rectangleGate")
  # With use_transformed_coords=TRUE, coordinates stay in display space
  expect_equal(result@min, 0)
  expect_equal(result@max, 256)
})

test_that("convert_range_gate errors on missing parameter", {
  gate <- list(
    xVertices = c(50, 200)
    # Missing parameter, xParameter, and xAxis$parameterSpec$name
  )

  expect_error(
    CyFj11:::convert_range_gate(
      gate = gate,
      pop_name = "Test1D_Error",
      extend_val = 0,
      extend_to = -4000
    ),
    "missing valid parameter"
  )
})

test_that("convert_range_gate errors on missing vertices", {
  gate <- list(
    parameter = "FSC-A"
    # Missing xVertices
  )

  expect_error(
    CyFj11:::convert_range_gate(
      gate = gate,
      pop_name = "Test1D_Error2",
      extend_val = 0,
      extend_to = -4000
    ),
    "missing vertices"
  )
})

test_that("convert_range_gate handles list vertices", {
  gate <- list(
    parameter = "FSC-A",
    xVertices = list(50, 200),  # List instead of vector
    xAxis = list(
      parameterSpec = list(name = "FSC-A"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    )
  )

  result <- CyFj11:::convert_range_gate(
    gate = gate,
    pop_name = "Test1D_ListVertices",
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), "FSC-A")
})

# ============================================================================
# Tests for convert_rectangle_gate with Log transform (2D case)
# ============================================================================

test_that("convert_rectangle_gate handles 2D gate with Log transform on one axis", {
  gate <- list(
    type = "RectangleGate",
    xAxis = list(
      parameterSpec = list(name = "FSC-A"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    ),
    yAxis = list(
      parameterSpec = list(name = "SSC-A"),
      transform = list(
        transformType = "Log",
        decadesOffset = 1,
        numberDecades = 4,
        vectorLength = 256,
        shift = 0
      )
    ),
    xVertices = c(50, 200),
    yVertices = c(0, 256)
  )

  result <- CyFj11:::convert_rectangle_gate(
    gate = gate,
    pop_name = "Test2D_MixedTransform",
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), c("FSC-A", "SSC-A"))

  # FSC-A should be linearly scaled: 50/256 * 262144 = 51200, 200/256 * 262144 = 204800
  expect_equal(unname(result@min["FSC-A"]), 51200, tolerance = 1)
  expect_equal(unname(result@max["FSC-A"]), 204800, tolerance = 1)

  # SSC-A should be log-transformed: 0->1, 256->10000
  expect_equal(unname(result@min["SSC-A"]), 1, tolerance = 0.1)
  expect_equal(unname(result@max["SSC-A"]), 10000, tolerance = 0.1)
})

test_that("convert_rectangle_gate handles 1D gate (missing yAxis)", {
  gate <- list(
    type = "RectangleGate",
    xAxis = list(
      parameterSpec = list(name = "FSC-A"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    ),
    # No yAxis - this triggers 1D gate path
    xVertices = c(50, 200)
  )

  result <- CyFj11:::convert_rectangle_gate(
    gate = gate,
    pop_name = "Test1D_Rect",
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), "FSC-A")
  # FSC-A should be linearly scaled: 50/256 * 262144 = 51200, 200/256 * 262144 = 204800
  expect_equal(result@min, 51200, tolerance = 1)
  expect_equal(result@max, 204800, tolerance = 1)
})

# ============================================================================
# Tests for convert_flowjo_gate dispatch
# ============================================================================

test_that("convert_flowjo_gate dispatches to convert_range_gate for RangeGate", {
  gate <- list(
    type = "RangeGate",
    parameter = "FSC-A",
    xVertices = c(50, 200),
    xAxis = list(
      parameterSpec = list(name = "FSC-A"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    )
  )

  result <- CyFj11:::convert_flowjo_gate(
    gate = gate,
    pop_name = "RangeTest",
    pop_type = "RangeGate",
    channel.ignore.case = FALSE,
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), "FSC-A")
})

test_that("convert_flowjo_gate handles RangeGate with type='range'", {
  gate <- list(
    type = "range",  # Alternative type name
    parameter = "SSC-A",
    xVertices = c(100, 300),
    xAxis = list(
      parameterSpec = list(name = "SSC-A"),
      transform = list(
        transformType = "Linear",
        minRange = 0,
        maxRange = 262144,
        vectorLength = 256
      )
    )
  )

  result <- CyFj11:::convert_flowjo_gate(
    gate = gate,
    pop_name = "RangeTest2",
    pop_type = "range",
    channel.ignore.case = FALSE,
    extend_val = 0,
    extend_to = -4000
  )

  expect_s4_class(result, "rectangleGate")
  expect_equal(unname(flowCore::parameters(result)), "SSC-A")
})
