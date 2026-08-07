# Grok CLI drop-ins for SemTools (`ask` / `parse`)

Semtools-compatible **`ask`** and **`parse`** wrappers that use the **Grok CLI** instead of OpenAI / Llama Cloud.

| Command | Replaces | Backend |
|---------|----------|---------|
| `parse` | cargo/npm `parse` (LlamaParse) | Grok headless + `~/.parse` cache |
| `ask` | cargo/npm `ask` (OpenAI) | Grok headless |
| `search` / `workspace` | unchanged | Local semtools binaries |

## Install

From the repo root:

```bash
./scripts/grok-cli/install.sh
# or: bash scripts/grok-cli/install.sh --copy
```

This installs into:

- `~/.grok/bin/{ask,parse}`
- `~/.local/bin/{ask,parse}` (if `~/.local/bin` exists)

Uninstall:

```bash
./scripts/grok-cli/install.sh --uninstall
```

Custom prefix only:

```bash
./scripts/grok-cli/install.sh --prefix /usr/local/bin --copy --no-local
```

## PATH

Ensure **`~/.local/bin`** or **`~/.grok/bin`** appears **before** **`~/.cargo/bin`**, otherwise the OpenAI/LlamaParse cargo binaries still win:

```bash
type -a ask parse
# expect: …/.local/bin/ask or …/.grok/bin/ask first
ask --version    # → ask 1.0.0-grok …
parse --version  # → parse 1.0.0-grok …
```

## Usage

```bash
parse report.pdf
parse papers/*.pdf | xargs search "evaluation"
parse papers/*.pdf | xargs ask "Summarize methodologies"
cat README.md | ask "How do I install?"
ask "Main findings?" notes/*.md
```

## Requirements

- [Grok CLI](https://grok.com) authenticated (`grok` on PATH or `~/.grok/bin/grok`)
- `python3` (parse cache metadata)
- Optional: local `search` / `workspace` from `cargo install semtools` or npm

## Environment

| Variable | Used by | Meaning |
|----------|---------|---------|
| `GROK_BIN` | both | Path to grok binary |
| `GROK_MODEL` | both | Default `-m` model |
| `GROK_MAX_TURNS` | ask | Default max turns (24) |
| `PARSE_MAX_TURNS` | parse | Default max turns (24) |
| `PARSE_CACHE_DIR` | parse | Default `~/.parse` |
| `ASK_TOOLS` / `PARSE_TOOLS` | both | Grok `--tools` allowlist |
| `ASK_NO_YOLO` / `PARSE_NO_YOLO` | both | Skip `--yolo` |

## Related

- Project skill: `.grok/skills/semtools-nexus/`
- Doctor: `.grok/skills/semtools-nexus/scripts/semtools-doctor.sh`
