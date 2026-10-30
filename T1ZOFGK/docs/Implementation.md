# Implementation

## Database and native rules

`SQL/00` clones America/Washington identity rows and the active Warrior/Barracks with `SELECT *` into uniquely named temporary tables. Only identity, text, art and human/AI flags change. `SQL/01` clones every supported `Unit_*`/`Building_*` companion table plus free-start and leader personality rows. It deliberately excludes Washington's trait and all other leader companion effects. New SQL loads after the complete released collection, preserving earlier IDs.

`SQL/02` uses CP v151's real fields: `CityAttack=15`, `VisibilityChange=1`, `UnitPromotions_Features.DoubleMove=1` for Forest/Jungle, `AttackWoundedMod=15` and `ExperiencePercent=15`. These are engine combat/movement rules. Wounded attacks check defender damage before combat, including ranged attacks after an applicable upgrade; defense and city attacks do not use the wounded-unit modifier.

Headquarters retain Barracks companion rows, including reverse references in `Unit_ProductionModifierBuildings`. Culture is incremented by one. The real CP `Unit_ProductionModifierBuildings` table adds ten percentage points to each qualifying land military unit definition: positive combat strength, no ranged strength and no free OnlyDefensive promotion. `CvUnitEntry` loads that table; `CvCity::getProductionModifier(UnitTypes)` checks the building in the actual training city and reads the per-unit modifier. This supports mixed and custom combat classes without speeding their ranged members. No Lua yields, production banking or queue manipulation occurs. Validation checks every unit and includes changed Barracks baseline, modded melee, mixed-class ranged and defensive-only fixtures.

## Permanent state and native conversion order

Native `PROMOTION_T1Z_SCOUTED` proves Recruit origin. One exclusive `PROMOTION_T1Z_DEVELOPMENT_n` stores the genuine upgrade count and effective `CombatPercent=4*n`; no base strength is edited. All permanent role/development promotions have `LostWithUpgrade=0` and cannot be chosen normally.

144 finite cumulative tiers cover the active acyclic Recruit upgrade graph, whose longest path is seven upgrades. Validation resolves class defaults and T1 overrides, rejects cycles and checks the bound. Simulations also exercise 18 upgrades. The engine receives only one cumulative tier per unit, not a growing collection of identical +4% promotions. A ruleset exceeding the audited bound fails explicitly rather than silently capping at 28%.

`GameEvents.UnitConverted(oldOwner,newOwner,oldID,newID,bIsUpgrade)` runs after promotion/original-owner copying and before the source is killed. This is the authoritative upgrade completion hook. A true upgrade with different unit types adds one tier to the destination. A destination receipt rejects duplicate callbacks. `UnitUpgraded` is not used to award strength because CP emits it before `convert()` copies promotions. Promotion level-ups have no development handler.

Unit ScriptData `[T1Z1_ID=owner.serial]` is a lifetime token, transferred explicitly at conversion. The native unit ID is only a current lookup. The source role is stripped before native prekill; the destination receives the same token and role, so an upgrade cannot start a false vacancy. Source death callbacks are then harmless. Transfers to another player vacate the role and strip it from the recipient. A returned gift cannot recruit again.

Player ScriptData keys store `SEQ`, creation order `BIRTHSEQ`, five slots `S1` to `S5`, one-time ready notices and capture-site receipts. A slot is `N` (never filled), `L:token` (living holder) or `V:readyTurn` (vacant). The ready turn is `deathTurn + round(10*TrainPercent/100)`: 7/10/15/30 for the four standard speeds. The original roster and later successors share those slot contracts. Unit `DONE` receipts make training/creation idempotent; new unit objects cannot borrow another unit's receipt merely by reusing its ID.

All writes preserve unrelated ScriptData. Lua globals hold derived caches only. On context recreation, old handlers are removed; on load, slots and promotions rebuild the cache. No repeating timer or frame callback exists.

## Birth and acquisition safety

`UnitCreated` also fires during upgrades/captures before native identity is final. It queues an ordered pending birth without assigning a role. `CityTrained(player,city,unit,bGold,bFaith)` proves a local birth after initialization: it can fill an initial slot for a Recruit, and only actual production in a real owned Headquarters can fill a ready replacement vacancy. Earlier pending births settle first to preserve creation order. Starting replacements are recognized during initialization; other native free births settle at an owner turn boundary.

Direct native capture recreation does not emit `UnitConverted` or provide a destination ID. OriginalOwner alone cannot distinguish a recaptured originally local Recruit. `UnitCaptured` therefore records exact capture coordinates and turn in the acquiring player's save data. Unproven births at that site/turn are quarantined from the initial roster; genuine CityTrained proof clears the quarantine. This deliberately avoids taking ownership of ScenarioData, which existing civ controllers also use.

The conservative guard can also exclude a scripted free Recruit created at exactly that capture site on that turn. This is a documented safety limitation, not an unconditional role transfer. Ordinary native training/purchases and free births elsewhere retain the requested behavior. Capture/gift events never fill replacement vacancies.

## Temporary formation, pressure and support

The controller retains at most five registered units per T1 player. A turn/lifecycle reconciliation accepts only the living unit matching each saved token and removes duplicate/corrupt roles. Formation checks compare those units directly using ordinary `Map.PlotDistance`; normal troops cannot count, a unit cannot count twice and the two Strength tiers are mutually exclusive.

Faker's native reverse-General field has same-domain and embarked-source restrictions in v151. The requested cross-domain military aura instead uses a single temporary `CombatPercent=-10` recipient promotion. It updates on source/recipient movement, creation, conversion, death, peace/war, initialization and owner boundaries. A notified war/peace pair temporarily overrides the asymmetric native team relationship during `WarStateChanged`, which fires after only one side is updated. Only truly hostile military units, including barbarians at war, qualify.

Keria's recipient promotion adds `FriendlyHealChange`, `NeutralHealChange` and `EnemyHealChange` of five. It never calls ChangeDamage. `CvUnit::ActualHealRate` invokes those territory bonuses only after native `canHeal`: movement, embarkation, blockade and other normal restrictions remain effective, and native damage clamping enforces maximum HP. This is additive to ordinary Medic healing, avoids native adjacent-Medic same-domain/max-medic limitations, and excludes Keria/civilians. Multiple Kerias use the same boolean recipient promotion and cannot stack.

On roster-source changes, only units within one hex of aura sources and previously affected recipients are revisited. Ordinary foreign movement evaluates only that unit against the small roster cache. Only T1 armies are enumerated at owner lifecycle boundaries. One load-time global scrub clears stale saved temporary effects before reconstruction. There are no map-wide frame scans.

## UI, art and isolation

`UI/T1Z_Roster.xml` is the sole simulation-owning addin; its Lua includes the controller and the collection's existing screen-recovery helper. A right-side launcher and scrollable summary show living units, development, formation and cooldowns. Native notifications report membership changes and readiness. No shared CityView is replaced.

SQL, Lua, atlases, text keys and ScriptData use T1Z namespaces. The collection retains its UUID and older save contracts; new T1 identifiers are appended. Metadata version 19 registers every file with correct VFS flags, and the ZIP/7z release inventory includes all 49 DDS assets. Asset construction and provenance are in `art-source/T1ZOFGK`.

Pinned source: [Community Patch v151, 44c1e14](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). Exact file hashes and static contract checks are recorded in [Validation.json](Validation.json). Native engine acceptance is still pending.
