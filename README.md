# CyFj11: Parse and Extract Data from FlowJo v11 Workspace Files

[![Bioconductor Build](https://bioconductor.org/shields/build/devel/bioc/CyFj11.svg)](https://bioconductor.org/checkresults/devel/bioc-LATEST/CyFj11/)
[![Bioconductor Dependencies](https://bioconductor.org/shields/dependencies/devel/CyFj11.svg)](https://bioconductor.org/packages/devel/bioc/html/CyFj11.html)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

The CyFj11 package provides tools to parse FlowJo v11 workspace files (.flowjo) and extract gating information, populations, and associated FCS files.

## Installation

### From Bioconductor (Development Version)

```r
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("CyFj11", version = "devel")
```

### Development Version from GitHub

```r
# install.packages("devtools")
devtools::install_github("C3BI-pasteur-fr/CyFj11")
```

## Overview

Flow cytometry data analysis often involves complex gating strategies that are stored in FlowJo workspace files. The CyFj11 package allows you to:

- Parse FlowJo v11 workspace files
- Extract gating hierarchies and populations
- Resolve associated FCS files
- Convert workspaces to GatingSet objects for advanced analysis
- Export GatingSet objects to FlowJo v10 workspace format (.xml)

## FlowJo v10 Export Support

The package provides comprehensive support for exporting GatingSet objects to FlowJo v10 workspace format:

### Supported Gate Types

- **RectangleGate**: 1D and 2D rectangular gates with min/max boundaries
- **PolygonGate**: Irregular polygonal gates defined by vertices
- **EllipsoidGate**: Elliptical gates defined by center and covariance matrix
- **BooleanGate**: Logical combinations of gates (AND, OR, NOT operations)

### Supported Transformations

- **Linear transformations** (`linearTransform`) with minRange and maxRange parameters
- **Logarithmic transformations** (`logTransform`) with offset and decades parameters
- **Biexponential transformations** (`biexTransform`) with length, maxRange, neg, width, and pos parameters
- **Arcsinh transformations** (`asinhtGml2Transform`) with length, maxRange, T, A, M, and W parameters
- **Logicle transformations** (`logicleTransform`) with length, T, A, W, and M parameters

### Export Limitations

- Quadrant gates are not currently supported in the export functionality
- Some advanced FlowJo v11 features may not translate perfectly to the v10 format
- Coordinate transformations may introduce small inaccuracies due to conversion between data and display spaces

## Vignettes

The package includes essential vignettes to help you get started:

- [Getting Started](vignettes/getting-started.Rmd) - Basic usage of the package
- [Compensation Workflow](vignettes/compensation-workflow.Rmd) - Handling compensation in flow cytometry data

## Main Functions

- `read_flowjo11_workspace()` - Main function to read and parse FlowJo v11 workspace files
- `fj11_to_gatingset()` - Convert FlowJo v11 workspace to GatingSet object (now with improved handling of multiple FCS file matches)
- `export_flowjo10_workspace()` - Export GatingSet object to FlowJo v10 workspace format
- `set_verbose()` - Enable/disable verbose output for debugging
- `get_verbose()` - Check current verbose output setting

## Example Usage

```r
library(CyFj11)

# Read a FlowJo workspace
workspace <- read_flowjo11_workspace("path/to/workspace.fjw")

# Convert to GatingSet for advanced analysis
gs <- fj11_to_gatingset(workspace, group_name = 1, path = "/path/to/fcs/files")

# Export a GatingSet to FlowJo v10 format
export_flowjo10_workspace(gs, "exported_workspace.xml")
```

## Verbose Output

The package includes a verbose mode that can be helpful for debugging and monitoring the package's operations. To enable verbose output:

```r
# Enable verbose output
set_verbose(TRUE)

# Perform operations with detailed output
ws <- read_flowjo11_workspace("path/to/workspace.fjw")
gs <- fj11_to_gatingset(ws, group_name = 1, path = "/path/to/fcs/files")

# Disable verbose output
set_verbose(FALSE)
```

When verbose mode is enabled, the package will print detailed information about:
- File processing steps
- Gate conversion progress
- Data extraction operations
- Error conditions and warnings

This can be particularly useful when troubleshooting issues with workspace parsing or FCS file resolution.

## Code of Conduct

Please note that the CyFj11 project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.
