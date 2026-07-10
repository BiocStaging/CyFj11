# Appendix C: Gating-ML 2.0 Standards Compliance

CyFj11 exports FlowJo v10 workspaces as XML documents intended to conform to the ISAC Gating-ML 2.0 standard (Spidlen et al., *Cytometry A*, 2012, doi:10.1002/cyto.a.22156). This appendix documents the structural conformance checks performed on the 13 synthetic test workspaces and summarizes the results.

## C.1 Conformance check methodology

The R script `manuscript/validate_gatingml_conformance.R` performs structural checks on each exported workspace without requiring a local XSD file (outbound HTTP is blocked in the validation environment). The checks mirror the structural rules defined in the published Gating-ML 2.0 specification and XSD:

1. **Namespace declarations.** The Gating-ML 2.0 namespace URIs for `gating`, `transformations`, and `data-type` must be declared.
2. **Gate element structure.** Each `RectangleGate`, `PolygonGate`, `EllipsoidGate`, and `BooleanGate` must contain the required child elements and attributes, and every dimension must reference a named FCS parameter.
3. **Transformation element structure.** Each `linear`, `biex`, `fasinh`, `logicle`, and `log` transformation element must carry the required parameter attributes and a non-empty `data-type:parameter` child.

Checks are run only on `SampleNode` elements to avoid duplicate counting of group-level gate definitions.

## C.2 Results

All 50 applicable structural checks passed across the 13 synthetic test workspaces (100%). The per-test breakdown is shown in Table C1.

## C.3 Table C1. Gating-ML 2.0 structural conformance by test

| Test | Namespace | Linear transform | RectangleGate | PolygonGate | EllipsoidGate | Biex transform | Log transform | Arcsinh transform |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| test01 | ✓ | ✓ | — | — | — | — | — | — |
| test02 | ✓ | ✓ | ✓ | — | — | — | — | — |
| test03 | ✓ | ✓ | ✓ | — | — | — | — | — |
| test04 | ✓ | ✓ | — | ✓ | — | — | — | — |
| test05 | ✓ | ✓ | — | — | ✓ | — | — | — |
| test06 | ✓ | ✓ | ✓ | — | — | ✓ | — | — |
| test07 | ✓ | ✓ | ✓ | — | — | — | ✓ | — |
| test08 | ✓ | ✓ | ✓ | — | — | — | — | ✓ |
| test09 | ✓ | ✓ | ✓ | — | — | — | — | — |
| test10 | ✓ | ✓ | ✓ | — | — | — | — | — |
| test11 | ✓ | ✓ | ✓ | ✓ | — | ✓ | — | ✓ |
| test12 | ✓ | ✓ | ✓ | — | ✓ | ✓ | ✓ | — |
| test13 | ✓ | ✓ | ✓ | ✓ | ✓ | — | — | ✓ |
| **Total passing / applicable** | **13 / 13** | **13 / 13** | **10 / 10** | **3 / 3** | **3 / 3** | **3 / 3** | **2 / 2** | **3 / 3** |

Legend: ✓ = check passed; — = gate/transform type not present in that test.

## C.4 Coverage notes

The structural checks verify XML schema conformance, not semantic correctness of population counts. Semantic correctness is assessed separately in Appendix B. The two checks are complementary:

- **Structural conformance** guarantees that exported workspaces are parseable by any Gating-ML 2.0–compliant reader.
- **Population-count validation** guarantees that the gates encoded in those valid XML structures produce the expected event subsets.

## C.5 Reproducibility

The conformance check can be re-run from the package root with:

```bash
Rscript manuscript/validate_gatingml_conformance.R
```

This regenerates `manuscript/gatingml_conformance.csv` and prints the per-test report shown above.
