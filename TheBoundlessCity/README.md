# The Boundless City

> There shall be no second city. For the first shall have no end.

An original Civilization V civilization led by **The First Architect**, built for **Brave New World + Community Patch v151**. Its capital is **The Heart of the World**. The theme combines a medieval settlement, golden civic architecture and an interconnected metropolis spreading across the world.

**Release 1.2.2 preview / mod version 4, awaiting full native playtesting.** The player confirmed the earlier crash replay succeeds; the latest [Workforce visibility fix](docs/UIVisibilityHotfix.md) still needs an in-game retry. Unlimited potential border/remote distance and the safe forced/surplus citizen model remain. New military options reclaim the genuine original and subjugate protected major cities; native Domination completion, remote improvement development and Tourism refresh are implemented. See the [six-limitation report](docs/EngineCompletionReport.md) and [engine boundaries](docs/EngineLimitations.md).

## Unique ability — The World Is One City

The initial Settler can found your original capital. Trained/purchased founding units are vetoed by civilization-scoped handlers and `NoAnnexing`; later founding is blocked, including after capital loss. Script-created extra Settlers are removed at the owner turn. Your original capital is identified by its coordinates and founding turn, rather than whichever city temporarily holds the Palace.

The capital's Culture drives a **separate frontier accumulator**. The mod does not subtract policy Culture or overwrite culture storage, border thresholds or Tourism. Native border growth remains active. Frontier claims always adjoin the capital-connected territory component, so water can join coastlines and islands without disconnected custom claims. Already owned enemy territory is excluded. Map adjacency APIs handle edges and wrapping.

Each claim costs:

```text
round((20 + 2.5 × sqrt(ownedPlots) + 0.20 × ownedPlots)
      × (1 + 0.05 × currentEra)
      × gameSpeed.CulturePercent / 100
      × (GrandRegistryPresent ? 0.85 : 1))
```

Costs grow progressively and approximately linearly. There is no radius check, exponential cost curve or per-game claim limit. Unspent progress remains banked if no legal adjacent tile exists. Tile ranking favors evaluated yields, visible resources, multiple owned approaches and proximity; your North/East/South/West preference adds a directional bias. Equal scores resolve by plot index. The formula is tunable in `BoundlessCore.lua`.

## Working distant districts

A distant plot contributes **only when assigned**. The six supported plot yields are Food, Production, Gold, Science, Culture and Faith, read from the engine's evaluated `Plot:GetYield`. Terrain, improvements, resources and ordinary technology/policy yield changes enter through that native result. No distance penalty is added.

Each credited plot uses one real native default labourer. A labourer is protected either by a verified withdrawal from a local plot (`City:AlterWorkingPlot`) or by a conservative surplus that cannot fit into all native local jobs and existing building specialist slots, even after governor reallocation. These are overlapping bounds, so they are never added together. The labourer remains in the existing population and consumes normal Food; its ordinary yields are subtracted from the miscellaneous base source. Gross remote plot yields enter the terrain base source, preserving ordinary city modifiers and the native terrain-Culture conversion to Tourism. The mod applies no second multiplier.

For example, two assignments supplying 5 Food and 8 Production add those amounts to terrain yields. If their native labourers would produce 1 Production each, the miscellaneous adjustment is -2 Production. Their native specialist source still supplies that 2 Production, so the combined contribution is exactly the remote plots' 5 Food and 8 Production. The native source setters are journalled, and a net-zero miscellaneous pulse refreshes cached rates after terrain-only changes.

With 80 population, 30 owned native local jobs and no specialist buildings, the verified surplus is 50: those 50 defaults can work remote tiles while 30 citizens remain local. With 150 population the same bound is 120. At lower populations, forced withdrawals can still be useful: the stress tests reserve 30 of 40 citizens. CP exposes no arbitrary forced-default setter, so all 80 citizens cannot safely be reserved remotely in the first example. Real unassigned citizens wait for native allocation; positive worker automatons from another mod conservatively disable remote credits. Population is never increased.

Assignments, exclusions and locks persist. Yield changes are handled through relevant events and owner-turn reconciliation. Eligibility requires ownership, a non-city plot with yields, water-working technology where needed, no visible enemy and no blockade. Yielding mountain wonders are allowed. Mid-action population/citizen/ownership changes trim unsafe credits, followed by one deferred callback. The capital plot stores a versioned yield ledger, so reinitialization replaces the previous contribution. Remote improvement upgrades advance once per owner turn using native rate/threshold APIs, while unassigned plots do not. Terrain-Culture Tourism is refreshed explicitly. Native worked counters and other worked-only effects remain limited; see the [effect matrix](docs/WorkedTileEffects.md).

The [Food growth hotfix](docs/FoodGrowthHotfix.md) keeps existing remote yields active through local governor changes while their real default citizens remain. This repairs a reproduced turn-order gap that could harvest less Food than the city displayed. Actual worker/specialist reclaims still remove excess credits immediately. Restart after installing; existing saves retain their assignments and progress. Native campaign confirmation is pending.

## The Boundless Workforce

The upper-right world-map button opens a panel with:

- Population, owned plots, local workers, credited remote workers, specialists and idle population.
- Available citizens, additional safe remote capacity, the structural remote limit, pending requests and locks, plus frontier Culture and next-claim cost.
- Gross remote plot yields, labourer compensation and the net base contribution.
- Automatic/Manual/Hybrid mode, Food/Production/Gold/Balanced priorities and border direction.
- Remote plot rows with coordinates, distance, resource, improvement, yields, assignment state and lock state.
- Sorting by distance, yield score, resource or improvement; **Assign/Release**, **Lock/Unlock** and **Locate** controls.

The overview uses three columns: **Territory**, **Workforce** and **Management**. Each statistic has its own localized label, including **Owned Plots**, Frontier Culture progress, the next frontier claim's Culture cost, both remote-capacity figures and original capitals subjugated. Summary text and yields share a scroll area above the action controls; scroll there when longer text exceeds the viewport. The overall panel size stays unchanged. See the [summary-display fix](docs/SummaryDisplayFix.md) for the localization cause and verification steps.

**Automatic** ignores old manual locks and ranks useful local/remote plots after specialists. **Manual** follows explicit selections; unlocking does not deselect a plot. **Hybrid** respects remote locks and native local locks before ranking other tiles. Releasing excludes a plot until selected again. Requests remain pending when capacity or eligibility is unavailable and retry after relevant changes. Native local/specialist allocation still belongs to the city governor, so Auto is a constrained approximation to a complete city optimizer.

Available citizens means population outside current specialist and active locked roles, including movable local workers. Additional remote capacity is the number that the implemented reservation system can actually add, capped by eligible remote inventory. The figures can differ substantially. Idle labourers are defaults not credited remotely; unassigned citizens are shown separately. Native automatons are listed separately when present, and remote credits are suspended until ordinary population can be attributed safely. The displayed census includes these adjustments rather than hiding unused population.

Rows are paged in groups of sixteen. The interface closes/hides for city screens, leader diplomacy, other game popups, nonselection interface modes and inactive turns. The launcher refreshes after returning to the map, including while the panel is closed. Native screen checks and turn/load recovery prevent missed notifications from leaving it hidden. It does not replace CityView and installs no idle frame-polling loop.

After updating the UI scripts, fully restart Civ V and reload your existing modded save. Open the upper-right Workforce button, enter and leave CityView, a policy popup and diplomacy, then reopen it. If it disappears again, the latest `Lua.log` includes `[BoundlessCity] Workforce visibility:` with its hiding reason. See the [UI hotfix report and exact retry steps](docs/UIVisibilityHotfix.md).

## The Grand Registry — Monument replacement

The Registry retains the active Monument's costs, prerequisites, replacement class and companion effects. Its base Culture row is +3. It adds `floor(ownedPlots / 10)` Culture, capped at +10. Ten hidden, nonstacking one-Culture building bits express that bonus without relying on ambiguous building-instance multiplication. Counts are updated when territory or Registry ownership changes. Removing the Registry removes its territorial bonus; plot loss decreases it. None of these bits can be constructed normally.

The Registry also discounts each custom frontier claim by 15%. It does not discount Social Policies or native plot purchases.

## Frontier Surveyor — Worker replacement

The Surveyor has 3 Movement and **125% of the active Worker's base WorkRate**. This is a multiplicative base-rate change, which preserves the ratio when normal additive Worker-speed modifiers apply. Actual completion turns remain discrete and depend on build time, game speed and other effects.

All Worker build permissions, AI roles, free promotions and upgrade/companion relationships are inherited from the active database. It remains a civilian with the ordinary Worker model and automation support; the custom portrait and flag do not add a combat role.

Completing a real improvement on an owned plot more than five hexes from the original capital grants **5 ordinary policy Culture**, once per plot per Boundless player. The completion callback must identify a Surveyor and a Build with an improvement type. Repairs, roads, railroads and canceled builds do not qualify. A persistent plot reward bit prevents replacements, pillage/repair cycles, ownership changes and reloads from repeating the award. The reward is intentionally the specified flat +5; Culture speed scaling is applied to frontier costs, not to this reward.

## One-city ownership and victories

Every Boundless unit keeps **NoCapture**, including created/converted units. The military view lists revealed cities and hides current details behind fog. At war, reduce a visible target to **1 HP** and bring an adjacent melee unit with movement and attacks remaining. Busy, defensive-only, embarked and air units are excluded; naval forces need a coastal city.

- **Reclaim:** available only to a living Boundless with zero cities, against its saved genuine original capital. Deferred native conquest reinstates the Heart and rebuilds frontier/workforce state while preserving saved Culture progress, preferences and Surveyor rewards. Native conquest effects apply. Normal attack-click recapture remains blocked; use this siege action.
- **Demolish:** only when the current owner passes native CanRaze and the city is not an original capital, holy city or city-state settlement. Deferred native Disband releases associated territory without giving Boundless another city or reward. Own-founded enemy towns generally fail the native check.
- **Subjugate:** acknowledges a defeated major settlement once when demolition is prohibited, including protected original capitals and holy cities. Ownership/territory stay with the enemy. It consumes moves, persists through transfer/liberation/reload, and awards no economic bonus. City-state settlements cannot be subjugated.

The native **StaysAliveZeroCities** trait lets Boundless survive capital loss while units remain. Losing the last unit or applicable max-city-elimination rules can still eliminate it. No eliminated player is revived and no hidden city is created. In upgraded v1–3 saves, the cached native trait may remain false until a normal technology/policy refresh; verify this in a backed-up test save. New v4 games initialize the flag normally.

With Domination enabled, subjugating **every ever-alive rival other-team major civilization's genuine original capital** can finish through the normal native winner API. Eliminated rivals still count; missing/replaced capitals block completion. Boundless must own its Heart and no extra city. Previous victories are preserved. Other civilizations' victory conditions/ownership are unchanged. This optional feature is enabled by `SubjugationDomination` in BoundlessCore.lua and remains unverified in a live game. Science, Culture and Diplomatic victories retain their normal rules.

Unexpected transfers resolve after acquisition: previous living legal owner, original living legal owner, then native living liberation recipient, native-legal removal, or quarantine. No unrelated custodian or forced resurrection is used. Same-turn return loops are blocked. Any Boundless recipient must be empty and regain only its own recorded original.

Quarantine clears queues/automation, blocks production and new trade routes involving extras, vetoes extra-city native border selection, maintains resistance to suppress ordinary rates/purchases, and excludes associated plots from remote work/Surveyors. Absolute one-city ownership remains limited: external transfers can be transient, and resources, Happiness, global buildings, existing routes, specialist GPP, city counts and military infrastructure are not comprehensively suppressed. Read [the exact limitations](docs/EngineLimitations.md).

## AI and balance

The AI is selectable and uses the same frontier, Registry, citizen reservations and one-city guards. Each owner turn chooses Food when growth is constrained, Production when defense is thin, and Balanced otherwise. Existing leader flavors are preserved. Surveyors share cached resource/yield/remote candidates. Native build IDs, unit creation identity and ownership are revalidated; dead/upgraded/stale targets are dropped. Busy targets remain reserved. Failed routes wait three turns before retry, units rotate fairly, and all calls share at most 12 native paths per owner turn. Budget deferral preserves a valid saved target. There is no distance/land-area cutoff or overwrite of busy native orders.

Native pathfinding, later homeland-AI orders and distant cross-continent development still require live verification. The custom worker planner does not teleport units or promise ocean development with land Workers. **Full AI compatibility has not been verified.**

The strengths are broad resource/terrain access and flexible selection of worked districts. Costs remain one queue, one population, no additional building/specialist infrastructure, travel time, exposed distant improvements and vulnerability to loss of the original capital. The implementation adds no extra percentage yield multiplier.

## Installation, development and references

Use the [root installation/build instructions](../README.md). The [civ page](../docs/civilizations/TheBoundlessCity.md) provides a shorter player guide.

- [Implementation architecture and persistence](docs/Implementation.md)
- [Verified CP API audit and rejected alternatives](docs/APIAudit.md)
- [Exact limitations and unmet original requirements](docs/EngineLimitations.md)
- [Static/simulation results and CP v151 live test steps](docs/Testing.md)
- [Civilization changelog](CHANGELOG.md)
- [Fixes and completion report](docs/FixesReport.md)
- [Current engine completion report](docs/EngineCompletionReport.md)
- [Worked-tile effect matrix](docs/WorkedTileEffects.md)
- [Optional DLL extension proposal](docs/OptionalDLLExtensions.md)
- [Archived final stability report](docs/FinalStabilityReport.md)
- [Supplied final-pass specification](docs/FinalStabilityRequest.md)
- [Supplied fixes specification](docs/FixesRequest.md)
- [Original supplied specification](docs/OriginalRequest.md)

The supplied specification referred to CoolWackyCivs; the user's requested destination supersedes that repository reference. The implementation is isolated in **CoolWackyCivs2**, following the existing Last City/Kingdoms/Shattered Empire conventions without modifying their source.

- [Turn/movement crash hotfix](docs/CrashHotfixReport.md)
