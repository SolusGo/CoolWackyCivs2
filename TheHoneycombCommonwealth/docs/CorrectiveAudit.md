# Honeycomb Commonwealth corrective audit

Audited baseline: `80b44e9`. Target: Windows BNW + Community Patch DLL v151, official commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`. Date: 2026-10-30. Balance, database identities, collection UUID/version 17, protected dialogue, Dawn, art and unit models are preserved. Exchange help drops its unconditional immediate-cleanup promise and states that Gold clears when loss is detected.

## Verdict and classifications

**FIXED:** eight reproducible fault/lifecycle defects in the original controller. **PASS:** database inheritance/isolation, exact caps, source-supported next-payout staging, expanded modeled regression and asset validation. **LIMITATION:** owner-end sampling remains different from literal owner-start sampling. **NEEDS NATIVE TEST:** observed payouts, live save continuation, event delivery and rendering. No known unresolved failure remains in the supported automated scenarios. The source is ready for controlled gameplay acceptance; full in-game certification is not claimed.

The original ordinary threshold tests passed. The defects below were reproduced against the actual original Lua before correction, using adversarial native-call models. These are confirmed controller behaviors under the stated callback/failure conditions, not claims that an unmodified CP DLL spontaneously throws or loses writes.

| Original defect | Reproduction | Correction |
| --- | --- | --- |
| Interrupted dummy synchronization lost its frozen target on reload | Fail both setter attempts, change assignments, recreate context: old state remains instead of the original four-Plantation target | Save an unfinished binary-target journal before setters; replay only that frozen target on supported recovery events |
| A failed receipt write permitted a second count in the same turn | Reject receipt, change four worked Plantations to one, repeat owner-end callback: target changes to one | Retain the pending target until a verified completion receipt; never recount a same-boundary pending snapshot |
| Silent setter failure was acknowledged as complete | Ignore the first setter: only three Production dummies remain, but receipt says complete | Verify changed real-building state through a freshly resolved city; retry the same target and retain failures |
| One failing city aborted the remaining city batch | Put failing city first in a deterministic iterator: healthy second city receives nothing | Isolate each city, continue healthy targets, retain the unfinished batch |
| Broad busy guard discarded meaningful callbacks | Remove Exchange during a dummy setter: Gold remains after the building is gone | Coalesce primitive-argument jobs instead of dropping events; retain observed Gold revocations across reentrant rebuilds |
| Exchange eligibility was sampled later than Plantation counts | Construct second city's Exchange while applying first city's dummies: second city gets premature Gold | Freeze both worked count and Exchange eligibility before any setter |
| IsFinalInitialized alone did not establish load readiness | CP serializes this flag; a newly recreated context's dirty notification sees temporarily absent Exchange and removes valid saved Gold | Ignore UI dirty work until a completion notification or a verified gameplay event establishes readiness |
| An already-running retired controller could continue writing | Recreate context during a setter, remove/rebuild Exchange in the new context: old in-flight writer restores revoked Gold | Fence setters, batch continuation and receipt completion on current context ownership |

The new queue was additionally tested with more than 100 cities and a late reentrant sale. Its initial fixed 64-job budget delayed a required cleanup; the finished implementation adapts to drain the ordinary coalesced batch, with a 4,096-job ceiling for pathological event storms. Missing identities also retire an older controller before returning, avoiding retained callbacks with obsolete IDs.

## Every controller path reviewed

`CountWorkedPlantations` retains all original filters: own actual Plantation, unpillaged, native worked-citizen bit, matching effective working city, distance at most three, no center/nil plot and unique plot index. It runs once per city per new owner-end boundary. `ApplyCommonwealthBonuses` applies frozen seven-bit targets; it does not calculate extra yields or grant resources. `Set` avoids unchanged writes and resolves owner/ID/x/y/founding identity after every mutation, so capture/destruction/ID reuse cannot leave a stale native city reference in the next setter. Clear helpers use the same verified setter.

`Cleanup` removes only HCC markers from foreign cities and Gold from missing Exchanges; it never refreshes UA assignments. `UpdateCommonwealthCities` freezes all cities before mutation and preserves the legacy duplicate receipt. `Guard` bounds/coalesces reentrancy; `Hook` checks context ownership/readiness and retires subscriptions. Capture/founding handlers reacquire x/y after reconstruction, invalidate relevant unfinished targets and clear markers. Capture uses the verified old-owner/capital/x/y/**new-owner** ABI; gifts and liberation follow the same acquisition code. Destroyed cities have no retained native references. Building notifications use actual owner/city IDs; notification loss is remembered before deferring mutation.

## Save/load and recovery

Applied yields remain the actual native dummy buildings. Normal old/new saves with only `[HCC1:T]` are not reconciled on load. New `[HCCP2:T|id,x,y,founded,mask;...]` exists only while an operation is unfinished: it records identity and seven binary desired states, never accumulated yields, harvests, stored Production or Gold. It is written and read back before the first mutation, then removed in the same verified write that acknowledges completion. Other ScriptData text is preserved, including changes made during setters.

Each city receives at most two synchronous attempts per pass. A partial batch can resume from LoadScreenClose/SequenceGameInitComplete, owner processing or a duplicate owner-end call without any plot scan. A later legitimate boundary can establish a new snapshot. Exchange loss revokes pending Gold; transfers cancel pending targets at those coordinates. Tests cover reload after construction/sale/capture, duplicate initialization, before/after/silent setter faults, receipt failure, later-turn retry, free buildings and identity reuse.

**LIMITATION:** persistent failure of the native write/storage interface cannot guarantee recovery before the economic pass, and the later PlayerDoTurn recovery cannot retroactively repair an already missed payout. It logs the failure and retains valid pending targets; it never compensates through direct grants. Corrupt/malformed pending metadata is diagnosed rather than guessed. An old pre-fix save containing an already partial snapshot has no original target to recover; its next legitimate owner-end snapshot repairs it. Do not downgrade while a new pending journal exists. Native save round-trip acceptance remains outstanding.

## Independent timing analysis

Ten key cached source files were independently downloaded from the official pinned commit and matched byte-for-byte by SHA-256. Those digest assertions and 77 executable source contracts are retained in [SourceAudit.json](SourceAudit.json).

The native chain is: setter → `SetNumRealBuildingTimed` delta → `processBuilding` → building base-yield change → `UpdateCityYields`. The subsequent city `doProduction` consumes `getYieldRateTimes100(YIELD_PRODUCTION)` into stored Production. Treasury `DoGold` consumes city-inclusive net Gold; player Culture accumulation includes city Culture. All occur before PlayerDoTurn. Owner-end PlayerDoneTurn runs synchronously before unit reset and completed/end UI publications; sequential next-player activation follows deactivation. Thus a successfully staged dummy is in the native yield state consumed by the next payout. This is source evidence, not observed native execution.

Other candidates were checked: AI_doTurnPre has no script hook; PlayerPreAIUnitUpdate belongs to unit automation, not the owner economy boundary; ActivePlayerTurnStart is published after economics; PlayerEndTurnInitiated/Completed are still end-turn hooks. GameCoreUpdateBegin is a repeated update callback, and blocking-diplomacy economics can precede it. PlayerTurnStatus's earlier engine/UI publication does not prove a synchronous Lua delivery contract in the available source. No guaranteed exact pre-economic owner-start hook was established, so the reliable existing staging approach is retained.

| Change after owner-end staging | Next payout / following boundary |
| --- | --- |
| Pillage a qualifying Plantation | Staged bonus remains for that payout; following owner-end excludes it |
| Repair a Plantation | Previous staged bonus remains for that payout; following owner-end includes it |
| Change citizen assignments | Existing snapshot remains until the next owner-end count |
| Capture/gift/liberate/recapture city | Native NeverCapture plus targeted cleanup clears HCC markers; acquired city waits for recipient's next snapshot |
| Found city | No conditional bonus until its first owner-end snapshot |
| Construct/grant Exchange after a snapshot | Food follows the building normally; conditional Gold waits for a new snapshot |
| Remove Exchange | Food disappears natively; observed removal clears Gold and revokes pending Gold without clearing UA |

## CP compatibility, dummy isolation and presentation

**PASS:** active Scout/Market rows and every available relevant companion table are inherited at activation; altered-baseline tests preserve requirements, Combat, terrain, AI, promotions, upgrades, cost, maintenance, specialists, yields/modifiers and trade effects. Class identity preserves ordinary policy/technology interactions. Forager adds only Moves+1 and a Sight-only, unchoosable, lost-on-upgrade promotion. Honey Exchange adds exactly one Food. No Washington/shared trait leakage or VP dependency is introduced. The database adapter reconstructs CP schema from the installed BNW backup in memory; this is not falsely labeled an already-active CP database.

**PASS:** seven distinct unlimited ordinary building classes, one appropriate yield each, no build/purchase cost, maintenance, specialists, Happiness or Great Work slots. Native IsDummy excludes them from ordinary city building-count limits and suppresses construction rewards; native NeverCapture rejects acquisition. Native class-specific policy/religion/technology tables do not name the new classes. Native creation/history metadata may still record a dummy type, but its unlimited class has no gameplay cap or associated rule. Normal yield modifiers still apply.

**LIMITATION:** the inspected CP-only Market has maintenance zero, and CP refuses manual sale of zero-maintenance buildings. Honey Exchange correctly inherits that rule; the audit does not add maintenance to make a sale test possible. Sale callbacks are defensive and covered with modeled/altered-baseline cases. Native scripted removal publishes a city-dirty notification, but immediate UI delivery/coalescing is not established by DLL source. Silent removal, or remove-and-rebuild before any observable absence, cannot be guaranteed detected immediately without polling; the owner-turn defense handles an actually missing Exchange. This is explicitly a native-only delivery check.

**PASS:** 40 DDS assets decode; every full mip chain has the expected dimensions and exact payload length, with valid atlases, alpha/flag/map/Dawn/diplomacy references and VFS registration. Original dialogue/Dawn have independent immutable digest checks. No art regeneration or unit-model change was made.

## Performance and executed validation

Both Standard and Marathon modeled contexts execute the original scenarios, 16 additional hardening cases, a SQL-backed payout model and a 34-player scale case. The latter adds 680 cities (803 total), includes 142 Commonwealth cities for the measured owner, runs 4,000 foreign dirty events and 100 duplicate turn callbacks. Foreign/duplicate work performs zero plot scans or building/ScriptData writes. Each new owner snapshot reads exactly 36 citizen indices per city and normally performs two ScriptData writes (journal then receipt). Unchanged dummies incur no setters. There are no full-map searches, frame handlers or continuous polling. [Performance.json](Performance.json) reports mock timings, which are not native DLL profiling or an FPS guarantee.

Actual commands/results are recorded in [Testing.md](Testing.md) and [Validation.json](Validation.json). The focused suite verifies SQL, Lua 5.1, source contracts, modeled mechanics/payout, full DDS payloads and manifest hashes. The full collection suite checks existing civilizations. Intentional injected failures produce HCC diagnostics inside tests; those are expected assertions of fault handling, not live game logs.

## Native status, uncertainty and readiness

BNW executable and CP v151 are installed, but no running Civ V instance was found. Windows control failed before initialization with `failed to write kernel assets: The system cannot find the path specified. (os error 3)`, repeated after a kernel reset. No game was launched, no native result is marked passed, no installed mod/config/save was changed and no package was built. The installed collection's v17 manifest still predates HCC, so the audited source must be deployed before native acceptance. Follow [NativeAcceptance.md](NativeAcceptance.md).

Suspected but unconfirmed items are confined to live engine/UI delivery, save-transition ordering, actual payout under the governor and render/layout behavior. No further SQL/balance/art defect was found. **NEEDS NATIVE TEST** remains the readiness qualifier for ordinary play beyond controlled acceptance.

## File changes

Modified: `Lua/HCC_Commonwealth.lua`; existing collection modinfo (Lua/text MD5s); `tools/validate_honeycomb.py`; `tools/tests/honeycomb_assertions.lua`; `tools/generate_honeycomb.py` and `SQL/10_HCC_Text.sql` (one help sentence); HCC README/changelog/Implementation.md/Testing.md/SourceAudit.json/Validation.json; collection README/changelog. Added: `tools/tests/honeycomb_hardening.lua`, `honeycomb_payout.lua`, `honeycomb_scale.lua`; `docs/CorrectiveAudit.md`, `docs/NativeAcceptance.md`, `docs/Performance.json` under this civilization. Core/inheritance/effects/art SQL, project inventory, dependencies, art and unrelated civilization gameplay are unchanged. Test-generated reports for unrelated civilizations are excluded.
