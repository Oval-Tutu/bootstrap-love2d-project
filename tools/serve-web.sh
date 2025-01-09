#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <zipfile>"
    exit 1
fi

ZIP_FILE="$1"

# Check if file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: File '$ZIP_FILE' does not exist"
    exit 1
fi

# Validate it's a zip file (works on both macOS and Linux)
if ! file -b "$ZIP_FILE" | grep -qi "zip"; then
    echo "Error: '$ZIP_FILE' is not a valid zip file"
    exit 1
fi

# Check for index.html in root of zip
if ! unzip -l "$ZIP_FILE" | grep -q "^.*[[:space:]]index\.html$"; then
    echo "Error: No index.html found in root of zip file"
    exit 1
fi

# Create temp directory (works on both macOS and Linux)
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'tmpdir')
trap 'rm -rf -- "$TEMP_DIR"' EXIT

echo "Extracting to temporary directory..."
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

echo "Starting server on http://localhost:1337"
cd "$TEMP_DIR"
miniserve \
    --header "Cross-Origin-Opener-Policy: same-origin" \
    --header "Cross-Origin-Embedder-Policy: require-corp" \
    --index index.html \
    --port 1337 \
    --verbose \
    .
