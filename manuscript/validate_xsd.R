#!/usr/bin/env Rscript
# validate_xsd.R
#
# Validates exported v10 WSP files against the official Gating-ML 2.0 XSD
# (Spidlen et al. 2012) using xml2::xml_validate().
#
# Strategy: The WSP is a <Workspace> document that contains gate elements
# using Gating-ML namespaces.  The official XSD expects a <gating:Gating-ML>
# root.  This script extracts all gate and transformation elements from each
# WSP, wraps them in a proper <gating:Gating-ML> document, and validates
# against the XSD.
#
# Usage:
#   Rscript manuscript/validate_xsd.R

suppressPackageStartupMessages(library(xml2))

BASE_DIR <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests"
XSD_DIR  <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/inst/Gating-ML 2.0 Full 20130122/XSD"
OUT_CSV  <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/manuscript/xsd_validation.csv"

NS <- c(
  gating     = "http://www.isac-net.org/std/Gating-ML/v2.0/gating",
  transforms = "http://www.isac-net.org/std/Gating-ML/v2.0/transformations",
  dt         = "http://www.isac-net.org/std/Gating-ML/v2.0/datatypes"
)

# ── Build a standalone Gating-ML document from a WSP ─────────────────────

extract_gatingml_xml <- function(wsp_path) {
  doc <- read_xml(wsp_path)

  # Collect gate nodes (all gate types) and transform nodes from the WSP.
  # Gates appear as children of <Gate> elements in the WSP.
  gate_types <- c("RectangleGate", "PolygonGate", "EllipsoidGate",
                  "BooleanGate", "QuadrantGate")
  transform_types <- c("linear", "biex", "fasinh", "logicle", "log",
                       "fratio", "dg1polynomial")

  gate_xpaths <- paste0(".//gating:", gate_types, collapse = " | ")
  tr_xpaths   <- paste0(".//transforms:", transform_types, collapse = " | ")

  gate_nodes  <- xml_find_all(doc, gate_xpaths, NS)
  tr_nodes    <- xml_find_all(doc, tr_xpaths, NS)

  # Deduplicate by gating:id (same gate may appear in GroupNode & SampleNode)
  gate_ids <- xml_attr(gate_nodes, "id", NS)
  gate_nodes <- gate_nodes[!duplicated(gate_ids)]

  tr_ids <- xml_attr(tr_nodes, "id", NS)
  tr_nodes <- tr_nodes[!duplicated(tr_ids)]

  # Serialise each node to a character string
  node_strings <- vapply(c(tr_nodes, gate_nodes), as.character, character(1))

  # Build a minimal Gating-ML document
  header <- paste0(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<gating:Gating-ML',
    ' xmlns:gating="http://www.isac-net.org/std/Gating-ML/v2.0/gating"',
    ' xmlns:transforms="http://www.isac-net.org/std/Gating-ML/v2.0/transformations"',
    ' xmlns:data-type="http://www.isac-net.org/std/Gating-ML/v2.0/datatypes">'
  )
  footer <- '</gating:Gating-ML>'

  paste0(c(header, node_strings, footer), collapse = "\n")
}

# ── Run XSD validation ────────────────────────────────────────────────────

xsd_path <- file.path(XSD_DIR, "Gating-ML.v2.0.xsd")
schema   <- read_xml(xsd_path)

test_dirs <- sort(list.dirs(BASE_DIR, recursive = FALSE))
test_dirs <- test_dirs[grepl("test\\d+$", test_dirs)]

results <- lapply(test_dirs, function(tdir) {
  test_name <- basename(tdir)
  wsp_path  <- file.path(tdir, "export.wsp")

  if (!file.exists(wsp_path)) {
    return(data.frame(test = test_name, valid = NA, errors = "no WSP file",
                      gate_count = 0L, transform_count = 0L,
                      stringsAsFactors = FALSE))
  }

  # Count elements in original WSP
  doc_orig <- read_xml(wsp_path)
  gate_count <- length(xml_find_all(doc_orig,
    ".//gating:RectangleGate | .//gating:PolygonGate | .//gating:EllipsoidGate | .//gating:BooleanGate | .//gating:QuadrantGate",
    NS))
  tr_count <- length(xml_find_all(doc_orig,
    ".//transforms:linear | .//transforms:biex | .//transforms:fasinh | .//transforms:logicle | .//transforms:log",
    NS))

  gml_xml <- tryCatch(extract_gatingml_xml(wsp_path), error = function(e) NULL)

  if (is.null(gml_xml)) {
    return(data.frame(test = test_name, valid = FALSE,
                      errors = "failed to extract Gating-ML",
                      gate_count = gate_count, transform_count = tr_count,
                      stringsAsFactors = FALSE))
  }

  gml_doc <- tryCatch(read_xml(gml_xml), error = function(e) {
    message("  Parse error: ", conditionMessage(e))
    NULL
  })

  if (is.null(gml_doc)) {
    return(data.frame(test = test_name, valid = FALSE,
                      errors = "XML parse error",
                      gate_count = gate_count, transform_count = tr_count,
                      stringsAsFactors = FALSE))
  }

  result <- xml_validate(gml_doc, schema)
  errors_str <- if (isTRUE(result)) "" else
    paste(attr(result, "errors"), collapse = "; ")

  cat(sprintf("%-10s %s  (gates: %d, transforms: %d)\n",
              test_name,
              ifelse(isTRUE(result), "PASS", "FAIL"),
              gate_count, tr_count))
  if (!isTRUE(result)) {
    for (e in attr(result, "errors")) cat("  ERROR:", e, "\n")
  }

  data.frame(test = test_name, valid = isTRUE(result), errors = errors_str,
             gate_count = gate_count, transform_count = tr_count,
             stringsAsFactors = FALSE)
})

df <- do.call(rbind, results)

# Summary
n_tested  <- sum(!is.na(df$valid))
n_pass    <- sum(df$valid, na.rm = TRUE)
n_fail    <- sum(!df$valid, na.rm = TRUE)

cat("\n")
cat(strrep("=", 60), "\n")
cat("GATING-ML 2.0 XSD VALIDATION SUMMARY\n")
cat(strrep("=", 60), "\n")
cat(sprintf("  Tested: %d   Pass: %d   Fail: %d\n", n_tested, n_pass, n_fail))

if (n_fail > 0) {
  cat("\nFailing tests:\n")
  fails <- df[!df$valid & !is.na(df$valid), , drop = FALSE]
  for (i in seq_len(nrow(fails))) {
    cat(sprintf("  %s: %s\n", fails$test[i], fails$errors[i]))
  }
}

write.csv(df, OUT_CSV, row.names = FALSE)
cat("\nResults written to:", OUT_CSV, "\n")
