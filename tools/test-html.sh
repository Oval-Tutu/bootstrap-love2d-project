#!/usr/bin/env bash

set -euo pipefail

source ./game/product.env
# Check if PRODUCT_NAME was found
if [ -z "${PRODUCT_NAME}" ]; then
  echo "Error: Could not find PRODUCT_NAME in game/product.env"
  exit 1
fi
PRODUCT_FILE="$(echo "${PRODUCT_NAME}" | tr ' ' '-')"
ZIP_FILE="builds/1/${PRODUCT_FILE}-html/${PRODUCT_FILE}-html.zip"

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

# Add cache-busting timestamp to prevent browser caching
TIMESTAMP=$(date +%s)
echo "Adding cache-busting measures for timestamp: $TIMESTAMP"
mv "$TEMP_DIR/game.love" "$TEMP_DIR/$TIMESTAMP.love"
sed -i "s/game\.love/$TIMESTAMP.love/g" "$TEMP_DIR/index.html"

echo "Starting server on http://localhost:1337"
cd "$TEMP_DIR"
miniserve \
  --header "Cross-Origin-Opener-Policy: same-origin" \
  --header "Cross-Origin-Embedder-Policy: require-corp" \
  --header "Cache-Control: no-store, no-cache, must-revalidate, max-age=0" \
  --header "Pragma: no-cache" \
  --header "Expires: 0" \
  --index index.html \
  --port 1337 \
  --verbose \
  .
