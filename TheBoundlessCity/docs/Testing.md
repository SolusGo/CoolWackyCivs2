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
| Source audit | 129 assertions passed against official v151 commit; hashes/URLs in SourceAudit.json |
| Actual database | Passed in-memory BNW/CP SQL, identity, starting Settler, native Worker/Monument companion inheritance, unchanged native rows, uniques, localization and atlas references |
| Lua syntax | All gameplay/UI/test Lua parse under Lua 5.1 |
| `boundless_assertions.lua` | Passed census/yields, growth/starvation, losses, pillage, water tech/blockade, mountain wonders, release, rewards, save rewind, city transfer and worker order checks |
| `frontier_assertions.lua` | Passed claims beyond 30 hexes and 1,000 plots, water, enemy exclusion, game speed, Registry cap, no unworked yields, plus targeted wrapped-edge water claim |
| `ui_assertions.lua` | Passed panel/launcher, sixteen-row paging, city/diplomacy/popup hiding, Escape and no permanent update |
| `workforce_stress.lua` | Passed four requested population/territory cases, adversarial governor allocation before delayed Lua, specialist slots, extras, 150% modifiers, unrelated sources, reload, growth/starvation |
| `completion_safety.lua` | Passed independent Manual selection/unlock, Auto lock isolation, partial mutations/cache pulses raising after change, v1 state/ledger migration, capital workforce preservation, return-loop quarantine, legal orphan territory release, movement departure retry, future/corrupt payload preservation |
| `siege_safety.lua` | Passed native-legal demolition, move cost/no reward, territory release, native veto/own-founded/no-raze, capital/holy/city-state protections and replacement identity |
| `stability_assertions.lua` | Passed 48 mode switches/six-source conservation, simulated Golden Age/policy extras, repeated v2/ownership/frontier rewind, original-capital return, optional mirror open/write faults, indexed/full trim faults, negative-terrain reset guard, automaton fast-path invalidation, abrupt 80-to-6 loss, unassigned population, simultaneous dead-owner quarantine reload and deferred Settler cleanup after capital loss |
| `ai_stability.lua` | Passed stale/dead/upgraded/reused identities, invalid saved build IDs, busy target reservation, unreachable cooldown/retry, shared turn budget, fair rotation and budget deferral |
| Package | Passed 48 game-file manifest/project, hashes/VFS/load order, XML controls and all 34 decoded DDS textures; genuine 7z/LZMA Civ5Mod integrity checked |
| Original collection | Read-only distinct UUID, imported basenames, globals and BC database identifiers; original working-tree status retains only its pre-existing project modification |
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

The supplied final-pass table lists 10 remotes for population 40. The reviewed commit's Manual fixture actually reserves 30 through forced withdrawals; 10 is the conservative unforced surplus. The tests retain the correct conditional distinction. Actual local job/slot counts must be measured in-game rather than inferred from these fixtures.

## Measured performance

[Benchmark.json](Benchmark.json) records actual Python/Lupa Lua 5.1 wall-clock samples for 16,000-plot wrapped maps and initial ownership of 100, 500, 1,000, 2,500 and 10,000 plots, population 150. Each scenario has 22 major-player records, 40 minor-player slots and 200 foreign military units. It measures full reconciliation, assignment changes, 1,000 unrelated/near-territory moves, coalesced hostile entry/departure batches, individual frontier claims, cached/uncached AI planning and same-turn reentry, row rebuild and open/closed UI refresh. Counts grow by nine frontier claims, so ownership is the initial count. These are synthetic actor records, not 22 fully simulated native civilizations.

Native calls are synthetic; unchanged near movement does not change eligibility, while the hostile batch explicitly toggles enemy flags. Native pathfinding/FPS are not measured. AI checks a shared 12-path turn budget and zero additional paths on exhausted same-turn reentry. Unchanged movement asserts no pending dispatcher. Benchmarks are host/run dependent, not native frame budgets.

| Initial owned | Full reconcile median ms | 1,000 far / near moves ms | One claim ms | Cached AI pass ms | 100 cached open UI refreshes ms |
| --- | --- | --- | --- | --- | --- |
| 100 | 2.125 | 36.924 / 73.988 | 1.356 | 0.072 | 46.190 |
| 500 | 4.464 | 35.600 / 69.625 | 0.977 | 0.059 | 77.000 |
| 1,000 | 12.350 | 62.287 / 135.552 | 3.843 | 0.124 | 72.681 |
| 2,500 | 28.825 | 61.431 / 125.659 | 4.447 | 0.138 | 64.939 |
| 10,000 | 97.234 | 63.788 / 87.543 | 4.066 | 0.129 | 61.485 |

## Live setup and logging

1. Back up version 1/2 test saves. Install Windows BNW + CP v151. Extract `Cool Wacky Civs 2 (v 3)` into the standard MODS directory after removing the previous version's install folder. Package version changes; native save schema stays 2.
2. Enable game logging (`LoggingEnabled = 1`, plus AI logging when needed). Start through Mods with CP + this collection. Begin Standard speed/small map, then Huge/wrapped and Epic/Marathon.
3. Select the First Architect and found the Heart with the initial Settler. Check Database.log/Lua.log for SQL, missing-hook, native-method or ledger errors. Verify art/icons/leader scene/Civilopedia.
4. Build the Registry: Culture 3 plus 1/2/10 territorial bonus at 10/20/100 owned plots. Compare Worker/Surveyor build points under equal modifiers; base ratio 125%, Movement 3. Repairs/replacements/routes must not repeat distant +5 Culture rewards.

## Workforce and source arithmetic

Create independent saves for all four population/owned cases above with precisely counted native jobs and specialist slots. Use FireTuner/editor only in test saves. Record population, worked native plots, default labourers, building specialists, idle/unassigned and remote credits **before Lua callbacks and after**. Verify the full census, unchanged Food consumption and no population growth caused by assignment.

Assign a farm/mine/trading post/fishing tile at distances 12/20/30/across water. Compare six plot base yields, terrain adjustment, negative default compensation and effective city rates. Preserve a known unrelated misc contribution during release/reload. Test city modifiers, labourer-specific policies/traits/religion, Golden Age start/end and Culture-to-Tourism conversion; check native cache refresh and unsupported worked-only effects separately.

Test growth/starvation including an abrupt 80-to-6 loss, specialists, new specialist buildings, center reset/governor reallocation, policies/religion/tech, pillage, occupation/blockade, lost land, war/peace and enemy death/departure. Test positive native automatons separately: credits must be suspended and their count displayed. Pending requests must resume when possible. Cycle Auto → Manual → Hybrid → Auto repeatedly and compare sources; Auto ignores stored locks, Manual unlock keeps selection, Hybrid preserves active locks. Releasing removes sources; unworked land adds no worker yields.

## City identity and conquest

Test trained/purchased/gifted/scripted/captured Settlers, normal founding, buyouts, peace/diplomatic transfers, city-state gifts and mod-created acquisitions. Verify the initial Settler works and extra production/project/process requests are denied. Original-capital loss must suspend all UA activity; a replacement Palace must not reactivate it. Test a legal matching transfer back; military recapture remains NoCapture-blocked.

For siege, prepare a city originally founded by A but now owned by enemy B, with B's CanRaze true. At 1 HP/adjacent melee/moves/war/visibility, queue demolition. Check no capture-stack mutation, acquired city/territory or repeated reward; moves are consumed and associated plots released. Repeat with first-founded enemy towns, capitals, holy/city-state cities, native veto/no-raze, missing visibility/moves, 2 HP and replacement owner/founding/city ID. Check every rejection reason and disabled action, hidden undiscovered cities, generic fogged known names, and immediate native city-info refresh after damage. AI must queue only ready rows. Save around queue/execution and load after demolition.

For extras, test historical/native recipients, dead owners, simultaneous transfers and reload immediately afterwards. No arbitrary recipient or resurrection is allowed. Same-turn return loops stop, while later legitimate returns recover again. A living empty Boundless owner may regain only its recorded original capital. Legal orphans are removed; protected/own-founded orphans have empty queues/automation off, resistance maintained through the native decrement, zero ordinary cached rates/purchases, and excluded remote/AI plots. Verify other city centers cannot be released via stale purchase IDs. Observe pre-dispatch yields/UI, empire resources and building/trade effects: absolute one-city enforcement is still not certified.

## Persistence, frontier, AI and coexistence

Load v1 and v2 saves into package v3; progress, direction, priority, selections, identity and rewards must survive. Repeated older snapshots must rewind ownership, population, progress and sources. Test saves around partial reconciliation, growth/loss, pending assignment, expansion, demolition, return/quarantine and capital loss. Try optional mirror failure: native ScriptData must still save. Corrupt/future payloads stay preserved. An unannounced source reset that makes terrain removal unsafe must log recovery, refuse new credits and avoid a native negative source; do not expect arbitrary source corruption to be repairable automatically. Do not downgrade.

Grow past 5/10/20/30 hexes, across water and wrapped edges. Block frontier with enemy tiles; it must not steal them. Test disconnected citadel holdings and direction ties after reload, ordinary policy Culture/Tourism and exact custom progress consumption.

Run AI Boundless for 100+ turns/era transition on mainland/islands. Inspect Surveyor target cleanup on death/upgrade/ID reuse, unreachable retry after three turns, busy reservations, unit rotation and a shared 12-path budget across repeated calls. Confirm budget exhaustion preserves valid targets and native homeland AI is not overwritten. Test Science/Culture/Diplomatic victories; standard Domination has no custom exception.

On Huge late-game saves with thousands of plots, measure native turn time, open/closed FPS, event cost, ScriptData/save size and load duration. Log hardware/mod roster and results. Enable the original collection and exercise its civilizations/UI/saves alongside Boundless; static namespace separation does not certify combined gameplay. Archive actual game logs before calling this a stable release.
