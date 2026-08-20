# terminal

The terminal environment: prompt theme, shell profile, aliases, and
functions for zsh (macOS/Linux) and PowerShell (Windows).

## Install everything

```sh
curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.ps1 | iex
```

This orchestrates the components below in order. Rerunning it is also
how you update — every Toolkit-owned file gets refreshed in place.

## Components

Each of these is independently installable — you don't need the rest
of this repo to install just one.

- [`oh-my-posh/`](oh-my-posh) — the [Oh My Posh](https://ohmyposh.dev)
  binary and the Toolkit's Catppuccin Latte prompt theme.
- [`zsh/`](zsh) — the zsh profile: history/completion settings,
  aliases, functions, zsh-autosuggestions, zsh-syntax-highlighting,
  zsh-completions. Does **not** install Oh My Zsh.
- [`powershell/`](powershell) — the PowerShell equivalent: profile,
  aliases, functions, PSReadLine history settings.

## Where things land

Nothing is read directly out of a cloned copy of this repo. Installers
copy or download files into:

```
~/.config/toolkit/terminal/
├── oh-my-posh/
│   └── config.omp.json
├── zsh/
│   ├── toolkit.zsh
│   ├── aliases.zsh
│   ├── functions.zsh
│   └── plugins/
└── powershell/
    ├── toolkit.ps1
    ├── aliases.ps1
    └── functions.ps1
```

`~/.zshrc` and `$PROFILE` only ever get a single managed block that
sources `toolkit.zsh` / `toolkit.ps1` from that installed location —
see the [`zsh/`](zsh) and [`powershell/`](powershell) READMEs for
details on how that block is inserted and updated.
