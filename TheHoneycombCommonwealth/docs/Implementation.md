# Implementation and delivery report

**Corrective audit:** [CorrectiveAudit.md](CorrectiveAudit.md) supersedes the original fault-handling assessment. Rules, SQL identities, dialogue and art are unchanged. [NativeAcceptance.md](NativeAcceptance.md) specifies controlled setup and actual economic-payout checks.

## Files and integration

Created five SQL files (`00_HCC_Core`, `01_HCC_Inheritance`, `02_HCC_Effects`, `03_HCC_Art`, `10_HCC_Text`), `Lua/HCC_Commonwealth.lua` and its XML entry, `Art/HCC_LeaderScene.xml` and 40 DDS textures, README/changelog and these implementation/testing/source-audit records. Added `tools/generate_honeycomb.py`, `prepare_honeycomb_art.py`, `validate_honeycomb.py`, `tools/tests/honeycomb_assertions.lua`, the civilization reference page, original artwork/prompts under `art-source/TheHoneycombCommonwealth` and three retained masters under `art-source/IconAtlasMasters`.

Modified the collection README/changelog, builder inventory, validation dispatcher, existing modinfo and existing project's file/action/entry lists. No new ModBuddy project or packaged release is generated. Five SQL files append after all released content, preserving prior database IDs and load order. SQL and the entry XML are outside the VFS; Lua, leader scene and textures are imported. Existing BNW/CP dependency identities and version constraints remain intact.

## Database and replacements

All identifiers use HCC. The civilization is human-only, with 24 themed city names, ten spies, Civilopedia sections, strategy, exact requested Dawn text and exact greeting/war/defeat dialogue. Standard civilization free-unit/technology/building rows provide an ordinary start. Only native leader personality tables are inherited; Washington's primary/shared abilities and unknown gameplay extensions are excluded. The UA trait itself has no native side effects.

At activation SQL temporary tables use `SELECT *` on **active** `UNIT_SCOUT` and `BUILDING_MARKET`, changing only new identities, art/help and specified differences. Schema-derived companion SQL copies every available `Unit_*`/`Building_*` table with its owner column, including empty tables that may gain dependency rows. This preserves requirements, AI roles/flavors, terrain flags, upgrade/ruin behavior, Market yields/modifiers, specialists, trade and prerequisites. Scout/Market class identities preserve ordinary class-based policy/technology interactions. Optional tables come from the already-existing collection Shared schema; no unrelated civ is referenced.

The inspected installed BNW backup plus CP v151 schema yields Scout Combat 5, Moves 2, BaseSightRange 2, reconnaissance class and IgnoreTerrainCost; Market Cost 100, Currency, one Merchant, +1 Gold, +25% Gold and both trade bonuses at 1. Installed CP-only files contain no Scout/Market balance override. The backup is **not an already-activated CP cache**: the repository adapter reconstructs CP schema read-only in memory. Shipped SQL deliberately derives active records again in-game. Altered-baseline tests verify this rather than assuming fixed values.

Forager uses Moves=baseline+1. Its unique promotion has VisibilityChange=1, CannotBeChosen=1 and LostWithUpgrade=1, no Movement/combat modifiers, no unit-combat eligibility, and is granted only to Forager. Honey Exchange retains Market class and adds one Food in `Building_YieldChanges`. Its conditional Gold uses separate dummies. The unit's ordinary Scout model remains unchanged.

## Plantation count and dummies

One pass walks each city's native citizen plot list (`GetNumCityPlots` → `GetNumWorkablePlots`, `GetCityIndexPlot` → `GetCityPlotFromIndex`), excluding center/nil plots. It requires actual Plantation improvement, owner match, unpillaged state, distance ≤3, `city:IsWorkingPlot(plot)` and matching owner/city ID from `plot:GetWorkingCity()`. CP implements the latter as effective owning city including overrides, so the citizen check is also essential. A plot-index set prevents duplicate counting. Unfinished, idle, foreign and another city's plantations fail qualification.

Every city count is taken before any dummy setter. Counts drive `min(4,n)` Production, `n>=2 and 1 or 0` Culture and, with an Exchange only, `min(2,floor(n/2))` Gold. Four distinct `BUILDING_HCC_PRODUCTION_1`–`_4`, one `BUILDING_HCC_CULTURE` and two `BUILDING_HCC_GOLD_1`/`_2` grant one native yield each. Each has its own ordinary class, Cost/FaithCost -1, IsDummy=1, ShowInPedia=0, GreatWorkCount=-1, zero maintenance/specialists/happiness, no tech prerequisite, NeverCapture=1 and ConquestProb=0. No wonder limits. Native dummy handling and the setter's no-bonus flag suppress construction rewards. Setters compare actual real-building counts; only mismatches change and no multiple copies are stacked.

## Timing evidence and unavoidable difference

Pinned official CP DLL v151 commit: [`44c1e14ff75d80c1dba5c8a71e8289439a53aafb`](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). [SourceAudit.json](SourceAudit.json) records direct source URLs, local SHA-256 hashes and executable contracts.

`CvPlayer::doTurnPostDiplomacy` runs city `doTurn()`, treasury `DoGold()` and Culture accumulation before `PlayerDoTurn`. `setTurnActive(true)` calls economics before `ActivePlayerTurnStart`; `AI_doTurnPre` has no script hook. The earlier `PublishPlayerTurnStatus(TURN_START)` is an engine/UI publication; available DLL source does not establish a synchronous Lua callback before economics, so it is not assumed safe for yield settlement.

Verified synchronous `GameEvents.PlayerDoneTurn(owner)` fires in `setTurnActive(false)`, gated by `EVENTS_PLAYER_TURN`, before unit reset/deactivation completes. HCC stages the next payout there, following existing timed collection systems. `PlayerDoTurn` only clears invalid markers and never recounts or grants late economic credits. There are no direct treasury/Production grants or cumulative yield counters.

**Test N proves source ordering and a simulated staged payout; it does not prove literal start-of-owner-turn sampling or observed native payout.** Interturn changes can differ from the requested exact snapshot until the next end-turn boundary. Staged rates may be visible while inactive. First-turn settlements wait for their first end-turn staging. City transfer and Exchange removal deliberately clear invalid effects immediately. No speculative callback, polling or DLL modification conceals this limitation.

## Save, ownership and faults

Actual dummy buildings remain the applied saved yield state. Completed snapshots with only the legacy `[HCC1:rawTurn]` receipt are untouched on load. Unfinished synchronization now has a temporary `[HCCP2:...]` journal of city identity and seven binary targets, persisted before the first setter and removed after verified completion. Load-completion/gameplay recovery replays only those targets; it never recounts changed assignments or stores accumulating yield totals. Other ScriptData is preserved.

`Game.IsFinalInitialized()` is serialized by CP and alone cannot prove all cities are restored. A fresh context therefore ignores UI dirty notifications until a load/init completion or a verified gameplay event establishes readiness. Context recreation preserves ordinary applied snapshots.

Context identity guards prevent duplicate registration. Recreated/shutdown contexts retire callbacks, and retained callbacks check ownership. Primitive-argument jobs coalesce reentrant notifications; observed Exchange loss remains revoked across a rebuild. The queue drains ordinary large batches with a 4,096-job pathological ceiling. Counts and Exchange eligibility are both frozen before setters. Every changed setter is read back through a newly resolved city; each city gets one retry, and a failed city does not block healthy cities. No city userdata survives mutation boundaries. Persistent storage/setter failures remain diagnosed and cannot guarantee repair before payout or retroactively recover a missed payout.

Native nine-argument `CityCaptureComplete` follows city reconstruction. HCC reacquires x/y and clears all seven markers even for HCC→HCC gifts. Founding clears only the new city. NeverCapture also prevents ordinary native capture retention. CitySoldBuilding fires **after** DoSellBuilding, so missing-Exchange Gold clears synchronously. SpecificCityInfoDirty covers notified scripted removals without recounting; rebuilding does not restore Gold before a snapshot. Every processed owner's turn defensively clears only HCC markers from foreign cities or missing-Exchange Gold.

Destroyed/transferred/reused city identities cannot receive a replayed target. An external script that removes the Exchange without observable absence relies on the defensive next owner-turn pass; silent/coalesced remove-and-rebuild cannot be guaranteed detected without polling/DLL support. Pure CP's zero-maintenance Market and Exchange are not manually sellable under native rules; sale hooks remain defensive without adding maintenance. Collection multiplayer/hotseat flags remain disabled, though handlers always use the actual owner.

## Validation and art

[Testing.md](Testing.md) distinguishes SQL/Lua/source validation from outstanding native acceptance. Original generated artwork covers bee, leader, Forager, Exchange, Dawn and diplomacy. Technical crops/resizes, collection gold-rim finishing and legacy RGBA DDS/mipmap exports follow existing conventions. Code-native alpha/flag and hive map are supplied. The static diplomacy painting and Scout 3D model are supported fallbacks; no animated leader, bee model, voice or music is supplied. No art references are missing.
