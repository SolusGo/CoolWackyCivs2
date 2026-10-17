# CODEX PROMPT — McPvP: The Endless Lobby — Reliability & AI Improvements

Repository: https://github.com/SolusGo/CoolWackyCivs2

## Objective

Review and improve the existing McPvP civilization implementation for Civilization V: Brave New World + Community Patch v151.

McPvP has already been implemented with:

- Hardcore Games, Capture the Flag, and Sabotage.
- Five kits: Kangaroo, Stomper, Endermage, Thor, Viper.
- A custom Server Browser.
- Veteran PvPer and Original Server Hub.
- Server Legacy progression.
- Information Era remembrance.
- Persistent state and AI functionality.

**Do not recreate the civilization. Fix and enhance the existing implementation.**

Preserve every existing mechanic, reward type, balance value, progression system, and narrative feature unless a change is technically necessary to resolve a defect.

Do not modify unrelated civilizations, especially The Boundless City, The Republic of Pigeons, and Trainer Red.

## Priority 1 — Fix Viper's combat detection

Inspect:

- `McPvP/Lua/MCP_Events.lua`
- `McPvP/Lua/MCP_Kits.lua`
- `tools/tests/mcpvp_kits.lua`

The current `CombatResult` callback checks the variable `damage` to determine whether the defender received damage.

This appears incorrect: the code may be checking damage received by the attacker rather than damage inflicted on the defender.

### Required work

1. Examine the actual `CombatResult` event signature from the pinned Community Patch v151 source.
2. Identify the correct attacker and defender damage arguments and whether they represent inflicted damage, final damage, or post-combat HP.
3. Correct Viper's detection using verified event semantics.
4. Ensure poison triggers only when a Viper unit successfully damages an eligible surviving enemy military unit.
5. Support melee and ranged attacks.
6. Ensure poison does not activate when an attacker receives damage without damaging the defender.
7. Prevent friendly fire, invalid targets, duplicate poison applications, and accidental reapplication from unrelated combat callbacks.
8. Preserve the existing two-tick, five-damage poison behaviour.
9. Preserve poison persistence, refresh behaviour, and save/load functionality.
10. Ensure an already poisoned unit cannot receive multiple simultaneous poison stacks.

### Additional tests

Add cases for:

- Successful melee attack.
- Successful ranged attack where the attacker receives zero damage.
- Defender taking zero damage.
- Attacker receiving damage without damaging the defender.
- Defender dying from the original attack.
- Poison refreshing correctly.
- Attacker dying after applying poison.
- Poison surviving save/load.
- Poison expiring after precisely two valid ticks.

Update the test harness to reflect the **actual Community Patch event signature**, rather than modifying production code merely to satisfy an incorrect mock.

This is the highest-priority fix.

---

## Priority 2 — Improve AI objective pathfinding

Inspect:

- `McPvP/Lua/MCP_AI.lua`
- `McPvP/Lua/MCP_Matches.lua`

The existing AI uses simple greedy movement.

It attempts to move to an adjacent tile that decreases the direct distance to its objective.

This can cause units to become stuck when approaching obstacles.

### Required work

Improve AI movement for all three game modes.

#### Hardcore Games

AI units should:

- Recognise an announced or active Feast.
- Assess whether reaching it is practical.
- Move toward it using legal routes.
- Navigate around terrain obstacles where possible.
- Avoid repeatedly attempting impossible movement.
- Claim the Feast through the existing objective system.

#### Capture the Flag

AI units should:

- Identify reachable enemy cities.
- Travel toward appropriate raid positions.
- Steal flags using the existing rules.
- Return to friendly territory using legal routes.
- Prefer survival while carrying a flag.
- Avoid attempting to attack with a Flag Carrier.
- Avoid being trapped by simplistic direct-distance movement.

#### Sabotage

AI reconnaissance units should:

- Identify reachable targets.
- Approach within the required infiltration range.
- Start valid missions.
- Remain within the operational area.
- Avoid abandoning active missions unnecessarily.
- Respect unit eligibility, visibility, war status, and existing mission restrictions.

### Pathfinding requirements

Investigate Community Patch movement/pathfinding APIs before implementation.

Prefer a reliable native route or mission-planning method where suitable.

If native pathfinding cannot support the required decisions, implement a bounded path-search fallback with:

- Legal terrain and domain validation.
- Occupied tile handling.
- Movement-cost considerations.
- War and territory access restrictions.
- A maximum search budget.
- Replanning when conditions change.
- Detection of repeated failed movement.
- Graceful abandonment of unreachable objectives.

Do not create an expensive full-map search every turn for every unit.

Do not introduce per-frame polling.

Do not grant AI players free Feast claims, flags, or successful missions.

Retain the existing gameplay objectives and reward conditions.

### AI tests

Add scenarios involving:

- Mountains between a unit and its objective.
- Water barriers.
- Narrow passages.
- Occupied tiles.
- Multiple potential objective routes.
- Unreachable enemy cities.
- Stolen flags requiring a detour home.
- Infiltrators completing missions without leaving their valid area.
- Objectives becoming invalid during movement.

Ensure that AI improvements do not interfere with ordinary Civ V military behaviour more than necessary.

---

## Priority 3 — Improve Feast accessibility and fairness

Inspect:

- `McPvP/Lua/MCP_Matches.lua`

The Feast selection algorithm currently checks land area, revealed territory, valid terrain, neighbouring exits, and relative distance.

However, being on the same land area does not necessarily mean the Feast is reasonably accessible.

### Required work

Improve Feast placement so that the selected objective is both valid and meaningfully contestable.

Prioritise locations that:

1. Are accessible to McPvP through a valid land route.
2. Have reasonable access for at least one rival civilization where possible.
3. Are not surrounded by impassable terrain.
4. Are not blocked behind unavoidable inaccessible territory.
5. Are not directly adjacent to the McPvP capital.
6. Have several viable approaches where the map allows.
7. Do not overlap another active McPvP Feast.
8. Preserve the existing 4–16 tile preferred distance from McPvP's capital.

### Accessibility scoring

Consider:

- Approximate reachable path distance.
- Number of accessible approaches.
- Nearby rivals.
- Distance from friendly and enemy settlements.
- Terrain obstacles.
- Whether suitable military units can realistically reach the site during the active Feast window.

A Feast does not need to be equally accessible to every civilization. Rival competition should be encouraged, not guaranteed artificially.

Preserve the original idea that the Feast may be risky or strategically difficult to secure.

### No-valid-location handling

If no acceptable Feast location exists:

- Fail gracefully.
- Do not spawn an invalid objective.
- Continue the Hardcore Games match.
- Preserve Grace Period and Final Battle mechanics.
- Do not award a fake Feast victory.
- Provide an understandable notification.
- Avoid endless repeated location searches.

Ensure the Feast still activates, expires, and pays rewards using the existing rules.

### Tests

Include:

- Tiny Islands.
- Small Continents.
- Continents.
- Pangaea.
- Narrow land bridges.
- Unexplored starting regions.
- No capital at turn zero.
- Multiple McPvP civilizations.
- Save/load before announcement.
- Save/load while the Feast is active.
- Rival civilization claiming the Feast.

Do not introduce excessive map-wide scans.

---

## Priority 4 — Review gameplay integration and persistence

After completing the three primary fixes, perform a targeted reliability audit.

Review interactions involving:

### Kit system

- One kit per unit.
- Kit cooldown persistence.
- Veteran kit switching.
- Upgraded Veterans retaining their identity.
- Endermage destination legality.
- Stomper terrain validation.
- Thor single-target damage.
- Kangaroo movement bonuses.
- Viper combat and poison handling.

### Match system

- Correct match duration on all game speeds.
- Queued modes activating at the next cycle.
- Match victory only being awarded once.
- No duplicate Server Legacy rewards.
- Flags becoming invalid when carriers die, upgrade, embark, or change ownership.
- Sabotage missions being cancelled correctly.
- Temporary Sabotage penalties expiring properly.
- No lingering temporary promotions between matches.

### Server Legacy

- Current and Lifetime Legacy remaining consistent.
- Training rewards being issued only once.
- Appropriate reward caps.
- Capital Culture bonuses remaining capped.
- Capital relocation preserving earned bonuses.
- Information Era remembrance triggering exactly once.
- Remembrance bonuses continuing to scale correctly after the event.

### Interface

- Server Browser opening reliably.
- Buttons correctly reflecting available actions.
- Invalid targets being rejected.
- Correct cooldown text.
- Accurate Feast status.
- No UI-related FPS degradation.
- Correct behaviour after unit selection changes.
- Proper hiding during diplomacy and incompatible screens.

Do not unnecessarily rewrite systems that already pass inspection.

---

## Priority 5 — Automated validation

Run the repository's existing tests, including:

- `tools/validate_mcpvp.py`
- `tools/validate_mod.py`
- Existing McPvP gameplay simulation suites.
- Existing civilization regression suites.

Add targeted regression tests for each issue fixed.

Also verify:

- Lua 5.1 compatibility.
- Community Patch v151 event/API compatibility.
- SQL schema validity.
- XML correctness.
- Modinfo integration.
- UI loading and callback registration.
- Save-state serialization.
- No unintended modifications to unrelated modules.

If the testing environment lacks required dependencies, report that limitation rather than pretending tests passed.

If tests detect additional genuine implementation bugs, fix them while preserving intended functionality.

Do not weaken assertions or change tests solely to make failures disappear.

---

## Priority 6 — Native testing readiness

Automated simulations do not prove that the mod works inside Civilization V.

Prepare an updated native testing checklist covering:

1. Civilization selection and initial loading.
2. Server Browser activation.
3. Choosing all five kits.
4. Melee and ranged Viper poison.
5. Endermage relocation.
6. AI pathfinding during Hardcore Games.
7. AI returning a stolen flag.
8. AI Sabotage missions.
9. Accessible Feast placement across different maps.
10. Saving and loading during active objectives.
11. Veteran upgrading while kit cooldowns are active.
12. Information Era remembrance.
13. AI-only games with multiple McPvP civilizations.
14. Lua.log and Database.log inspection.

Explicitly distinguish automated tests from actual native Civ V gameplay tests.

Do not claim successful native testing unless Civilization V was actually launched.

---

# Implementation constraints

**Very important:**

- Preserve all existing gameplay mechanics.
- Preserve all existing numerical balance values unless required for correctness.
- Do not simplify the civilization.
- Do not remove systems.
- Do not change the intended identity of McPvP.
- Do not change the existing collection UUID.
- Preserve existing save compatibility whenever possible.
- Avoid changing persistent state formats.
- If state migration is unavoidable, implement safe backward compatibility.
- Do not modify unrelated civilizations.
- Do not add DLL dependencies.
- Do not introduce costly frame-by-frame Lua polling.
- Keep Community Patch v151 compatibility.
- Preserve the existing original artwork and localization.

Maintain the current modular implementation.

# Definition of done

The task is complete when:

1. Viper correctly detects actual damage inflicted on enemies.
2. Melee and ranged poison behaviour is regression-tested.
3. AI units can handle ordinary terrain obstacles while pursuing objectives.
4. AI objective movement has safe failure and replanning behaviour.
5. Feast placement evaluates meaningful accessibility rather than only geometric distance.
6. Existing mechanics still behave as designed.
7. Automated test suites pass, or remaining failures are clearly explained.
8. Existing save compatibility is preserved.
9. The implementation documentation reflects actual behaviour.
10. Remaining native runtime limitations are explicitly documented.

# Final report

After making the changes, provide:

- Files modified.
- Bugs confirmed.
- Bugs fixed.
- AI pathfinding changes.
- Feast placement improvements.
- Tests added.
- Validation results.
- Save compatibility impact.
- Remaining limitations.
- In-game testing instructions.

**Do not stop at an analysis or implementation proposal. Make the necessary code changes.**

The goal is to turn McPvP from a substantial initial implementation into a robust, reliable civilization ready for extensive single-player testing.

Preserve its defining philosophy:

**"The match ends. The memories don't."**