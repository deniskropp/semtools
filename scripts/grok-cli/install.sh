#!/usr/bin/env bash
# install.sh — install Grok-backed semtools ask/parse drop-ins
#
# Usage:
#   ./scripts/grok-cli/install.sh              # symlink into ~/.grok/bin + ~/.local/bin
#   ./scripts/grok-cli/install.sh --copy       # copy instead of symlink
#   ./scripts/grok-cli/install.sh --prefix DIR # only install under DIR (no local/bin)
#   ./scripts/grok-cli/install.sh --uninstall
#
# Default destinations:
#   ~/.grok/bin/{ask,parse}
#   ~/.local/bin/{ask,parse}   (when ~/.local/bin exists)
#
# Ensure ~/.grok/bin or ~/.local/bin precedes ~/.cargo/bin on PATH so these
# wrappers win over the OpenAI/LlamaParse cargo binaries.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=symlink
PREFIX=""
UNINSTALL=0
ALSO_LOCAL=1

usage() {
  sed -n '2,16p' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --copy) MODE=copy; shift ;;
    --symlink) MODE=symlink; shift ;;
    --prefix)
      PREFIX="${2:-}"
      ALSO_LOCAL=0
      shift 2
      ;;
    --no-local) ALSO_LOCAL=0; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    *)
      echo "install: unknown option: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$PREFIX" ]]; then
  PREFIX="${HOME}/.grok/bin"
fi

install_one() {
  local name="$1"
  local src="${SRC_DIR}/${name}"
  local dest="${PREFIX}/${name}"
  if [[ ! -f "$src" ]]; then
    echo "install: missing source $src" >&2
    exit 1
  fi
  mkdir -p "$PREFIX"
  if [[ "$MODE" == "copy" ]]; then
    install -m 0755 "$src" "$dest"
    echo "installed (copy)  $dest"
  else
    ln -sfn "$src" "$dest"
    echo "installed (link)  $dest -> $src"
  fi
}

uninstall_one() {
  local dest="$1"
  if [[ -L "$dest" || -f "$dest" ]]; then
    # Only remove if it looks like our wrapper
    if [[ -L "$dest" ]] || head -n 3 "$dest" 2>/dev/null | grep -q 'Grok CLI drop-in'; then
      rm -f "$dest"
      echo "removed $dest"
    else
      echo "skip (not our wrapper): $dest" >&2
    fi
  fi
}

if [[ "$UNINSTALL" -eq 1 ]]; then
  uninstall_one "${PREFIX}/ask"
  uninstall_one "${PREFIX}/parse"
  if [[ "$ALSO_LOCAL" -eq 1 && -d "${HOME}/.local/bin" ]]; then
    uninstall_one "${HOME}/.local/bin/ask"
    uninstall_one "${HOME}/.local/bin/parse"
  fi
  exit 0
fi

for cmd in ask parse; do
  install_one "$cmd"
done

if [[ "$ALSO_LOCAL" -eq 1 && -d "${HOME}/.local/bin" ]]; then
  for cmd in ask parse; do
    dest="${HOME}/.local/bin/${cmd}"
    if [[ "$MODE" == "copy" ]]; then
      install -m 0755 "${SRC_DIR}/${cmd}" "$dest"
      echo "installed (copy)  $dest"
    else
      # Prefer linking to PREFIX so one update path
      ln -sfn "${PREFIX}/${cmd}" "$dest"
      echo "installed (link)  $dest -> ${PREFIX}/${cmd}"
    fi
  done
fi

echo
echo "Done. Verify with:"
echo "  type -a ask parse"
echo "  ask --version"
echo "  parse --version"
echo
echo "PATH tip: put ${PREFIX} (and ~/.local/bin) before ~/.cargo/bin so Grok wrappers win."
