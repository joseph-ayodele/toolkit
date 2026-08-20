#!/usr/bin/env bash
#
# Toolkit — repository-level installer.
#
# Currently orchestrates the terminal component. Other categories
# (bootstrap, git, editors, dev, cloud, scripts) will be wired in here
# as they land — this script is not required to install any one
# component; see terminal/install.sh for the terminal-only entrypoint.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/install.sh | bash
#   ./install.sh   (from a local clone)
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

echo "==> Toolkit installer"

case "$(uname -s)" in
  Darwin|Linux)
    if [[ -n "$SCRIPT_DIR" ]]; then
      bash "$SCRIPT_DIR/terminal/install.sh"
    else
      curl -fsSL "$RAW_BASE/terminal/install.sh" | bash
    fi
    ;;
  *)
    echo "error: unsupported platform for install.sh; use install.ps1 on Windows." >&2
    exit 1
    ;;
esac
