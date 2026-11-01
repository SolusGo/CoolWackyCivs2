# The Triumphal Imperium - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheTriumphalImperium/README.md)

**Leader:** Imperator Aurelion  
**Playstyle:** Victory-fed military strength and mobilisation that fade during quiet campaigns  
**Suggested victories:** Domination

Prepare a sustainable army, then chain major-civilization combat victories. Momentum starts at 0, caps at 6 and grants +2% military Strength and +4% military Production per point. A complete owner-turn cycle without a qualifying victory loses 1. Defensive victories between your turns also count.

## Opening priorities

Secure Food, Production, Iron and normal research. Build or acquire a Hall of Triumphs for Barracks experience and +1 Culture. The civilization has no unearned empire Momentum bonus: choose the first war for achievable kills rather than expecting the laurel to win it.

## Develop the engine

Support Unbroken with ranged units and replacements. They retain the active Swordsman balance and gain a permanent +10% attacking bonus. At 4 Momentum original Unbroken gain +1 Movement and Hall cities gain +10% military Production. A major conquest gives +2 Momentum once per city site and a Hall after Bronze Working.

## Convert the advantage

Use high Momentum to replace losses and exploit decisive openings. At 6 the empire has +12% military Strength and +24% military Production; a Hall adds 10 percentage points locally. Upgrade experienced Unbroken to preserve their attack promotion, while accounting for the loss of their original-type temporary movement.

## Pros

- Offensive, defensive, ranged, naval and air combat kills against major military units can sustain Momentum.
- Earned strength and native military Production reinforce successive successful campaigns.
- Captured cities receive the actual Hall once Bronze Working is known, including puppets.

## Cons and opportunity costs

- The economy, strategic resources, Happiness and technology obey normal rules.
- Quiet or unsuccessful cycles decay Momentum and can switch both threshold abilities off.
- Barbarian, City-State and civilian deaths cannot build the engine.

## Playing against this civ

- Protect exposed units and withdraw damaged armies to deny easy combat kills.
- Force pauses, threaten supply routes and exploit the loss of March below 4 Momentum.
- Use terrain and coordinated fire; the earned strength cap is only +12%, not permanent growth.

## Common mistakes

- Starting a war before assembling the units and resources to earn the first victories.
- Treating the temporary extra Movement as an immediate movement refill.
- Expecting repeated recaptures of one city to grant unlimited conquest Momentum.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [The Conical Union](TheConicalUnion.md) | An exposed network of secondary cities can offer distinct conquest targets; secured connections still support a normal defense. |
| Opportunity | [The Lantern Fleet](TheLanternFleet.md) | Capturing accessible coastal cities can establish new training centers, but naval defenders can deny safe landings. |
| Threat | [Laureate Commonwealth](TheLaureateCommonwealth.md) | A prepared defender that finishes wounded units can trade efficiently and deny a sustained imperial offensive. |
| Threat | [The Threshold Court](TheThresholdCourt.md) | Paid doorway reinforcement can make isolated city targets less vulnerable than they first appear. |

## Implementation limits

Each captured city site grants conquest Momentum once per Imperium player; recaptures still refresh victory activity and Hall eligibility. Movement activation does not refill moves. Owner-start decay uses the native PlayerDoTurn boundary, after the preceding cycle production settles. Source/database and Lua-mock checks are separate from native in-game acceptance.

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheTriumphalImperium/README.md](../../TheTriumphalImperium/README.md)
- [TheTriumphalImperium/SQL/00_TRI_Core.sql](../../TheTriumphalImperium/SQL/00_TRI_Core.sql)
- [TheTriumphalImperium/SQL/01_TRI_Inheritance.sql](../../TheTriumphalImperium/SQL/01_TRI_Inheritance.sql)
- [TheTriumphalImperium/SQL/02_TRI_Effects.sql](../../TheTriumphalImperium/SQL/02_TRI_Effects.sql)
- [TheTriumphalImperium/Lua/TRI_Gameplay.lua](../../TheTriumphalImperium/Lua/TRI_Gameplay.lua)
- [TheTriumphalImperium/Lua/TRI_Bonuses.lua](../../TheTriumphalImperium/Lua/TRI_Bonuses.lua)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
