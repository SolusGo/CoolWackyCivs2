# The Conical Union - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheConicalUnion/README.md)

**Leader:** High Marshal Bollard  
**Playstyle:** Connected secondary cities and efficient worker logistics  
**Suggested victories:** Science or conventional Domination

Develop useful non-capital cities, connect them through the actual native network, and make the connection worth its upkeep. The capital is the network anchor rather than a beneficiary of the signature connected-city yields.

## Opening priorities

Use Road Crews to improve food and resources before laying unnecessary roads. Settle defensible cities that can support the maintenance and benefit from a reliable connection to the capital.

## Develop the engine

Complete connections and put Detour Offices where their defense and conditional Gold matter. Check the native connection flag after changes. An extra route between already connected cities does not multiply the flat bonus.

## Convert the advantage

Use the network's steady Production, Culture and Gold to support research and reinforcement. Protect bottlenecks and keep repair crews available so one raid does not disconnect a large part of the empire.

## Pros

- Connected secondary cities receive steady development support.
- Road Crews improve, connect and repair more effectively.
- Offices combine normal Walls with additional cultural and network value.

## Cons and opportunity costs

- The capital gains no UA connection yields.
- Road upkeep and physical network defense remain real costs.
- Flat bonuses do not multiply with redundant paths or automatically scale with Era.

## Playing against this civ

- Pillage key connections and threaten exposed repair crews.
- Attack the bottleneck that supports several cities rather than scattering raids.
- Pressure a new city before its connection is active.

## Common mistakes

- Expecting a capital road loop to earn the non-capital bonus.
- Counting several roads or Harbors as several copies of the same effect.
- Assuming every route change is reflected immediately before the next economic settlement.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Pigeon Republic](TheRepublicOfPigeons.md) | A protected native city-connection network supplies its own flat bonuses without consuming outgoing caravan capacity. |
| Opportunity | [Saba](KingdomOfSaba.md) | A well-connected network has opportunities on useful sites that lack Saba's required River or Desert-centre conditions. |
| Threat | [Beyond the Sky](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/MasayaBeyondSky.md) | Fast raiders can reach network bottlenecks and force repeated repair duty. |
| Threat | [The Filthy Realm](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/FilthyRealm.md) | Economic disruption and forced emergency spending make a maintenance-dependent network harder to sustain. |

## Implementation limits

Native connection status is cached. The documented first-settlement lag can apply after a network change; no instantaneous same-turn activation or removal is promised.

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheConicalUnion/README.md](../../TheConicalUnion/README.md)
- [TheConicalUnion/SQL/00_CONICAL_Core.sql](../../TheConicalUnion/SQL/00_CONICAL_Core.sql)
- [TheConicalUnion/SQL/01_CONICAL_Inheritance.sql](../../TheConicalUnion/SQL/01_CONICAL_Inheritance.sql)
- [TheConicalUnion/SQL/02_CONICAL_Effects.sql](../../TheConicalUnion/SQL/02_CONICAL_Effects.sql)
- [TheConicalUnion/SQL/03_CONICAL_Art.sql](../../TheConicalUnion/SQL/03_CONICAL_Art.sql)
- [TheConicalUnion/SQL/10_CONICAL_Text.sql](../../TheConicalUnion/SQL/10_CONICAL_Text.sql)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
