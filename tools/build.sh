#!/usr/bin/env bash

# Wrapper around act to build and extract game packages

case ${1} in
  android|html|linux|love|windows)
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

  for EXT in .AppImage -debug-signed.apk -release-signed.aab -release-signed.apk .love .tar.gz -installer.exe .exe; do
    if [ -f "builds/1/${PRODUCT_NAME}${EXT}/${PRODUCT_NAME}${EXT}.zip" ]; then
      unzip -o "builds/1/${PRODUCT_NAME}${EXT}/${PRODUCT_NAME}${EXT}.zip" -d "builds/1/${PRODUCT_NAME}${EXT}/"
      rm "builds/1/${PRODUCT_NAME}${EXT}/${PRODUCT_NAME}${EXT}.zip"
    fi
  done
else
  echo 'ERROR! Command not find `act` to build the package.'
  exit 1
fi
