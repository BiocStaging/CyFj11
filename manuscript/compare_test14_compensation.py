#!/usr/bin/env python3
"""Compare original FlowSOM test14 compensation matrix with CyFj11-exported matrix."""

import csv
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ORIG_WSP = Path("flowjo_export_tests/test14/test14_flowsom.wsp")
EXP_WSP  = Path("flowjo_export_tests/test14/test14.compensation.wsp")
OUT_CSV  = Path("manuscript/test14_compensation_elementwise.csv")
OUT_MD   = Path("manuscript/test14_compensation_elementwise.md")

NS = {
    "gating":     "http://www.isac-net.org/std/Gating-ML/v2.0/gating",
    "transforms": "http://www.isac-net.org/std/Gating-ML/v2.0/transformations",
    "data-type":  "http://www.isac-net.org/std/Gating-ML/v2.0/datatypes",
}


def parse_original_matrix(path: Path) -> tuple[list[str], dict[tuple[str, str], float]]:
    tree = ET.parse(path)
    root = tree.getroot()
    mat = root.find(".//transforms:spilloverMatrix", NS)
    params = [p.get(f"{{{NS['data-type']}}}name") for p in mat.findall("data-type:parameters/data-type:parameter", NS)]
    values = {}
    for spill in mat.findall("transforms:spillover", NS):
        row = spill.get(f"{{{NS['data-type']}}}parameter")
        for coeff in spill.findall("transforms:coefficient", NS):
            col = coeff.get(f"{{{NS['data-type']}}}parameter")
            val = float(coeff.get(f"{{{NS['transforms']}}}value"))
            values[(row, col)] = val
    return params, values


def parse_exported_matrix(path: Path) -> tuple[list[str], dict[tuple[str, str], float]]:
    """The exported file uses prefixed names but omits namespace declarations.
    Parse with regex instead of a standard XML parser."""
    text = path.read_text(encoding="utf-8")

    # Parameter order: only parameters inside the spilloverMatrix block,
    # and only the raw detector names (strip Comp- prefix if present).
    matrix_match = re.search(
        r'<transforms:spilloverMatrix[^>]*>(.*?)</transforms:spilloverMatrix>',
        text, re.DOTALL,
    )
    if not matrix_match:
        raise ValueError("No spilloverMatrix found in exported matrix")
    matrix_text = matrix_match.group(1)
    params = re.findall(
        r'<data-type:parameter\s+data-type:name="(Comp-)?([^"]+)"', matrix_text
    )
    params = [p[1] for p in params]
    if not params:
        raise ValueError("No parameters found in exported matrix")

    values = {}
    # Each <transforms:spillover data-type:parameter="..."> ... </transforms:spillover> block
    for block in re.findall(
        r'<transforms:spillover\s+data-type:parameter="([^"]+)"[^>]*>(.*?)</transforms:spillover>',
        text, re.DOTALL,
    ):
        row = block[0]
        for coeff in re.findall(
            r'<transforms:coefficient\s+data-type:parameter="([^"]+)"\s+transforms:value="([^"]+)"',
            block[1],
        ):
            col, val = coeff[0], float(coeff[1])
            values[(row, col)] = val

    return params, values


def build_matrix(params: list[str], values: dict[tuple[str, str], float]) -> list[list[float]]:
    return [[values.get((r, c), float("nan")) for c in params] for r in params]


def main():
    orig_params, orig_vals = parse_original_matrix(ORIG_WSP)
    exp_params, exp_vals = parse_exported_matrix(EXP_WSP)

    # Verify parameter sets match
    if set(orig_params) != set(exp_params):
        raise ValueError("Parameter sets differ between original and exported matrices")

    # Exported matrix uses percentages (diagonal 100); original uses proportions (diagonal 1)
    exp_vals_scaled = {k: v / 100.0 for k, v in exp_vals.items()}

    origM = build_matrix(orig_params, orig_vals)
    expM = build_matrix(orig_params, exp_vals_scaled)

    rows = []
    diffs = []
    for r in orig_params:
        for c in orig_params:
            o = orig_vals[(r, c)]
            e = exp_vals_scaled[(r, c)]
            rel = (e - o) / o if o != 0 else (0.0 if e == 0 else float("inf"))
            abs_rel = abs(rel)
            diffs.append(abs_rel)
            rows.append({
                "from": r,
                "to": c,
                "original": o,
                "exported_scaled": e,
                "absolute_difference": e - o,
                "relative_difference": rel,
                "absolute_relative_difference": abs_rel,
            })

    rows.sort(key=lambda x: x["absolute_relative_difference"], reverse=True)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    max_diff = max(diffs)
    max_row = next(r for r in rows if r["absolute_relative_difference"] == max_diff)
    mean_diff = sum(diffs) / len(diffs)
    median_diff = sorted(diffs)[len(diffs) // 2]

    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write("# Test 14 compensation matrix element-wise comparison\n\n")
        f.write(f"Original source: `{ORIG_WSP}`\n\n")
        f.write(f"Exported source: `{EXP_WSP}`\n\n")
        f.write(
            "The exported matrix stores coefficients as percentages (diagonal = 100); "
            "the original stores them as proportions (diagonal = 1). "
            "After rescaling the exported matrix by ÷100, the matrices are compared element-wise.\n\n"
        )
        f.write(f"- Matrix dimension: {len(orig_params)} × {len(orig_params)}\n")
        f.write(f"- Mean absolute relative difference: {mean_diff * 100:.6f}%\n")
        f.write(f"- Median absolute relative difference: {median_diff * 100:.6f}%\n")
        f.write(
            f"- Maximum absolute relative difference: {max_diff * 100:.6f}% "
            f"(at {max_row['from']} → {max_row['to']})\n\n"
        )

        f.write("## Largest absolute relative differences\n\n")
        f.write("| From | To | Original | Exported (scaled) | Absolute diff | Relative diff (%) |\n")
        f.write("|---|---:|---:|---:|---:|---:|\n")
        for r in rows[:20]:
            f.write(
                f"| {r['from']} | {r['to']} | {r['original']:.7f} | "
                f"{r['exported_scaled']:.7f} | {r['absolute_difference']:.7f} | "
                f"{r['relative_difference'] * 100:.6f} |\n"
            )

        f.write(f"\nFull element-wise results: `{OUT_CSV}`\n")

    print(f"Done. Max absolute relative difference: {max_diff * 100:.6f}%")


if __name__ == "__main__":
    main()
