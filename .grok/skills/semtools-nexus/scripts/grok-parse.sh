#!/bin/bash
# Thin wrapper → packaged scripts/grok-cli/parse
# Extra: --out-dir DIR prints/writes markdown paths under DIR (convenience).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
PARSE="${ROOT}/scripts/grok-cli/parse"
if [[ ! -x "$PARSE" ]]; then
  echo "grok-parse: missing $PARSE — run from a full semtools checkout" >&2
  exit 127
fi

OUT_DIR=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$OUT_DIR" ]]; then
  exec "$PARSE" "${ARGS[@]+"${ARGS[@]}"}"
fi

mkdir -p "$OUT_DIR"
# parse prints cache paths; copy into out-dir for convenience
mapfile -t paths < <("$PARSE" "${ARGS[@]+"${ARGS[@]}"}")
for p in "${paths[@]+"${paths[@]}"}"; do
  if [[ -f "$p" ]]; then
    base="$(basename "$p")"
    dest="${OUT_DIR}/${base}"
    # avoid clobbering when source already under out-dir
    if [[ "$(realpath "$p")" != "$(realpath -m "$dest")" ]]; then
      cp -f "$p" "$dest"
    fi
    echo "$dest"
  else
    echo "$p"
  fi
done
