#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Source the config file relative to the script directory
source "${SCRIPT_DIR}/config.sh"

# Create love package using zip
if command -v zip &>/dev/null; then
  if [ -e "builds/${PACKAGE_NAME}.love" ]; then
    rm "builds/${PACKAGE_NAME}.love"
  fi
  (cd game && zip -9 -r "../builds/${PACKAGE_NAME}.love" . -x "*.gitkeep")
else
  echo "ERROR! Command not found: zip"
  exit 1
fi
