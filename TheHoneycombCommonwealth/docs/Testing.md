# Validation and native acceptance

Run with the existing repository environment:

```powershell
.\.venv\Scripts\python.exe tools/validate_honeycomb.py
.\.venv\Scripts\python.exe tools/validate_mod.py
```

**Executed 2026-10-30:** both commands completed with exit code **0**. All focused HCC SQL/Lua/source/art/manifest checks passed, as did the full collection regression suite. `git diff --check`, Python syntax, new documentation links, released manifest record order and unchanged dependency checks also passed. [Validation.json](Validation.json) retains the result summary. Regenerated timing reports for other civilizations were excluded from this change.

The focused validator executes shipped SQL against the installed BNW backup reconstructed with CP v151 schema, after the entire released collection; compares all existing rows; checks Scout/Market rows and companion inheritance; and repeats with altered baselines. It parses Lua 5.1 and drives actual HCC callbacks with mocks. It now verifies **77 source contracts**, including ten independently downloaded official file hashes, all complete DDS mip payloads/atlas references, immutable dialogue/Dawn hashes, manifests/VFS/order and dummy class isolation. The collection validator covers existing civ regressions, all Lua, icon framing, project/modinfo inventory and namespaces. No release packaging is needed.

The corrective audit adds `honeycomb_hardening.lua` (16 adversarial lifecycle/fault cases), `honeycomb_payout.lua` (SQL-backed, source-supported settlement arithmetic) and `honeycomb_scale.lua` (34 players, 680 additional cities, 4,000 foreign dirty events and 100 duplicates). All scenarios run in Standard and Marathon contexts. The original source was separately exercised to reproduce all eight reported defects before correction. See [audit](CorrectiveAudit.md) and [mock performance](Performance.json).

| Test | Automated evidence | Native acceptance |
| --- | --- | --- |
| A, B | Actual Lua: 0–8 Plantations, exact Production/Culture caps | Observe displayed/earned yields |
| C, D | SQL Food and unchanged Market effects; Lua Gold with/without/free Exchange | Observe specialists, Food and Gold payout |
| E | Own four, work one → +1 Production only | Actual citizen assignments |
| F | Pillaged Plantation excluded at staging | Pillage/repair/boundary |
| G | Midturn dirty events and repeated callbacks never recount | Reassign in playable turn |
| H | Context/load events and partial-load dirty events preserve dummies and duplicate receipt | Save/reload midturn and autosaves |
| I | Foreign/HCC captures and gifts clear markers; removed-city callbacks safe | Conquest, gift, liberation, razing |
| J | Every Scout column/companion, Moves+1, Sight-only promotion/native upgrade source | Train, explore, embark and upgrade |
| K | All existing DB rows unchanged; foreign Lua city retains ordinary buildings | Another civ's Market/Scout/Plantations |
| L | Actual Lua empire totals: Production 7, Culture 2, Food 3, Gold 3 | Four-city scenario |
| M | Duplicate/unchanged snapshots perform zero writes; post-mutation fault retry | Actual repeated notifications |
| N | Source proves late PlayerDoTurn and synchronous next-payout staging; mock checks staged state before payout | Record stored Production/Gold/Culture before/after economics; exact beginning sampling remains unavailable |

Additional cases cover foreign land, incomplete improvements, wrong working city, owner mismatch with same city ID, radius >3, nil/duplicate plots, missing/dead owners, multiple Commonwealth players with another locally active player, context recreation, immediate Exchange sale/notified-script-removal cleanup, delayed rebuild Gold, free Exchange ownership and unrelated ScriptData preservation. SQL verifies no Washington/shared ability leakage.

**Civilization V was not launched.** The executable and CP are installed, but Windows control failed before initialization with `failed to write kernel assets: The system cannot find the path specified. (os error 3)`, including after reset. Setup, actual payouts, governor/native save behavior, live ownership/removal delivery, text wrapping and rendering remain **NEEDS NATIVE TEST**. Never mark N passed merely because an event fired. The SQL-backed payout model is still a model. [NativeAcceptance.md](NativeAcceptance.md) supplies the exact repeatable checklist, including the normal +25% Market Gold modifier and CP's zero-maintenance sale restriction.

For native tests use the linked checklist's population-9/eight-Plantation fixture. Record full rates and stored payouts across the owner-end and next activation boundaries, test save/reload and interturn pillage/repair separately, and test notified removal/rebuild without changing Market maintenance. Inspect Database.log and Lua.log. The installed collection predates HCC and must be updated with the audited source before testing.
