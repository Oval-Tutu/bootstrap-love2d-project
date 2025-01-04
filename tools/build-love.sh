#!/usr/bin/env bash

# Create love package using act or 7z
if command -v act &>/dev/null; then
  act -j build-love
elif command -v 7z &>/dev/null; then
  # Fall back to 7z if act is not available
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
  7z a -tzip -mx=6 -mpass=15 -mtc=off \
  "./builds/${PACKAGE_NAME}.love" \
  ./game/* \
  -xr!.gitkeep
else
  echo 'ERROR! Command not finf `act` or `7z` to build the package.'
  exit 1
fi
