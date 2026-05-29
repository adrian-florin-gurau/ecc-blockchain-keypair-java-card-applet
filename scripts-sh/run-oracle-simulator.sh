#!/usr/bin/env bash
set -euo pipefail

TRANSACTION="bitcoin:from=alice;to=bob;amount=0.01000000;nonce=1"
PORT=9025

while [ "$#" -gt 0 ]; do
  case "$1" in
    --tx) TRANSACTION="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "${JC_HOME_SIMULATOR:-}" ]; then
  echo "Set JC_HOME_SIMULATOR to the Oracle Java Card simulator directory." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) PATH_SEP=';' ;;
  *) PATH_SEP=':' ;;
esac

to_native_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

to_shell_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  else
    printf '%s\n' "$1"
  fi
}

"$ROOT/scripts-sh/build.sh" --applet

JC_SIM_SHELL="$(to_shell_path "$JC_HOME_SIMULATOR")"
AM_SERVICE="$JC_SIM_SHELL/client/AMService/amservice.jar"
SOCKET_PROVIDER="$JC_SIM_SHELL/client/COMService/socketprovider.jar"
PROPS="$ROOT/build/oracle-simulator-client.config.properties"
MODULE_PATH="$(to_native_path "$AM_SERVICE")$PATH_SEP$(to_native_path "$SOCKET_PROVIDER")"
HOST_CLASSES="$ROOT/build/host-classes"

cat > "$PROPS" <<EOF
A000000151000000_scp03enc_01=00000000000000000000000000000000
A000000151000000_scp03mac_01=00000000000000000000000000000000
A000000151000000_scp03dek_01=00000000000000000000000000000000
EOF

javac -d "$(to_native_path "$HOST_CLASSES")" \
  -cp "$(to_native_path "$HOST_CLASSES")" \
  -p "$MODULE_PATH" \
  --add-modules ALL-MODULE-PATH \
  "$ROOT/src/host/ro/ase/ism/blockchainwallet/host/SimulatorDeployAndRun.java"

java -cp "$(to_native_path "$HOST_CLASSES")" \
  -p "$MODULE_PATH" \
  --add-modules ALL-MODULE-PATH \
  ro.ase.ism.blockchainwallet.host.SimulatorDeployAndRun \
  "--props=$(to_native_path "$PROPS")" \
  "--port=$PORT" \
  "--tx=$TRANSACTION"
