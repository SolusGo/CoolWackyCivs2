# The Twelfth Hour - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheTwelfthHour/README.md)

**Leader:** The Keeper of Seconds  
**Playstyle:** Developed-city industry and a synchronized six-turn economy  
**Suggested victories:** Science; production-led Domination

Build cities whose normal output is worth multiplying, then plan important work around the Grand Chime. The fixed six-played-turn cadence is an empire schedule; it does not restart when you found a city.

## Opening priorities

Develop workable food and production, establish safe expansion, and note the next Chime. Do not leave a city idle just to make a completion look synchronized; productive normal turns still matter.

## Develop the engine

Build Clocktowers where their inherited industrial role is useful. Time expensive construction and a healthy science base around the global cadence, and use Pendulum Guards to protect the cities that make the timing valuable.

## Convert the advantage

Turn repeated industrial and research bursts into the normal requirements of your chosen victory. Retain a usable standing army between Chimes, when there is no direct temporary combat-strength reward from the clock itself.

## Pros

- A Chime benefits every currently owned city.
- Developed baseline output makes percentage bursts more valuable.
- Clocktowers and mobile territorial defenders support industrial consolidation.

## Cons and opportunity costs

- Five of each six played turns are ordinary turns.
- The clock does not by itself provide food, expansion safety or a permanent combat bonus.
- A weak or suppressed city has little healthy output for a burst to multiply.

## Playing against this civ

- Pressure production centres between Chimes and disrupt the jobs supporting their normal output.
- Do not mistake a production spike for an immediate universal military-strength buff.
- Force spending on defense before an important scheduled construction push.

## Common mistakes

- Resetting plans as if founding or reloading restarted the clock.
- Assuming named game speeds change the six-turn cadence.
- Delaying necessary infrastructure or defense merely to wait for a Chime.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Luna Network](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/LunaNetwork.md) | A mature developed-city economy can contest sustained production through synchronized bursts; it must first survive Luna's earlier tempo. |
| Opportunity | [The Republic of First Drafts](TheRepublicOfFirstDrafts.md) | A major Wonder or expensive-construction race can favour a prepared Chime, while Marginalia's class reward excludes Wonders. |
| Threat | [The Filthy Realm](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/FilthyRealm.md) | Economic disruption timed before a scheduled burst can reduce the output and construction readiness it was meant to exploit. |
| Threat | [The Urgal](TheUrgal.md) | A positioned attacking force can pressure cities during the long interval between economic bursts. |

## Implementation limits

The schedule uses played turns and the implemented staging model. Native yield settlement and rendering still require the civilization's documented live acceptance checks.

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheTwelfthHour/README.md](../../TheTwelfthHour/README.md)
- [TheTwelfthHour/SQL/00_TWELFTH_Core.sql](../../TheTwelfthHour/SQL/00_TWELFTH_Core.sql)
- [TheTwelfthHour/SQL/01_TWELFTH_Inheritance.sql](../../TheTwelfthHour/SQL/01_TWELFTH_Inheritance.sql)
- [TheTwelfthHour/SQL/02_TWELFTH_Effects.sql](../../TheTwelfthHour/SQL/02_TWELFTH_Effects.sql)
- [TheTwelfthHour/SQL/03_TWELFTH_Art.sql](../../TheTwelfthHour/SQL/03_TWELFTH_Art.sql)
- [TheTwelfthHour/SQL/10_TWELFTH_Text.sql](../../TheTwelfthHour/SQL/10_TWELFTH_Text.sql)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
