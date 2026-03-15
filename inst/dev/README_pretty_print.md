# FlowJo Workspace Pretty Printer

This utility provides a function to extract and pretty print the JSON content from FlowJo v11 workspace files (.flowjo).

## Function

`pretty_print_flowjo()` - Takes a FlowJo workspace file and creates a pretty-printed JSON file.

## Usage

```r
# Source the function
source("pretty_print_flowjo.R")

# Pretty print a FlowJo workspace
output_file <- pretty_print_flowjo("your_workspace.flowjo")

# The function returns the path to the created file
print(output_file)  # e.g., "your_workspace_pretty.json"
```

## Features

- Extracts JSON content from compressed FlowJo v11 workspace files
- Pretty prints the JSON for human readability
- Preserves all data structure and content
- Creates output files with "_pretty.json" suffix
- Handles error cases (file not found, invalid format, etc.)

## Requirements

- R with `jsonlite` package installed
- Unix-like system with `unzip` command available
- FlowJo v11 workspace files (.flowjo)

## Example Output

The function creates a file named `[original_filename]_pretty.json` with properly formatted JSON:

```json
{
  "schemaVersion": "2.0.0",
  "analysisUUID": "20d4057e-4fdb-434a-96f4-d7db9fc7a329",
  "uri": "/path/to/analysis.json",
  "compoundParameterSets": {
    // ... formatted content
  }
  // ... more content
}
```

## Notes

- The function creates temporary files during extraction, which are automatically cleaned up
- Large FlowJo workspaces may take a moment to process due to the size of the JSON content
- The output files are significantly larger than the original compressed files due to pretty printing