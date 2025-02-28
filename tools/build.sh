#!/usr/bin/env bash

# Wrapper around act to build and extract game packages

case ${1} in
  android|linux|love|windows)
    echo "Building for ${1}...";;
  *)
    echo "Usage: $0 android|linux|love|windows"
    exit 0
    ;;
esac

if command -v act &>/dev/null; then
  source ./game/product.env

  # Check if PRODUCT_NAME was found
  if [ -z "${PRODUCT_NAME}" ]; then
    echo "Error: Could not find PRODUCT_NAME in game/product.env"
    exit 1
  fi

  act -j build-${1}

  if [ "${1}" = "linux" ]; then
    # Check if the AppImage zip exists
    if [ -f "builds/1/${PRODUCT_NAME}.AppImage/${PRODUCT_NAME}.AppImage.zip" ]; then
        # Extract the AppImage zip
        unzip -o "builds/1/${PRODUCT_NAME}.AppImage/${PRODUCT_NAME}.AppImage.zip" -d "builds/1/${PRODUCT_NAME}.AppImage/"
        rm "builds/1/${PRODUCT_NAME}.AppImage/${PRODUCT_NAME}.AppImage.zip"
        echo "Successfully extracted ${PRODUCT_NAME}.AppImage.zip"
    else
        echo "Error: Could not find builds/1/${PRODUCT_NAME}.AppImage/${PRODUCT_NAME}.AppImage.zip"
        exit 1
    fi
  fi
else
  echo 'ERROR! Command not find `act` to build the package.'
  exit 1
fi
