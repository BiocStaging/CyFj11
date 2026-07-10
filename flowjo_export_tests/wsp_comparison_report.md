# FlowJo .wsp vs .llm.wsp comparison report
Generated from files under `flowjo_export_tests/`. Each `*.llm.wsp` is the same workspace after being loaded and saved in FlowJo 10.

## test01
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/test01_export.wsp` (16781 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/test01_export.llm.wsp` (17739 B)
- Added nodes: 5 | Removed nodes: 5 | Changed nodes: 7
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/test01_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/test01_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891681454'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:18 CEST 2026'` → `'Wed Jul 01 09:41:21 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afd4edec0/sample01.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/sample01.fcs`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test01_export.llm.wsp`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test01_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/test01_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/test01_export.llm.wsp`; clientTimestamp: `NA` → `1782891681454`; modDate: `Thu Jun 25 18:27:18 CEST 2026` → `Wed Jul 01 09:41:21 CEST 2026`

### Added nodes (only in .llm.wsp)
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- `/Workspace/SampleList/Sample/Transformations/log[4]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test02
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/test02_export.wsp` (19478 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/test02_export.llm.wsp` (21887 B)
- Added nodes: 11 | Removed nodes: 6 | Changed nodes: 12
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/test02_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/test02_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891702011'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:18 CEST 2026'` → `'Wed Jul 01 09:41:42 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af46d80b45/sample02.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/sample02.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404840` → `ID138441548`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404840` → `ID1512306556`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test02_export.llm.wsp`

#### `RectangleGate` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404840` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test02_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/test02_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/test02_export.llm.wsp`; clientTimestamp: `NA` → `1782891702011`; modDate: `Thu Jun 25 18:27:18 CEST 2026` → `Wed Jul 01 09:41:42 CEST 2026`

#### `dimension` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate/dimension`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `60000.000000` → `60000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `180000.000000` → `180000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `60000.000000` → `60000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `180000.000000` → `180000.0`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- `/Workspace/SampleList/Sample/Transformations/log[4]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test03
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/test03_export.wsp` (19991 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/test03_export.llm.wsp` (22285 B)
- Added nodes: 9 | Removed nodes: 4 | Changed nodes: 13
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/test03_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/test03_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891711745'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:19 CEST 2026'` → `'Wed Jul 01 09:41:51 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af2838d55c/sample03.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/sample03.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404841` → `ID787005263`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404841` → `ID1547086814`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test03_export.llm.wsp`

#### `RectangleGate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate`: percentY: `None` → `0`; percentX: `None` → `0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404841` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test03_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/test03_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/test03_export.llm.wsp`; clientTimestamp: `NA` → `1782891711745`; modDate: `Thu Jun 25 18:27:19 CEST 2026` → `Wed Jul 01 09:41:51 CEST 2026`

#### `dimension` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: yRatio: `0.5` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `40000.000000` → `40000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `130000.000000` → `130000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `40000.000000` → `40000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `130000.000000` → `130000.0`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- `/Workspace/SampleList/Sample/Transformations/log[4]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test04
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/test04_export.wsp` (22151 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/test04_export.llm.wsp` (24446 B)
- Added nodes: 9 | Removed nodes: 4 | Changed nodes: 14
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/test04_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/test04_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891721757'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:20 CEST 2026'` → `'Wed Jul 01 09:42:01 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af3a9e6cf8/sample04.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/sample04.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `ID1942175329`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `ID1977979276`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test04_export.llm.wsp`

#### `PolygonGate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/PolygonGate`: quadId: `None` → `-1`; gateResolution: `None` → `256`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/PolygonGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; quadId: `None` → `-1`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `None`; gateResolution: `None` → `256`

#### `Population` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population`: count: `7555` → `7569`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test04_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/test04_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/test04_export.llm.wsp`; clientTimestamp: `NA` → `1782891721757`; modDate: `Thu Jun 25 18:27:20 CEST 2026` → `Wed Jul 01 09:42:01 CEST 2026`

#### `coordinate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/PolygonGate/vertex[6]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `80000.000000` → `80000`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/PolygonGate/vertex[6]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `80000.000000` → `80000`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- `/Workspace/SampleList/Sample/Transformations/log[4]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test05
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/test05_export.wsp` (22465 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/test05_export.llm.wsp` (24775 B)
- Added nodes: 9 | Removed nodes: 4 | Changed nodes: 12
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/test05_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/test05_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891733656'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:20 CEST 2026'` → `'Wed Jul 01 09:42:13 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af6c4e7fd7/sample05.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/sample05.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `ID1951908901`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `ID326417881`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test05_export.llm.wsp`

#### `Population` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population`: count: `7301` → `7306`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test05_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/test05_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/test05_export.llm.wsp`; clientTimestamp: `NA` → `1782891733656`; modDate: `Thu Jun 25 18:27:20 CEST 2026` → `Wed Jul 01 09:42:13 CEST 2026`

#### `coordinate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/EllipsoidGate/edge/vertex[4]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `198.698720` → `199`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/EllipsoidGate/edge/vertex[4]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `198.698720` → `199`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- `/Workspace/SampleList/Sample/Transformations/log[4]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test06
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/test06_export.wsp` (19714 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/test06_export.llm.wsp` (21978 B)
- Added nodes: 11 | Removed nodes: 6 | Changed nodes: 13
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/test06_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/test06_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891742908'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:20 CEST 2026'` → `'Wed Jul 01 09:42:22 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af471f8d52/sample06.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/sample06.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `ID1508583984`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `ID244652499`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test06_export.llm.wsp`

#### `RectangleGate` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404842` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test06_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/test06_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/test06_export.llm.wsp`; clientTimestamp: `NA` → `1782891742908`; modDate: `Thu Jun 25 18:27:20 CEST 2026` → `Wed Jul 01 09:42:22 CEST 2026`

#### `biex` (1 changes)
- `/Workspace/SampleList/Sample/Transformations/biex`: {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length: `4096` → `256`

#### `dimension` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate/dimension`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `139.531060` → `139.53106`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `139.531060` → `139.53106`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[3]`
- `/Workspace/SampleList/Sample/Transformations/log[3]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test07
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/test07_export.wsp` (19613 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/test07_export.llm.wsp` (21878 B)
- Added nodes: 11 | Removed nodes: 8 | Changed nodes: 12
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/test07_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/test07_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891754023'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:21 CEST 2026'` → `'Wed Jul 01 09:42:34 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af6504ef38/sample07.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/sample07.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404843` → `ID1424314791`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404843` → `ID995723330`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test07_export.llm.wsp`

#### `Population` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population`: count: `3198` → `753`

#### `RectangleGate` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404843` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test07_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/test07_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/test07_export.llm.wsp`; clientTimestamp: `NA` → `1782891754023`; modDate: `Thu Jun 25 18:27:21 CEST 2026` → `Wed Jul 01 09:42:34 CEST 2026`

#### `dimension` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- `/Workspace/SampleList/Sample/Transformations/log[4]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log`
- `/Workspace/SampleList/Sample/Transformations/log/parameter`


## test08
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/test08_export.wsp` (19725 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/test08_export.llm.wsp` (22019 B)
- Added nodes: 11 | Removed nodes: 6 | Changed nodes: 12
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/test08_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/test08_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891762836'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:21 CEST 2026'` → `'Wed Jul 01 09:42:42 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afd4f651e/sample08.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/sample08.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404843` → `ID1080192776`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404843` → `ID1739137378`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test08_export.llm.wsp`

#### `RectangleGate` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404843` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test08_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/test08_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/test08_export.llm.wsp`; clientTimestamp: `NA` → `1782891762836`; modDate: `Thu Jun 25 18:27:21 CEST 2026` → `Wed Jul 01 09:42:42 CEST 2026`

#### `dimension` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`

#### `fasinh` (1 changes)
- `/Workspace/SampleList/Sample/Transformations/fasinh`: {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}M: `4` → `5.418539922`; {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length: `1` → `256`; {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}W: `-262144` → `-262144.0000000001`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[3]`
- `/Workspace/SampleList/Sample/Transformations/log[3]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test09
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/test09_export.wsp` (22413 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/test09_export.llm.wsp` (24852 B)
- Added nodes: 9 | Removed nodes: 4 | Changed nodes: 16
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/test09_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/test09_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891772557'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:22 CEST 2026'` → `'Wed Jul 01 09:42:52 CEST 2026'`

### Changed nodes (selected / grouped)

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af2729c22e/sample09.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/sample09.fcs`

#### `Gate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404844` → `ID1676474357`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404844` → `ID1038309514`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `ID1599191883`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404844` → `ID1038309514`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test09_export.llm.wsp`

#### `RectangleGate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate`: percentY: `None` → `0`; percentX: `None` → `0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404844` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test09_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/test09_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/test09_export.llm.wsp`; clientTimestamp: `NA` → `1782891772557`; modDate: `Thu Jun 25 18:27:22 CEST 2026` → `Wed Jul 01 09:42:52 CEST 2026`

#### `dimension` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: yRatio: `0.5` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `40000.000000` → `40000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `140000.000000` → `140000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `40000.000000` → `40000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `140000.000000` → `140000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `60000.000000` → `60000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `170000.000000` → `170000.0`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- `/Workspace/SampleList/Sample/Transformations/log[4]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test10
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/test10_export.wsp` (29429 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/test10_export.llm.wsp` (36184 B)
- Added nodes: 21 | Removed nodes: 6 | Changed nodes: 17
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/test10_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/test10_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891781869'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:22 CEST 2026'` → `'Wed Jul 01 09:43:01 CEST 2026'`

### Changed nodes (selected / grouped)

#### `AndNode` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/AndNode`: owningGroup: `` → `All Samples`; sortPriority: `10` → `15`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/AndNode`: sortPriority: `10` → `15`

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afa662678/sample10.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/sample10.fcs`

#### `Gate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `ID742736820`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `ID1185949440`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test10_export.llm.wsp`

#### `NotNode` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/NotNode`: owningGroup: `` → `All Samples`; sortPriority: `10` → `13`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/NotNode`: sortPriority: `10` → `13`

#### `OrNode` (1 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/OrNode`: owningGroup: `` → `All Samples`

#### `RectangleGate` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test10_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/test10_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/test10_export.llm.wsp`; clientTimestamp: `NA` → `1782891781869`; modDate: `Thu Jun 25 18:27:22 CEST 2026` → `Wed Jul 01 09:43:01 CEST 2026`

#### `dimension` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Gate/RectangleGate/dimension`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `50000.000000` → `50000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `130000.000000` → `130000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `50000.000000` → `50000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `130000.000000` → `130000.0`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/NotNode/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/NotNode/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/NotNode/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/NotNode/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/NotNode/Graph/GraphSettings`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/NotNode/Graph`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/NotNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/NotNode/Graph/GraphEnvironment`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/NotNode/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/NotNode/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[4]`
- ... and 1 more

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test11
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/test11_export.wsp` (32071 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/test11_export.llm.wsp` (34742 B)
- Added nodes: 11 | Removed nodes: 6 | Changed nodes: 23
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/test11_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/test11_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891791361'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:23 CEST 2026'` → `'Wed Jul 01 09:43:11 CEST 2026'`

### Changed nodes (selected / grouped)

#### `AndNode` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/AndNode`: sortPriority: `10` → `15`

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af3c62016d/sample11.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/sample11.fcs`

#### `Gate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `ID709285037`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `ID784081614`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404848` → `ID701403610`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404845` → `ID784081614`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test11_export.llm.wsp`

#### `PolygonGate` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Gate/PolygonGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; quadId: `None` → `-1`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404848` → `None`; gateResolution: `None` → `256`

#### `Population` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]`: count: `9478` → `9474`

#### `RectangleGate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate`: percentY: `None` → `0`; percentX: `None` → `0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404847` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test11_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/test11_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/test11_export.llm.wsp`; clientTimestamp: `NA` → `1782891791361`; modDate: `Thu Jun 25 18:27:23 CEST 2026` → `Wed Jul 01 09:43:11 CEST 2026`

#### `biex` (1 changes)
- `/Workspace/SampleList/Sample/Transformations/biex`: {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length: `4096` → `256`

#### `coordinate` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Gate/PolygonGate/vertex[6]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `85000.000000` → `85000`

#### `dimension` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: yRatio: `0.5` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `30000.000000` → `30000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `150000.000000` → `150000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `30000.000000` → `30000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `150000.000000` → `150000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `150.392573` → `139.53106`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `156149.256669` → `58002.924367`

#### `fasinh` (1 changes)
- `/Workspace/SampleList/Sample/Transformations/fasinh`: {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}M: `4` → `5.418539922`; {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length: `1` → `256`; {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}W: `-262144` → `-262144.0000000001`

#### `fcs-dimension` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Gate/RectangleGate/dimension/fcs-dimension`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}name: `APC-A` → `FITC-A`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/WindowPosition`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[2]`
- `/Workspace/SampleList/Sample/Transformations/log[2]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[3]/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test12
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/test12_export.wsp` (34163 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/test12_export.llm.wsp` (39636 B)
- Added nodes: 17 | Removed nodes: 8 | Changed nodes: 24
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/test12_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/test12_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891801427'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:23 CEST 2026'` → `'Wed Jul 01 09:43:21 CEST 2026'`

### Changed nodes (selected / grouped)

#### `AndNode` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/AndNode`: count: `2879` → `0`; sortPriority: `10` → `15`

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afb1dd131/sample12.fcs` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/sample12.fcs`

#### `Gate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404846` → `ID2145219007`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404846` → `ID550355822`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404848` → `ID599306472`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404845` → `ID872561098`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test12_export.llm.wsp`

#### `NotNode` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/NotNode`: count: `5879` → `4688`; sortPriority: `10` → `13`

#### `OrNode` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/OrNode`: count: `3886` → `5077`

#### `Population` (2 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]`: count: `9803` → `9797`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/Population[2]`: count: `3831` → `2143`

#### `RectangleGate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Gate/RectangleGate`: percentY: `None` → `0`; percentX: `None` → `0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404845` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404848` → `None`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test12_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/test12_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/test12_export.llm.wsp`; clientTimestamp: `NA` → `1782891801427`; modDate: `Thu Jun 25 18:27:23 CEST 2026` → `Wed Jul 01 09:43:21 CEST 2026`

#### `biex` (1 changes)
- `/Workspace/SampleList/Sample/Transformations/biex`: {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length: `4096` → `256`

#### `coordinate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Gate/EllipsoidGate/edge/vertex[4]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `214.809954` → `215`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Gate/EllipsoidGate/edge/vertex[4]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `214.809954` → `215`

#### `dimension` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Gate/RectangleGate/dimension[2]`: yRatio: `0.5` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `25000.000000` → `25000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `145000.000000` → `145000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `25000.000000` → `25000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `145000.000000` → `145000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `10.000000` → `10.0`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/GraphEnvironment/WindowPosition`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/NotNode/Graph`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/GraphEnvironment`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/GraphEnvironment/WindowPosition`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/Population[2]/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log[3]`
- `/Workspace/SampleList/Sample/Transformations/log[3]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population[2]/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/Population[2]/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log`
- `/Workspace/SampleList/Sample/Transformations/log/parameter`


## test13
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/test13_export.wsp` (35690 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/test13_export.llm.wsp` (39654 B)
- Added nodes: 15 | Removed nodes: 6 | Changed nodes: 30
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/test13_export.wsp'` → `'file:/Volumes/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/test13_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782828961017'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:24 CEST 2026'` → `'Tue Jun 30 16:16:01 CEST 2026'`

### Changed nodes (selected / grouped)

#### `AndNode` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/AndNode`: sortPriority: `10` → `15`

#### `Axis` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Graph/Axis[2]`: name: `PE-A` → ``

#### `DataSet` (1 changes)
- `/Workspace/SampleList/Sample/DataSet`: uri: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af6cd040c9/sample13.fcs` → `file:/Volumes/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/sample13.fcs`

#### `Gate` (4 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404846` → `ID916443811`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404846` → `ID413400572`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404848` → `ID454439191`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404846` → `ID413400572`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404850` → `ID280055102`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404847` → `ID454439191`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test13_export.llm.wsp`

#### `NotNode` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/NotNode`: sortPriority: `10` → `13`

#### `PolygonGate` (2 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/PolygonGate`: quadId: `None` → `-1`; gateResolution: `None` → `256`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/PolygonGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; quadId: `None` → `-1`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404846` → `None`; gateResolution: `None` → `256`

#### `Population` (3 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population`: count: `9939` → `9940`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]`: count: `2983` → `9470`; name: `FITC_PE_gate` → `singlets`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]`: count: `1888` → `2838`; name: `APC_pos` → `FITC_pos`

#### `RectangleGate` (2 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404847` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404850` → `None`

#### `TColumn` (1 changes)
- `/Workspace/Columns/TColumn[3]`: width: `210` → `284`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test13_export.llm.wsp`

#### `WindowPosition` (1 changes)
- `/Workspace/WindowPosition`: height: `600` → `696`; width: `800` → `1021`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/test13_export.wsp` → `file:/Volumes/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/test13_export.llm.wsp`; clientTimestamp: `NA` → `1782828961017`; modDate: `Thu Jun 25 18:27:24 CEST 2026` → `Tue Jun 30 16:16:01 CEST 2026`

#### `coordinate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/PolygonGate/vertex[6]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `148000.000000` → `148000`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/PolygonGate/vertex[6]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `148000.000000` → `148000`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Gate/EllipsoidGate/edge/vertex[4]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `315.341759` → `315`

#### `dimension` (2 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `60000.000000` → `60000.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `185000.000000` → `185000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/RectangleGate/dimension`: yRatio: `None` → `0.5`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `150.392573` → `109.923567`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `114430.005841` → `156149.256669`

#### `fasinh` (1 changes)
- `/Workspace/SampleList/Sample/Transformations/fasinh[3]`: {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}M: `4` → `5.418539922`; {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length: `1` → `256`; {http://www.isac-net.org/std/Gating-ML/v2.0/transformations}W: `-262144` → `-262144.0000000001`

#### `fcs-dimension` (1 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/RectangleGate/dimension/fcs-dimension`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}name: `APC-A` → `FITC-A`

#### `parameter` (1 changes)
- `/Workspace/SampleList/Sample/Transformations/fasinh[3]/parameter`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}name: `PE-A` → `APC-A`

### Added nodes (only in .llm.wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/NotNode/Graph`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/GraphEnvironment`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/NotNode/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Graph/Axis[2]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]`
- `/Workspace/SampleList/Sample/Transformations/linear[4]/parameter`
- `/Workspace/SampleList/Sample/Transformations/log`
- `/Workspace/SampleList/Sample/Transformations/log/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Graph/Axis`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


## test14
- Files: `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test14/test14_export.wsp` (83193 B) vs `/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test14/test14_export.llm.wsp` (83218 B)
- Added nodes: 16 | Removed nodes: 13 | Changed nodes: 36
### Workspace attribute changes
- `Workspace@nonAutoSaveFileName`: `'file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test14/test14_export.wsp'` → `'file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test14/test14_export.llm.wsp'`
- `Workspace@clientTimestamp`: `'NA'` → `'1782891818569'`
- `Workspace@modDate`: `'Thu Jun 25 18:27:25 CEST 2026'` → `'Wed Jul 01 09:43:38 CEST 2026'`

### Changed nodes (selected / grouped)

#### `Gate` (8 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404847` → `ID1816397197`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404847` → `ID985838611`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404848` → `ID569475102`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404847` → `ID985838611`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404849` → `ID1114783319`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404848` → `ID569475102`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404853` → `ID279663850`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404849` → `ID1114783319`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404855` → `ID1437192251`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404853` → `ID279663850`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404861` → `ID838419061`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404855` → `ID1437192251`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[4]/Gate`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404860` → `ID2085425942`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id: `ID1782404856` → `ID1368809169`

#### `Keyword` (1 changes)
- `/Workspace/Experiment/PlateEditorState/KeywordList/Keyword[3]`: value: `10ug/L` → `24hr`; attribute: `Treatment "Drug A"` → `Time point`

#### `Layout` (1 changes)
- `/Workspace/LayoutEditor/Layout`: outputFile: `` → `file:/Users/bernd/Layout`

#### `LayoutEditor` (1 changes)
- `/Workspace/LayoutEditor`: title: `FlowJo Layouts` → `FlowJo Layouts: test14_export.llm.wsp`

#### `PolygonGate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/PolygonGate`: quadId: `None` → `-1`; gateResolution: `None` → `256`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/PolygonGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; quadId: `None` → `-1`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404847` → `None`; gateResolution: `None` → `256`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/PolygonGate`: lineWeight: `1` → `Hairline`; percentY: `0` → `None`; percentX: `0` → `None`; quadId: `None` → `-1`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404861` → `None`; gateResolution: `None` → `256`

#### `Population` (7 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population`: count: `19225` → `19203`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population`: count: `18702` → `18680`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population`: count: `18585` → `18563`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]`: count: `17470` → `0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]`: count: `10752` → `0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]`: count: `1470` → `0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[4]`: count: `6` → `0`

#### `RectangleGate` (5 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404848` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404849` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404853` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404855` → `None`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[4]/Gate/RectangleGate`: lineWeight: `1` → `Hairline`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}id: `ID1782404860` → `None`

#### `TColumn` (1 changes)
- `/Workspace/Columns/TColumn[3]`: width: `210` → `205`

#### `Table` (1 changes)
- `/Workspace/TableEditor/Table`: outputFile: `` → `file:/Users/bernd/Table`; autoColumnName: `None` → ``

#### `TableEditor` (1 changes)
- `/Workspace/TableEditor`: title: `FlowJo Tables` → `FlowJo Tables: test14_export.llm.wsp`

#### `Workspace` (1 changes)
- `/Workspace`: nonAutoSaveFileName: `file:/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test14/test14_export.wsp` → `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test14/test14_export.llm.wsp`; clientTimestamp: `NA` → `1782891818569`; modDate: `Thu Jun 25 18:27:25 CEST 2026` → `Wed Jul 01 09:43:38 CEST 2026`

#### `coordinate` (3 changes)
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Gate/PolygonGate/vertex[12]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `36096.000000` → `36096`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Gate/PolygonGate/vertex[12]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `36096.000000` → `36096`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/PolygonGate/vertex[8]/coordinate[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value: `23745.907490` → `23745.90749`

#### `dimension` (3 changes)
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `17472.000000` → `17472.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `201536.000000` → `201536.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `1152.000000` → `1152.0`; {http://www.isac-net.org/std/Gating-ML/v2.0/gating}max: `120000.000000` → `120000.0`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Gate/RectangleGate/dimension[2]`: {http://www.isac-net.org/std/Gating-ML/v2.0/gating}min: `622.589430` → `622.58943`

### Added nodes (only in .llm.wsp)
- `/Workspace/Cytometers/Cytometer[2]`
- `/Workspace/Cytometers/Cytometer[2]/FilterParams`
- `/Workspace/Cytometers/Cytometer[2]/LinParams`
- `/Workspace/Cytometers/Cytometer[2]/LinParams/Param`
- `/Workspace/Cytometers/Cytometer[2]/LogParams`
- `/Workspace/Cytometers/Cytometer[2]/TransformStore`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/Axis[2]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphEnvironment/TextTraits[4]`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Graph/GraphSettings`
- `/Workspace/SampleList/Sample/Keywords/Keyword[248]`
- `/Workspace/SampleList/Sample/Transformations/biex[11]`
- `/Workspace/SampleList/Sample/Transformations/biex[11]/parameter`
- `/Workspace/SampleList/Sample/Transformations/linear[7]`
- `/Workspace/SampleList/Sample/Transformations/linear[7]/parameter`

### Removed nodes (only in .wsp)
- `/Workspace/Cytometers/Cytometer`
- `/Workspace/Cytometers/Cytometer/FilterParams`
- `/Workspace/Cytometers/Cytometer/LinParams`
- `/Workspace/Cytometers/Cytometer/LinParams/Param`
- `/Workspace/Cytometers/Cytometer/LogParams`
- `/Workspace/Cytometers/Cytometer/TransformStore`
- `/Workspace/Groups/GroupNode[2]/Subpopulations/Population/Subpopulations`
- `/Workspace/SampleList/Sample/Keywords/Keyword[368]`
- `/Workspace/SampleList/Sample/SampleNode/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[2]/Subpopulations/Population[4]/Subpopulations`
- `/Workspace/SampleList/Sample/Transformations/biex[12]`
- `/Workspace/SampleList/Sample/Transformations/biex[12]/parameter`
- `/Workspace/SampleList/Sample/Transformations/linear[6]`
- `/Workspace/SampleList/Sample/Transformations/linear[6]/parameter`


# Summary

## Per-test node change counts
| Test | Added | Removed | Changed |
|------|-------|---------|---------|
| test01 | 5 | 5 | 7 |
| test02 | 11 | 6 | 12 |
| test03 | 9 | 4 | 13 |
| test04 | 9 | 4 | 14 |
| test05 | 9 | 4 | 12 |
| test06 | 11 | 6 | 13 |
| test07 | 11 | 8 | 12 |
| test08 | 11 | 6 | 12 |
| test09 | 9 | 4 | 16 |
| test10 | 21 | 6 | 17 |
| test11 | 11 | 6 | 23 |
| test12 | 17 | 8 | 24 |
| test13 | 15 | 6 | 30 |
| test14 | 16 | 13 | 36 |

## Workspace root attributes that changed across tests
- `Workspace@nonAutoSaveFileName`: 14 test(s)
- `Workspace@clientTimestamp`: 14 test(s)
- `Workspace@modDate`: 14 test(s)

## Most common attribute changes by tag

### `AndNode`
- `sortPriority`: 5 test(s)
- `owningGroup`: 1 test(s)
- `count`: 1 test(s)

### `Axis`
- `name`: 1 test(s)

### `DataSet`
- `uri`: 13 test(s)

### `Gate`
- `{http://www.isac-net.org/std/Gating-ML/v2.0/gating}id`: 37 test(s)
- `{http://www.isac-net.org/std/Gating-ML/v2.0/gating}parent_id`: 11 test(s)

### `Keyword`
- `value`: 13 test(s)
- `attribute`: 13 test(s)

### `Layout`
- `outputFile`: 14 test(s)

### `LayoutEditor`
- `title`: 14 test(s)

### `NotNode`
- `sortPriority`: 4 test(s)
- `owningGroup`: 1 test(s)
- `count`: 1 test(s)

### `OrNode`
- `owningGroup`: 1 test(s)
- `count`: 1 test(s)

### `PolygonGate`
- `quadId`: 8 test(s)
- `gateResolution`: 8 test(s)
- `lineWeight`: 5 test(s)
- `percentY`: 5 test(s)
- `percentX`: 5 test(s)
- `{http://www.isac-net.org/std/Gating-ML/v2.0/gating}id`: 5 test(s)

### `Population`
- `count`: 16 test(s)
- `name`: 2 test(s)

### `RectangleGate`
- `lineWeight`: 19 test(s)
- `{http://www.isac-net.org/std/Gating-ML/v2.0/gating}id`: 19 test(s)
- `percentY`: 12 test(s)
- `percentX`: 12 test(s)

### `TColumn`
- `width`: 2 test(s)

### `Table`
- `outputFile`: 14 test(s)
- `autoColumnName`: 14 test(s)

### `TableEditor`
- `title`: 14 test(s)

### `WindowPosition`
- `height`: 1 test(s)
- `width`: 1 test(s)

### `Workspace`
- `nonAutoSaveFileName`: 14 test(s)
- `clientTimestamp`: 14 test(s)
- `modDate`: 14 test(s)

### `biex`
- `{http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length`: 3 test(s)

### `coordinate`
- `{http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}value`: 13 test(s)

### `dimension`
- `{http://www.isac-net.org/std/Gating-ML/v2.0/gating}min`: 21 test(s)
- `{http://www.isac-net.org/std/Gating-ML/v2.0/gating}max`: 19 test(s)
- `yRatio`: 12 test(s)

### `fasinh`
- `{http://www.isac-net.org/std/Gating-ML/v2.0/transformations}M`: 3 test(s)
- `{http://www.isac-net.org/std/Gating-ML/v2.0/transformations}length`: 3 test(s)
- `{http://www.isac-net.org/std/Gating-ML/v2.0/transformations}W`: 3 test(s)

### `fcs-dimension`
- `{http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}name`: 2 test(s)

### `parameter`
- `{http://www.isac-net.org/std/Gating-ML/v2.0/datatypes}name`: 1 test(s)
