#!/usr/bin/env Rscript
# validate_gatingml_conformance.R
#
# Checks that gate and transformation elements in exported v10 WSP files
# conform to the Gating-ML 2.0 specification (Spidlen et al., Cytometry A,
# 2012, doi:10.1002/cyto.a.22156).
#
# Because no XSD file is available locally and outbound HTTP is blocked, this
# script implements a structural conformance check based on the published
# Gating-ML 2.0 specification requirements.  The checks correspond to the
# structural rules defined in the XSD and specification document:
#
#   1. Namespace URIs match the Gating-ML 2.0 standard.
#   2. Gate elements have the required child elements and attributes.
#   3. Transformation elements have the required parameter attributes.
#   4. Dimension references are non-empty and reference a named FCS parameter.
#
# Gate types covered: RectangleGate, PolygonGate, EllipsoidGate, BooleanGate.
# Transformation types covered: linear, biex, fasinh, logicle, log.
#
# Usage:
#   Rscript manuscript/validate_gatingml_conformance.R
#
# Output:
#   Printed per-file conformance report.
#   CSV written to manuscript/gatingml_conformance.csv.

suppressPackageStartupMessages(library(xml2))

BASE_DIR <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests"
OUT_CSV  <- "/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/manuscript/gatingml_conformance.csv"

# ── Expected namespace URIs (Gating-ML 2.0) ──────────────────────────────
EXPECTED_NS <- list(
  gating     = "http://www.isac-net.org/std/Gating-ML/v2.0/gating",
  transforms = "http://www.isac-net.org/std/Gating-ML/v2.0/transformations",
  `data-type`= "http://www.isac-net.org/std/Gating-ML/v2.0/datatypes"
)

NS <- c(
  gating     = EXPECTED_NS$gating,
  transforms = EXPECTED_NS$transforms,
  dt         = EXPECTED_NS$`data-type`
)

# ── Check helpers ─────────────────────────────────────────────────────────

fail <- function(msg) list(pass = FALSE, msg = msg)
pass <- function(msg = "ok") list(pass = TRUE,  msg = msg)

check_all <- function(checks) {
  fails <- Filter(function(x) !x$pass, checks)
  if (length(fails) == 0) pass() else
    fail(paste(sapply(fails, `[[`, "msg"), collapse = "; "))
}

# ── Namespace conformance ─────────────────────────────────────────────────

check_namespaces <- function(doc) {
  ns_map <- xml_ns(doc)
  results <- lapply(names(EXPECTED_NS), function(prefix) {
    # xml_ns returns a named vector: names are d1, d2 … or the actual prefix
    uri <- EXPECTED_NS[[prefix]]
    if (uri %in% ns_map) pass(sprintf("ns:%s present", prefix))
    else fail(sprintf("namespace URI '%s' (%s) not declared", uri, prefix))
  })
  check_all(results)
}

# ── Gate element checks ───────────────────────────────────────────────────

#' Check a single RectangleGate node.
check_rectangle <- function(gate_node) {
  dims <- xml_find_all(gate_node, "gating:dimension", ns = NS)
  checks <- list(
    if (length(dims) >= 1) pass() else fail("RectangleGate: no gating:dimension children"),
    check_all(lapply(dims, function(d) {
      has_min <- !is.na(xml_attr(d, "gating:min", ns = NS))
      has_max <- !is.na(xml_attr(d, "gating:max", ns = NS))
      fcs_dim <- xml_find_first(d, "dt:fcs-dimension", ns = NS)
      has_fcs <- !is.na(fcs_dim)
      ch_name <- if (has_fcs) xml_attr(fcs_dim, "name") else NA_character_
      has_name <- !is.na(ch_name) && nchar(ch_name) > 0
      check_all(list(
        if (has_min || has_max) pass() else fail("dimension: neither gating:min nor gating:max"),
        if (has_fcs)  pass() else fail("dimension: missing dt:fcs-dimension"),
        if (has_name) pass() else fail("fcs-dimension: missing or empty name attribute")
      ))
    }))
  )
  check_all(checks)
}

#' Check a single PolygonGate node.
check_polygon <- function(gate_node) {
  dims  <- xml_find_all(gate_node, "gating:dimension", ns = NS)
  verts <- xml_find_all(gate_node, "gating:vertex",    ns = NS)
  checks <- list(
    if (length(dims) == 2) pass() else
      fail(sprintf("PolygonGate: expected 2 dimensions, found %d", length(dims))),
    if (length(verts) >= 3) pass() else
      fail(sprintf("PolygonGate: need ≥3 vertices, found %d", length(verts))),
    check_all(lapply(verts, function(v) {
      coords <- xml_find_all(v, "gating:coordinate", ns = NS)
      vals   <- sapply(coords, function(c) xml_attr(c, "dt:value", ns = NS))
      checks_v <- list(
        if (length(coords) == 2) pass() else
          fail(sprintf("vertex: expected 2 coordinates, found %d", length(coords))),
        if (all(!is.na(vals))) pass() else fail("vertex: coordinate missing dt:value")
      )
      check_all(checks_v)
    })),
    # Dimensions must reference named FCS parameters
    check_all(lapply(dims, function(d) {
      fcs <- xml_find_first(d, "dt:fcs-dimension", ns = NS)
      ch  <- if (!is.na(fcs)) xml_attr(fcs, "name") else NA
      if (!is.na(ch) && nchar(ch) > 0) pass()
      else fail("polygon dimension: missing fcs-dimension name")
    }))
  )
  check_all(checks)
}

#' Check a single EllipsoidGate node.
check_ellipsoid <- function(gate_node) {
  dims     <- xml_find_all(gate_node, "gating:dimension", ns = NS)
  foci     <- xml_find_first(gate_node, "gating:foci",   ns = NS)
  distance <- xml_attr(gate_node, "gating:distance", ns = NS)
  checks <- list(
    if (length(dims) == 2) pass() else
      fail(sprintf("EllipsoidGate: expected 2 dimensions, found %d", length(dims))),
    if (!is.na(foci)) pass() else fail("EllipsoidGate: missing gating:foci element"),
    if (!is.na(distance) && suppressWarnings(!is.na(as.numeric(distance))))
      pass() else fail("EllipsoidGate: missing or non-numeric gating:distance attribute"),
    # foci must contain at least one vertex
    if (!is.na(foci)) {
      foci_verts <- xml_find_all(foci, "gating:vertex", ns = NS)
      if (length(foci_verts) >= 1) pass()
      else fail("EllipsoidGate: foci has no vertices")
    } else pass()
  )
  check_all(checks)
}

#' Check a single BooleanGate node.
check_boolean <- function(gate_node) {
  and_node <- xml_find_first(gate_node, "gating:and", ns = NS)
  or_node  <- xml_find_first(gate_node, "gating:or",  ns = NS)
  not_node <- xml_find_first(gate_node, "gating:not", ns = NS)

  ops <- sum(!is.na(c(and_node, or_node, not_node)))
  if (ops != 1)
    return(fail(sprintf("BooleanGate: expected exactly one of and/or/not, found %d", ops)))

  op_node <- Filter(Negate(is.na), list(and_node, or_node, not_node))[[1]]
  # Gate references may use gating:gate-reference or gating:gateReference
  refs <- c(
    xml_find_all(op_node, "gating:gate-reference",  ns = NS),
    xml_find_all(op_node, "gating:gateReference",   ns = NS)
  )
  if (length(refs) == 0)
    return(fail("BooleanGate: operand has no gate references"))

  check_all(lapply(refs, function(r) {
    ref_val <- coalesce_attr(r, c("gating:ref", "ref"), ns = NS)
    if (!is.na(ref_val) && nchar(ref_val) > 0) pass()
    else fail("BooleanGate: gate reference missing ref attribute")
  }))
}

#' Helper: try attribute names in order, return first non-NA value.
coalesce_attr <- function(node, attrs, ns = NULL) {
  for (a in attrs) {
    v <- tryCatch(xml_attr(node, a, ns = ns), error = function(e) NA)
    if (!is.na(v)) return(v)
  }
  NA_character_
}

# ── Transformation element checks ─────────────────────────────────────────

#' Check that a transformation node has the required parameter attributes
#' and a valid data-type:parameter child.
check_transform <- function(trans_node) {
  local_name <- xml_name(trans_node)  # e.g. "linear", "biex", "fasinh" …

  required_attrs <- switch(local_name,
    linear  = character(0),  # minRange/maxRange are on the element (checked separately)
    biex    = c("transforms:length", "transforms:maxRange",
                "transforms:neg", "transforms:width", "transforms:pos"),
    fasinh  = c("transforms:T", "transforms:M", "transforms:A",
                "transforms:length", "transforms:maxRange"),
    logicle = c("transforms:T", "transforms:W", "transforms:M", "transforms:A"),
    log     = c("transforms:decades", "transforms:offset"),
    character(0)
  )

  # linear uses transforms:minRange / transforms:maxRange (no ns prefix in some WSPs)
  if (local_name == "linear") {
    has_min <- !is.na(xml_attr(trans_node, "transforms:minRange", ns = NS)) ||
               !is.na(xml_attr(trans_node, "minRange"))
    has_max <- !is.na(xml_attr(trans_node, "transforms:maxRange", ns = NS)) ||
               !is.na(xml_attr(trans_node, "maxRange"))
    required_attrs_check <- list(
      if (has_min) pass() else fail("linear: missing transforms:minRange"),
      if (has_max) pass() else fail("linear: missing transforms:maxRange")
    )
  } else {
    required_attrs_check <- lapply(required_attrs, function(a) {
      v <- xml_attr(trans_node, a, ns = NS)
      if (!is.na(v)) pass() else fail(sprintf("%s: missing %s", local_name, a))
    })
  }

  # Must have a data-type:parameter child with a non-empty name attribute
  param <- xml_find_first(trans_node, "dt:parameter", ns = NS)
  param_check <- if (!is.na(param)) {
    nm <- xml_attr(param, "name")
    if (!is.na(nm) && nchar(nm) > 0) pass()
    else fail(sprintf("%s: dt:parameter missing name", local_name))
  } else fail(sprintf("%s: missing dt:parameter child", local_name))

  check_all(c(required_attrs_check, list(param_check)))
}

# ── Per-file conformance check ────────────────────────────────────────────

check_wsp <- function(wsp_path) {
  doc  <- tryCatch(read_xml(wsp_path), error = function(e) NULL)
  if (is.null(doc)) return(list(file = basename(dirname(wsp_path)),
                                ns_ok = FALSE, results = NULL,
                                error = "XML parse failed"))

  issues <- list()
  results <- list()

  # 1. Namespace check
  ns_check <- check_namespaces(doc)
  results[["namespace"]] <- ns_check

  # 2. Gate checks — SampleNode level only (avoids counting GroupNode duplicates)
  gate_types <- list(
    RectangleGate = check_rectangle,
    PolygonGate   = check_polygon,
    EllipsoidGate = check_ellipsoid,
    BooleanGate   = check_boolean
  )

  for (gt in names(gate_types)) {
    xpath  <- sprintf(".//SampleNode//gating:%s", gt)
    nodes  <- xml_find_all(doc, xpath, ns = NS)
    if (length(nodes) == 0) next

    checks <- lapply(nodes, gate_types[[gt]])
    fails  <- Filter(function(x) !x$pass, checks)
    if (length(fails) == 0) {
      results[[gt]] <- pass(sprintf("%d element(s) conform", length(nodes)))
    } else {
      results[[gt]] <- fail(sprintf("%d/%d %s fail: %s",
        length(fails), length(nodes), gt,
        paste(unique(sapply(fails, `[[`, "msg")), collapse = " | ")))
    }
  }

  # 3. Transformation checks
  trans_types <- c("linear", "biex", "fasinh", "logicle", "log")
  for (tt in trans_types) {
    xpath <- sprintf(".//transforms:%s", tt)
    nodes <- xml_find_all(doc, xpath, ns = NS)
    if (length(nodes) == 0) next

    checks <- lapply(nodes, check_transform)
    fails  <- Filter(function(x) !x$pass, checks)
    if (length(fails) == 0) {
      results[[paste0("transform:", tt)]] <- pass(sprintf("%d conform", length(nodes)))
    } else {
      results[[paste0("transform:", tt)]] <- fail(sprintf("%d/%d fail: %s",
        length(fails), length(nodes),
        paste(unique(sapply(fails, `[[`, "msg")), collapse = " | ")))
    }
  }

  list(file = basename(dirname(wsp_path)), results = results, error = NULL)
}

# ── Run all tests ─────────────────────────────────────────────────────────

test_dirs <- sprintf("test%02d", 1:13)
wsp_paths <- file.path(BASE_DIR, test_dirs, "export.wsp")

all_results <- vector("list", length(test_dirs))
for (i in seq_along(test_dirs)) {
  wsp <- wsp_paths[i]
  if (!file.exists(wsp)) {
    all_results[[i]] <- list(file = test_dirs[i], results = NULL, error = "file not found")
    next
  }
  all_results[[i]] <- check_wsp(wsp)
  cat(sprintf("Checked %s\n", test_dirs[i]))
}

# ── Summary report ────────────────────────────────────────────────────────

cat("\n", strrep("=", 70), "\n")
cat("GATING-ML 2.0 STRUCTURAL CONFORMANCE REPORT\n")
cat(strrep("=", 70), "\n\n")

# Collect all check categories that appear across any file
all_categories <- unique(unlist(lapply(all_results, function(r) names(r$results))))

# Print per-test, per-category table
cat(sprintf("%-18s", "Test"))
for (cat_name in all_categories) cat(sprintf("  %-22s", cat_name))
cat("\n")
cat(strrep("-", 18 + 24 * length(all_categories)), "\n")

summary_rows <- list()
for (r in all_results) {
  if (!is.null(r$error) && r$error == "file not found") {
    cat(sprintf("%-18s  (skipped)\n", r$file)); next
  }
  cat(sprintf("%-18s", r$file))
  row_pass <- integer(length(all_categories))
  for (j in seq_along(all_categories)) {
    cn <- all_categories[j]
    res <- r$results[[cn]]
    if (is.null(res)) {
      cat(sprintf("  %-22s", "n/a"))
      row_pass[j] <- NA
    } else if (res$pass) {
      cat(sprintf("  %-22s", "PASS"))
      row_pass[j] <- 1L
    } else {
      cat(sprintf("  %-22s", paste0("FAIL: ", substr(res$msg, 1, 15))))
      row_pass[j] <- 0L
    }
  }
  cat("\n")
  summary_rows[[r$file]] <- data.frame(
    test = r$file,
    matrix(row_pass, nrow = 1,
           dimnames = list(NULL, make.names(all_categories))),
    stringsAsFactors = FALSE
  )
}

cat(strrep("-", 18 + 24 * length(all_categories)), "\n")

# Overall totals
tbl <- do.call(rbind, summary_rows)
for (cn in make.names(all_categories)) {
  vals <- tbl[[cn]]
  n_applicable <- sum(!is.na(vals))
  n_pass       <- sum(vals == 1L, na.rm = TRUE)
  cat(sprintf("  %-20s  %d / %d applicable tests pass\n",
              cn, n_pass, n_applicable))
}

# Overall verdict
n_total    <- sum(!is.na(unlist(tbl[, -1])))
n_passing  <- sum(unlist(tbl[, -1]) == 1L, na.rm = TRUE)
cat(sprintf("\nOverall: %d / %d checks pass (%.1f%%)\n",
            n_passing, n_total, 100 * n_passing / n_total))

# ── Failure details ───────────────────────────────────────────────────────
cat("\n── Failure details ──\n")
any_fail <- FALSE
for (r in all_results) {
  if (is.null(r$results)) next
  for (cn in names(r$results)) {
    res <- r$results[[cn]]
    if (!res$pass) {
      cat(sprintf("  %s / %s: %s\n", r$file, cn, res$msg))
      any_fail <- TRUE
    }
  }
}
if (!any_fail) cat("  None — all checks passed.\n")

# ── CSV output ────────────────────────────────────────────────────────────
write.csv(tbl, OUT_CSV, row.names = FALSE)
cat(sprintf("\nResults written to: %s\n", OUT_CSV))
cat("\nNote: This is a structural conformance check against Gating-ML 2.0\n")
cat("requirements (Spidlen et al. 2012, doi:10.1002/cyto.a.22156).\n")
cat("Checks correspond to the structural rules in the published XSD.\n")
cat("Done.\n")
