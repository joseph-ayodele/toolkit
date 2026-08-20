#!/usr/bin/env bash
#
# Toolkit — zsh component installer.
#
# Installs the Toolkit zsh profile (history/completion settings,
# aliases, functions), zsh-autosuggestions, zsh-syntax-highlighting,
# and zsh-completions, then wires a single managed block into
# ~/.zshrc. This is also the update command — re-running it refreshes
# Toolkit-owned files in place without touching unrelated ~/.zshrc
# content.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/zsh/install.sh | bash
#   ./terminal/zsh/install.sh   (from a local clone)
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
COMPONENT_PATH="terminal/zsh"

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
INSTALL_DIR="$TOOLKIT_HOME/terminal/zsh"
PLUGINS_DIR="$INSTALL_DIR/plugins"
ZSHRC="$HOME/.zshrc"

# If ~/.zshrc is a symlink (e.g. managed by a separate dotfiles tool),
# operate on its real target instead of replacing the symlink itself.
if [[ -L "$ZSHRC" ]]; then
  ZSHRC_TARGET="$(readlink "$ZSHRC")"
  [[ "$ZSHRC_TARGET" != /* ]] && ZSHRC_TARGET="$(cd "$(dirname "$ZSHRC")" && pwd)/$ZSHRC_TARGET"
  ZSHRC="$ZSHRC_TARGET"
fi

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

install_plugin() {
  local name="$1" url="$2"
  local dest="$PLUGINS_DIR/$name"
  if [[ -d "$dest/.git" ]]; then
    echo "    updating $name..."
    git -C "$dest" pull --ff-only --quiet
  else
    echo "    installing $name..."
    rm -rf "$dest"
    git clone --depth=1 --quiet "$url" "$dest"
  fi
}

if ! command -v zsh >/dev/null 2>&1; then
  echo "error: zsh is not installed. Install zsh first, then re-run this script." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required to install zsh plugins." >&2
  exit 1
fi

echo "==> Installing Toolkit zsh profile"

mkdir -p "$INSTALL_DIR" "$PLUGINS_DIR"
fetch_file "toolkit.zsh" "$INSTALL_DIR/toolkit.zsh"
fetch_file "aliases.zsh" "$INSTALL_DIR/aliases.zsh"
fetch_file "functions.zsh" "$INSTALL_DIR/functions.zsh"

echo "==> Installing zsh plugins"
install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
install_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions"

OMP_MARKER_START="# >>> toolkit:oh-my-posh >>>"
OMP_MARKER_END="# <<< toolkit:oh-my-posh <<<"

# Clean up standalone toolkit:oh-my-posh blocks from other startup files
OTHER_STARTUP_FILES=(
  "${ZDOTDIR:-$HOME}/.zprofile"
  "${ZDOTDIR:-$HOME}/.zshenv"
  "${ZDOTDIR:-$HOME}/.zlogin"
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.bash_login"
  "$HOME/.profile"
)

for file in "${OTHER_STARTUP_FILES[@]}"; do
  [[ ! -f "$file" ]] && continue
  real_file="$file"
  if [[ -L "$real_file" ]]; then
    link="$(readlink "$real_file")"
    [[ "$link" != /* ]] && link="$(cd "$(dirname "$real_file")" && pwd)/$link"
    real_file="$link"
  fi
  [[ "$real_file" == "$ZSHRC" ]] && continue

  if grep -Fq "$OMP_MARKER_START" "$real_file" 2>/dev/null; then
    cleaned="$(awk -v start="$OMP_MARKER_START" -v end="$OMP_MARKER_END" '
      $0 == start { skip = 1; next }
      $0 == end   { skip = 0; next }
      !skip { print }
    ' "$real_file")"
    if [[ -n "$cleaned" ]]; then
      printf '%s\n' "$cleaned" > "$real_file.tmp"
    else
      : > "$real_file.tmp"
    fi
    mv "$real_file.tmp" "$real_file"
    echo "    removed standalone oh-my-posh block from $file (now managed via toolkit:terminal)"
  fi
done

echo "==> Wiring ~/.zshrc"

touch "$ZSHRC"

MARKER_START="# >>> toolkit:terminal >>>"
MARKER_END="# <<< toolkit:terminal <<<"

START_COUNT="$(grep -cF "$MARKER_START" "$ZSHRC" || true)"
END_COUNT="$(grep -cF "$MARKER_END" "$ZSHRC" || true)"

if [[ "$START_COUNT" -ne "$END_COUNT" || "$START_COUNT" -gt 1 ]]; then
  echo "error: $ZSHRC has a malformed toolkit marker block (found $START_COUNT start / $END_COUNT end markers)." >&2
  echo "       refusing to modify it automatically to avoid losing content. Remove the" >&2
  echo "       partial '# >>> toolkit:terminal >>>' / '# <<< toolkit:terminal <<<' block by hand and re-run." >&2
  exit 1
fi

OMP_START_COUNT="$(grep -cF "$OMP_MARKER_START" "$ZSHRC" || true)"
OMP_END_COUNT="$(grep -cF "$OMP_MARKER_END" "$ZSHRC" || true)"

if [[ "$OMP_START_COUNT" -ne "$OMP_END_COUNT" || "$OMP_START_COUNT" -gt 1 ]]; then
  echo "error: $ZSHRC has a malformed oh-my-posh toolkit marker block (found $OMP_START_COUNT start / $OMP_END_COUNT end markers)." >&2
  echo "       refusing to modify it automatically to avoid losing content. Remove the" >&2
  echo "       partial '# >>> toolkit:oh-my-posh >>>' / '# <<< toolkit:oh-my-posh <<<' block by hand and re-run." >&2
  exit 1
fi

if [[ ! -f "$ZSHRC.toolkit-backup" && -s "$ZSHRC" ]]; then
  cp "$ZSHRC" "$ZSHRC.toolkit-backup"
  echo "    backed up existing ~/.zshrc to ~/.zshrc.toolkit-backup"
fi

# Command substitution strips trailing newlines, so any blank line(s)
# left behind by a removed block don't accumulate on repeated reruns.
STRIPPED="$(awk -v t_start="$MARKER_START" -v t_end="$MARKER_END" \
                -v o_start="$OMP_MARKER_START" -v o_end="$OMP_MARKER_END" '
  $0 == t_start || $0 == o_start { skip = 1; next }
  $0 == t_end || $0 == o_end     { skip = 0; next }
  !skip { print }
' "$ZSHRC")"

{
  [[ -n "$STRIPPED" ]] && printf '%s\n\n' "$STRIPPED"
  printf '%s\n' "$MARKER_START"
  printf '%s\n' '[[ -f "$HOME/.config/toolkit/terminal/zsh/toolkit.zsh" ]] && source "$HOME/.config/toolkit/terminal/zsh/toolkit.zsh"'
  printf '%s\n' "$MARKER_END"
} > "$ZSHRC.tmp"

mv "$ZSHRC.tmp" "$ZSHRC"

echo "==> zsh component installed."
echo "    restart your shell or run: exec zsh"
