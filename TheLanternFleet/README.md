# The Lantern Fleet

High Keeper Maren leads a human-selectable defensive maritime civilization for **Brave New World + Community Patch v151 (CP only)**. Capital: **First Beacon**. Preferred victories: Science / Culture. This is source-complete with original art; **native turn-event dispatch and same-turn economic settlement remain an integration acceptance requirement**, not a passed test.

| Unique | Effect |
| --- | --- |
| **No Harbor Goes Dark** | At owner-turn start, each native coastal city with an owned naval combat unit physically inside its city-center plot receives +2 Science / +1 Culture for that snapshot. |
| **Beacon Cutter** | Active Trireme replacement; +1 Sight and +15% Strength in native friendly territory, on attack and defense. Ordinary CP stats, costs, requirements, model and upgrades are inherited. The unique promotion follows normal retention on upgrade. |
| **Signal Lighthouse** | Active Lighthouse replacement; all normal effects plus +1 permanent Culture. At a qualifying Guarded Harbor snapshot, adds +2 Gold. |

One qualifying ship is enough. Extra ships never stack. Cargo Ships, civilians, embarked land units, dead/delayed-death units and any foreign owner's ships do not qualify. Adjacent ships do not qualify. Later eligible naval military units work. Native coastal status is required independently of the ship.

With a Signal Lighthouse and a qualifying guard, the added base yields are **+2 Science, +2 Culture, +2 Gold**. None scales with era; ordinary engine yield modifiers still apply. The Lighthouse's +1 Culture needs no ship.

The two hidden real-building counts represent a fixed snapshot. Moving in after the check waits until next turn; moving out afterward keeps this turn's snapshot. A Lighthouse completed after the check also waits for the next snapshot for conditional Gold. Loading does not reevaluate or pay an extra reward. City capture clears both conditional buildings immediately, even when the recipient is another Lantern player. Its next genuine turn-start check uses actual ownership.

Selection is human-only (`Playable=1`, `AIPlayable=0`); scripted/scenario AI Lantern players still run the same ownership-based rules. No starting ships, unit spawning, era multipliers, extra resources or custom gameplay panel are added.

Build through the collection's Python file builder; ModBuddy is optional. Enable CP v151 and this collection through Mods. Start a new game to choose Maren; released civilization IDs and ScriptData formats are preserved. Native compatibility of existing saves is unverified.

[Implementation and source timing evidence](docs/Implementation.md) · [Executed tests and native acceptance procedure](docs/Testing.md) · [Machine-readable validation](docs/Validation.json) · [File inventory](docs/Files.md)
