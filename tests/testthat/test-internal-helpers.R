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

# Unit tests for small internal helper functions that can be tested in isolation.

test_that("%||% returns left operand when not NULL", {
  expect_equal("value" %||% "default", "value")
  expect_equal(0 %||% 1, 0)
  expect_equal(FALSE %||% TRUE, FALSE)
})

test_that("%||% returns right operand when NULL", {
  expect_equal(NULL %||% "default", "default")
  expect_equal(NULL %||% 42, 42)
  expect_equal(NULL %||% NULL, NULL)
})

test_that("sanitize_population_name handles vectors and lists", {
  expect_equal(sanitize_population_name("CD45+/Lymph"), "CD45+:Lymph")
  expect_equal(sanitize_population_name("NoSlash"), "NoSlash")
  expect_equal(
    sanitize_population_name(list("A/B", "C")),
    list("A:B", "C")
  )
})

test_that("sanitize_path_with_separator preserves path separator", {
  expect_equal(
    unname(sanitize_path_with_separator("root/Lymph/CD45+/T")),
    "root/Lymph/CD45+/T"
  )
  expect_null(sanitize_path_with_separator(NULL))
})

test_that("map_param_names handles exact and sanitized matches", {
  src <- c("Comp-FITC-A", "CD4/PE", "missing")
  tgt <- c("FITC-A", "CD4_PE", "SSC-A")

  mapping <- map_param_names(src, tgt, strip_comp_prefix = TRUE)
  expect_equal(mapping[["Comp-FITC-A"]], "FITC-A")
  expect_equal(mapping[["CD4/PE"]], "CD4_PE")
  expect_null(mapping[["missing"]])
})

test_that("map_param_names supports description matching", {
  src <- c("CD4", "CD8")
  tgt <- c("CD4-FITC", "CD8-PE", "SSC-A")
  desc <- c(`CD4-FITC` = "CD4", `CD8-PE` = "CD8", `SSC-A` = "scatter")

  mapping <- map_param_names(src, tgt, target_descriptions = desc)
  expect_equal(mapping[["CD4"]], "CD4-FITC")
  expect_equal(mapping[["CD8"]], "CD8-PE")
})

test_that("map_param_names returns empty or all-null when inputs are empty", {
  expect_equal(map_param_names(character(), c("A")), list())
  expect_equal(
    map_param_names(c("A"), character()),
    setNames(list(NULL), "A")
  )
})

test_that("apply_param_mapping keeps, drops, or warns", {
  mapping <- list(A = "a", B = "b")

  expect_equal(
    unname(apply_param_mapping(c("A", "B", "C"), mapping, on_no_match = "keep")),
    c("a", "b", "C")
  )
  expect_equal(
    unname(apply_param_mapping(c("A", "B", "C"), mapping, on_no_match = "drop")),
    c("a", "b")
  )
  expect_warning(
    apply_param_mapping(c("A", "C"), mapping, on_no_match = "warn"),
    "Could not map parameter name 'C'"
  )
})

test_that("parse_compensation_data accepts matrix, df, string, and list", {
  mat <- matrix(c(1, 0.1, 0.2, 1), nrow = 2,
                dimnames = list(c("F", "G"), c("F", "G")))
  expect_s4_class(parse_compensation_data(mat), "compensation")

  expect_s4_class(
    parse_compensation_data(as.data.frame(mat)),
    "compensation"
  )

  comp_string <- "2,F,G,1,0.1,0.2,1"
  expect_s4_class(parse_compensation_data(comp_string), "compensation")

  comp_list <- list(
    matrix = list(c(1, 0.1), c(0.2, 1)),
    parameters = c("F", "G")
  )
  expect_s4_class(parse_compensation_data(comp_list), "compensation")

  # Note: as.integer("invalid") produces NA with a warning, then our validation warns
  expect_warning(
    expect_warning(
      parse_compensation_data(comp_data = "invalid"),
      "Invalid compensation string format"
    ),
    "NAs introduced"
  )
})

test_that("parse_compensation_data warns on malformed string", {
  expect_warning(
    out <- parse_compensation_data("2,F,G,1,0.1"),
    "Invalid compensation string format"
  )
  expect_null(out)
})

test_that("validate_compensation accepts compensation, matrix, and data frame", {
  mat <- matrix(c(1, 0, 0, 1), nrow = 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  expect_s4_class(validate_compensation(mat), "compensation")
  expect_s4_class(validate_compensation(as.data.frame(mat)), "compensation")
  expect_s4_class(
    validate_compensation(flowCore::compensation(mat)),
    "compensation"
  )
})

test_that("validate_compensation errors on bad inputs", {
  expect_error(
    validate_compensation(matrix(1:4, nrow = 2)),
    "must have row and column names"
  )
  expect_error(
    validate_compensation("bad"),
    "Invalid compensation object"
  )
})

test_that("map_compensation_names maps names and warns", {
  comp <- flowCore::compensation(matrix(
    c(1, 0.1, 0.2, 1),
    nrow = 2,
    dimnames = list(c("CD4_FITC", "CD8_PE"), c("CD4_FITC", "CD8_PE"))
  ))
  mapped <- map_compensation_names(comp, c("CD4_FITC", "CD8_PE"))
  expect_s4_class(mapped, "compensation")
  expect_equal(colnames(mapped@spillover), c("CD4_FITC", "CD8_PE"))

  # Suppress expected warning about unmapped channel
  suppressWarnings(
    map_compensation_names(comp, c("unknown"))
  )
})

test_that("display_to_raw handles common transform types", {
  # Linear
  expect_equal(
    display_to_raw(c(0, 128, 256),
                   list(transformType = "Linear", minRange = 0, maxRange = 262144)),
    c(0, 131072, 262144)
  )

  # NULL transform spec
  expect_equal(display_to_raw(c(1, 2, 3), NULL), c(1, 2, 3))

  # Empty input
  expect_equal(display_to_raw(NULL, NULL), numeric(0))
  expect_equal(display_to_raw(list(), NULL), numeric(0))

  # Unsupported type returns as-is
  expect_warning(
    out <- display_to_raw(c(1, 2), list(transformType = "Unknown")),
    "Unsupported transform type"
  )
  expect_equal(out, c(1, 2))
})

test_that("display_to_raw errors on linear maxRange=0", {
  expect_error(
    display_to_raw(100, list(transformType = "Linear", minRange = 0, maxRange = 0)),
    "maxRange=0"
  )
})

test_that("apply_extension only modifies values below threshold", {
  expect_equal(apply_extension(c(-100, 0, 50, 100), 10, -4000),
               c(-4000, -4000, 50, 100))
  expect_equal(apply_extension(c(1, 2, 3), 0, -4000),
               c(1, 2, 3))
  expect_equal(apply_extension(c(1, 2, 3), 0, 0), c(1, 2, 3))
})

test_that("convert_flowjo_gate infers and converts rectangle gate", {
  gate <- list(
    type = "RectangleGate",
    xAxis = list(parameterSpec = list(name = "FSC-A")),
    yAxis = list(parameterSpec = list(name = "SSC-A")),
    xVertices = c(0, 256),
    yVertices = c(0, 256),
    xAxis = list(parameterSpec = list(name = "FSC-A"),
                 transform = list(transformType = "Linear", minRange = 0, maxRange = 262144)),
    yAxis = list(parameterSpec = list(name = "SSC-A"),
                 transform = list(transformType = "Linear", minRange = 0, maxRange = 262144))
  )
  out <- convert_flowjo_gate(gate, "rect_pop")
  expect_s4_class(out, "rectangleGate")
})

test_that("convert_flowjo_gate infers gate type from structure", {
  gate <- list(
    xVertices = c(0, 128, 256),
    yVertices = c(0, 128, 256),
    xAxis = list(parameterSpec = list(name = "FSC-A"),
                 transform = list(transformType = "Linear", minRange = 0, maxRange = 262144)),
    yAxis = list(parameterSpec = list(name = "SSC-A"),
                 transform = list(transformType = "Linear", minRange = 0, maxRange = 262144))
  )
  out <- convert_flowjo_gate(gate, "poly_pop", "PolygonGate")
  expect_s4_class(out, "polygonGate")
})

test_that("convert_flowjo_gate warns on unsupported type", {
  gate <- list(type = "UnsupportedGate")
  expect_warning(
    out <- convert_flowjo_gate(gate, "bad_pop"),
    "Unsupported gate type"
  )
  expect_null(out)
})

test_that("convert_flowjo_gate converts boolean gate", {
  gate <- list(
    type = "BooleanGate",
    specification = "A & B"
  )
  out <- convert_flowjo_gate(gate, "bool_pop", "BooleanGate")
  expect_s4_class(out, "booleanFilter")
})
