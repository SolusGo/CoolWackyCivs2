# The Threshold Court - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheThresholdCourt/README.md)

**Leader:** Queen Elsewhere  
**Playstyle:** A paid defensive reinforcement network between owned cities  
**Suggested victories:** Science or supported Domination

Build Houses in useful cities and use the network to move an existing melee defender where distance would otherwise be decisive. One crossing per turn and arrival exhaustion make this a reinforcement tool, not an instant attacking swarm.

## Opening priorities

Develop at least two viable cities with an ordinary economy and defense. The network does not begin with free Houses. Plan endpoints around cities worth protecting and reserve the Gold needed for an emergency crossing.

## Develop the engine

Keep a mobile eligible unit at a ready origin and an empty military slot at the intended destination. Rotate departures among cities as origin cooldowns permit. Hingeguards support territorial defense while normal units cover ranged, siege and naval roles.

## Convert the advantage

Use the network to maintain distant fronts without abandoning local support. Send a unit before its offensive action is needed, because arrival consumes movement and attacks until the next originating owner-turn.

## Pros

- A valid crossing has no distance or ordinary pathfinding limit.
- The same existing unit retains its identity and experience.
- Several origins can support a rotating long-distance defense.

## Cons and opportunity costs

- The empire gets only one successful crossing per owner-turn.
- Origins recharge, Gold is required, and an occupied destination is unavailable.
- Only eligible land melee military units qualify; arrival is exhausted.

## Playing against this civ

- Pressure several cities at once or use a sustained siege that one arrival cannot solve.
- Threaten the treasury and approach before Houses are established.
- Use ranged, naval and logistical pressure instead of assuming every threatened city is isolated.

## Common mistakes

- Blocking the destination with a combat unit while expecting another to arrive.
- Trying to send a civilian, ranged or siege unit.
- Planning an immediate attack or upgrade by the exhausted arrival.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Beyond the Sky](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/MasayaBeyondSky.md) | A distant city can receive a defender without travelling the route a fast raider expected to exploit. |
| Opportunity | [McPvP](McPvP.md) | A timely arrival can contest an objective city or return approach before a mobile raider completes the plan. |
| Threat | [Luna Network](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/LunaNetwork.md) | Several simultaneous fronts can exceed the single-crossing limit. |
| Threat | [The Filthy Realm](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/FilthyRealm.md) | A city-focused shutdown or economic disruption can tax the Gold and local support on which reinforcement depends. |

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheThresholdCourt/README.md](../../TheThresholdCourt/README.md)
- [TheThresholdCourt/SQL/00_THC_Core.sql](../../TheThresholdCourt/SQL/00_THC_Core.sql)
- [TheThresholdCourt/SQL/01_THC_Inheritance.sql](../../TheThresholdCourt/SQL/01_THC_Inheritance.sql)
- [TheThresholdCourt/SQL/02_THC_Effects.sql](../../TheThresholdCourt/SQL/02_THC_Effects.sql)
- [TheThresholdCourt/SQL/03_THC_Art.sql](../../TheThresholdCourt/SQL/03_THC_Art.sql)
- [TheThresholdCourt/SQL/10_THC_Text.sql](../../TheThresholdCourt/SQL/10_THC_Text.sql)
- [TheThresholdCourt/Lua/THC_Core.lua](../../TheThresholdCourt/Lua/THC_Core.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
