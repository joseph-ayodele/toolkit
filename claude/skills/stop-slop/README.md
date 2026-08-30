# Stop Slop

A skill for removing AI tells from prose.

<img width="3840" height="2160" alt="G-Yg4RVbIAAhVxW" src="https://github.com/user-attachments/assets/902afc15-1f40-4a9d-af24-8cd67afb8ebf" />

## What this is

AI writing has patterns. Predictable phrases, structures, rhythms. This skill teaches Claude (or any LLM) to catch and remove them.

## Skill Structure

```
stop-slop/
├── SKILL.md                       # Core instructions
├── references/
│   ├── phrases.md                 # Phrases to remove
│   ├── structures.md              # Structural patterns to avoid
│   ├── examples.md                # Before/after transformations
│   ├── epistemics.md              # What the text is allowed to claim
│   └── style-profile-template.md  # Voice calibration template
├── README.md
├── LICENSE.upstream
└── LICENSE.upstream.unslop
```

This vendored copy also merges in content from
[asavvin-pixel/unslop](https://github.com/asavvin-pixel/unslop) (MIT):
`references/epistemics.md` and `references/style-profile-template.md` are
adapted from unslop, not from the original stop-slop. See
`claude/skills/README.md` in the toolkit repo for full provenance. This
merged skill installs as either `stop-slop` or `unslop`.

## Quick start

**Claude Code:** Add this folder as a skill.

**Claude Projects:** Upload `SKILL.md` and reference files to project knowledge.

**Custom instructions:** Copy core rules from `SKILL.md`.

**API calls:** Include `SKILL.md` in your system prompt. Reference files load on demand.

## What it catches

**Banned phrases** - Throat-clearing openers, emphasis crutches, business jargon, all adverbs, vague declaratives, meta-commentary. See `references/phrases.md`.

**Structural clichés** - Binary contrasts, negative listings, dramatic fragmentation, rhetorical setups, false agency, narrator-from-a-distance voice, passive voice. See `references/structures.md`.

**Sentence-level rules** - No Wh- sentence starters, no em dashes, no staccato fragmentation, no lazy extremes, active voice required.

**Invented specifics and over-resolved endings** - Numbers, quotes, and thresholds must trace to a source; computed claims and judgment calls get marked as such; conclusions stop instead of restating themselves. See `references/epistemics.md`.

**Voice calibration** - Optional. On "calibrate to my style," fill in `references/style-profile-template.md` from the author's own AI-free samples and save it as `references/style-profile.md`.

## Scoring

Rate 1-10 on each dimension:

| Dimension | Question |
|-----------|----------|
| Directness | Statements or announcements? |
| Rhythm | Varied or metronomic? |
| Trust | Respects reader intelligence? |
| Authenticity | Sounds human? |
| Density | Anything cuttable? |

Below 35/50: revise.

## Author

[Hardik Pandya](https://hvpandya.com) (base skill). Epistemics and voice-calibration content adapted from [Afanasiy's unslop](https://github.com/asavvin-pixel/unslop).

## License

MIT. Base skill © Hardik Pandya (`LICENSE.upstream`); merged-in epistemics/style-profile content © Afanasiy (`LICENSE.upstream.unslop`).
