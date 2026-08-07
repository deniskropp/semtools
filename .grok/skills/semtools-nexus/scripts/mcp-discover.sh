#!/bin/bash
# mcp-discover.sh — SemTools Nexus MCP discovery helper
# Usage:
#   ./mcp-discover.sh
#   ./mcp-discover.sh github
#   ./mcp-discover.sh --doctor

set -euo pipefail

GROK_BIN="${GROK_BIN:-/home/dok/.grok/bin/grok}"
query="${1:-}"

if [[ "$query" == "--doctor" || "$query" == "doctor" ]]; then
  echo "=== grok mcp doctor ==="
  "$GROK_BIN" mcp doctor 2>&1 || true
  exit 0
fi

echo "=== grok mcp list ==="
"$GROK_BIN" mcp list 2>&1 || true

if [[ -n "$query" ]]; then
  echo
  echo "=== Suggested in-agent discovery ==="
  echo "search_tool(query=\"$query\", limit=15)"
fi

echo
echo "Reminder: In-agent discovery MUST use search_tool first, then use_tool."
echo "SemTools itself stays on the terminal (parse/search/ask/workspace)."
