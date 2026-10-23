# Implementation

`GARVEY_` is the database, VFS, Lua-event and save namespace. One InGameUIAddin, `UI/GARVEY_RollCall.xml`, includes the Core, Events and Interface modules. Included Lua/textures enter VFS; SQL and the addin XML do not. No global CityView changes or vanilla file edits are needed. Existing collection content loads first, preserving its numeric database IDs.

## Save and turn contract

One versioned `Modding.OpenSaveData()` value per player stores clock, original capital foundation turn, next availability, selected student, bonus deadline, Insubordination, Detention deadline and availability-notification marker. Firaxis save functions use **dot calls**. Writes are read back before accepting a selection. Missing state is initialized from the capital foundation turn; malformed/newer state disables commands and strips temporary effects rather than resetting progression. Lua keeps no persistent native city/unit objects.

CP v151 settles city yields and research before `PlayerDoTurn`. Selecting on turn T applies modifiers immediately. They remain for actions on T through T+7 and the eight future economic settlements T+1 through T+8. The player's T+8 callback advances the saved clock and removes the bonus before further actions. Detention follows the same rule with five turns. Other players' events use the saved owner clock, so they cannot remove the final yield tick early. Duplicate callbacks, loading and UI access do not decrement timers. Pending Roll Call has no expiration; only selection replaces its deadline.

Selection checks human/civilization/active-player/active-turn/capital/UI eligibility and the rendered availability deadline. `Game.Rand(100, ...)` resolves one correction, and is never called for Timothy. State commits before modifiers and notifications, preventing rapid clicks from choosing or rerolling twice. Idempotent saves/reconciliation receive one synchronous retry after a transient failure; RNG, notifications and Culture delivery never enter that retry. No automatic AI choices occur. The original v1 state fields and kill keys are unchanged.

## Native effects and lifecycle

Six hidden, zero-maintenance, never-captured dummy buildings express native military Production, CultureRateModifier and Building_YieldModifiers. Two branchless free dummy policies express exactly one signed Happiness penalty. CP applies `ExtraHappiness` once through the capital; it is neither multiplied by Office count nor deducted once per city. Policy adoption is blocked for these maintenance identities. Both policies are removed on expiry or loss of human eligibility. Actual city Science bonuses only exist where an Office currently exists.

Native `CombatPercent` promotions add strength; Lua never modifies damage or base strength. `FriendlyLandsModifier` evaluates the battle territory through CP, including its normal friendship/access rules. Hidden temporary promotions have `LostWithUpgrade=1`; unit-created/trained/converted/upgraded hooks reapply only currently eligible empire effects and the Hall-specific Detention bonus only to actual Hall Monitors. Full turn and load reconciliation repairs missed scripted changes. Capture/transfer reconciliation removes city markers from foreign owners.

`CombatResult` snapshots the two units' actual maximum base melee/ranged strength and the battle tile. `CombatEnded` consumes that snapshot once, checks final cumulative damage against maximum HP and awards only the Hall Monitor effect. Detention instead uses `UnitPrekill` for attributed lethal damage to an enemy military unit, covering nuclear and collateral deaths too. CP's ordinary `UnitKilledInCombat` callback lacks a winner-unit ID and is not used. A per-save unit-lifetime/effect paid marker prevents delayed/final callbacks from paying twice across reloads; the two different effects can still stack. Captures, disbands, friendly fire and nonlethal script removals fail eligibility checks. Culture enters the player's policy pool.

## Interface and performance

The blackboard attendance sheet displays availability, student duration, patience and Detention, with five explicit choices. Its scrolling body fits short windows without fixed overlapping rows. Only the active human Classroom sees the launcher. The shared collection modal gate was adapted from `CK_Interface.lua`, retaining city, diplomacy, tech, Civilopedia and popup checks; strategic-view events also hide it. Commands validate the same gate as rendering.

UI events schedule at most one pending frame callback, which **detaches before execution**. Generic GameData/CityInfo dirty events are UI-only. CP's post-mutation `SpecificCityInfoDirty(playerID, cityID, updateType)` queues only affected city IDs, including scripted real/free building mutations. The native `CountNumBuildings` cache supplies Office presence to policies/UI without a Lua city scan. CityRazed excludes the dying Office before native removal and schedules a final policy check after deletion. Full owner-turn/load/capture/selection reconciliation remains. Dirty storms coalesce; idempotent setters skip unchanged counts. There is no periodic timer, idle update or map scan. Unrelated players' turns do not scan Classroom cities or armies.

Three native bullet pips supplement the existing patience text; Detention lights all three while the actual counter remains reset. Existing screen gates and all five choices remain. See [the audit](AuditReport.md) for source-contract evidence, fault tests and native limits.

## Art

Original Mr. Garvey painting generated with the built-in imagegen tool; source and exact prompt are retained in `art-source/TheSubstituteClassroom`. Deterministic clipboard, monitor shield, office door, floor plan and blackboard graphics follow the collection's drawn-icon pipeline. `prepare_garvey_art.py` creates 41 legacy mipmapped DDS textures. The collection icon finisher adds standard gold rims and leader padding. Normal Pikeman 3D assets remain inherited.

Source contracts use the collection's pinned official [CP v151 revision](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). See Validation.json for exact checked contracts and hashes. These checks do not substitute for native game acceptance.
