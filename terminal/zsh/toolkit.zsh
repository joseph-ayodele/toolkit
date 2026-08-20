# Toolkit — zsh profile
#
# Managed by Toolkit's terminal/zsh installer. Local customizations
# belong in your own dotfiles, not here — reruns of the installer
# overwrite this file.

TOOLKIT_HOME="${TOOLKIT_HOME:-$HOME/.config/toolkit}"
TOOLKIT_ZSH_DIR="$TOOLKIT_HOME/terminal/zsh"
TOOLKIT_PLUGINS_DIR="$TOOLKIT_ZSH_DIR/plugins"

# --- History ---------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# --- Completion --------------------------------------------------------------
if [[ -d "$TOOLKIT_PLUGINS_DIR/zsh-completions/src" ]]; then
  fpath=("$TOOLKIT_PLUGINS_DIR/zsh-completions/src" $fpath)
fi

autoload -Uz compinit
_toolkit_compdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${_toolkit_compdump}(#qN.mh+24) ]]; then
  compinit -d "$_toolkit_compdump"
else
  compinit -C -d "$_toolkit_compdump"
fi
unset _toolkit_compdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Plugins -------------------------------------------------------------------
[[ -f "$TOOLKIT_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$TOOLKIT_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- Prompt (Oh My Posh) -------------------------------------------------------
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config "$TOOLKIT_HOME/terminal/oh-my-posh/config.omp.json")"
fi

# --- Aliases & functions --------------------------------------------------------
[[ -f "$TOOLKIT_ZSH_DIR/aliases.zsh" ]] && source "$TOOLKIT_ZSH_DIR/aliases.zsh"
[[ -f "$TOOLKIT_ZSH_DIR/functions.zsh" ]] && source "$TOOLKIT_ZSH_DIR/functions.zsh"

# zsh-syntax-highlighting must be sourced last.
[[ -f "$TOOLKIT_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$TOOLKIT_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
