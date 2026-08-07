# MCP Integration — SemTools Nexus (Grok CLI)

## Discovery (always first in-agent)

1. `search_tool(query="github create issue")` (or drive, gmail, …)
2. Read `input_schema`
3. `use_tool(tool_name="github__…", tool_input={…})`

CLI:

```bash
.grok/skills/semtools-nexus/scripts/mcp-discover.sh
.grok/skills/semtools-nexus/scripts/mcp-discover.sh "github|drive|gmail"
```

## Typical chains (Grok + local search + MCP)

### 1. Corpus Q&A → GitHub issue

```text
grok-parse.sh docs/*.pdf          # Grok CLI, not LlamaParse
search "open problems" …          # local
grok-ask.sh "List TODOs / risks" …  # Grok CLI, not OpenAI
→ search_tool github create issue
→ use_tool … (confirm with user first)
```

### 2. Summary → Google Drive

```text
grok-ask.sh "Executive summary" corpus/*.md > /tmp/summary.md
→ Drive upload via MCP (base64 only in shell, never in chat)
```

### 3. Search hits → PR comment

```text
search "authentication" src/**/*.md --top-k 15
→ format markdown
→ GitHub PR comment tool
```

## File upload rule

Never load large base64 into model context; expand only inside the shell that calls MCP.

## Failure modes

| Symptom | Action |
|---------|--------|
| `grok` missing / auth fail | Fix Grok CLI install/login; do not fall back to OpenAI or Llama Cloud |
| Empty search_tool | Continue CLI-only (search + grok) |
| Hugging Face MCP Auth | Skip HF; local embeddings + Grok still work |

## Related

- Parent: `~/.grok/skills/flow-nexus-init/`
- Headless Grok: `~/.grok/docs/user-guide/14-headless-mode.md`
