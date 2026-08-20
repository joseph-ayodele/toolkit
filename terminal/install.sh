#!/usr/bin/env bash
#
# Toolkit — terminal component orchestrator.
#
# Installs the full terminal environment: Oh My Posh + theme, and the
# zsh profile (plugins, aliases, functions, history/completion
# settings). This is also the update command — re-running it refreshes
# Toolkit-owned files in place without touching unrelated shell config.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.sh | bash
#   ./terminal/install.sh   (from a local clone)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

TOOLKIT_OWNER="${TOOLKIT_OWNER:-joseph-ayodele}"
TOOLKIT_REPO="${TOOLKIT_REPO:-toolkit}"
TOOLKIT_REF="${TOOLKIT_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/${TOOLKIT_OWNER}/${TOOLKIT_REPO}/${TOOLKIT_REF}"

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

run_component() {
  local component="$1"
  echo "==> terminal/${component}"
  if [[ -n "$SCRIPT_DIR" ]]; then
    bash "$SCRIPT_DIR/${component}/install.sh"
  else
    curl -fsSL "$RAW_BASE/terminal/${component}/install.sh" | bash
  fi
}

run_component "oh-my-posh"
run_component "zsh"

echo "==> Terminal environment installed. Restart your shell or run: source ~/.zshrc (or: exec zsh)"
