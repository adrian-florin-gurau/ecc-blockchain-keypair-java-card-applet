#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-9025}"
LOG_LEVEL="${2:-fine}"

if [ -z "${JC_HOME_SIMULATOR:-}" ]; then
  echo "Set JC_HOME_SIMULATOR to the Oracle Java Card Development Kit Simulator directory." >&2
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
SIMULATOR="$JC_SIM_SHELL/runtime/bin/jcsw.exe"
if [ ! -f "$SIMULATOR" ]; then
  echo "Could not find simulator executable: $SIMULATOR" >&2
  exit 1
fi

echo "Starting Oracle Java Card simulator on port $PORT..."
echo "Leave this window open while running scripts-sh/run-oracle-simulator.sh."

"$SIMULATOR" "-p=$PORT" "-log_level=$LOG_LEVEL"
