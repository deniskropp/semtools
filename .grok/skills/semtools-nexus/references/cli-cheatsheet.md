# SemTools Nexus CLI Cheatsheet (Grok-backed)

## Division of labor

| Command | Role | Backend |
|---------|------|---------|
| `~/.grok/bin/parse` (or `grok-parse.sh`) | Document → markdown paths | **Grok CLI** + `~/.parse` cache |
| `semtools search` / `search` | Local semantic search | Local embeddings |
| `~/.grok/bin/ask` (or `grok-ask.sh`) | Q&A over files | **Grok CLI** |
| `semtools workspace` / `workspace` | Embedding cache | Local disk |

**Not used in this skill:** Llama Cloud / LlamaParse, OpenAI, cargo `parse`/`ask` cloud backends.

## Grok headless essentials

```bash
GROK_BIN="${GROK_BIN:-grok}"   # or /home/dok/.grok/bin/grok

# Parse-style extract
"$GROK_BIN" -p "Extract full content as clean markdown. File: /abs/path/doc.pdf" \
  --tools "read_file" --yolo --output-format plain

# Ask-style Q&A
"$GROK_BIN" -p "Answer using only these files… Question: …" \
  --tools "read_file,grep,list_dir" --yolo --output-format plain

# Optional: cap turns / model
"$GROK_BIN" -p "…" -m grok-build --max-turns 20 --yolo --output-format plain
```

Helpers:

```bash
.grok/skills/semtools-nexus/scripts/grok-parse.sh doc.pdf
.grok/skills/semtools-nexus/scripts/grok-ask.sh "Summarize methods" ./corpus/*.md
```

## Search flags (local)

- `--max-distance <float>` — lower = stricter
- `--n-lines <n>` — context lines
- `--top-k <n>` — result count

```bash
search "installation" ./docs/*.md --max-distance 0.3 --n-lines 5 --top-k 10
```

## Workspace flow

```bash
workspace use my-workspace
export SEMTOOLS_WORKSPACE=my-workspace
search "query" ./large_dir/*.md --n-lines 5 --top-k 10
workspace prune
```

## Compose

```bash
# Parse with Grok, then local search
.grok/skills/semtools-nexus/scripts/grok-parse.sh paper.pdf > /tmp/paper.md
search "evaluation metrics" /tmp/paper.md --top-k 5

# Search then deep ask with Grok
hits=$(search "auth" ./docs/*.md --top-k 10)
.grok/skills/semtools-nexus/scripts/grok-ask.sh "Explain authentication flow from these hits" ./docs/*.md
```

## Install / paths

```bash
# From repo root — install Grok ask/parse wrappers
./scripts/grok-cli/install.sh
```

- Packaged sources: `scripts/grok-cli/{ask,parse}`
- Grok binary: `$HOME/.grok/bin/grok` or `grok` on PATH
- Local search: `cargo install semtools` or npm `@llamaindex/semtools` — only need **search** + **workspace** for Nexus
