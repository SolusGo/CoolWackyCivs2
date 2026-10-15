# The Boundless City

> There shall be no second city. For the first shall have no end.

![The First Architect](../../art-source/TheBoundlessCity/ArchitectAndWorld.png)

**Leader:** The First Architect · **Capital:** The Heart of the World · **Target:** BNW + CP v151 · **Human/AI selectable:** yes · **Release:** 1.2.2 preview / mod v4

## Identity and uniques

| Unique | Gameplay |
| --- | --- |
| **The World Is One City** | One original capital; no additional founding or trained Settlers. A separate Culture pool claims unowned tiles adjacent to capital-connected territory, with no expansion-distance limit. Real citizens can be reserved for distant owned tiles through The Boundless Workforce. |
| **The Grand Registry** | Replaces Monument. +3 Culture; +1 territorial Culture for each 10 owned plots, capped at +10; custom frontier costs reduced by 15%. Other active Monument rules are inherited. |
| **Frontier Surveyor** | Replaces Worker. 3 Movement, 125% base work rate, and +5 policy Culture once per owned plot when completing a new improvement more than five hexes from the capital. Repairs and routes do not qualify. |

## How it plays

Early play favors population, the Registry, improved local land and a defensible capital. Your frontier grows from a separate copy of the capital's Culture output; ordinary Social Policy Culture is not spent. Over time, districts spread across coastlines and water into new landmasses. Valuable resources, yields, compact approaches and your chosen cardinal direction influence deterministic tile selection.

The central advantage is the **choice of tiles**, rather than passive yields from territory. A distant mine, farm or fishing improvement can contribute to the same capital, but each assigned plot needs one real reserved citizen. All production still passes through one queue, workers must travel to distant districts, and losing the original capital leaves no replacement settlement.

## The Boundless Workforce

Open the button at the upper right of the world map. The panel shows population, owned land, local/remote workers, specialists, idle labourers and unassigned citizens. It distinguishes movable citizens from additional safe remote capacity and lists pending/locked requests, frontier progress, gross remote yields, labourer compensation and net base contribution.

- **Automatic:** ignores old manual locks and ranks local/distant plots while retaining native specialists.
- **Manual:** uses explicit selections; unlocking keeps a selection, while Release removes it.
- **Hybrid:** preserves your remote locks and native local locks before ranking other plots.
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
