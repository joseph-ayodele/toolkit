#!/usr/bin/env bash
#
# Toolkit — Oh My Posh component installer.
#
# Installs the oh-my-posh binary (if missing) and the Toolkit's
# Catppuccin Latte theme to ~/.config/toolkit/terminal/oh-my-posh/.
# Safe to rerun: it skips the binary install if already present and
# always refreshes the theme file.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/oh-my-posh/install.sh | bash
#   ./terminal/oh-my-posh/install.sh   (from a local clone)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.
#   TOOLKIT_HOME                               override the install root (default: ~/.config/toolkit).

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

TOOLKIT_OWNER="${TOOLKIT_OWNER:-joseph-ayodele}"
TOOLKIT_REPO="${TOOLKIT_REPO:-toolkit}"
TOOLKIT_REF="${TOOLKIT_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/${TOOLKIT_OWNER}/${TOOLKIT_REPO}/${TOOLKIT_REF}"
COMPONENT_PATH="terminal/oh-my-posh"

# Resolve through symlinks (e.g. this script symlinked into ~/bin) so
# local-clone detection still finds the real repo checkout.
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
  while [[ -L "$SCRIPT_SOURCE" ]]; do
    SCRIPT_TARGET="$(readlink "$SCRIPT_SOURCE")"
    if [[ "$SCRIPT_TARGET" == /* ]]; then
      SCRIPT_SOURCE="$SCRIPT_TARGET"
    else
      SCRIPT_SOURCE="$(dirname "$SCRIPT_SOURCE")/$SCRIPT_TARGET"
    fi
  done
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
else
  SCRIPT_DIR=""
fi

TOOLKIT_HOME="${TOOLKIT_HOME:-$HOME/.config/toolkit}"
INSTALL_DIR="$TOOLKIT_HOME/terminal/oh-my-posh"

fetch_file() {
  local rel="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -n "$SCRIPT_DIR" ]]; then
    cp "$SCRIPT_DIR/$rel" "$dest"
  else
    local tmp
    tmp="$(mktemp)"
    curl -fsSL "$RAW_BASE/$COMPONENT_PATH/$rel" -o "$tmp"
    mv "$tmp" "$dest"
  fi
}

echo "==> Installing Oh My Posh"

if command -v oh-my-posh >/dev/null 2>&1; then
  echo "    oh-my-posh already installed: $(command -v oh-my-posh)"
else
  echo "    installing oh-my-posh binary..."
  if ! curl -fsSL https://ohmyposh.dev/install.sh | bash -s; then
    echo "error: failed to install oh-my-posh" >&2
    exit 1
  fi
  if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "warning: oh-my-posh installed but not on PATH yet." >&2
    echo "         add its install directory (commonly ~/.local/bin) to PATH and restart your shell." >&2
  fi
fi

mkdir -p "$INSTALL_DIR"
fetch_file "config.omp.json" "$INSTALL_DIR/config.omp.json"
echo "    theme installed: $INSTALL_DIR/config.omp.json"

echo "==> Oh My Posh component installed."
