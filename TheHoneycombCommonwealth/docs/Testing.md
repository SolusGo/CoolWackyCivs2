# Validation and native acceptance

Run with the existing repository environment:

```powershell
.\.venv\Scripts\python.exe tools/validate_honeycomb.py
.\.venv\Scripts\python.exe tools/validate_mod.py
```

**Executed 2026-10-30:** both commands completed with exit code **0**. All focused HCC SQL/Lua/source/art/manifest checks passed, as did the full collection regression suite. `git diff --check`, Python syntax, new documentation links, released manifest record order and unchanged dependency checks also passed. [Validation.json](Validation.json) retains the result summary. Regenerated timing reports for other civilizations were excluded from this change.

The focused validator executes shipped SQL against the installed BNW backup reconstructed with CP v151 schema, after the entire released collection; compares all existing rows; checks Scout/Market rows and companion inheritance; and repeats with altered baselines. It parses Lua 5.1 and drives actual HCC callbacks with mocks. It verifies XML, 43 pinned native source contracts, all DDS/mipmaps/atlas references, manifest hashes, VFS and load order. The collection validator covers existing civ regressions, all Lua, icon framing, project/modinfo inventory and namespaces. No release packaging is needed.

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

**Civilization V was not launched for this change.** Setup selection, actual economic payout, governor behavior, native serialization, live captures/sales, Dawn wrapping and texture rendering still require observation. Never mark N passed solely because an event fired. Interturn timing differs as explicitly described in [Implementation.md](Implementation.md), using the permitted fallback.

For native tests, enable only BNW, CP v151 and this collection. Start a new Mellia game with a test map/save containing six Plantations and sufficient population. Manually assign each threshold, advance owner end and the next payout, and compare stored yields. Test assignment/pillage during the owner turn and interturn separately. Save after reassigning but before ending: load must retain existing dummies, then the end boundary updates once. Sell/rebuild Exchange in that window: Food follows actual possession; Gold waits for the next snapshot. Repeat transfers and foreign-civ comparisons; inspect Database.log and Lua.log.
