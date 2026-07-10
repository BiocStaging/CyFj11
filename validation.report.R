#!/usr/bin/env Rscript
# =============================================================================
# CyFj11 Validation Statistics — reads Supplementary Table S1 (.xlsx)
# =============================================================================
# Usage (CLI):  Rscript validation.report.R [table.xlsx] [sheet]
# Usage (R):    source("validation.report.R"); res <- main("manuscript/validation_counts 2.xlsx")
#
# STRUCTURE OF THE XLSX (observed):
#   Row 1:     Sheet title "validation_counts" in col A, rest NA
#   Rows 2–23: Instruction/comment rows — col A starts with "#", rest NA
#   Row 24:    Header row: test | gate_name | hierarchy | ... | notes
#   Rows 25+:  Data rows interspersed with comment/blank rows
#
# TEST14 SPECIAL CASE:
#   Rows 91–105 have comment text (or NA) in the 'test' column while the
#   gate data lives in gate_name onward.  Filtering on col A alone would
#   silently discard all test14 data.
#
# KEY DESIGN: data rows are identified by gate_name being non-empty and
#   non-comment — NOT by col A content.
# =============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringr)
  library(readr)
})

# ── CONFIGURATION ─────────────────────────────────────────────────────────────

DEFAULT_PATH <- "manuscript/validation_counts 2.xlsx"
DEFAULT_SHEET <- 1

# Strings treated as NA in count cells
NA_STRINGS <- c(
  "NA", "Na", "na", "N/A", "n/a", "N/a",
  "Not imported", "Not implemented", "Not applicable",
  "Problem importing marker names",
  "[a]", "-", "—", ""
)

THRESH_MINOR <- 0.30   # ≤ this % → "within threshold" discrepancy
THRESH_PASS  <- 0.50   # acceptance criterion for mean |% diff|

# Arcsinh exclusion rules.
# gate = NULL  →  entire test excluded (only one gate anyway).
# gate = name  →  only that specific gate excluded.
# Rationale: test13/live and test13/singlets are scatter (linear) gates
# inside an arcsinh test; we keep them in "core" for export validation.
ARCSINH_RULES <- list(
  list(test = "test08", gate = NULL),            # whole test, single gate
  list(test = "test11", gate = "APC_pos"),       # only APC_pos uses arcsinh
  list(test = "test13", gate = "FITC_PE_gate"),  # arcsinh ellipse
  list(test = "test13", gate = "FITC_pos"),      # arcsinh 1D rect
  list(test = "test13", gate = "APC_pos")        # arcsinh 1D rect
  # test13/double_pos and test13/not_double caught by is_boolean flag
  # test13/live and test13/singlets are linear scatter → stay in core
)

# Gate names that uniquely identify test14 rows
TEST14_GATES <- c(
  "Lymphocytes", "Singlets", "Singlets2",
  "NK1_1+", "Nk1_1+", "NK cells", "NK T cells",
  "NK1_1-", "Nk1_1-", "B cells", "T cells",
  "Ab T cells", "CD4 T cells", "CD8 T cells",
  "DN T cells", "DP T cells", "Gd T cells"
)

# Ratio thresholds for flagging suspicious fl11_remake values
FLAG_LO <- 0.20
FLAG_HI <- 5.00

# =============================================================================
# 1. READ XLSX
# =============================================================================

# Convert one column-name string to lower_snake_case
norm_name <- function(x) {
  x %>%
    trimws() %>% tolower() %>%
    str_replace_all("[^a-z0-9]+", "_") %>%
    str_replace_all("_+", "_") %>%
    str_remove("^_|_$")
}

# Map variant column names produced by norm_name() to canonical internal names.
# Must run AFTER norm_name() so inputs are already lower_snake_case.
remap_colnames <- function(x) {
  for (i in seq_along(x)) {
    v <- x[i]
    # "fj11_remake", "fl11_remake", "fj11remake" … → fl11_remake
    if (grepl("(fj11|fl11).*(remake|remade)", v, ignore.case = TRUE))
      x[i] <- "fl11_remake"
    # "read_fj11", "read_fj_11" … → read_fj11
    if (grepl("^read.*(fj|j).*11", v, ignore.case = TRUE))
      x[i] <- "read_fj11"
  }
  x
}

#' Read the xlsx and return a clean data.frame with standardised column names.
read_xlsx_table <- function(path, sheet = DEFAULT_SHEET, debug = FALSE) {
  
  if (!file.exists(path)) stop("File not found: ", path)
  cat("Reading:", path, "  sheet:", sheet, "\n")
  
  raw <- read_excel(
    path, sheet = sheet,
    col_names = FALSE, col_types = "text",
    .name_repair = "minimal"
  )
  cat(sprintf("  Raw sheet: %d rows × %d cols\n", nrow(raw), ncol(raw)))
  
  # ── Locate header row ──────────────────────────────────────────────────────
  # Header row = first row containing the exact text "gate_name" in any cell
  is_hdr <- apply(raw, 1, function(r)
    any(grepl("^\\s*gate_name\\s*$", as.character(r), ignore.case = TRUE),
        na.rm = TRUE))
  
  hdr_positions <- which(is_hdr)
  if (!length(hdr_positions))
    stop("No header row found. Expected a cell containing exactly 'gate_name'.")
  
  hdr_row <- hdr_positions[1]
  cat(sprintf("  Header row at xlsx row %d\n", hdr_row))
  if (length(hdr_positions) > 1)
    cat(sprintf("  (Duplicate header rows at rows %s — ignored)\n",
                paste(hdr_positions[-1], collapse = ", ")))
  
  # ── Build column names ─────────────────────────────────────────────────────
  raw_names  <- as.character(raw[hdr_row, ])
  col_names  <- vapply(raw_names, norm_name, character(1))
  col_names  <- remap_colnames(col_names)
  col_names  <- make.unique(col_names, sep = "_x")
  
  cat(sprintf("  Columns: %s\n", paste(col_names, collapse = " | ")))
  
  # ── Locate key column indices ──────────────────────────────────────────────
  g_col <- which(col_names == "gate_name")[1]
  t_col <- which(col_names == "test")[1]
  
  if (is.na(g_col)) stop("'gate_name' column not found after normalisation.")
  if (is.na(t_col)) stop("'test' column not found after normalisation.")
  
  # ── Extract body rows ──────────────────────────────────────────────────────
  body <- raw[(hdr_row + 1):nrow(raw), ]
  colnames(body) <- col_names
  
  # A DATA ROW has gate_name non-empty and not starting with "#"
  gv <- trimws(as.character(body[[g_col]]))
  is_data <- !is.na(gv) & nchar(gv) > 0 & gv != "NA" &
    !grepl("^\\s*#", gv)
  
  data <- body[is_data, ]
  cat(sprintf("  Data rows extracted: %d\n", nrow(data)))
  
  # ── Clean 'test' column ────────────────────────────────────────────────────
  # Keep only proper "testNN" tokens; replace everything else (comments,
  # NA, long strings from test14 rows) with NA_character_
  tv <- trimws(as.character(data[[t_col]]))
  tv[!grepl("^test\\d+$", tv, ignore.case = TRUE)] <- NA_character_
  data[[t_col]] <- tv
  
  # ── Assign test14 to unlabelled rows ──────────────────────────────────────
  gv2 <- trimws(as.character(data[["gate_name"]]))
  n_before <- sum(is.na(data[["test"]]))
  data <- data %>%
    mutate(test = case_when(
      is.na(test) & gate_name %in% TEST14_GATES ~ "test14",
      TRUE ~ test
    ))
  n_after <- sum(is.na(data[["test"]]))
  cat(sprintf("  test14 rows labelled: %d\n", n_before - n_after))
  
  # Drop any rows still without a test label
  n0 <- nrow(data)
  data <- data %>% filter(!is.na(test), test != "")
  if (nrow(data) < n0)
    cat(sprintf("  Rows dropped (no test label): %d\n", n0 - nrow(data)))
  
  if (debug) {
    cat("\n  ── DEBUG: first 6 data rows ──\n")
    print(as.data.frame(head(data, 6)), row.names = FALSE)
    cat("\n  ── DEBUG: test14 rows ──\n")
    print(as.data.frame(data[data$test == "test14", ]), row.names = FALSE)
  }
  
  data
}

# =============================================================================
# 2. CLEAN AND CLASSIFY
# =============================================================================

to_num <- function(x) {
  x <- trimws(as.character(x))
  x[x %in% NA_STRINGS] <- NA
  suppressWarnings(as.numeric(x))
}

# Compute residual discrepancy for child gates after removing the error
# inherited from the parent population.  For root gates residual == delta.
# Sign convention follows the curated table:  truth - observed.
compute_residuals <- function(df, truth_col, obs_col) {
  res <- rep(NA_real_, nrow(df))
  for (i in seq_len(nrow(df))) {
    truth_c <- df[[truth_col]][i]
    obs_c   <- df[[obs_col]][i]
    if (is.na(truth_c) || truth_c <= 0 || is.na(obs_c)) next

    child_delta <- truth_c - obs_c
    hier <- trimws(as.character(df$hierarchy[i]))
    if (is.na(hier) || hier == "" || hier == "NA") {
      res[i] <- child_delta
      next
    }

    # Parent path = hierarchy with the last segment removed
    parts <- strsplit(hier, "/")[[1]]
    parts <- parts[parts != ""]
    if (length(parts) <= 1) {
      res[i] <- child_delta
      next
    }
    parent_hier <- paste0("/", paste(parts[-length(parts)], collapse = "/"))

    parent_idx <- which(df$test == df$test[i] & trimws(df$hierarchy) == parent_hier)
    if (length(parent_idx) != 1) {
      res[i] <- child_delta
      next
    }

    truth_p <- df[[truth_col]][parent_idx]
    obs_p   <- df[[obs_col]][parent_idx]
    if (is.na(truth_p) || truth_p <= 0 || is.na(obs_p)) {
      res[i] <- child_delta
      next
    }

    inherited_delta <- truth_c * (truth_p - obs_p) / truth_p
    res[i] <- child_delta - inherited_delta
  }
  res
}

flag_arcsinh <- function(tests, gates) {
  out <- rep(FALSE, length(tests))
  for (rule in ARCSINH_RULES) {
    tm <- !is.na(tests) & tolower(tests) == rule$test
    out <- out | if (is.null(rule$gate)) tm
    else tm & !is.na(gates) & gates == rule$gate
  }
  out
}

clean_and_classify <- function(df) {
  
  df <- df %>% mutate(across(where(is.character), ~trimws(as.character(.x))))
  
  # Numeric columns — fill missing columns with NA rather than error
  num_cols <- c("r_count","fj10_count","fj11_count",
                "fl11_remake","read_fj11","fj10_r_diff","fj11_r_diff")
  for (col in num_cols) {
    if (col %in% names(df)) df[[col]] <- to_num(df[[col]])
    else                     df[[col]] <- NA_real_
  }

  # Residual discrepancies: remove error inherited from parent population
  df$residual_fj10 <- compute_residuals(df, "r_count", "fj10_count")
  df$residual_fj11 <- compute_residuals(df, "r_count", "fj11_count")
  # For FJ11r the reference is N_re (read_fj11) and the observed is N_FJ11r
  df$residual_fj11r <- compute_residuals(df, "read_fj11", "fl11_remake")

  df %>%
    mutate(
      is_boolean    = grepl("bool:", gate_type, ignore.case = TRUE),
      is_arcsinh    = flag_arcsinh(test, gate_name),
      is_real_world = test == "test14",
      is_synthetic  = grepl("^test(0[1-9]|1[0-3])$", test, ignore.case = TRUE),
      # Export valid: need r_count > 0 and fj10_count present
      export_valid  = !is.na(r_count) & r_count > 0 & !is.na(fj10_count),
      # Import valid: need fl11_remake > 0 and read_fj11 present
      import_valid  = !is.na(fl11_remake) & fl11_remake > 0 & !is.na(read_fj11)
    )
}

# =============================================================================
# 3. DATA QUALITY CHECKS
# =============================================================================

hdr     <- function(t, w = 70) {
  cat("\n", strrep("═", w), "\n  ", t, "\n", strrep("═", w), "\n", sep = "")
}
sub_hdr <- function(t) cat("\n  ──", t, "\n")

check_quality <- function(df) {
  
  hdr("DATA QUALITY FLAGS")
  bad <- character(0)
  issues <- 0L
  
  # ── Boolean gates where fl11_remake / r_count is implausible ──────────────
  # (catches OR/NOT swap: OR should have ~max(FSC,SSC) events,
  #  NOT should have complement; if swapped the ratio will be far from 1)
  b_flag <- df %>%
    filter(is_boolean, !is.na(fl11_remake), !is.na(r_count), r_count > 0) %>%
    mutate(ratio = fl11_remake / r_count) %>%
    filter(ratio < FLAG_LO | ratio > FLAG_HI) %>%
    select(test, gate_name, gate_type, r_count, fl11_remake, read_fj11)
  
  if (nrow(b_flag)) {
    issues <- issues + nrow(b_flag)
    cat(sprintf("\n  ⚠  Boolean fl11_remake/r_count outside [%.2f, %.2f]",
                FLAG_LO, FLAG_HI),
        sprintf("(%d rows — likely data-entry swap, e.g. OR↔NOT):\n",
                nrow(b_flag)))
    print(as.data.frame(b_flag), row.names = FALSE)
    bad <- c(bad, paste(b_flag$test, b_flag$gate_name, sep = "/"))
    cat("  → Excluded from import statistics.\n")
  }
  
  # ── Order-of-magnitude errors in read_fj11 ────────────────────────────────
  oom <- df %>%
    filter(import_valid, !is.na(r_count), r_count > 0) %>%
    mutate(ratio = read_fj11 / r_count) %>%
    filter(ratio > 8 | ratio < 0.1) %>%
    select(test, gate_name, r_count, fl11_remake, read_fj11)
  
  if (nrow(oom)) {
    issues <- issues + nrow(oom)
    cat(sprintf("\n  ⚠  read_fj11/r_count outside [0.1, 8.0]  (%d rows):\n",
                nrow(oom)))
    print(as.data.frame(oom), row.names = FALSE)
    bad <- c(bad, paste(oom$test, oom$gate_name, sep = "/"))
  }
  
  # ── Cross-check stored diff column against computed value ─────────────────
  dc <- df %>%
    filter(export_valid, !is.na(fj10_r_diff)) %>%
    mutate(
      computed  = fj10_count - r_count,
      mismatch  = abs(computed - fj10_r_diff) > 0
    ) %>%
    filter(mismatch) %>%
    select(test, gate_name, r_count, fj10_count, fj10_r_diff, computed)
  
  if (nrow(dc)) {
    issues <- issues + nrow(dc)
    cat(sprintf("\n  ⚠  fj10_r_diff ≠ fj10_count − r_count  (%d rows):\n",
                nrow(dc)))
    print(as.data.frame(dc), row.names = FALSE)
  }
  
  # ── Rows with missing r_count ─────────────────────────────────────────────
  nr <- df %>% filter(is.na(r_count) | r_count <= 0)
  if (nrow(nr)) {
    issues <- issues + nrow(nr)
    cat(sprintf("\n  ⚠  Missing/zero r_count  (%d rows):\n", nrow(nr)))
    print(as.data.frame(select(nr, test, gate_name, r_count)),
          row.names = FALSE)
  }
  
  if (!issues) cat("  No issues detected.\n")
  
  unique(bad)
}

# =============================================================================
# 4. STATISTICS ENGINE
# =============================================================================

calc_stats <- function(truth, residual_diff, label = "", ids = NULL) {
  keep <- !is.na(truth) & !is.na(residual_diff) & truth > 0
  if (!any(keep)) return(list(label = label, n = 0L))

  t  <- truth[keep]
  rd <- residual_diff[keep]
  id <- if (!is.null(ids)) ids[keep] else seq_along(t)
  ad <- abs(rd)
  pd <- ad / t * 100

  list(
    label      = label,
    n          = sum(keep),
    n_exact    = sum(ad == 0),
    pct_exact  = round(mean(ad == 0) * 100, 1),
    n_within   = sum(ad > 0 & pd <= THRESH_MINOR),
    pct_within = round(mean(ad > 0 & pd <= THRESH_MINOR) * 100, 1),
    max_abs    = max(ad),
    mean_pct   = round(mean(pd), 4),
    median_pct = round(median(pd), 4)
  )
}

# Filter helper shared by run_exp() and run_imp()
subset_df <- function(df, bad_ids,
                      excl_arc, excl_bool, only_arc, only_bool,
                      excl_real, incl_test) {
  id <- paste(df$test, df$gate_name, sep = "/")
  d  <- df[!id %in% bad_ids, ]
  if (excl_arc)  d <- d[!d$is_arcsinh,    ]
  if (excl_bool) d <- d[!d$is_boolean,    ]
  if (only_arc)  d <- d[ d$is_arcsinh,    ]
  if (only_bool) d <- d[ d$is_boolean,    ]
  if (excl_real) d <- d[!d$is_real_world, ]
  if (!is.null(incl_test)) d <- d[d$test %in% incl_test, ]
  d
}

run_exp <- function(df, label, bad_ids = character(0),
                    excl_arc = FALSE, excl_bool = FALSE,
                    only_arc = FALSE, only_bool = FALSE,
                    excl_real = FALSE, incl_test = NULL) {
  d <- subset_df(df[df$export_valid, ], bad_ids,
                 excl_arc, excl_bool, only_arc, only_bool,
                 excl_real, incl_test)
  calc_stats(d$r_count, d$residual_fj10, label,
             paste(d$test, d$gate_name, sep = "/"))
}

run_imp <- function(df, label, bad_ids = character(0),
                    excl_arc = FALSE, excl_bool = FALSE,
                    only_arc = FALSE, only_bool = FALSE,
                    excl_real = FALSE, incl_test = NULL) {
  d <- subset_df(df[df$import_valid, ], bad_ids,
                 excl_arc, excl_bool, only_arc, only_bool,
                 excl_real, incl_test)
  calc_stats(d$fl11_remake, d$residual_fj11r, label,
             paste(d$test, d$gate_name, sep = "/"))
}

# =============================================================================
# 5. PRINT / FORMAT HELPERS
# =============================================================================

print_s <- function(s, tag = "") {
  if (is.null(s) || s$n == 0L) {
    cat(sprintf("  [%-32s] No valid data\n", tag))
    return(invisible(NULL))
  }
  cat(sprintf("\n  [%-32s] %s  (n = %d)\n", tag, s$label, s$n))
  cat(sprintf("    Exact                  : %3d / %d  (%5.1f%%)\n",
              s$n_exact,  s$n, s$pct_exact))
  cat(sprintf("    Within 0 < d ≤ %.1f%%  : %3d / %d  (%5.1f%%)\n",
              THRESH_MINOR, s$n_within, s$n, s$pct_within))
  cat(sprintf("    Max  |diff|            : %.2f cells\n", s$max_abs))
  cat(sprintf("    Mean   |%%diff|        : %.4f%%\n", s$mean_pct))
  cat(sprintf("    Median |%%diff|        : %.4f%%\n", s$median_pct))
}

chk <- function(val, label) {
  if (is.null(val) || length(val) == 0 || is.na(val) || !is.finite(val)) {
    cat(sprintf("  %-63s — (no data)\n", label)); return(invisible())
  }
  pass <- val <= THRESH_PASS
  cat(sprintf("  %-63s %s  (%.4f%% vs ≤ %.2f%%)\n",
              label, if (pass) "✓ PASS" else "✗ FAIL", val, THRESH_PASS))
}

fmt <- function(s) {
  if (is.null(s) || s$n == 0L) return(rep("—", 5))
  c(
    as.character(s$n),
    sprintf("%d (%.0f%%)", s$n_exact, s$pct_exact),
    sprintf("%d (%.0f%%)", s$n_within, s$pct_within),
    sprintf("%.2f cells", s$max_abs),
    sprintf("%.4f%%", s$mean_pct)
  )
}

# =============================================================================
# 5b. MARKDOWN TABLE EXPORT
# =============================================================================

# ── Markdown table export ────────────────────────────────────────────────────

# Normalise a count cell to a display string.
# Recognises the sentinel values used in the spreadsheet and maps them to
# canonical markdown forms.  Purely numeric cells are returned as-is.
fmt_count <- function(x) {
  if (is.null(x) || length(x) == 0L) return("—")
  x <- trimws(as.character(x))
  if (length(x) == 0L || is.na(x) || x %in% c("", "NA", "Na", "na", "N/A", "n/a", "N/a",
               "Not applicable", "Problem importing marker names")) return("N/A")
  if (x %in% c("Not imported", "NI")) return("NI")
  if (x %in% c("Not implemented", "Nim")) return("Nim")
  if (x %in% c("-", "—")) return("—")
  # Test 14 marker-name annotation
  if (x == "[a]") return("[a]")
  if (grepl("^\\s*\\[a\\]\\s*$", x)) return("[a]")
  x
}

# Compute Δ_FJ11r = N_re - N_FJ11r.  If either input is a sentinel that makes
# the difference undefined, return that sentinel.
fmt_delta_fj11r <- function(n_re, n_fj11r) {
  r <- fmt_count(n_re)
  f <- fmt_count(n_fj11r)
  for (s in c("NI", "Nim", "N/A", "—")) if (r == s || f == s) return(s)
  r_num <- suppressWarnings(as.numeric(r))
  f_num <- suppressWarnings(as.numeric(f))
  if (is.na(r_num) || is.na(f_num)) return("—")
  as.character(r_num - f_num)
}

# Convert spreadsheet gate_type to the curated markdown label.
gate_type_md <- function(gt) {
  gt <- trimws(as.character(gt))
  case_when(
    grepl("rect1D|1D rect|range", gt, ignore.case = TRUE) ~ "Range (1D)",
    grepl("rect2D|2D rect", gt, ignore.case = TRUE)      ~ "Rect (2D)",
    grepl("^poly$|polygon", gt, ignore.case = TRUE)       ~ "Poly",
    grepl("ellipse|ellipsoid", gt, ignore.case = TRUE)    ~ "Ellipse",
    grepl("bool:.*AND|^AND$", gt, ignore.case = TRUE)     ~ "AND",
    grepl("bool:.*OR|^OR$", gt, ignore.case = TRUE)       ~ "OR",
    grepl("bool:.*NOT|^NOT$", gt, ignore.case = TRUE)    ~ "NOT",
    grepl("root", gt, ignore.case = TRUE)                 ~ "Root",
    grepl("^Rectangle$", gt)                              ~ "Rect (2D)",
    grepl("^Polygon$", gt)                                ~ "Poly",
    TRUE                                                   ~ gt
  )
}

# Prettify channel/condition strings for Test 14 (and fall-back for others).
fmt_channels <- function(x) {
  x <- trimws(as.character(x))
  x <- ifelse(is.na(x) | x == "" | x == "NA", "—", x)
  # Title-case each token, but keep well-known channel abbreviations uppercase
  x <- vapply(x, function(s) tools::toTitleCase(tolower(s)), character(1), USE.NAMES = FALSE)
  x <- gsub("Fsc", "FSC", x, fixed = TRUE)
  x <- gsub("Ssc", "SSC", x, fixed = TRUE)
  x <- gsub("Fcs", "FCS", x, fixed = TRUE)
  x <- gsub("Cd3", "CD3", x, fixed = TRUE)
  x <- gsub("Cd4", "CD4", x, fixed = TRUE)
  x <- gsub("Cd8", "CD8", x, fixed = TRUE)
  x <- gsub("Cd19", "CD19", x, fixed = TRUE)
  x <- gsub("Nk1\\.1|Nk1_1|Nk1-1", "NK1.1", x)
  x <- gsub("Tcrb|TCRb", "TCRβ", x)
  x <- gsub("TRCgd|Tcrgd|TCRgd", "TCRγδ", x)
  x <- gsub("\\s+-\\s+", " vs ", x)
  x <- gsub("\\s+vs\\s+", " vs ", x, ignore.case = TRUE)
  x
}

write_markdown_table <- function(df, path = "manuscript/comparison.table.md") {
  # Preserve numeric residuals before converting counts to character
  df <- df %>%
    mutate(
      res_fj10  = round(residual_fj10),
      res_fj11  = round(residual_fj11),
      res_fj11r = round(residual_fj11r)
    ) %>%
    mutate(across(where(is.character), ~trimws(as.character(.x)))) %>%
    mutate(
      gate_type_md = gate_type_md(gate_type),
      channels_md  = fmt_channels(channels),
      condition_md = if ("condition" %in% names(.)) fmt_channels(condition) else channels_md
    )

  fmt_res <- function(x) {
    if (is.null(x) || length(x) == 0L || is.na(x)) return("—")
    as.character(as.integer(round(as.numeric(x))))
  }

  make_row_01_09 <- function(r) {
    r <- as.list(r)
    test_num <- sprintf("%02d", as.integer(sub("test0?", "", r$test)))
    paste0("| ", test_num,
           " | ", r$gate_name,
           " | ", r$gate_type_md,
           " | ", r$channels_md,
           " | ", fmt_count(r$r_count),
           " | ", fmt_count(r$fj10_count),
           " | ", fmt_count(r$fj11_count),
           " | ", fmt_count(r$fl11_remake),
           " | ", fmt_count(r$read_fj11),
           " | ", fmt_res(r$res_fj10),
           " | ", fmt_res(r$res_fj11),
           " | ", fmt_res(r$res_fj11r),
           " |")
  }

  make_row_other <- function(r) {
    r <- as.list(r)
    cond <- if ("condition" %in% names(r) && !is.na(r$condition) && r$condition != "")
      r$condition_md else r$channels_md
    paste0("| ", r$gate_name,
           " | ", r$hierarchy,
           " | ", r$gate_type_md,
           " | ", cond,
           " | ", fmt_count(r$r_count),
           " | ", fmt_count(r$fj10_count),
           " | ", fmt_count(r$fj11_count),
           " | ", fmt_count(r$fl11_remake),
           " | ", fmt_count(r$read_fj11),
           " | ", fmt_res(r$res_fj10),
           " | ", fmt_res(r$res_fj11),
           " | ", fmt_res(r$res_fj11r),
           " |")
  }

  make_row_t14 <- function(r) {
    r <- as.list(r)
    paste0("| ", r$gate_name,
           " | ", r$gate_type_md,
           " | ", r$channels_md,
           " | ", fmt_count(r$r_count),
           " | ", fmt_count(r$fj10_count),
           " | ", fmt_count(r$fj11_count),
           " | ", fmt_count(r$fl11_remake),
           " | ", fmt_count(r$read_fj11),
           " | ", fmt_res(r$res_fj10),
           " | ", fmt_res(r$res_fj11),
           " | ", fmt_res(r$res_fj11r),
           " |")
  }

  md <- c(
    "# Appendix — Gate Event-Count Validation: CyFj11 Export Round-Trip Tests",
    "",
    "**Column definitions.**",
    paste0("**N_R**: reference count from R (flowCore/openCyto); ",
           "**N_FJ10**: count in FlowJo v10 after workspace import; ",
           "**N_FJ11**: count in FlowJo v11 after workspace import; ",
           "**N_FJ11r**: count after gate remade in FlowJo v11; ",
           "**N_re**: count from re-reading the FlowJo v11-exported workspace; ",
           "**res_FJ10** = residual N_R − N_FJ10 after removing error inherited from the parent gate; ",
           "**res_FJ11** = residual N_R − N_FJ11 after removing error inherited from the parent gate; ",
           "**res_FJ11r** = residual N_re − N_FJ11r after removing error inherited from the parent gate. ",
           "**NI** = not imported (Boolean gates unsupported by this pipeline); ",
           "**Nim** = not implemented; **N/A** = not evaluated for this test; ",
           "**—** = difference not computable."),
    "",
    "**Gate-type abbreviations.** Range (1D): 1-D range gate; Rect (2D): 2-D rectangle gate; Poly: polygon; Ellipse: ellipsoid; AND / OR / NOT: Boolean gate.",
    "",
    "---",
    ""
  )

  # Tests 01–09
  d01_09 <- df %>% filter(grepl("^test0[1-9]$", test, ignore.case = TRUE))
  if (nrow(d01_09)) {
    rows <- apply(d01_09, 1, function(r) make_row_01_09(r))
    md <- c(md,
            "## Tests 01–09: Single Gate-Type Validation",
            "",
            "| Test | Gate | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |",
            "|:---:|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|",
            rows,
            "",
            "† Test 05: round-trip count drift is expected for ellipsoid gates because different mathematical representations of the ellipse accumulate rounding and precision effects.",
            "")
  }

  # Test 10
  d10 <- df %>% filter(grepl("^test10$", test, ignore.case = TRUE))
  if (nrow(d10)) {
    rows <- apply(d10, 1, function(r) make_row_other(r))
    md <- c(md,
            "## Test 10: Boolean AND / OR / NOT (Linear Axes)",
            "",
            "| Gate | Path | Gate type | Condition | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |",
            "|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|",
            rows,
            "")
  }

  # Test 11
  d11 <- df %>% filter(grepl("^test11$", test, ignore.case = TRUE))
  if (nrow(d11)) {
    rows <- apply(d11, 1, function(r) make_row_other(r))
    md <- c(md,
            "## Test 11: Mixed Biexponential + Arcsinh, Hierarchy + Boolean",
            "",
            "| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |",
            "|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|",
            rows,
            "")
  }

  # Test 12
  d12 <- df %>% filter(grepl("^test12$", test, ignore.case = TRUE))
  if (nrow(d12)) {
    rows <- apply(d12, 1, function(r) make_row_other(r))
    md <- c(md,
            "## Test 12: Biexponential + Log, Ellipse + Full Boolean Set",
            "",
            "> **Note.** FlowJo v11 does not support a combined `NOT(pop1, pop2)` Boolean gate.",
            "",
            "| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |",
            "|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|",
            rows,
            "")
  }

  # Test 13
  d13 <- df %>% filter(grepl("^test13$", test, ignore.case = TRUE))
  if (nrow(d13)) {
    rows <- apply(d13, 1, function(r) make_row_other(r))
    md <- c(md,
            "## Test 13: Arcsinh × 3 Channels, 3-Level Hierarchy + Boolean",
            "",
            "| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |",
            "|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|",
            rows,
            "")
  }

  # Test 14
  d14 <- df %>% filter(grepl("^test14$", test, ignore.case = TRUE))
  if (nrow(d14)) {
    rows <- apply(d14, 1, function(r) make_row_t14(r))
    md <- c(md,
            "---",
            "",
            "## Test 14: Real-World Validation — FlowSOM Example Data",
            "",
            "**Source.** FlowSOM R package; file `68983.fcs` + `gating.wsp` (mouse bone marrow immunophenotyping).  ",
            "**Pipeline.** `CytoML::flowjo_to_gatingset()` → `export_flowjo10_workspace()` (CyFj11 v10 → CytoML v10 import).  ",
            "**Acquisition settings.** Compensation matrix applied; fluorescence channels biexponential; scatter channels linear.",
            "",
            "| Gate | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |",
            "|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|",
            rows,
            "",
            "**[a]** FlowJo v11 failed to parse the marker name \"NK1_1+\" (underscore–plus character combination). All populations gated downstream of NK1_1+ and NK1_1− consequently displayed as NA in FlowJo v11. FlowJo v10 reproduced the NK1_1+ count correctly (Δ_FJ10 = 1 event). This failure reflects a FlowJo v11 marker-name parsing idiosyncrasy and does not indicate an error in the CyFj11 export.",
            "",
            "All other discrepancies can be explained by numerical conversion differences.")
  }

  writeLines(md, path)
  invisible(path)
}

# =============================================================================
# 6. MAIN
# =============================================================================

main <- function(path    = DEFAULT_PATH,
                 sheet   = DEFAULT_SHEET,
                 out_csv = "flowjo_export_tests/cyfj11_validation_summary.csv",
                 out_det = "flowjo_export_tests/cyfj11_validation_detail.csv",
                 out_txt = "flowjo_export_tests/cyfj11_validation_report.txt",
                 out_md  = "manuscript/comparison.table.generated.md",
                 debug   = FALSE) {
  
  if (!is.null(out_txt)) {
    con <- file(out_txt, "wt"); sink(con, split = TRUE)
    on.exit({ sink(); close(con) }, add = TRUE)
  }
  
  cat(strrep("═", 70), "\n  CyFj11 Validation Statistics\n")
  cat(sprintf("  %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
  cat(sprintf("  Input : %s  (sheet: %s)\n", path, sheet))
  cat(strrep("═", 70), "\n")
  
  # ── 1. Read ─────────────────────────────────────────────────────────────────
  df_raw <- read_xlsx_table(path, sheet, debug = debug)
  df     <- clean_and_classify(df_raw)
  
  tests <- sort(unique(df$test))
  cat(sprintf("\nFinal dataset: %d rows across %d tests (%s)\n",
              nrow(df), length(tests), paste(tests, collapse = ", ")))
  cat(sprintf("  export_valid = %d  |  import_valid = %d\n",
              sum(df$export_valid), sum(df$import_valid)))
  cat(sprintf("  arcsinh = %d  |  boolean = %d  |  real-world = %d\n",
              sum(df$is_arcsinh), sum(df$is_boolean), sum(df$is_real_world)))
  
  # ── 2. Quality checks ───────────────────────────────────────────────────────
  bad <- check_quality(df)
  df  <- df %>%
    mutate(import_valid = import_valid &
             !paste(test, gate_name, sep = "/") %in% bad)
  
  # ── 3. Export validation ────────────────────────────────────────────────────
  hdr("A. EXPORT  r_count  vs  fj10_count")
  cat("   export_flowjo10_workspace() → opened in FlowJo v10\n")
  
  sub_hdr("A1  All gates, all tests")
  eAll  <- run_exp(df, "All gates, all tests", bad)
  
  sub_hdr("A2  Synthetic (01–13), all gates")
  eSyn  <- run_exp(df, "Synthetic all", bad, excl_real = TRUE)
  
  sub_hdr("A3  Synthetic core — excl. arcsinh + boolean  ★ PRIMARY")
  eCore <- run_exp(df, "Synthetic core", bad,
                   excl_arc = TRUE, excl_bool = TRUE, excl_real = TRUE)
  
  sub_hdr("A4  Arcsinh gates only (synthetic)")
  eArc  <- run_exp(df, "Arcsinh (synthetic)", bad,
                   only_arc = TRUE, excl_real = TRUE)
  
  sub_hdr("A5  Boolean gates only (synthetic)")
  eBool <- run_exp(df, "Boolean (synthetic)", bad,
                   only_bool = TRUE, excl_real = TRUE)
  
  sub_hdr("A6  Real-world test14")
  eT14  <- run_exp(df, "Real-world test14", bad, incl_test = "test14")
  
  EXP_TAGS <- c("All gates, all tests"  = "Exp-All",
                "Synthetic all"         = "Exp-Syn-All",
                "Synthetic core"        = "Exp-Core ★",
                "Arcsinh (synthetic)"   = "Exp-Arcsinh",
                "Boolean (synthetic)"   = "Exp-Boolean",
                "Real-world test14"     = "Exp-Test14")
  for (s in list(eAll, eSyn, eCore, eArc, eBool, eT14))
    print_s(s, EXP_TAGS[s$label])
  
  # ── 4. Import validation ─────────────────────────────────────────────────────
  hdr("B. IMPORT  fl11_remake  vs  read_fj11")
  cat("   fj11_to_gatingset() reads .flowjo → R\n")
  cat("   Ground truth = count displayed in FlowJo v11 (fl11_remake)\n")
  
  sub_hdr("B1  All gates, all tests")
  iAll  <- run_imp(df, "All gates, all tests", bad)
  
  sub_hdr("B2  Synthetic (01–13), all gates")
  iSyn  <- run_imp(df, "Synthetic all", bad, excl_real = TRUE)
  
  sub_hdr("B3  Synthetic core — excl. arcsinh + boolean  ★ PRIMARY")
  iCore <- run_imp(df, "Synthetic core", bad,
                   excl_arc = TRUE, excl_bool = TRUE, excl_real = TRUE)
  
  sub_hdr("B4  Arcsinh gates only (synthetic)")
  iArc  <- run_imp(df, "Arcsinh (synthetic)", bad,
                   only_arc = TRUE, excl_real = TRUE)
  
  sub_hdr("B5  Boolean gates only (synthetic)")
  iBool <- run_imp(df, "Boolean (synthetic)", bad,
                   only_bool = TRUE, excl_real = TRUE)
  
  sub_hdr("B6  Real-world test14")
  iT14  <- run_imp(df, "Real-world test14", bad, incl_test = "test14")
  
  IMP_TAGS <- c("All gates, all tests"  = "Imp-All",
                "Synthetic all"         = "Imp-Syn-All",
                "Synthetic core"        = "Imp-Core ★",
                "Arcsinh (synthetic)"   = "Imp-Arcsinh",
                "Boolean (synthetic)"   = "Imp-Boolean",
                "Real-world test14"     = "Imp-Test14")
  for (s in list(iAll, iSyn, iCore, iArc, iBool, iT14))
    print_s(s, IMP_TAGS[s$label])
  
  # ── 5. Acceptance criteria ───────────────────────────────────────────────────
  hdr("C. ACCEPTANCE  (threshold: mean |%%diff| ≤ 0.5%%)")
  
  cat("\n  Export:\n")
  chk(eCore$mean_pct,  "  Export core    : mean |%diff|")
  chk(eArc$mean_pct,   "  Export arcsinh : mean |%diff|")
  chk(eBool$mean_pct,  "  Export boolean : mean |%diff|")
  chk(eT14$mean_pct,   "  Export test14  : mean |%diff|")

  cat("\n  Import:\n")
  chk(iCore$mean_pct,  "  Import core    : mean |%diff|")
  chk(iArc$mean_pct,   "  Import arcsinh : mean |%diff|")
  chk(iBool$mean_pct,  "  Import boolean : mean |%diff|")
  chk(iT14$mean_pct,   "  Import test14  : mean |%diff|")
  
  # ── 6. Manuscript Table 2 ────────────────────────────────────────────────────
  hdr("D. MANUSCRIPT TABLE 2  (copy-paste ready)")
  cat("  ★ = primary comparison; arcsinh and boolean excluded — see text\n\n")
  
  tbl <- as.data.frame(rbind(
    c("Export FJ10 | synthetic, all gates",                    fmt(eSyn)),
    c("Export FJ10 | synthetic core (excl. arcsinh+bool) ★",  fmt(eCore)),
    c("Export FJ10 | arcsinh gates only",                      fmt(eArc)),
    c("Export FJ10 | boolean gates only",                      fmt(eBool)),
    c("Export FJ10 | real-world test14",                       fmt(eT14)),
    c(strrep("─", 46), rep("", 5)),
    c("Import R    | synthetic, all gates",                    fmt(iSyn)),
    c("Import R    | synthetic core (excl. arcsinh+bool) ★",  fmt(iCore)),
    c("Import R    | arcsinh gates only",                      fmt(iArc)),
    c("Import R    | boolean gates only",                      fmt(iBool)),
    c("Import R    | real-world test14",                       fmt(iT14))
  ), stringsAsFactors = FALSE)

  colnames(tbl) <- c("Comparison", "N",
                     "Exact", "Within ≤0.3%", "Max |diff|",
                     "Mean |%diff|")
  print(tbl, row.names = FALSE)
  
  # ── 7. Per-gate detail table ─────────────────────────────────────────────────
  hdr("E. PER-GATE DETAIL")
  
  detail <- df %>%
    mutate(
      # Raw deltas (truth - observed)
      exp_diff  = r_count - fj10_count,
      imp_diff  = fl11_remake - read_fj11,
      fj11r_re_diff = fl11_remake - read_fj11,
      # Residuals after removing parent-inherited error
      exp_res   = residual_fj10,
      imp_res   = residual_fj11r,
      exp_pct   = ifelse(export_valid & r_count > 0,
                         round(abs(exp_res) / r_count * 100, 3), NA_real_),
      imp_pct   = ifelse(import_valid & fl11_remake > 0,
                         round(abs(imp_res) / fl11_remake * 100, 3), NA_real_),
      category  = case_when(
        is_arcsinh    ~ "arcsinh",
        is_boolean    ~ "boolean",
        is_real_world ~ "real-world",
        TRUE          ~ "core")
    ) %>%
    select(test, gate_name, gate_type, category,
           r_count, fj10_count, exp_diff, exp_res, exp_pct,
           fl11_remake, read_fj11, imp_diff, imp_res, imp_pct,
           fj11r_re_diff) %>%
    arrange(test, gate_name)
  
  print(as.data.frame(detail), row.names = FALSE)
  
  # ── 8. Write outputs ──────────────────────────────────────────────────────────
  hdr("F. OUTPUT FILES")
  write_csv(tbl,    out_csv)
  write_csv(detail, out_det)
  if (!is.null(out_md)) {
    write_markdown_table(df, out_md)
    cat(sprintf("  %s\n", out_md))
  }
  cat(sprintf("  %s\n  %s\n", out_csv, out_det))
  if (!is.null(out_txt)) cat(sprintf("  %s\n", out_txt))

  invisible(list(
    data   = df, bad_ids = bad,
    eAll   = eAll,  eSyn   = eSyn,  eCore  = eCore,
    eArc   = eArc,  eBool  = eBool, eT14   = eT14,
    iAll   = iAll,  iSyn   = iSyn,  iCore  = iCore,
    iArc   = iArc,  iBool  = iBool, iT14   = iT14,
    summary = tbl, detail = detail
  ))
}

# =============================================================================
# ENTRY POINT
# =============================================================================

if (!interactive()) {
  args  <- commandArgs(trailingOnly = TRUE)
  path  <- if (length(args) >= 1) args[1] else DEFAULT_PATH
  sheet <- if (length(args) >= 2) {
    s <- suppressWarnings(as.integer(args[2]))
    if (!is.na(s)) s else args[2]
  } else DEFAULT_SHEET
  main(path, sheet)
}

