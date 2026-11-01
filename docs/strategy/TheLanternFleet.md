# The Lantern Fleet - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheLanternFleet/README.md)

**Leader:** High Keeper Maren  
**Playstyle:** Defensive coastal development and turn-start naval snapshots  
**Suggested victories:** Science or Culture

Build useful coastal cities, keep one eligible owned military ship inside each selected city at the snapshot, and develop the ordinary economy behind those additions. A garrisoned ship has a real cost and cannot simultaneously perform every naval task.

## Opening priorities

Choose a genuinely coastal site with workable food and production. Establish a Beacon Cutter when safe and useful. The civilization does not grant a starting fleet, so shore defense and economic construction still need resources.

## Develop the engine

Place a guard in the city-centre naval slot before the qualifying turn start. Build Signal Lighthouses where their inherited coastal benefits matter. One ship is sufficient; extra parked ships do not stack more snapshot yields.

## Convert the advantage

Turn a protected coastal network into research or cultural infrastructure while retaining a mobile patrol force. Keep inland defense and naval technology current, and do not confuse guarding the city with controlling every sea lane.

## Pros

- Eligible guarded coastal cities support a modest recurring Science/Culture plan.
- Signal Lighthouses add permanent Culture and a conditional Gold incentive.
- Beacon Cutters combine sight with friendly-territory combat support.

## Cons and opportunity costs

- The condition needs a real coastal city and an owned naval combat unit physically in its centre.
- Civilian trade ships, nearby ships and embarked land units do not qualify.
- The flat additions do not scale automatically with Era, and parked guards have upkeep and opportunity costs.

## Playing against this civ

- Pressure productive coastal approaches and landward tiles, not only the parked ship.
- Use a mobile fleet to contest routes and force difficult garrison-versus-patrol decisions.
- On an inland map, develop advantages that do not require coastal snapshot sites.

## Common mistakes

- Parking a ship adjacent to the city and counting it as a guard.
- Counting a Cargo Ship or several stacked guards as extra qualifying copies.
- Moving in after the snapshot and expecting the current turn's conditional yields.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Pigeon Republic](TheRepublicOfPigeons.md) | On a sea-dominated map with few safe land routes, guarded coastal sites offer opportunities Coo's caravan-only ability cannot use. |
| Opportunity | [The Conical Union](TheConicalUnion.md) | Separate guarded coastal sites can contribute without every city first obtaining a capital connection; the ship and Lighthouse costs still matter. |
| Threat | [Sol Intellect](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/SolIntellect.md) | A protected mature specialist and construction engine can threaten a research race beyond the fleet's modest flat additions. |
| Threat | [Jin](JinDynasty.md) | Mobile land cavalry can threaten the productive approaches and resource sites beyond a parked coastal guard. |

## Implementation limits

Native event dispatch and exact same-turn economic settlement remain unverified acceptance requirements. The guide describes the implemented snapshot contract, not a claimed live-game timing result.

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheLanternFleet/README.md](../../TheLanternFleet/README.md)
- [TheLanternFleet/SQL/00_LANTERN_Core.sql](../../TheLanternFleet/SQL/00_LANTERN_Core.sql)
- [TheLanternFleet/SQL/01_LANTERN_Inheritance.sql](../../TheLanternFleet/SQL/01_LANTERN_Inheritance.sql)
- [TheLanternFleet/SQL/02_LANTERN_Effects.sql](../../TheLanternFleet/SQL/02_LANTERN_Effects.sql)
- [TheLanternFleet/SQL/03_LANTERN_Art.sql](../../TheLanternFleet/SQL/03_LANTERN_Art.sql)
- [TheLanternFleet/SQL/10_LANTERN_Text.sql](../../TheLanternFleet/SQL/10_LANTERN_Text.sql)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
