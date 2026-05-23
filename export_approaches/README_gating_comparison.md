# Gating Method Comparison Framework

This framework provides a systematic approach to compare different automated gating methods for flow cytometry data analysis.

## Overview

The framework implements wrappers for six popular gating methods:
1. `gate_mindensity()` - 1D density valley detection
2. `gate_flowclust_1d()` - 1D mixture model
3. `gate_flowclust_2d()` - 2D mixture model
4. `gate_tailgate()` - Rare population detection
5. `gate_quantile()` - Percentile cutoff
6. `deGate()` - Automated density-based gating (flowDensity package)

## Features

- **Multi-method comparison**: Test multiple gating algorithms side-by-side
- **Visual assessment**: Generate 1D histograms and 2D density plots
- **Batch processing**: Apply methods to all samples in a GatingSet
- **Flexible visualization**: Support for both 1D and 2D plotting approaches
- **Statistical summaries**: Quantitative comparison of gating results
- **Organized output**: Structured results with plots and data files

## Installation

Ensure you have the required packages installed:

```r
# Install required packages
install.packages(c("tidyverse", "ggcyto", "gridExtra", "RColorBrewer"))

# Install Bioconductor packages if needed
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("flowCore", "flowWorkspace", "openCyto", "flowDensity"))
```

## Usage

### Basic Usage

```r
# Load the framework
source("export_approaches/gating_comparison_framework.R")

# Run comparison
results <- compare_gating_methods(
  gs = your_gating_set,
  parent_pop = "root",           # Parent population path
  target_marker = "CD45RA",      # Target marker name
  methods = c("mindensity", "flowclust_1d", "quantile"),
  plot_types = c("1d", "2d"),
  output_dir = "results/gating_comparison"
)
```

### Test Script

See `test_gating_comparison.R` for a complete example using the existing GatingSet.

## Framework Components

### Main Functions

- `compare_gating_methods()` - Main orchestration function
- `create_channel_map_enhanced()` - Extended channel mapping
- Method-specific wrapper functions:
  - `apply_gate_mindensity()`
  - `apply_gate_flowclust_1d()`
  - `apply_gate_flowclust_2d()`
  - `apply_gate_tailgate()`
  - `apply_gate_quantile()`
  - `apply_deGate()`

### Visualization Functions

- Individual method plots (1D histograms, 2D density plots)
- Comparison grid plots
- Statistical summary reports

## Output Structure

```
results/gating_comparison/
├── plots/
│   ├── 1d_histograms/
│   │   ├── sample1_mindensity.png
│   │   ├── sample1_flowclust_1d.png
│   │   └── ...
│   ├── 2d_density/
│   │   ├── sample1_mindensity_2d.png
│   │   └── ...
│   └── comparison_grids/
│       ├── all_samples_marker1.png
│       └── ...
├── data/
│   ├── gating_comparison_results.rds
│   └── summary_statistics.csv
└── reports/
    └── gating_comparison_report.html (future feature)
```

## Method Details

### gate_mindensity
- **Best for**: Finding natural valleys in unimodal distributions
- **Parameters**: `gate_range`, `adjust`, `min_cutoff`
- **Reference**: Automatic gating using density valley detection

### gate_flowclust_1d
- **Best for**: Complex distributions with multiple populations
- **Parameters**: `K` (clusters), `quantile`, `target`
- **Reference**: Lo et al. (2008) Automated gating of flow cytometry data

### gate_flowclust_2d
- **Best for**: Bivariate population identification
- **Parameters**: `K`, `quantile`, `target`, `minPoints`
- **Reference**: Pyne et al. (2009) Automated high-dimensional flow

### gate_tailgate
- **Best for**: Rare event detection in distribution tails
- **Parameters**: `tol`, `quantile`, `target`
- **Reference**: Specialized for rare population identification

### gate_quantile
- **Best for**: Fixed percentile gating
- **Parameters**: `probs`, `target`, `inverse`
- **Reference**: Quantile-based thresholding

### deGate (flowDensity)
- **Best for**: Automated density-based gating
- **Parameters**: `gate_type`, `min`, `max`, `use_negatives`
- **Reference**: Farahani et al. (2020) flowDensity package

## Customization

### Adding New Methods

To add a new gating method:

1. Create a wrapper function following the pattern of existing methods
2. Add the method name to the `methods` parameter in `compare_gating_methods()`
3. Update the `switch` statement in `compare_gating_methods()` to call your function

### Parameter Tuning

Each method wrapper accepts additional parameters that are passed directly to the underlying function:

```r
results <- compare_gating_methods(
  gs = your_gating_set,
  parent_pop = "root",
  target_marker = "CD45RA",
  methods = "mindensity",
  # Method-specific parameters
  gate_range = c(100, 10000),
  adjust = 2,
  min_peak_height = 100
)
```

## Troubleshooting

### Common Issues

1. **Marker not found**: Check that the marker name exists in your channel map
2. **Method fails on specific samples**: Some methods may fail on samples with insufficient events
3. **Plot generation issues**: Ensure sufficient memory for large datasets

### Error Handling

The framework includes error handling for:
- Missing markers/channels
- Method failures on individual samples
- Invalid parameters
- File I/O issues

## Future Enhancements

Planned improvements:
- Interactive parameter tuning interface
- HTML report generation
- Additional gating methods
- Performance optimization for large datasets
- Integration with shiny for interactive exploration

## References

1. Lo, K. et al. (2008). Automated gating of flow cytometry data using robust model-based clustering. *Cytometry Part A*, 73(4), 321-332.
2. Pyne, S. et al. (2009). Automated high-dimensional flow cytometric data analysis. *PNAS*, 106(21), 8519-8524.
3. Farahani, M. et al. (2020). flowDensity: Sequential Flow Cytometry Data Gating. R package version 1.22.0.