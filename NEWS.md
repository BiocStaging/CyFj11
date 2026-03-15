# CyFj11 0.1.0

* Initial release of the package
* Added functions to parse FlowJo v11 workspace files
* Implemented gate extraction functionality
* Created population extraction methods
* Added basic validation functions for gate consistency
* Included FCS file discovery and resolution utilities
* Provided export functionality for extracted data
* Fixed issue with handling multiple FCS file matches in fj11_to_gatingset() function
* Improved error handling for stop_on_multiple parameter
* Fixed "Error: 1 not found!" issue in compute_boolean_gates function
* Added support for additional gate types: spiderQuad, range, curlyQuad, quad
* Improved boolean gate conversion robustness with better error handling
* Enhanced validation for population paths in boolean gate computation