#!/usr/bin/env bash
#
# Toolkit — Claude skills component installer.
#
# Installs the Toolkit's vendored Claude Code skills into
# ~/.claude/skills/, where Claude Code picks them up automatically
# (each loads as <name>@skills-dir). This is also the update command
# — re-running it replaces each Toolkit-owned skill directory in
# place, dropping files that upstream removed, and never touches
# skills Toolkit does not own.
#
# A skill directory is considered Toolkit-owned once it contains a
# .toolkit-managed marker. A pre-existing directory without that
# marker is backed up to <name>.toolkit-backup before it is replaced.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/skills/install.sh | bash
#   ./claude/skills/install.sh                (from a local clone; installs every skill)
#   ./claude/skills/install.sh visual-plan    (install/update a single skill)
#
# Environment:
#   TOOLKIT_OWNER, TOOLKIT_REPO, TOOLKIT_REF   override the source repo/ref.
#   CLAUDE_CONFIG_DIR                          override Claude's config dir (default: ~/.claude).

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

TOOLKIT_OWNER="${TOOLKIT_OWNER:-joseph-ayodele}"
TOOLKIT_REPO="${TOOLKIT_REPO:-toolkit}"
TOOLKIT_REF="${TOOLKIT_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/${TOOLKIT_OWNER}/${TOOLKIT_REPO}/${TOOLKIT_REF}"
COMPONENT_PATH="claude/skills"

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

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"

MARKER=".toolkit-managed"

# Every skill Toolkit vendors, and the files each one owns. Keep these
# lists in sync with the directories in this component — the remote
# (curl | bash) path has no directory listing to walk, so the manifest
# is what tells it which files to fetch.
ALL_SKILLS=(
  "visual-plan"
  "visual-recap"
  "stop-slop"
)

# Alternate names for a vendored skill above: same files, fetched from the
# canonical source dir, installed under the alias's own directory name with
# the SKILL.md `name:` field swapped to match. Add a case line here (and a
# name to ALIAS_NAMES below) to give any skill above another install name —
# no other changes needed. (Not an associative array: this has to run on
# bash 3.2, which is still what macOS ships as /bin/bash.)
ALIAS_NAMES=(
  "unslop"
)

alias_source() {
  case "$1" in
    unslop) echo "stop-slop" ;;
    *) echo "$1" ;;
  esac
}

# All names install_skill will accept: canonical skills plus their aliases.
INSTALLABLE_SKILLS=("${ALL_SKILLS[@]}" "${ALIAS_NAMES[@]}")

skill_files() {
  case "$(alias_source "$1")" in
    visual-plan)
      printf '%s\n' \
        "SKILL.md" \
        "README.md" \
        "LICENSE.upstream" \
        "references/canvas.md" \
        "references/connection.md" \
        "references/document-quality.md" \
        "references/exemplar.md" \
        "references/local-files.md" \
        "references/wireframe.md"
      ;;
    visual-recap)
      printf '%s\n' \
        "SKILL.md" \
        "README.md" \
        "LICENSE.upstream" \
        "references/connection.md" \
        "references/local-files.md" \
        "references/wireframe.md"
      ;;
    stop-slop)
      printf '%s\n' \
        "SKILL.md" \
        "README.md" \
        "LICENSE.upstream" \
        "LICENSE.upstream.unslop" \
        "references/examples.md" \
        "references/phrases.md" \
        "references/structures.md" \
        "references/epistemics.md" \
        "references/style-profile-template.md"
      ;;
    *)
      return 1
      ;;
  esac
}

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

install_skill() {
  local name="$1"
  local dest="$SKILLS_DIR/$name"
  local staging="$SKILLS_DIR/.$name.toolkit-staging"

  if [[ -L "$dest" ]]; then
    echo "error: $dest is a symlink, presumably managed by something else." >&2
    echo "       refusing to replace it. Remove the symlink by hand and re-run." >&2
    return 1
  fi

  if [[ -d "$dest" && ! -f "$dest/$MARKER" ]]; then
    if [[ -e "$dest.toolkit-backup" ]]; then
      echo "    replacing unmanaged $name (backup already exists at $name.toolkit-backup)"
    else
      cp -R "$dest" "$dest.toolkit-backup"
      echo "    backed up existing $name to $name.toolkit-backup"
    fi
  fi

  # Stage the whole skill first, so a failed download can never leave a
  # half-written skill directory behind where Claude Code would read it.
  rm -rf "$staging"
  mkdir -p "$staging"

  local source
  source="$(alias_source "$name")"

  local rel
  while IFS= read -r rel; do
    if ! fetch_file "$source/$rel" "$staging/$rel"; then
      rm -rf "$staging"
      echo "error: failed to fetch $name/$rel; leaving the installed copy untouched." >&2
      return 1
    fi
  done < <(skill_files "$name")

  if [[ ! -s "$staging/SKILL.md" ]]; then
    rm -rf "$staging"
    echo "error: $name/SKILL.md came back empty; leaving the installed copy untouched." >&2
    return 1
  fi

  if [[ "$source" != "$name" ]]; then
    sed -i.bak "s/^name: .*/name: $name/" "$staging/SKILL.md" && rm -f "$staging/SKILL.md.bak"
  fi

  printf '%s\n' \
    "# Installed by Toolkit — https://github.com/${TOOLKIT_OWNER}/${TOOLKIT_REPO}" \
    "# Source: ${COMPONENT_PATH}/${name}" \
    "# Edits here are overwritten on the next run; change the skill in the repo instead." \
    > "$staging/$MARKER"

  rm -rf "$dest"
  mv "$staging" "$dest"
  echo "    installed $name -> $dest"
}

if ! command -v curl >/dev/null 2>&1 && [[ -z "$SCRIPT_DIR" ]]; then
  echo "error: curl is required to install skills over the network." >&2
  exit 1
fi

if [[ $# -gt 0 ]]; then
  SKILLS=("$@")
else
  SKILLS=("${ALL_SKILLS[@]}")
fi

# Validate every requested name before touching the filesystem, so a
# typo in one argument can't leave a partial install behind.
for skill in "${SKILLS[@]}"; do
  if ! skill_files "$skill" >/dev/null 2>&1; then
    echo "error: unknown skill '$skill'. Known skills: ${INSTALLABLE_SKILLS[*]}" >&2
    exit 1
  fi
done

echo "==> Installing Toolkit Claude skills"

mkdir -p "$SKILLS_DIR"
for skill in "${SKILLS[@]}"; do
  install_skill "$skill"
done

echo "==> Claude skills component installed."
echo "    restart Claude Code to pick them up: ${SKILLS[*]}"
