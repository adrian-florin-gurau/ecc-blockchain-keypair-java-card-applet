#!/usr/bin/env bash
set -euo pipefail

KEY_VERSION_NUMBER="${1:-01}"
ENC_KEY="${2:-00000000000000000000000000000000}"
MAC_KEY="${3:-00000000000000000000000000000000}"
DEK_KEY="${4:-00000000000000000000000000000000}"

if [ -z "${JC_HOME_SIMULATOR:-}" ]; then
  echo "Set JC_HOME_SIMULATOR to the Oracle Java Card simulator directory." >&2
  exit 1
fi

to_shell_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  else
    printf '%s\n' "$1"
  fi
}

JC_SIM_SHELL="$(to_shell_path "$JC_HOME_SIMULATOR")"
CONFIGURATOR="$JC_SIM_SHELL/tools/Configurator.jar"
SIMULATOR="$JC_SIM_SHELL/runtime/bin/jcsw.exe"

if [ ! -f "$CONFIGURATOR" ]; then
  echo "Could not find Configurator.jar: $CONFIGURATOR" >&2
  exit 1
fi

if [ ! -f "$SIMULATOR" ]; then
  echo "Could not find simulator binary: $SIMULATOR" >&2
  exit 1
fi

echo "Configuring Oracle simulator SCP03 keys in:"
echo "$SIMULATOR"
echo "Stop the simulator before running this script."

java -jar "$CONFIGURATOR" \
  -binary "$SIMULATOR" \
  -SCP-keyset "$KEY_VERSION_NUMBER" "$ENC_KEY" "$MAC_KEY" "$DEK_KEY" \
  -global-pin 000000000000 03 \
  -force

echo "Simulator configured."
