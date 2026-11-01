# The Urgal - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheUrgal/README.md)

**Leader:** Urgal  
**Playstyle:** Snapshot-based melee timing attacks  
**Suggested victories:** Domination

Build and position a complete eligible melee army, then spend a scarce bottle when several useful attacks are ready. Strength II is an attacking window for the current snapshot, not a permanent army upgrade.

## Opening priorities

Develop food, Production, resources and supporting ranged units. Preserve the initial potion until a real objective is reachable. The iron-free Rusher helps the early plan, but the economy still has to build and maintain the force.

## Develop the engine

Stage the existing unembarked melee attackers before drinking. Use ranged fire, siege where appropriate, and controlled paths to maximize productive attacks during the short window. Newly created units do not join that already committed snapshot.

## Convert the advantage

Keep a second line and a plan for Aftertaste. Save later bottles for important technologies or fronts rather than using one whenever it becomes available. Normal upgrades preserve only an eligible participant's remaining deadline.

## Pros

- The attack bonus applies to eligible melee attacks against units and cities.
- Stored bottles allow deliberate campaign timing.
- A positioned mixed army can combine boosted finishers with ordinary ranged and siege support.

## Cons and opportunity costs

- The bonus does not improve defense, ranged attacks, ships or aircraft.
- Newly trained or acquired units cannot enter the current snapshot.
- The attack window is finite, and Aftertaste blocks immediate reuse.

## Playing against this civ

- Withdraw vulnerable units, use ranged pressure and force long approaches during the window.
- Defend through the deadline and counterattack after it expires.
- Attack the production and staging base before the eligible army is ready.

## Common mistakes

- Drinking while the army is still several turns from contact.
- Expecting new reinforcements, ranged units or ships to receive the current bonus.
- Treating Aftertaste as a direct combat penalty rather than a restriction on drinking again.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Luna Network](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/LunaNetwork.md) | A concentrated early strike can punish exposed cities whose owner has prioritized settlement and infrastructure. |
| Opportunity | [Viltrum](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/ViltrumEmpire.md) | A well-stocked force can exploit the Scourge's severe population, survivor and production vulnerability. |
| Threat | [Unrung Bell](KingdomOfTheUnrungBell.md) | A prepared Toll and territorial line can buy the time needed to exhaust a limited potion window. |
| Threat | [The Threshold Court](TheThresholdCourt.md) | A maintained House network can reinforce a threatened city while the attacking snapshot's clock keeps running. |

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheUrgal/README.md](../../TheUrgal/README.md)
- [TheUrgal/SQL/00_URGAL_Core.sql](../../TheUrgal/SQL/00_URGAL_Core.sql)
- [TheUrgal/SQL/01_URGAL_Inheritance.sql](../../TheUrgal/SQL/01_URGAL_Inheritance.sql)
- [TheUrgal/SQL/02_URGAL_Effects.sql](../../TheUrgal/SQL/02_URGAL_Effects.sql)
- [TheUrgal/SQL/03_URGAL_Art.sql](../../TheUrgal/SQL/03_URGAL_Art.sql)
- [TheUrgal/SQL/10_URGAL_Text.sql](../../TheUrgal/SQL/10_URGAL_Text.sql)
- [TheUrgal/Lua/URGAL_Core.lua](../../TheUrgal/Lua/URGAL_Core.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
