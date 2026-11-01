# Lantern Fleet corrective audit

**Overall verdict: STATICALLY VALIDATED, NATIVE ACCEPTANCE PENDING.** Original design, numerical values, SQL identities, models and original artwork are preserved. Native economic timing remains the critical unresolved acceptance item.

## Scope and preserved newer work

Baseline: `512bc608d2d5f5e245f037fc8399b586ea2e3c9e`. The checkout and fetched origin/main are at `2342ac0`, including the later all-human roster and complete Civilopedia/strategy-guide commits. The working tree also already contained a new Triumphal Imperium, collection version 23 metadata and shared-tool improvements. This audit preserves them, including the already-fixed T1/First Drafts description separator and the already-improved contiguous Lantern SQL-order check. It adds no collection version, dependency, DLL change, new gameplay ability or interface.

## Findings and fixes

| Finding / root cause | Correction | Evidence |
| --- | --- | --- |
| Active-player bootstrap stamped a completed receipt before the first legitimate fresh/scenario notification. | Use the native loaded-game and declared start-turn predicates; do not pre-complete a fresh initial turn. Loaded/progressed ambiguous active state gets a settled-phase marker, not a false completion. | First human/AI/advanced-scenario, early context, loaded initial turn, context recreation and legacy receipts pass in simulation. Native lifecycle ordering remains pending. |
| Completion was written before any real-building setter. A partial write was then permanently skipped. | Reserve the boundary, freeze all city targets, durably acknowledge that plan, apply/verify counts, then commit LANTERN1. | Partial city/dummy, setter failures before/after mutation, completion/persistence failures and full VM restart tests. |
| Retrying by current positions would silently change the snapshot. | Recovery reads immutable saved targets keyed by plot/city ID/founding turn, including frozen Lighthouse presence. Incomplete qualification reservations cannot rescan that turn. | Entry/departure after failures, zero targets, replay, expired plans and replaced-city tests. |
| A UI status might be delivered after native economics. | Retain the unverified candidate, add a non-economic PlayerDoTurn phase observer, reject known-late starts and print explicit missing-early-snapshot diagnostics. | A baseline late-event case fails before and passes after. This is a simulated order, not proof of executable delivery. |
| Capture could be swallowed by the old global busy guard, or recovery could restore a captured target. | Capture runs independently, persists cancellation, saves zero-only cleanup and independently attempts both clears. Reacquire identities before writes; preserve newly appended cleanup intents. | Capture during setters, recapture, foreign/Lantern recipients, persistent clear failure and nested capture tests. |
| Corrupt receipts could disable all later turns or invite a duplicate fresh calculation. | Quarantine known malformed/duplicate/truncated blocks, conservatively seal an ambiguous active turn, retain unrelated data, and reject unknown newer formats without downgrade. | Known corrupt, future-turn, unknown-version and missing-receipt tests. |
| Old handler retirement could fail to remove a listener, the old generation could survive same-context inclusion, or old shutdown could affect a replacement. | Retire by controller generation/identity as well as bounded Remove calls; shutdown only clears its own registration. | Duplicate initialization, old shutdown/new owner, missing start event and capture fallback coverage. Native context lifecycle remains untested. |

Saved recovery also checks the actual current civilization. A scenario/debug player changed away from Lantern receives only zero cleanup, including for completed or pending old targets; Lighthouse permanent Culture is left alone. Both paths have focused regressions.

PlayerDoTurn never qualifies a city, sets a dummy count or adds Science/Culture/Gold. There is no convenient late or end-of-turn economic fallback.

## Save and recovery protocol

- `[LANTERN1|turn]`: the existing completed-turn receipt, kept compatible.
- `[LANTERN2|settledTurn|intentTurn|mode|rows]`: native-phase observation and pending intent. `R` means boundary admission reserved but no complete plan; `S` means a fully frozen plan; `N` has no pending target. Rows contain coordinates, native city ID, founding turn, harbor/gold counts and capture cancellation.
- `[LANTERN_CLEAR2|rows]`: zero-only capture cleanup which does not consume the recipient's next snapshot.

Real-building counts remain the economic effects. Acknowledged intent always precedes positive setters, every setter is idempotent, and completion follows verification. An unacknowledged in-context buffer can retry persistence but cannot authorize positive writes without acknowledgement. Ordinary completed loads do not change counts or inspect ships. Incomplete saved plans may finish on reload without paying stocks or observing new positions. Unknown future formats fail closed; quarantine preserves known damaged text rather than rewriting unrelated data.

## Turn-start engine evidence

The checksum-verified CP151 source at `44c1e14ff75d80c1dba5c8a71e8289439a53aafb` publishes TURN_START before doTurn. Its post-diplomacy continuation processes cities, Gold, Culture and research before PlayerDoTurn. The installed Firaxis turn-processing listener consumes AIProcessingStartedForPlayer and explicitly filters humans. The installed load screen uses UI:IsLoadedGame for Begin versus Continue. These are **publication, API and source-order facts**, not human event-delivery proof.

Human dispatch, tag types/values, IsTurnActive at delivery, synchronous delivery before every economic calculation and first-context lifecycle ordering are **not verified**. A late observer can reject events received after PlayerDoTurn; it cannot detect every possible delivery between earlier individual economic calculations. No genuinely suitable alternate early owner hook was established from public source. The user explicitly instructed not to launch Civ V, so native testing is not performed. The initial application approval attempt before that restriction timed out; no permission bypass or later launch attempt occurred.

## Executed tests

- 75 Lua 5.1 controller/probe scenarios: all original 27 retained, 45 new named hardening cases, two extra full-VM restart cases and one read-only probe test.
- Eight baseline failures reproduced and corrected with the same API mocks and shipped production controller. Individual failures/current passes are in Validation.json.
- Actual BNW snapshot + CP151 schema overlay, full active scalar/176 companion inheritance, altered-baseline properties/resources/Culture, exact 2 Science/2 combined Culture/2 conditional Gold, promotion values/retention/grant isolation, human-only registration, localization, XML, current manifest/project/VFS/SQL ordering, 40 DDS/mip checks and preserved compatibility flags.
- Twelve prerequisite/read-only unit tests.
- Complete current collection regression: all 21 current civilizations pass, with 1,381 files in the other civilization folders preserved. See CollectionRegression.json for the final result, current civilization list and redirected-report record. Legacy report writes are redirected to ignored evidence paths so preexisting modifications are not overwritten.
- Native tests: **none**. No numerical or asset change is used to conceal an engine limitation.

## Compatibility

The active CP151 Trireme/Lighthouse cloning and every original SQL action are unchanged. Sight=1, FriendlyLandsModifier=15, LostWithUpgrade=0 and Cutter-only initial grant remain intact. Native source uses friendly territory in melee offense/defense and normally copies retained promotions; native combat/upgrades still need acceptance. Coastal/plot ownership, native combat, domain, embarkation and death methods remain unchanged; IsCombatUnit is positive native base combat. Native serialization visitors include ScriptData, city founding turn and real-building counts, but actual save serialization was not exercised.

Existing completed Lantern saves remain readable. New journal/phase metadata is namespaced and no other ScriptData block is removed. Database IDs, collection UUID, current preexisting version and MinCompatibleSaveVersion=1 remain. Downgrading an interrupted journal save to the old controller is not a recovery mechanism. Multiplayer/hotseat remain unsupported; interleaved-owner tests prove local isolation only. Other civilization source, reports and artwork are hash-checked by the collection wrapper.

## Remaining risks, reproduction and remedy

| Severity | Remaining risk / reproduction | Remedy / boundary |
| --- | --- | --- |
| **Critical acceptance** | The candidate may be absent for humans, tagged differently, inactive at delivery or delivered after some native yields. Compare adjacent versus center placement at the immediate owner boundary, with/without UB, using actual stock/research deltas. | Follow Testing.md manually if native testing is later permitted. Reject an unsuitable event; do not claim native verification or substitute late staging/payouts. No supported replacement is proven. |
| **High acceptance** | Exact first-context/lifecycle ordering is untested. A controller introduced only after economics on the very first fresh turn, with no receipt/phase, can be indistinguishable from early fresh initialization using available evidence. | Normal modeled early starts and saved/recreated contexts are protected; validate actual initialization order. Treat ambiguous first-turn late installation as unsupported until established. |
| **Conditional high** | A building setter remains broken until after native economics. The frozen journal repairs counts later but cannot retroactively repair already banked Science/Culture/Gold. | Two immediate retries handle transient faults. Fix the API/mod conflict before advancing or reload the pre-boundary save. No direct catch-up payout or claim of atomic native economics. |
| **Conditional medium** | Failure before the full plan is durably captured leaves `R`; past qualification cannot be reconstructed. Previous counts may persist for the failed boundary. A VM restart after wholly failed persistence can lose an unacknowledged in-memory target. | Do not rescan moved ships or pretend completion. Diagnose logs, repair the cause and reload a pre-boundary save; the next genuine boundary can create a fresh plan. |
| **Conditional medium** | All capture setters or ScriptData writes persistently fail. Lua cannot guarantee immediate cleanup or durable cancellation under a permanently broken native API. | Independent zero retries, a persisted cleanup intent when possible, owner/identity checks and unchanged NeverCapture/ConquestProb=0 are safeguards. Repair the underlying failure; native failure/serialization testing remains pending. |
| **Low / deliberate** | Known corrupt active-turn receipts are quarantined and that ambiguous turn is suppressed; unknown newer save schemas are disabled. | Preserve data and avoid duplicate qualification. Resume at a later legitimate boundary for known repaired formats, or use the matching implementation/pre-corruption save. |
| **Unsupported** | Multiplayer/simultaneous/hotseat executable synchronization. | Current manifest does not support these modes. No network guarantee follows from local interleaving mocks. |

## Exact audit file changes

- TheLanternFleet/Lua/LANTERN_Harbors.lua — admission, phase guard, immutable journal, acknowledgment, recovery, cancellation/cleanup and receipt parsing.
- TheLanternFleet/Lua/LANTERN_TimingProbe.lua — actual research-progress/stock samples, typed tags/lifecycle/phase logs, explicit deltas and read-only handler retirement.
- tools/tests/lantern_mock.lua — real city identity/location and map lookup, native-like loaded/start-turn fields and read counters.
- tools/tests/lantern_assertions.lua — retain original cases; strengthen the no-late-fallback case to verify the non-economic observer.
- tools/tests/lantern_hardening.lua — 45 focused new production-controller cases.
- tools/validate_lantern.py — preserved newer SQL-order check, expanded source/API/serialization checks, full-VM/probe tests, baseline comparison and truthful verdict.
- tools/validate_lantern_collection.py — complete-suite runner which preserves all other civilization files and existing reports.
- Current preexisting Cool Wacky Civs 2 (v 23).modinfo — only the two changed Lantern Lua MD5 values refreshed. No project/action/entry/version change is necessary.
- TheLanternFleet/README.md, CHANGELOG.md, docs/Implementation.md, docs/Testing.md, docs/Files.md — updated guidance/audit inventory while preserving newer player-guide links.
- TheLanternFleet/docs/Validation.json, docs/CollectionRegression.json, docs/Hardening.md — actual validation/audit evidence and limits.

Original SQL, DDS, PNG artwork, unit models, generated project and unrelated working-tree content are not changed by this audit.
