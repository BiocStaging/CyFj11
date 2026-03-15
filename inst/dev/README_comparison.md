# FlowJo v11 Workspace Comparison

This package includes functionality to compare two FlowJo v11 workspace files in detail, identifying common elements and differences.

## Main Function

### `compare_flowjo_workspaces()`

Performs a comprehensive comparison of two FlowJo v11 workspace files, identifying common elements and differences. Handles UUID mapping to correctly trace corresponding elements even when UUIDs differ between files.

#### Parameters

- `workspace1`: First workspace (loaded with `read_flowjo11_workspace`)
- `workspace2`: Second workspace (loaded with `read_flowjo11_workspace`)
- `precision`: Numerical precision for comparing floating-point values (default: 4 decimal places)

#### Returns

A list containing:

- `summary`: Overall comparison statistics
- `common`: Elements that are identical between workspaces
- `differences`: Elements that differ between workspaces
- `uuid_mapping`: Mapping between UUIDs in the two workspaces

#### Example Usage

```r
# Load two FlowJo workspace files
ws1 <- read_flowjo11_workspace("experiment1.flowjo")
ws2 <- read_flowjo11_workspace("experiment2.flowjo")

# Compare the workspaces
results <- compare_flowjo_workspaces(ws1, ws2, precision = 4)

# View summary
print(results$summary)

# View common elements
print(results$common)

# View differences
print(results$differences)
```

## Features

### UUID Mapping and Tracing

The function automatically maps UUIDs between workspaces based on matching names and other identifying characteristics. This ensures that corresponding elements are correctly compared even when their UUIDs differ.

### Numerical Precision Handling

The comparison accounts for numerical precision differences by rounding values to the specified number of decimal places before comparison.

### Comprehensive Element Comparison

The function compares all major elements of FlowJo workspaces:

- **Populations**: Gate definitions, parameters, and vertices
- **Groups**: Sample groupings and membership
- **Data Sources**: FCS files and associated metadata
- **Gates**: Gate boundaries and parameters
- **Transformations**: Cytometer transformation specifications

### Hierarchical Structure Support

The comparison respects the hierarchical nature of FlowJo workspaces, correctly handling parent-child relationships between populations.

## Output Structure

The function returns a detailed comparison report with the following structure:

```r
$results$summary
├── populations
├── groups
├── dataSources
├── gates
└── transformations

$results$common
├── populations
├── groups
└── dataSources

$results$differences
├── populations
├── populations_missing_in_ws1
├── populations_missing_in_ws2
├── groups
├── groups_missing_in_ws1
├── groups_missing_in_ws2
├── dataSources
├── dataSources_missing_in_ws1
├── dataSources_missing_in_ws2
├── gates
├── gates_missing_in_ws1
├── gates_missing_in_ws2
└── transformations

$results$uuid_mapping
├── populations
├── groups
└── dataSources
```

## Testing

Unit tests for the comparison functionality are located in `tests/testthat/test-comparison.R` and can be run with:

```r
testthat::test_file("tests/testthat/test-comparison.R")