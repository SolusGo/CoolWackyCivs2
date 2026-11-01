# Validation and native acceptance

**Verdict: STATICALLY VALIDATED, NATIVE ACCEPTANCE PENDING.** No native game test was run. The user explicitly instructed not to launch Civ V; this audit does not ask to override that restriction.

## Executed checks

```powershell
.venv/Scripts/python.exe tools/validate_lantern.py --compare-baseline 512bc608d2d5f5e245f037fc8399b586ea2e3c9e
.venv/Scripts/python.exe -m unittest discover -s tools/tests -p test_validation_prerequisites.py
.venv/Scripts/python.exe tools/validate_lantern_collection.py
```

The Lantern validator applies the complete current collection SQL to a read-only BNW snapshot plus CP151 schema in memory. It preserves all preexisting database rows, checks the human-only identity/assignments, active scalar inheritance and 176 Unit/Building companion tables, upgrade/resource relationships, exact promotion fields and exact added yields. Altered baselines change cost/combat/movement, add unknown scalar columns and resource requirements, and supply preexisting Lighthouse Culture. The original Trireme/Lighthouse rows remain unchanged.

Lua 5.1 syntax, XML, localized keys, one gameplay entry, VFS uniqueness, current manifest/project registration, hashes, contiguous original SQL ordering, 40 DDS decodes/mip chains, existing save compatibility flags and the collection description separator are checked. Later appended civilizations remain supported. The separator was already corrected in the newer working tree and is preserved.

**75 shipped-controller/probe Lua scenarios pass:** all 26 original named cases plus the original VM-restart case, 45 focused hardening cases, two additional full-VM restart cases, and the optional probe test. These include fresh human/scenario-AI starts, advanced native start turns, a controller present before the first notification, mid-turn loads/recreation, old/missing/duplicate/malformed/truncated/future receipts, one-city/one-dummy partial writes, before/after-mutation API errors, unacknowledged persistence, completion-write failure, immutable recovery after movement, full-VM partial saves, expired plans, invalidated city identities, capture/recapture/reentrancy/nested cleanup, absent event/lifecycle APIs, interleaved owners, late-event rejection, observer non-mutation, old-context shutdown and no movement/load-based qualification. Actual qualification cases (center/adjacent, owner/team/allied, Cargo Ship, embarked, dead/delayed, coast/inland, multiple ships/cities, later warship, UB presence/completion) remain covered.

Eight focused regressions fail against the baseline controller and pass against the current controller: initial human/AI suppression; partial second dummy; partial second city; throw after native setter mutation; reload after partial application; capture during a snapshot setter; and status received after the late economic boundary. See Validation.json for all test names and actual before/after failure messages. The original no-late-fallback scenario now explicitly verifies the additional observer scans no ships and changes no building counts; its old literal zero-listener assertion was intentionally replaced by that behavioral check.

The 12 prerequisite/read-only unit tests pass. The complete current collection suite uses a wrapper that redirects legacy JSON evidence into ignored tools/reference rather than rewriting existing civilization reports. Its final result, civilization list and preservation count are in CollectionRegression.json. These are static and simulated checks, not game acceptance.

## Source evidence and limitations

Pinned official CP151 commit: `44c1e14ff75d80c1dba5c8a71e8289439a53aafb` (checksum-verified). The source proves:

- TURN_START is published before doTurn; city processing, DoGold, Culture accumulation and doResearch precede PlayerDoTurn. It does not expose the executable's status-to-Lua event delivery.
- The installed Firaxis listener uses AIProcessingStartedForPlayer(playerID, tag) and filters humans itself. This is not proof that human callbacks occur, are synchronous, have an empty tag or see IsTurnActive=true at the required instant.
- Firaxis LoadScreen.lua uses `UI:IsLoadedGame()` to choose Begin/Continue. CP exposes Game.GetStartTurn and the identity/ScriptData/research-progress methods used here. Their existence is verified; initial context timing is not.
- CvUnit::IsCombatUnit checks positive native base combat; GetUnit indexes the queried plot, not neighbors. Native sea-domain/embarked/death methods are bound.
- Both melee attack and defense use the generic friendly-territory modifier; VisibilityChange/FriendlyLandsModifier are real CP columns; upgrade copying respects LostWithUpgrade=0.
- Player ScriptData, city founding turn and real-building counts are in the native serialization visitors. This does not prove an actual save/load round trip or an atomic economic transaction.

No verified replacement early simulation hook was found in the inspected public CP151 sources. PlayerDoTurn is too late, ActivePlayerTurnStart is published after doTurn, PlayerDoneTurn is an end boundary, and PlayerPreAIUnitUpdate belongs to unit updates. End staging/global-turn substitution/frame polling do not preserve this design. The candidate event is retained with explicit diagnostics, not certified.

## Reproducible FireTuner protocol (manual, not executed)

Use a disposable new single-player BNW + CP151 game and the current collection. No Vox Populi. Back up saves/configuration; enable LoggingEnabled/FireTuner only if doing this manually. Prepare a peaceful, fully revealed coastal test city. Hold population, citizens, policies, beliefs, Golden Age state, improvements, resources, research target, trade and expenses fixed. Keep Gold positive and choose a research target that will not finish during either comparison.

Use the **same owned ship** in both branches, adjacent in A and inside the center in B. Do not compare different unit ownership/maintenance. Start both branches with both dummy counts zero and make their native pre-boundary economy identical. Avoid native garrison-specific modifiers. Retain the same native Lighthouse effects: ordinary Lighthouse for the no-UB control, Signal Lighthouse for the UB branch; never have both at once.

1. Select the `LANTERN_Harbors` context in FireTuner. Run `include("LANTERN_TimingProbe")`. It is a manually loaded, read-only module. It never spawns units, changes buildings or grants stocks.
2. Run `before=LANTERN_TimingMark("before_boundary",0)` (substitute the actual owner ID). Advance exactly one owner-turn boundary. Run `after=LANTERN_TimingMark("after_boundary",0)` and `LANTERN_TimingDelta(before,after)`. Lua.log contains LANTERN_TIMING, LANTERN_PHASE, LANTERN_CITY and LANTERN_DELTA. Numeric values ending in 100 are hundredths.
3. The probe records **actual selected-tech research progress**, Culture stock and Gold stock, plus the research identity. It refuses a delta across a changed/finished research target. Rates/tooltips are auxiliary, never payout proof. Control interturn changes and compare identical A/B branches; an individual raw stock delta includes ordinary income/expenses.
4. Without the UB, guarded minus unguarded should add research100=200, culture100=100, gold100=0 in that immediate boundary with no modifiers. With the UB in both branches, guarded minus unguarded should add 200/100/200; its permanent Culture appears in both. Relative to the ordinary-Lighthouse unguarded control, guarded Signal Lighthouse adds **200/200/200**, plus unchanged ordinary Lighthouse effects. Apply native modifiers when the fixture cannot eliminate them.
5. Inspect the exact candidate tag value/type and IsTurnActive for the human owner. It must arrive at the correct phase. The new observer rejects callbacks *after* PlayerDoTurn; a callback earlier than that observer could still be after Gold or another settlement. Therefore absence of a rejection does not prove correctness. Compare actual stocks/research, and record both zero-to-one and one-to-zero transitions.
6. Move the ship in/out after the snapshot, replay notifications, save/reload completed and partial states, recreate the context, test saves immediately before/after the boundary, and test initial/advanced scenario starts. No later unit position may change an existing snapshot or saved target plan. Capture must clear both counts immediately, including Lantern-to-Lantern; a remaining Signal Lighthouse keeps its permanent Culture. Repeat with a scenario-AI owner if supported.
7. Run the complete native qualification matrix and inspect Database.log/xml.log/Lua.log, Civilopedia, Dawn/leader/art/flags, combat previews in own/team/open-border/neutral/enemy territory and the active upgrade path. Ordinary Triremes must not receive the promotion. Native saves, counts and actual economic deltas must be recorded separately from these simulations.
8. Stop with `LANTERN_StopTimingProbe()`. The collection still declares multiplayer/hotseat unsupported. The interleaved-owner mock is not multiplayer or simultaneous-turn acceptance.

If human delivery is absent, the tag/activity assumptions fail, or stock differences appear a turn late, mark the candidate unsuitable. Do not substitute PlayerDoTurn, end staging, direct payouts or DLL edits. Document the missing engine hook. For unrecoverable interrupted economic settlement and other exact limits, see Hardening.md.
