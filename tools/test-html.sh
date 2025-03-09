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

# Add cache-busting timestamp to prevent browser caching
TIMESTAMP=$(date +%s)
echo "Adding cache-busting measures for timestamp: $TIMESTAMP"

# Firefox-specific variables
FIREFOX_PID=""
FIREFOX_PROFILE_PATH=""

# Enhanced cleanup function to handle Firefox as well
cleanup() {
  echo "Cleaning up..."
  # Kill Firefox if running
  if [ -n "$FIREFOX_PID" ]; then
    echo "Terminating Firefox process..."
    kill $FIREFOX_PID 2>/dev/null || true
  fi

  # Remove Firefox profile if it exists
  if [ -n "$FIREFOX_PROFILE_PATH" ] && [ -d "$FIREFOX_PROFILE_PATH" ]; then
    echo "Removing temporary Firefox profile..."
    rm -rf "$FIREFOX_PROFILE_PATH"
  fi

  # Remove temp directory
  rm -rf -- "$TEMP_DIR"
}

# Set trap to clean up on exit
trap cleanup EXIT INT TERM

echo "Extracting to temporary directory..."
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

mv "$TEMP_DIR/game.love" "$TEMP_DIR/$TIMESTAMP.love"
sed -i "s/game\.love/$TIMESTAMP.love\&c=1/g" "$TEMP_DIR/index.html"

# Check if Firefox is available
if command -v firefox >/dev/null 2>&1; then
  echo "Firefox detected, creating temporary profile for testing"

  # Create a Firefox profile named with the timestamp
  FIREFOX_PROFILE_PATH="/tmp/firefox_profile_${TIMESTAMP}"
  mkdir -p "$FIREFOX_PROFILE_PATH"

  # Launch Firefox with the temporary profile
  echo "Launching Firefox with temporary profile at $FIREFOX_PROFILE_PATH"
  firefox --new-instance --profile "$FIREFOX_PROFILE_PATH" "http://localhost:1337" &
  FIREFOX_PID=$!
  echo "Firefox started with PID: $FIREFOX_PID"
fi

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
