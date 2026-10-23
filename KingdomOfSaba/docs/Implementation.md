# Saba implementation

## Identity and integration

SQL loads in numeric order: core identity/replacements; companion inheritance; promotion and city yields; atlases; English text. `tools/generate_saba.py` derives statements from the installed BNW/CP schema. Saba is appended after every released civilization by `tools/build_mod.py`; version 11 keeps the collection UUID and minimum save version 1. Existing numeric IDs and persistence formats are preserved. No peer mechanics or artwork are edited.

Saba inherits Arabia's regional art identity and normal starting units, technologies and buildings, without its trait or uniques. Leader flavor/approach data is copied to a distinct leader; Science/Culture/Growth flavors are local to that identity. City names include the Sabaean heartland and wider ancient South Arabian region over time; their sequence does not claim every place was founded or ruled by Karib'il Watar. Spy names and dialogue are original historical interpretations.

## City yields

`BUILDING_SABA_RIVER` supplies +1 Food/+1 Production through verified `Building_YieldChanges`. `BUILDING_SABA_DESERT` supplies +1 Culture through the same native table. Both have unique classes, Cost/FaithCost -1, GreatWorkCount -1, IsDummy 1, ShowInPedia 0, NeverCapture 1, ConquestProb 0, NukeImmune 1 and zero maintenance. These are flat **base city yields**, subject to normal city modifiers/resistance, rather than percentage bonuses or altered plot yields. CP's native `IsBuildingSellable` rejects zero-maintenance buildings, preventing dummy sales.

One invisible `InGameUIAddin` context, `Lua/SABA_Cities.xml`, automatically loads its same-name Lua file. It adds no UI. Functions are local, with a namespaced `MapModData.SABA_CitiesLoaded` registration guard. The controller reads the current owner, `city:Plot():IsRiver()` and `GetTerrainType()==TERRAIN_DESERT`. Hills retain their underlying Desert type. Each dummy is set to exactly zero or one only when its existing real-building count differs.

Initialization and context creation after load reconcile all players' city lists once. `PlayerCityFounded` reconciles the new city. `CityCaptureComplete` reads the current city at the event coordinates after native `acquireCity` reconstruction. CP emits this event for conquest and nonconquest acquisition; `DoLiberatePlayer` uses `acquireCity` too. NeverCapture rejects those buildings before peaceful and conquest transfers, and the Lua hook independently removes stale markers from foreign owners. `PlayerDoTurn` repairs the relevant player's cities as a missed-event fallback. Optional CP `CityRazed` safely reconciles a still-existing city or no-ops on an empty plot. Destruction needs no registry cleanup because no city objects/IDs are retained.

Save state is only native building counts and existing city/plot data. There is no OpenSaveData, timer, turn counter, per-frame work, map enumeration or terrain transformation. Acquired/returned cities are recalculated. Founding-time terrain/river history is not separately stored; standard Civ V keeps those properties stable. A terrain-changing mod would cause the next reconciliation to use the changed actual plot. Native old-save continuation remains unverified.

## Wadi Sentinel

The active `UNIT_SPEARMAN` row is cloned with `SELECT *` at activation, retaining every scalar field including CP additions. Every schema-known `Unit_*` companion with `UnitType` is cloned, including upgrades, free promotions, resources and flavors. Only identity/help/icon fields differ. `Unit_FreePromotions` adds one `PROMOTION_SABA_WADI_GUARD`, with `VisibilityChange=1`, `CannotBeChosen=1` and `LostWithUpgrade=1`.

The task requested investigation of `UnitPromotions_Terrain` (singular). The installed schema has **no such table**. The old `UnitPromotions_Terrains` (plural) exists, but its Defense applies only without features. Installed CP's `NewPromotionTables.xml` and pinned DLL source instead verify **`UnitPromotions_TerrainModifiers`** (`PromotionType`, `TerrainType`, `Attack`, `Defense`). Saba inserts Desert/Attack 0/Defense 15 only there. Native `GetMaxDefenseStrength` reads underlying terrain separately from the feature branch and also handles hills. `GetMaxAttackStrength` does not consume this defense value. Desert cities, Flood Plains and Oasis therefore retain the intended bonus without unconditional defense or adjacent-Desert checks. No Lua unit events are used. Spearman model/animations are inherited.

The development database adapter now loads schema-defined `UnitPromotions_*` tables in its in-memory test database. It creates no custom gameplay table in the shipped mod. [SourceAudit.json](SourceAudit.json) records source commit, hashes and contracts; source inspection is not gameplay testing.

## Ma'rib Cistern

The active `BUILDING_WATERMILL` row and every schema-known `Building_*` companion with `BuildingType` are cloned at activation. Costs, maintenance, technology, River restriction, specialists, modifiers and CP-specific fields stay intact. Food and Gold rows are incremented by one; if absent, a new one-yield row is added. The building retains `BUILDINGCLASS_WATERMILL`, with one Saba class override. Native construction selects the Cistern instead of offering two independent Water Mills. No Lua adds Cistern yields, so removal/transfer follow native building behavior without a separate ledger.

`Shared/SQL/00_OptionalCompatibility.sql` supplies an empty optional `Building_ConstructionAudio` metadata table when absent, as it already does for other cache-only metadata. Populated tables are untouched. Inherited SQL can load without requiring the unrelated mod that contributed that table to the development cache.

## Presentation and limits

Original built-in imagegen artwork supplies static diplomacy, loading and portrait crops. Original drawn water-gate emblem, spear/shield, cistern and schematic map use the existing icon/DDS pipeline. All nine standard atlas sizes, alpha atlas and unit flag are supplied; shared finishing adds gold rims/portrait padding and legacy DXT5 or RGBA encoding. Sources and exact prompt are retained. No custom 3D model, voice line or leader animation is claimed.

Historical context was checked against [UNESCO's Saba/Marib account](https://whc.unesco.org/en/list/1700/) and [The mukarrib and his beads](https://revistas.uam.es/isimu/article/download/3543/3767). Prose and art interpret the setting; the map is schematic and the dam scene combines the broader tradition of Sabaean irrigation.

Native yields, combat tooltips, rendering, transfers and save continuation require the [in-game checklist](Testing.md). Target: Windows BNW + CP v151 single player. Multiplayer, hotseat, Mac and unrelated DLL versions are unsupported. Mods altering Spearman/Water Mill **after** this collection loads cannot be inherited retroactively.
