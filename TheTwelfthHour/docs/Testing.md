# Validation and native acceptance checklist

Date: **19 October 2026**. **Civ V was not launched. No native gameplay scenario is claimed passed.**

Automated commands:

```powershell
.venv/Scripts/python.exe tools/validate_twelfth.py
.venv/Scripts/python.exe tools/validate_mod.py
.venv/Scripts/python.exe tools/build_mod.py
```

Static validation executes SQL in memory against the installed BNW/CP schema and a read-only copy of the current active cache. It checks all preexisting rows remain unchanged (except enabling required event options), human-only flags, every scalar/direct companion inherited from Pikeman/Workshop, an altered baseline with extra CP columns and preexisting Workshop Culture, exact dummies, promotions, class overrides, city names, localization, DDS/atlas references and integrity. The full collection validator also parses every Lua file under Lua 5.1 and checks manifest/project order, MD5, VFS uniqueness, decoded DDS files and all prior civilization regression suites.

The original Twelfth fixture runs 24 turns in each of **five speeds and two start turns** (0 and 150), sampling SQL-backed illustrative Production/Science BEFORE `PlayerDoTurn`. Its context reloads, notifications, dirty storms, city/building lifecycle and invalid-player cases remain covered. The audit suite adds snapshots that restore player/city state and the per-save database, same-turn A/B games, rewinds, old absent-key saves, pre-staging autosaves at 5/6 and 11/12, transient/persistent faults and notification recovery: **20 suite runs total**. Save functions strictly enforce the installed Firaxis dot-call contract; sales now follow CP's post-removal callback. These are **mocked Lua** tests, not the native governor, research cache, queue, localization DLL or serializer. **43** pinned official CP v151 source contracts check native order, autosave/serializer flags, yield expressions, lifecycle hooks, promotion transfer and event ABI. CP-derived arithmetic models separately cover additive/item/Golden Age modifiers, overflow, post-modifier/trade yields, suppression and rounding. See [AuditReport.md](AuditReport.md) for confirmed issues and limits.

| # | Required scenario | Automated evidence | Native status |
| --- | --- | --- | --- |
| 1 | New game has no Chime | Explicit context initialization, raw 0 | Pending |
| 2 | Turns 1–5 normal | All five pre-hook fixture harvests | Pending |
| 3 | Turn 6 bonuses | Raw 5 pre-hook model + exact SQL modifiers | Pending |
| 4 | Turn 7 removes temporary effects | Next-turn staging, raw 6 model | Pending |
| 5 | Turn 12 activates again | 24-turn schedule | Pending |
| 6 | Real construction progress | Production source path + illustrative harvest model | **Pending actual queue delta** |
| 7 | Real research progress | Research source path + illustrative harvest model | **Pending actual beaker delta** |
| 8 | Clocktower +1 permanent Culture | Additive SQL assertion including baseline Culture | Pending |
| 9 | Clocktower +2 flat Production only on Chime | SQL and dummy lifecycle assertions | Pending |
| 10 | No Clocktower, no flat bonus | Separate city and captured city assertions | Pending |
| 11 | Multiple cities receive modifiers | Multi-city assertions | Pending |
| 12 | Founded city joins current cycle | Founded event assertions | Pending |
| 13 | Captures follow owner rules | Conquest/gift/liberation and foreign cleanup assertions | Pending |
| 14 | Guard Movement and friendly strength | Inheritance, promotion values, native friendly modifier path | Pending combat/upgrade test |
| 15 | Save during Chime, no stacking/replayed notice | Actual fixture snapshots/rewinds, same-turn A/B games, strict save API | Pending native round trip |
| 16 | Save outside Chime preserves cycle | Active/interturn loads, absent-key saves and pre-staging autosave models | Pending native round trip |
| 17 | Other civilizations gain nothing | Foreign cleanup and all prior SQL rows preserved | Pending |
| 18 | Speeds keep six-turn cycle | Quick, Standard, Epic, Marathon, custom fixture | Pending |
| 19 | No early/late actual harvest | Pre-hook fixture, serialized flag/resume contracts, pre-staging autosave and synchronous failure models | **Pending native timing and autosave test** |
| 20 | Text, DDS, modinfo load | Localization references, atlas decoding, full package checks | Pending native render/log inspection |

## Native procedure

1. Install the generated package with only CP v151, BNW and the collection enabled. Choose Keeper of Seconds, found Last Minute, choose research and a long build. Watch `Database.log`, `Lua.log` and `xml.log` for errors. Confirm no Twelfth civilization is assigned to ordinary AI slots.
2. Record **both** `Game.GetGameTurn()` and `Game.GetStartTurn()` in FireTuner. Use played turn `raw-start+1`; the vanilla turn label may begin at zero. Check both dummy counts are zero through the active fifth turn. Do not confuse staging while other players act with an economic credit.
3. Keep population, worked tiles, trade routes, specialists, policies, Golden Ages, happiness, resource eligibility and build item stable across turns. Record stored construction and team research progress immediately before ending played turn 5 and upon entering 6. Include item-specific modifiers and any tech completion/overflow in the comparison. Ensure the Chime is included in those **actual stored deltas**, and removed from the deltas entering 7. Repeat at 12 and 13. A tooltip alone is insufficient.
4. Repeat with a unit, ordinary building, wonder and project in progress. Compare a city with a Clocktower and one without; the former should gain two base Production during Chime and exactly one additional Culture every turn relative to the active CP Workshop. Verify actual engineer slots, resource/tech requirements, Workshop modifiers and CP specialist behavior are preserved.
5. Found/acquire a second city during normal and Chime turns. Capture, gift, liberate and recapture cities across owners, including a city whose local ID collides with another owner's. Foreign owners must have neither dummy. Complete and purchase a Clocktower on Chime; sell or script-remove it. Confirm conditional Production disappears and construction rewards do not fire for dummy changes.
6. Train a Guard alongside the active CP Pikeman, compare Movement and inherited promotions, inspect +15% friendly combat strength for both attacking and defending, test neutral/enemy territory, then upgrade it and verify the custom promotion remains once. Friendly territory follows native diplomatic/battle-plot rules.
7. Save/reload active turns 5, 6, 7 and 12, then save during AI processing immediately after ending 5 and 6. Compare dummy counts, cycle, actual next harvest, notification count and researched progress. **Separately load the engine-created end-turn autosave**: CP writes it before `PlayerDoneTurn`, so its resumed transition needs real verification. Also test a turn-start autosave. Record whether native transitions replay, rather than assuming ordinary active-save behavior.
   Switch between two independently created games saved at the same raw/start turn, and rewind to an earlier save from before notification delivery. Test manual, quick and auto saves; the provider must restore each save's own keys and native city state. Existing v1 keys are retained by the audit fix.
8. Repeat the boundary tests at Quick/Epic/Marathon and an advanced-era start. Change era/capital between Chimes; destroy the last city, revive through a scenario if available, and verify no errors with no cities or an AI-controlled Twelfth player. Check icons in setup, Civilopedia, city lists, unit flags, diplomacy and Dawn of Man at representative UI scales.

No synthetic yield compensation, balance changes or unsupported pre-turn API is used to hide native limitations. See [Implementation.md](Implementation.md) for the interturn staging and first-install-after-harvest limits.
