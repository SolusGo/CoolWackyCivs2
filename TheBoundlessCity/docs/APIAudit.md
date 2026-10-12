# Community Patch v151 API audit

The implementation was checked against the official [Community-Patch-DLL source](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2) on 2026-10-12. `CustomMods.h` identifies the DLL as **Community Patch v151**. The installed Community Patch database changes and a read-only BNW debug cache supply the schema used by the SQL generator and validator. This confirms source/API availability; it does not establish runtime correctness in a launched game.

## Accepted APIs

| API | Source / decision |
| --- | --- |
| `Plot:SetOwner(player, cityID, checkUnits)` | [CvLuaPlot.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaPlot.cpp): passes city ID to native ownership. No Lua distance restriction. Used only on validated unowned frontier tiles. |
| `Plot:GetYield(yieldID)` | Same binding: returns the evaluated native plot yield. No fabricated terrain/improvement yield tables. |
| `City:AlterWorkingPlot(cityPlotIndex)` | [CvLuaCity.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaCity.cpp) calls `DoAlterWorkingPlot`. Unworking a native tile creates one default specialist and one forced-default reservation. |
| `City:DoTask(TASK_REMOVE_SLACKER, 0, -1, false)` | [CvCity.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvCity.cpp) removes a default specialist and reallocates the citizen. Used to release owned reservations. |
| `GetSpecialistCount`, `GetTotalSpecialistCount`, `GetSpecialistYield` | Exposed city bindings. Native total specialists excludes default labourers. Default yields include player and city specialist-yield modifiers. |
| `City:ChangeBaseYieldRateFromMisc` | Native base source setter supports signed deltas and updates city yields. The ledger records only this mod's contribution; other miscellaneous yields are preserved. |
| `NoCapture` promotion | [CvUnit.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvUnit.cpp) prohibits enemy-city entry/capture. No override of a global unit or combat rule is needed. |
| `PlayerBuilt` | [CustomMods.h](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CustomMods.h): `(player, unit, x, y, build)`. Supports attributed improvement completion; repair Builds are excluded. |
| `TileOwnershipChanged`, `TileImprovementChanged`, population/tech/policy hooks | Event-driven invalidation; current owner-turn reconciliation remains the scheduled fallback. Enabled CP event options affect hook availability, while handlers remain civilization-scoped. |
| `Unit:CanBuild(plot, build, visible, testGold)` / `PushMission` / `IsBusy` | Verified [CvLuaUnit.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaUnit.cpp) bindings. AI missions use native legality/pathfinding and numeric optional flags. |
| Player/Plot ScriptData, `Modding.OpenSaveData` | Verified bindings provide native-save authority and a redundant mirror. The city's ledger is stored on its capital plot: City ScriptData methods are not exposed by this binding. No executable save content. |

## Rejected alternatives

**Increasing working radius** does not implement unbounded citizen assignment: [CvCityCitizens.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvCityCitizens.cpp) uses fixed native plot arrays/range checks. No global radius setting is changed.

**A single zero-yield specialist building** cannot provide arbitrary capacity. `GetNumSpecialistsAllowedByBuilding` returns the building's static SpecialistCount, and `IsCanAddSpecialistToBuilding` also imposes `MAX_SPECIALISTS_FROM_BUILDING`. Multiple copies do not multiply that returned slot count. No unverified capacity setter is assumed. Thousands of generated placeholder buildings would impose another artificial cap and excessive database/AI cost.

**Negative automatons** would reduce the effective worker pool, but `CvCity::setAutomatons` asserts that automatons remain nonnegative. That workaround is rejected.

**Adding default specialists through `TASK_ADD_SPECIALIST` with building -1** is not a safe reservation primitive when no unassigned citizen exists: it changes default and unassigned counts without first removing an occupied citizen. It would violate native accounting. Only verified transitions from actual worked plots are used.

**Razing or retransferring inside `CityCaptureComplete`** is unsafe. [CvPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlayer.cpp) continues dereferencing `pNewCity` after invoking that hook. Native `AcquireCity` deletes/recreates city objects. Military capture is blocked; exceptional city returns are deferred until the native stack unwinds. No `City:Kill` workaround or global conquest-rule change is used.

`PlayerDoTurn` runs after native city turn processing. The implementation therefore maintains ongoing yield rates through events, initializes them at load, and reconciles on `PlayerDoneTurn`; it does not pretend an after-turn instant grant behaves exactly like native tile yields. Exact native ordering remains on the game test checklist.
