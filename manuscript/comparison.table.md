# Appendix — Gate Event-Count Validation: CyFj11 Export Round-Trip Tests

**Column definitions.**
*N*_R: reference count from R (flowCore/openCyto); *N*_FJ10: count in FlowJo v10 after workspace import; *N*_FJ11: count in FlowJo v11 after workspace import; *N*_FJ11r: count after gate remade in FlowJo v11; *N*_re: count from re-reading the FlowJo v11-exported workspace; Δ_FJ10 = *N*_R − *N*_FJ10; Δ_FJ11 = *N*_R − *N*_FJ11. **NI** = not imported (Boolean gates unsupported by this pipeline); **Nim** = not implemented; **N/A** = not evaluated for this test; **—** = difference not computable.

**Gate-type abbreviations.** Range (1D): 1-D range gate; Rect (2D): 2-D rectangle gate; Poly: polygon; Ellipse: ellipsoid; AND / OR / NOT: Boolean gate.

---

## Tests 01–09: Single Gate-Type Validation

| Test | Gate | Gate type | Channel(s) | *N*_R | *N*_FJ10 | *N*_FJ11 | *N*_FJ11r | *N*_re | Δ_FJ10 | Δ_FJ11 |
|:---:|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| 01 | All Events | Root | — | 5000 | 5000 | 5000 | 5000 | 5000 | 0 | 0 |
| 02 | FSC_filter | Range (1D) | FSC-A | 4776 | 4776 | 4778 | 4776 | 4776 | 0 | −2 |
| 03 | cells | Rect (2D) | FSC-A vs SSC-A | 4631 | 4631 | 4636 | 4631 | 4631 | 0 | −5 |
| 04 | singlets | Poly | FSC-A vs FSC-H | 7555 | 7569 | 7506 | 7506 | 7555 | −14 | 49 |
| 05 | ellipse_cells | Ellipse | FSC-A vs SSC-A | 7301 | 7314 | 7503 | 7290 | 7217 | −13 | −202 |
| 06 | FITC_pos | Range (1D) | FITC-A (biexp) | 2403 | 2403 | 2403 | 2396 | 2396 | 0 | 0 |
| 07 | PE_pos | Range (1D) | PE-A (log)† | 3198 | 3198 | 3198 | 3198 | 3198 | 0 | 0 |
| 08 | APC_pos | Range (1D) | APC-A (arcsinh) | 1606 | 1606 | 1608 | 1599 | 1599 | 0 | −2 |
| 09 | cells | Rect (2D) | FSC-A vs SSC-A | 9441 | 9441 | 9462 | 9441 | 9441 | 0 | −21 |
| 09 | singlets | Rect (2D) | FSC-A vs FSC-H | 8800 | 8800 | 8813 | 8800 | 8800 | 0 | −13 |

† Test 07: minor round-trip count drift from the log transform is expected and documented.

---

## Test 10: Boolean AND / OR / NOT (Linear Axes)

| Gate | Path | Gate type | Condition | *N*_R | *N*_FJ10 | *N*_FJ11 | *N*_FJ11r | *N*_re | Δ_FJ10 | Δ_FJ11 |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| FSC_gate | /FSC_gate | Range (1D) | FSC-A | 7554 | 7554 | 7562 | 7558 | 7558 | 0 | −8 |
| SSC_gate | /SSC_gate | Range (1D) | SSC-A | 7392 | 7392 | 7419 | 7392 | 7392 | 0 | −27 |
| both | /both | AND | FSC_gate AND SSC_gate | 6979 | 6979 | 7013 | 6983 | 6983 | 0 | −34 |
| bothOR | /bothOR | OR | FSC_gate OR SSC_gate | 7967 | 7967 | 7968 | 1017 | 1017 | 0 | −1 |
| bothNOT | /bothNOT | NOT | NOT both | 1021 | 1021 | 987 | 7967 | 7967 | 0 | 34 |

---

## Test 11: Mixed Biexponential + Arcsinh, Hierarchy + Boolean

| Gate | Path | Gate type | Channel(s) | *N*_R | *N*_FJ10 | *N*_FJ11 | *N*_FJ11r | *N*_re | Δ_FJ10 | Δ_FJ11 |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| cells | /cells | Rect (2D) | FSC-A vs SSC-A | 9696 | 9696 | 9705 | 9696 | 9696 | 0 | −9 |
| FITC_pos | /cells/FITC_pos | Range (1D) | FITC-A (biexp) | 2897 | 2897 | 2900 | 2897 | 2897 | 0 | −3 |
| APC_pos | /cells/APC_pos | Range (1D) | APC-A (arcsinh) | 1930 | 1930 | 1932 | 1930 | 1930 | 0 | −2 |
| singlets | /cells/singlets | Poly | FSC-A vs FSC-H | 9478 | 9474 | 9487 | 9478 | 9478 | 4 | −9 |
| double_pos | /cells/double_pos | AND | FITC_pos AND APC_pos | 1928 | 1928 | NI | 1928 | 1928 | 0 | — |
| either_pos | /cells/either_pos | OR | FITC_pos OR APC_pos | 2899 | 2899 | NI | 2899 | 2899 | 0 | — |

---

## Test 12: Biexponential + Log, Ellipse + Full Boolean Set

> **Note.** PE_hi and all gates depending on it may exhibit round-trip count drift attributable to the log transform.

| Gate | Path | Gate type | Channel(s) | *N*_R | *N*_FJ10 | *N*_FJ11 | *N*_FJ11r | *N*_re | Δ_FJ10 | Δ_FJ11 |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| cells | /cells | Rect (2D) | FSC-A vs SSC-A | 9765 | 9765 | 9766 | 9765 | 9765 | 0 | −1 |
| scatter_ellipse | /scatter_ellipse | Ellipse | FSC-A vs SSC-A | 9803 | 9797 | 9890 | 9768 | 9759 | 6 | −87 |
| FITC_hi | /cells/FITC_hi | Range (1D) | FITC-A (biexp) | 2934 | 2934 | 2934 | 2934 | 2934 | 0 | 0 |
| PE_hi | /cells/PE_hi | Range (1D) | PE-A (log) | 3831 | 3831 | 3831 | 3831 | 3831 | 0 | 0 |
| double_hi | /cells/double_hi | AND | FITC_hi AND PE_hi | 2879 | 2879 | NI | 2879 | 2879 | 0 | — |
| either_hi | /cells/either_hi | OR | FITC_hi OR PE_hi | 3886 | 3886 | NI | 3886 | 3886 | 0 | — |
| neither | /cells/neither | NOT | NOT either_hi | 5879 | 5879 | NI | 5934 | Nim | 0 | — |

---

## Test 13: Arcsinh × 3 Channels, 3-Level Hierarchy + Boolean

| Gate | Path | Gate type | Channel(s) | *N*_R | *N*_FJ10 | *N*_FJ11 | *N*_FJ11r | *N*_re | Δ_FJ10 | Δ_FJ11 |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| live | /live | Poly | FSC-A vs SSC-A | 9939 | 9940 | 9938 | N/A | N/A | −1 | 1 |
| singlets | /live/singlets | Rect (2D) | FSC-A vs FSC-H | 9470 | 9470 | 9486 | N/A | N/A | 0 | −16 |
| FITC_PE_gate | /live/FITC_PE_gate | Ellipse | FITC-A vs PE-A (arcsinh) | 2983 | 2992 | 2158 | N/A | N/A | −9 | 825 |
| FITC_pos | /live/singlets/FITC_pos | Range (1D) | FITC-A (arcsinh) | 2838 | 2838 | 2842 | N/A | N/A | 0 | −4 |
| APC_pos | /live/singlets/APC_pos | Range (1D) | APC-A (arcsinh) | 1888 | 1888 | 1891 | N/A | N/A | 0 | −3 |
| double_pos | /live/singlets/double_pos | AND | FITC_pos AND APC_pos | 1887 | 1887 | NI | N/A | N/A | 0 | — |
| not_double | /live/singlets/not_double | NOT | NOT double_pos | 7583 | 7583 | NI | N/A | N/A | 0 | — |

---

## Test 14: Real-World Validation — FlowSOM Example Data

**Source.** FlowSOM R package; file `68983.fcs` + `gating.wsp` (mouse bone marrow immunophenotyping).  
**Pipeline.** `CytoML::flowjo_to_gatingset()` → `export_flowjo10_workspace()` (CyFj11 v10 → CytoML v10 import).  
**Acquisition settings.** Compensation matrix applied; fluorescence channels biexponential; scatter channels linear.

| Gate | Gate type | Channel(s) | *N*_R | *N*_FJ10 | *N*_FJ11 | *N*_FJ11r | *N*_re | Δ_FJ10 | Δ_FJ11 |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| Lymphocytes | Poly | FSC-A vs SSC-A | 19212 | 19203 | 19132 | 19132 | 19079 | 9 | 80 |
| Singlets | Rect (2D) | FSC-H vs FSC-W | 18689 | 18680 | 18594 | 18594 | 18545 | 9 | 95 |
| Singlets2 | Rect (2D) | SSC-H vs SSC-W | 18573 | 18563 | 18466 | 18466 | 18418 | 10 | 107 |
| NK1_1+ | Range (1D) | NK1.1 vs FSC-A | 923 | 922 | [a] | 918 | 940 | 1 | — |
| NK cells | Rect (2D) | CD3 vs NK1.1 | 312 | 312 | [a] | 310 | 314 | 0 | — |
| NK T cells | Rect (2D) | CD3 vs NK1.1 | 535 | 534 | [a] | 536 | 552 | 1 | — |
| NK1_1− | Range (1D) | NK1.1 vs FSC-A | 17458 | 17449 | [a] | 17448 | 17358 | 9 | — |
| B cells | Rect (2D) | CD19 vs CD3 | 2459 | 2460 | [a] | 2461 | 2452 | −1 | — |
| T cells | Rect (2D) | CD19 vs CD3 | 10745 | 10747 | [a] | 10746 | 10747 | −2 | — |
| αβ T cells | Poly | TCRβ vs TCRγδ | 9188 | 9190 | [a] | 9195 | 9182 | −2 | — |
| CD4 T cells | Rect (2D) | CD4 vs CD8 | 7480 | 7485 | [a] | 7482 | 7469 | −5 | — |
| CD8 T cells | Rect (2D) | CD4 vs CD8 | 1407 | 1404 | [a] | 1412 | 1413 | 3 | — |
| DN T cells | Rect (2D) | CD4 vs CD8 | 266 | 266 | [a] | 265 | 264 | 0 | — |
| DP T cells | Rect (2D) | CD4 vs CD8 | 6 | 6 | [a] | 6 | 7 | 0 | — |
| γδ T cells | Poly | TCRβ vs TCRγδ | 1470 | 1470 | [a] | 1470 | 1470 | 0 | — |

**[a]** FlowJo v11 failed to parse the marker name "NK1_1+" (underscore–plus character combination). All populations gated downstream of NK1_1+ and NK1_1− consequently displayed as NA in FlowJo v11. FlowJo v10 reproduced the NK1_1+ count correctly (Δ_FJ10 = 1 event). This failure reflects a FlowJo v11 marker-name parsing idiosyncrasy and does not indicate an error in the CyFj11 export.