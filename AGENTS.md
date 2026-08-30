# AGENTS.md

Instructions for Claude Code (and other agents) working in this repo.

## What this is

`toolkit` is Joseph's personal, cross-platform machine-setup repo:
dotfiles and config for a new machine, delivered as `curl | bash` /
`irm | iex` installers, not a dotfiles-manager framework. There is no
build, no test suite, no package to publish — the deliverable is the
shell scripts and config files themselves.

Currently implemented: `terminal/` (Oh My Posh, zsh, PowerShell) and
`claude/` (vendored Claude Code skills). Everything else in the
repository-structure diagram in `README.md` (`bootstrap/`, `git/`,
`editors/`, `dev/`, `cloud/`, `scripts/`, `docs/`) is planned, not yet
started — don't assume those directories exist or infer conventions
from them.

Read `README.md` first for the full picture (quick-start commands,
repo structure, conventions, `TOOLKIT_REF` override). What follows here
is agent-specific: things worth knowing before editing, not a repeat of
what's already documented there.

## Layout

- `install.sh` / `install.ps1` — repo-level orchestrators. Call each
  top-level category's installer in turn.
- `terminal/` — prompt theme, zsh profile, PowerShell profile. Installs
  into `~/.config/toolkit/terminal/`.
- `claude/` — vendored Claude Code skills. Installs into
  `~/.claude/skills/` instead (Claude Code only reads skills from its
  own config dir — this is the one component that doesn't use
  `~/.config/toolkit/`).

Each category directory has the same shape: a `README.md`, an
`install.sh`/`install.ps1` that orchestrates its subcomponents, and one
subdirectory per subcomponent, each independently installable and each
carrying its own `install.sh`/`install.ps1`. Don't add a component that
can only be installed as part of the whole — every level has to work
standalone.

## Conventions that aren't optional

These are load-bearing, not style preferences — breaking them breaks
the `curl | bash` install path or corrupts a user's existing config:

- **bash 3.2 compatibility.** All `.sh` scripts must run under bash
  3.2, because that's still what `/bin/bash` is on macOS. No
  associative arrays (`declare -A`), no `mapfile`/`readarray`, no
  `${var,,}`/`${var^^}`. Use indexed arrays and `case` statements
  instead — see `alias_source()` in `claude/skills/install.sh` for the
  pattern.
- **`sed -i` needs an explicit backup suffix** (`sed -i.bak ... && rm
  -f *.bak`), not a bare `-i`. BSD sed (macOS) requires the argument;
  GNU sed (most Linux) makes it optional but accepts the same form —
  the explicit-suffix form is the only one portable to both.
- **`curl | bash` has no directory listing.** A raw GitHub URL can't
  enumerate a folder, so every installer that fetches remotely keeps
  an explicit file manifest (`skill_files()` in `install.sh`,
  `$SkillManifest` in `install.ps1`, etc). If you add a file to a
  vendored component, add it to the manifest too, or the remote
  install path silently won't fetch it — only the local-clone path
  will (it copies from `$SCRIPT_DIR` instead), so this class of bug
  won't show up in a local test.
- **Stage before swapping in.** Installers that write multiple files
  into one destination directory build the new copy in a
  `.name.toolkit-staging` dir first, then `rm -rf dest && mv staging
  dest`. A failed fetch partway through must not leave a half-written
  directory where Claude Code (or the shell) would read it — clean up
  staging on every failure path, not just the ones caught at the end.
- **Never overwrite what you don't own.** Anything Toolkit installs
  into a shared location (a skill directory, `~/.zshrc`) gets a marker
  — `.toolkit-managed` for directories, a `# >>> toolkit:... >>>` /
  `# <<< toolkit:... <<<` block for files that also hold the user's own
  content. Pre-existing unmanaged content gets backed up once
  (`<name>.toolkit-backup` / `<file>.toolkit-backup`) before being
  touched, and a malformed marker block causes the installer to refuse
  and exit rather than guess. Don't relax this to make an installer
  simpler.
- **Idempotency.** Every installer is also the update command —
  rerunning it is how a user picks up changes. Verify by running it
  twice in a row and diffing the result; it should be a no-op the
  second time.

## Vendored (not authored) content

`claude/skills/visual-plan`, `visual-recap`, and `stop-slop` are
vendored copies of other people's skills, pinned to an upstream commit
and carrying `LICENSE.upstream`. They are copies, not submodules —
nothing updates them automatically. See "Provenance" and
"Re-vendoring from upstream" in `claude/skills/README.md` before
editing one, especially `stop-slop`: it merges content from two
upstreams (hardikpandya/stop-slop and asavvin-pixel/unslop) and also
installs under a second name (`unslop`) via the alias mechanism in
`claude/skills/install.sh`/`install.ps1`. A naive re-vendor that does
`rm -rf` before copying will destroy the merged-in files
(`references/epistemics.md`, `references/style-profile-template.md`,
`LICENSE.upstream.unslop`) — the documented re-vendor steps deliberately
avoid that.

Don't reflow, "clean up," or restyle vendored prose while touching
something else in the same file — it's not this repo's writing, and
unrelated diffs make re-vendoring harder to review next time.

## Testing changes

There's no CI and no test suite. Before calling an installer change
done:

1. `bash -n <script>.sh` (or read `install.ps1` carefully — no `pwsh`
   is assumed to be available).
2. Run it against a scratch config dir, never your real one:
   `TOOLKIT_HOME=/tmp/... bash terminal/install.sh` or
   `CLAUDE_CONFIG_DIR=/tmp/... bash claude/install.sh`. Set the env var
   and run the command in the *same* Bash tool call — it does not
   persist across separate tool calls, and a dropped override means
   the "scratch" run lands in the real `~/.config/toolkit` or
   `~/.claude` instead.
3. Run it twice to check idempotency, and once against a deliberately
   broken/missing source file to check failure paths don't leave
   partial state behind.

## Committing

Only commit when explicitly asked. This repo has no remote CI gate, so
a bad commit reaches `main` (and anyone else's `curl | bash`) the
moment it's pushed — treat `main` accordingly and don't push unless
asked to.
