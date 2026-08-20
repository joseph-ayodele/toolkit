# terminal/oh-my-posh

Installs [Oh My Posh](https://ohmyposh.dev) and the Toolkit's custom
Catppuccin Latte prompt theme.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/oh-my-posh/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/oh-my-posh/install.ps1 | iex
```

Or, from a local clone:

```sh
./terminal/oh-my-posh/install.sh
```

## What it does

- Installs the `oh-my-posh` binary if it isn't already on `PATH`
  (via the official installer on macOS/Linux, `winget` on Windows).
- Copies `config.omp.json` to
  `~/.config/toolkit/terminal/oh-my-posh/config.omp.json`.

It does **not** wire the prompt into your shell — that's handled by
[`terminal/zsh`](../zsh) and [`terminal/powershell`](../powershell),
which reference the installed config path directly.

## Updating the theme

`config.omp.json` in this directory is the source of truth. Edit it,
commit, and re-run the installer (or `terminal/install.sh`) to refresh
the installed copy. Rerunning never touches your shell profile.

## Requirements

A [Nerd Font](https://www.nerdfonts.com/) is required for the icons in
this theme to render correctly in your terminal.
