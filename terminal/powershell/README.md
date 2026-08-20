# terminal/powershell

Installs the Toolkit PowerShell profile: history settings (via
PSReadLine), aliases, functions, and Oh My Posh prompt wiring.

## Install

```powershell
irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/powershell/install.ps1 | iex
```

Or, from a local clone:

```powershell
.\terminal\powershell\install.ps1
```

## What it does

- Copies `toolkit.ps1`, `aliases.ps1`, and `functions.ps1` to
  `$HOME/.config/toolkit/terminal/powershell/`.
- Adds a single managed block to `$PROFILE.CurrentUserAllHosts`:

  ```powershell
  # >>> toolkit:terminal >>>
  if (Test-Path "$HOME/.config/toolkit/terminal/powershell/toolkit.ps1") { . "$HOME/.config/toolkit/terminal/powershell/toolkit.ps1" }
  # <<< toolkit:terminal <<<
  ```

  The first time this block is added, your existing profile is backed
  up alongside it with a `.toolkit-backup` suffix. Rerunning the
  installer only ever rewrites the content between the markers —
  everything else in your profile is left untouched.

## Updating

`toolkit.ps1`, `aliases.ps1`, and `functions.ps1` in this directory
are the source of truth. Edit them, commit, and re-run the installer
(or `terminal/install.ps1`) to refresh the installed copies. This does
not touch shell history or unrelated profile content, and does not
check GitHub on shell startup — only when you explicitly rerun the
installer.
