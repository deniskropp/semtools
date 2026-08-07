#!/bin/bash
# semtools-doctor.sh — check Grok CLI + local search for Nexus pipelines
# Usage: ./semtools-doctor.sh

set -euo pipefail

# .grok/skills/semtools-nexus/scripts → repo root is four levels up
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

echo "=== SemTools Nexus Doctor (Grok-backed) ==="
echo "Repo root guess: $ROOT"
echo

ok=0
warn=0

have() { command -v "$1" >/dev/null 2>&1; }

resolve_grok() {
  if [[ -n "${GROK_BIN:-}" ]]; then
    echo "$GROK_BIN"
  elif have grok; then
    command -v grok
  elif [[ -x /home/dok/.grok/bin/grok ]]; then
    echo /home/dok/.grok/bin/grok
  else
    echo ""
  fi
}

echo "--- Grok CLI (parse + ask) ---"
GROK="$(resolve_grok)"
if [[ -n "$GROK" ]]; then
  echo "OK  grok: $GROK"
  "$GROK" --version 2>&1 | head -5 || true
  ok=$((ok + 1))
else
  echo "WARN  grok CLI not found — install/login Grok Build (parse/ask will fail)"
  warn=$((warn + 1))
fi

if [[ -n "${LLAMA_CLOUD_API_KEY:-}" ]]; then
  echo "INFO LLAMA_CLOUD_API_KEY is set but UNUSED by this skill (Grok replaces LlamaParse)"
fi
if [[ -n "${OPENAI_API_KEY:-}" || -n "${SEMTOOLS_OPENAI_API_KEY:-}" ]]; then
  echo "INFO OpenAI key is set but UNUSED by this skill (Grok replaces semtools ask)"
fi

echo
echo "--- Local search / workspace ---"
if have search; then
  echo "OK  search: $(command -v search)"
  ok=$((ok + 1))
elif have semtools; then
  echo "OK  semtools: $(command -v semtools) (use: semtools search …)"
  ok=$((ok + 1))
elif [[ -x "$ROOT/target/release/semtools" ]]; then
  echo "OK  release binary: $ROOT/target/release/semtools"
  ok=$((ok + 1))
elif [[ -x "$ROOT/target/debug/semtools" ]]; then
  echo "OK  debug binary: $ROOT/target/debug/semtools"
  ok=$((ok + 1))
else
  echo "WARN  search/semtools not found — cargo install semtools or npm i -g @llamaindex/semtools"
  warn=$((warn + 1))
fi

if have workspace; then
  echo "OK  workspace: $(command -v workspace)"
elif have semtools; then
  echo "OK  workspace via semtools"
fi

if have parse; then
  _parse="$(command -v parse)"
  if [[ -x /home/dok/.grok/bin/parse ]] && parse --version 2>/dev/null | grep -q grok; then
    echo "OK  parse: $_parse (Grok CLI wrapper)"
    ok=$((ok + 1))
  else
    echo "INFO parse on PATH: $_parse — prefer ~/.grok/bin/parse (Grok wrapper) over cargo LlamaParse"
  fi
fi
if have ask; then
  _ask="$(command -v ask)"
  if [[ -x /home/dok/.grok/bin/ask ]] && ask --version 2>/dev/null | grep -q grok; then
    echo "OK  ask: $_ask (Grok CLI wrapper)"
    ok=$((ok + 1))
  else
    echo "INFO ask on PATH: $_ask — prefer ~/.grok/bin/ask (Grok wrapper) over cargo OpenAI ask"
  fi
fi

echo
echo "--- Env (local only) ---"
if [[ -n "${SEMTOOLS_WORKSPACE:-}" ]]; then
  echo "OK  SEMTOOLS_WORKSPACE=$SEMTOOLS_WORKSPACE"
else
  echo "INFO SEMTOOLS_WORKSPACE not set (optional)"
fi
if [[ -n "${GROK_MODEL:-}" ]]; then
  echo "OK  GROK_MODEL=$GROK_MODEL"
fi

echo
echo "--- Caches ---"
[[ -d "$HOME/.semtools/workspaces" ]] && echo "OK  ~/.semtools/workspaces exists" || echo "INFO no workspaces yet"
[[ -d "$HOME/.parse" ]] && echo "OK  ~/.parse exists (Grok parse cache)" || echo "INFO ~/.parse not created yet"

echo
echo "--- Skill helpers ---"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for s in grok-parse.sh grok-ask.sh mcp-discover.sh; do
  if [[ -x "$SCRIPT_DIR/$s" ]]; then
    echo "OK  $s"
  elif [[ -f "$SCRIPT_DIR/$s" ]]; then
    echo "WARN  $s not executable"
    warn=$((warn + 1))
  else
    echo "WARN  missing $s"
    warn=$((warn + 1))
  fi
done

echo
echo "=== Summary: $ok ok checks, $warn warnings ==="
echo "Parse/Ask → Grok CLI | Search/Workspace → local semtools | No Llama Cloud / OpenAI required"
exit 0
