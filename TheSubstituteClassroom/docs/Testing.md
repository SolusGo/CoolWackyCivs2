# Testing

**Native Civ V gameplay, rendering and save serialization: NOT TESTED IN GAME.** No claim of completed native compatibility or measured native FPS is made.

Run from the repository with Python 3.11+ and requirements-dev.txt installed (the development checkout also has `.venv/Scripts/python.exe`):

```powershell
python tools/generate_garvey.py
python tools/build_mod.py --manifest-only
python tools/validate_garvey.py
python tools/validate_mod.py
python tools/benchmark.py
python tools/build_mod.py
python tools/verify_release.py
```

The Classroom validator clones the installed BNW debug database read-only, adds installed CP schema in memory and applies all released SQL before the new content. It checks human-only setup flags, replacements, complete scalar/companion inheritance, changed-base schema fixtures, exact configured modifiers, English references and preservation of peer rows/IDs. It decodes all 41 DDS textures, validates mip/legacy headers, atlas indices and the five-choice XML.

Shipped gameplay and UI Lua execute under **Lua 5.1** with a mocked native boundary. Six lifecycle, combat, UI, persistence, audit/performance and fault scenarios each run on four named speed settings and at turns 0 and 150 (**48 runs**). The runtime intentionally never queries a speed multiplier. Coverage includes the original timing, progression, rewards, lifecycle, saves and modal gates, plus isolated/mutated UnitPrekill SQL, native-shaped pre-deletion razing, scripted real/free Office changes, dummy repair, all four patience pip states, transient storage/native setter faults, and **201 cities/2,003 units** with 1,000 separate UI-dirty frames causing zero Lua city/unit scans or building/promotion reads. These are arithmetic/API-contract models, not native yields, localization/font measurements, save serialization or FPS benchmarks. See [AuditReport.md](AuditReport.md) for exact fixes and evidence. Artwork is reused; routine validation does not require regeneration.

Pinned CP source checks document economic turn order, event argument order, additive promotions, territory handling, upgrade loss, kill strength scaling and signed policy Happiness. Art previews were visually inspected outside the game. The full collection regression runner includes the Classroom suite; package verification compares generated ZIP bytes and extracted genuine 7z/LZMA contents.

## Outstanding native acceptance

1. Install CP v151 plus collection v12 only. Confirm Mr. Garvey appears for the human and never in normal AI selection/random opponents. Inspect icon/flag, loading text, static diplomacy and Civilopedia.
2. On Quick, Standard, Epic and Marathon, found the capital on a known turn. Check first availability exactly 12 turns later, waiting through multiple turns and save/load before selecting. Check all five choices, RNG outcomes and 12-turn cooldown from selection.
3. Record native yields on each of the eight settlements and combat bonuses during the eight action turns. Save/reload before/after expiry and during the interturn; verify no ninth harvest. Repeat for five-turn Detention, including a Buh-Lah-Kay trigger (+35% additive empire strength).
4. Verify 0/1/2 Insubordination persists across saves, era changes, capital loss and capture. Trigger a third correction: a single notice, immediate counter reset, displayed Detention duration, no later lingering modifiers.
5. Compare actual Happiness before/during/after Detention: -2 with no Office, -1 with one or five Offices. Sell, rebuild, capture, gift and lose Offices/capital during the state. Verify local Office Science and clean foreign ownership.
6. Train, purchase, spawn, upgrade and gift units during both temporary states. Verify civilians receive no combat promotion, Hall training expires on upgrade, and eligible upgraded units retain only the current empire effects.
7. Kill military units using Hall Monitors on friendly and hostile battle tiles, ordinary units, defensive wins and city bombardment. Check max base melee/ranged strength, rounding/minimum, two rewards only when both effects qualify, and no reward for civilians/survivors/city capture. Check nuclear collateral, delayed/final callbacks across a reload and naval/air/interception outcomes separately.
8. Open/close diplomacy, cities, technology, Civilopedia, all relevant popups and Strategic View while the attendance panel is open. Confirm hidden launcher/panel, no click-through, duplicate controls or callbacks after load, and correct active-human gate.
9. Inspect Database.log/Lua.log and play a large late-game map alongside every existing collection civilization. Measure native FPS with panel open/closed and confirm zero idle update callbacks. Test older-save continuation on a backup separately.
