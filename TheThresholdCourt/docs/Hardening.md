# Threshold Court corrective audit — 1.14.1 / mod version 17

Reference: `5456f2ae4ab0bd3ce7f9b34da52e9dec0c37c38d`. This is a targeted correction; the relocation/receipt architecture, balance, identity, artwork, localization and UI are retained. Native Civ V gameplay/render/save acceptance is still pending.

## Confirmed defects and corrections

| Finding | Cause and fix |
| --- | --- |
| Washington ability inherited | The generic `Leader*` companion clone included `Leader_Traits`. Executed SQL produced both `TRAIT_DOOR_IN_EVERY_WALL` and `TRAIT_RIVER_EXPANSION`. Generation now allows only the three native flavor/approach tables and excludes primary traits, optional shared-policy traits and unknown extensions. |
| Eliminated origin left surviving gifts/conversions exhausted | Sync required a living human origin, so its clock never advanced after death. A separate safe turn-boundary sweep now releases known dead-origin stamps strictly after their crossing turn, independently of that player's financial state. |
| Stray/corrupt effect could veto unrelated movement | The handler used a promotion or loosely parsed record as sufficient evidence. Movement/upgrade vetoes now require a current creation/type-matched stamp whose originating player is a Court civilization. Invalid records do not become global movement vetoes. |
| Late financial recovery exhausted the next owner-turn | Sync recovered before advancing its owner clock, and recovery unconditionally called FinishMoves/SetMadeAttack. The clock now advances first; restrictions expire independently of financial recovery, and recovery applies those setters only in the original owner-turn. A prepared cancellation restores saved movement only in that same turn. |
| A corrupt financial ledger prevented independent unit expiry | The early invalid-player-state return also skipped valid unit deadlines. A verified owner-turn can now expire an independently valid unit stamp without touching the corrupt ledger; portals remain disabled. An executed additional regression reproduced this before the final fix. |
| Numeric corruption could masquerade as a receipt | Syntax/range checks alone admitted impossible phases/costs/turns/types/endpoints. Semantic checks now reject impossible data without erasing it or speculatively charging Gold. |
| Veto exception fallback returned nil | Lua's `veto and false or nil` cannot return false. The existing wrapper now returns false explicitly for a failing veto; normal unrelated callbacks return true before any restriction is applied. |

## Exact trait audit

The complete `Leader_Traits` relation for `LEADER_QUEEN_ELSEWHERE` is asserted as:

```text
[TRAIT_DOOR_IN_EVERY_WALL]
```

The assertion checks multiplicity as well as membership, so duplicate intended traits also fail. `Leader_SharedTraits` has no Queen rows. Unknown leader gameplay tables are excluded too; a populated sentinel table tests regeneration. Complete non-Queen primary/shared relations and Washington's own rows are compared before/after activation. Harmless `Leader_Flavors`, `Leader_MajorCivApproachBiases` and `Leader_MinorCivApproachBiases` remain baseline metadata. No other civilization's trait assignments are repaired or changed by this pass.

## Elimination cleanup boundary

For a living origin, nothing changes: the unit remains exhausted until that origin's next owner-turn, including while held by another major or a city-state. UnitConverted copies the existing marker to the new native instance with its current creation turn/type. Gifting/conversion never releases exhaustion early.

For a dead origin, the first eligible `PlayerDoTurn` sweep with `Game.GetGameTurn() > crossingTurn` removes only `PROMOTION_THRESHOLD_EXHAUSTED`, `[THC_U1:...]` and optional `[THC_O1:...]`. The sweep runs at most once per eliminated origin per game turn and only scans living recipients when a dead Court exists. There is no frame/timer scan, no elimination callback mutation and no cleanup inside UnitConverted/combat. Death in crossing turn T cannot release a unit on another player's turn T. A load resets only the transient sweep budget; the native stamp still enforces T+1 or later.

Malformed/missing unit origin records cannot safely identify a living source. With any living Court, these remain diagnosed without guessing. With no living Court, an additional native unit block `[THC_O1:firstObservedTurn]` persists one full quarantine turn before removing only the temporary effect. Context rebuild cannot skip that delay. Corrupt/ambiguous financial receipts are never cleared by orphan cleanup. Dead units are skipped; a fault on one survivor does not prevent another survivor's cleanup, and failed cleanup retries at a later boundary.

Cleanup never calls SetMoves, FinishMoves, SetMadeAttack, damage/experience setters or changes unrelated promotions. Native counters therefore remain exactly as they were. Revival before cleanup resumes normal living-owner timing; revival after cleanup does not recreate a restriction.

## Movement compatibility

CP v151 dispatches CanMoveInto only when both `EVENTS_CAN_MOVE_INTO` and the unit **type's** `SendCanMoveIntoEvent` are enabled. It has no per-owner/per-instance opt-in exposed here. Guaranteeing movement exhaustion for ordinary shared melee types consequently requires shared type metadata; replacing units or changing the DLL would violate this civilization's design.

The SQL update is narrowed to the existing transfer validator's static candidates:

```sql
Domain = 'DOMAIN_LAND' AND Combat > 0
AND COALESCE(RangedCombat, 0) = 0
AND CombatClass IS NOT NULL
AND CombatClass NOT IN ('UNITCOMBAT_ARCHER','UNITCOMBAT_SIEGE','UNITCOMBAT_HELICOPTER')
```

Current embarked/defensive-only/dead/busy conditions remain native per-instance checks. Existing event opt-ins on every other type are preserved, including Jin's ranged Grenadier and defenders. Eligible upgraded melee/gun/mounted types receive dispatch; normal upgrades are still forbidden during active exhaustion. A late-loading external type must provide this same native opt-in or remains unavailable to the portal validator, as before this pass.

The callback accepts the pinned six arguments `(owner, unit, x, y, attack, declareWar)`; unused trailing flags do not affect the decision. It returns true without a valid active restriction. A true result does not override another controller's false result: CP uses TestAll. The composed regression executes the **shipped** Jin leash predicate on the same modeled event bus and tests allowed movement, excessive distance and city entry. The full Jin suite also runs through the collection validator.

Shared opt-in can expose arbitrary external handlers that previously received fewer unit types. All collection behavior is tested, but compatibility with an external unscoped veto cannot be guaranteed without testing that mod. There is no claim that metadata opt-in is private to Court owners.

## Receipt and balance audit

The original unit is still moved with numeric-flag `SetXY`; there is no replacement-unit repair. Native ID/type, health, XP, custom promotions and existing restrictions remain intact. Gold still follows confirmed exact-tile arrival once; a charged receipt can be retried/reloaded without charging twice. Unexpected positions, disappeared/reused unit IDs and ambiguous treasury preserve the receipt and block new transfers. A quarantined financial receipt no longer immobilizes a unit in a later owner-turn. Ownership/generation checks still prevent applying a former origin's cooldown to a captured/rebuilt city.

One crossing per owner-turn, origin T+8, native Era cost `50 + 25 × GetCurrentEra()`, unlimited distance, owned Houses, free destination military slot, exact city-tile arrival, eligible land melee units, and exhausted arrivals remain unchanged. Destination receipt never starts its own cooldown. Hingeguard remains active Pikeman +1 Move/+15% native friendly battle-plot strength, without extra base combat. Threshold House remains active Market +1 Culture. Human-only flags remain 1/0; no AI portal or multiplayer support was added.

## Executed checks and failures

The pre-fix complete-trait assertion failed with the additional `TRAIT_RIVER_EXPANSION`. Three new Lua regressions were executed against the old implementation and failed for dead-origin cleanup, promotion-only movement veto and next-turn receipt exhaustion. An additional executed corrupted-ledger regression then reproduced blocked unit expiry before its final corrective branch was added. These failures are recorded in the local diagnostic runs; they are not simulated claims about an unexecuted test.

The final focused validator runs eight suites on four speeds (32 modeled Lua 5.1 runs), compares 176 companion tables and dynamic Market/Pikeman sentinel baselines, checks regenerated trait isolation and narrowed per-type opt-ins, decodes all 48 Court DDS files and checks 65 pinned native source contracts. See [Validation.json](Validation.json) for the executed result and [Testing.md](Testing.md) for commands and the native checklist. The full collection validator and release builder/verifier are also required; local logs are retained under ignored `dist/threshold-hardening-*.log`. Deliberately injected read/write/relocation/payment failures inside passing suites are expected diagnostics, not successful native gameplay tests.

## Verified CP v151 interfaces

Pinned official commit: `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`, DLL version 151. The source report contains URLs and SHA-256 values. Verified interfaces include legacy `PlayerDoTurn(owner)`, nine-argument CityCaptureComplete (handler uses its leading owner/capital/x/y values), UnitSetXY(owner/unit/x/y), UnitConverted with `iiiib`, CanMoveInto with `iiiibb`, CanHaveUpgrade with `iiii`, native player/plot/unit ScriptData serialization, IsAlive, current Era/treasury/unit lookup, numeric relocation/endpoint flags, movement setters, and native promotion removal's negative OnlyDefensive counter delta. PlayerDoTurn is before `doTurnUnits` and outside the immediate elimination/combat callback; per-unit flags gate the TestAll movement veto.

## Remaining native risks

No game was launched for this audit. Real database activation, saves/autosaves/application restart, combat-time last-city elimination and conversion, gifting to city-states/majors, revival, quarantine load timing, late receipt recovery, actual movement restoration/Blitz, UI, Huge-map transfer and whole-game balance still require native verification. The static portrait/Pikeman field model are unchanged.

**Older v17 saves:** the source's trait Read path loads serialized aggregate trait values, even though leader trait membership is refreshed from the current database. Removing the bad SQL association does not prove that every cached/granted Washington effect disappears immediately in an old campaign. No exposed direct trait-cache refresh is used, no policy/technology manipulation is introduced, and no retroactive refund/promotion stripping is attempted. Start a new Court game for a clean corrected trait baseline; back up existing saves. Existing portal save blocks remain compatible, but native old-save continuation is not certified.

## Exact files changed by this corrective pass

```text
CHANGELOG.md
README.md
Cool Wacky Civs 2 (v 17).modinfo
TheThresholdCourt/CHANGELOG.md
TheThresholdCourt/README.md
TheThresholdCourt/Lua/THC_Core.lua
TheThresholdCourt/Lua/THC_State.lua
TheThresholdCourt/Lua/THC_Events.lua
TheThresholdCourt/SQL/01_THC_Inheritance.sql
TheThresholdCourt/SQL/02_THC_Effects.sql
TheThresholdCourt/docs/Hardening.md
TheThresholdCourt/docs/Implementation.md
TheThresholdCourt/docs/Testing.md
TheThresholdCourt/docs/Validation.json
tools/generate_threshold.py
tools/validate_threshold.py
tools/validate_cats.py
tools/validate_kingdom.py
tools/tests/threshold_mock.lua
tools/tests/threshold_transfers.lua
tools/tests/threshold_elimination.lua
tools/tests/threshold_movement.lua
tools/tests/threshold_recovery.lua
```

The two existing collection validators change only their exact permitted notification-bit expectation to match the narrower predicate. No existing civilization gameplay/artwork is edited. No version increment or save-block replacement occurs; the v17 manifest and ignored ZIP/7z artifacts are regenerated. The optional new quarantine tag is additive.
