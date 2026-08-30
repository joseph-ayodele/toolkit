---
name: stop-slop
description: Remove AI writing patterns from prose. Use when drafting, editing, or reviewing text to eliminate predictable AI tells.
metadata:
  trigger: Writing prose, editing drafts, reviewing content for AI patterns
  author: Hardik Pandya (https://hvpandya.com); epistemics level and style-profile calibration merged in from Afanasiy's unslop (https://github.com/asavvin-pixel/unslop)
---

# Stop Slop

Eliminate predictable AI writing patterns from prose.

If `references/style-profile.md` exists, its entries override the defaults below.

## Core Rules

1. **Cut filler phrases.** Remove throat-clearing openers, emphasis crutches, and all adverbs. See [references/phrases.md](references/phrases.md).

2. **Break formulaic structures.** Avoid binary contrasts, negative listings, dramatic fragmentation, rhetorical setups, false agency. See [references/structures.md](references/structures.md).

3. **Use active voice.** Every sentence needs a human subject doing something. No passive constructions. No inanimate objects performing human actions ("the complaint becomes a fix").

4. **Be specific.** No vague declaratives ("The reasons are structural"). Name the specific thing. No lazy extremes ("every," "always," "never") doing vague work.

5. **Put the reader in the room.** No narrator-from-a-distance voice. "You" beats "People." Specifics beat abstractions.

6. **Vary rhythm.** Mix sentence lengths. Two items beat three. End paragraphs differently. No em dashes.

7. **Trust readers.** State facts directly. Skip softening, justification, hand-holding.

8. **Cut quotables.** If it sounds like a pull-quote, rewrite it.

9. **Don't invent specifics.** Numbers, quotes, names, and thresholds must trace back to the source or the user. Mark computed claims and judgment calls as such instead of stating them as fact. Allow uneven confidence instead of hedging (or asserting) uniformly. Stop the ending cleanly instead of restating the point. See [references/epistemics.md](references/epistemics.md).

## Quick Checks

Before delivering prose:

- Any adverbs? Kill them.
- Any passive voice? Find the actor, make them the subject.
- Inanimate thing doing a human verb ("the decision emerges")? Name the person.
- Sentence starts with a Wh- word? Restructure it.
- Any "here's what/this/that" throat-clearing? Cut to the point.
- Any "not X, it's Y" contrasts? State Y directly.
- Three consecutive sentences match length? Break one.
- Paragraph ends with punchy one-liner? Vary it.
- Em-dash anywhere? Remove it.
- Vague declarative ("The implications are significant")? Name the specific implication.
- Narrator-from-a-distance ("Nobody designed this")? Put the reader in the scene.
- Meta-joiners ("The rest of this essay...")? Delete. Let the essay move.
- Any specific number, quote, or name that isn't traceable to a source? Cut or flag it.
- Ending restates or summarizes instead of just stopping? Cut the restatement.

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

## Examples

See [references/examples.md](references/examples.md) for before/after transformations.

## Voice calibration (optional)

On "calibrate to my style," fill in [references/style-profile-template.md](references/style-profile-template.md) from 3-5 AI-free writing samples and save it as `references/style-profile.md`. Until that file exists, rules above run on their defaults.

## License

MIT (stop-slop core, Hardik Pandya). Epistemics level and style-profile template adapted from unslop (MIT, Afanasiy/asavvin-pixel) — see references/epistemics.md and references/style-profile-template.md.
