#!/usr/bin/env bash
#
# Toolkit — Oh My Posh component installer.
#
# Installs the oh-my-posh binary (if missing) and the Toolkit's
# Catppuccin Latte theme to ~/.config/toolkit/terminal/oh-my-posh/,
# then checks shell startup files (zsh, bash) and wires prompt init
# via a managed block — unless it's already wired (by this script,
# by the fuller terminal/zsh component, or by hand). Safe to rerun:
# skips the binary install if already present and always refreshes
# the theme file.
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

resolve_target() {
  local target="$1"
  if [[ -L "$target" ]]; then
    local link
    link="$(readlink "$target")"
    if [[ "$link" != /* ]]; then
      link="$(cd "$(dirname "$target")" && pwd)/$link"
    fi
    echo "$link"
  else
    echo "$target"
  fi
}

MARKER_START="# >>> toolkit:oh-my-posh >>>"
MARKER_END="# <<< toolkit:oh-my-posh <<<"
TERMINAL_MARKER_START="# >>> toolkit:terminal >>>"

strip_omp_block() {
  local file="$1"
  awk -v start="$MARKER_START" -v end="$MARKER_END" '
    $0 == start { skip = 1; next }
    $0 == end   { skip = 0; next }
    !skip { print }
  ' "$file"
}

# Standard interactive and login startup files for zsh and bash
CANDIDATE_FILES=(
  "${ZDOTDIR:-$HOME}/.zshrc"
  "${ZDOTDIR:-$HOME}/.zprofile"
  "${ZDOTDIR:-$HOME}/.zshenv"
  "${ZDOTDIR:-$HOME}/.zlogin"
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.bash_login"
  "$HOME/.profile"
)

already_wired_file=""
already_wired_reason=""
omp_block_file=""

seen_files=()
for file in "${CANDIDATE_FILES[@]}"; do
  [[ ! -f "$file" ]] && continue
  real_file="$(resolve_target "$file")"
  if [[ ${#seen_files[@]} -gt 0 ]]; then
    already_seen=0
    for seen in "${seen_files[@]}"; do
      if [[ "$seen" == "$real_file" ]]; then
        already_seen=1
        break
      fi
    done
    [[ "$already_seen" -eq 1 ]] && continue
  fi
  seen_files+=("$real_file")

  # 1. Check for fuller toolkit:terminal block
  if grep -Fq "$TERMINAL_MARKER_START" "$real_file" 2>/dev/null; then
    already_wired_file="$file"
    already_wired_reason="toolkit:terminal"
    break
  fi

  # 2. Check for existing toolkit:oh-my-posh block
  if grep -Fq "$MARKER_START" "$real_file" 2>/dev/null; then
    omp_block_file="$real_file"
  fi

  # 3. Check for manual oh-my-posh init (outside any toolkit:oh-my-posh block)
  stripped_content="$(strip_omp_block "$real_file")"
  if echo "$stripped_content" | grep -Eq 'oh-my-posh[[:space:]]+init'; then
    already_wired_file="$file"
    already_wired_reason="manual"
    break
  fi
done

if [[ -n "$already_wired_file" ]]; then
  if [[ "$already_wired_reason" == "toolkit:terminal" ]]; then
    echo "    oh-my-posh already wired via toolkit:terminal in $already_wired_file"
  else
    echo "    oh-my-posh already wired manually in $already_wired_file"
  fi
else
  if [[ -n "$omp_block_file" ]]; then
    TARGET_REAL="$omp_block_file"
    TARGET_DISPLAY="$omp_block_file"
    if [[ "$(basename "$TARGET_REAL")" =~ zsh|zprofile|zshenv|zlogin ]]; then
      SHELL_FLAVOR="zsh"
    else
      SHELL_FLAVOR="bash"
    fi
  else
    if [[ "${SHELL:-}" == */zsh ]] || command -v zsh >/dev/null 2>&1; then
      TARGET_FILE="${ZDOTDIR:-$HOME}/.zshrc"
      SHELL_FLAVOR="zsh"
    elif [[ "${SHELL:-}" == */bash ]]; then
      if [[ -f "$HOME/.bashrc" || ! -f "$HOME/.bash_profile" ]]; then
        TARGET_FILE="$HOME/.bashrc"
      else
        TARGET_FILE="$HOME/.bash_profile"
      fi
      SHELL_FLAVOR="bash"
    else
      TARGET_FILE="${ZDOTDIR:-$HOME}/.zshrc"
      SHELL_FLAVOR="zsh"
    fi

    TARGET_DISPLAY="$TARGET_FILE"
    TARGET_REAL="$(resolve_target "$TARGET_FILE")"
    touch "$TARGET_REAL"

    if [[ ! -f "$TARGET_REAL.toolkit-backup" && -s "$TARGET_REAL" ]]; then
      cp "$TARGET_REAL" "$TARGET_REAL.toolkit-backup"
      echo "    backed up existing $(basename "$TARGET_REAL") to $(basename "$TARGET_REAL.toolkit-backup")"
    fi
  fi

  START_COUNT="$(grep -cF "$MARKER_START" "$TARGET_REAL" 2>/dev/null || true)"
  END_COUNT="$(grep -cF "$MARKER_END" "$TARGET_REAL" 2>/dev/null || true)"
  if [[ "$START_COUNT" -ne "$END_COUNT" || "$START_COUNT" -gt 1 ]]; then
    echo "error: $TARGET_REAL has a malformed toolkit marker block (found $START_COUNT start / $END_COUNT end markers)." >&2
    echo "       refusing to modify it automatically to avoid losing content. Remove the" >&2
    echo "       partial '$MARKER_START' / '$MARKER_END' block by hand and re-run." >&2
    exit 1
  fi

  echo "==> Wiring $(basename "$TARGET_DISPLAY")"

  STRIPPED="$(strip_omp_block "$TARGET_REAL")"

  {
    [[ -n "$STRIPPED" ]] && printf '%s\n\n' "$STRIPPED"
    printf '%s\n' "$MARKER_START"
    printf '%s\n' '# Interactive shells only: a prompt engine emits output that corrupts'
    printf '%s\n' '# scp/rsync and adds latency to every non-interactive shell invocation.'
    printf '%s\n' 'case $- in'
    printf '%s\n' '  *i*)'
    printf '%s\n' '    if command -v oh-my-posh >/dev/null 2>&1; then'
    printf '%s\n' "      eval \"\$(oh-my-posh init $SHELL_FLAVOR --config \"\$HOME/.config/toolkit/terminal/oh-my-posh/config.omp.json\")\""
    printf '%s\n' '    fi'
    printf '%s\n' '    ;;'
    printf '%s\n' 'esac'
    printf '%s\n' "$MARKER_END"
  } > "$TARGET_REAL.tmp"

  mv "$TARGET_REAL.tmp" "$TARGET_REAL"
  echo "    prompt init wired in $(basename "$TARGET_DISPLAY")"
fi

echo "==> Oh My Posh component installed."
echo "    restart your shell or run: source ~/.zshrc (or: exec zsh)"
