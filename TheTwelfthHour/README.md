# The Twelfth Hour

**The Keeper of Seconds** rules from **Last Minute**. A human-playable industrial clockwork civilization for Civilization V: Brave New World and Windows Community Patch **v151**. `Playable=1`, `AIPlayable=0`.

| Component | Effect |
| --- | --- |
| When the Clock Strikes | Every sixth played turn, every owned city receives +75% Production and +50% Science for one turn. |
| Pendulum Guard (Pikeman) | All active Pikeman properties/promotions, plus an upgrade-retained promotion with +1 Movement and +15% strength in friendly territory. |
| Municipal Clocktower (Workshop) | All active Workshop properties/related rows, +1 permanent Culture, and +2 flat Production only during a Grand Chime. |

The Grand Clock uses `Game.GetGameTurn() - Game.GetStartTurn() + 1`. Played turns 1–5 are normal; 6, 12, 18, 24… chime at every game speed. Founding, conquest, capital changes, eras and loading never restart the clock. The city Production modifier follows the engine's normal rules for units, buildings, wonders and projects. The Clocktower's flat Production enters those same rules; other modifiers remain additive as the engine defines them.

Build several well-developed cities and plan important construction around the Chime. Science is the preferred victory; synchronized industry can support Domination. Clocktower Culture and a productive economy also support cultural or diplomatic alternatives. Pendulum Guards move between threatened cities and fight effectively in friendly territory.

One notification announces each Chime and identifies the next six-turn interval. There is no custom top-panel replacement or continuously updated countdown. Original painted civilization/unit/building icons, leader scene, Dawn of Man illustration, monochrome alpha/flag assets and complete English Civilopedia/diplomacy text are included. The unit uses the existing Pikeman battlefield model; diplomacy uses a static illustrated leader scene and generic fallback responses for situations beyond the custom greeting/war/peace/defeat lines. No custom audio or 3D model is required.

## Installation and verification

Use the collection's generated ZIP or `.civ5mod`; enable BNW, CP v151 and Cool Wacky Civs 2 in the Mods menu. Choose **The Keeper of Seconds** in single-player setup. No DLL replacement is included. The existing collection UUID, version 8 and minimum compatible save version remain unchanged; the new SQL loads after all released content so existing insertion order is preserved.

```powershell
.venv/Scripts/python.exe tools/generate_twelfth.py
.venv/Scripts/python.exe tools/prepare_twelfth_art.py
.venv/Scripts/python.exe tools/build_mod.py
.venv/Scripts/python.exe tools/validate_mod.py
```

See [implementation and native timing limits](docs/Implementation.md), [all 20 required test scenarios](docs/Testing.md), and [source contracts](docs/SourceAudit.json).

The [second-pass technical audit](docs/AuditReport.md) fixes the Firaxis save-function calling convention, adds bounded synchronous error recovery and reliable notification marking, and removes unnecessary post-sale delay. Its 20 Lua suite runs include real fixture snapshots, separate same-turn games and pre-staging autosaves; 43 pinned CP contracts and installed save-API evidence support the implementation. All gameplay numbers, SQL, art, human-only flags and existing save keys are preserved.

**Verification status:** SQL on BNW/CP schemas and a read-only copy of the active cache, Lua 5.1 simulations and source contracts pass. Native Civ V was **not launched** for this implementation. Actual construction/research settlement, rendered UI, and native save/load round trips remain manual acceptance checks. A mock is not proof of engine behavior.
