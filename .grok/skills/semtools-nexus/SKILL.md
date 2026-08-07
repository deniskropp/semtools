---
name: semtools-nexus
description: >
  Flow Nexus for SemTools — local semantic search/workspace via semtools CLI, with
  document parse and Q&A via Grok CLI (not Llama Cloud or OpenAI). Use when the user
  runs /semtools-nexus, ⫻flow/nexus:semtools, invokes Flow Nexus for this repo, or
  asks to parse/search/ask over docs and ship results via connected MCP tools.
  Triggers: semtools-nexus, semtools flow, grok parse ask, document Q&A pipeline,
  MCP + semtools, semantic search orchestration.
---

# SemTools Nexus

## Overview

Project-scoped Flow Nexus skill for **SemTools** plus **Grok CLI**:

| Step | Tool | Backend |
|------|------|---------|
| **parse** | `grok` CLI (headless) | Grok reads PDFs/docs → markdown text |
| **search** | `semtools search` | Local embeddings (no cloud) |
| **ask** | `grok` CLI (headless) | Grok agent over files (not OpenAI) |
| **workspace** | `semtools workspace` | Local cache under `~/.semtools/workspaces/` |

**Do not** use `LLAMA_CLOUD_API_KEY`, LlamaParse, `OPENAI_API_KEY`, or `semtools ask` /
`semtools parse` for cloud backends in this skill. Prefer Grok CLI for any LLM step.

## Prerequisites

1. CLIs:
   ```bash
   command -v grok || command -v /home/dok/.grok/bin/grok
   command -v search || command -v semtools   # local search/workspace
   .grok/skills/semtools-nexus/scripts/semtools-doctor.sh
   ```
2. Grok authenticated (same session/account as normal Grok Build) — no separate
   Llama Cloud or OpenAI keys for Nexus pipelines.
3. Optional: `SEMTOOLS_WORKSPACE` after `semtools workspace use <name>` (or `workspace use`).
4. MCP: `search_tool` **before** any `use_tool`. Never invent schemas.

## Core CLI Patterns

Use absolute paths when chaining. Default Grok binary: `GROK_BIN="${GROK_BIN:-grok}"`
(fallback `/home/dok/.grok/bin/grok`).

### Parse (Grok CLI — replaces LlamaParse)

Drop-in binary (preferred): **`~/.grok/bin/parse`** (also linked as `~/.local/bin/parse`).

Stdout is **one result path per line** (semtools contract): markdown under `~/.parse/`, or the
original path for already-readable text (`md`/`txt`/`rs`/…).

```bash
# Drop-in (caches under ~/.parse; no LLAMA_CLOUD_API_KEY)
parse report.pdf
parse papers/*.pdf | xargs search "evaluation"
parse papers/*.pdf | xargs ask "Summarize methodologies"
parse -v --force slide-deck.pptx

# Skill helper (prints markdown to stdout; optional --out-dir)
.grok/skills/semtools-nexus/scripts/grok-parse.sh path/to/doc.pdf
```

Plain-text files with odd extensions use a local fast path; binary/office/PDF use headless Grok.

### Search (local — unchanged)

```bash
semtools search "keywords" path/to/**/*.md --max-distance 0.3 --n-lines 5 --top-k 10
# or cargo/npm shims:
search "keywords" ./corpus/*.txt --n-lines 5 --top-k 10

export SEMTOOLS_WORKSPACE=my-workspace
search "keywords" ./corpus/*.txt --n-lines 5 --top-k 10
```

### Ask (Grok CLI — replaces OpenAI / semtools ask)

Drop-in binary (preferred): **`~/.grok/bin/ask`** (also linked as `~/.local/bin/ask` when present).

```bash
# Drop-in (semtools-compatible CLI, Grok backend — no OPENAI_API_KEY)
ask "What are the main findings?" papers/*.md
cat README.md | ask "How do I install SemTools?"
ask -m grok-build --max-turns 20 "Summarize methods" papers/*.md

# Skill helper (same idea)
.grok/skills/semtools-nexus/scripts/grok-ask.sh "What are the main findings?" papers/*.md

# Raw headless
GROK_BIN="${GROK_BIN:-grok}"
"$GROK_BIN" -p "Answer the question using only the given files. Cite paths.
Question: What are the main findings?
Files:
- $(realpath papers/a.md)
- $(realpath papers/b.md)" \
  --tools "read_file,grep,list_dir" \
  --yolo \
  --output-format plain
```

Ensure `~/.grok/bin` or `~/.local/bin` precedes `~/.cargo/bin` on `PATH` so the Grok `ask` wins over the OpenAI cargo binary.

### Workspace (local — unchanged)

```bash
semtools workspace use my-workspace   # or: workspace use my-workspace
export SEMTOOLS_WORKSPACE=my-workspace
semtools workspace prune
```

### Recommended pipelines

| Goal | Pipeline |
|------|----------|
| Fresh PDF Q&A | `grok-parse.sh` → `grok-ask.sh` |
| Keyword exploration | parse if needed → `search` |
| Large stable corpus | `workspace use` → repeated `search`; Grok only for deep ask |
| Exact + semantic | `grep` prefilter → `search` |
| Ship result | CLI pipeline → artifact → MCP (confirm writes) |

## MCP Integration (Flow Nexus)

**In-agent:**
1. `search_tool(query="…")`
2. `use_tool(tool_name, tool_input)` with schema-valid args

**CLI helpers:**
```bash
.grok/skills/semtools-nexus/scripts/mcp-discover.sh
.grok/skills/semtools-nexus/scripts/mcp-discover.sh github
.grok/skills/semtools-nexus/scripts/semtools-doctor.sh
.grok/skills/semtools-nexus/scripts/grok-parse.sh <files...>
.grok/skills/semtools-nexus/scripts/grok-ask.sh "<question>" <files...>
```

**Common chains:** search hits → GitHub issue; Grok summary → Drive/Gmail (confirm first).

## Agent Instructions (imperative)

When this skill is active:

1. **Clarify corpus** — paths, workspace, whether parse is needed
2. **Doctor** if unsure — `scripts/semtools-doctor.sh` (expects `grok` + local search, not cloud keys)
3. **Parse with Grok** — `grok-parse.sh` or `grok -p … --tools read_file --yolo`; never LlamaParse / `LLAMA_CLOUD_API_KEY`
4. **Search with semtools** — local only; do not reimplement embeddings in prose
5. **Ask with Grok** — `grok-ask.sh` or `grok -p …`; never `OPENAI_API_KEY` / `semtools ask` for Nexus
6. **Cap blast radius** — explicit paths; `--max-turns` on long Grok jobs if needed
7. **Synthesize** with path citations
8. **MCP only after intent** — confirm before mutating remote systems

## Safety

- No cloud API keys required for the default Nexus path; do not commit secrets
- Headless Grok with `--yolo` is high privilege — keep `--tools` minimal for parse/ask
- Prefer read-only MCP unless the user requests writes

## References

- `references/mcp-integration.md`
- `references/cli-cheatsheet.md`
- Grok headless: `~/.grok/docs/user-guide/14-headless-mode.md`
- Local search: repo `README.md` (`search` / `workspace` sections only)
