# T1 - The ZOFGK Dynasty

**Faker** leads a human-only Civilization V: Brave New World civilization requiring **Community Patch v151**. It is part of Cool Wacky Civs 2, not a standalone mod. Start a new game and choose T1; AI random selection excludes it. Capital: **T1 HQ**. Preferred victories: Domination, then Culture. Complexity: **4/5**.

The historical Zeus/Oner/Faker/Gumayusi/Keria roster reached the 2022 Worlds final and won consecutive World Championships in 2023 and 2024. This civilization commemorates that lineup rather than presenting it as the current team.

## Five Legends. One Dynasty.

The first five locally created T1 Recruits automatically take **Zeus, Oner, Faker, Gumayusi, Keria**, in that order. The starting Warrior replacement counts. Purchases count toward this initial roster. Each individual retains its role through upgrades.

| Role | Effect |
| --- | --- |
| Zeus | +15% Strength when attacking cities |
| Oner | +1 Sight; native double Forest/Jungle movement |
| Faker | Hostile military units within one hex suffer -10% Strength |
| Gumayusi | +15% Strength when attacking wounded enemy military units |
| Keria | Adjacent friendly military units add 5 HP to otherwise legal normal healing; excludes himself |

Only living roster units receive **Five as One**. Count distinct roles within two hexes, including the unit itself: one or two gives nothing; three or four gives +10% Strength; five gives +15% instead. Normal troops never count. Map distance also applies while embarked, carried or stationed in cities.

## Develop the recruits

**T1 Recruit** replaces Warrior, inheriting the active Warrior's strength, moves, cost, training requirements, normal promotions and upgrade destinations. No replacement 3D model is needed.

Every Recruit has **Scouted Talent**, adding 15% combat experience. **Legendary Development** adds another permanent **4% Strength per genuine unit-type upgrade**. One upgrade gives +4%, seven gives +28%, eight gives +32%, and so on. Level-ups and promotion choices give no development. The current cumulative tier appears in the promotion tooltip and roster panel. Non-roster Recruits develop as well.

Death loses that veteran's XP and history. New units cannot inherit it. Upgrading a living member does not create a vacancy.

## Headquarters and successors

**T1 Headquarters** replaces Barracks and retains its normal experience and companion effects. Adds **1 Culture** and **10% local Production toward land melee military units**. Native per-unit building modifiers include eligible modded classes and exclude ranged/defensive-only units. They handle switching queues and overflow; Lua never grants Production.

A lost, deleted, disbanded or gifted-away member leaves a saved vacancy. Wait **7 / 10 / 15 / 30 turns** on Quick / Standard / Epic / Marathon. The next **newly produced land melee military unit in an owned city with a real Headquarters** inherits the available role. Purchases, gifts, captures, civilians, ranged, naval and defensive-only units cannot replace a lost member. If several vacancies are ready, Z-O-F-G-K priority applies. No free units spawn.

A successor inherits only the role. A successor trained as a Recruit keeps its own Scouted Talent; it receives none of the deceased unit's XP, upgrades or promotions.

The **ZOFGK Roster** launcher on the right of the map opens a compact summary of all five slots, current development/formation bonuses and remaining cooldowns. Notifications announce recruitment, losses and readiness.

## Strategy

Train the original five early, protect them with supporting troops and save Gold for upgrades. Zeus pressures cities, Oner scouts and rotates, Faker weakens a battlefront, Gumayusi finishes wounded targets and Keria sustains the formation. Retreating a wounded veteran can be more valuable than winning one additional attack. A scattered or under-teched roster remains vulnerable. Headquarters help rebuild after a loss, but cannot recreate a veteran's history.

## Validation and limits

See [Implementation](docs/Implementation.md), [Testing](docs/Testing.md), [validation report](docs/Validation.json) and [art provenance](../art-source/T1ZOFGK/README.md).

Gameplay state is stored in native promotions and namespaced ScriptData. No permanent frame polling or shared CityView changes are used. Ordinary city recruits are assigned immediately after native training; other free Recruit births settle at the next owner turn boundary so native conversion/capture initialization can finish.

CP direct captures expose the source but no destination-ID callback. An unproven birth at the exact capture site on the same turn is conservatively excluded from initial recruitment, including recaptures of an originally local unit. A genuine CityTrained event proves local production/purchase and clears that guard. This can also exclude a scripted free Recruit spawned at that exact site and turn. It does not affect normal training, starting units or goody recruits elsewhere.

Production eligibility is derived from unit definitions and free promotions when the mod database activates. Units added by other mods after this collection's SQL need load-order review. The development tier bound is audited against the actual upgrade graph; it is not a 28% cap.

**Native gameplay, rendering and save-file acceptance remain untested.** Automated SQL/source/Lua simulations do not replace those tests. Multiplayer, hotseat and Mac remain unsupported by the collection.
