# The Boundless City

> There shall be no second city. For the first shall have no end.

![The First Architect](../../art-source/TheBoundlessCity/ArchitectAndWorld.png)

**Leader:** The First Architect · **Capital:** The Heart of the World · **Target:** BNW + CP v151 · **Human/AI selectable:** yes · **Release:** 1.1.1 preview / mod v3

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

Rows are paged; the panel has no permanent frame polling and hides during city, diplomacy and other incompatible screens.

## Limits you need to know

Remote distance has no mod limit. Remote count now uses forced local withdrawals **or** a verified surplus that cannot fit into native local jobs and building specialist slots. With 80 population and 30 native jobs, the fixture works 50 remote plots rather than stopping at 30. With 150 population it works 120. These are conservative bounds, not a claim that all population can be reserved remotely: CP Lua has no arbitrary forced-labourer setter. Specialists and local locks consume capacity.

Military units cannot capture cities. **Siege demolition** is available at 1 HP with an adjacent melee unit, war and visibility, only if the current owner can natively raze the settlement. Capitals, holy cities and city-states are excluded. Own-founded enemy towns normally fail that ownership-dependent native check. The action consumes moves, releases that city's territory, and gives Boundless no city or capture rewards. Standard Domination remains unavailable through normal play.

Unexpected transfers return to historical or native-identified living recipients after acquisition finishes. No unrelated custodian is chosen. Same-turn return loops are blocked; a living empty Boundless owner may regain only its recorded original capital. Native-legal orphans can be removed; protected extras are quarantined with production guards, resistance and remote/Surveyor plot exclusion. Transient ownership and empire-level effects remain possible. Native gameplay has not been tested.

The siege view explains why known targets are unavailable and hides undiscovered cities. Surveyors clean stale targets, preserve busy orders and share a fair path budget with unreachable-route retry delays. Version 3 preserves save schema 2 and supports version 1/2 upgrade paths subject to native testing.

Native conditional effects that require a tile to be marked “worked” are not fully simulated. Read the [exact engine limitations](../../TheBoundlessCity/docs/EngineLimitations.md) before relying on a particular policy, belief or improvement mechanic.

## Further reading

- [Detailed mechanics, balance and installation](../../TheBoundlessCity/README.md)
- [Implementation and citizen accounting](../../TheBoundlessCity/docs/Implementation.md)
- [CP API audit](../../TheBoundlessCity/docs/APIAudit.md)
- [Validation results and exact game tests](../../TheBoundlessCity/docs/Testing.md)
- [Civilization changelog](../../TheBoundlessCity/CHANGELOG.md)
- [Fixes report and measured verification](../../TheBoundlessCity/docs/FixesReport.md)
- [Final stability pass](../../TheBoundlessCity/docs/FinalStabilityReport.md)
