#!/usr/bin/env bash

# Create love package using act or 7z
if command -v act &>/dev/null; then
  act -j build-love
elif command -v 7z &>/dev/null; then
  # Get the PRODUCT_NAME from product.env
  PRODUCT_NAME=$(grep -E "^PRODUCT_NAME=" ./game/product.env | cut -d'"' -f2)

  # Check if PRODUCT_NAME was found
  if [ -z "${PRODUCT_NAME}" ]; then
    echo "Error: Could not find PRODUCT_NAME in game/product.env"
    exit 1
  fi

  mkdir -p "./builds/1"
  7z a -tzip -mx=6 -mpass=15 -mtc=off \
    "./builds/1/${PRODUCT_NAME}.love" \
    ./game/* \
    -xr!.gitkeep
else
  echo 'ERROR! Command not find `act` or `7z` to build the package.'
  exit 1
fi
