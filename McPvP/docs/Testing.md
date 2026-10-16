# Validation and native checklist — 2026-10-17

## Automated verification

Run `tools/validate_mcpvp.py` for the module or `tools/validate_mod.py` for the full collection, using the repository virtual environment. The database adapter opens the installed BNW cache and CP v151 schema read-only; all test SQL executes in memory. CP source audits read the repository's pinned official source cache. The test harness executes shipped gameplay Lua under Lua 5.1 with the collection's engine double.

Passed checks:

- Actual-schema collection SQL, Scout/Barracks inheritance, promotion fields, Sabotage modifiers, dummy safeguards, localized references and SQLite integrity.
- Seventy-one native method names, critical object bindings and event signatures against CP v151; Information Era is the actual `ERA_FUTURE` type.
- Every McPvP Lua file parses as Lua 5.1; XML parses; Browser control references resolve; all 48 DDS assets decode; collection icon framing and manifest/project checks pass.
- `mcpvp_matches.lua`: Grace expiry, Feast announcement/activation, rival and McPvP rewards, single claims, all three victories, flags/return/attack restrictions, one raid/mission per city, defender warning, interruption, debuff expiry, permanent remembrance and capital relocation.
- `mcpvp_kits.lua`: five distinct kits, exclusive promotions, Veteran retraining, upgrade cooldown continuity, exact single-target damage, hill and visibility rules, legal Endermage landing, Viper combat hook/refresh/ticks/death and combat Legacy caps.
- `mcpvp_persistence.lua`: selected-save rollback, preservation of foreign ScriptData, training idempotency, free-unit exclusion, native upgrade without ScriptData copy, copied tags, stale/reused IDs, gifts, flags across reload/embarkation, capture cancellation, invalid-state refusal and all four native speeds.
- `mcpvp_ai_ui.lua`: turn-zero startup before capital founding, first-match Feast preparation, human callbacks and screen transitions, multiplayer rejection, isolated McPvP players, overlapping nonstacking debuffs, actual AI kit/flag/return/infiltration behavior, no-site fallback and no lingering update loop.
- Existing Boundless, Pigeon and Red regression suites, clean optional-metadata compatibility, namespace coexistence and release package validation remain part of the collection check.

These are simulations and file/source checks. **Civilization V has not been launched for this implementation.** They do not prove native rendering, real tactical/pathfinding behavior, native save round trips or multiplayer synchronization.

## Native Civ V checks still required

1. Enable BNW, CP v151 and this collection. Start a new Standard-speed game as The Old Guard. Verify leader selection, city names, dawn art, diplomacy, Civilopedia, UU/UB icons, full Barracks benefits and Lua/database logs.
2. Found Lobby One. Open Server Browser, switch selected units and cycle kit/objective targets. Verify long text at 1366×768 and larger resolutions. Open diplomacy, cities, tech/policy screens and popups; confirm the panel and launcher hide appropriately and recover. Select targets again after a movement/death event to check stale-action refusal.
3. Play through three full matches. Queue each next mode mid-cycle, save just before a boundary and reload. Confirm one summary, one completion count and at most one victory award. Repeat on Quick, Epic and Marathon.
4. Verify Grace expiry, three-turn Feast announcement, notification map location, activation, rival claims, healing cap, XP/Gold scaling, exactly one claim, near-Feast kill cap and unclaimed expiry. Save/reload before and after activation and claim. Test map isolation and no valid sites.
5. At war, steal adjacent to a city; verify no attacks, including ranged/Blitz. Try ordinary upgrade, goody upgrade, gift, disband and embark. Verify city capture/razing, peace, carrier death, forced conversion and cycle expiry lose the flag. Return on an owned city tile and an owned noncity working tile. Verify no repeat raid on the same city that cycle.
6. Infiltrate with a Veteran and ordinary recon unit. Give the defender time to eliminate it after the warning. Move outside range, upgrade or change city ownership to cancel. Complete and verify actual -20% Production/-15% Gold modifiers, native city-turn timing, one reward and complete removal after five scaled turns. Test overlapping attackers and a razed city.
7. Train/purchase land and nonland military units in Hubs; confirm +2 Legacy exactly once and land-kit eligibility. Create free units and upgrade/capture/gift units; confirm no training reward. Compare full active CP Barracks experience and maintenance.
8. Exercise each kit against a valid and invalid target, with zero moves and during cooldown. Check all five are mutually exclusive. Upgrade a Veteran with a running cooldown and compare XP, earned promotions, identity and kit-changing rights. Try Endermage against water, mountains, occupied landing tiles, hidden/embarked units and city occupants. Verify direct-damage kills and Viper poison across save/load and attacker death.
9. Reach each Lifetime milestone, then enter Information Era by research and an advanced start/progression tool. Confirm one remembrance notification and +10% XP for existing/new military units. Raise Legacy afterward; verify additional Culture grows to +10, total capital bonus caps at +18 and follows a new capital after loss. Save/reload after the event.
10. Run AI-only games with one and two McPvP civilizations. Observe mode choices, kit distribution, movement, real Feast claims, flag returns and missions. Check elimination cleanup and that other civilizations retain normal behavior. Inspect Lua.log and Database.log throughout.

Native multiplayer, hotseat and Mac are unsupported. No successful native test or multiplayer synchronization result is claimed.
