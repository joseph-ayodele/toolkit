# terminal/zsh

Installs the Toolkit zsh profile: history and completion settings,
aliases, functions, and three plugins
([zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions),
[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting),
[zsh-completions](https://github.com/zsh-users/zsh-completions)).

This does **not** install [Oh My Zsh](https://ohmyz.sh/) — Toolkit
manages its own minimal profile instead.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/zsh/install.sh | bash
```

Or, from a local clone:

```sh
./terminal/zsh/install.sh
```

## What it does

- Copies `toolkit.zsh`, `aliases.zsh`, and `functions.zsh` to
  `~/.config/toolkit/terminal/zsh/`.
- Clones (or updates) the three plugins into
  `~/.config/toolkit/terminal/zsh/plugins/`.
- Adds a single managed block to `~/.zshrc`:

  ```sh
  # >>> toolkit:terminal >>>
  [[ -f "$HOME/.config/toolkit/terminal/zsh/toolkit.zsh" ]] && source "$HOME/.config/toolkit/terminal/zsh/toolkit.zsh"
  # <<< toolkit:terminal <<<
  ```

  The first time this block is added, your existing `~/.zshrc` is
  backed up to `~/.zshrc.toolkit-backup`. Rerunning the installer only
  ever rewrites the content between the markers — everything else in
  `~/.zshrc` is left untouched.

## Updating

`toolkit.zsh`, `aliases.zsh`, and `functions.zsh` in this directory
are the source of truth. Edit them, commit, and re-run the installer
(or `terminal/install.sh`) to refresh the installed copies and
plugins. This does not touch shell history or unrelated `~/.zshrc`
content, and does not check GitHub on shell startup — only when you
explicitly rerun the installer.

## Requirements

`zsh` and `git` must already be installed.
