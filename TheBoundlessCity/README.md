# The Boundless City

> There shall be no second city. For the first shall have no end.

An original Civilization V civilization led by **The First Architect**, built for **Brave New World + Community Patch v151**. Its capital is **The Heart of the World**. The theme combines a medieval settlement, golden civic architecture and an interconnected metropolis spreading across the world.

**Release status: implementation preview, awaiting native playtesting.** Unlimited potential border distance and unlimited remote tile distance are implemented. Population-only unlimited remote-worker count and absolute synchronous one-city enforcement for every externally scripted transfer are **not** achieved. See [EngineLimitations.md](docs/EngineLimitations.md); these are explicit design gaps, not implied guarantees.

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

For each credited plot, the mod unworks a real native tile through `City:AlterWorkingPlot`. The citizen becomes a **forced native labourer**, still part of the existing population, still eating as an ordinary citizen, and unavailable for simultaneous local tile or specialist work. The mod subtracts that labourer's complete current yield contribution and adds the assigned remote plot's yields to the city's miscellaneous base-yield source. City/global yield modifiers then apply through the normal engine calculations.

For example, reserving two citizens for a 5-Food farm and an 8-Production mine yields those plots' gross 5 Food and 8 Production. If their native labourer replacements would produce 1 Production each, the added miscellaneous contribution is 5 Food and 6 Production: the remaining 2 Production already comes from the two native labourers. The original local tiles have been unworked. Nothing produces twice.

Native labourer reservation is the central limit: the mod can reserve only citizens safely withdrawn from currently worked native plots. It does not increase the city's population, use negative automatons, invent specialist setters, raise global radius settings or grant yields from every owned plot. Native specialists are governed by the city interface/governor and subtracted from capacity. Extra unemployed population is not automatically converted to remote capacity.

Assignments, exclusions and locks persist. Yield changes are handled through relevant game events and owner-turn reconciliation. Invalid ownership, mountains, city tiles, visible enemy units and blockaded water invalidate a remote plot. Mid-action population/citizen/ownership changes synchronously trim credited contributions; native reallocation follows through one deferred callback. The capital plot stores the city's yield ledger, so reinitialization replaces a previous contribution instead of adding another copy.

## The Boundless Workforce

The upper-right world-map button opens a panel with:

- Population, owned plots, local workers, credited remote workers, specialists and idle population.
- Available additional reservations, frontier Culture and next-claim cost.
- Gross remote plot yields and the labourer yields being replaced.
- Automatic/Manual/Hybrid mode, Food/Production/Gold/Balanced priorities and border direction.
- Remote plot rows with coordinates, distance, resource, improvement, yields, assignment state and lock state.
- Sorting by distance, yield score, resource or improvement; **Assign/Release**, **Lock/Unlock** and **Locate** controls.

**Automatic** compares local and remote plot scores using the available native population after specialists. **Manual** follows selected remote locks and leaves local decisions to the city screen. **Hybrid** prioritizes remote locks and native local locks before scoring other tiles. Releasing a plot excludes it from automatic selection until you assign or lock it again. A lock can remain pending when there is no safe reservation capacity; ownership of land alone never guarantees assignment.

Rows are paged in groups of sixteen. The interface closes/hides for city screens, leader diplomacy, other game popups, nonselection interface modes and inactive turns. It does not replace CityView and installs no idle frame-polling loop.

## The Grand Registry — Monument replacement

The Registry retains the active Monument's costs, prerequisites, replacement class and companion effects. Its base Culture row is +3. It adds `floor(ownedPlots / 10)` Culture, capped at +10. Ten hidden, nonstacking one-Culture building bits express that bonus without relying on ambiguous building-instance multiplication. Counts are updated when territory or Registry ownership changes. Removing the Registry removes its territorial bonus; plot loss decreases it. None of these bits can be constructed normally.

The Registry also discounts each custom frontier claim by 15%. It does not discount Social Policies or native plot purchases.

## Frontier Surveyor — Worker replacement

The Surveyor has 3 Movement and **125% of the active Worker's base WorkRate**. This is a multiplicative base-rate change, which preserves the ratio when normal additive Worker-speed modifiers apply. Actual completion turns remain discrete and depend on build time, game speed and other effects.

All Worker build permissions, AI roles, free promotions and upgrade/companion relationships are inherited from the active database. It remains a civilian with the ordinary Worker model and automation support; the custom portrait and flag do not add a combat role.

Completing a real improvement on an owned plot more than five hexes from the original capital grants **5 ordinary policy Culture**, once per plot per Boundless player. The completion callback must identify a Surveyor and a Build with an improvement type. Repairs, roads, railroads and canceled builds do not qualify. A persistent plot reward bit prevents replacements, pillage/repair cycles, ownership changes and reloads from repeating the award. The reward is intentionally the specified flat +5; Culture speed scaling is applied to frontier costs, not to this reward.

## One-city ownership and victories

Every Boundless unit receives the native **NoCapture** promotion. Starting, trained, created and converted units are covered; transfers to another civilization strip this civilization-specific promotion. Military attacks can weaken cities but cannot enter to occupy them. There is no conquest reward to farm. Ordinary conquered cities are not automatically destroyed because acquisition is prevented in the first place.

If diplomacy or another script nevertheless transfers a city, recovery queues its coordinates and returns it through native `AcquireCity` after the original acquisition stack finishes. The previous/original eligible living owner is preferred, followed by a living non-Boundless custodian. The original capital is excluded by coordinates/founding identity. If there is no eligible recipient, construction/training in the additional city is blocked and a notification records quarantine; no city is illegally killed or razed. This fallback can temporarily leave an extra owned city and is explicitly outside the absolute one-city guarantee.

Science, Culture and Diplomatic victories retain normal game rules, subject to live CP verification. Standard Domination cannot normally be won while foreign original capitals cannot be occupied. No global domination changes or special untested alternative victory have been added.

## AI and balance

The AI is selectable and uses the same frontier, Registry, citizen reservations and one-city guards. Each owner turn chooses Food when growth is constrained, Production when defense is thin, and Balanced otherwise. Leader flavors emphasize growth, improvements, defense, Culture, Science and infrastructure; Settler expansion flavor is suppressed. Idle Surveyors receive legal deterministic improvement/movement missions on useful land in their current area.

Native pathfinding, later homeland-AI orders and distant cross-continent development still require live verification. The custom worker planner does not teleport units or promise ocean development with land Workers. **Full AI compatibility has not been verified.**

The strengths are broad resource/terrain access and flexible selection of worked districts. Costs remain one queue, one population, no additional building/specialist infrastructure, travel time, exposed distant improvements and vulnerability to loss of the original capital. The implementation adds no extra percentage yield multiplier.

## Installation, development and references

Use the [root installation/build instructions](../README.md). The [civ page](../docs/civilizations/TheBoundlessCity.md) provides a shorter player guide.

- [Implementation architecture and persistence](docs/Implementation.md)
- [Verified CP API audit and rejected alternatives](docs/APIAudit.md)
- [Exact limitations and unmet original requirements](docs/EngineLimitations.md)
- [Static/simulation results and CP v151 live test steps](docs/Testing.md)
- [Civilization changelog](CHANGELOG.md)
- [Original supplied specification](docs/OriginalRequest.md)

The supplied specification referred to CoolWackyCivs; the user's requested destination supersedes that repository reference. The implementation is isolated in **CoolWackyCivs2**, following the existing Last City/Kingdoms/Shattered Empire conventions without modifying their source.
