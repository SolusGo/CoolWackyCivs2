# The Boundless City

> There shall be no second city. For the first shall have no end.

The civilization selection map now uses an original [parchment city atlas](../../TheBoundlessCity/docs/MapArtwork.md), fitted to the native map window.

![The First Architect](../../art-source/TheBoundlessCity/ArchitectAndWorld.png)

**Leader:** The First Architect · **Capital:** The Heart of the World · **Target:** BNW + CP v151 · **Human/AI selectable:** yes · **Collection:** mod v14, preview

## Identity and uniques

| Unique | Gameplay |
| --- | --- |
| **The World Is One City** | One original capital; no additional founding or trained Settlers. A separate Culture pool claims unowned tiles adjacent to capital-connected territory, with no expansion-distance limit. Real citizens can be reserved for distant owned tiles through The Boundless Workforce. |
| **The Grand Registry** | Replaces Monument. +3 Culture; +1 territorial Culture for each 10 owned plots, capped at +10; custom frontier costs reduced by 15%. Other active Monument rules are inherited. |
| **Frontier Surveyor** | Replaces Worker. 3 Movement, 125% base work rate, and +5 policy Culture once per owned plot when completing a new improvement more than five hexes from the capital. Repairs and routes do not qualify. |

## History, society and government

The complete civic history is available in [The Charter of One Threshold](../../TheBoundlessCity/Lore/TheCity.md). The overview below explains the world behind the mechanics.

### Why an entire country calls itself one city

The Boundless City measures its unity through a common charter. Its residents can live among vineyards, in a distant quarry reach or on an island beyond the coast while sharing the citizenship, final courts, treasury and municipal identity of The Heart of the World. Their homes are districts of one political community. The capital remains the place where that community's highest obligations are finally witnessed.

The arrangement began at the Seven Crossings, rival settlements whose disconnected defenses worsened the Great Inundation. One quay's embankment diverted water into another's streets. Grain remained behind a toll gate while downstream families starved. The First Architect's response joined the crossings' responsibilities around a common bridge, common measures and an open flood channel.

The founding vow denied future governments an easy excuse to abandon a distant neighborhood. A new district would remain part of the same undertaking, entitled to a hearing and answerable for its share of the work. Over generations, that commitment produced a municipality stretching across a landscape outsiders would naturally describe as a country.

### Government that can reach its residents

The Heart handles decisions that must bind the whole city. Ward councils handle services their residents can inspect, and reach boards coordinate the corridors connecting several wards. A reach might follow a river basin, a mountain pass or a chain of ferries. Its boundaries reflect practical connections and can change as the city develops.

| Institution | What it does |
| --- | --- |
| **Council of Wards** | Gives districts a voice in common law, taxation, appropriations and executive authority. Population matters, while minimum representation preserves the standing of smaller wards. |
| **First Architect** | Directs an integrated program of works under the charter and the terms of the office's appointment. |
| **College of Works** | Provides the engineering, medical, surveying and provisioning knowledge needed to make the program usable. |
| **Common Bench** | Hears final appeals and claims against officials, including the city's own highest planners. |
| **Grand Registry** | Preserves households, obligations, decisions, public accounts and the evidence needed to correct a mistake. |
| **Ward councils and reach boards** | Organize everyday services, local reserves, shared corridors and immediate emergency action. |

The institutions check and frustrate one another. The Council can withhold an appropriation, a court can require a plan to change, and a ward can produce evidence contradicting a central report. The city has also experienced captured offices, narrow franchises and rulers who used emergency authority to avoid those restraints. Its charter is a standard people struggle to enforce.

### How the land actually feeds and supports it

A remote worker normally lives in the district where they work. An orchard household does not travel across a continent every morning. Its contribution enters the same common account as the work of a central artisan, and the city must avoid committing the same person's time to both places. Citizenship moves with a resident transferring between districts.

Provision follows a similar principle. Food travels between farms, mills, quays, stores and receiving households. Much of it never passes through the capital. Shared accounts allow the city to coordinate that supply, while dispersed reserves reduce dependence on a single bridge or storehouse. Physical distance still costs labor and creates vulnerability to weather, interruption and neglect.

The city contains many workshops, but major appropriations draw on a common pool of skilled labor and materials. An arsenal, a great crossing and an ambitious university cannot each claim the whole of that pool. Establishing an order of works is both a source of remarkable concentration and a source of lasting resentment among wards asked to wait.

### Water, justice and the right to be remembered

Water connects the city's obligations as firmly as its roads. Upstream wards cannot use their position to erase downstream claims. Local crews inspect wells and drains; larger offices coordinate watersheds and expensive works. Public health depends on those offices listening when an ordinary neighborhood reports a failure.

The Registry preserves records in ward houses and reach offices as well as at the Heart. The Great Register Fire taught the city that a single authoritative archive could become a single point at which thousands of people lost the means to prove what they were owed. Separated copies, witnesses and recorded corrections made its memory more resilient.

The Ardin judgment established the corresponding principle in law: an omitted household does not cease to exist because an official book has lost it. The Common Bench's route of appeal protects that claim, though distance, cost and obstruction can still make the route difficult to use. The city becomes credible through the people able to hold it to its own record.

### People, culture and the cost of ambition

Neighborhoods retain different foods, languages, beliefs and customs. Ward schools teach the practical language of common membership: reading a notice, recognizing a measure and making a complaint. Specialists and research institutions connect local knowledge to larger undertakings. Temples and philosophical traditions argue over whether endless construction expresses mutual care or civic pride.

The Petition of the Dry Cups remembers low-quay residents who brought their drinking vessels into the Council chamber while labor and water were diverted to a monumental avenue. Their victory forced the city to put neglected intakes ahead of a favored plan. Later officials praised the charter for making correction possible; residents remembered how long their earlier reports had been ignored.

The [First Architect](../../TheBoundlessCity/Lore/TheFirstArchitect.md) represents a mortal founder and an office inherited across generations. The [Surveyors](../../TheBoundlessCity/Lore/FrontierSurveyors.md) carry the city's plans outward and must return to record the consequences. Their stories make the promise of one city compelling precisely because keeping it requires more than a map and an impressive title.

The full [lore library](../../TheBoundlessCity/Lore/README.md) includes 29 city chapters, a six-part leader biography, Registry and Surveyor histories, and the Dawn address. The same books supply the in-game Civilopedia. Government, reserves and institutions described here are worldbuilding; the implemented mechanics remain those below.

## Gameplay overview

Early play favors population, the Registry, improved local land and a defensible capital. Your frontier grows from a separate copy of the capital's Culture output; ordinary Social Policy Culture is not spent. Over time, districts spread across coastlines and water into new landmasses. Valuable resources, yields, compact approaches and your chosen cardinal direction influence deterministic tile selection.

The central advantage is the **choice of tiles**, rather than passive yields from territory. A distant mine, farm or fishing improvement can contribute to the same capital, but each assigned plot needs one real reserved citizen. All production still passes through one queue, workers must travel to distant districts, and losing the original capital leaves no replacement settlement.

The [Food growth hotfix](../../TheBoundlessCity/docs/FoodGrowthHotfix.md) preserves remote yields across harmless local governor changes, so the reproduced pre-growth callback sequence harvests the displayed rate. Credits remain bounded by actual default citizens; existing saves need no migration. In-game confirmation remains pending.

## The Boundless Workforce

The [custom graphical skin](../../TheBoundlessCity/docs/UIVisuals.md) adds an engraved-city header, brass/teal frames, textured controls and assignment/pending marks. Native yield icons keep the rows compact, with full-name tooltips. [Preview and art sources](../../art-source/TheBoundlessCity/WorkforceUI/README.md).

Open the button at the upper right of the world map. The panel shows population, owned land, local/remote workers, specialists, idle labourers and unassigned citizens. It distinguishes movable citizens from additional safe remote capacity and lists pending/locked requests, frontier progress, gross remote yields, labourer compensation and net base contribution.

Territory, Workforce and Management now use separate localized labels so Owned Plots and the remaining statistics stay visible. Frontier Culture and the next claim's cost are separate fields; original capitals subjugated appears under Management. Scroll the overview to reach wrapped text or the yield breakdown. Existing assignment and siege controls remain below it. See the [summary fix and live checklist](../../TheBoundlessCity/docs/SummaryDisplayFix.md).

- **Automatic:** compares distant jobs with labourer output and displaced local work, ignores old manual locks and retains native specialists.
- **Manual:** uses explicit selections; unlocking keeps a selection, while Release removes it.
- **Hybrid:** preserves your remote locks and native local locks before ranking other plots.

The saved **Food minimum** control cycles Off, 0, +2, +4 and +6 net Food (default 0). Automatic/Hybrid choices use bounded native Food feedback; Manual remains direct control. A red **!** explains an unmet target. Stable useful assignments survive small changes, and cached candidates/bounded selection reduce work on large territories. See the [planner, benchmarks and continuation checklist](../../TheBoundlessCity/docs/RemotePlanner.md).
- Choose **Food**, **Production**, **Gold** or **Balanced** priorities; sort distant plots by distance, score, resource or improvement.
- **Assign/Release** controls participation; **Lock/Unlock** controls preservation in Hybrid. **Locate** centers the map. A requested lock can wait for reservation capacity.

Rows are paged; the panel has no permanent frame polling and hides during city, diplomacy and other incompatible screens. The launcher checks actual screen visibility and refreshes after returning to the map, even while the panel is closed. The [1.2.2 UI hotfix](../../TheBoundlessCity/docs/UIVisibilityHotfix.md) keeps existing saves and assignments compatible; restart Civ V after installing it.

## Limits you need to know

Remote distance has no mod limit. Remote count now uses forced local withdrawals **or** a verified surplus that cannot fit into native local jobs and building specialist slots. With 80 population and 30 native jobs, the fixture works 50 remote plots rather than stopping at 30. With 150 population it works 120. These are conservative bounds, not a claim that all population can be reserved remotely: CP Lua has no arbitrary forced-labourer setter. Specialists and local locks consume capacity.

Units retain NoCapture. At 1 HP, war and visibility with an adjacent eligible melee force, use the military panel to **Reclaim** your genuine original capital, **Demolish** a current-owner native-legal settlement, or **Subjugate** a protected major settlement once without occupation/rewards. Capitals and holy cities are never demolished; city-state settlements remain excluded. No-raze rules and native vetoes continue to govern destruction.

Boundless survives capital loss while units remain through its own native trait. Zero units/max-city-elimination can still defeat it; already eliminated players cannot reclaim. Older native saves may need a normal technology/policy trait refresh. Reclaim restores the saved original and UA through deferred native conquest; ordinary attack-click capture remains blocked.

Subjugate every ever-alive rival other-team original capital to use the optional native Domination finish. Original civilization/founding identity persists through liberation/transfers. Missing/replaced originals prevent victory; prior winners and other civilizations' rules are untouched. This path is implemented and simulation-tested, awaiting native gameplay verification.

Unexpected cities follow historical/native living recipients, legal removal, then quarantine. New trade routes and border selection are vetoed for extras; resistance/production guards and remote/Surveyor exclusion remain. Resources, Happiness, global buildings, existing routes, specialist GPP and native city counts still limit an absolute guarantee.

Remote improvement upgrades advance once per owner turn only on assigned eligible remotes. Terrain Culture-to-Tourism now refreshes through the native cache API. Virtual assignments still do not count as native worked plots for all policy/belief/GP effects. Version 4 migrates prior Lua state to schema 3, preserving Culture, original identity, assignments and reward history; BCY2 remains unchanged. See the [six-limitation report](../../TheBoundlessCity/docs/EngineCompletionReport.md) and [effect matrix](../../TheBoundlessCity/docs/WorkedTileEffects.md).

## Further reading

- [Detailed mechanics, balance and installation](../../TheBoundlessCity/README.md)
- [Implementation and citizen accounting](../../TheBoundlessCity/docs/Implementation.md)
- [CP API audit](../../TheBoundlessCity/docs/APIAudit.md)
- [Validation results and exact game tests](../../TheBoundlessCity/docs/Testing.md)
- [Civilization changelog](../../TheBoundlessCity/CHANGELOG.md)
- [Fixes report and measured verification](../../TheBoundlessCity/docs/FixesReport.md)
- [Final stability pass](../../TheBoundlessCity/docs/FinalStabilityReport.md)

- [Current engine completion report](../../TheBoundlessCity/docs/EngineCompletionReport.md)
- [Optional DLL interfaces](../../TheBoundlessCity/docs/OptionalDLLExtensions.md)

- [Turn/movement crash hotfix](../../TheBoundlessCity/docs/CrashHotfixReport.md)
