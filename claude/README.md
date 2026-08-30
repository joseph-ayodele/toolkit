# claude

Claude Code configuration: the skills I want on every machine.

## Install everything

```sh
curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/install.ps1 | iex
```

This orchestrates the components below in order. Rerunning it is also
how you update — every Toolkit-owned file gets refreshed in place.

## Components

Each of these is independently installable — you don't need the rest
of this repo to install just one.

- [`skills/`](skills) — vendored Claude Code skills, installed into
  `~/.claude/skills/`. Currently `visual-plan`, `visual-recap`, and
  `stop-slop` (also installable as `unslop` — same skill, second
  name; see [`skills/`](skills) for why).

`stop-slop` runs offline with nothing else set up. The two `visual-*`
skills are clients for a hosted service and won't produce anything
until a backend is reachable — Toolkit doesn't register that connector
for you. See [`skills/`](skills) for why, and for the local-files mode
that keeps plan content on your machine.

The install-everything command above only installs the canonical
skills, not the `unslop` alias — that has to be requested by name:

```sh
./claude/skills/install.sh unslop
```

## Where things land

Unlike the rest of Toolkit, this category does **not** install into
`~/.config/toolkit/`. Claude Code only reads skills from its own
config directory, so that is where they go:

```
~/.claude/skills/
├── visual-plan/
│   ├── .toolkit-managed
│   ├── SKILL.md
│   └── references/
├── visual-recap/
│   ├── .toolkit-managed
│   ├── SKILL.md
│   └── references/
└── stop-slop/            # or unslop/, if installed under that name
    ├── .toolkit-managed
    ├── SKILL.md
    └── references/
```

The `.toolkit-managed` marker is what makes reinstalls safe: a skill
directory carrying it is Toolkit's to replace wholesale, and anything
else in `~/.claude/skills/` is left alone. See the
[`skills/`](skills) README for the full ownership rules.

Set `CLAUDE_CONFIG_DIR` to install somewhere other than `~/.claude`.
