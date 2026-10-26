# Threshold Transfer implementation

## Loading and ownership

`THC_Transfer.xml` is the civilization's single `InGameUIAddin`. Its same-basename UI Lua includes `THC_Core`, which includes the persistence and event modules. All simulation calls and UI validation therefore use one authoritative module in one context. There is no cross-context copy of the rules, networking surrogate or per-frame polling loop. Dirty events schedule one update callback that immediately detaches. Main-menu, city-screen, diplomacy, popup and turn-end contexts hide/close the interface.

The native selection is reacquired at confirmation. A snapshot contains owner/unit ID, creation turn and unit type, plus origin/destination plot-backed city identities. Selecting another unit, upgrading, destroying a unit, changing a city owner or replacing a city cannot silently redirect an old selection.

The collection builder appends all Threshold SQL **after** the previous fourteen civilizations, preserving their insertion order. Collection UUID is unchanged; version increases from 16 to 17. Only notification/veto options and `Units.SendCanMoveIntoEvent` opt-ins are changed on shared data; existing unit stats, civilization flags, traits and effects are preserved. The movement hook requires that per-unit-type opt-in in CP v151, so all land combat types opt in. Its veto returns true for every unmarked unit, including other civilizations.

## Eligibility and relocation

`T.Validate` is used by both the UI and `T.Transfer`. It checks active human owner, civilization, native unit validity, land domain, native combat and melee attack capability, non-ranged/non-embarked status, combat class, actual city-tile location, ownership, building, cooldown, saved empire limit, movement/busy state, treasury and destination legality. It excludes special units without a combat class and defensive-only units; positive Combat alone is insufficient. Both Hingeguard and ordinary eligible melee units qualify.

Destination validation requires a different owned city containing the building, checks every unit for military occupancy and hostile civilians, and calls `CanMoveOrAttackInto(plot, 0, 1)`. The fourth argument is an **integer** destination flag; the pinned CP binding does not use the third argument. It checks stacking/terrain without generating a route. Neither geographic distance nor continent enters the cost or validator.

After writing a prepared receipt, execution reacquires both cities and repeats identity/endpoint checks. It restricts the original unit and calls `unit:SetXY(x, y, 0, 1, 1, 0)`. CP's wrapper uses `luaL_optint` for these flags; passing Lua booleans would be wrong. The wrapper directly calls the same unit's native `setXY`, preserving its ID, health, XP, promotions, upgrade history and custom state. It never kills/spawns a substitute.

Execution reacquires the unit by ID and verifies creation turn/type, exact destination coordinates and non-embarked state. Only confirmed arrival records T+8, consumes this owner's turn and charges Gold. Errors before arrival restore the prepared unit's movement and remove only the mod's temporary restriction. An unexpected position is quarantined in the receipt without speculative payment or relocation to adjacent tiles. Expected invalid targets consume nothing.

## Save data and recovery

The implementation uses native **player, plot and unit ScriptData**, not a profile-wide database. Each object is serialized within the game save by the pinned engine. Numeric blocks are versioned, parsed without `loadstring`, range-checked and round-trip verified; other mods' text is retained. Each read uses current native objects rather than a transient state cache.

| Block | Content |
| --- | --- |
| Player `[THC_P1:...]` | Last successful turn plus one (zero means never), last owner-turn start, receipt phase and original unit identity, origin/destination coordinates, origin epoch, crossing turn, exact cost, pre-charge treasury, original unit type/movement and previous origin deadline. |
| City plot `[THC_C1:...]` | Monotonic per-plot generation, current owner, city ID, founding turn, original owner and ready deadline. |
| Unit `[THC_U1:...]` | Originating owner, crossing turn, creation turn and unit type. |

The city generation changes on founding and capture notifications. Owner/ID/founding/original-owner mismatches also reset it. A razed city leaves an inert plot record; a newly founded replacement gets a new generation even if the ID and founding turn are reused. Names never identify cities. Capturing and recapturing the same plot invalidates its old cooldown and UI token. Removing the Threshold House disables an endpoint immediately on revalidation without resetting an existing cooldown.

One transfer in flight per owner is enforced synchronously. A prepared receipt precedes relocation. A confirmed receipt stores the treasury immediately before payment. Recovery distinguishes an unchanged treasury from exactly one charged cost, so an exception after charging cannot charge twice. A unit still at the origin cancels the prepared receipt without cost/cooldown. Identity loss, an unexpected position or ambiguous treasury preserves the receipt and disables further actions for diagnosis; it does not guess an unrelated unit or apply a cooldown to a replacement city. Native C++ relocation cannot be made atomically transactional with several Lua ScriptData writes. The receipt is the defensive accommodation for that engine limitation.

The turn identifier is `Game.GetGameTurn()` in supported single player. Stored owner-turn start advances only on this player's turn, then releases all stamped units, including gifted units. A captured/gifted unit remains exhausted until the originating owner's next turn. No movement or attack count is granted by cleanup: native turn processing restores them. Valid saves do not reset empire use, city recharge or exhaustion when the UI closes or its context is rebuilt.

## Exhaustion

`FinishMoves()` removes movement; `SetMadeAttack(true)` records a used attack. CP's `isOutOfAttacks` explicitly lets Blitz bypass the attack count, so these setters alone do not suffice. `PROMOTION_THRESHOLD_EXHAUSTED` adds native `OnlyDefensive=1`, which prevents offensive melee eligibility while preserving normal defense. A scoped `CanMoveInto` veto rejects movement away from the unit's tile even after another ordinary mechanic restores movement. UnitSetXY re-exhausts an externally relocated marked unit. A native upgrade veto defers upgrades until recovery, and UnitConverted propagates the marker to conversions/gifts.

The temporary promotion survives gifting/upgrading until cleanup; no existing promotion is removed. On the next owner-turn only this promotion and marker are removed. The permanent Hingeguard `FriendlyLandsModifier=15` uses the native battle-plot check on both attack and defense. It remains on normal upgrades. `FriendlyLandsAttackModifier` is left zero to avoid doubling the bonus.

## CP inheritance and presentation

SQL uses temporary `SELECT *` clones of the **active** Pikeman and Market at activation, including extension columns. Companion copies are generated from the installed CP schema and cover every matching `Unit*`/`Building*` relationship. Resource requirements, upgrade targets, free promotions, costs, maintenance, specialists and economic behavior follow the dependency. Changes are +1 Hingeguard Movement, its +15% promotion, exactly +1 Threshold House Culture and presentation/override identifiers. An existing Market Culture row is incremented; an absent row is created.

Queen Elsewhere has a static original leader painting. The Hingeguard has an original portrait and native Pikeman model. Doorway heraldry/alpha icons, house icon, promotion badges and an illustrative network map use the existing collection compiler. Every atlas includes 16/24/32/45/48/64/80/128/256 sizes with mipmaps. Original art and exact imagegen prompts are retained in `art-source/TheThresholdCourt`.

## Files changed

New civilization files:

- `TheThresholdCourt/SQL/00_THC_Core.sql`, `01_THC_Inheritance.sql`, `02_THC_Effects.sql`, `03_THC_Art.sql`, `10_THC_Text.sql`.
- `TheThresholdCourt/Lua/THC_Core.lua`, `THC_State.lua`, `THC_Events.lua`.
- `TheThresholdCourt/UI/THC_Transfer.xml`, `THC_Transfer.lua`.
- `TheThresholdCourt/Art/THC_LeaderScene.xml`, `THC_Leader.dds`, `THC_Dawn.dds`, `THC_Map.dds`, and 45 atlas DDS files (`THC_Icon`, `Alpha`, `Portrait`, `Objects`, `Promotions` at nine sizes).
- `TheThresholdCourt/README.md`, `CHANGELOG.md`, `docs/Implementation.md`, `docs/Testing.md`, `docs/Validation.json`.
- `docs/civilizations/TheThresholdCourt.md`, `art-source/TheThresholdCourt/{QueenElsewhere.png,Hingeguard.png,Preview.png,README.md,Prompts.md}` and retained `art-source/IconAtlasMasters/THC_*` masters/metadata generated by standardization.
- `tools/generate_threshold.py`, `prepare_threshold_art.py`, `validate_threshold.py`, and `tools/tests/threshold_{mock,transfers,rejections,faults,ui,lifecycle}.lua`.

Modified integration files: root `README.md`, `CHANGELOG.md`, `CoolWackyCivs2.civ5proj`, `tools/build_mod.py`, `prepare_art.py`, `validate_mod.py`, `verify_release.py`, `validate_kingdom.py` and `validate_cats.py` (their all-collection regressions permit exactly the required notification opt-in while preserving every gameplay field); the version 16 manifest is replaced by `Cool Wacky Civs 2 (v 17).modinfo`. Ignored build outputs are the version 17 ZIP and genuine LZMA/7z `.civ5mod`.

No existing civilization's source or artwork is edited. Native runtime acceptance, real save testing and whole-game balance remain outstanding; the [testing record](Testing.md) separates those from executed checks.
