# Toolkit — zsh functions
#
# Managed by Toolkit. Add personal functions in your own dotfiles, not
# here — reruns of the installer overwrite this file.

# Create a directory and cd into it.
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# Go up N directories (default 1).
up() {
  local n="${1:-1}"
  local path="."
  local i
  for (( i = 0; i < n; i++ )); do
    path="$path/.."
  done
  cd "$path"
}

# Extract most common archive formats.
extract() {
  local file="$1"
  # Guard against filenames starting with '-' being parsed as flags.
  [[ "$file" != /* && "$file" != ./* ]] && file="./$file"

  if [[ ! -f "$file" ]]; then
    echo "extract: '$1' is not a file" >&2
    return 1
  fi
  case "$file" in
    *.tar.bz2) tar xjf "$file" ;;
    *.tar.gz)  tar xzf "$file" ;;
    *.tar.xz)  tar xJf "$file" ;;
    *.tar)     tar xf "$file" ;;
    *.tbz2)    tar xjf "$file" ;;
    *.tgz)     tar xzf "$file" ;;
    *.zip)     unzip "$file" ;;
    *.rar)     unrar x "$file" ;;
    *.7z)      7z x "$file" ;;
    *.gz)      gunzip "$file" ;;
    *.bz2)     bunzip2 "$file" ;;
    *) echo "extract: unsupported archive type: $1" >&2; return 1 ;;
  esac
}

# Re-run the Toolkit terminal installer to pick up updates.
toolkit-update() {
  curl -fsSL "https://raw.githubusercontent.com/${TOOLKIT_OWNER:-joseph-ayodele}/${TOOLKIT_REPO:-toolkit}/${TOOLKIT_REF:-main}/terminal/install.sh" | bash
}
