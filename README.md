# toolkit

Personal, cross-platform machine setup and dotfiles. Each component is
independently installable — you never need to clone this repository
to install just one piece.

Toolkit installs runtime configuration to `~/.config/toolkit/`. Your
machine keeps working even if this repository is deleted, never
cloned, or GitHub is unavailable — shell startup never reaches out to
the network.

## Status

Currently implemented: **terminal** (Oh My Posh, zsh, PowerShell).
Everything else below is planned.

## Quick start

Install the full terminal environment:

```sh
curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.ps1 | iex
```

Or install a single component, e.g. just Oh My Posh:

```sh
curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/oh-my-posh/install.sh | bash
```

Running any installer again updates the Toolkit-owned files in place
— it's also the update command.

## Repository structure

```
toolkit/
├── install.sh          # repo-level orchestrator (bash)
├── install.ps1         # repo-level orchestrator (PowerShell)
│
├── bootstrap/           # planned: OS-level machine setup
├── terminal/             # Oh My Posh, zsh, PowerShell
│   ├── install.sh / install.ps1
│   ├── oh-my-posh/
│   ├── zsh/
│   └── powershell/
│
├── git/                  # planned: git config
├── editors/              # planned: editor config (VS Code, ...)
├── dev/                  # planned: language/runtime tooling
├── cloud/                # planned: AWS, Terraform, ...
├── scripts/              # planned: standalone utility scripts
└── docs/                 # planned: setup & troubleshooting docs
```

See [`terminal/`](terminal) for details on the terminal component.

## Conventions

- **Independently installable**: `terminal/oh-my-posh/install.sh` only
  installs Oh My Posh; it never requires the rest of the repo.
- **Category installers orchestrate**: `terminal/install.sh` just
  calls each component's installer in turn.
- **Path maps to URL**: a script's path in this repo is also its raw
  GitHub URL, e.g. `terminal/zsh/install.sh` →
  `https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/zsh/install.sh`.
- **Source of truth vs. install target**: this repo is the source of
  truth; installers copy/download files into `~/.config/toolkit/`,
  which is what your shell actually reads. Nothing sources files
  directly from a cloned copy of this repo.
- **Ref override**: set `TOOLKIT_REF` to install from a branch or tag
  other than `main`. A `VAR=val` prefix only applies to the first
  command in a pipeline, so it won't reach `bash` on the far side of
  `curl | bash` — export it first, or pass it to `bash -c` directly:

  ```sh
  export TOOLKIT_REF=v1.0.0
  curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.sh | bash

  # or, in one line:
  TOOLKIT_REF=v1.0.0 bash -c "$(curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/terminal/install.sh)"
  ```

## License

Personal configuration — use at your own risk.
