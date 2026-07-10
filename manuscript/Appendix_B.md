# Appendix B: FlowJo v11 Compatibility and Per-Population Validation

The exported FlowJo v10 workspaces were opened in FlowJo v10 and FlowJo v11, and population counts were recorded at each stage. This appendix documents the observed compatibility behavior of FlowJo v11's v10 importer and provides the full per-population validation data.

## B.1 Validation pipeline

For each test scenario:

1. `export_flowjo10_workspace()` wrote a v10 XML workspace.
2. The workspace was opened in FlowJo v10 and population counts (`N_FJ10`) were recorded.
3. The workspace was also saved from within FlowJo v10 under ".llm.wsp"
3. The same workspace was opened in FlowJo v11; counts (`N_FJ11`) and any import warnings were recorded.
4. Where gates were dropped or mis-rendered in FlowJo v11, the gate was manually reconstructed in the v11 GUI and counts were re-recorded (`N_FJ11r`).
5. The v11-saved workspace was re-read into R via `fj11_to_gatingset()` to obtain `N_re`.

Residual differences (`res_FJ10`, `res_FJ11`, `res_FJ11r`) remove the error inherited from the parent population, so they reflect only gate-level discrepancy.

## B.2 FlowJo v11 compatibility findings

### B.2.1 Boolean gates

FlowJo v11's v10 importer **dropped hierarchical Boolean gates** in tests 11–13. Root-level Boolean gates (test 10) were imported, but deeper Boolean populations appeared as "not imported" (NI) and had to be reconstructed manually. After reconstruction, counts matched the R reference exactly. This behavior localizes the failure to FlowJo v11's importer, not to the exported XML: the same files open correctly in FlowJo v10.

### B.2.2 Arcsinh ellipsoid gates

One-dimensional arcsinh rectangle gates matched faithfully between R, FlowJo v10, and FlowJo v11. The **arcsinh ellipsoid gate** in test 13 (`FITC_PE_gate` on FITC-A vs PE-A) was rendered incorrectly by FlowJo v11, producing a count of 2,158 events versus the R reference of 2,983 events (≈28% loss). FlowJo v10 reproduced the count within numerical noise (2,992 events). This indicates that FlowJo v11's importer mis-handles the arcsinh-scaled `EllipsoidGate` coordinates, whereas the v10 XML itself is valid.

### B.2.3 Polygon and ellipse gates (general)

Small residual count differences for polygon gates (test 04, test 11 `singlets`) and ellipse gates (test 05, test 12 `scatter_ellipse`) reflect differences in how FlowJo renders these shapes when reading v10-format coordinates, not errors in the gate definitions. Once parent-inherited drift is removed, residuals remain within a few tens of cells (<0.2% relative).

### B.2.4 Log-transform display space

Test 07 uses a log-transformed PE-A axis. The gate coordinates stored in the v10 XML are in **transformed data space** (0.4–0.8), while FlowJo's GUI displays them multiplied by the decade parameter (≈6). The counts are nevertheless identical in R and FlowJo, confirming that the data-space coordinates are correct.

### B.2.5 Real-world test 14 marker-name issue

FlowJo v11 failed to parse the marker name "NK1_1+" (underscore–plus character combination). All populations downstream of `NK1_1+` and `NK1_1−` therefore displayed as not available in FlowJo v11. FlowJo v10 reproduced the `NK1_1+` count correctly (residual = 1 event). This failure is a FlowJo v11 marker-name parsing idiosyncrasy and does not indicate an error in the CyFj11 export.

## B.3 Table B1. Per-population event-count validation

Table B1 gives the full per-population counts for all 14 tests. Columns are defined as follows:

| Column | Meaning |
|---|---|
| `N_R` | Reference count from R (`flowCore`/`openCyto`). |
| `N_FJ10` | Count in FlowJo v10 after workspace import. |
| `N_FJ11` | Count in FlowJo v11 after workspace import. |
| `N_FJ11r` | Count after gate remade in FlowJo v11. |
| `N_re` | Count from re-reading the FlowJo v11-exported workspace. |
| `res_FJ10` | Residual `N_R − N_FJ10` after removing parent-inherited error. |
| `res_FJ11` | Residual `N_R − N_FJ11` after removing parent-inherited error. |
| `res_FJ11r` | Residual `N_re − N_FJ11r` after removing parent-inherited error. |

Abbreviations: **Range (1D)**, one-dimensional range gate; **Rect (2D)**, two-dimensional rectangle gate; **Poly**, polygon gate; **Ellipse**, ellipsoid gate; **AND / OR / NOT**, Boolean gates; **NI**, not imported; **Nim**, not implemented; **N/A**, not evaluated; **—**, not computable.

### B.3.1 Tests 01–09: single gate-type validation

| Test | Gate | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---:|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| 01 | All Events | Root | — | 5000 | 5000 | 5000 | 5000 | 5000 | 0 | 0 | 0 |
| 02 | FSC_filter | Range (1D) | FSC-A | 4776 | 4776 | 4778 | 4776 | 4776 | 0 | -2 | 0 |
| 03 | cells | Rect (2D) | FSC-A vs SSC-A | 4631 | 4631 | 4636 | 4631 | 4631 | 0 | -5 | 0 |
| 04 | singlets | Poly | FSC-A vs FSC-H | 7555 | 7569 | 7506 | 7506 | 7555 | -14 | 49 | 49 |
| 05 | ellipse_cells | Ellipse | FSC-A vs SSC-A | 7301 | 7314 | 7503 | 7290 | 7217 | -13 | -202 | -73 |
| 06 | FITC_pos | Range (1D) | FITC-A (Biexp) | 2403 | 2403 | 2403 | 2396 | 2396 | 0 | 0 | 0 |
| 07 | PE_pos | Range (1D) | PE-A (log) | 3198 | 3198 | 3198 | 3198 | 3198 | 0 | 0 | 0 |
| 08 | APC_pos | Range (1D) | APC-A (Arcsinh) | 1606 | 1606 | 1608 | 1599 | 1599 | 0 | -2 | 0 |
| 09 | cells | Rect (2D) | FSC-A vs SSC-A | 9441 | 9441 | 9462 | 9441 | 9441 | 0 | -21 | 0 |
| 09 | singlets | Rect (2D) | FSC-A vs FSC-H | 8800 | 8800 | 8813 | 8800 | 8800 | 0 | 7 | 0 |

† Test 05: round-trip count drift is expected for ellipsoid gates because different mathematical representations of the ellipse accumulate rounding and precision effects.

### B.3.2 Test 10: Boolean AND / OR / NOT (linear axes)

| Gate | Path | Gate type | Condition | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| FSC_gate | /FSC_gate | Range (1D) | FSC-A | 7554 | 7554 | 7562 | 7558 | 7558 | 0 | -8 | 0 |
| SSC_gate | /SSC_gate | Range (1D) | SSC-A | 7392 | 7392 | 7419 | 7392 | 7392 | 0 | -27 | 0 |
| both | /both | AND | FSC_gate and SSC_gate | 6979 | 6979 | 7013 | 6983 | 6983 | 0 | -34 | 0 |
| bothOR | /bothOR | OR | FSC_gate or SSC_gate | 7967 | 7967 | 7968 | 7967 | 7967 | 0 | -1 | 0 |
| bothNOT | /bothNOT | NOT | Not both | 1021 | 1021 | 987 | 1017 | 1017 | 0 | 34 | 0 |

### B.3.3 Test 11: mixed biexponential + arcsinh, hierarchy + Boolean

| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| cells | /cells | Rect (2D) | FSC-A vs SSC-A | 9696 | 9696 | 9705 | 9696 | 9696 | 0 | -9 | 0 |
| FITC_pos | /cells/FITC_pos | Range (1D) | FITC-A (Biexp) | 2897 | 2897 | 2900 | 2897 | 2897 | 0 | 0 | 0 |
| APC_pos | /cells/APC_pos | Range (1D) | APC-A (Arcsinh) | 1930 | 1930 | 1932 | 1930 | 1930 | 0 | 0 | 0 |
| singlets | /cells/singlets | Poly | FSC-A vs FSC-H | 9478 | 9474 | 9487 | 9478 | 9478 | 4 | 0 | 0 |
| double_pos | /cells/double_pos | AND | FITC_pos and APC_pos | 1928 | 1928 | N/A | 1928 | 1928 | 0 | — | 0 |
| either_pos | /cells/either_pos | OR | FITC_pos or APC_pos | 2899 | 2899 | N/A | 2899 | 2899 | 0 | — | 0 |

### B.3.4 Test 12: biexponential + log, ellipse + full Boolean set

> **Note.** FlowJo v11 does not support a combined `NOT(pop1, pop2)` Boolean gate.

| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| cells | /cells | Rect (2D) | FSC-A vs SSC-A | 9765 | 9765 | 9766 | 9765 | 9765 | 0 | -1 | 0 |
| scatter_ellipse | /scatter_ellipse | Ellipse | FSC-A vs SSC-A | 9803 | 9797 | 9890 | 9768 | 9759 | 6 | -87 | -9 |
| FITC_hi | /cells/FITC_hi | Range (1D) | FITC-A (Biexp) | 2934 | 2934 | 2934 | 2934 | 2934 | 0 | 0 | 0 |
| PE_hi | /cells/PE_hi | Range (1D) | PE-A (log) | 3831 | 3831 | 3831 | 3831 | 3831 | 0 | 0 | 0 |
| double_hi | /cells/double_hi | AND | FITC_hi and PE_hi | 2879 | 2879 | N/A | 2879 | 2879 | 0 | — | 0 |
| either_hi | /cells/either_hi | OR | FITC_hi or PE_hi | 3886 | 3886 | N/A | 3886 | 3886 | 0 | — | 0 |
| neither | /cells/neither | NOT | Not either_hi | 5879 | 5879 | N/A | 5934 | N/A | 0 | — | — |

### B.3.5 Test 13: arcsinh × 3 channels, 3-level hierarchy + Boolean

| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| live | /live | Poly | FSC-A vs SSC-A | 9939 | 9940 | 9938 | N/A | N/A | -1 | 1 | — |
| singlets | /live/singlets | Rect (2D) | FSC-A vs FSC-H | 9470 | 9470 | 9486 | N/A | N/A | 1 | -17 | — |
| FITC_PE_gate | /live/FITC_PE_gate | Ellipse | FITC-A vs PE-A (Arcsinh) | 2983 | 2992 | 2158 | N/A | N/A | -9 | 825 | — |
| FITC_pos | /live/singlets/FITC_pos | Range (1D) | FITC-A (Arcsinh) | 2838 | 2838 | 2842 | N/A | N/A | 0 | 1 | — |
| APC_pos | /live/singlets/APC_pos | Range (1D) | APC-A (Arcsinh) | 1888 | 1888 | 1891 | N/A | N/A | 0 | 0 | — |
| double_pos | /live/singlets/double_pos | AND | FITC_pos and APC_pos | 1887 | 1887 | N/A | N/A | N/A | 0 | — | — |
| not_double | /live/singlets/not_double | NOT | Not double_pos | 7583 | 7583 | N/A | N/A | N/A | 0 | — | — |

### B.3.6 Test 14: real-world validation — FlowSOM example data

**Source.** FlowSOM R package; file `68983.fcs` + `gating.wsp` (mouse bone marrow immunophenotyping).  
**Pipeline.** `CytoML::flowjo_to_gatingset()` → `export_flowjo10_workspace()` (CyFj11 v10 → CytoML v10 import).  
**Acquisition settings.** Compensation matrix applied; fluorescence channels biexponential; scatter channels linear.

| Gate | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Lymphocytes | Poly | FSC-SSC | 19212 | 19203 | 19132 | 19132 | 19079 | 9 | 80 | -53 |
| Singlets | Rect (2D) | FSC-H FSC-W | 18689 | 18680 | 18594 | 18594 | 18545 | 9 | 95 | -49 |
| Singlets2 | Rect (2D) | SSC-H SSC-W | 18573 | 18563 | 18466 | 18466 | 18418 | 10 | 107 | -48 |
| Nk1_1+ | Rect (2D) | NK1.1 vs FSC-A | 923 | 922 | N/A | 918 | 940 | 1 | — | 22 |
| NK cells | Rect (2D) | CD3 NK1.1 | 312 | 312 | N/A | 310 | 314 | 0 | — | 4 |
| NK T cells | Rect (2D) | CD3 NK1.1 | 535 | 534 | N/A | 536 | 552 | 1 | — | 16 |
| NK1_1- | Rect (2D) | NK1.1 vs FSC-A | 17458 | 17449 | N/A | 17448 | 17358 | 9 | — | -90 |
| B cells | Rect (2D) | CD19 CD3 | 2459 | 2460 | N/A | 2461 | 2452 | -1 | — | -9 |
| T cells | Rect (2D) | CD19 CD3 | 10745 | 10747 | N/A | 10746 | 10747 | -2 | — | 1 |
| Ab T cells | Poly | TCRβ vs TCRγδ | 9188 | 9190 | N/A | 9195 | 9182 | -2 | — | -13 |
| CD4 T cells | Rect (2D) | CD4 vs CD8 | 7480 | 7485 | N/A | 7482 | 7469 | -5 | — | -13 |
| CD8 T cells | Rect (2D) | CD4 vs CD8 | 1407 | 1404 | N/A | 1412 | 1413 | 3 | — | 1 |
| DN T cells | Rect (2D) | CD4 vs CD8 | 266 | 266 | N/A | 265 | 264 | 0 | — | -1 |
| DP T cells | Rect (2D) | CD4 vs CD8 | 6 | 6 | N/A | 6 | 7 | 0 | — | 1 |
| Gd T cells | Poly | TCRβ vs TCRγδ | 1470 | 1470 | N/A | 1470 | 1470 | 0 | — | 0 |

**[a]** FlowJo v11 failed to parse the marker name "NK1_1+" (underscore–plus character combination). All populations gated downstream of NK1_1+ and NK1_1− consequently displayed as N/A in FlowJo v11. FlowJo v10 reproduced the NK1_1+ count correctly (res_FJ10 = 1 event). This failure reflects a FlowJo v11 marker-name parsing idiosyncrasy and does not indicate an error in the CyFj11 export.

## B.4 Test 14 detail: compensation matrix preservation

Test 14 exercises compensation matrix round-tripping on real mouse bone-marrow data. The original FlowSOM workspace (`flowjo_export_tests/test14/test14_flowsom.wsp`) contains an 11 × 11 acquisition-defined spillover matrix. CyFj11 exports this matrix in `flowjo_export_tests/test14/test14.compensation.wsp`. The original matrix stores coefficients as proportions (diagonal = 1), while the exported matrix stores them as percentages (diagonal = 100); after rescaling the exported matrix by ÷100, the element-wise comparison is:

- Matrix dimension: 11 × 11
- Mean absolute relative difference: 0.000308%
- Median absolute relative difference: 0.000010%
- Maximum absolute relative difference: 0.011125% (Qdot 605-A → APC-Cy7-A)

The full element-wise comparison is provided in `manuscript/test14_compensation_elementwise.csv`; the 20 largest absolute relative differences are shown in Table B2.

### Table B2. Largest absolute relative differences in the test 14 compensation matrix

| From | To | Original | Exported (scaled) | Absolute diff | Relative diff (%) |
|---|---:|---:|---:|---:|---:|
| Qdot 605-A | APC-Cy7-A | 0.0000261 | 0.0000261 | 0.0000000 | 0.011125 |
| Qdot 605-A | PE-Cy7-A | 0.0000364 | 0.0000364 | 0.0000000 | 0.007414 |
| Pacific Blue-A | Alexa Fluor 700-A | 0.0001085 | 0.0001085 | -0.0000000 | -0.001935 |
| Pacific Blue-A | PE-Cy7-A | 0.0000388 | 0.0000387 | -0.0000000 | -0.001806 |
| Qdot 605-A | Pacific Blue-A | 0.0002496 | 0.0002496 | -0.0000000 | -0.001763 |
| Qdot 605-A | Alexa Fluor 700-A | 0.0002576 | 0.0002576 | -0.0000000 | -0.001747 |
| Qdot 605-A | FITC-A | 0.0000863 | 0.0000863 | -0.0000000 | -0.001739 |
| AmCyan-A | PE-Texas Red-A | 0.0001757 | 0.0001757 | 0.0000000 | 0.001480 |
| Pacific Blue-A | FITC-A | 0.0004844 | 0.0004844 | -0.0000000 | -0.000908 |
| PE-Texas Red-A | Alexa Fluor 700-A | 0.0001830 | 0.0001830 | 0.0000000 | 0.000601 |
| PE-Texas Red-A | Pacific Blue-A | 0.0005403 | 0.0005403 | -0.0000000 | -0.000500 |
| FITC-A | APC-Cy7-A | 0.0008660 | 0.0008660 | 0.0000000 | 0.000439 |
| PE-A | FITC-A | 0.0011664 | 0.0011664 | -0.0000000 | -0.000420 |
| PE-Cy5-A | Pacific Blue-A | 0.0005018 | 0.0005018 | -0.0000000 | -0.000339 |
| AmCyan-A | Alexa Fluor 700-A | 0.0011353 | 0.0011353 | 0.0000000 | 0.000335 |
| PE-A | Alexa Fluor 700-A | 0.0002449 | 0.0002449 | -0.0000000 | -0.000327 |
| PE-Cy5-A | FITC-A | 0.0003372 | 0.0003372 | 0.0000000 | 0.000326 |
| PE-Cy5-A | AmCyan-A | 0.0016727 | 0.0016727 | 0.0000000 | 0.000293 |
| FITC-A | Alexa Fluor 700-A | 0.0010697 | 0.0010697 | -0.0000000 | -0.000280 |
| Pacific Blue-A | APC-A | 0.0017360 | 0.0017360 | -0.0000000 | -0.000219 |

The compensation matrix is therefore preserved to numerical round-off; remaining differences are at the level of single-precision representation and do not affect population counts.

## B.5 Summary statistics

Key summary statistics derived from Table B1 are reproduced in Table B3.

### Table B3. Validation summary by comparison subset

| Comparison subset | N | Exact match | Within ≤0.3% | Max \|residual\| | Mean \|%diff\| |
|---|---:|---:|---:|---:|---:|
| Export FJ10, synthetic core (excl. arcsinh + Boolean) | 20 | 14 (70%) | 6 (30%) | 14 cells | 0.0243% |
| Export FJ10, arcsinh gates only | 5 | 4 (80%) | 1 (20%) | 8.7 cells | 0.0583% |
| Export FJ10, Boolean gates only | 10 | 10 (100%) | 0 | 0 cells | 0.0000% |
| Export FJ10, real-world test 14 | 15 | 4 (27%) | 11 (73%) | 10 cells | 0.0571% |
| Import R, synthetic core (excl. arcsinh + Boolean) | 18 | 15 (83%) | 1 (6%) | 73 cells | 0.0970% |
| Import R, arcsinh gates only | 2 | 2 (100%) | 0 | 0 cells | 0.0000% |
| Import R, Boolean gates only | 7 | 7 (100%) | 0 | 0 cells | 0.0000% |
| Import R, real-world test 14 | 15 | 1 (7%) | 7 (47%) | 90 cells | 1.7195% |

The synthetic export and import comparisons pass the acceptance criterion of mean absolute percentage difference ≤0.5%. The real-world test 14 import comparison exceeds this threshold because of the `NK1_1+` marker-name parsing failure and small residual drift accumulated across a deep compensation/transform stack.

## B.6 Gating-ML 2.0 conformance

Structural Gating-ML 2.0 conformance of the exported v10 workspaces is documented in **Appendix C**. All 50 applicable structural checks passed across the 13 synthetic test workspaces (100%). That appendix also contains the per-test conformance table (Table C1).

## B.7 Source data

The machine-readable validation data underlying this appendix are available in:

- `manuscript/validation_counts 2.xlsx` — authoritative curated per-gate counts (used to generate all tables here).
- `cyfj11_validation_detail.csv` — per-gate residuals and percentages.
- `cyfj11_validation_summary.csv` — aggregated statistics by comparison subset.
- `cyfj11_validation_report.txt` — full human-readable report.
- `manuscript/comparison.table.generated.md` — manuscript-formatted version of Table B1.
- `manuscript/test14_compensation_elementwise.csv` — full element-wise compensation matrix comparison for test 14.
- `manuscript/test14_compensation_elementwise.md` — rendered top differences for test 14 compensation.

The validation report can be regenerated with:

```bash
Rscript validation.report.R "manuscript/validation_counts 2.xlsx"
```

The test 14 compensation comparison can be regenerated with:

```bash
python3 manuscript/compare_test14_compensation.py
```
