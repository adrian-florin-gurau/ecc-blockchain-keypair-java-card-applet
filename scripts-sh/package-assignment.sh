#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 LASTNAME FIRSTNAME [ASSIGNMENT6]" >&2
  exit 2
fi

LAST_NAME="$1"
FIRST_NAME="$2"
ASSIGNMENT="${3:-ASSIGNMENT6}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ZIP_NAME="${LAST_NAME}${FIRST_NAME}SPCEQ2026${ASSIGNMENT}.zip"
ZIP_PATH="$ROOT/$ZIP_NAME"
STAGE="$ROOT/build/package"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp "$ROOT/README.md" "$STAGE/"
cp -R "$ROOT/src" "$STAGE/"
cp -R "$ROOT/scripts" "$STAGE/"
cp -R "$ROOT/scripts-sh" "$STAGE/"
cp -R "$ROOT/docs" "$STAGE/"

rm -f "$ZIP_PATH"
if command -v zip >/dev/null 2>&1; then
  (cd "$STAGE" && zip -qr "$ZIP_PATH" .)
elif command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "Compress-Archive -Path '$STAGE/*' -DestinationPath '$ZIP_PATH'"
else
  echo "Could not find zip or powershell.exe to create the archive." >&2
  exit 1
fi

echo "Created $ZIP_PATH"
