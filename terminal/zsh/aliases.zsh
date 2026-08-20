# Toolkit — zsh aliases
#
# Managed by Toolkit. Add personal aliases in your own dotfiles, not
# here — reruns of the installer overwrite this file.

alias ll='ls -lh'
alias la='ls -lAh'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias grep='grep --color=auto'
alias mkdir='mkdir -p'

alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -lh'
  alias la='eza -lAh'
  alias lt='eza --tree'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
fi

alias reload='exec zsh'
