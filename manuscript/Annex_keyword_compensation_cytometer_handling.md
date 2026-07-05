# Annex D: Keyword, Compensation, and Cytometer Metadata Handling

*This annex documents how CyFj11 handles FCS keywords, compensation matrices, and cytometer metadata during FlowJo v11 → R → FlowJo v10 conversion. It is intended for reviewers and developers who need to understand the limits of information preservation in the current pipeline.*

---

## D.1 Scope

CyFj11 converts FlowJo workspaces through the following pipeline:

```
FlowJo v10 .wsp  ──►  GatingSet  ──►  FlowJo v10 .wsp
                CytoML          CyFj11 export
```

For test14, the first step uses `CytoML::flowjo_to_gatingset()` to read a public FlowJo v10 workspace (the FlowSOM `gating.wsp` example). The same principles apply when CyFj11's own `fj11_to_gatingset()` reads a FlowJo v11 workspace, because the resulting `GatingSet` object is identical in structure.

This annex explains:

1. Where FCS keywords come from.
2. How compensation changes keywords and channel names.
3. Why the `SPILL` keyword is reformatted on export.
4. Why cytometer name, `useTransform`, and related workspace attributes are lost.
5. Which information from the original workspace is preserved and which is not.

---

## D.2 Keyword provenance: workspace XML vs. FCS file

`flowCore::keyword(gh)` returns a **merged keyword list**. For a `GatingHierarchy` created by `CytoML::flowjo_to_gatingset()`, the keywords are assembled as follows:

- The base set is read from the **FCS TEXT segment** of the linked `.fcs` file.
- The workspace parser overlays any keywords stored under `Sample/Keywords/Keyword` nodes in the `.wsp` XML.
- `flowWorkspace` appends computed entries (for example, `flowCore_$PnRmax/min`).

For test14, `keyword(gh)` contains **248 keywords**. The original workspace XML contains **282** keyword-like entries; the difference is mostly unused parameter slots (`$P19N` … `$P29R`) and a FlowJo-internal `FJ_FCS_VERSION` entry that are not copied into the `GatingSet`.

Concrete test14 values returned by `flowCore::keyword(gh)`:

```r
$FIL  = "68983.fcs"
$CYT  = ""
$INST = ""
SPILL = <11 x 11 matrix with colnames "Comp-FITC-A" ...>
$P8N  = "Comp-FITC-A"     # raw FCS had "FITC-A"
$P15N = "Comp-PE-A"       # raw FCS had "PE-A"
```

Thus the keywords written back by CyFj11 are **not** an exact copy of the original FCS TEXT. CytoML modifies parameter names when compensation is applied, and appends its own metadata.

---

## D.3 Effect of compensation on keywords and data

When `flowjo_to_gatingset()` applies compensation:

- The in-memory `cytoframe` stores **compensated, transformed** fluorescence values.
- `$PnN` keywords are rewritten to include the `Comp-` prefix for fluorescence channels.
- `$PnS` keywords (stain short names) remain unchanged.
- The `SPILL` keyword is parsed into an R matrix whose column/row names carry the `Comp-` prefix.
- `$CYT` and `$INST` are preserved verbatim if present; in test14 they are empty strings.

Population counts are computed on the compensated and transformed data. For test14, the `NK cells` count returned by `gh_pop_get_count()` was verified to match the result of manually applying `raw_fluorescence %*% solve(SPILL)` followed by the biexponential transform and the gate.

---

## D.4 Why the `SPILL` keyword is reformatted on export

CyFj11 does not modify the underlying `.fcs` file, but the internal representation of the compensation matrix inside the `GatingSet` is different from the string that FlowJo expects in the `<Keywords>` section of a v10 workspace:

| Aspect | In `GatingSet` keyword | FlowJo FCS keyword string |
|---|---|---|
| Type | `matrix` | single comma-separated `character` string |
| Channel names | `Comp-FITC-A`, `Comp-PE-A`, … | `FITC-A`, `PE-A`, … (no prefix) |
| Layout | R matrix | `n,ch1,…,chn,v11,v12,…,vnn` (row-major) |

The function `extract_spillover_matrix()` strips the `Comp-` prefix, and `format_spill_keyword()` flattens the matrix in **row-major** order, because `as.numeric()` on an R matrix uses column-major order but FlowJo stores values row by row.

For test14, the reformatted string is identical to the original workspace `SPILL` string (2003 characters). If the `Comp-` prefix were not stripped, the string would be 2058 characters long and invalid for FlowJo.

Code references:

- `R/export-flowjo10.R:2330–2376` — `extract_spillover_matrix()`
- `R/export-flowjo10.R:2387–2400` — `format_spill_keyword()`

---

## D.5 Loss of cytometer name, description, and `useTransform`

The exported workspace currently writes a hard-coded generic cytometer:

```xml
<Cytometer name="GENERIC" cyt="" useFCS3="1" ... useTransform="0" transformType="LOG" manufacturer="" serialnumber="" ... />
```

The original test14 workspace contained:

```xml
<Cytometer name="DIVA" cyt="BD FACSDiva Software Version 6.2" ... useTransform="1" transformType="BIEX" ... />
```

These attributes are **not preserved because they are not stored in the `GatingSet`**. `flowCore::keyword(gh)` contains no `DIVA`, `BD`, cytometer name, or `useTransform` entries. CytoML's C++ parser reads sample keywords, compensation matrices, and transformation definitions, but it does not parse the `<Cytometers>` node. Because CyFj11 export reconstructs the workspace entirely from the `GatingSet`, it has no source for the original cytometer metadata and falls back to a generic placeholder.

---

## D.6 Other workspace-level information that is not preserved

The following items from the original `test14_flowsom.wsp` are lost after import/export:

| Information | Original value | Exported value | Reason |
|---|---|---|---|
| Cytometer name | `DIVA` | `GENERIC` | Not parsed by CytoML |
| Cytometer description (`cyt`) | `BD FACSDiva Software Version 6.2` | empty | Not in `GatingSet` |
| `useTransform` | `1` | `0` | Not stored |
| Cytometer `transformType` | `BIEX` | `LOG` | Not stored |
| Manufacturer / serial / homepage / icon | BD-specific | generic/empty | Not stored |
| `hideCompNodes` | `1` | absent | Workspace attribute not tracked |
| `WindowPosition` | `x="884" y="67" width="600" height="720"` | hard-coded `100,100,800,600` | Hard-coded in export |
| `Graph@heatMapStatParameter` | `Comp-FITC-A` | `BUV395-A` | Hard-coded default |
| Uncompensated channel transforms | 29 transforms | 13 transforms | Only active `Comp-…` transforms + linear defaults emitted |
| `$P19N`–`$P29R` parameter slots | present | absent | Not in FCS/GatingSet |
| `FJ_FCS_VERSION` keyword | present | absent | Not in `GatingSet` |
| Original `DataSet` URI | `file:/D:/FlowSOM/inst/extdata/lymphocytes.fcs` | local `sample14.fcs` path | Re-rooted by export |
| Per-population display settings | original | generic defaults | Not stored |

What **is** preserved:

- Full population hierarchy and all gates.
- Population counts.
- Gate coordinates in transformed/compensated space.
- Compensation matrix values (via `<Matrices>` and reformatted `SPILL` keyword).
- FCS keywords such as `$FIL`, `$DATE`, `$BTIM`, `$PnS`, `GUID`, `ORIGINALGUID`.

---

## D.7 Implications for users and future work

The current pipeline guarantees faithful round-trip of **gating logic** and **population statistics**, but not of **instrument metadata** or **display state**. In most cases this is sufficient for downstream analysis in R and for returning gated populations to FlowJo. However, the hard-coded cytometer may cause problems when FlowJo uses instrument-specific defaults to interpret compensation or display scaling. The test14 result — where FlowJo re-saved the exported workspace as `DIVA` but all terminal subset counts dropped to zero — suggests that cytometer/transform interaction is a likely failure mode.

To preserve cytometer metadata in the future, CyFj11 would need to either:

1. Parse the original workspace XML separately and pass cytometer attributes into `export_flowjo10_workspace()`, or
2. Extend CytoML / `flowWorkspace` to expose the `<Cytometers>` node in the `GatingSet`.

Until then, users should be aware that exported workspaces carry a generic cytometer definition and that any workflow relying on instrument-specific settings may require manual adjustment in FlowJo after import.
