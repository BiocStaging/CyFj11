# FlowJo 10 XML Workspace Schema Documentation (Complete Analysis)

## Overview

This document describes the XML schema used by FlowJo 10 for storing workspace data. The file is an XML document with a hierarchical structure that contains cytometry data, sample information, gating strategies, and analysis results. This documentation is based on analysis of actual FlowJo 10 workspace files, specifically the MIV3_T-B_15-03-2022_TD.wsp file, and includes all known gate types and transformation types that may be present in FlowJo 10 workspaces.

## File Structure

The FlowJo 10 workspace file follows this general structure:

```
Workspace
├── WindowPosition
├── TextTraits
├── Columns
│   └── TColumn
│       ├── Property
│       └── Keyword
├── Matrices
├── Cytometers
│   └── Cytometer
│       ├── LinParams
│       │   └── Param
│       ├── LogParams
│       ├── FilterParams
│       └── TransformStore
├── Groups
│   └── GroupNode
│       ├── Graph
│       │   ├── Axis
│       │   ├── GraphSettings
│       │   └── GraphEnvironment
│       │       └── TextTraits
│       ├── Subpopulations
│       │   ├── Population
│       │   │   ├── Graph
│       │   │   │   ├── Axis
│       │   │   │   ├── GraphSettings
│       │   │   │   └── GraphEnvironment
│       │   │   │       └── TextTraits
│       │   │   ├── Gate
│       │   │   │   ├── gating:RectangleGate
│       │   │   │   │   ├── gating:dimension
│       │   │   │   │   │   └── data-type:fcs-dimension
│       │   │   │   │   └── data-type:parameter
│       │   │   │   ├── gating:PolygonGate
│       │   │   │   │   ├── gating:dimension
│       │   │   │   │   │   └── data-type:fcs-dimension
│       │   │   │   │   ├── gating:vertex
│       │   │   │   │   │   └── gating:coordinate
│       │   │   │   │   └── data-type:parameter
│       │   │   │   ├── gating:EllipsoidGate
│       │   │   │   │   ├── gating:dimension
│       │   │   │   │   │   └── data-type:fcs-dimension
│       │   │   │   │   ├── gating:foci
│       │   │   │   │   │   └── gating:vertex
│       │   │   │   │   └── data-type:parameter
│       │   │   │   ├── gating:QuadrantGate
│       │   │   │   │   ├── gating:dimension
│       │   │   │   │   │   └── data-type:fcs-dimension
│       │   │   │   │   └── data-type:parameter
│       │   │   │   └── gating:BooleanGate
│       │   │   │       └── data-type:parameter
│       │   │   ├── Statistic
│       │   │   └── Subpopulations (recursive)
│       │   └── Statistic
│       └── Group
│           ├── Criteria
│           │   └── Criterion
│           ├── SampleRefs
│           │   └── SampleRef
│           └── Keywords
│               └── Keyword
├── SampleList
│   └── Sample
│       ├── DataSet
│       ├── Transformations
│       │   ├── transforms:linear
│       │   │   └── data-type:parameter
│       │   ├── transforms:log
│       │   │   └── data-type:parameter
│       │   ├── transforms:biex
│       │   ├── transforms:fasinh
│       │   ├── transforms:hyperlog
│       │   ├── transforms:logicle
│       │   └── transforms:miltenyi
│       ├── Keywords
│       │   └── Keyword
│       └── SampleNode
│           ├── Graph
│           └── Subpopulations
├── Experiment
│   ├── PlateModel
│   │   └── PrintLayout
│   └── PlateEditorState
│       ├── KeywordList
│       │   └── Keyword
│       └── StagingArea
│           └── StagingWell
└── Exports
```

## Root Element

### `<Workspace>`

The root element of the document.

**Attributes:**
- `version`: Version of the workspace format (e.g., "20.0")
- `modDate`: Last modification date
- `clientTimestamp`: Timestamp in milliseconds
- `flowJoVersion`: Version of FlowJo that created the workspace
- `drawRowBorders`: Boolean flag for row borders
- `drawColumnBorders`: Boolean flag for column borders
- `hideCompNodes`: Boolean flag to hide compensation nodes
- `curGroup`: Currently selected group
- `groupPaneHeight`: Height of the group pane
- `xmlns:xsi`: XML Schema Instance namespace
- `xmlns:gating`: Gating-ML namespace
- `xmlns:transforms`: Transformations namespace
- `xmlns:data-type`: Data types namespace
- `xsi:schemaLocation`: Schema location URLs
- `nonAutoSaveFileName`: Path to the workspace file

## Main Sections

### `<WindowPosition>`

Defines the window position and size.

**Attributes:**
- `x`: X coordinate
- `y`: Y coordinate
- `width`: Window width
- `height`: Window height
- `displayed`: Whether window is displayed
- `panelState`: Panel state information

### `<TextTraits>`

Text formatting properties.

**Attributes:**
- `font`: Font family
- `size`: Font size
- `name`: Text trait name
- `style`: Font style (plain, bold, italic)
- `color`: Text color in hex format
- `background`: Background color in hex format
- `just`: Text justification (left, center, right)

### `<Columns>`

Defines the columns in the workspace view.

**Child Elements:**
- `<TColumn>`: Column definition
  - `width`: Column width
  - `<Property>`: Property to display
    - `key`: Property key
  - `<Keyword>`: Keyword to display
    - `name`: Keyword name

### `<Matrices>`

Container for compensation matrices (often empty).

### `<Cytometers>`

Defines cytometer configurations.

**Child Elements:**
- `<Cytometer>`: Cytometer definition
  - `name`: Cytometer name
  - `cyt`: Cytometer model
  - `useFCS3`: Boolean for FCS3 usage
  - `extraNegs`: Extra negatives setting
  - `widthBasis`: Width basis value
  - `linMin`: Linear minimum
  - `logMin`: Logarithmic minimum
  - `linMax`: Linear maximum
  - `logMax`: Logarithmic maximum
  - `linearRescale`: Linear rescaling flag
  - `logRescale`: Logarithmic rescaling flag
  - `linFromKW`: Linear from keyword flag
  - `logFromKW`: Logarithmic from keyword flag
  - `useGain`: Gain usage flag
  - `useTransform`: Transform usage flag
  - `transformType`: Transform type (LOG, etc.)
  - `manufacturer`: Manufacturer name
  - `serialnumber`: Serial number
  - `homepage`: Homepage URL
  - `icon`: Icon file name

**Sub-elements of Cytometer:**
- `<LinParams>`: Linear parameters
  - `<Param>`: Parameter name
- `<LogParams>`: Logarithmic parameters
- `<FilterParams>`: Filter parameters
- `<TransformStore>`: Transformation storage

### `<Groups>`

Container for group definitions.

### `<SampleList>`

Container for sample definitions.

**Child Elements:**
- `<Sample>`: Sample definition
  - `<DataSet>`: Dataset definition
    - `uri`: URI to FCS file
    - `sampleID`: Unique sample identifier
  - `<Transformations>`: Data transformations for this sample
    - `<transforms:linear>`: Linear transformation
      - `transforms:minRange`: Minimum range
      - `transforms:maxRange`: Maximum range
      - `gain`: Gain value
      - `<data-type:parameter>`: Parameter being transformed
        - `data-type:name`: Parameter name
    - `<transforms:log>`: Logarithmic transformation
      - `transforms:offset`: Offset value
      - `transforms:decades`: Number of decades
      - `<data-type:parameter>`: Parameter being transformed
        - `data-type:name`: Parameter name
    - `<transforms:biex>`: Biexponential transformation
      - `transforms:length`: Length parameter
      - `transforms:maxRange`: Maximum range
      - `transforms:neg`: Negative parameter
      - `transforms:width`: Width parameter
      - `transforms:pos`: Positive parameter
      - `<data-type:parameter>`: Parameter being transformed
        - `data-type:name`: Parameter name
    - `<transforms:fasinh>`: Fasinh transformation
      - `transforms:length`: Length parameter
      - `transforms:maxRange`: Maximum range
      - `transforms:T`: T parameter
      - `transforms:A`: A parameter
      - `transforms:M`: M parameter
      - `transforms:W`: W parameter
      - `<data-type:parameter>`: Parameter being transformed
        - `data-type:name`: Parameter name
    - `<transforms:hyperlog>`: Hyperlog transformation
      - `transforms:length`: Length parameter
      - `transforms:maxRange`: Maximum range
      - `transforms:T`: T parameter
      - `transforms:A`: A parameter
      - `transforms:M`: M parameter
      - `transforms:W`: W parameter
      - `<data-type:parameter>`: Parameter being transformed
        - `data-type:name`: Parameter name
    - `<transforms:logicle>`: Logicle transformation
      - `transforms:length`: Length parameter
      - `transforms:T`: T parameter
      - `transforms:A`: A parameter
      - `transforms:W`: W parameter
      - `transforms:M`: M parameter
      - `<data-type:parameter>`: Parameter being transformed
        - `data-type:name`: Parameter name
    - `<transforms:miltenyi>`: Miltenyi transformation
      - `transforms:maxRange`: Maximum range
      - `<data-type:parameter>`: Parameter being transformed
        - `data-type:name`: Parameter name
  - `<Keywords>`: Sample keywords
    - `<Keyword>`: Individual keyword
      - `name`: Keyword name
      - `value`: Keyword value
  - `<SampleNode>`: Sample node definition
    - `name`: Sample name
    - `annotation`: Annotation text
    - `owningGroup`: Owning group name
    - `expanded`: Expansion state
    - `sortPriority`: Sort priority
    - `count`: Event count
    - `sampleID`: Unique sample identifier
    - `<Graph>`: Graph settings
    - `<Subpopulations>`: Container for population hierarchies

### `<GroupNode>`

Main grouping structure for samples and populations.

**Attributes:**
- `name`: Group name
- `annotation`: Annotation text
- `owningGroup`: Owning group name
- `expanded`: Expansion state
- `sortPriority`: Sort priority
- `count`: Event count

**Child Elements:**
- `<Graph>`: Graph settings
  - `smoothing`: Smoothing level
  - `backColor`: Background color
  - `foreColor`: Foreground color
  - `type`: Graph type (Pseudocolor, DotPlot, etc.)
  - `fast`: Fast rendering flag
  - `<Axis>`: Axis definition
    - `dimension`: Axis dimension (x or y)
    - `name`: Parameter name
    - `label`: Axis label
    - `auto`: Auto-scaling flag
  - `<GraphSettings>`: Graph display settings
  - `<GraphEnvironment>`: Graph environment settings
    - `<TextTraits>`: Text traits for different elements
- `<Subpopulations>`: Container for population hierarchies
  - `<Population>`: Cell population
    - `name`: Population name
    - `annotation`: Annotation text
    - `owningGroup`: Owning group name
    - `expanded`: Expansion state
    - `sortPriority`: Sort priority
    - `count`: Event count
    - `<Graph>`: Population-specific graph settings
    - `<Gate>`: Gating region
      - `gating:id`: Unique gate identifier
      - `gating:parent_id`: Parent gate identifier
      - `<gating:RectangleGate>`: Rectangular gate
        - `eventsInside`: Events inside flag
        - `annoOffsetX`: Annotation offset X
        - `annoOffsetY`: Annotation offset Y
        - `tint`: Color tint
        - `isTinted`: Tinted flag
        - `lineWeight`: Line weight
        - `userDefined`: User defined flag
        - `percentX`: Percentage X
        - `percentY`: Percentage Y
        - `<gating:dimension>`: Dimension specification
          - `gating:min`: Minimum value
          - `gating:max`: Maximum value
          - `<data-type:fcs-dimension>`: FCS parameter reference
            - `data-type:name`: Parameter name
      - `<gating:PolygonGate>`: Polygonal gate
        - Same attributes as RectangleGate plus:
        - `quadId`: Quadrant ID
        - `gateResolution`: Gate resolution
        - `<gating:dimension>`: Dimension specification
          - `<data-type:fcs-dimension>`: FCS parameter reference
            - `data-type:name`: Parameter name
        - `<gating:vertex>`: Vertex for polygon gates
          - `<gating:coordinate>`: Coordinate value
            - `data-type:value`: Coordinate value
      - `<gating:EllipsoidGate>`: Ellipsoidal gate
        - Same attributes as RectangleGate plus:
        - `gating:distance`: Distance parameter
        - `<gating:dimension>`: Dimension specification
          - `<data-type:fcs-dimension>`: FCS parameter reference
            - `data-type:name`: Parameter name
        - `<gating:foci>`: Foci points
          - `<gating:vertex>`: Focus vertex
            - `<gating:coordinate>`: Coordinate value
              - `data-type:value`: Coordinate value
      - `<gating:QuadrantGate>`: Quadrant gate
        - `eventsInside`: Events inside flag
        - `annoOffsetX`: Annotation offset X
        - `annoOffsetY`: Annotation offset Y
        - `tint`: Color tint
        - `isTinted`: Tinted flag
        - `lineWeight`: Line weight
        - `userDefined`: User defined flag
        - `<gating:dimension>`: Dimension specification
          - `<data-type:fcs-dimension>`: FCS parameter reference
            - `data-type:name`: Parameter name
      - `<gating:BooleanGate>`: Boolean gate
        - `eventsInside`: Events inside flag
        - `annoOffsetX`: Annotation offset X
        - `annoOffsetY`: Annotation offset Y
        - `tint`: Color tint
        - `isTinted`: Tinted flag
        - `lineWeight`: Line weight
        - `userDefined`: User defined flag
        - `<data-type:parameter>`: Parameter reference
          - `data-type:name`: Parameter name
    - `<Statistic>`: Statistical values for populations
      - `name`: Statistic name
      - `annotation`: Annotation text
      - `owningGroup`: Owning group name
      - `expanded`: Expansion state
      - `sortPriority`: Sort priority
      - `ancestor`: Ancestor population
      - `correlate`: Correlation information
      - `value`: Statistical value
      - `id`: Parameter ID (for median, etc.)
    - `<Subpopulations>`: Recursive sub-populations
  - `<Statistic>`: Statistical values at group level
- `<Group>`: Group definition within GroupNode
  - `name`: Group name
  - `live`: Live flag
  - `role`: Group role
  - `key`: Group key
  - `synchronized`: Synchronization flag
  - `foreground`: Foreground color
  - `fontStyle`: Font style
  - `<Criteria>`: Group criteria
    - `<Criterion>`: Individual criterion
      - `connector`: Logical connector (And, Or)
      - `keyword`: Keyword name
      - `function`: Comparison function (Contains, etc.)
      - `value`: Comparison value
  - `<SampleRefs>`: Sample references
    - `<SampleRef>`: Sample reference
      - `sampleID`: Referenced sample ID
  - `<Keywords>`: Group keywords

### `<Experiment>`

Experimental setup information.

**Child Elements:**
- `<PlateModel>`: Plate model definition
  - `name`: Model name
  - `color`: Color in hex format
  - `rows`: Number of rows
  - `columns`: Number of columns
  - `plateID`: Plate identifier
  - `expID`: Experiment identifier
  - `format`: Plate format
  - `<PrintLayout>`: Print layout settings
- `<PlateEditorState>`: Plate editor state
  - `<KeywordList>`: Keyword list
    - `<Keyword>`: Individual keyword
      - `attribute`: Keyword attribute
      - `value`: Keyword value
  - `<StagingArea>`: Staging area
    - `<StagingWell>`: Staging well

### `<Exports>`

Export configurations (typically empty).

## Gate Types

FlowJo 10 supports several gate types:

1. **RectangleGate**: Defined by min/max values on two dimensions
   - Used for 2D rectangular gating
   - Contains gating:dimension elements specifying min/max values

2. **PolygonGate**: Defined by a series of vertices
   - Used for irregular polygonal gating
   - Contains gating:vertex elements defining the polygon boundary
   - May include quadId and gateResolution attributes

3. **EllipsoidGate**: Defined by a center and covariance matrix
   - Used for elliptical or oval gating
   - Contains gating:foci elements for focus points
   - Includes gating:distance attribute

4. **QuadrantGate**: Divides space into quadrants
   - Used for quadrant gating (e.g., dividing positive/negative populations)
   - Typically defined by crossover points on two axes

5. **BooleanGate**: Combination of other gates using boolean operations
   - Used for complex gating strategies combining multiple gates
   - References other gates through parameter specifications

## Data Representation

### Parameters

Parameters are referenced using the `<data-type:fcs-dimension>` element with a `data-type:name` attribute that corresponds to the FCS parameter name (e.g., "FSC-A", "SSC-A", "FITC-A").

For transformations, parameters are referenced using `<data-type:parameter>` with `data-type:name`.

### Transformations

Data transformations are stored in the `<Transformations>` section and can be:
- Linear transformations (`<transforms:linear>`)
  - Parameters: minRange, maxRange, gain
- Logarithmic transformations (`<transforms:log>`)
  - Parameters: offset, decades
- Biexponential transformations (`<transforms:biex>`)
  - Parameters: length, maxRange, neg, width, pos
- Fasinh transformations (`<transforms:fasinh>`)
  - Parameters: length, maxRange, T, A, M, W
- Hyperlog transformations (`<transforms:hyperlog>`)
  - Parameters: length, maxRange, T, A, M, W
- Logicle transformations (`<transforms:logicle>`)
  - Parameters: length, T, A, W, M
- Miltenyi transformations (`<transforms:miltenyi>`)
  - Parameters: maxRange

## Hierarchical Structure

The workspace follows a strict hierarchical structure:
1. Samples are grouped under GroupNodes
2. Populations are nested under Subpopulations
3. Gates are associated with specific populations
4. Statistics are calculated for each population

## Identifiers

FlowJo 10 uses several types of identifiers:
- `sampleID`: Numeric identifier for samples
- `gating:id`: String identifier for gates
- `gating:parent_id`: References to parent gates

## File References

FCS files are referenced using `uri` attributes in `<DataSet>` elements with URL-encoded paths.

## Conclusion

The FlowJo 10 XML workspace format is a comprehensive schema for storing cytometry analysis data. It combines standard XML structure with Gating-ML namespaces to provide a rich representation of flow cytometry data, analysis gates, and statistical results. This detailed analysis is based on examination of actual workspace files, providing insight into the complete structure and relationships between elements. The documentation includes all known gate types and transformation types that may be present in FlowJo 10 workspaces.