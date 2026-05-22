# Bioconductor Submission - Manual Steps Required

**Created:** 2026-05-22  
**Package:** CyFj11 v0.9.3

---

## What Has Been Done

The following files have been updated/created for Bioconductor submission:

### ✅ Completed

1. **DESCRIPTION** - Updated with Bioconductor fields:
   - Added `biocViews: FlowCytometry, DataImport, DataExport, Gating, WorkspaceConversion`
   - Added `Depends: R (>= 4.0.0)`
   - Added `URL` and `BugReports`
   - Added `SystemRequirements: None`
   - Extended description

2. **README.md** - Updated installation instructions:
   - Added Bioconductor installation section
   - Kept GitHub development version instructions

3. **vignettes/getting-started.Rmd** - Updated for Bioconductor:
   - Changed output to `BiocStyle::html_document`
   - Added `%\VignettePackage{CyFj11}`

4. **inst/CITATION** - Created citation file:
   - Standard bibentry format for the manuscript

5. **BIOCONDUCTOR_SUBMISSION.md** - Created comprehensive guide:
   - Complete checklist with all requirements
   - Timeline and submission process
   - Quick start commands

---

## What Needs to Be Done Manually

### 1. Run R Checks (Requires R Installation)

```r
# Navigate to package directory
cd /pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11

# Run devtools::check() - must pass with 0 ERRORs, 0 WARNINGs
devtools::check()

# Fix any issues reported, then re-run
```

**Expected issues to address:**
- Undocumented code objects
- Namespace import/export issues
- Vignette dependencies (BiocStyle must be available)

### 2. Test Coverage Check

```r
# Install coverage package
install.packages("covr")

# Run coverage analysis
covr::package_coverage()

# Target: >= 90% coverage
# If below 90%, add tests for uncovered code paths
```

### 3. BiocCheck

```r
# Install BiocCheck
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("BiocCheck")

# Run checks
BiocCheck::BiocCheck()

# Address all issues reported
```

### 4. Update README with Badges (After Bioconductor Acceptance)

Once the package is on Bioconductor, add these badges to README.md:

```markdown
[![Bioconductor Build](https://bioconductor.org/shields/build/devel/bioc/CyFj11.svg)](https://bioconductor.org/checkResults/devel/bioc-LATEST/CyFj11/)
[![Bioconductor Dependencies](https://bioconductor.org/shields/dependencies/devel/CyFj11.svg)](https://bioconductor.org/packages/devel/bioc/html/CyFj11.html)
```

### 5. Create Export Vignette (Optional but Recommended)

The README mentions `vignette("exporting-to-flowjo")` but this file doesn't exist yet.

Create `vignettes/exporting-to-flowjo.Rmd`:

```markdown
---
title: "Exporting to FlowJo v10"
output: BiocStyle::html_document
vignette: >
  %\VignetteIndexEntry{Exporting to FlowJo v10}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
  %\VignettePackage{CyFj11}
---

# Exporting GatingSet Objects to FlowJo v10

## Introduction

This vignette demonstrates how to export GatingSet objects to FlowJo v10 workspace format.

## Basic Export

```r
library(CyFj11)
library(flowWorkspace)

# Load or create a GatingSet
gs <- ...  # Your GatingSet object

# Export to FlowJo v10 format
export_path <- "exported_workspace.wsp"
export_flowjo10_workspace(gs, export_path)

# Verify the export
file.exists(export_path)

# Open in FlowJo v11 (maintains backward compatibility with v10)
```

## Supported Gate Types

- RectangleGate (1D and 2D)
- PolygonGate
- EllipsoidGate
- BooleanGate (AND, OR, NOT)

## Supported Transformations

- Linear
- Logarithmic
- Biexponential
- Arcsinh
- Logicle

## Limitations

- Quadrant gates are not exported
- Per-sample gate variations are merged to group-level
- Log transform gate positions may show minor drift on round-trip

## Troubleshooting

### Common Issues

1. **Warning about invalid transformations**: Normal if no transformations are set
2. **FCS file path issues**: Ensure paths are absolute or relative to workspace
3. **Boolean gate errors**: Verify parent populations exist
```

### 6. Set Up Bioconductor Git Repository

Follow the official guide: https://bioconductor.org/developers/package-git-repository/

```bash
# Clone your GitHub repository
git clone git@github.com:baj12/CyFj11.git
cd CyFj11

# Add Bioconductor remote
git remote add bioc git@git.bioconductor.org:packages/CyFj11.git

# Verify remote
git remote -v

# Push to Bioconductor
git push bioc main
```

**Note:** You'll need to request a new package repository from Bioconductor first:
- Visit: https://github.com/Bioconductor/requests/issues/new/choose
- Select "New package submission"
- Fill in package details

### 7. Final Verification Before Submission

```r
# Build the package
devtools::build()

# Check the built tarball
R CMD check CyFj11_0.9.3.tar.gz

# Verify vignettes build
R CMD INSTALL --build CyFj11_0.9.3.tar.gz
```

---

## Submission Checklist

Before pushing to Bioconductor git, verify:

- [ ] `devtools::check()` passes with 0 ERRORs, 0 WARNINGs
- [ ] `covr::package_coverage()` shows >= 90% coverage
- [ ] `BiocCheck::BiocCheck()` passes all checks
- [ ] All vignettes build without errors
- [ ] All examples in documentation run without errors
- [ ] DESCRIPTION has all required Bioconductor fields
- [ ] README has proper installation instructions
- [ ] CITATION file is present
- [ ] NEWS.md is up to date
- [ ] LICENSE file is present and valid

---

## Timeline

| Week | Tasks |
|------|-------|
| 1 | Run checks, fix ERRORs and WARNINGs |
| 2 | Improve test coverage to >= 90% |
| 3 | Address BiocCheck issues, create export vignette |
| 4 | Final verification, submit to Bioconductor |
| 5-6 | Address reviewer comments |

---

## Contact Information

For Bioconductor submission questions:
- Bioconductor mailing list: bioc-devel@r-project.org
- Package submission guide: https://bioconductor.org/developers/how-to-submit/

---

*Last updated: 2026-05-22*
