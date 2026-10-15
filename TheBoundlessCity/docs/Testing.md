# Validation and native CP v151 test guide

## Automated results — 2026-10-15

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
| Source audit | 176 assertions passed against official v151 commit; hashes/URLs in SourceAudit.json |
| Actual database | Passed in-memory BNW/CP SQL, identity, starting Settler, native Worker/Monument companion inheritance, unchanged native rows, uniques, localization and atlas references |
| Lua syntax | All gameplay/UI/test Lua parse under Lua 5.1 |
| `boundless_assertions.lua` | Passed census/yields, growth/starvation, losses, pillage, water tech/blockade, mountain wonders, release, rewards, save rewind, city transfer and worker order checks |
| `frontier_assertions.lua` | Passed claims beyond 30 hexes and 1,000 plots, water, enemy exclusion, game speed, Registry cap, no unworked yields, plus targeted wrapped-edge water claim |
| `ui_assertions.lua` | Passed panel/launcher, sixteen-row paging, missed/early/nested popup close, native city/mode/leader recovery, turn/load/player/context return, render fault recovery, 1,000 coalesced UI requests without gameplay writes, shared/reentrant dispatch, siege and no idle polling |
| `workforce_stress.lua` | Passed four requested population/territory cases, adversarial governor allocation before delayed Lua, specialist slots, extras, 150% modifiers, unrelated sources, reload, growth/starvation |
| `completion_safety.lua` | Passed independent Manual selection/unlock, Auto lock isolation, partial mutations/cache pulses raising after change, v1 state/ledger migration, capital workforce preservation, return-loop quarantine, legal orphan territory release, movement departure retry, future/corrupt payload preservation |
| `siege_safety.lua` | Passed native-legal demolition, move cost/no reward, territory release, native veto/own-founded/no-raze, capital/holy/city-state protections and replacement identity |
| `stability_assertions.lua` | Passed 48 mode switches/six-source conservation, simulated Golden Age/policy extras, repeated v2/ownership/frontier rewind, original-capital return, optional mirror open/write faults, indexed/full trim faults, negative-terrain reset guard, automaton fast-path invalidation, abrupt 80-to-6 loss, unassigned population, simultaneous dead-owner quarantine reload and deferred Settler cleanup after capital loss |
| `ai_stability.lua` | Passed stale/dead/upgraded/reused identities, invalid saved build IDs, busy target reservation, unreachable cooldown/retry, shared turn budget, fair rotation and budget deferral |
| `engine_completion.lua` | Passed modeled survival/dead-player rules, strict original reclaim/source rebuilding/reload, one-time protected/own-founded subjugation, rival/native-victory guards, derived Tourism removal, assigned-only development/reload/release, extra-city route/border vetoes and deferred AI movement dispatch |
| `dispatcher_contract.lua` | Passed persistent native update contract, nil rejection, explicit detachment, 1,000-event coalescing/idle writes, reentrant scheduling, failure detachment, two-player batching and hostile movement settling |
| Package | Passed 49 game-file manifest/project, hashes/VFS/load order, XML controls and all 34 decoded DDS textures; genuine 7z/LZMA Civ5Mod integrity checked |
| Original collection | Read-only distinct UUID, imported basenames, globals and BC database identifiers; original working-tree status retains only its pre-existing project modification |
| Native gameplay/save/FPS | Player confirmed the pre-crash turn/movement replay succeeds after 1.2.1; automated native UI/gameplay/save/FPS tests **NOT RUN**, 1.2.2 UI retry pending |

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
| 100 | 1.851 | 22.245 / 41.062 | 0.712 | 0.055 | 31.084 |
| 500 | 3.506 | 22.287 / 38.960 | 0.590 | 0.049 | 30.388 |
| 1,000 | 4.830 | 20.987 / 34.876 | 1.437 | 0.051 | 30.792 |
| 2,500 | 9.782 | 20.599 / 39.285 | 1.654 | 0.049 | 29.989 |
| 10,000 | 35.236 | 21.733 / 37.806 | 1.497 | 0.051 | 28.539 |

## Live setup and logging

1. Back up version 1–3 test saves. Install Windows BNW + CP v151. Extract `Cool Wacky Civs 2 (v 4)` into the standard MODS directory after removing the previous version's install folder. Package version changes; Lua state migrates explicitly to schema 3; BCY2 stays unchanged.
2. Enable game logging (`LoggingEnabled = 1`, plus AI logging when needed). Start through Mods with CP + this collection. Begin Standard speed/small map, then Huge/wrapped and Epic/Marathon.
3. Select the First Architect and found the Heart with the initial Settler. Check Database.log/Lua.log for SQL, missing-hook, native-method or ledger errors. Verify art/icons/leader scene/Civilopedia.
4. Build the Registry: Culture 3 plus 1/2/10 territorial bonus at 10/20/100 owned plots. Compare Worker/Surveyor build points under equal modifiers; base ratio 125%, Movement 3. Repairs/replacements/routes must not repeat distant +5 Culture rewards.

## Workforce and source arithmetic

Create independent saves for all four population/owned cases above with precisely counted native jobs and specialist slots. Use FireTuner/editor only in test saves. Record population, worked native plots, default labourers, building specialists, idle/unassigned and remote credits **before Lua callbacks and after**. Verify the full census, unchanged Food consumption and no population growth caused by assignment.

Assign a farm/mine/trading post/fishing tile at distances 12/20/30/across water. Compare six plot base yields, terrain adjustment, negative default compensation and effective city rates. Preserve a known unrelated misc contribution during release/reload. Test city modifiers, labourer-specific policies/traits/religion, Golden Age start/end and Culture-to-Tourism conversion; check native cache refresh and unsupported worked-only effects separately.

Test growth/starvation including an abrupt 80-to-6 loss, specialists, new specialist buildings, center reset/governor reallocation, policies/religion/tech, pillage, occupation/blockade, lost land, war/peace and enemy death/departure. Test positive native automatons separately: credits must be suspended and their count displayed. Pending requests must resume when possible. Cycle Auto → Manual → Hybrid → Auto repeatedly and compare sources; Auto ignores stored locks, Manual unlock keeps selection, Hybrid preserves active locks. Releasing removes sources; unworked land adds no worker yields.

## City identity and conquest

Test trained/purchased/gifted/scripted/captured Settlers, normal founding, buyouts, peace/diplomatic transfers, city-state gifts and mod-created acquisitions. Verify the initial Settler works and extra production/project/process requests are denied. Original-capital loss must suspend all UA activity; a replacement Palace must not reactivate it. Test a legal matching transfer back and the original-only siege reclaim action below. Ordinary attack-click capture still has NoCapture.

For siege, prepare a city originally founded by A but now owned by enemy B, with B's CanRaze true. At 1 HP/adjacent melee/moves/war/visibility, queue demolition. Check no capture-stack mutation, acquired city/territory or repeated reward; moves are consumed and associated plots released. Repeat with first-founded/protected major settlements: demolition is forbidden but one-time Subjugate may be ready. City-states remain unavailable. Test native veto/no-raze, missing visibility/moves, 2 HP and replacement owner/founding/city ID. Check every protection/action/rejection reason and disabled invalid action, hidden undiscovered cities, generic fogged known names, and immediate native city-info refresh after damage. AI must queue only ready rows. Save around queue/execution and load after demolition.

For extras, test historical/native recipients, dead owners, simultaneous transfers and reload immediately afterwards. No arbitrary recipient or resurrection is allowed. Same-turn return loops stop, while later legitimate returns recover again. A living empty Boundless owner may regain only its recorded original capital. Legal orphans are removed; protected/own-founded orphans have empty queues/automation off, resistance maintained through the native decrement, zero ordinary cached rates/purchases, and excluded remote/AI plots. Verify other city centers cannot be released via stale purchase IDs. Observe pre-dispatch yields/UI, empire resources and building/trade effects: absolute one-city enforcement is still not certified.

## Persistence, frontier, AI and coexistence

Load v1 and v2 saves into package v3; progress, direction, priority, selections, identity and rewards must survive. Repeated older snapshots must rewind ownership, population, progress and sources. Test saves around partial reconciliation, growth/loss, pending assignment, expansion, demolition, return/quarantine and capital loss. Try optional mirror failure: native ScriptData must still save. Corrupt/future payloads stay preserved. An unannounced source reset that makes terrain removal unsafe must log recovery, refuse new credits and avoid a native negative source; do not expect arbitrary source corruption to be repairable automatically. Do not downgrade.

Grow past 5/10/20/30 hexes, across water and wrapped edges. Block frontier with enemy tiles; it must not steal them. Test disconnected citadel holdings and direction ties after reload, ordinary policy Culture/Tourism and exact custom progress consumption.

Run AI Boundless for 100+ turns/era transition on mainland/islands. Inspect Surveyor target cleanup on death/upgrade/ID reuse, unreachable retry after three turns, busy reservations, unit rotation and a shared 12-path budget across repeated calls. Confirm budget exhaustion preserves valid targets and native homeland AI is not overwritten. Test Science/Culture/Diplomatic victories; also test the native subjugation Domination path below and another civilization winning under unchanged native rules.

On Huge late-game saves with thousands of plots, measure native turn time, open/closed FPS, event cost, ScriptData/save size and load duration. Log hardware/mod roster and results. Enable the original collection and exercise its civilizations/UI/saves alongside Boundless; static namespace separation does not certify combined gameplay. Archive actual game logs before calling this a stable release.

## Required v4 native regressions A–I — NOT RUN

Use separate backed-up FireTuner test saves with CP v151 and logs enabled. The standard executable/Steam path probe did not locate a controllable game session; no game was launched. Automated simulations do not certify these results.

**A — Original recapture/elimination.** In a new v4 game, found the Heart and leave a melee army alive. Let an enemy take the only city. Record IsAlive, unit count and native original owner/flag/founding coordinates immediately and after the turn. Expect survival with units when max-city-elimination does not apply. Verify frontier/remote credits stop. Reduce the occupied Heart to 1 HP with ranged forces, put an eligible melee adjacent, open the military panel and choose Reclaim. Verify zero→one city, native conquest callback/Palace, no foreign second city, moves consumed, preferences/Culture/reward bits preserved, one fresh ledger and valid capital-connected expansion. Try a replacement, foreign capital, false original flag, second external city, exhausted/defensive/busy/air/embarked force and peace: reclaim must reject. Kill every surviving unit or test max-city-elimination: elimination is allowed, and no reclaim/resurrection is advertised. Repeat in upgraded v1–3 saves both before and after normal technology/policy refresh; record the cached-trait caveat.

**B — Ordinary military resolution.** Attack an enemy's own-founded noncapital at 1 HP. Native CanRaze should reject demolition; Subjugate records one defeat without city/territory/economic reward and consumes melee moves. Retry after transfer/liberation/reload: no repeat subjugation. Attack a previously captured native-razable city: Demolish uses native cleanup, releases its associated plots, preserves unrelated city centers/valid unit handling and grants no second city. Change owner/founding/native city ID/action permission or actor birth between queue and dispatch: cancel the saved action.

**C — Protection.** Repeat against genuine original capitals, holy cities, current/original city-state towns, CP unique-luxury cities, no-raze/OCC rules and an explicit CanRaze veto. Protected major settlements may be acknowledged once; they must never be destroyed. City-state settlements remain unavailable. Test 2 HP, missing melee, no attacks, war/peace, visibility/fog and already queued/subjugated UI labels. Unknown cities stay hidden.

**D — Population 80/500.** Count thirty owned native positions and zero specialist slots, request 80 remotes. Expect 50 safe credits plus thirty pending in this fixture; account for all eighty citizens, center free, native Food consumption unchanged. Governor reallocations before callbacks must not reuse credited citizens. Add/remove slots, locks, defaults and external automatons; test 80→6 starvation and all six effective rates. Full 80-remote allocation remains engine blocked, not an acceptance claim.

**E — Worked effects.** Compare equal native and remote farms/mines/trading posts and a modded ImprovementUpgrade chain. Read plot yields, source ledgers, Tourism, upgrade progress and native worked/GP/per-X counters. With landmark conversion, assigning/releasing remote Culture must refresh Tourism once without extra sources. Progress uses native rate/plot threshold once per owner turn; release/starvation/blockade/capture stops invalid remotes, reload never doubles progress, and local/other-civ/unassigned plots receive no extra step. Native worked counters/GPP/resource discovery can differ; record those limits. Test pillage and policy/religion/Golden Age context separately.

**F — External extras/quarantine.** Force scripted/gift/peace/city-state/special-ability transfers, including simultaneous protected cities whose historical owners are eliminated. Verify deterministic living historical/native recipients or legal removal/quarantine, never an arbitrary custodian. Test same-turn loops and later legal returns. After quarantine, inspect production, six rates, purchases, specialists, remote/Surveyor eligibility, border growth and attempts to create routes to/from the extra. Those new routes/border selections must reject while capital/foreign-only routes remain legal. Measure resources/Happiness/global buildings/existing routes/GPP/city count/prerequisites/bombard/rebase; remaining effects are known gaps, not silently certified inert. Record any economic callback before deferred resolution.

**G — Native Domination.** In a three-plus-major game with Domination enabled, subjugate genuine rival originals once through wartime siege. Check original civ/founding identity through enemy transfers/liberation and save/reload. Every ever-alive other-team major counts, including eliminated rivals; missing/replaced originals must block. Hold only the Heart and finish the last required original: inspect normal winner/victory, popup, notification/replay and saved result. Repeat with disabled Domination, Config.SubjugationDomination=false, a prior Science/Culture/Diplomatic winner, missing own capital and a quarantined extra: no forced result/overwrite. Test allied teammates excluded, two Boundless players and another civilization's native Domination unchanged.

**H — Saves/faults.** Save before/after every queue, subjugation, reclaim, upgrade and quarantine. Load twice and rewind older saves; no repeat awards/progress/duplicate sources. Upgrade known v1/v2/v3 state to schema 3 without resetting original/Culture/preferences/rewards; malformed/future state stays preserved/disabled. Test new-game versus old native survival cache separately. Native capture creates a fresh city object; mocks only model that boundary. Inspect logs for ledger, stale-object or missing-method errors.

**I — Huge maps and AI.** Use 1,000+ owned plots, population 150+, 22 majors/many units/several wars and multiple known siege targets. Measure native owner turns, military panel/closed UI FPS, improvement development, victory checks, path completion, save size and load time. Confirm no permanent update handler/world scan on ordinary movement. Watch AI siege actions after native city damage and adjacent movement; verify it spends moves, avoids protected destruction/rewards and retains existing Surveyor path budget/personality. Run 100+ turns and coexistence with the original collection. Capture logs/hardware/roster and actual results before calling the release stable.

### New mechanism simulation timings

These are host Lupa medians, not native engine timings. Development fixtures have assigned jobs but no upgrade chain; native upgrade cost must be measured in E/I. Military fixtures contain 42 revealed enemy cities and 21 rival original identities. Existing maxima, initialization and other measures remain in Benchmark.json.

| Initial owned | One development pass ms | 42-city military rows ms | 100 domination progress checks ms |
| --- | --- | --- | --- |
| 100 | 0.461 | 0.137 | 1.385 |
| 500 | 0.595 | 0.134 | 1.469 |
| 1,000 | 1.302 | 0.131 | 1.387 |
| 2,500 | 1.228 | 0.255 | 1.443 |
| 10,000 | 0.637 | 0.131 | 1.355 |

## Turn/movement hotfix replay

The 1.2.1 preview keeps native mod version 4/schema 3. The player reported that the pre-crash replay completed successfully. The later log contains no Boundless update-call flood. Full native regression coverage remains outstanding; the original collection's separate failures remain in that log. See [CrashHotfixReport.md](CrashHotfixReport.md).

### Workforce UI hotfix replay

The 1.2.2 preview keeps the same native version/schema. Fully restart Civ V and reload the existing modded campaign. Confirm the upper-right Workforce launcher opens; check the saved mode, locks and remote assignments. Enter/exit CityView, production, Social Policies, Declare War and leader root/discussion/trade, then reopen the panel. The launcher should stay hidden over those screens and return on the map. End a turn, reload and repeat. Check `Lua.log` for visibility reasons and any refresh errors. Native rendering/event timing and other mods' custom popup contexts require this live retry. See [UIVisibilityHotfix.md](UIVisibilityHotfix.md).
