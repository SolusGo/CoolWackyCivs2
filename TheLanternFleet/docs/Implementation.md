# Implementation and engine evidence

## Database compatibility

The five SQL actions append after all released SQL. Existing Type identities, ID insertion order, collection UUID and save compatibility version are retained. Selection is human-only, but the controller does not test `IsHuman()`. The trait is empty: Washington's abilities are not inherited. Only ordinary free-start civilization relationships and the three supported leader personality tables are copied. Maren favors naval defense, Science and Culture; these are AI preferences, not victory modifiers.

The generator reads the installed v151 schema. Shipped SQL uses temporary `SELECT *` tables at **activation**, so active Trireme/Lighthouse properties, including future compatible scalar columns, are copied rather than freezing the fixture's vanilla values. It copies every available Unit*/Building* companion table with the owning UnitType/BuildingType column, including normal promotions, upgrade classes, resource requirements, flavors, sea-resource yields, prerequisites and CP extension tables. The ordinary Trireme model and Lighthouse appearance are retained. No original unit or building row is updated.

The local fixture is a read-only BNW snapshot with v151 schema overlaid in memory, **not proof of a live activated CP economy**. An altered-baseline test changes Combat/Movement/Cost, adds unknown scalar columns and resource requirements, and supplies preexisting Lighthouse Culture to verify active inheritance and exactly +1 additive Culture. No baseline Lighthouse bonuses are copied twice.

`PROMOTION_LANTERN_FRIENDLY_WATERS` sets VisibilityChange=1 and FriendlyLandsModifier=15, CannotBeChosen=1, LostWithUpgrade=0. Only the Cutter receives it. Ordinary promotion retention therefore keeps this training on upgrades; other inherited promotions retain their own normal rules. There is no generic CombatPercent or outside-friendly modifier.

At pinned CP commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`, CvPromotionClasses.cpp reads those actual columns. CvUnit.cpp's `GetMaxAttackStrength` and `GetMaxDefenseStrength` both call `GetGenericMeleeStrengthModifier`, which adds `getFriendlyLandsModifier()` only when the battle plot passes `IsFriendlyTerritory(owner)`. For an attack the battle plot is the destination; for defense it is the defending plot. The ranged path also honors the native field if retained on a later ranged upgrade. CvPlot.cpp defines friendly territory as own/team land, major territory granting open borders, and eligible city-state open borders. Unowned/enemy territory receives no Lantern Strength. This is native friendly territory, not an invented own-territory-only check. Native combat displays and upgrades still require acceptance testing.

## Qualification and state

One invisible InGameUIAddin XML owns all gameplay subscriptions. A MapModData context guard prevents duplicate registration and retires old contexts; globals do not hold economic state. There are no movement, dirty-event, frame, load-screen or construction subscriptions in the controller.

`city:IsCoastal(-1)` calls native `CvCity::isCoastal`, which forwards to `plot()->isCoastalLand(iMinWaterSize)`. Its default -1 uses the engine's ordinary ocean-size threshold. Only `city:Plot():GetUnit(index)` is inspected. A ship must match the actual city owner, have DOMAIN_SEA, pass IsCombatUnit, and be non-embarked, living and not delayed-death. All city decisions (including Lighthouse presence) are frozen before any dummy writes.

`BUILDING_LANTERN_GUARDED_HARBOR` supplies exactly Science 2/Culture 1; `BUILDING_LANTERN_SIGNAL_GOLD` supplies exactly Gold 2. Each has a separate ordinary building class, IsDummy=1, ShowInPedia=0, GreatWorkCount=-1, Cost/FaithCost=-1, NeverCapture=1, ConquestProb=0 and zero maintenance/other effects. The setter assigns real counts **0 or 1**, never increments.

Player ScriptData contains only `[LANTERN1|gameTurn]`, preserving unrelated data. This receipt suppresses duplicate turn notifications, reentrancy and load callbacks; it contains no yields or city qualification. Saved native real-building counts remain authoritative. Context initialization never scans units or changes buildings; an active Lantern player missing a receipt is stamped to prevent a mid-turn installation from manufacturing a snapshot. Inactive players are not prematurely stamped. Foreign players receive no ScriptData changes. Both buildings are cleared in CityCaptureComplete using a freshly reacquired plot city regardless of recipient; no captured snapshot is recomputed.

## Turn timing: verified publication, unverified executable dispatch

The selected candidate is **Events.AIProcessingStartedForPlayer**, restricted to untagged turn-start status and an active actual Lantern owner, once per saved game-turn receipt. There is deliberately no PlayerDoTurn fallback and no direct yield payout.

Verified in the pinned [CvPlayer.cpp source](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlayer.cpp):

1. `setTurnActive(true)` sets native turn-active state, then publishes `DLLUI->PublishPlayerTurnStatus(TURN_START, GetID())` (line 33986), before the call to `doTurn()` (line 34023).
2. `doTurn()` reaches `doTurnPostDiplomacy()` (diplomacy can defer this continuation).
3. That continuation runs city `doTurn()` (10434), Treasury DoGold (10440), Culture accumulation (10457), `doResearch()` (10497), then PlayerDoTurn (10571).
4. The installed Firaxis `Assets/UI/InGame/TurnProcessing.lua` listens to `Events.AIProcessingStartedForPlayer(iPlayerID, szTag)` and explicitly filters out human players itself. This establishes the event's API, but does **not** prove the executable maps TURN_START to that event synchronously for human players.

The executable's UI publication/dispatch implementation is outside the available DLL source. **Neither a mock nor these source lines prove same-turn payout.** Civ V is installed, but a launch attempt through the computer-use skill returned `Computer Use was not approved to use civilizationv_dx11`. No permission bypass was attempted. No native game or economic timing test passed. The selected event's mapping, delivery before economic calculations, human and scenario-AI coverage, and load/reactivation behavior remain required integration acceptance gates. This limitation is exposed in the README and collection status; do not describe this as a fully verified working timing implementation.

If acceptance shows delayed dispatch or no human notification, this candidate is unsuitable. Do not switch to PlayerDoTurn or owner-end staging, both of which violate the requested turn-start semantics. Find a genuinely earlier available hook or report that the exact mechanic needs an engine hook beyond CP151's exposed simulation events. No DLL modification is included.

## Art

Five original built-in imagegen paintings and saved prompts are in `art-source/TheLanternFleet`. The deterministic compiler produces 40 legacy DXT5 DDS textures with complete mip chains: navy/gold civ and leader atlases, object atlases, alpha symbols, unit flag, 1600x900 static leader, 1024x768 Dawn and harbor map illustration. Atlas sizes match the collection (16/24/32/45/48/64/80/128/256), with the same gold framing and portrait padding. There are no missing referenced assets. Static fallback diplomacy, ordinary 3D unit/building models and no voiced dialogue are intentional.
