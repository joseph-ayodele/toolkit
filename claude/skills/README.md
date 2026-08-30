# claude/skills

Claude Code skills, vendored into this repo and installed into
`~/.claude/skills/`. Claude Code loads anything in that directory
automatically, so each one shows up as `<name>@skills-dir` — no
marketplace, no plugin install, no network at load time.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/skills/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/skills/install.ps1 | iex
```

Restart Claude Code afterwards to pick up the new skills.

To install or update a single skill, pass its name:

```sh
./claude/skills/install.sh visual-plan
```

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/joseph-ayodele/toolkit/main/claude/skills/install.sh)" -- visual-plan
```

## Skills

| Skill | How it's invoked | What it does |
| --- | --- | --- |
| [`visual-plan/`](visual-plan) | `/visual-plan` | Turns a text plan into an interactive visual plan — diagrams, file maps, annotated code, open questions, optional wireframe/prototype canvas. |
| [`visual-recap/`](visual-recap) | `/visual-recap` | Turns a PR, branch, commit, or diff into a visual recap — the same plan model pointed backwards at work already done. |
| [`stop-slop/`](stop-slop) (also installable as `unslop`) | Model-invoked | Strips AI writing tells out of prose: filler phrases, formulaic contrasts, passive voice, em dashes, pull-quote endings, invented specifics, over-resolved conclusions. Applies while drafting or editing rather than being called by name. |

None of these ship a `commands/` directory — each is a plain skill, and
Claude Code surfaces it once it loads as `<name>@skills-dir`. Upstream
documents the two visual ones as `/visual-plan` and `/visual-recap`;
stop-slop is written to trigger on its own when you're working on prose.

`stop-slop` works offline with nothing else installed. The two
`visual-*` skills don't — see [below](#these-two-skills-need-a-backend).

### Provenance

Every skill here is a vendored copy, pinned to the upstream commit it
was taken from, with its upstream license kept alongside it as
`LICENSE.upstream`.

| Skill | Upstream | License | Pinned at |
| --- | --- | --- | --- |
| `visual-plan`, `visual-recap` | [BuilderIO/skills](https://github.com/BuilderIO/skills) | MIT © Builder.io | [`0ecfb56`](https://github.com/BuilderIO/skills/commit/0ecfb56f3bf78b9d957246789379f3f78e2f85ec) |
| `stop-slop` (base) | [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) | MIT © Hardik Pandya (`LICENSE.upstream`) | [`8da1f03`](https://github.com/hardikpandya/stop-slop/commit/8da1f030185bdfe8471220585162991eaeb970e9) |
| `stop-slop` (epistemics.md, style-profile-template.md) | [asavvin-pixel/unslop](https://github.com/asavvin-pixel/unslop) | MIT © Afanasiy (`LICENSE.upstream.unslop`) | commit current as of 2026-08 |

`stop-slop` merges both upstreams: it took hardikpandya/stop-slop as its
base (Level 1/2 rules, scoring rubric, phrase/structure blacklists — these
were already more thorough than unslop's equivalent) and added unslop's
Level 3 epistemics rules and its style-profile-template, which stop-slop
didn't have. unslop's `prose-benchmarks.md` and `examples/mindfulness.md`
were left out as redundant with what stop-slop already covers, and its
`README.md`/`LICENSE`/`.gitignore` repo cruft was never vendored.

The same merged content installs under either name — see
[Aliases](#aliases) below.

## These two skills need a backend

This applies to `visual-plan` and `visual-recap` only; `stop-slop` is
self-contained.

Neither visual skill renders anything by itself — the files here are
just Markdown instructions. Both are clients for Builder.io's
Agent-Native Plans service, and by default they publish through its
hosted MCP connector at `plan.agent-native.com`. The skills explicitly
refuse to fall back to inline chat output, so with no backend
reachable `/visual-plan` doesn't produce a worse plan; it stops and
asks you to connect.

Toolkit deliberately does **not** register that connector. Publishing
sends the plan's content — file maps, annotated code, diffs — to a
third-party host, which is a decision worth making per machine rather
than inheriting from a dotfiles install. Use local-files mode below,
or register the connector yourself:

```sh
claude mcp add --transport http --scope user plan https://plan.agent-native.com/mcp
```

```sh
claude mcp login plan
```

## Local-files mode (no hosted publish)

Both visual skills support a local-files privacy mode that skips the
hosted service: plan content is written as MDX under your own repo and
previewed through a localhost bridge, never uploaded. Turn it on for
a single run by asking for a local/private/no-database plan, or make
it the default:

```sh
export AGENT_NATIVE_PLANS_MODE=local-files
```

In this mode the skill writes a plan directory — `plans/<slug>/` to
check the artifact into the repo, or `.agent-native/plans/<slug>/` for
a throwaway — holding `plan.mdx` plus optional `canvas.mdx` and
`prototype.mdx`. Preview is driven by the upstream CLI, so this path
needs `node`/`npx` rather than an MCP connector:

```sh
npx -y @agent-native/core@latest plan local check --dir plans/<slug>
```

```sh
npx -y @agent-native/core@latest plan local serve --dir plans/<slug> --kind plan --open
```

Worth knowing before you rely on it:

- The preview still loads the hosted Plan UI in your browser, but it
  reads the content from the localhost bridge. On macOS open it in a
  Chromium browser — Safari can block the hosted HTTPS page from
  fetching the HTTP localhost bridge.
- `serve` writes a `<plan-dir>/.plan-url` token file. Don't commit it.
- Hosted comments, sharing, export, and history aren't available —
  feedback is just editing the MDX and re-running `check`.
- It keeps plan content off the Plan server. It does not make the
  agent local; the model still sees everything it normally would.

## Aliases

`stop-slop` can also be installed as `unslop` — same files, fetched from
`stop-slop/`, written into `~/.claude/skills/unslop/` with only the
`SKILL.md` `name:` field swapped so it self-identifies correctly:

```sh
./claude/skills/install.sh unslop
```

```sh
.\claude\skills\install.ps1 -Skill unslop
```

The default no-argument install only installs canonical skills
(`visual-plan`, `visual-recap`, `stop-slop`); an alias has to be named
explicitly, same as installing one specific skill by name.

Aliases are for giving one vendored skill another install name, not for
vendoring a second skill's content — that's a real entry in `ALL_SKILLS`
(and `skill_files()`) instead. To add an alias for a skill already vendored
here:

1. Add a case line to `alias_source()` and a name to `ALIAS_NAMES` in
   `install.sh`.
2. Add an entry to `$SkillAliases` in `install.ps1`.
3. Nothing else — `skill_files()`/`$SkillManifest` lookups, staging, and
   the `name:` swap all key off the alias table.

## Re-vendoring from upstream

These are copies, not submodules — nothing updates them for you. The
upstream layouts differ: BuilderIO keeps each skill under `skills/`
in a monorepo, while stop-slop's repo root *is* the skill.

```sh
git clone --depth=1 https://github.com/BuilderIO/skills.git /tmp/builderio-skills
for s in visual-plan visual-recap; do
  rm -rf "claude/skills/$s"
  cp -R "/tmp/builderio-skills/skills/$s" "claude/skills/$s"
  cp /tmp/builderio-skills/LICENSE "claude/skills/$s/LICENSE.upstream"
done
```

```sh
git clone --depth=1 https://github.com/hardikpandya/stop-slop.git /tmp/stop-slop
cp -R /tmp/stop-slop/SKILL.md /tmp/stop-slop/README.md claude/skills/stop-slop/
cp -R /tmp/stop-slop/references/. claude/skills/stop-slop/references/
cp /tmp/stop-slop/LICENSE claude/skills/stop-slop/LICENSE.upstream
```

This overwrites `SKILL.md`/`README.md` wholesale and copies in any new or
changed reference files upstream added, but doesn't `rm -rf` the directory
first — `references/epistemics.md`, `references/style-profile-template.md`,
and `LICENSE.upstream.unslop` are merged in from unslop, not from
hardikpandya/stop-slop, and would be lost by a blanket wipe. If upstream
stop-slop's `SKILL.md` changes structurally, re-apply the epistemics rule
(item 9) and the voice-calibration section by hand — they don't exist
upstream to merge automatically. To re-vendor the unslop half instead:

```sh
git clone --depth=1 https://github.com/asavvin-pixel/unslop.git /tmp/unslop
cp /tmp/unslop/LICENSE claude/skills/stop-slop/LICENSE.upstream.unslop
# then hand-port any changes to references/epistemics.md and
# references/style-profile-template.md — these are adapted, not copied
# verbatim, so there's no source file to diff against directly.
```

Then update the file manifests in `install.sh` and `install.ps1` if
upstream added or removed files, and update the pinned commits in the
provenance table above. The manifests are how the `curl | bash` path
knows what to fetch — raw GitHub URLs can't list a directory — so a
file missing from one is a file that never lands on a fresh machine.

## Adding a skill

1. Drop the skill directory in here (it needs a `SKILL.md` with
   `name` and `description` frontmatter).
2. If it came from someone else, copy its license in as
   `<skill>/LICENSE.upstream` so the installed copy carries it too.
3. Add its name to `ALL_SKILLS` and its files to `skill_files()` in
   `install.sh`.
4. Add the same entry to `$SkillManifest` in `install.ps1`.
5. Add rows to the skills and provenance tables above.

## Ownership and reruns

Reinstalling is the update command, and it is safe to run repeatedly:

- Each install stages the whole skill in a temp directory first, then
  swaps it into place. A failed download leaves the previously
  installed copy untouched rather than a half-written skill.
- A `.toolkit-managed` marker file is written into every installed
  skill. Directories carrying it are Toolkit's, and get replaced
  wholesale on each run — which is how files deleted upstream also
  disappear locally.
- A skill directory that already exists *without* that marker is
  yours, not Toolkit's. It gets copied to `<name>.toolkit-backup`
  before being replaced, once — subsequent runs won't overwrite that
  backup.
- A skill path that is a symlink is left alone entirely and the
  install fails loudly, on the assumption another tool manages it.
- Everything else in `~/.claude/skills/` is never touched.

Since installed copies get replaced, edit skills in this repo and
rerun the installer rather than editing `~/.claude/skills/` in place.
