# Modifications to population_plot_mi.R

## Overview
This document summarizes the key modifications made to the `population_plot_mi.R` script to enhance its functionality according to the specified requirements.

## Key Modifications

### 1. Unique Short Names for Plots
- Added generation of unique short names (max 5 characters) for each plot
- Implemented naming convention using sample type and indices:
  ```r
  if(sample_type == "Innate") c1 = "I" else c1 = "A"
  c2 = which(stats$name == sample_gs)
  c3 = sample_idx
  short_name <- sprintf("%s%d:%d", c1, c2, c3)
  ```

### 2. FlowJo Count Extraction
- Added `extract_flowjo_counts()` function to retrieve cell counts from FlowJo workspace files
- Implemented `extract_all_flowjo_counts()` function to extract all counts from WSP files once and cache them:
  ```r
  # Extract all FlowJo counts once and store in a cache
  flowjo_counts_cache <- extract_all_flowjo_counts(gs_dirs = gs_dirs, flowjo_root = flowjo_root, sample_type = sample_type)
  ```

### 3. Enhanced Data Table with Comparison Metrics
- Modified the script to include FlowJo counts in the output CSV
- Added calculation of differences between FlowJo counts and R counts:
  ```r
  # Calculate difference between FlowJo count and R count
  combined_stats$count_difference <- combined_stats$flowjo_count - combined_stats$Count
  ```

### 4. Improved Plot Titles
- Enhanced plot titles to include directory names and short identifiers:
  ```r
  title_text <- sprintf("%s (%s)\nRank: %d/%d | Count: %d | ID: %s",
                        plot_info$sample,
                        plot_info$gs_name,
                        i, n_plots, plot_info$count, plot_info$short_name)
  ```

### 5. Sample Name Handling Fixes
- Corrected sample name extraction to use `pData(gs)$name` instead of `sampleNames(gs)`:
  ```r
  stats$sample_name <- pData(gs)$name
  ```

### 6. Data Integration
- Added merging of plot information with statistics:
  ```r
  # Merge with combined_stats
  if (!is.null(plot_info_df) && nrow(plot_info_df) > 0) {
    combined_stats <- merge(combined_stats, plot_info_df, by = "sample_name", all.x = TRUE)
  }
  ```

## Benefits of Modifications
1. **Unique Identifiers**: Each plot now has a unique short name for easy identification
2. **Cross-Platform Validation**: FlowJo counts are extracted and compared with R counts for validation
3. **Enhanced Debugging**: The CSV output includes all necessary information for debugging
4. **Improved Visualization**: Plot titles contain more contextual information
5. **Performance Optimization**: FlowJo count extraction is cached to avoid repeated file parsing

## Output Files
1. **PDF Files**: Containing plots with enhanced titles
2. **CSV Files**: Including short names, FlowJo counts, and count differences for debugging

These modifications ensure that the script meets all specified requirements while maintaining its existing functionality for population plotting.