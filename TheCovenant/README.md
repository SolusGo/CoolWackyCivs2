# The Covenant — Written on the Heart

The Scribe leads a fictional, human-only civilization built for memorising five NIV Bible passages. Requires **Cool Wacky Civs 2 v24**, Brave New World and Windows Community Patch v151. Start a new modded single-player game as **The Scribe / Covenant**.

## Civilization

| Feature | Effect |
| --- | --- |
| Written on the Heart | +1 Culture in each city. An unaided review gives 10 Faith and 5 Culture × (era index + 1), once per turn even during an exam. |
| Scriptorium | Shrine replacement: 2 Faith and 1 Culture. Copies Shrine cost, technology and maintenance; original building portrait. |
| Tabernacle | Temple replacement: 3 Faith and 1 Science. Copies Temple cost, technology, maintenance and prerequisite building classes; original building portrait. |
| Appearance | Original navy-and-gold Scripture/quill emblem, Scribe portrait and static leader scene, building paintings, loading art, fictional map and matching recall-panel textures. |

## The memory contract

The first five campaign turns introduce Revelation 3:17–18, Hebrews 9:8, Malachi 3:1, Hebrews 8:5 and the corrected John 14:29, in that order. The supplied wording is stored in `Lua/CovenantVerses.lua`.

Study the full passage in numbered sections for at least 12 seconds, with more time for longer text. Hide it, type its book/chapter/verse reference from the theme cue, then type every section in order. Section word counts identify typing boundaries. Click **Check recall** after each answer.

For section recall, case, punctuation, curly quotes and extra spaces are ignored. References require the correct book, chapter and exact verse/range with a colon; spaces and hyphen/en-dash formatting are flexible. Missing, extra, reordered or misspelled words fail. A mistake restarts the entire passage from its reference and removes the unaided reward. **Study again** reveals the text for another timed study, then requires a fresh complete attempt. Large pasted text changes are rejected; text-change callbacks cannot reliably identify every clipboard action or distinguish batched input from paste.

The modal gate has no skip/close button. Escape, Return, game shortcuts and outside clicks do not dismiss it. Complete recall resumes play. Other civilizations, AI players, network games and hotseat do not receive this gate.

After introductions, the most overdue passage returns, at most one ordinary passage per turn. Unaided successes expand its review interval to 2, 4, 8 and 12 turns. A studied or failed attempt returns the next turn; the one-per-turn limit can delay overdue reviews. Every tenth campaign turn requires **all five** in rotating order. Three consecutive unaided reviews mark mastery, but reviews continue.

The save-data store records the unfinished queue, current section, assistance, mistakes and schedule after every submitted action. Changing a passage's wording or reference gives it a new progress identity. Native save-file round trips remain a manual acceptance test.

The v24 reliability revision preserves existing progress keys and migrates valid schema 1 progress to schema 2, which also journals the reward-turn limit. Back up a save before upgrading if you may return to the original schema-1-only mod. A carried session uses its completion turn for the next review; a due examination is resolved before unlocking. See the [audit report](docs/AuditReport.md) for validation and remaining native limits.

This is a strict practice tool inside a normal modded game. It cannot prevent consulting another screen, disabling/editing the mod or loading an earlier save.

## Play and strategy

Enable **Community Patch** and **Cool Wacky Civs 2** through MODS, choose version 24, enter modded single-player setup, then select The Scribe. Do not enable the old standalone Covenant alongside the collection.

Build a Scriptorium early and defend normally. Your Faith and Culture support conventional religious and cultural development; successful memory does not replace food, production or an army. Study aloud, connect the ideas, and use the repeating exams for maintenance.

[Strategy guide](../docs/strategy/TheCovenant.md) · [Implementation](docs/Implementation.md) · [Testing](docs/Testing.md)

[Art sources, exact prompts and compilation](../art-source/TheCovenant/README.md). The game-ready set uses the collection's nine atlas sizes, gold rims, transparent portrait padding, monochrome alpha/flag convention and full-mip legacy DDS format. The leader scene is a static illustration; native 3D building/unit models remain inherited. Native rendering acceptance remains pending.

Scripture quotations taken from The Holy Bible, New International Version®, NIV®. Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.® Wording supplied by the player for this personal learning mod. Original AI-generated paintings and procedural heraldry/UI textures are bundled; no extracted proprietary stock artwork is redistributed.
