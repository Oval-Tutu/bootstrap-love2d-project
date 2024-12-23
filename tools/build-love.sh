#!/usr/bin/env bash

PACKAGE_NAME="Game";
if [ -n "${1}" ]; then
  PACKAGE_NAME="${1}"
fi

#If $2 is set use it as the package name suffix
if [ -n "${2}" ]; then
  PACKAGE_NAME="${PACKAGE_NAME}-${2}"
fi

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
