#!/bin/bash

# Script to update file paths in FlowJo workspace files
# Updates DataSet URIs to use a configurable target root directory
#
# Usage:
#   TARGET_ROOT=/Volumes/scBiomarkers/bernd/cytometry/CyFl11/flowjo_export_tests ./update_paths.sh
#   or
#   ./update_paths.sh /Volumes/scBiomarkers/bernd/cytometry/CyFl11/flowjo_export_tests
#
# The script updates paths to:
#   $TARGET_ROOT/test##/sample##.fcs (or 68983.fcs for test14)

set -e

# Base directory containing the test files
BASE_DIR="/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFl11/flowjo_export_tests"

# Get target root from command line argument or environment variable
# Default to Linux path if not specified
TARGET_ROOT="${1:-$TARGET_ROOT}"
if [ -z "$TARGET_ROOT" ]; then
    TARGET_ROOT="/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFl11/flowjo_export_tests"
    echo "No TARGET_ROOT specified, using default: $TARGET_ROOT"
    echo "Usage: TARGET_ROOT=/your/path $0"
fi

echo "Updating file paths in .wsp files to use: $TARGET_ROOT"

# Update sample file paths (DataSet uri and FILENAME keyword)
for i in $(seq -w 1 14); do
    TEST_DIR="$BASE_DIR/test$i"
    if [ -d "$TEST_DIR" ]; then
        # For test14, use 68983.fcs; for others use sample#.fcs
        if [ "$i" = "14" ]; then
            FCS_FILE="68983.fcs"
        else
            FCS_FILE="sample$i.fcs"
        fi

        # Build the target path
        TARGET="$TARGET_ROOT/test$i/$FCS_FILE"

        # Update DataSet uri - replace any existing file: URI with the new target
        # Match file: followed by anything up to the file extension
        find "$TEST_DIR" -name "*.wsp" -exec sed -i \
            "s|file:[^\"]*\.fcs|$TARGET|g" {} \;

        echo "Updated test$i -> $TARGET"
    fi
done

# Update workspace file paths (nonAutoSaveFileName)
find "$BASE_DIR" -name "*.wsp" -exec sed -i \
    "s|/pasteur/helix/projects/scBiomarkers/bernd/cytometry/CyFl11/flowjo_export_tests|$TARGET_ROOT|g" {} \;

# Also handle Mac Volumes paths that may have been set previously
find "$BASE_DIR" -name "*.wsp" -exec sed -i \
    "s|/Volumes/[^/]*/bernd/cytometry/CyFl11/flowjo_export_tests|$TARGET_ROOT|g" {} \;

echo "Updated workspace paths"

# Verify the changes
echo ""
echo "Verification - checking DataSet URIs:"
grep -h "DataSet uri" "$BASE_DIR"/test*/test*.wsp | head -5

echo ""
echo "Done! All paths updated to use: $TARGET_ROOT"
echo ""
echo "To use on a different system, run:"
echo "  TARGET_ROOT=/your/custom/path $0"
