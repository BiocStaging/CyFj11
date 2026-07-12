#!/usr/bin/env Rscript
# Compare original FlowSOM test14 compensation matrix with the CyFj11-exported matrix.
# The original workspace uses coefficients on a 0-1 scale (column-normalised to the
# diagonal = 1). The exported workspace uses percentages (diagonal = 100).
# We rescale the exported matrix to 0-1 before comparison.

suppressPackageStartupMessages({
  library(xml2)
  library(dplyr)
  library(tidyr)
  library(readr)
})

ORIG_WSP <- "flowjo_export_tests/test14/test14_flowsom.wsp"
EXP_WSP  <- "flowjo_export_tests/test14/test14.compensation.wsp"
OUT_CSV  <- "manuscript/test14_compensation_elementwise.csv"
OUT_MD   <- "manuscript/test14_compensation_elementwise.md"

extract_spillover <- function(path) {
  doc <- read_xml(path)
  ns  <- xml_ns(doc)

  # Some WSPs omit namespace declarations but still use prefixes in child names.
  # Build an XPath that works whether or not the prefix is bound.
  t_prefix <- if (any(names(ns) == "transforms")) "transforms" else {
    idx <- grep("transformations", ns)
    if (length(idx)) names(ns)[idx[1]] else "transforms"
  }

  mat_xpath <- sprintf(".//%s:spilloverMatrix", t_prefix)
  mat <- xml_find_first(doc, mat_xpath, ns = ns)
  if (length(mat) == 0 || is.na(mat)) {
    # Fallback: local-name search
    mat <- xml_find_first(doc, "//*[local-name()='spilloverMatrix']")
  }
  if (length(mat) == 0 || is.na(mat)) stop("No spilloverMatrix found in ", path)

  params <- xml_find_all(mat, ".//*[local-name()='parameter']") %>% xml_attr("name")
  # Attributes may be prefixed (data-type:name) or unprefixed (name)
  if (all(is.na(params))) {
    params <- xml_find_all(mat, ".//*[local-name()='parameter']") %>%
      xml_attr("name", ns = ns)
  }
  params <- params[!is.na(params)]

  spills <- xml_find_all(mat, ".//*[local-name()='spillover']")

  rows <- lapply(spills, function(s) {
    coeffs <- xml_find_all(s, ".//*[local-name()='coefficient']")
    vals <- xml_attr(coeffs, "value") %>% as.numeric()
    if (all(is.na(vals))) vals <- xml_attr(coeffs, "value", ns = ns) %>% as.numeric()
    names(vals) <- xml_attr(coeffs, "parameter")
    if (all(is.na(names(vals)))) names(vals) <- xml_attr(coeffs, "parameter", ns = ns)
    vals
  })

  M <- do.call(rbind, lapply(rows, function(r) r[params]))
  if (is.null(dim(M)) || nrow(M) != length(params)) {
    stop(sprintf("Could not build matrix from %s: got %d rows, expected %d",
                 path, if (is.null(dim(M))) length(M) else nrow(M), length(params)))
  }
  rownames(M) <- params
  colnames(M) <- params
  M
}

orig <- extract_spillover(ORIG_WSP)
exp  <- extract_spillover(EXP_WSP)

# Exported matrix is in percent (diagonal 100); original is proportion (diagonal 1).
exp_scaled <- exp / 100

all.equal(orig, exp_scaled, tolerance = 1e-6)

rel_diff <- (exp_scaled - orig) / orig
rel_diff[is.infinite(rel_diff) | is.nan(rel_diff)] <- 0
abs_rel_diff <- abs(rel_diff)

# Summary
max_abs_rel <- max(abs_rel_diff, na.rm = TRUE)
mean_abs_rel <- mean(abs_rel_diff, na.rm = TRUE)
median_abs_rel <- median(abs_rel_diff, na.rm = TRUE)
max_idx <- which(abs_rel_diff == max_abs_rel, arr.ind = TRUE)

# Long-format table
long <- as.data.frame(as.table(rel_diff)) %>%
  rename(from = Var1, to = Var2, rel_diff = Freq) %>%
  mutate(
    original = as.vector(orig),
    exported = as.vector(exp_scaled),
    abs_rel_diff = abs(rel_diff),
    pct_diff = rel_diff * 100
  ) %>%
  select(from, to, original, exported, pct_diff, abs_rel_diff) %>%
  arrange(desc(abs_rel_diff))

write.csv(long, OUT_CSV, row.names = FALSE)

# Markdown report
cat(sprintf("# Test 14 compensation matrix element-wise comparison\n\n"), file = OUT_MD)
cat(sprintf("Original source: `%s`\n\n", ORIG_WSP), file = OUT_MD, append = TRUE)
cat(sprintf("Exported source: `%s`\n\n", EXP_WSP), file = OUT_MD, append = TRUE)
cat(sprintf("The exported matrix stores coefficients as percentages (diagonal = 100); "
            "the original stores them as proportions (diagonal = 1). "
            "After rescaling the exported matrix by ÷100, the matrices are compared element-wise.\n\n"),
    file = OUT_MD, append = TRUE)
cat(sprintf("- Matrix dimension: %d × %d\n", nrow(orig), ncol(orig)), file = OUT_MD, append = TRUE)
cat(sprintf("- Mean absolute relative difference: %.6f%%\n", mean_abs_rel * 100), file = OUT_MD, append = TRUE)
cat(sprintf("- Median absolute relative difference: %.6f%%\n", median_abs_rel * 100), file = OUT_MD, append = TRUE)
cat(sprintf("- Maximum absolute relative difference: %.6f%% (at %s → %s)\n\n",
            max_abs_rel * 100, rownames(orig)[max_idx[1,1]], colnames(orig)[max_idx[1,2]]),
    file = OUT_MD, append = TRUE)

# Top differences table
cat("## Largest absolute relative differences\n\n", file = OUT_MD, append = TRUE)
cat("| From | To | Original | Exported (scaled) | Relative diff (%) |\n", file = OUT_MD, append = TRUE)
cat("|---|---:|---:|---:|---:|\n", file = OUT_MD, append = TRUE)
for (i in seq_len(min(20, nrow(long)))) {
  r <- long[i, ]
  cat(sprintf("| %s | %s | %.7f | %.7f | %.6f |\n",
              r$from, r$to, r$original, r$exported, r$pct_diff),
      file = OUT_MD, append = TRUE)
}

cat(sprintf("\nFull element-wise results: `%s`\n", OUT_CSV), file = OUT_MD, append = TRUE)

message("Done. Max absolute relative difference: ", round(max_abs_rel * 100, 6), "%")
