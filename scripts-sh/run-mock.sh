#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

"$ROOT/scripts-sh/build.sh"
java -cp "$ROOT/build/host-classes" ro.ase.ism.blockchainwallet.host.HostApp --mock
