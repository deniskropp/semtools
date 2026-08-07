#!/bin/bash
# grok-parse.sh — document → markdown via Grok CLI (replaces LlamaParse / semtools parse)
# Usage:
#   ./grok-parse.sh file.pdf [file2.docx ...]
#   ./grok-parse.sh --out-dir ./parsed file.pdf
# Env:
#   GROK_BIN   default: grok, then /home/dok/.grok/bin/grok
#   GROK_MODEL optional -m model id

set -euo pipefail

GROK_BIN="${GROK_BIN:-}"
if [[ -z "$GROK_BIN" ]]; then
  if command -v grok >/dev/null 2>&1; then
    GROK_BIN="$(command -v grok)"
  else
    GROK_BIN="/home/dok/.grok/bin/grok"
  fi
fi

OUT_DIR=""
files=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Usage: $0 [--out-dir DIR] <file> [file...]" >&2
  exit 1
fi

if [[ ! -x "$GROK_BIN" ]] && ! command -v "$GROK_BIN" >/dev/null 2>&1; then
  echo "ERROR: grok CLI not found at GROK_BIN=$GROK_BIN" >&2
  exit 1
fi

if [[ -n "$OUT_DIR" ]]; then
  mkdir -p "$OUT_DIR"
fi

model_args=()
if [[ -n "${GROK_MODEL:-}" ]]; then
  model_args=(-m "$GROK_MODEL")
fi

for f in "${files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "WARN: skip missing file: $f" >&2
    continue
  fi
  abs="$(realpath "$f")"
  prompt="Extract the full document content as clean markdown. Preserve structure (headings, lists, tables, code). Do not summarize — extract. File path: ${abs}. Output only the markdown body, no preamble."

  if [[ -n "$OUT_DIR" ]]; then
    base="$(basename "$f")"
    out="${OUT_DIR}/${base}.md"
    "$GROK_BIN" -p "$prompt" --tools "read_file" --yolo --output-format plain "${model_args[@]}" >"$out"
    echo "$out"
  else
    echo "===== $abs ====="
    "$GROK_BIN" -p "$prompt" --tools "read_file" --yolo --output-format plain "${model_args[@]}"
    echo
  fi
done
