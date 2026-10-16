# CODEX IMPLEMENTATION PROMPT — McPvP: The Endless Lobby

You are an expert Civilization V: Brave New World mod developer, highly experienced with Lua, XML, SQL, custom user interfaces, custom promotions, persistent game state, and the Community Patch (CP).

Implement a complete, polished, playable Civilization V civilization based on **McPvP**, the legendary Minecraft multiplayer network from the early 2010s.

## 1. Project setup

Inspect the entire repository before making modifications.

- Implement the civilization in the current repository, following its established mod structure and conventions.
- If the current repository is CoolWackyCivs2, create an appropriately isolated McPvP module within that project.
- Do not overwrite or interfere with other civilizations.
- Use Civilization V BNW and Community Patch compatibility as the development target.
- Assume Community Patch v151 compatibility where applicable.
- Prefer XML/SQL database definitions, Lua gameplay scripts, and Lua-based UI.
- Do not require custom DLL modifications.
- Use compatible, existing asset conventions where possible.
- Include proper civilization selection text, Civilopedia entries, diplomacy text, unique components, loading screen text, and icon definitions.
- Add or register all necessary files through the repository's established mod-loading structure.
- Preserve compatibility with existing saves wherever reasonably possible.

This is a complicated civilization. Do not simplify or silently remove entire systems simply because they are difficult to implement.

However, do not invent nonexistent Civ V Lua APIs. Investigate the repository and available interfaces, and implement technically sound alternatives where direct implementation is impossible.

**Important:** All gameplay systems described below must be functional, persistent, documented, and tested to the extent possible.

---

# 2. Civilization identity

**Civilization:** McPvP — The Endless Lobby

**Leader:** The Old Guard

**Capital:** Lobby One

**Unique Ability:** Just One More Game

**Unique Unit:** Veteran PvPer (Scout replacement)

**Unique Building:** Original Server Hub (Barracks replacement)

**Preferred victories:** Domination and Culture

**Personality:** Competitive, adaptive, opportunistic, and highly skilled in unconventional warfare.

## Design philosophy

McPvP must not play like a conventional conquest civilization.

Its defining identity is the Minecraft server experience:

- Choosing your favourite kits.
- Competing in Hardcore Games.
- Fighting over the Feast.
- Playing Capture the Flag.
- Using deception in Sabotage.
- Learning mechanics and outplaying opponents.
- Growing from an ordinary beginner into a highly skilled veteran.
- Returning to play another match.
- Preserving the memories of an extraordinary Minecraft era.

The player should feel as though they are managing a Minecraft PvP server within Civilization V.

The mechanical systems should integrate naturally with Civ V's existing turn-based gameplay.

Do not attempt to recreate Minecraft itself. Translate its gameplay concepts into coherent Civ V mechanics.

---

# 3. Unique Ability — Just One More Game

The civilization has access to three rotating game modes:

1. Hardcore Games
2. Capture the Flag
3. Sabotage

Implement a custom **Server Browser** interface.

The Server Browser allows the human player to choose the game mode for the upcoming match cycle.

## Match cycles

Standard game speed:

- Each match cycle lasts 20 turns.
- The selected mode becomes active at the start of the next cycle.
- A player may queue a different mode during an ongoing cycle.
- Each mode has its own objectives, rewards, and gameplay interactions.
- Match completion grants Server Legacy based on objective performance.

Scale match duration using the game's speed settings.

Suggested durations:

| Speed | Match duration |
|---|---:|
| Quick | 13 turns |
| Standard | 20 turns |
| Epic | 30 turns |
| Marathon | 60 turns |

Scale other time-based cooldowns and durations appropriately.

Avoid hardcoded assumptions about the current turn or standard speed.

## Server Browser UI

Build a usable custom interface displaying:

- Current game mode.
- Queued game mode.
- Remaining turns in the current match.
- Match-specific objective.
- Current Server Legacy.
- Lifetime Server Legacy.
- Completed matches.
- Mode victories.
- Current Feast location, where applicable.
- Relevant unit abilities.
- Current objective progress.

Use a dedicated button, popup, or established custom UI pattern already supported by the mod.

The UI must be available during regular gameplay and should not require opening the Civilopedia.

Do not use extremely frequent ContextPtr update loops or 0.1-second polling. Prefer relevant UI events, state updates, and turn-based refreshes.

Ensure the interface does not appear in inappropriate contexts such as leader diplomacy screens.

---

# 4. Hardcore Games — The Feast

Hardcore Games is McPvP's signature game mode.

Implement three phases.

## Phase I — Grace Period

At the beginning of the match:

- McPvP military units receive +10% defensive Combat Strength for 3 turns.
- Newly trained units may still select kits.
- Feast preparations begin.
- Opponents are notified that a Hardcore Games match is underway, where technically practical.

This bonus should expire reliably and not stack indefinitely.

## Phase II — The Feast

A Feast location is announced during the match.

Requirements:

1. Choose a valid land plot.
2. Avoid cities, impassable terrain, mountains, and invalid locations.
3. Prefer reasonably accessible, contestable plots.
4. Announce the Feast location three turns before it activates.
5. Provide a notification and map indication.
6. When the Feast activates, the first eligible land military unit to secure the location claims the reward.
7. Other civilizations must be able to contest the Feast.
8. Prevent the Feast from being claimed multiple times.
9. Expire the Feast after a reasonable period if nobody claims it.

The Feast should not always spawn directly beside the McPvP capital.

It must represent a meaningful military objective.

## Feast rewards

On Standard speed:

- 75 Gold.
- 20 XP to the claiming unit.
- Heal the claiming unit by 25 HP, capped at maximum health.
- 15 Server Legacy to McPvP if McPvP claims the Feast.
- An additional 10 Server Legacy if McPvP defeats an enemy military unit within two tiles of the active Feast.

Scale economic rewards appropriately for game speed and game era.

The claiming civilization must receive its normal Feast rewards even when it is not McPvP.

The location and claim status must persist across save/load.

## Phase III — Final Battle

After the Feast activates:

- McPvP units receive +20% combat XP for the remainder of the match.
- Defeating eligible enemy units grants 3 Server Legacy, capped at 15 per match.
- The match ends when its scheduled duration expires.

Display a summary of:

- Enemy units defeated.
- Whether the Feast was secured.
- Legacy earned.
- Final match result.

Do not create artificial units solely to supply opponents unless necessary for a clearly documented, balanced implementation.

The existing Civ V civilizations provide the competition.

---

# 5. Capture the Flag — The Great Capture

Create an objective-based warfare system inspired by McPvP CTF.

The goal is to infiltrate enemy territory, secure a flag, and return it to friendly territory.

## Flag acquisition

While CTF is active:

- An eligible McPvP land military unit may attempt to steal a flag from an enemy city.
- The unit must be adjacent to the enemy city.
- The civilizations must be at war.
- The target city must not already have a flag stolen from it.
- A given city can only be successfully raided once per match cycle.
- Initiating the action consumes the unit's remaining movement.

Represent the stolen flag using persistent unit state, a promotion, or another reliable mechanism.

Do not use the actual city ownership system to simulate a flag capture.

## Flag Carrier

A unit transporting an enemy flag becomes a Flag Carrier.

While carrying the flag:

- Cannot initiate attacks.
- Suffers -15% defensive Combat Strength.
- Retains its normal movement.
- Cannot steal additional flags.
- Receives a clearly visible status indicator.

If the Flag Carrier dies, the carried flag is lost and the capture attempt fails.

If practical, allow the enemy to recover the flag by defeating the carrier.

Prevent gifting, disbanding, upgrading, embarking, or other edge cases from duplicating or preserving invalid flags.

## Returning the flag

A Flag Carrier successfully scores by reaching an eligible tile within its own city's territory and performing a Return Flag action.

A successful capture grants:

- 25 Server Legacy.
- 40 Culture.
- 50 Golden Age Points.
- 15 XP to the Flag Carrier.

Scale Culture and Golden Age rewards appropriately for game speed and era.

Only one successful flag capture per enemy city per match.

Track total captures and provide a match-end summary.

## Tactical considerations

This mechanic must reward clever movement, unit preservation, positioning, and opportunity rather than simply rewarding the largest army.

If custom unit actions are technically problematic, use a reliable event-driven alternative that preserves the same requirements and restrictions.

AI-controlled McPvP must have a basic, functioning way to participate.

---

# 6. Sabotage — Trust No One

Implement a covert operations system inspired by McPvP Sabotage.

This mode focuses on deception, infiltration, detection, and disruption.

## Eligible units

Reconnaissance-class units and the Veteran PvPer may conduct Sabotage missions.

Requirements:

- Must be at war with the target.
- Must be within two tiles of the target city.
- The city must be visible to the infiltrating player.
- The target must not already be undergoing a Sabotage mission by that player.
- The unit must have sufficient movement.

## Sabotage mission

When activated:

- The unit begins a three-turn infiltration mission.
- Its movement is consumed.
- It must remain within the allowed operational area.
- Being killed or moving outside the area cancels the mission.
- The defending civilization receives a warning after the first mission turn.
- Eligible defending military units can intercept the infiltrator by eliminating it.

At completion, the target city receives:

- -20% Production for five turns.
- -15% Gold for five turns.

Use dummy buildings, compatible city modifiers, or an equivalent implementation.

The effects must expire correctly.

Do not permanently modify production buildings or underlying city yields.

## Sabotage rewards

Successful missions grant:

- 20 Server Legacy.
- 15 XP to the infiltrating unit.
- 25 Gold to McPvP.

Each enemy city can grant Legacy from one successful Sabotage mission per match.

Missions may fail if the infiltrator is eliminated or the target becomes invalid.

Show clear notifications for:

- Infiltration initiated.
- Suspicious activity detected.
- Mission interrupted.
- Sabotage successful.
- Sabotage effects expired.

The defender must have an actual opportunity to respond.

---

# 7. The Kit System

This is one of the most important McPvP mechanics.

Implement five authentic-inspired PvP kits:

1. Kangaroo
2. Stomper
3. Endermage
4. Thor
5. Viper

These must be distinct mechanical choices, not merely differently named promotions providing identical bonuses.

## Kit selection

Eligible military units trained in cities containing an Original Server Hub may select one kit.

The Veteran PvPer can select a kit without a Server Hub.

Rules:

- Exactly one kit per unit.
- Kits are mutually exclusive.
- The chosen kit persists through normal unit upgrades.
- Kits do not stack with other kits.
- Kit abilities must have appropriate cooldowns.
- Cooldowns must persist across save/load.
- Abilities must respect movement, visibility, range, ownership, and target validity.
- Prevent exploitative repeated activation using save/load or unit upgrades.

Implement either a dedicated kit selection popup or a reliable set of unit action buttons.

## Kangaroo — The Mobility Specialist

Effects:

- +1 Movement on land.
- -10% defensive Combat Strength.
- Retains normal attack rules.

Purpose: Capturing flags, repositioning, escaping danger, and chasing weakened opponents.

Do not allow the kit to bypass impassable terrain or illegally enter plots.

## Stomper — The High-Ground Assassin

Inspired by the original kit's devastating fall damage.

Effects:

- Gains an activated Stomp ability.
- Requires the unit to occupy a hill.
- Targets an adjacent enemy land military unit on lower terrain.
- Deals 20 damage to the target.
- Consumes remaining movement.
- Five-turn cooldown.

Ensure a Stomp cannot be performed against an invalid or invisible target.

Damage must respect the game's normal maximum HP and death handling.

Do not simulate this using uncontrolled movement or repeated forced combat.

## Endermage — The Master of Positioning

The Endermage can manipulate enemy positioning.

Effects:

- Activated ability with range two.
- Seven-turn cooldown.
- Select one valid enemy land military unit.
- Pull that unit onto a valid unoccupied land tile adjacent to the Endermage.
- Consume the Endermage's remaining movement.

Restrictions:

- Cannot target cities.
- Cannot target embarked, air, or naval units.
- Cannot move a unit onto impassable terrain.
- Cannot move a unit onto an occupied plot.
- Must respect domain and terrain constraints.
- Must not permit capturing cities or units through invalid teleportation.
- Handle movement and Lua event side effects safely.

If precise relocation is unsafe under CP, implement the closest reliable tactical repositioning effect and document why.

Prioritise game stability.

## Thor — The Lightning Striker

Effects:

- Activated lightning attack within two tiles.
- Five-turn cooldown.
- Deals 15 direct damage to one valid visible enemy unit.
- Consumes remaining movement.

Do not accidentally apply damage to multiple units.

Use compatible Lua unit-damage methods rather than inventing unsupported combat hooks.

## Viper — The Poison Specialist

Effects:

- Successful direct attacks inflict Poison.
- Poison deals five damage at the start of the affected unit's next two turns.
- Poison cannot stack from multiple Viper attacks.
- A new successful attack refreshes the duration.
- Poison expires automatically after its duration.

Prevent infinite damage stacking and orphaned poison state.

## Kit UI requirements

Show:

- Kit name.
- Kit description.
- Current ability cooldown.
- Valid targets.
- Whether the ability is ready.
- Why an ability cannot currently be activated.

The kit system must remain usable without requiring debug console commands.

---

# 8. Unique Unit — Veteran PvPer

Replaces Scout.

## Basic properties

- 6 Combat Strength, balanced against CP's actual Scout baseline.
- Normal Scout mobility and reconnaissance functionality.
- +25% additional combat XP.
- Can select a kit immediately.
- May change its kit once every 15 turns while inside a friendly city.
- Remains recognisable as a Veteran PvPer through upgrades.

## Kit changes

When changing kits:

- Remove the previous kit's promotions and mechanics.
- Remove any temporary effects that belong only to the old kit.
- Apply the new kit correctly.
- Reset appropriate kit cooldowns.
- Preserve normal earned promotions and XP.
- Do not allow cooldown avoidance by repeatedly changing kits.

## Veteran identity

Use a persistent Veteran promotion or reliable unit metadata.

After upgrading into another reconnaissance unit, the Veteran must retain:

- Its veteran identity.
- Combat XP modifier.
- Kit eligibility.
- Kit-changing privileges.

Prevent unintended stacking with other promotions and unit conversions.

---

# 9. Unique Building — Original Server Hub

Replaces Barracks.

Retains all standard Barracks functionality.

Additional bonuses:

- +1 Culture.
- +1 Gold.
- Units trained in the city become eligible to select a kit.
- Every eligible military unit trained grants 2 Server Legacy.

A unit may only grant its training Legacy once.

Do not grant training rewards repeatedly when units upgrade, change ownership, or reload.

Ensure the building replacement works with Community Patch balance changes.

---

# 10. Server Legacy System

Implement a civilization-wide Server Legacy resource.

This represents the popularity, achievements, memories, rivalries, and history of McPvP.

Maintain two separate values:

- Current Server Legacy.
- Lifetime Server Legacy.

Legacy is earned through:

| Activity | Legacy |
|---|---:|
| Training an eligible military unit in a Server Hub | +2 |
| Defeating an enemy military unit during Hardcore Games | +3 |
| Claiming the Feast | +15 |
| Winning a battle near the active Feast | +10 |
| Returning a stolen flag | +25 |
| Completing Sabotage | +20 |
| Winning a match | +10 |

Prevent farming through:

- Repeated combat against the same unit.
- Repeated city flag captures.
- Barbarian or summoned-unit exploitation.
- Free or duplicated units.
- Unintended recursive Lua events.

Use sensible activity caps.

## Lifetime Legacy milestones

For every 25 Lifetime Legacy:

- Grant +1 Culture per turn in the capital.

Maximum: +8 Culture per turn.

Use dummy buildings or another compatible persistent system.

Once earned, milestones are permanent and must remain functional after loading a saved game.

Current Legacy may be displayed as an available balance for future mechanics, but do not deduct or consume it arbitrarily.

The player should feel consistently rewarded for participation without gaining unlimited yields.

## Match victory definitions

Hardcore Games:
- Winning means McPvP secures the Feast.

Capture the Flag:
- Winning means returning at least one enemy flag.

Sabotage:
- Winning means completing at least one successful Sabotage mission.

Grant +10 Legacy once per winning match.

Track victories individually by game mode.

---

# 11. Information Era Event — Thanks for Playing

This is the emotional climax of the civilization.

The first time McPvP enters the Information Era, trigger a unique event.

The event must occur exactly once per game per McPvP civilization.

Display a special notification or popup:

**THANKS FOR PLAYING**

"The servers have fallen silent.

The lobbies that once held thousands now stand empty.

But the friendships, rivalries, victories and defeats remain.

A match can end.

A memory doesn't have to."

Event title:

**Legacy Unforgotten**

## Gameplay effect

Upon completion:

- Gain one permanent +10% military combat XP modifier.
- Gain an additional permanent Culture bonus in the capital.
- Bonus Culture equals floor(Lifetime Legacy / 50), capped at +10 Culture per turn.
- The bonus must be recalculated as Lifetime Legacy increases after the event.

All existing systems continue operating.

The Server Browser remains accessible.

Kit abilities remain usable.

McPvP does not collapse or lose access to gameplay.

This is an event about remembrance and continuation, not destruction.

Avoid reliance on real-world dates because Civ V's chronology differs from Minecraft history.

The event should be triggered by game progression, not the calendar year 2015.

---

# 12. AI compatibility

The civilization must be functional under AI control.

The AI is not required to use custom buttons designed for human players.

Implement sensible autonomous behaviour.

## AI game mode selection

If McPvP is AI-controlled:

- Choose a game mode automatically at the start of each cycle.
- Prefer Hardcore Games when suitable military units are available.
- Prefer CTF when at war with a reachable opponent.
- Prefer Sabotage when reconnaissance units can reach enemy cities.
- Otherwise choose a mode using a reasonable weighted distribution.

## AI kits

Assign kits automatically.

Consider unit role:

- Fast reconnaissance units → Kangaroo.
- Hill-focused melee units → Stomper.
- Frontline tactical units → Thor.
- Harassment units → Viper.
- Special tactical units → Endermage.

Allow some variety.

## AI ability usage

Implement conservative, event-driven ability decisions.

Avoid excessive map scanning or per-frame checks.

AI should only use abilities when valid and beneficial.

## AI objective participation

Provide reasonable AI logic for:

- Claiming nearby Feasts.
- Selecting flag targets.
- Returning captured flags.
- Attempting Sabotage missions.

If full tactical pathfinding cannot be implemented safely, create an appropriately constrained AI fallback rather than granting free objective completions.

Document remaining AI limitations.

---

# 13. Game-speed scaling

Ensure these systems scale appropriately:

- Match duration.
- Kit cooldowns.
- Veteran kit changes.
- Sabotage duration.
- Temporary buffs and debuffs.
- Feast preparation and expiration.
- Economic and Culture rewards.

Use the game's actual speed information rather than assuming Standard speed globally.

Combat Strength, fixed damage, movement bonuses, and percentages should generally remain consistent across speeds.

Ensure minimum cooldowns and durations cannot round to zero.

---

# 14. Persistent data and save compatibility

All gameplay systems must survive save/load reliably.

Persist:

- Current and queued game modes.
- Match cycle start/end turn.
- Current and Lifetime Legacy.
- Match results and victories.
- Active Feast location and status.
- Unit kit assignments.
- Unit ability cooldowns.
- Flag Carrier status and original target.
- City flag raid status.
- Sabotage missions and city debuffs.
- Lifetime Legacy milestones.
- Information Era event completion.
- Any other gameplay-critical flags.

Follow existing project conventions for Civ V state storage and serialization.

Do not rely on volatile Lua globals as the only source of truth.

Handle:

- Dead units.
- Captured cities.
- Eliminated civilizations.
- Reloaded saves.
- Unit upgrades.
- Invalid or removed target plots.
- Invalidated missions.
- Multiple McPvP players in the same match.

State changes should not leak between players.

Use stable identifiers and validation to avoid accidental reassignment when units are removed and IDs are reused.

---

# 15. Performance and reliability

This civilization contains many interconnected systems.

Keep the implementation efficient.

Requirements:

- Prefer event-driven gameplay logic.
- Avoid per-frame full-map scans.
- Avoid unnecessarily checking every unit every turn.
- Cache stable information where appropriate.
- Limit AI searches to relevant units and plots.
- Avoid infinite or recursive event handlers.
- Validate nil references and invalid objects.
- Do not assume the active player is McPvP.
- Avoid duplicate gameplay rewards from multiple event handlers.
- Avoid using UI-only context to execute unsynchronised gameplay state changes.

Ensure no unintended conflict with Community Patch or other civilizations' Lua scripts.

Single-player reliability is the highest priority.

For multiplayer, identify any synchronisation limitations honestly rather than claiming multiplayer safety without evidence.

---

# 16. Visuals, presentation and atmosphere

The civilization must feel nostalgic.

Use text and visual design inspired by the early Minecraft multiplayer era.

Suggested UI presentation:

- Classic Minecraft-inspired menus.
- Server selection indicators.
- Kit icons.
- Feast notifications.
- Match countdowns.
- Victory announcements.
- A final nostalgic server shutdown message.

Avoid requiring external copyrighted music or third-party assets.

If no suitable licensed art is available, use temporary original or appropriately reused in-game icons and document the asset limitations.

Implement standard Civ V presentation components:

- Civilization icon and alpha icon.
- Leader icon.
- Unit icon.
- Building icon.
- Dawn of Man loading screen.
- Diplomacy dialogue.
- Civilization description.
- Civilopedia entries.
- Unique Ability description.
- Strategy text.
- City name list.

Do not leave broken icon references or missing texture dependencies.

## Suggested city names

Lobby One, Hunger Games Arena, Feast Grounds, CTF Lobby, Sabotage Hub, Kit Arena, Veteran's Hall, Spawn Point, Deathmatch Arena, Old Spawn, Final Circle, Spectator Stand, Legacy Lobby.

---

# 17. Balance expectations

McPvP should be a strong, interesting military civilization with a genuine Culture victory alternative.

## Strengths

- Highly adaptable military units.
- Excellent tactical mobility.
- Strong skirmishing and reconnaissance.
- Opportunities to generate Culture through combat objectives.
- Veteran unit progression.
- Meaningful rewards for winning matches.

## Weaknesses

- Requires active participation to reach full potential.
- Objectives are contested or require war.
- Less reliable when isolated or at peace.
- Does not receive overwhelming passive production or science bonuses.
- Relies on careful positioning.
- Kit abilities have meaningful cooldowns.

The civilization should reward tactical skill rather than being an automatic victory against conventional civilizations.

Do not introduce enormous flat yields or unlimited stacking combat bonuses.

---

# 18. Required technical validation

Before declaring the implementation complete:

1. Review the repository's current architecture and existing civilization conventions.
2. Determine the exact XML/SQL and Lua components required.
3. Implement the complete civilization, including all database entries and gameplay handlers.
4. Register all content in the relevant mod loading structure.
5. Validate required type references and database table names.
6. Confirm Lua APIs actually exist in the supported game environment.
7. Check Lua syntax for all scripts.
8. Validate XML syntax and SQL statements.
9. Search for missing references, duplicate types, and conflicting definitions.
10. Inspect persistent state handling.
11. Inspect cooldown handling.
12. Inspect save/load behaviour.
13. Inspect unit-upgrade behaviour.
14. Inspect AI fallback functionality.
15. Inspect every game mode's rewards and expiry conditions.
16. Inspect the Server Legacy milestone calculations.
17. Inspect Information Era event execution.
18. Inspect UI callbacks and gameplay state consistency.
19. Review likely Community Patch compatibility problems.
20. Check that all required assets and localization strings are registered.

Where a test requires launching Civilization V and cannot be performed in the current environment, explicitly say it was not runtime-tested.

Do not fabricate test results.

---

# 19. Edge cases to address

Test or reason carefully about:

- The Feast spawning on inaccessible terrain.
- The Feast being claimed twice.
- A Feast disappearing after loading.
- Two eligible units reaching the Feast simultaneously.
- A flag carrier dying, upgrading, being gifted, or disbanding.
- A target city being razed or captured during a flag raid.
- A Sabotage target being captured before the mission completes.
- Poison being applied repeatedly.
- Poison killing a unit after its original attacker has died.
- Endermage attempting an invalid teleport.
- Thor causing unintentional damage to friendly units.
- A unit changing kits while its previous ability is active.
- A unit upgrading while a cooldown is running.
- Legacy being granted multiple times for one event.
- The capital being captured while Legacy milestones exist.
- The player entering the Information Era through an unusual progression event.
- Multiple McPvP civilizations existing simultaneously.
- AI McPvP using the civilization without access to the human UI.
- Matches starting when no valid objectives exist.

Fail safely when an unusual state is encountered.

Do not crash, softlock, or silently corrupt persistent data.

---

# 20. Definition of done

The implementation is considered complete only when:

- McPvP appears as a selectable civilization.
- Its Unique Ability is functional.
- All three modes have working objectives and rewards.
- The Server Browser works for human players.
- The Feast spawns, can be contested, and can be claimed.
- CTF flag stealing, carrying, and returning work.
- Sabotage missions apply and remove effects reliably.
- All five kits have distinct working abilities.
- The Veteran PvPer upgrades and maintains its identity correctly.
- The Original Server Hub provides its intended benefits.
- Server Legacy is earned, displayed, saved, and rewarded.
- The Information Era event triggers correctly.
- AI McPvP has basic functional autonomous support.
- Lua, XML, and SQL files are appropriately integrated.
- The mod does not rely on undefined functions or placeholder implementations.
- The code has been reviewed for reliability, performance, and CP compatibility.

Create a final implementation report identifying:

- Files created.
- Files modified.
- Mechanics implemented.
- Technical compromises, if any.
- Testing performed.
- Testing that requires launching Civilization V.
- Known limitations.
- Any remaining manual asset preparation.

Do not simply provide a design document or implementation suggestions.

**Actually modify the repository and implement the civilization.**

# Final creative direction

Above all, preserve the soul of McPvP.

This civilization should not be about building the largest empire or possessing the strongest army.

It is about the thrill of competition.

The feeling of choosing Kangaroo or Stomper before another Hunger Games match.

The anticipation when the Feast coordinates are announced.

The satisfaction of bringing home a flag while enemies chase you.

The thrill of mastering a kit nobody expected you to use so well.

And finally, the moment when the server shuts down, but the experiences remain with you.

The central philosophy:

**"The match ends. The memories don't."**

Implement McPvP — The Endless Lobby as a complete, nostalgic, technically sound Civilization V civilization worthy of that legacy.