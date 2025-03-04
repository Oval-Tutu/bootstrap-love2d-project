#!/usr/bin/env bash

# Wrapper around act to build and extract game packages

case ${1} in
  android | html | linux | love | windows)
    echo "Building for ${1}..."
    ;;
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
  PRODUCT_FILE="$(echo "${PRODUCT_NAME}" | tr ' ' '-')"

  act -j build-${1}

  for EXT in .AppImage -debug-signed.apk -release-signed.aab -release-signed.apk .love .tar.gz -installer.exe .exe; do
    echo "Checking for ${PRODUCT_FILE}${EXT}..."
    if [ -f "builds/1/${PRODUCT_FILE}${EXT}/${PRODUCT_FILE}${EXT}.zip" ]; then
      unzip -o "builds/1/${PRODUCT_FILE}${EXT}/${PRODUCT_FILE}${EXT}.zip" -d "builds/1/${PRODUCT_FILE}${EXT}/"
      rm "builds/1/${PRODUCT_FILE}${EXT}/${PRODUCT_FILE}${EXT}.zip"
      # Extract .tar.gz for SteamOS DevKit integration
      if [ -f "builds/1/${PRODUCT_FILE}${EXT}/${PRODUCT_FILE}.tar.gz" ]; then
        tar -xzf "builds/1/${PRODUCT_FILE}${EXT}/${PRODUCT_FILE}.tar.gz" -C "builds/1/${PRODUCT_FILE}${EXT}/"
        rm "builds/1/${PRODUCT_FILE}${EXT}/${PRODUCT_FILE}.tar.gz"
        # Test if localhost:32010 is available
        if nc -z localhost 32010; then

          # Create JSON notify for SteamOS DevKit
          cat <<EOF >notify.json
{
    "type": "build",
    "status": "success",
    "name": "${PRODUCT_FILE}"
}
EOF
          curl --header "Content-Type: application/json" \
            --request POST http://localhost:32010/post_event \
            -d @notify.json
          rm notify.json
        fi
      fi
    fi
  done
else
  echo 'ERROR! Command not find `act` to build the package.'
  exit 1
fi
