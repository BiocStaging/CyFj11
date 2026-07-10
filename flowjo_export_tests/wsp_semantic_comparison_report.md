# Semantic comparison: .wsp vs .llm.wsp

This report focuses on meaningful changes: transformations, population names/counts, gate IDs, and data file paths.

## test01

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afd4edec0/sample01.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test01/sample01.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.7971982698'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2668664412'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '234310.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '234310', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '251048.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '251048', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.0450881615'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.0932114918'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '154561.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '154561', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '166940.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '166940', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

## test02

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af46d80b45/sample02.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test02/sample02.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.9618954737'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1724569744'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '226198.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '226198', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '239384.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '239384', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1009216803'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2914354549'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '153928.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '153928', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '160534.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '160534', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

## test03

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af2838d55c/sample03.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test03/sample03.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.8513195126'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2200819249'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '225580.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '225580', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '242320.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '242320', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1797815158'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1106906973'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '150962.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '150962', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '158728.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '158728', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

## test04

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af3a9e6cf8/sample04.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test04/sample04.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.8609366207'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1595671932'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '222261.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '222261', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '232822.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '232822', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1441381377'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1933750806'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '154866.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '154866', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '164469.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '164469', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

### Sample ? populations
- **~** `/singlets`: count 7555 → 7569, gate_id ID1782404842 → ID1977979276

## test05

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af6c4e7fd7/sample05.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test05/sample05.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.9585161034'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1532659351'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '228108.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '228108', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '240621.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '240621', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2225343934'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1529606743'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '150483.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '150483', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '160992.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '160992', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

### Sample ? populations
- **~** `/ellipse_cells`: count 7301 → 7306, gate_id ID1782404842 → ID326417881

## test06

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af471f8d52/sample06.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test06/sample06.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.7470231775'}}`
- **FITC-A**: `{'type': 'biex', 'attrs': {'length': '4096', 'maxRange': '262144', 'neg': '0', 'width': '-10', 'pos': '4.5'}}` → `{'type': 'biex', 'attrs': {'length': '256', 'maxRange': '262144', 'neg': '0', 'width': '-10', 'pos': '4.5'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '252082.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '252082', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262145.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262145', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1143440546'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1863346633'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '146096.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '146096', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '156645.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '156645', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

## test07

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af6504ef38/sample07.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test07/sample07.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.9703933721'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2367135634'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '233756.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '233756', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '231479.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '231479', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1127390224'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '152936.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '152936', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '158127.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '158127', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

### Sample ? populations
- **~** `/PE_pos`: count 3198 → 753, gate_id ID1782404843 → ID995723330

## test08

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afd4f651e/sample08.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test08/sample08.fcs`

### Transformations per parameter
- **APC-A**: `{'type': 'fasinh', 'attrs': {'length': '1', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '4', 'W': '-262144'}}` → `{'type': 'fasinh', 'attrs': {'length': '256', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '5.418539922', 'W': '-262144.0000000001'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2242221861'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '235445.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '235445', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '256392.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '256392', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1144108024'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1589953768'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '155908.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '155908', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '157406.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '157406', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

## test09

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af2729c22e/sample09.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test09/sample09.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.8600983297'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2156111296'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '233801.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '233801', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '240022.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '240022', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1124374173'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2513705055'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '154630.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '154630', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '159735.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '159735', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

## test10

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afa662678/sample10.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test10/sample10.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.8689969025'}}`
- **+ FITC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.1528995964'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '234379.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '234379', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '247057.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '247057', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.0792898061'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.27485032'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '151198.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '151198', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '162584.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '162584', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

## test11

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af3c62016d/sample11.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test11/sample11.fcs`

### Transformations per parameter
- **APC-A**: `{'type': 'fasinh', 'attrs': {'length': '1', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '4', 'W': '-262144'}}` → `{'type': 'fasinh', 'attrs': {'length': '256', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '5.418539922', 'W': '-262144.0000000001'}}`
- **FITC-A**: `{'type': 'biex', 'attrs': {'length': '4096', 'maxRange': '262144', 'neg': '0', 'width': '-10', 'pos': '4.5'}}` → `{'type': 'biex', 'attrs': {'length': '256', 'maxRange': '262144', 'neg': '0', 'width': '-10', 'pos': '4.5'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '230992.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '230992', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '245109.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '245109', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PE-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2159546439'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.3147728126'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '154669.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '154669', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '155163.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '155163', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

### Sample ? populations
- **~** `/cells/singlets`: count 9478 → 9474, gate_id ID1782404848 → ID701403610

## test12

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002afb1dd131/sample12.fcs`
- LLM:      `file:/System/Volumes/Data/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test12/sample12.fcs`

### Transformations per parameter
- **+ APC-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '3.8596185788'}}`
- **FITC-A**: `{'type': 'biex', 'attrs': {'length': '4096', 'maxRange': '262144', 'neg': '0', 'width': '-10', 'pos': '4.5'}}` → `{'type': 'biex', 'attrs': {'length': '256', 'maxRange': '262144', 'neg': '0', 'width': '-10', 'pos': '4.5'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '219851.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '219851', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '233747.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '233747', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2878241157'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '153329.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '153329', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '158365.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '158365', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

### Sample ? populations
- **~** `/cells/PE_hi`: count 3831 → 2143, gate_id ID1782404848 → ID599306472
- **~** `/scatter_ellipse`: count 9803 → 9797, gate_id ID1782404846 → ID550355822

## test13

### Data file URI
- Original: `file:/pasteur/helix/scratch/bernd/Rtmp/Rtmpel7rVw/file3002af6cd040c9/sample13.fcs`
- LLM:      `file:/Volumes/scBiomarkers/bernd/cytometry/CyFj11/flowjo_export_tests/test13/sample13.fcs`

### Transformations per parameter
- **APC-A**: `{'type': 'fasinh', 'attrs': {'length': '1', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '4', 'W': '-262144'}}` → `{'type': 'fasinh', 'attrs': {'length': '256', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '5.418539922', 'W': '-262144.0000000001'}}`
- **FITC-A**: `{'type': 'fasinh', 'attrs': {'length': '1', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '4', 'W': '-262144'}}` → `{'type': 'fasinh', 'attrs': {'length': '256', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '5.418539922', 'W': '-262144.0000000001'}}`
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '228743.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '228743', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '249113.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '249113', 'gain': '1'}}`
- **- FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`
- **PE-A**: `{'type': 'fasinh', 'attrs': {'length': '1', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '4', 'W': '-262144'}}` → `{'type': 'fasinh', 'attrs': {'length': '256', 'maxRange': '262144', 'T': '262144', 'A': '0', 'M': '5.418539922', 'W': '-262144.0000000001'}}`
- **+ PerCP-Cy5-5-A**: `{'type': 'log', 'attrs': {'offset': '1', 'decades': '4.2546930594'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '151206.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '151206', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '156369.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '156369', 'gain': '1'}}`
- **- SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}`

### Sample ? populations
- **~** `/live`: count 9939 → 9940, gate_id ID1782404846 → ID413400572
- **~** `/live/FITC_PE_gate`: count 2983 → 9940, gate_id ID1782404848 → ID617642577

## test14

### Transformations per parameter
- **FSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262144', 'gain': '1'}}`
- **FSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262144', 'gain': '1'}}`
- **FSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262144', 'gain': '1'}}`
- **SSC-A**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262144', 'gain': '1'}}`
- **SSC-H**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262144', 'gain': '1'}}`
- **SSC-W**: `{'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '262144.0', 'gain': '1'}}` → `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262144', 'gain': '1'}}`
- **+ Time**: `{'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '262144', 'gain': '1'}}`

### Sample ? populations
- **~** `/Lymphocytes`: count 19225 → 19203, gate_id ID1782404847 → ID985838611
- **~** `/Lymphocytes/Singlets`: count 18702 → 18680, gate_id ID1782404848 → ID569475102
- **~** `/Lymphocytes/Singlets/Singlets2`: count 18585 → 18563, gate_id ID1782404849 → ID1114783319
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1+`: count 923 → 0, gate_id ID1782404850 → ID468323630
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1+/NK T cells`: count 535 → 0, gate_id ID1782404852 → ID1907605457
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1+/NK cells`: count 312 → 0, gate_id ID1782404851 → ID1391545896
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-`: count 17470 → 0, gate_id ID1782404853 → ID279663850
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/B cells`: count 2460 → 0, gate_id ID1782404854 → ID2116351724
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/T cells`: count 10752 → 0, gate_id ID1782404855 → ID1437192251
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/T cells/ab T cells`: count 9196 → 0, gate_id ID1782404856 → ID1368809169
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/T cells/ab T cells/CD4 T cells`: count 7487 → 0, gate_id ID1782404857 → ID1003064905
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/T cells/ab T cells/CD8 T cells`: count 1407 → 0, gate_id ID1782404858 → ID386378288
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/T cells/ab T cells/DN T cells`: count 267 → 0, gate_id ID1782404859 → ID1403770327
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/T cells/ab T cells/DP T cells`: count 6 → 0, gate_id ID1782404860 → ID2085425942
- **~** `/Lymphocytes/Singlets/Singlets2/NK1_1-/T cells/gd T cells`: count 1470 → 0, gate_id ID1782404861 → ID838419061


# Cross-test summary

## Transformation changes
- `added:linear`: 1 occurrences
  - ('test14', 'Time')
- `added:log`: 42 occurrences
  - ('test01', 'APC-A')
  - ('test01', 'FITC-A')
  - ('test01', 'PE-A')
  - ('test01', 'PerCP-Cy5-5-A')
  - ('test02', 'APC-A')
  - ('test02', 'FITC-A')
  - ('test02', 'PE-A')
  - ('test02', 'PerCP-Cy5-5-A')
  - ('test03', 'APC-A')
  - ('test03', 'FITC-A')
  - ... and 32 more
- `changed`: 66 occurrences
  - ('test01', 'FSC-A', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '234310.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '234310', 'gain': '1'}})
  - ('test01', 'FSC-H', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '251048.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '251048', 'gain': '1'}})
  - ('test01', 'SSC-A', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '154561.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '154561', 'gain': '1'}})
  - ('test01', 'SSC-H', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '166940.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '166940', 'gain': '1'}})
  - ('test02', 'FSC-A', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '226198.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '226198', 'gain': '1'}})
  - ('test02', 'FSC-H', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '239384.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '239384', 'gain': '1'}})
  - ('test02', 'SSC-A', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '153928.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '153928', 'gain': '1'}})
  - ('test02', 'SSC-H', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '160534.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '160534', 'gain': '1'}})
  - ('test03', 'FSC-A', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '225580.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '225580', 'gain': '1'}})
  - ('test03', 'FSC-H', {'type': 'linear', 'attrs': {'minRange': '0.0', 'maxRange': '242320.0', 'gain': '1'}}, {'type': 'linear', 'attrs': {'minRange': '0', 'maxRange': '242320', 'gain': '1'}})
  - ... and 56 more
- `removed:linear`: 26 occurrences
  - ('test01', 'FSC-W')
  - ('test01', 'SSC-W')
  - ('test02', 'FSC-W')
  - ('test02', 'SSC-W')
  - ('test03', 'FSC-W')
  - ('test03', 'SSC-W')
  - ('test04', 'FSC-W')
  - ('test04', 'SSC-W')
  - ('test05', 'FSC-W')
  - ('test05', 'SSC-W')
  - ... and 16 more

## Population changes
- Added: 0
- Removed: 0
- Changed (count/name/gate_id): 23

Per test:
- test04: 1 population changes
- test05: 1 population changes
- test07: 1 population changes
- test11: 1 population changes
- test12: 2 population changes
- test13: 2 population changes
- test14: 15 population changes
