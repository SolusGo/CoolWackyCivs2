# Honeycomb Commonwealth - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheHoneycombCommonwealth/README.md)

**Leader:** Speaker Mellia  
**Playstyle:** Worked-Plantation specialization and protected agrarian development  
**Suggested victories:** Science or Culture through a developed economy

Settle useful Plantation resources, improve them, and actually assign citizens to work them. The capped city bonus is a reward for a functioning specialized settlement, not for owning every Plantation on the map.

## Opening priorities

Scout resources and food together. Improve the relevant tiles and ensure a city has enough population to work them without starving its development. Foragers scout and reveal opportunities; they do not build or harvest Plantations.

## Develop the engine

Review the worked assignments before ending the turn and construct Honey Exchanges where normal Market benefits and added Food are useful. Develop research infrastructure alongside the Production and Culture support.

## Convert the advantage

Protect the productive resource belt and keep assignments useful as specialists and new improvements compete for citizens. Respect the per-city cap: the fifth worked Plantation is a tile choice, not another uncapped UA tier.

## Pros

- A useful Plantation city gains steady flat Production and cultural support.
- Exchanges add ordinary trade infrastructure and a modest Food/Gold contribution.
- The resource plan is readable and does not require an active ability sequence.

## Cons and opportunity costs

- Tiles must be eligible, owned, assigned and actually worked.
- The per-city yield additions are capped and do not scale automatically with Era.
- Pillage and assignment changes can reduce the next staged bonus.

## Playing against this civ

- Threaten the actual productive Plantations and force citizens or workers away.
- Pressure cities before enough improved tiles and population exist to support the specialization.
- Use mobile raids against the resource belt rather than ignoring it in favour of a fortified centre.

## Common mistakes

- Counting owned but unworked Plantations.
- Treating a Forager as an improved Worker.
- Expecting a midturn assignment change to rewrite the already staged payout immediately.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [RomanGladius Network](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/RomanGladiusNetwork.md) | A good early Plantation site can provide practical output before an expensive Server population and staffing programme matures. |
| Opportunity | [Pigeon Republic](TheRepublicOfPigeons.md) | A protected Plantation economy can operate without outgoing caravan capacity or an external destination. |
| Threat | [Beyond the Sky](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/MasayaBeyondSky.md) | Fast land units can reach resource tiles and force repeated repairs. |
| Threat | [Jin](JinDynasty.md) | A mobile cavalry campaign can pressure the specialized countryside while the city needs those tiles worked. |

## Implementation limits

The current implementation snapshots at owner end-turn for the next payout. Interturn pillage and reassignment can differ from a literal next-turn-start count; this documented timing limitation remains.

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheHoneycombCommonwealth/README.md](../../TheHoneycombCommonwealth/README.md)
- [TheHoneycombCommonwealth/SQL/00_HCC_Core.sql](../../TheHoneycombCommonwealth/SQL/00_HCC_Core.sql)
- [TheHoneycombCommonwealth/SQL/01_HCC_Inheritance.sql](../../TheHoneycombCommonwealth/SQL/01_HCC_Inheritance.sql)
- [TheHoneycombCommonwealth/SQL/02_HCC_Effects.sql](../../TheHoneycombCommonwealth/SQL/02_HCC_Effects.sql)
- [TheHoneycombCommonwealth/SQL/03_HCC_Art.sql](../../TheHoneycombCommonwealth/SQL/03_HCC_Art.sql)
- [TheHoneycombCommonwealth/SQL/10_HCC_Text.sql](../../TheHoneycombCommonwealth/SQL/10_HCC_Text.sql)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
