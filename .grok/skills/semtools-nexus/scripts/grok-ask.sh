#!/bin/bash
# Thin wrapper → packaged scripts/grok-cli/ask
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
ASK="${ROOT}/scripts/grok-cli/ask"
if [[ ! -x "$ASK" ]]; then
  echo "grok-ask: missing $ASK — run from a full semtools checkout" >&2
  exit 127
fi
exec "$ASK" "$@"
