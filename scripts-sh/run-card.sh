#!/usr/bin/env bash
set -euo pipefail

TRANSACTION="${1:-bitcoin:from=alice;to=bob;amount=0.01000000;nonce=1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

"$ROOT/scripts-sh/build.sh"
java -cp "$ROOT/build/host-classes" ro.ase.ism.blockchainwallet.host.HostApp --card "$TRANSACTION"
