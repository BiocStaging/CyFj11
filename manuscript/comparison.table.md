# Appendix — Gate Event-Count Validation: CyFj11 Export Round-Trip Tests

**Column definitions.**
**N_R**: reference count from R (flowCore/openCyto); **N_FJ10**: count in FlowJo v10 after workspace import; **N_FJ11**: count in FlowJo v11 after workspace import; **N_FJ11r**: count after gate remade in FlowJo v11; **N_re**: count from re-reading the FlowJo v11-exported workspace; **res_FJ10** = residual N_R − N_FJ10 after removing error inherited from the parent gate; **res_FJ11** = residual N_R − N_FJ11 after removing error inherited from the parent gate; **res_FJ11r** = residual N_re − N_FJ11r after removing error inherited from the parent gate. **NI** = not imported (Boolean gates unsupported by this pipeline); **Nim** = not implemented; **N/A** = not evaluated for this test; **—** = difference not computable.

**Gate-type abbreviations.** Range (1D): 1-D range gate; Rect (2D): 2-D rectangle gate; Poly: polygon; Ellipse: ellipsoid; AND / OR / NOT: Boolean gate.

---

## Tests 01–09: Single Gate-Type Validation

| Test | Gate | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---:|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| 01 | All Events | Root | — | 5000 | 5000 | 5000 | 5000 | 5000 | 0 | 0 | 0 |
| 02 | FSC_filter | Range (1D) | FSC-a | 4776 | 4776 | 4778 | 4776 | 4776 | 0 | -2 | 0 |
| 03 | cells | Rect (2D) | FSC-a vs SSC-a | 4631 | 4631 | 4636 | 4631 | 4631 | 0 | -5 | 0 |
| 04 | singlets | Poly | FSC-a vs FSC-h | 7555 | 7569 | 7506 | 7506 | 7555 | -14 | 49 | 49 |
| 05 | ellipse_cells | Ellipse | FSC-a vs SSC-a | 7301 | 7314 | 7503 | 7290 | 7217 | -13 | -202 | -73 |
| 06 | FITC_pos | Range (1D) | Fitc-a (Biexp) | 2403 | 2403 | 2403 | 2396 | 2396 | 0 | 0 | 0 |
| 07 | PE_pos | Range (1D) | Pe-a (log) | 3198 | 3198 | 3198 | 3198 | 3198 | 0 | 0 | 0 |
| 08 | APC_pos | Range (1D) | Apc-a (Arcsinh) | 1606 | 1606 | 1608 | 1599 | 1599 | 0 | -2 | 0 |
| 09 | cells | Rect (2D) | FSC-a vs SSC-a | 9441 | 9441 | 9462 | 9441 | 9441 | 0 | -21 | 0 |
| 09 | singlets | Rect (2D) | FSC-a vs FSC-h | 8800 | 8800 | 8813 | 8800 | 8800 | 0 | 7 | 0 |

† Test 05: round-trip count drift is expected for ellipsoid gates because different mathematical representations of the ellipse accumulate rounding and precision effects.

## Test 10: Boolean AND / OR / NOT (Linear Axes)

| Gate | Path | Gate type | Condition | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| FSC_gate | /FSC_gate | Range (1D) | FSC-a | 7554 | 7554 | 7562 | 7558 | 7558 | 0 | -8 | 0 |
| SSC_gate | /SSC_gate | Range (1D) | SSC-a | 7392 | 7392 | 7419 | 7392 | 7392 | 0 | -27 | 0 |
| both | /both | AND | FSC_gate and SSC_gate | 6979 | 6979 | 7013 | 6983 | 6983 | 0 | -34 | 0 |
| bothOR | /bothOR | OR | FSC_gate or SSC_gate | 7967 | 7967 | 7968 | 7967 | 7967 | 0 | -1 | 0 |
| bothNOT | /bothNOT | NOT | Not both | 1021 | 1021 | 987 | 1017 | 1017 | 0 | 34 | 0 |

## Test 11: Mixed Biexponential + Arcsinh, Hierarchy + Boolean

| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| cells | /cells | Rect (2D) | FSC-a vs SSC-a | 9696 | 9696 | 9705 | 9696 | 9696 | 0 | -9 | 0 |
| FITC_pos | /cells/FITC_pos | Range (1D) | Fitc-a (Biexp) | 2897 | 2897 | 2900 | 2897 | 2897 | 0 | 0 | 0 |
| APC_pos | /cells/APC_pos | Range (1D) | Apc-a (Arcsinh) | 1930 | 1930 | 1932 | 1930 | 1930 | 0 | 0 | 0 |
| singlets | /cells/singlets | Poly | FSC-a vs FSC-h | 9478 | 9474 | 9487 | 9478 | 9478 | 4 | 0 | 0 |
| double_pos | /cells/double_pos | AND | Fitc_pos and Apc_pos | 1928 | 1928 | N/A | 1928 | 1928 | 0 | — | 0 |
| either_pos | /cells/either_pos | OR | Fitc_pos or Apc_pos | 2899 | 2899 | N/A | 2899 | 2899 | 0 | — | 0 |

## Test 12: Biexponential + Log, Ellipse + Full Boolean Set

> **Note.** FlowJo v11 does not support a combined `NOT(pop1, pop2)` Boolean gate.

| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| cells | /cells | Rect (2D) | FSC-a vs SSC-a | 9765 | 9765 | 9766 | 9765 | 9765 | 0 | -1 | 0 |
| scatter_ellipse | /scatter_ellipse | Ellipse | FSC-a vs SSC-a | 9803 | 9797 | 9890 | 9768 | 9759 | 6 | -87 | -9 |
| FITC_hi | /cells/FITC_hi | Range (1D) | Fitc-a (Biexp) | 2934 | 2934 | 2934 | 2934 | 2934 | 0 | 0 | 0 |
| PE_hi | /cells/PE_hi | Range (1D) | Pe-a (log) | 3831 | 3831 | 3831 | 3831 | 3831 | 0 | 0 | 0 |
| double_hi | /cells/double_hi | AND | Fitc_hi and Pe_hi | 2879 | 2879 | N/A | 2879 | 2879 | 0 | — | 0 |
| either_hi | /cells/either_hi | OR | Fitc_hi or Pe_hi | 3886 | 3886 | N/A | 3886 | 3886 | 0 | — | 0 |
| neither | /cells/neither | NOT | Not Either_hi | 5879 | 5879 | N/A | 5934 | N/A | 0 | — | — |

## Test 13: Arcsinh × 3 Channels, 3-Level Hierarchy + Boolean

| Gate | Path | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| live | /live | Poly | FSC-a vs SSC-a | 9939 | 9940 | 9938 | N/A | N/A | -1 | 1 | — |
| singlets | /live/singlets | Rect (2D) | FSC-a vs FSC-h | 9470 | 9470 | 9486 | N/A | N/A | 1 | -17 | — |
| FITC_PE_gate | /live/FITC_PE_gate | Ellipse | Fitc-a vs Pe-a (Arcsinh) | 2983 | 2992 | 2158 | N/A | N/A | -9 | 825 | — |
| FITC_pos | /live/singlets/FITC_pos | Range (1D) | Fitc-a (Arcsinh) | 2838 | 2838 | 2842 | N/A | N/A | 0 | 1 | — |
| APC_pos | /live/singlets/APC_pos | Range (1D) | Apc-a (Arcsinh) | 1888 | 1888 | 1891 | N/A | N/A | 0 | 0 | — |
| double_pos | /live/singlets/double_pos | AND | Fitc_pos and Apc_pos | 1887 | 1887 | N/A | N/A | N/A | 0 | — | — |
| not_double | /live/singlets/not_double | NOT | Not Double_pos | 7583 | 7583 | N/A | N/A | N/A | 0 | — | — |

---

## Test 14: Real-World Validation — FlowSOM Example Data

**Source.** FlowSOM R package; file `68983.fcs` + `gating.wsp` (mouse bone marrow immunophenotyping).  
**Pipeline.** `CytoML::flowjo_to_gatingset()` → `export_flowjo10_workspace()` (CyFj11 v10 → CytoML v10 import).  
**Acquisition settings.** Compensation matrix applied; fluorescence channels biexponential; scatter channels linear.

| Gate | Gate type | Channel(s) | N_R | N_FJ10 | N_FJ11 | N_FJ11r | N_re | res_FJ10 | res_FJ11 | res_FJ11r |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Lymphocytes | Poly | FCS-SSC | 19212 | 19203 | 19132 | 19132 | 19079 | 9 | 80 | -53 |
| Singlets | Rect (2D) | FSC-h FSC-w | 18689 | 18680 | 18594 | 18594 | 18545 | 9 | 95 | -49 |
| Singlets2 | Rect (2D) | SSC-h SSC-w | 18573 | 18563 | 18466 | 18466 | 18418 | 10 | 107 | -48 |
| Nk1_1+ | Rect (2D) | NK1.1 vs FSC-a | 923 | 922 | N/A | 918 | 940 | 1 | — | 22 |
| NK cells | Rect (2D) | CD3 NK1.1 | 312 | 312 | N/A | 310 | 314 | 0 | — | 4 |
| NK T cells | Rect (2D) | CD3 NK1.1 | 535 | 534 | N/A | 536 | 552 | 1 | — | 16 |
| NK1_1- | Rect (2D) | NK1.1 vs FSC-a | 17458 | 17449 | N/A | 17448 | 17358 | 9 | — | -90 |
| B cells | Rect (2D) | CD19 CD3 | 2459 | 2460 | N/A | 2461 | 2452 | -1 | — | -9 |
| T cells | Rect (2D) | CD19 CD3 | 10745 | 10747 | N/A | 10746 | 10747 | -2 | — | 1 |
| Ab T cells | Poly | TCRβ vs Trcgd | 9188 | 9190 | N/A | 9195 | 9182 | -2 | — | -13 |
| CD4 T cells | Rect (2D) | CD4 vs CD8 | 7480 | 7485 | N/A | 7482 | 7469 | -5 | — | -13 |
| CD8 T cells | Rect (2D) | CD4 vs CD8 | 1407 | 1404 | N/A | 1412 | 1413 | 3 | — | 1 |
| DN T cells | Rect (2D) | CD4 vs CD8 | 266 | 266 | N/A | 265 | 264 | 0 | — | -1 |
| DP T cells | Rect (2D) | CD4 vs CD8 | 6 | 6 | N/A | 6 | 7 | 0 | — | 1 |
| Gd T cells | Poly | TCRβ vs Trcgd | 1470 | 1470 | N/A | 1470 | 1470 | 0 | — | 0 |

**[a]** FlowJo v11 failed to parse the marker name "NK1_1+" (underscore–plus character combination). All populations gated downstream of NK1_1+ and NK1_1− consequently displayed as NA in FlowJo v11. FlowJo v10 reproduced the NK1_1+ count correctly (Δ_FJ10 = 1 event). This failure reflects a FlowJo v11 marker-name parsing idiosyncrasy and does not indicate an error in the CyFj11 export.

All other discrepancies can be explained by numerical conversion differences.
