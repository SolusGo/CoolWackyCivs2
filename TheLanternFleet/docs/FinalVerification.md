# Final verification — 2026-11-02

**STATICALLY VALIDATED — NATIVE ACCEPTANCE PENDING.** Audited gameplay commit: `920cbcbc2277bb78d6c263037003ffb1cd61961f`. The checkout and fetched origin/main matched that commit before this pass. No native execution was permitted: the user's earlier instruction not to launch Civ V remains in force. No launch, application-control attempt or protected-file modification was made in this verification pass.

## Event verification

The controller still uses **Events.AIProcessingStartedForPlayer**. No evidence establishes that this candidate is wrong, and no evidence establishes that it is suitable in the actual executable. Replacing it or changing the economy would therefore be speculative. The existing frozen journal, first-turn safeguards, capture cancellation, recovery and duplicate protection are unchanged.

| Required native observation | Result |
| --- | --- |
| Human Lantern owner receives the event | Not demonstrated |
| Callback player ID equals the owner | Not demonstrated |
| Legitimate tag is nil or an empty string | Not demonstrated |
| IsTurnActive is true at delivery | Not demonstrated |
| Delivery precedes Science, Culture **and** Gold settlement | Not demonstrated |
| Fresh, loaded and advanced-scenario lifecycle ordering | Not demonstrated |
| Duplicate/delayed behavior in the executable | Not demonstrated; expected sequences and rejection/recovery are tested only in simulation |

The checksum-verified public CP source at `44c1e14ff75d80c1dba5c8a71e8289439a53aafb` establishes that CvPlayer::setTurnActive publishes TURN_START before doTurn. Its economic continuation processes cities, Gold, Culture and research before PlayerDoTurn. The installed Firaxis TurnProcessing.lua subscribes to AIProcessingStartedForPlayer and filters humans itself. LoadScreen.lua uses UI:IsLoadedGame for Begin versus Continue. These facts do not expose the executable's dispatch implementation or demonstrate delivery for a human.

PlayerDoTurn remains diagnostic only. It does not qualify cities, change dummy counts or award yields. A callback before this late observer could still be after one of the earlier calculations. Its position alone cannot certify same-turn payout. No verified alternative early owner callback was established from the available source; PlayerDoTurn, end staging, global-turn substitution, frame polling and direct payouts were not substituted. The DLL was not modified.

## Economic results

There are **no native before/after research, Culture or Gold values to report**. The following differences are acceptance expectations, not measurements:

| Paired branches, B minus A | Science | Culture | Gold | Native measurements |
| --- | ---: | ---: | ---: | --- |
| Same ship adjacent in A / inside center in B; no Signal Lighthouse | +2 | +1 | +0 | Not run |
| Same comparison with Signal Lighthouse in **both** branches | +2 | +1 | +2 | Not run |

Values are base yields before applicable modifiers/rounding. The UB's permanent +1 Culture belongs to both UB branches and cancels from their difference. A guarded Signal Lighthouse city still adds +2 Science/+2 Culture/+2 Gold relative to ordinary Lighthouse effects.

Use [Testing.md](Testing.md)'s controlled paired-save protocol. It keeps the **same ship in both branches**, identical pre-boundary dummy counts, population, research target, policies, beliefs, Golden Age, trade, expenses and other modifiers. Advance exactly one owner-turn and compare actual banked research/Culture/Gold, not rate displays. Repeat both entering and leaving qualification transitions, with/without the UB, and record native lifecycle/save/capture cases.

## Diagnostic script and manual procedure

The existing LANTERN_TimingProbe.lua already supplies every requested field: game turn, owner ID, human/AI flag, activity, event phase, tag value/type, selected research identity and progress, Gold/Culture stocks, both dummy counts and saved completion/phase receipts. It remains read-only and is not automatically loaded by the gameplay entry.

In a manually authorized test session, select the LANTERN_Harbors FireTuner context:

```lua
include("LANTERN_TimingProbe")
before = LANTERN_TimingMark("A_without_UB_before", 0) -- use the actual owner ID
-- Advance exactly one owner-turn through the game's UI.
after = LANTERN_TimingMark("A_without_UB_after", 0)
LANTERN_TimingDelta(before, after)
LANTERN_StopTimingProbe()
```

Run the corresponding B branch from its controlled pre-boundary save and repeat with the UB in both branches. Preserve the logs outside the game between loads: the probe's Lua sample numbers reset when its context is recreated. Delta fields are hundredths. The probe refuses comparison across different/finished research targets; retain one unfinished target in both branches. Validate turn/sample IDs in the log before using a delta. Map `candidate_status` to AIProcessingStartedForPlayer and `after_native_economy` to PlayerDoTurn. Do not infer economic correctness solely from their printed order.

## Automated results and fixture limitation

- **75/75** shipped Lua controller/probe scenarios pass, including all original cases and first human/scenario/advanced starts, loaded/context-recreated state, legacy receipts, partial journals, movement after snapshots, duplicates, capture and civilization-change cleanup.
- **12/12** prerequisite/read-only tests and **2/2** verification-runner gate checks pass. Strict mode rejects the populated cache, and opt-in mode still rejects unrelated prerequisite failures.
- Current BNW snapshot + CP151 schema overlay validation passes: active unit/building scalar properties and **176 companion tables**, altered baselines, exact bonus values, human-only flags, promotion retention/grant isolation, localization, Lua 5.1, XML, current manifest/project/VFS/hashes and all **40 DDS textures**.
- Full collection execution was attempted. The first attempt stopped at Saba and a second reached Conical, where optional live-cache activation probes stopped because the live Civ5DebugDatabase.db already contains the collection, which the pristine-baseline preflight correctly rejects. That optional probe is **unavailable**, not passed. The clean archived fixture used by the principal checks remains valid.
- The explicit availability-aware remaining-phase run and preservation results are recorded in FinalCollectionRegression.json: available checks across **21 civilizations** passed, and **1,381 other-civ files** were preserved. It executes the unchanged collection validators, including Saba's principal checks, without replacing a database or economy. Only the rejected optional fixture is hidden from existing availability gates for the Twelfth, Circus, Saba, Conical and Unrung live-cache probes. Principal checks use the valid archived baseline as usual. No unrelated validator or civilization is edited. The shared unavailable fixture remains listed separately in the result; none of its optional activation probes is converted into a passed native or fixture test. Completed core-through-Classroom checks and the Conical-through-Triumphal continuation are recorded as separate phases, with the earlier log's SHA-256. Gameplay inputs remained unchanged between phases.

Reproduce the checks without launching the game:

```powershell
.venv/Scripts/python.exe -c "import sys;sys.path.insert(0,'tools');from validate_lantern import source_contract,sql_checks,static,runtime;source_contract();d,n=sql_checks();static(d);runtime()"
.venv/Scripts/python.exe -m unittest discover -s tools/tests -p test_validation_prerequisites.py
.venv/Scripts/python.exe tools/verify_lantern_final.py --date 2026-11-02 --allow-unavailable-optional-cache
```

Without that last explicit opt-in, the verification runner rejects the populated live cache. It does not touch the cache or silently substitute a backup for the unavailable active-cache probe. Other prerequisite or assertion failures still fail the run. Historical audit reports are retained; current results are in FinalVerification.json and FinalCollectionRegression.json.

## Changes and compatibility

No gameplay/controller/probe fix was supported or required by the available evidence in this pass. No SQL, artwork, models, balance numbers, registration, collection version or save format was changed. Beacon Cutter remains the active Trireme clone with +1 Sight and +15% native friendly-territory Strength; the retained promotion and normal requirements/upgrades are unchanged. Signal Lighthouse remains the active Lighthouse clone with +1 permanent Culture and +2 conditional Gold. Playable=1/AIPlayable=0 remains.

Files changed/added by this pass:

- **tools/verify_lantern_final.py** — reproducible final collection runner; explicit handling/reporting of the observed unavailable optional cache fixture, while preserving historical and unrelated reports. This fixes a verification-path availability problem, not a civilization mechanic.
- **TheLanternFleet/docs/FinalVerification.md** — this final evidence, manual procedure, limitations and recommendation.
- **TheLanternFleet/docs/FinalVerification.json** — dated observed Lantern/source/schema/simulation results; native measurements remain null.
- **TheLanternFleet/docs/FinalCollectionRegression.json** — current collection results, preserved-file count and unavailable-probe record.
- **TheLanternFleet/README.md** and **TheLanternFleet/docs/Testing.md** — links to this current report; previous hardening and manual acceptance instructions retained.

## Remaining risks and recommendation

**Critical native acceptance remains open:** human event delivery, arguments/activity, first-turn/load/scenario ordering and immediate economic deltas. Controlled native A/B settlement and lifecycle tests are required to close it. Source publication and mocked dispatch cannot do so. If those tests show unsuitable delivery, establish a genuinely earlier supported hook before changing code; otherwise report the engine/API limitation.

Persistent API failures spanning economic settlement remain the journal's documented limit: restoring counts cannot retroactively repair already banked resources. Actual native serialization, UU combat/upgrades, rendering and native performance are also untested. Multiplayer/hotseat remain unsupported.

**Recommendation:** suitable only as an experimental, statically validated implementation. Do not describe it as gameplay-verified for normal play, and do not rely on the Guarded Harbor economy in large/balance-sensitive Civilization V simulations until native timing and lifecycle acceptance pass. Native large-simulation performance has not been profiled.
