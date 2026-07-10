FlowJo Export Test Files
========================

Generated: 2026-03-18 17:22:30.056817
Last updated: 2026-06-25

Overview
--------
This directory contains the structured validation suite for the CyFj11 R
package. It is organized into 14 test scenarios (test01/ ... test14/) that
exercise FlowJo v10 workspace export across all supported gate types,
transformations, and population hierarchies.

Data provenance
---------------
- Tests 01–13 use entirely synthetic FCS data. The FCS files were generated
  programmatically by flowjo_export_tests/generate_all_tests.R via the
  create_test_fcs() helper, which draws random values from normal and
  log-normal distributions with fixed seeds. No human or patient-derived
  biological material is included.
- Test 14 uses the public example dataset bundled with the Bioconductor
  FlowSOM package: 68983.fcs and gating.wsp. These files are automatically
  retrieved from FlowSOM's installed extdata/ directory when the test is
  regenerated. They are not patient-derived or otherwise restricted human
  data.

Directory Structure:
  test01/ - Minimal export (no gates, linear only)
  test02/ - Single 1D rectangle gate (linear)
  test03/ - Single 2D rectangle gate (linear)
  test04/ - Polygon gate (linear)
  test05/ - Ellipsoid gate (linear)
  test06/ - 1D rectangle gate (biexponential)
  test07/ - 1D rectangle gate (log)
  test08/ - 1D rectangle gate (arcsinh)
  test09/ - Hierarchical gates (2 levels, linear)
  test10/ - Boolean AND/OR/NOT gates (linear)
  test11/ - Mixed hierarchy with biexponential + arcsinh + boolean gates
  test12/ - Ellipsoid, range, and full boolean set (biexp + log)
  test13/ - 3-level hierarchy with arcsinh transforms and boolean gates
  test14/ - Real-world FlowSOM lymphocyte gating dataset (linear)

How to Regenerate Tests 01–13
------------------------------
The synthetic tests can be regenerated from R from the package root:

  Rscript flowjo_export_tests/generate_all_tests.R

or from within R:

  source("flowjo_export_tests/generate_all_tests.R")

Test 14 is regenerated only when the FlowSOM package is installed; the
test script copies the public example files 68983.fcs and gating.wsp from
FlowSOM's extdata/ directory.

How to Test in FlowJo
---------------------
  1. Open FlowJo v10 or v11
  2. File → Import → Workspace
  3. Select the desired *_export.wsp file from any test directory
  4. Verify gates appear correctly
  5. Check population statistics match expected values

Each test directory contains:
  - *.fcs - FCS files (synthetic for tests 01–13, real-world for test14)
  - *_export.wsp - FlowJo v10 workspace produced by CyFj11
  - *_export.llm.wsp - Copy of the exported workspace for comparison/testing
  - (for some tests) additional intermediate .flowjo or .wsp files

Keyword, compensation, and cytometer metadata
---------------------------------------------
When a workspace is imported into a GatingSet (via CytoML for v10 or via
CyFj11 for v11), FCS keywords are merged from the FCS file and the workspace
XML. Compensation rewrites fluorescence parameter names to the "Comp-..."
form and parses the SPILL matrix into an R matrix. The CyFj11 exporter
reformats SPILL back into the FlowJo FCS keyword string format because the
internal matrix representation differs from the workspace string format.

Cytometer name, cytometer description, useTransform, transformType,
manufacturer, serial number, and other workspace-level instrument metadata
are NOT stored in the GatingSet by CytoML/flowWorkspace. Consequently, the
CyFj11 exporter writes a generic placeholder cytometer. This means exported
workspaces faithfully preserve gating logic, population counts, gate
coordinates, and compensation matrices, but not the original instrument or
display settings. For a detailed technical explanation, see:

  manuscript/Annex_keyword_compensation_cytometer_handling.md

Validation records
------------------
  - validation_counts.csv / validation_counts.tsv: population counts recorded
    from the R GatingSet for each test scenario.
  - validation_transforms.tsv: transformation-level validation summary.
  - history.txt: log of workspace generation history.
  - WSP_LLM_DIFFERENCES_SUMMARY.md, wsp_comparison_report.md, and
    wsp_semantic_comparison_report.md: detailed comparisons between the
    exported workspaces and the versions re-saved by FlowJo.

For full methodological details, see the Validation section and Annex D of the
CyFj11 manuscript (manuscript/cyfjll_manuscript.Rmd and
manuscript/Annex_keyword_compensation_cytometer_handling.md).
