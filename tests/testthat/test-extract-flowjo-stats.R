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

#' @title Unit Tests for FlowJo Workspace Statistics Extraction
#' @name test-extract-flowjo-stats
#' @keywords internal
NULL

# Create a minimal FlowJo .wsp XML file in a temporary directory
make_minimal_wsp <- function(dir, name = "test.wsp") {
  path <- file.path(dir, name)
  xml <- '<Workspace>
  <SampleNode name="Sample1" sampleID="S1" count="100000">
    <Population name="CD45+" id="P1" count="75000">
      <Population name="T cells" id="P2" count="40000">
        <Population name="CD4+" id="P3" count="25000">
          <Statistic name="Freq. of Parent" ancestor="" value="62.5" id="S1"/>
          <Statistic name="Median" ancestor="" value="4.2" id="S2"/>
        </Population>
        <Population name="CD4-" id="P4" count="15000">
          <Statistic name="Freq. of Parent" ancestor="" value="37.5" id="S3"/>
        </Population>
      </Population>
    </Population>
  </SampleNode>
</Workspace>'
  writeLines(xml, path)
  path
}

test_that("extract_wsp_data_long returns expected columns and rows", {
  tmp <- tempdir()
  wsp <- make_minimal_wsp(tmp)

  long <- extract_wsp_data_long(wsp)

  expect_s3_class(long, "tbl_df")
  expect_named(long, c("file", "sample_name", "sample_id", "sample_count",
                       "population_path", "population", "id", "field_type",
                       "stat_name", "stat_ancestor", "value_raw"))
  # CD45+, T cells, CD4+, CD4- => 4 PopulationCount rows
  expect_equal(sum(long$field_type == "PopulationCount"), 4)
  # 3 Statistic rows
  expect_equal(sum(long$field_type == "Statistic"), 3)

  # Population paths are built correctly
  cd4_plus <- long %>% filter(population == "CD4+")
  expect_equal(cd4_plus$population_path[1], "CD45+ / T cells / CD4+")
})

test_that("sanitize_name preserves +/- distinction", {
  expect_equal(sanitize_name("CD4+"), "CD4+")
  expect_equal(sanitize_name("CD4-"), "CD4-")
  expect_equal(sanitize_name("CD4+/CD8+"), "CD4+_CD8+")
  expect_equal(sanitize_name("1start"), "X1start")
})

test_that("shorten_stat_name shortens common statistics", {
  expect_equal(shorten_stat_name("Freq. of Parent"), "FreqParent")
  expect_equal(shorten_stat_name("PopulationCount"), "Count")
  expect_equal(shorten_stat_name("Median"), "Median")
})

test_that("make_better_names keeps +/- distinct and suffixes true duplicates", {
  nms <- make_better_names(c("CD4+", "CD4-"), "Freq. of Parent", NA)
  expect_equal(length(unique(nms)), 2)
  expect_true(grepl("CD4\\+", nms[1]))
  expect_true(grepl("CD4-", nms[2]))

  nms_dup <- make_better_names(c("CD4+", "CD4+"), "Count", NA)
  expect_equal(nms_dup, c("CD4+_Count", "CD4+_Count_2"))

  nms_anc <- make_better_names("CD4+", "Freq. of Parent", "CD45+")
  expect_equal(nms_anc, "CD4+_FreqParent_rel_CD45+")
})

test_that("extract_flowjo_stats returns template when csv_file is NULL", {
  tmp <- tempdir()
  wsp <- make_minimal_wsp(tmp)

  result <- extract_flowjo_stats(wsp, write_csv = FALSE)

  expect_type(result, "list")
  expect_named(result, c("long", "mapping"))
  expect_true("better_name" %in% names(result$mapping))
  expect_true(all(!is.na(result$mapping$better_name)))
})

test_that("extract_flowjo_stats produces wide table from valid CSV", {
  tmp <- tempdir()
  wsp <- make_minimal_wsp(tmp)

  template <- extract_flowjo_stats(wsp, write_csv = FALSE)
  csv_path <- file.path(tmp, "mapping.csv")
  readr::write_csv(template$mapping, csv_path)

  wide <- extract_flowjo_stats(wsp, csv_file = csv_path)

  expect_s3_class(wide, "tbl_df")
  expect_equal(nrow(wide), 1)
  expect_true("CD4+_FreqParent" %in% names(wide))
  expect_true("CD4-_FreqParent" %in% names(wide))
})

test_that("extract_flowjo_stats errors on missing signatures with file info", {
  tmp <- tempdir()
  wsp <- make_minimal_wsp(tmp)

  # CSV missing the CD4- population
  partial <- tibble::tibble(
    population_path = "CD45+ / T cells / CD4+",
    stat_name = "Freq. of Parent",
    stat_ancestor = NA_character_,
    better_name = "CD4_FreqParent"
  )
  csv_path <- file.path(tmp, "partial.csv")
  readr::write_csv(partial, csv_path)

  expect_error(
    extract_flowjo_stats(wsp, csv_file = csv_path),
    regexp = "missing from csv_file"
  )
})

test_that("check_wsp_csv_coverage reports missing signatures", {
  tmp <- tempdir()
  wsp <- make_minimal_wsp(tmp)

  template <- extract_flowjo_stats(wsp, write_csv = FALSE)
  # Drop one row from mapping
  partial_mapping <- template$mapping[-1, ]
  csv_path <- file.path(tmp, "partial.csv")
  readr::write_csv(partial_mapping, csv_path)

  coverage <- check_wsp_csv_coverage(wsp, csv_path)

  expect_s3_class(coverage, "tbl_df")
  expect_equal(nrow(coverage), 1)
  expect_true(coverage$missing_signatures > 0)
  expect_false(coverage$covered)
})
