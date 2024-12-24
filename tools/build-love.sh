#!/usr/bin/env bash

PACKAGE_NAME="Game";
# If $1 is set use it as the package name
if [ -n "${1}" ]; then
  PACKAGE_NAME="${1}"
fi

# If $2 is set use it as the package name suffix
if [ -n "${2}" ]; then
  PACKAGE_NAME="${PACKAGE_NAME}-${2}"
else
  PACKAGE_NAME="${PACKAGE_NAME}-$(date +%y.%j.%H%M)"
fi

# Create love package using zip
if command -v 7z &>/dev/null; then
  7z a -tzip ./builds/"${PACKAGE_NAME}.love" ./game/* -xr!.gitkeep
else
  echo "ERROR! Command not found: 7z"
  exit 1
fi
