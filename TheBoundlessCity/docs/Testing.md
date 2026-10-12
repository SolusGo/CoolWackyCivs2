# Validation and native CP v151 test guide

## Automated results — 2026-10-12

Run from the repository root with Python 3.11 and `requirements-dev.txt` dependencies:

```powershell
python tools/audit_cp.py --fetch
python tools/build_mod.py --manifest-only
python tools/validate_mod.py
python tools/benchmark.py
python tools/build_mod.py
```

The source fetch is optional for building/playing. SQL tests use a read-only backup BNW debug database at `~/Documents/My Games/Sid Meier's Civilization 5/cache_backup/Civ5DebugDatabase.db` plus installed `MODS/(1) Community Patch` schema. `tools/database.py` clones into memory; game caches/saves are never written. Developers with another layout can pass paths to that adapter. The committed SQL builds without regeneration.

| Check | Result / scope |
| --- | --- |
| Source audit | 121 assertions passed against official v151 commit; hashes/URLs in SourceAudit.json |
| Actual database | Passed in-memory BNW/CP SQL, identity, starting Settler, native Worker/Monument companion inheritance, unchanged native rows, uniques, localization and atlas references |
| Lua syntax | All gameplay/UI/test Lua parse under Lua 5.1 |
| `boundless_assertions.lua` | Passed census/yields, growth/starvation, losses, pillage, water tech/blockade, mountain wonders, release, rewards, save rewind, city transfer and worker order checks |
| `frontier_assertions.lua` | Passed claims beyond 30 hexes and 1,000 plots, water, enemy exclusion, game speed, Registry cap, no unworked yields, plus targeted wrapped-edge water claim |
| `ui_assertions.lua` | Passed panel/launcher, sixteen-row paging, city/diplomacy/popup hiding, Escape and no permanent update |
| `workforce_stress.lua` | Passed four requested population/territory cases, adversarial governor allocation before delayed Lua, specialist slots, extras, 150% modifiers, unrelated sources, reload, growth/starvation |
| `completion_safety.lua` | Passed independent Manual selection/unlock, Auto lock isolation, partial mutations/cache pulses raising after change, v1 state/ledger migration, capital workforce preservation, return-loop quarantine, legal orphan territory release, movement departure retry, future/corrupt payload preservation |
| `siege_safety.lua` | Passed native-legal demolition, move cost/no reward, territory release, native veto/own-founded/no-raze, capital/holy/city-state protections and replacement identity |
| Package | Passed 48 game-file manifest/project, hashes/VFS/load order, XML controls and all 34 decoded DDS textures; genuine 7z/LZMA Civ5Mod integrity checked |
| Original collection | Read-only distinct UUID, imported basenames and BC database identifiers; original working-tree status retains only its pre-existing project modification |
| Native gameplay/save/FPS | **NOT RUN** |

The tool environment has no controllable native Civ V gameplay session. The game was not launched for these tests. Mocks approximate native accounting and cannot prove DLL governor, capture, pathfinding, UI layout or save behavior. Injected exceptions are expected safety tests, not unexplained runtime failures.

With 30 native local positions, no specialist slots and sufficient legal remote inventory:

| Population | Owned plots | Requested remotes | Verified fixture credits | Pending |
| --- | --- | --- | --- | --- |
| 10 | 30 | 10 | 10 | 0 |
| 40 | 150 | 40 | 30 | 10 |
| 80 | 500 | 80 | 50 | 30 |
| 150 | 1,000 | 150 | 120 | 30 |

The 10-population case owns ten native local jobs within the 30-position list. The higher cases own all thirty. These figures demonstrate a surplus beyond the old 30-worker ceiling; they do **not** demonstrate full population-only allocation.

## Measured performance

[Benchmark.json](Benchmark.json) records actual Python/Lupa Lua 5.1 wall-clock samples for 16,000-plot wrapped maps and initial ownership of 100, 500, 1,000, 2,500 and 10,000 plots, population 150. It measures full reconciliation, priority/assignment changes, 1,000 unrelated/near-territory moves, individual frontier claims, cached/uncached AI planning, row rebuild and open/closed UI refresh batches. Counts grow by nine frontier claims during each scenario, so the ownership field is the initial count.

Native calls are synthetic. Native pathfinding/FPS are not measured. Shared AI passes assert at most 12 path calls, and unchanged movement asserts no pending dispatcher. Benchmarks are host/run dependent and should be compared using the committed measurements, not assumed game frame budgets.

## Live setup and logging

1. Back up test saves. Install Windows BNW + CP v151. Extract `Cool Wacky Civs 2 (v 2)` into the standard MODS directory after removing the previous version's install folder.
2. Enable game logging (`LoggingEnabled = 1`, plus AI logging when needed). Start through Mods with CP + this collection. Begin Standard speed/small map, then Huge/wrapped and Epic/Marathon.
3. Select the First Architect and found the Heart with the initial Settler. Check Database.log/Lua.log for SQL, missing-hook, native-method or ledger errors. Verify art/icons/leader scene/Civilopedia.
4. Build the Registry: Culture 3 plus 1/2/10 territorial bonus at 10/20/100 owned plots. Compare Worker/Surveyor build points under equal modifiers; base ratio 125%, Movement 3. Repairs/replacements/routes must not repeat distant +5 Culture rewards.

## Workforce and source arithmetic

Create independent saves for all four population/owned cases above with precisely counted native jobs and specialist slots. Use FireTuner/editor only in test saves. Record population, worked native plots, default labourers, building specialists, idle/unassigned and remote credits **before Lua callbacks and after**. Verify the full census, unchanged Food consumption and no population growth caused by assignment.

Assign a farm/mine/trading post/fishing tile at distances 12/20/30/across water. Compare six plot base yields, terrain adjustment, negative default compensation and effective city rates. Preserve a known unrelated misc contribution during release/reload. Test city modifiers, labourer-specific policies/traits/religion, Golden Age start/end and Culture-to-Tourism conversion; check native cache refresh and unsupported worked-only effects separately.

Test growth/starvation, specialists, new specialist buildings, city-center reset, city governor reallocation, policies/religion/tech, improvement changes/pillage, occupation/blockade, lost land, war/peace and enemy death/departure. Pending requests must resume when possible. Auto must ignore stored locks; Manual unlock must keep selection; Hybrid must preserve active locks/native local obligations. Releasing must remove sources; owning unworked land must add no worker yields.

## City identity and conquest

Test trained/purchased/gifted/scripted/captured Settlers, normal founding, buyouts, peace/diplomatic transfers, city-state gifts and mod-created acquisitions. Verify the initial Settler works and extra production/project/process requests are denied. Original-capital loss must suspend all UA activity; a replacement Palace must not reactivate it. Test a legal matching transfer back; military recapture remains NoCapture-blocked.

For siege, prepare a city originally founded by player A but now owned by enemy B, with B's native CanRaze true. At 1 HP/adjacent melee/moves/war/visibility, queue demolition. Check no mutation during capture/combat stack, no acquired city/territory, moves consumed, associated tiles released and no repeated reward. Repeat with a first-founded enemy town, capital, holy city, current/original city-state, rule veto/no-raze option, missing visibility/moves, 2 HP and replacement ownership/founding identity. All invalid cases must survive unchanged. Save around queued execution.

For unexpected extras, test previous owner, original owner, dead owners, native liberation recipient and no recipient. Confirm no arbitrary civilization receives the city; repeat transfer must not loop. Legal orphans should be removed; protected/own-founded orphans should be quarantined with empty queues/automation off. Observe native yields and city-selection UI during the transient ownership period: the absolute one-city invariant is not certified in this case.

## Persistence, frontier, AI and coexistence

Load a v1 save and confirm progress, direction, priority, selection/locks, original identity and reward bits survive migration with no duplicate sources. Save/reload v2 twice, then load an older snapshot: custom state must rewind with native state. Test saves around partial reconciliation, growth, yield changes, extra-city return and capital loss. Preserve future/corrupt ScriptData and inspect disabled behavior; do not downgrade migrated saves.

Grow past 5/10/20/30 hexes, across water and wrapped edges. Block frontier with enemy tiles; it must not steal them. Test disconnected citadel holdings and direction ties after reload, ordinary policy Culture/Tourism and exact custom progress consumption.

Run AI Boundless for 100+ turns/era transition on mainland and island maps. Inspect food, remote accounting, Surveyor targets, unreachable paths, budget rotation, busy mission preservation and native homeland-AI interference. Test native Science/Culture/Diplomatic victories; standard Domination has no custom exception.

On Huge late-game saves with thousands of plots, measure native turn time, open/closed FPS, event cost, ScriptData/save size and load duration. Log hardware/mod roster and results. Enable the original collection and exercise its civilizations/UI/saves alongside Boundless; static namespace separation does not certify combined gameplay. Archive actual game logs before calling this a stable release.
