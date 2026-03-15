# Specific Fixes for Each Vignette

## Getting Started Vignette (`vignettes/getting-started.Rmd`)

### Issues Identified:
1. Hardcoded file paths specific to author's system
2. Development/debugging code mixed with documentation
3. Use of `devtools::load_all()` instead of `library(CyFj11)`
4. Unexplained code chunks with development notes
5. Undefined variables in code chunks

### Specific Fixes Needed:

#### 1. Path Handling
**Problem Lines**: 207-210, 227, 255, 349
**Fix**: Replace with generic examples and add instructions for users
```r
# Instead of:
base_path <- if (file.exists("/Volumes/bernd")) "/Volumes/bernd" else "/pasteur/helix/projects/LabExMI/USERS/bernd"

# Use:
# Set your base path to the directory containing your FlowJo workspace and FCS files
base_path <- "."  # Current directory or specify your path
```

#### 2. Library Loading
**Problem Lines**: 225, 249
**Fix**: Replace `devtools::load_all()` with proper package loading
```r
# Instead of:
devtools::load_all()

# Use:
library(CyFj11)
```

#### 3. Cleanup Development Notes
**Problem Lines**: 235-239
**Fix**: Remove development notes or move to comments
```r
# Remove:
# 18.12.
# it seems to be working, but the tsne proojection is not included.
# all inconsistancies should be printed with warnings.
# gatingset seems not to be transformed
```

#### 4. Fix Undefined Variables
**Problem Lines**: 311
**Fix**: Correct variable names
```r
# Instead of:
print(groups)

# Use:
print(groups2)
```

#### 5. Improve Code Chunk Documentation
Add clear explanations for what each code chunk is doing and why.

## Advanced Usage Vignette (`vignettes/advanced-usage.Rmd`)

### Issues Identified:
1. Template code without sufficient explanation
2. Many examples marked `eval=FALSE` with no context
3. Placeholder comments instead of actual implementation
4. Incomplete examples that don't show expected results

### Specific Fixes Needed:

#### 1. Expand Explanations
**Problem Areas**: Throughout the document
**Fix**: Add detailed explanations for each section
```r
# Add before each major section:
# ## Section Name
# Brief explanation of what this section covers and why it's important
# Prerequisites: What the user should know before proceeding
```

#### 2. Provide Runnable Examples
**Problem Areas**: Sections 27-43, 50-52, 58-74, 84-90
**Fix**: Create self-contained examples with expected outputs
```r
# Instead of eval=FALSE with no output, provide:
# Example with sample data and expected results
```

#### 3. Replace Placeholders
**Problem Lines**: 130, 142, 177, 210
**Fix**: Provide actual implementation guidance or mark as advanced topics
```r
# Instead of:
# (Implementation depends on specific requirements)

# Use:
# Implementation example:
# [Actual working code example]
# This approach is useful when [specific conditions]
```

## FCS File Management Vignette (`vignettes/fcs-file-management.Rmd`)

### Issues Identified:
1. Hardcoded paths specific to author's system
2. Undefined variables in examples
3. Incomplete workflow examples
4. Setup code mixed with documentation

### Specific Fixes Needed:

#### 1. Generic Path Examples
**Problem Lines**: 22, 35, 56
**Fix**: Use relative paths and provide setup instructions
```r
# Instead of:
base_path <- "/pasteur/helix/projects/LabExMI/USERS/bernd"

# Use:
# Set your base path to the directory containing your FCS files
base_path <- "."  # Current directory or specify your path
```

#### 2. Define All Variables
**Problem Lines**: 83, 153, 180-183
**Fix**: Either define variables or provide instructions for users
```r
# Add before first use:
# Load a FlowJo v11 workspace to get dataSources and populationDefinitions
# For example:
# workspace <- read_flowjo11_workspace("path/to/your/workspace.flowjo")
# dataSources <- extract_data_sources(workspace)  # Pseudo-code - replace with actual function
# populationDefinitions <- workspace$populationDefinitions
```

#### 3. Complete Workflow Examples
**Problem Lines**: 145-189
**Fix**: Provide a complete, runnable workflow with sample data
```r
# Add a section at the beginning:
# ## Setup
# # Create sample data for demonstration
# # [Code to create or load sample data]
```

## Export Example Vignette (`vignettes/export-example.Rmd`)

### Issues Identified:
1. Almost all examples are `eval=FALSE` with no demonstration
2. Lack of concrete examples with real data
3. No expected outputs or results shown
4. Very brief explanations

### Specific Fixes Needed:

#### 1. Add Runnable Examples
**Problem Lines**: 29-32, 46-62, 85-93
**Fix**: Provide concrete examples with sample data
```r
# Add a setup section:
# ## Setup
# # Create a simple GatingSet for demonstration
# # [Code to create sample GatingSet]

# Then show actual usage:
# export_flowjo10_workspace(gs, "example_output.xml")
```

#### 2. Show Expected Outputs
Add sections showing what users can expect to see
```r
# Add:
# ## Expected Output
# # After running the export function, you should see:
# # - A new .flowjo file created
# # - Console output showing progress
# # - [Other expected results]
```

#### 3. Expand Explanations
**Problem Lines**: 34-41, 64-72, 73-80
**Fix**: Provide detailed explanations of parameters and components
```r
# Add detailed parameter explanations:
# ## Parameter Details
# # gating_set: [Detailed explanation]
# # output_path: [Detailed explanation]
# # groups: [Detailed explanation with examples]
```

## General Improvements for All Vignettes

### 1. Consistent Structure
Each vignette should follow this structure:
1. Title and introduction
2. Learning objectives
3. Prerequisites
4. Setup instructions
5. Main content with examples
6. Expected outputs/results
7. Troubleshooting tips
8. Next steps/resources

### 2. Code Quality Standards
- All code examples should be runnable
- Variables should be clearly defined
- Error handling should be demonstrated
- Best practices should be followed

### 3. User Experience Improvements
- Clear navigation between sections
- Consistent terminology
- Progressive difficulty
- Links to related functions/documentation