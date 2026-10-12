# The Boundless City — final mechanics and stability pass

**Reviewed baseline:** `fee9bed9b9d5517bec4ebb394c4543e15c4e7267` · **Date:** 2026-10-12 · **Release:** 1.1.1 preview / mod version 3 · **Target:** BNW + CP v151

This pass keeps the verified citizen model, frontier, art, uniques, balance, personality and save architecture. Changes address observed failure/lifecycle/UI gaps rather than replacing those systems. All work is confined to CoolWackyCivs2; the original collection is only read for coexistence comparison.

## Bugs, causes and implemented corrections

| Bug | Cause | Fix |
| --- | --- | --- |
| No explanation for rejected siege targets | The panel listed only ready settlements; failed checks returned one undifferentiated false | Revealed targets show protection, damage, melee, war, visibility, native-interface/rule or queued reasons. Invalid buttons are disabled, unknown cities hidden and fogged current details withheld. Native city-info events refresh siege rows. |
| Queued demolition could follow a same-turn replacement | Owner/founding coordinates could match another object | New records include native city ID and execution checks it. Legacy records retain their existing owner/founding checks. |
| Territory release could affect another city center | Release trusted a stale purchase/owning-city ID | Remaining city centers are skipped after both siege and orphan disband. |
| Protected quarantine remained an economic/purchase center | Production vetoes/empty queues did not suppress ordinary city rates | Maintain native resistance at two turns, ensuring one survives the next pre-production decrement; refresh six cached rates. Associated plots are indexed out of remote work and custom Surveyor targets, including at load. Empire/transient effects remain a gap. |
| Settlers survived after capital loss | Turn cleanup ran after the valid-capital early return | Cleanup runs before that gate and through deferred creation/conversion dispatch. IDs/type/creation turn are re-resolved; no deletion inside a native unit callback. Initial Settler is preserved. |
| Legitimate later transfers treated as permanent return loops | Recipient/founding records had no turn scope | Same-turn repeats are suppressed; later legal returns can proceed. Legacy unstamped records get one new guarded attempt. No arbitrary custodian/resurrection is introduced. |
| Another Boundless owner could never recover its lost original | All Boundless recipients were rejected | A living recipient with zero cities may receive only its recorded original capital, matching coordinates, founding turn, original owner and native capital flag. It cannot receive a replacement or second city. |
| Trim faults left inconsistent assignment/cache/source state until dispatch | Indexed/full trim changed records before mutation but had weaker failure cleanup than full reconcile | All paths share immediate known-ledger cleanup, clear assignment/scalar/source caches, preserve withdrawal cleanup and set RECOVER. Additional capacity is unavailable until recovery and UI gives a diagnostic. |
| External source erasure could reach native negative-terrain assertion | Saved journal amount was assumed physically present | Reject negative terrain totals before the native setter. An inconsistent journal/source cannot be safely guessed away; retain diagnostics and refuse new credits until verified recovery. |
| Fast movement trim missed some automatons | Fast census checked only population, specialists and defaults | Include native automatons; show them separately in the panel and retain conservative zero remote credits while positive. |
| Optional mirror could abort successful native saves | OpenSaveData open/write errors propagated through reconciliation | Both are protected/nonfatal. Player ScriptData remains authoritative and is saved before mirror work. |
| Dead/upgraded/reused AI targets and invalid build IDs | Saved target records were not fully pruned against current units/builds | Check live Surveyor ID/creation identity, inherited build membership, ownership and native CanBuild before using a target. |
| Duplicate busy targets / repeated unreachable paths / starvation of later workers | Only newly assigned idle targets were claimed; no failure delay; low IDs consumed every pass budget | Reserve busy/no-move targets, three-turn per-unit/plot cooldown, fair unit rotation, and a shared 12-path budget per owner turn. Budget deferral retains a valid target; local legal builds need no path. Busy missions remain untouched. |

## Remote workforce: retained verified limit

Every credited plot uses one protected real default labourer. The free center is excluded:

```text
local workers + remote workers + building specialists + idle defaults + unassigned
    = ordinary population + separately reported native automatons
```

Positive external automatons suspend remote credits because ordinary-human attribution is uncertain. No population/negative-automaton/unassigned-default workaround is used. Labourer six-yield compensation remains database base plus native total type extras divided by real default count. Terrain credits, misc compensation and cached-rate pulses are journalled; modifiers are applied natively once.

CP v151 still exposes no arbitrary forced-default setter or functional citizen-automation disable task. Unforced defaults can be reassigned by the governor. With M owned native local positions and Q static slots in present specialist buildings, the conservative surplus is `max(0, P-M-Q)`. The pool is capped by actual real defaults and uses `max(surplus, verified forced withdrawals)`, never their sum. Working radius and specialists therefore still influence the safe bound; this pass intentionally does not pretend all P citizens can be reserved remotely.

| Population / owned | Verified fixture remotes | Explanation |
| --- | --- | --- |
| 10 / 30 | 10 | Forced withdrawal of ten real local workers |
| 40 / 150 | 30 | Forced withdrawals; unforced surplus alone is 10 |
| 80 / 500 | 50 | Surplus above thirty native local jobs |
| 150 / 1,000 | 120 | Same conservative surplus bound |

These fixtures use 30 native positions and no specialist slots. Actual game counts may differ. The supplied final task's population-40 value 10 describes the unforced lower bound; the reviewed Manual test already reserved 30. Distance remains unlimited by the mod, with no per-tile/passive workaround. The native governor remains in charge of other local/specialist allocation, so Auto is still a constrained optimizer.

## Demolition and strict ownership

The source audit distinguishes interface ownership/founding restrictions from capital/holy/luxury/mod protections. Native CanRaze returns early for wrong ownership and the owner's own-founded city, before every later native/mod protection veto can be evaluated. Disband itself does not certify legality. Recreating only visible rules in Lua would not preserve all native vetoes; no verified independent permission API or universal pre-acquisition veto was found.

Accordingly, **general demolition of first-founded enemy towns remains unsupported**. Restricted siege is retained: visible city at 1 HP, war, adjacent non-embarked melee with movement, hard capital/holy/current-or-original-city-state exclusions, and current-owner native CanRaze. It executes outside combat/capture stacks, revalidates identity/permission, consumes moves, uses native current-owner Disband and releases associated plots. No city, territory or capture reward goes to Boundless. Protected cities survive; normal NoCapture remains active, including military original-capital recapture.

Unexpected transfers return only to justified living historical/native recipients. Eliminated owners are not resurrected. Native-legal orphans can be removed; protected/own-founded extras remain quarantined with the new resistance/plot/production guards. **Absolute immediate one-city enforcement remains unmet**: ownership can be transient, and empire resources, building effects, trade infrastructure, native city counts/UI and pre-dispatch economic effects are not fully eliminated. Matching legal original-capital return can restore the UA; no substitute capital does.

## Save compatibility

- Same UUID `f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392`; package version 3 and minimum compatible mod save version 1.
- Native BCSTATE1 envelope/table schema 2 and BCY2 ledger remain unchanged. Version 1 migration/BCY1 replacement are retained and tested.
- Optional return-turn and siege-city-ID fields extend records compatibly. Older known-version records retain documented guarded behavior; no Culture, territory, capital identity or reward reset is introduced.
- Optional AI cooldown/budget/cursor state is ephemeral. Saved targets are revalidated after load; transient routing failures are not permanent saved exclusions.
- Native Player/Plot ScriptData, not the mirror, governs older-save rewind. Corrupt/future state remains preserved/disabled. Externally erased/corrupted source journals may be unrepairable without a native reset; no new credits are issued during that failure.
- Native version 1/2 upgrades and save UI ordering are not yet tested. Back up saves, replace the older install folder and do not downgrade.

## Verification and measurements

**Source-verified:** official CP commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`, DLL version 151. All relevant bindings plus task/resistance/capture/raze behavior were inspected. [SourceAudit.json](SourceAudit.json) records **129 passed assertions**, URLs and hashes. This establishes available methods/signatures/observed C++ behavior, not live compatibility.

**SQL/Lua/package validation:** actual read-only BNW/CP schema cloned in memory; native rows/inheritance/uniques/localization unchanged except intended text. Every Lua source parses as Lua 5.1. Forty-eight game files, one addin, numeric SQL/include ordering, VFS/hashes, all 34 DDS textures, UUID/dependencies/save/project metadata and ZIP/7z packaging are checked. Read-only coexistence checks compare the original collection's UUID, imported filenames, globals and database identifiers.

**Mock simulations:** eight suites pass. They cover the requested 80/500 and 150/1,000 cases, adversarial governor/specialists, 48 mode switches with all six sources conserved, simulated Golden Age/policy changes, ten repeated v2 restores, ownership/frontier rewind, mirror open/write faults, partial native mutations in both trim paths, unsafe source-reset refusal, automatons, abrupt 80-to-6 population loss, genuine unassigned citizens, deferred Settlers after capital loss, original-capital return, simultaneous eliminated-owner quarantine/reload, siege reasons/protected/replacement/reload cases, AI lifecycle/route/budget/fairness and no idle polling. Injected exceptions are deliberate tests.

**Measured simulation timing:** [Benchmark.json](Benchmark.json) profiles 100/500/1,000/2,500/10,000 owned plots on 16,000-plot wrapped maps, population 150, with 22 major-player records, 40 minor-player slots and 200 moving military units. It includes coalesced hostile entry/departure, frontier claims, full reconciliation/assignment changes, AI cache/reentry and cached open/closed UI. Native calls and actor behavior are synthetic; neither native pathfinding nor FPS are measured. Exact medians/maxima are committed, with a readable table in [Testing.md](Testing.md).

**Untested native behavior:** Civ V was not launched; no controllable native game session is available in this tool environment. Governor/event order, effective six rates/Tourism, policy/religion/Golden Age plot recalculation, resistance economic/purchase suppression and recipient reset, transfer/city UI, demolition cleanup, save migration, actual AI path completion and Huge-map FPS still need the live checklist. Passing mocks is not proof of a stable hundreds-turn campaign.

## Exact file changes

Runtime/UI/text:

- `TheBoundlessCity/Lua/BoundlessCitizens.lua`
- `TheBoundlessCity/Lua/BoundlessCore.lua`
- `TheBoundlessCity/Lua/BoundlessEvents.lua`
- `TheBoundlessCity/Lua/BoundlessPersistence.lua`
- `TheBoundlessCity/Lua/BoundlessSiege.lua`
- `TheBoundlessCity/Lua/BoundlessAI.lua`
- `TheBoundlessCity/UI/BoundlessWorkforce.lua`
- `TheBoundlessCity/SQL/10_BC_Text.sql`

Integration/tools/tests:

- `Cool Wacky Civs 2 (v 3).modinfo` replaces the v2 manifest; `CoolWackyCivs2.civ5proj`
- `tools/build_mod.py`, `tools/generate_database.py`, `tools/validate_mod.py`
- `tools/audit_cp.py`, `tools/benchmark.py`
- `tools/tests/boundless_mock.lua`, `completion_safety.lua`, `siege_safety.lua`, `ui_assertions.lua`
- New `tools/tests/stability_assertions.lua`, `tools/tests/ai_stability.lua`

Documentation/records:

- `README.md`, `CHANGELOG.md`
- `TheBoundlessCity/README.md`, `TheBoundlessCity/CHANGELOG.md`
- `docs/civilizations/TheBoundlessCity.md`
- `TheBoundlessCity/docs/APIAudit.md`, `Implementation.md`, `EngineLimitations.md`, `Testing.md`
- `TheBoundlessCity/docs/SourceAudit.json`, `Benchmark.json`, archival `FixesReport.md` pointer
- New `TheBoundlessCity/docs/FinalStabilityReport.md`, `FinalStabilityRequest.md`

Original art, UI XML layout, civilization/leader/unique/effect/inheritance/art SQL and balance constants remain unchanged. Local v3 ZIP/Civ5Mod products are ignored by Git. The original collection has only its pre-existing project modification.

## Required live checks

Follow [Testing.md](Testing.md): install v3 with CP v151, enable logs, check art/uniques, measure census/rates at all four populations, test mode churn/specialists/starvation/Governor/Golden Age, known/fogged/protected/ordinary siege targets and queue replacement, same/later-turn transfers and dead owners, quarantine resistance/purchases/associated plots, native v1/v2 upgrade/older rewinds, AI path/cooldown/busy behavior over 100+ turns, and Huge-map turn time/open-closed FPS/save size. Repeat with the original collection enabled. Record actual native logs/results before promoting the preview to stable.
