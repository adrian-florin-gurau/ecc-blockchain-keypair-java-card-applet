#!/usr/bin/env bash
set -euo pipefail

APPLET=false
for arg in "$@"; do
  case "$arg" in
    --applet|-a) APPLET=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT/build"
HOST_CLASSES="$BUILD_DIR/host-classes"
APPLET_CLASSES="$BUILD_DIR/applet-classes"
APPLET_CONFIG="$BUILD_DIR/applet-config"
APPLET_DELIVERABLES="$BUILD_DIR/applet-deliverables"

mkdir -p "$HOST_CLASSES" "$APPLET_CLASSES" "$APPLET_CONFIG" "$APPLET_DELIVERABLES"

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

echo "Compiling host application..."
mapfile -t HOST_SOURCES < <(find "$ROOT/src/host" -name '*.java' ! -name 'SimulatorDeployAndRun.java' -print)
javac -d "$(to_native_path "$HOST_CLASSES")" "${HOST_SOURCES[@]}"

if [ "$APPLET" = true ]; then
  if [ -z "${JAVACARD_HOME:-}" ]; then
    echo "Set JAVACARD_HOME to the Java Card 3.2 SDK directory before compiling the applet." >&2
    exit 1
  fi

  JC_HOME_SHELL="$(to_shell_path "$JAVACARD_HOME")"
  API_JAR="$JC_HOME_SHELL/lib/api_classic-3.2.0.jar"
  if [ ! -f "$API_JAR" ]; then
    echo "Could not find lib/api_classic-3.2.0.jar under JAVACARD_HOME." >&2
    exit 1
  fi

  echo "Compiling Java Card applet with $API_JAR..."
  mapfile -t APPLET_SOURCES < <(find "$ROOT/src/applet" -name '*.java' -print)
  javac -g -source 10 -target 10 -cp "$(to_native_path "$API_JAR")" -d "$(to_native_path "$APPLET_CLASSES")" "${APPLET_SOURCES[@]}"

  if command -v cygpath >/dev/null 2>&1 && [ -f "$JC_HOME_SHELL/bin/converter.bat" ]; then
    CONVERTER="$JC_HOME_SHELL/bin/converter.bat"
  else
    CONVERTER="$JC_HOME_SHELL/bin/converter.sh"
  fi
  if [ ! -f "$CONVERTER" ]; then
    CONVERTER="$JC_HOME_SHELL/bin/converter.bat"
  fi
  if [ ! -f "$CONVERTER" ]; then
    echo "Could not find converter.sh or converter.bat under JAVACARD_HOME/bin." >&2
    exit 1
  fi

  if [ -z "${JAVA_HOME:-}" ]; then
    JAVA_HOME="$(java -XshowSettings:properties -version 2>&1 | sed -n 's/^[[:space:]]*java\.home[[:space:]]*=[[:space:]]*//p' | head -n 1)"
    export JAVA_HOME
    echo "JAVA_HOME was not set; using $JAVA_HOME"
  fi

  CONFIG_PATH="$APPLET_CONFIG/BlockchainWalletApplet.conf"
  cat > "$CONFIG_PATH" <<EOF
-i
-classdir $(to_native_path "$APPLET_CLASSES")
-applet 0xF0:0x01:0x02:0x03:0x04:0x05:0x06 ro.ase.ism.blockchainwallet.BlockchainWalletApplet
-out CAP JCA EXP
-d $(to_native_path "$APPLET_DELIVERABLES")
-v
-debug
-target 3.2.0
ro.ase.ism.blockchainwallet
0xF0:0x01:0x02:0x03:0x04:0x05 1.0
EOF

  echo "Converting Java Card applet to CAP..."
  "$CONVERTER" -config "$(to_native_path "$CONFIG_PATH")"

  CAP_FILE="$APPLET_DELIVERABLES/ro/ase/ism/blockchainwallet/javacard/blockchainwallet.cap"
  if [ ! -f "$CAP_FILE" ]; then
    echo "Java Card converter did not produce expected CAP file: $CAP_FILE" >&2
    exit 1
  fi
fi

echo "Build completed."
