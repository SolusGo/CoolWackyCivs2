# Urgal implementation

One `InGameUIAddin`, `UI/URGAL_Potions.xml`, owns the simulation through its same-named Lua file and `URGAL_Core` / `URGAL_AI` includes. Database identities, VFS basenames and `MapModData.URGAL` are isolated. A retired context removes its event handlers and marks callbacks inactive. Shutdown of an old context cannot invalidate its successor. The panel refreshes on events and coalesces dirty signals with a one-shot update; it does not poll every frame. City screens, diplomacy, popups, interface modes, inactive turns and hidden contexts suppress it; click handling revalidates availability.

Persistent authority is in player and unit ScriptData, serialized with the game:

- Player `[URGAL_P1:potions:lastEra:finishTurn:readyTurn:serial]` records inventory, Era high-water mark and absolute effect/Aftertaste deadlines.
- Each participating unit has `[URGAL_U1:owner:serial:finishTurn]`. No transient list is required to reconstruct a window after loading. Other mods' ScriptData is retained byte for byte around these markers.
- Bootstrap rechecks unit eligibility and reconstructs promotions from those records. Numeric overflow/corrupt records fail closed. No default inventory is granted to a recognized but invalid player record.

On a new game, one bottle is granted at the first bootstrap and the starting Era is recorded. `TeamSetEra` awards the difference to all matching Urgal teammates immediately, using the event Era as well as the player's Era. `PlayerDoTurn` supplies a missed-event fallback. Entering earlier Eras or duplicate events cannot replenish inventory. Advanced starts do not award bottles for Eras never entered during play.

Drinking writes the consumed inventory and new deadline first, then writes a marker on each currently eligible unit, including embarked participants. Native promotions are applied only while unembarked. Strength uses `AttackMod=50`, with `CityAttack=-50` cancelling the attack bonus against cities. Promotion selection is disabled. No generic CombatPercent or defense modifier is used. Only melee land units receive it, so the native AttackMod's ranged behavior cannot grant a ranged bonus. Percentages combine additively with other native modifiers.

Pot Chaser is a permanent marker (`LostWithUpgrade=0`). An additional temporary promotion supplies `HPHealedIfDestroyEnemy=15` only while the unit has Strength II and Pot Chaser. CP's native post-kill handler applies it once and clamps at missing health. No Lua damage simulation, forced movement, extra attacks or duplicate kill callbacks are required. Other engine healing restrictions remain effective.

Unit creation clears temporary participation; it cannot join an existing window. `UnitConverted` follows native promotion copying and precedes source-unit destruction in CP v151. A same-owner normal upgrade transfers the old unit's matching serial/deadline to the eligible replacement. Other conversions clear it. Temporary promotions are lost on native gifting/upgrading and explicitly reconstructed only for eligible participants. Movement reconciliation suspends effects while embarked and restores a participant on disembarkation before the unchanged deadline. Permanent Pot Chaser remains with its veteran.

The Brewing Stand copies active Barracks scalar and companion data, fixing its requested cost/maintenance and retaining supported baseline XP. Production uses `Unit_ProductionModifierBuildings` for each eligible unit type, rather than a combat-class-wide bonus that might include ranged hybrids. The SQL and Lua share the domain, combat, ranged and excluded-class predicates. Units loaded after this collection's database actions cannot be automatically added to those precompiled production rows; mod ordering can resolve that case.

Rusher scalar values explicitly match the supplied design (14 strength, 2 movement, 80 cost); active companion rows and native models are inherited. SQL compilers enumerate the installed schema and use runtime `SELECT *` cloning so new scalar columns survive. The collection keeps its UUID and earlier insertion order; Urgal is appended after Unrung Bell. Existing civilization files and save identities are preserved. Native continuation of older collection saves has not been verified.

The AI only uses visible, non-invisible opponents at war, requires at least three ready eligible units near one engagement and a legal adjacent attack, then evaluates local enemy counts, an adjacent city or invasion. Radius-three scans and a 48-anchor ceiling bound work. This is a local activation heuristic, not a replacement tactical AI or a guarantee of optimal potion use.

See [Validation.json](Validation.json) for pinned CP source URLs/hashes and the exact audited contracts. These establish source behavior; [Testing.md](Testing.md) records what still requires the native engine.
