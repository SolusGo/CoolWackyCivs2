# Community Patch v151 source audit

Audited on 2026-10-12 against official commit **44c1e14ff75d80c1dba5c8a71e8289439a53aafb**. [CustomMods.h](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CustomMods.h) declares DLL version 151. `python tools/audit_cp.py --fetch` downloads these pinned sources; rerunning without `--fetch` uses the local copies. [SourceAudit.json](SourceAudit.json) records official URLs, SHA-256 hashes and **129 passed assertions**, including registered City/Player/Plot/Unit/Team methods used by the runtime. This proves source availability/ABI, not launched-game compatibility.

## Citizen management

The decisive source is [CvCityCitizens.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvCityCitizens.cpp).

| Investigation | Source finding and implementation decision |
| --- | --- |
| Default labourers | Real population, with normal consumption. `GetTotalSpecialistCount` excludes defaults; census counts them separately. |
| Local withdrawal | `DoAlterWorkingPlot` unworks a native tile and adds one forced default. Lua verifies both transitions before recording a withdrawal. |
| Governor | Initial assignment clears unforced defaults and fills local/building jobs. Existing defaults alone are not proof of durable reservations. A lower bound is population minus all owned native local positions and static specialist slots in present buildings. Existing real defaults cap this bound. Forced withdrawals and surplus overlap: use their maximum, not their sum. |
| Forced defaults | No registered Lua setter/getter for their count. End-turn reservations are renewed; invisible forced-count resets and native event order remain live test cases. |
| Unassigned citizens | Inferred from population/automatons minus native workers/defaults/specialists. No credits until a genuine default or verified withdrawal exists. `TASK_ADD_SPECIALIST` with building -1 enters an inconsistent precondition and can consume nonexistent unassigned citizens; it is not used. |
| Buildings | Specialist allowance is static and also capped by `MAX_SPECIALISTS_FROM_BUILDING`. Repeated copies do not provide unlimited slots. No hidden-city or generated-building reservoir is used. |
| Automatons | Negative values violate native assertions. Positive external automatons make real-human attribution uncertain, so remote credits are disabled. |
| Eligibility | Native `IsCanWorkWithOverride` checks owner, city, `hasYield`, water-working ability and blockade; it does not ban all mountains. The remote system mirrors these available checks and permits yielding mountain wonders, without claiming native effective-owner/worked status. |

## Yield and task bindings

See [CvLuaCity.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaCity.cpp) and [CvCity.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvCity.cpp).

- `DoTask(task, data1, data2, option)` reads option with **luaL_optint**. All calls use numeric 0, including reservation release and quarantine queue/automation controls. A Lua boolean would raise a native argument error.
- `GetSpecialistYield(default, yield)` combines player extras with city extras inconsistently and cannot simply be multiplied by remote count. `GetExtraSpecialistYieldOfType(yield, specialist)` returns the total, count-multiplied extras. Correct per-labourer yield is the database base plus this total divided by actual default count; it includes specific policy/trait/event/religious extras and excludes generic boosts that do not apply to labourers.
- Gross remote yields use `ChangeBaseYieldRateFromTerrain`; negative labourer compensation uses `ChangeBaseYieldRateFromMisc`. Ordinary modifiers apply natively once. The terrain-Culture source participates in native landmark/improvement Culture-to-Tourism conversion; worked-only Tourism remains unsupported.
- The terrain setter only changes its source and marks the city screen dirty. It **does not** refresh static yield caches. The misc setter refreshes the corresponding cache only for nonzero deltas. Terrain is applied first, then compensation or a journalled +1/-1 misc pulse refreshes the six supported rates. The final pulse contribution is zero. Tourism caches refresh through subsequent native all-yield updates; immediate same-frame Tourism refresh is not certified.
- `Plot:GetYield` reads the native evaluated value. [CvPlot.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlot.cpp) includes ordinary Golden Age additions. The mod adds no Golden Age multiplier. Conditional effects requiring native working remain outside this method, and remote plot recalculation timing needs live tests.
- Misc supports negative contributions; terrain credits are nonnegative ordinary yields. The BCY2 ledger records only this mod's adjustments, preserving unrelated sources. Plot and Player ScriptData are exposed; **City ScriptData is absent**. No executable saved payload is evaluated.

## Cities and military resolution

[CvPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlayer.cpp) continues using `pNewCity` after `CityCaptureComplete`. `AcquireCity` deletes/recreates city objects. The callback only retires old plot-ledger markers, records state and queues work; it never acquires, razes or destroys a city.

`Player:CanRaze(city, false)` requires that player to own the city and rejects cities originally founded by that player. Calling it as Boundless on an enemy city is invalid; calling it as the current owner usually rejects first-founded enemy towns. Restricted siege demolition uses the **current owner's** real check, plus hard capital/holy/city-state exclusions. Native `Disband` does not enforce legality itself, so every invocation is gated immediately beforehand. It destroys through native `city.kill` and associated cleanup. This is an immediate demolition action, not capture or gradual razing; ordinary occupation remains blocked by NoCapture.

`GetPlayerToLiberate` and `CanLiberatePlayer` identify justified recipients, but this implementation transfers only to living eligible recipients. It does not resurrect eliminated civilizations. Historical previous/original living owners precede native liberation candidates. A missing recipient means native-legal removal or protected quarantine, never assignment to an arbitrary living civilization.

The final pass rechecked the distinction between native interface restrictions and game-rule protection. Ownership/current-owner founding checks run **before** native CanRaze script vetoes and luxury/capital/holy checks. Mirroring only the later visible rules would not invoke every native/mod veto. `Disband` is a destruction primitive, not an independent legality predicate. No verified safe ownership-independent replacement was found, so general demolition remains restricted.

`City:IsRevealed(team, false)` is exposed and filters siege rows without revealing undiscovered settlements. `GetResistanceTurns`/`ChangeResistanceTurns` are also registered. Native city yield calculation returns zero while resisting; normal purchase-cost legality rejects resistance. `DoResistanceTurn` decrements before production, so quarantine maintains two turns and refreshes the six cached rates. Native acquisition reconstructs a fresh city and does not copy the old resistance timer; no ownership/raze rule is altered. Empire resources, buildings and other infrastructure are not comprehensively disabled by resistance.

Return-loop records now include an optional game-turn stamp. A same-turn repeat is blocked, while legitimate later returns can proceed. A living Boundless recipient is eligible only with zero cities and a matching saved original-capital coordinate/founding identity. This uses the same native trade acquisition outside callbacks; no resurrection or substitute-capital identification is inferred.

The `CanMoveInto` event is per-unit opt-in (`SendCanMoveIntoEvent`), and movement has fallback logic outside a universal acquisition veto. No safe universal pre-acquisition hook was found. NoCapture is retained for normal enemy-city entry, including original-capital military recapture.

## Events, AI and registration

| Hook/API | Confirmed ABI / behavior |
| --- | --- |
| `PlayerBuilt` | player, unit, x, y, build; improvement rewards validate Surveyor and completed improvement, exclude repair/route and persist reward bit first |
| `UnitConverted` | old player, new player, old unit, new unit, upgrade flag; promotion ownership corrected |
| `TileOwnershipChanged` | x, y, new owner, old owner |
| `TileImprovementChanged` | x, y, owner, old improvement, new improvement, pillaged; first three arguments sufficient for invalidation |
| `PlayerDoneTurn` | player; always renews native reservations |
| `DeclareWar`, `MakePeace` | CP player/team/bool, or vanilla team/team depending on event option; handler ignores positional interpretation and invalidates Boundless states. Peace reconciliation is deferred to observe final war state. |
| `PlayerDoTurn` | After native city processing; never used to claim an instant award is a native per-turn source |
| Native city vetoes | Founding/training/constructing plus CityCanCreate and CityCanMaintain; unrelated players pass through |
| `Plot:SetOwner` | player, city ID, check units; no binding distance cap; frontier checks unowned adjacency first |
| `Unit:GeneratePath` | plot, maximum turns; returns native path table and does no caching. Planner caps calls rather than imposing a distance limit. |
| `CanBuild` / `PushMission` | Actual native legality and movement/build commands with numeric optional flags; no teleport or imaginary order API |

The SQL enables CP hook options without changing native civilization rules. Namespaces, VFS basenames, one UI addin, SQL order, project imports, localization and all 34 DDS references are validated. Coexistence checks compare the separate original collection read-only. Gameplay coexistence remains untested.
