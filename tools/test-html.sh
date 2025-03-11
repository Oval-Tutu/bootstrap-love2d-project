#!/usr/bin/env bash

set -euo pipefail

IP_ADDR="127.0.0.1"
IP_PORT="1337"

function cleanup() {
  echo "Cleaning up..."
  # Kill Firefox
  if [ -n "${FIREFOX_PID}" ]; then
    kill "${FIREFOX_PID}" 2>/dev/null || true
  fi
  # Remove Firefox profile if it exists
  if [ -n "${FIREFOX_PROFILE_PATH}" ] && [ -d "${FIREFOX_PROFILE_PATH}" ]; then
    rm -rf "${FIREFOX_PROFILE_PATH}"
  fi
  # Remove temp directory
  if [ -d "${TEMP_DIR}" ]; then
    rm -rf "${TEMP_DIR}"
  fi
}

# Set trap to clean up on exit
trap cleanup EXIT INT TERM

source ./game/product.env
if [ -z "${PRODUCT_NAME}" ]; then
  echo "ERROR! Could not find PRODUCT_NAME in game/product.env"
  exit 1
fi
PRODUCT_FILE="$(echo "${PRODUCT_NAME}" | tr ' ' '-')"
ZIP_FILE="builds/1/${PRODUCT_FILE}-html/${PRODUCT_FILE}-html.zip"

# Check if file exists
if [ ! -f "${ZIP_FILE}" ]; then
  echo "ERROR! ${ZIP_FILE} does not exist"
  exit 1
fi

# Validate it's a zip file (works on both macOS and Linux)
if ! file -b "${ZIP_FILE}" | grep -qi "zip"; then
  echo "ERROR! ${ZIP_FILE} is not a valid zip file"
  exit 1
fi

# Check for index.html in root of zip
if ! unzip -l "${ZIP_FILE}" | grep -q "^.*[[:space:]]index\.html$"; then
  echo "ERROR! index.html found in root of ${ZIP_FILE}"
  exit 1
fi

# Check if miniserve is available
if ! command -v miniserve >/dev/null 2>&1; then
  echo "ERROR! miniserve is not installed or not in your PATH"
  echo "       Install miniserve using cargo:"
  echo "           cargo install miniserve"
  echo "       Or download a pre-built binary from: https://github.com/svenstaro/miniserve/releases"
  exit 1
fi

# Firefox-specific variables
FIREFOX_PID=""
FIREFOX_PROFILE_PATH=""

# Create temp directory (works on both macOS and Linux)
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'tmpdir')
unzip -q "${ZIP_FILE}" -d "${TEMP_DIR}"

# Add cache-busting timestamp to prevent browser caching
TIMESTAMP=$(date +%s)
mv "${TEMP_DIR}/game.love" "${TEMP_DIR}/${TIMESTAMP}.love"
sed -i "s/game.love/${TIMESTAMP}.love/g" "${TEMP_DIR}/index.html"

# Check if Firefox is available
if command -v firefox >/dev/null 2>&1; then
  # Create Firefox temporary profile
  FIREFOX_PROFILE_PATH="${TEMP_DIR}/firefox_${TIMESTAMP}"
  mkdir -p "${FIREFOX_PROFILE_PATH}"
  # Launch Firefox with temporary profile
  echo "Firefox Profile: ${FIREFOX_PROFILE_PATH}"
  firefox --new-instance --profile "${FIREFOX_PROFILE_PATH}" "http://${IP_ADDR}:${IP_PORT}" &
  FIREFOX_PID=$!
  echo "Firefox PID:     ${FIREFOX_PID}"
fi

cd "${TEMP_DIR}"
miniserve \
  --header "Cross-Origin-Opener-Policy: same-origin" \
  --header "Cross-Origin-Embedder-Policy: require-corp" \
  --header "Cache-Control: no-store, no-cache, must-revalidate, max-age=0" \
  --header "Pragma: no-cache" \
  --header "Expires: 0" \
  --index index.html \
  --interfaces "${IP_ADDR}" \
  --port "${IP_PORT}" \
  .
