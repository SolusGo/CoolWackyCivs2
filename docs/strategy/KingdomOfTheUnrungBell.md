# Unrung Bell - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../KingdomOfTheUnrungBell/README.md)

**Leader:** Keeper Sable  
**Playstyle:** Peaceful accumulation followed by a limited territorial response  
**Suggested victories:** Culture or Science

Build Quietude during genuine peace, develop Belfry cities, and use the Great Toll to survive the first part of a war. The economy and combat reserve are different phases: war consumes the peaceful yields instead of leaving both active.

## Opening priorities

Develop food, defense and cities that will make per-city Quietude useful. Avoid an unnecessary major or City-State war while building the peaceful counter. Barbarians do not break it.

## Develop the engine

Build Belfries in productive cities and protect the peace long enough to earn the desired stacks. Keep a standing army: a full counter does not make ordinary defenders invulnerable.

## Convert the advantage

When war begins, defend purposefully during the Toll and plan for its expiry. Further declarations in the same continuous war do not refill it. Make complete peace when rebuilding Quietude fits the strategic situation.

## Pros

- Peaceful stacks add Culture across the empire and Science in Belfry cities.
- Bellwarden territorial support can survive normal upgrades.
- A prepared Toll can buy time at the start of a dangerous conflict.

## Cons and opportunity costs

- A qualifying war removes the peaceful economic stacks.
- The Toll has a finite window and cannot be renewed by adding another war.
- Repeated or continuous hostility prevents a fresh peaceful reserve.

## Playing against this civ

- Avoid your main assault during the strongest initial Toll if time is on your side.
- Keep meaningful pressure after the temporary response expires.
- Use sustained economic or territorial threats rather than donating easy fights to a prepared defensive line.

## Common mistakes

- Assuming Quietude remains active alongside wartime Toll bonuses.
- Declaring extra wars to refresh the same Toll.
- Confusing native friendly-land combat with an exclusively defensive or exactly owned-target-only rule.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [The Urgal](TheUrgal.md) | A prepared territorial reserve can help stall a short Strength II offensive until its attacking window ends. |
| Opportunity | [Beyond the Sky](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/MasayaBeyondSky.md) | Pikeman-derived units and a prepared friendly-land line can make an unsupported mounted rush expensive. |
| Threat | [Sol Intellect](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/SolIntellect.md) | A protected specialist and construction economy can put pressure on a passive research race. |
| Threat | [Viltrum](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/ViltrumEmpire.md) | An extended conquest campaign can continue after the Toll expires and prevent Quietude from rebuilding. |

## Implementation limits

The implementation uses CP's native friendly-land modifier, including its attack/defense and territorial interpretation; the more exclusive original design condition is not claimed.

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [KingdomOfTheUnrungBell/README.md](../../KingdomOfTheUnrungBell/README.md)
- [KingdomOfTheUnrungBell/SQL/00_UNRUNG_Core.sql](../../KingdomOfTheUnrungBell/SQL/00_UNRUNG_Core.sql)
- [KingdomOfTheUnrungBell/SQL/01_UNRUNG_Inheritance.sql](../../KingdomOfTheUnrungBell/SQL/01_UNRUNG_Inheritance.sql)
- [KingdomOfTheUnrungBell/SQL/02_UNRUNG_Effects.sql](../../KingdomOfTheUnrungBell/SQL/02_UNRUNG_Effects.sql)
- [KingdomOfTheUnrungBell/SQL/03_UNRUNG_Art.sql](../../KingdomOfTheUnrungBell/SQL/03_UNRUNG_Art.sql)
- [KingdomOfTheUnrungBell/SQL/10_UNRUNG_Text.sql](../../KingdomOfTheUnrungBell/SQL/10_UNRUNG_Text.sql)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
