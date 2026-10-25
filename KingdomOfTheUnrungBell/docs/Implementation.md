# Implementation and evidence

## Database and package

`tools/generate_unrung.py` uses the collection's schema-derived clone/companion helpers. SQL files load in numeric order, after all previously released civilizations. Core civilization/leader defaults come from America/Washington with all identity, art and text replaced; `Playable=1`, `AIPlayable=0`, no leader AI flavors. Ordinary starting free building classes/techs/units are inherited. Bellwarden overrides `UNITCLASS_PIKEMAN`; Silent Belfry overrides `BUILDINGCLASS_TEMPLE`.

Runtime temporary `SELECT *` scalar clones preserve all active columns; 176 installed Unit*/Building* companion tables are enumerated, even when empty. Pikeman art definitions, unit flag and strategic view are inherited unchanged. Only descriptive art/text differs. A new permanent promotion supplies Sight/territory strength; no scalar combat or movement changes occur. Belfry Culture is added to an existing Culture row, or inserted if absent, preserving baseline yields.

Six hidden buildings each supply exactly one Culture or Science. Each is binary and has its own nonconstructible class, Cost/FaithCost -1, no upkeep, `IsDummy=1`, `ShowInPedia=0`, `NeverCapture=1`, `ConquestProb=0`, `GreatWorkCount=-1`, and no prerequisites or defense/happiness. Native setters recalculate city yields and pass `bNoBonus=true`. Conditional Science checks the actual Belfry type via `GetNumBuilding`, including free Belfry copies. Real dummy counts are set to their desired value rather than incremented.

`tools/build_mod.py` registers exactly one invisible `InGameUIAddin` (`Lua/UnrungBell.xml`). The matching Lua and all textures/leader-scene XML are VFS imports; entry XML and SQL are not. Version 14 / preview 1.11.0 retains the collection UUID and appends new IDs. Root guides, package verification and the collection validator include the new civ. Other civilizations' mechanics and art are unchanged.

## Controller, persistence and time

The context-private `__UNRUNG_CONTROLLER` pairs with `MapModData.UNRUNG_Controller`; re-inclusion is inert only when both agree with the active context. A fresh owner retires/removes old handlers, whose wrappers also refuse work without current ownership. Shutdown cannot clear a newer controller. These shared values contain no saved gameplay state.

Every authoritative state read comes from `Modding.OpenSaveData().GetValue`, using dot notation. One pipe-delimited v1 string holds `peace,war,toll,windows,lastBegin,lastDone,blocked,skipBegin`; no independent field writes can persist half a transition. `toll=0` means inactive; Quietude is always derived. Commit readback precedes applying derived effects. Invalid/version-newer records fail closed without overwriting. This is atomic at the single save-data row level, not a claim about whole-engine crash transactions.

`PlayerDoneTurn` counts a peaceful window once using `lastDone`. A war or peace transition while the owner is active marks the current window interrupted; even war followed by peace in that same window earns no peaceful turn. `PlayerDoTurn` reconciles war, deduplicates via `lastBegin`, and advances an active Toll's window count. An activation during an active owner turn sets `skipBegin` to that turn token so a late/duplicate callback cannot count the partial turn. At start #6, after five complete start-to-start windows, Toll strength/window count becomes zero. Save initialization never invokes either turn boundary. Other civilizations' turns perform only the eligibility check.

Source evidence confirms that `PlayerDoTurn` follows native city settlement and that `PlayerDoneTurn` fires on deactivation with `EVENTS_PLAYER_TURN`. Thus Quietude appears at the end of its fifth completed peaceful action turn and feeds subsequent native settlements. No per-turn lump-sum yield is paid in Lua. End-turn autosave is written before DoneTurn in CP; engine resumption/replay of that boundary remains a manual save test.

## War transition ordering

The authoritative notification is `Events.WarStateChanged(teamA,teamB,bool)`, corresponding to `CvTeam::setAtWar` calling `GameplayWarStateChanged` after its own `m_abAtWar` write. Both sides emit; the opposite side may still contain its old flag on the first notification. Queries overlay the notified pair for each relevant Unrung human player, then consider other alive nonbarbarian players' teams. War with a minor counts; barbarian war does not. Only eligible owner IDs are reconciled, and additional declarations leave the existing continuous-war guard intact.

Pre-change DeclareWar/MakePeace are not registered: when `EVENTS_WAR_AND_PEACE` is enabled their first argument is the originating **player**, whereas the legacy callback uses a **team**. Acting there also risks consuming before the actual relationship. City/unit handlers intentionally do not reconcile war, so incidental native capture work during `setAtWar` cannot clear stacks before the notification snapshots them. Initialization and owner boundaries provide actual-state reconciliation without introducing frame callbacks. Source placement is verified; UI delivery/synchrony must still be observed in game.

## City/unit lifecycle and cost

Founding and capture callbacks reacquire the city by plot and actual owner. Capture occurs after native reconstruction and covers nonconquest transfers/liberation. Razing retains no city object after the callback. Construction, sale and targeted city-dirty notifications recalculate one city. Same-city dirty events from dummy setters are suppressed. Separate city errors do not abort remaining cities. Initial load sweeps native foreign city/unit lists once to remove stale markers; repeated init notifications revisit only relevant empires. No map plots are enumerated.

Toll promotions are mutually exclusive, `CannotBeChosen=1`, `LostWithUpgrade=1`. Land domain, a combat class and positive base melee/ranged strength are required; civilians, special noncombat units, ships and aircraft are excluded. UnitCreated handles purchases/training/capture creation; CityTrained handles completion; UnitConverted runs after native promotion copy, including gifts/ownership changes; UnitUpgraded repairs the new unit after an upgrade. Owner boundaries provide a scoped unit-list fallback. Expiration/peace scans the relevant army immediately. No reconciliation touches the permanent Bellwarden promotion or unrelated promotions. `LostWithUpgrade=0` and the native conversion copy preserve the unique promotion normally.

Ordinary relevant owner boundaries cost O(owned cities + units); a foreign boundary performs no list scan. Relevant war changes scan one affected empire. Targeted city/unit events are O(1), aside from the small fixed six/three effect checks and save lookup. The test simulates 5,000 foreign turns without a city/unit-list scan. Native Huge-map timing is not measured.

## Verified combat limitation

`UnitPromotions.FriendlyLandsModifier` is loaded by `CvPromotionEntry`, added into `m_iFriendlyLandsModifier`, and included additively in the generic melee battle-plot modifier for both attack and defense. It therefore stacks 15+15=30 at Toll III without a global strength increase. `FriendlyLandsAttackModifier` is zero, avoiding an additional origin-based melee modifier.

However `CvPlot::IsFriendlyTerritory` includes same-team and open-border territory. `CvUnit::GetMaxRangedCombatStrength` checks `pMyPlot` (the shooter's plot), while melee checks `pBattlePlot`. This cannot express the specified exclusively Kingdom-owned target condition with those fields. This preview openly retains native semantics. Exact behavior requires a CP-compatible DLL change; Lua post-combat hooks cannot retroactively repair combat strength, and transient worldwide modifiers would also give misleading previews and timing hazards. No such workaround is claimed.

Pinned source URLs and hashes are in [SourceAudit.json](SourceAudit.json). Tests prove source contracts, SQL properties and mocked lifecycle invariants, not native combat/save correctness. No in-game tests have been performed for this addition.
