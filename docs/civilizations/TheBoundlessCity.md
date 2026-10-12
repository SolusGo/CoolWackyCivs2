# The Boundless City

> There shall be no second city. For the first shall have no end.

![The First Architect](../../art-source/TheBoundlessCity/ArchitectAndWorld.png)

**Leader:** The First Architect · **Capital:** The Heart of the World · **Target:** BNW + CP v151 · **Human/AI selectable:** yes · **Release:** implementation preview

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

Open the button at the upper right of the world map. The panel shows population, owned land, local workers, remote assignments, specialists, idle citizens, reservation capacity, frontier progress, gross remote yields and the labourer yields being replaced.

- **Automatic:** ranks local and distant plots together while retaining the city's specialist population.
- **Manual:** uses the remote assignments you choose; local management stays in the city screen.
- **Hybrid:** preserves your remote locks and native local locks before ranking other plots.
- Choose **Food**, **Production**, **Gold** or **Balanced** priorities; sort distant plots by distance, score, resource or improvement.
- **Assign/Release** controls participation; **Lock/Unlock** controls preservation in Hybrid. **Locate** centers the map. A requested lock can wait for reservation capacity.

Rows are paged; the panel has no permanent frame polling and hides during city, diplomacy and other incompatible screens.

## Limits you need to know

This is a playable implementation candidate awaiting live game verification. Remote **distance** has no mod-imposed limit, but remote **count** is bounded by citizens safely withdrawn from native worked plots. Specialists are preserved, and excess unemployed population cannot be arbitrarily forced into remote reservations with the verified Lua APIs. The original population-only capacity requirement therefore remains unmet.

Military units cannot capture cities. Protected capitals are never forcibly deleted, and standard Domination is unavailable while foreign capitals remain under other owners. Unexpected externally transferred cities are returned after the native acquisition finishes; a transfer with no eligible recipient is quarantined. That fallback does not satisfy an absolute one-city guarantee against every external script.

Native conditional effects that require a tile to be marked “worked” are not fully simulated. Read the [exact engine limitations](../../TheBoundlessCity/docs/EngineLimitations.md) before relying on a particular policy, belief or improvement mechanic.

## Further reading

- [Detailed mechanics, balance and installation](../../TheBoundlessCity/README.md)
- [Implementation and citizen accounting](../../TheBoundlessCity/docs/Implementation.md)
- [CP API audit](../../TheBoundlessCity/docs/APIAudit.md)
- [Validation results and exact game tests](../../TheBoundlessCity/docs/Testing.md)
- [Civilization changelog](../../TheBoundlessCity/CHANGELOG.md)
