#!/bin/bash
# grok-ask.sh — Q&A over files via Grok CLI (replaces OpenAI / semtools ask)
# Usage:
#   ./grok-ask.sh "What are the main findings?" file1.md file2.md
#   ./grok-ask.sh "Summarize" --dir ./corpus
# Env:
#   GROK_BIN, GROK_MODEL, GROK_MAX_TURNS (default 24)

set -euo pipefail

GROK_BIN="${GROK_BIN:-}"
if [[ -z "$GROK_BIN" ]]; then
  if command -v grok >/dev/null 2>&1; then
    GROK_BIN="$(command -v grok)"
  else
    GROK_BIN="/home/dok/.grok/bin/grok"
  fi
fi

GROK_MAX_TURNS="${GROK_MAX_TURNS:-24}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"<question>\" [files...] [--dir DIR]" >&2
  exit 1
fi

question="$1"
shift

files=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      dir="${2:-}"
      shift 2
      if [[ -d "$dir" ]]; then
        while IFS= read -r -d '' p; do
          files+=("$p")
        done < <(find "$dir" -type f \( -name '*.md' -o -name '*.txt' -o -name '*.rst' -o -name '*.pdf' \) -print0 | head -z -n 80)
      fi
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

if [[ ! -x "$GROK_BIN" ]] && ! command -v "$GROK_BIN" >/dev/null 2>&1; then
  echo "ERROR: grok CLI not found at GROK_BIN=$GROK_BIN" >&2
  exit 1
fi

file_block=""
if [[ ${#files[@]} -gt 0 ]]; then
  file_block=$'\nFiles (read these; cite paths in the answer):\n'
  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      file_block+="- $(realpath "$f")"$'\n'
    else
      echo "WARN: missing file: $f" >&2
    fi
  done
else
  file_block=$'\nNo explicit files listed — use tools to inspect the working directory if needed.\n'
fi

prompt="You are answering a question over a document collection for SemTools Nexus.
Use only the listed files (and tool reads of those paths). Cite file paths.
If evidence is missing, say so.

Question: ${question}
${file_block}"

model_args=()
if [[ -n "${GROK_MODEL:-}" ]]; then
  model_args=(-m "$GROK_MODEL")
fi

exec "$GROK_BIN" -p "$prompt" \
  --tools "read_file,grep,list_dir" \
  --yolo \
  --max-turns "$GROK_MAX_TURNS" \
  --output-format plain \
  "${model_args[@]}"
