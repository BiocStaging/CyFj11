# Test 14 compensation matrix element-wise comparison

Original source: `flowjo_export_tests/test14/test14_flowsom.wsp`

Exported source: `flowjo_export_tests/test14/test14.compensation.wsp`

The exported matrix stores coefficients as percentages (diagonal = 100); the original stores them as proportions (diagonal = 1). After rescaling the exported matrix by ÷100, the matrices are compared element-wise.

- Matrix dimension: 11 × 11
- Mean absolute relative difference: 0.000308%
- Median absolute relative difference: 0.000010%
- Maximum absolute relative difference: 0.011125% (at Qdot 605-A → APC-Cy7-A)

## Largest absolute relative differences

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

Full element-wise results: `manuscript/test14_compensation_elementwise.csv`
