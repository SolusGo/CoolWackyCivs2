# McPvP - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../McPvP/README.md)

**Leader:** The Old Guard  
**Playstyle:** Objective warfare, mobility and persistent Server Legacy  
**Suggested victories:** Domination or Culture

Choose a mode that matches the map and army, complete one legal objective, and carry the resulting Legacy into later matches. Winning a field battle is useful, but the mode's explicit objective determines its special payoff.

## Opening priorities

Scout approaches and read the default Hardcore Games timer. Develop a real military and production base before chasing an announced Feast. A rival's eligible unit can claim it too.

## Develop the engine

Queue the next mode around achievable routes. In CTF, plan both the theft and the safe return; in Sabotage, retain visibility and the required infiltration position. Choose kits and support units for the actual objective instead of only for damage.

## Convert the advantage

Use accumulated Legacy and repeated successes to support the chosen victory. Keep a backup plan for a failed objective and protect conventional cities while mobile units are away from the main front.

## Pros

- Mode choice creates different tactical routes to lasting rewards.
- Kits and objective actions give mobile units several useful jobs.
- Legacy persists beyond one match rather than resetting the entire campaign.

## Cons and opportunity costs

- Objectives have specific visibility, position, movement and timing restrictions.
- Flag carriers cannot attack and are easier to punish on the return route.
- Infiltration can be interrupted and a Feast is contested rather than reserved for McPvP.

## Playing against this civ

- Defend likely flag return routes as well as the city where a flag was stolen.
- Remove or force away a revealed infiltrator before the timer completes.
- Contest the Feast only when the terrain and army make it a good fight.

## Common mistakes

- Changing the queued mode and expecting the current match to restart.
- Stealing a flag without a safe legal return route.
- Treating an announced Feast as an automatic reward or a partial infiltration as a completed objective.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Sol Intellect](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/SolIntellect.md) | A successful infiltration can disrupt a productive builder while forcing defense around valuable construction cities. |
| Opportunity | [RomanGladius Network](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/RomanGladiusNetwork.md) | Mobile pressure on large economic cities can tax staffing money and exploit a defense spread among several Servers. |
| Threat | [The Last City](https://github.com/SolusGo/CoolWackyCivs/blob/main/docs/strategy/TheLastCity.md) | A concentrated defended approach makes unobserved city objectives and safe return routes harder to obtain. |
| Threat | [The Threshold Court](TheThresholdCourt.md) | A working House network can place a defender near a distant objective before a travelling raider expects reinforcement. |

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [McPvP/README.md](../../McPvP/README.md)
- [McPvP/SQL/00_MCP_Core.sql](../../McPvP/SQL/00_MCP_Core.sql)
- [McPvP/SQL/01_MCP_Inheritance.sql](../../McPvP/SQL/01_MCP_Inheritance.sql)
- [McPvP/SQL/02_MCP_Effects.sql](../../McPvP/SQL/02_MCP_Effects.sql)
- [McPvP/SQL/03_MCP_Art.sql](../../McPvP/SQL/03_MCP_Art.sql)
- [McPvP/SQL/10_MCP_Text.sql](../../McPvP/SQL/10_MCP_Text.sql)
- [McPvP/Lua/MCP_Core.lua](../../McPvP/Lua/MCP_Core.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
