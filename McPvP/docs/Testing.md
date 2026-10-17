# Validation and native checklist — 2026-10-17

## Automated verification

Run `tools/validate_mcpvp.py` for the module or `tools/validate_mod.py` for the full collection, using the repository virtual environment. The database adapter opens the installed BNW cache and CP v151 schema read-only; all test SQL executes in memory. CP source audits read the repository's pinned official source cache. The test harness executes shipped gameplay Lua under Lua 5.1 with the collection's engine double.

Passed checks:

- Actual-schema collection SQL, Scout/Barracks inheritance, promotion fields, Sabotage modifiers, dummy safeguards, localized references and SQLite integrity.
- Eighty-three native method names, critical object bindings, both complete combat callback argument lists and native route-query return semantics against CP v151; Information Era is the actual `ERA_FUTURE` type.
- Every McPvP Lua file parses as Lua 5.1; XML parses; Browser control references resolve; all 48 DDS assets decode; collection icon framing and manifest/project checks pass.
- `mcpvp_matches.lua`: Grace expiry, Feast announcement/activation, rival and McPvP rewards, single claims, all three victories, flags/return/attack restrictions, one raid/mission per city, defender warning, interruption, debuff expiry, permanent remembrance and capital relocation.
- `mcpvp_kits.lua`: five distinct kits, exclusive promotions, Veteran retraining, upgrade cooldown continuity, exact single-target damage, hill and visibility rules, legal Endermage landing, Viper combat hook/refresh/ticks/death and combat Legacy caps.
- `mcpvp_persistence.lua`: selected-save rollback, preservation of foreign ScriptData, training idempotency, free-unit exclusion, native upgrade without ScriptData copy, copied tags, stale/reused IDs, gifts, flags across reload/embarkation, capture cancellation, invalid-state refusal and all four native speeds.
- `mcpvp_ai_ui.lua`: turn-zero startup before capital founding, first-match Feast preparation, human callbacks and screen transitions, multiplayer rejection, isolated McPvP players, overlapping nonstacking debuffs, actual AI kit/flag/return/infiltration behavior, no-site fallback and no lingering update loop.
- `mcpvp_viper.lua`: the verified 15-argument ABI; melee/ranged hits, zero incoming damage, zero outgoing damage, suppressed damage, post-combat healing, dead/friendly/civilian/invalid targets, duplicate/unrelated completions, refresh, attacker death, selected-save rollback and precisely two valid ticks.
- `mcpvp_navigation.lua`: native table/row normalization, mountain and water detours, weighted fallback, occupied choke points, closed/open borders, deferred budgets, failure cooldowns, preserved native orders, route replanning and unchanged saved encoding.
- `mcpvp_objectives.lua`: reachable mode selection, actual AI Feast claims, detour flag returns, danger avoidance, no-kit carriers, reconnaissance approach/hold/completion, invalidated cities and shared army budgets.
- `mcpvp_feasts.lua`: bounded models of Tiny Islands, Small Continents, Continents, Pangaea, bridges and inaccessible territory; no full-map traversal, preparation limits, military arrival, turn-zero/no-capital behavior, multiple McPvP players, preserved pending/active saves and rival rewards.
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

## Reliability-update native pass

1. **Selection/loading:** start new games with BNW + CP v151; verify Old Guard/UU/UB selection, leader/loading art, unchanged localization, and clean Database.log/Lua.log.
2. **Browser activation:** open/close after founding and after load. Change selected units and targets; verify cooldowns, pending versus unavailable Feast status and no idle refresh loop. Test city/diplomacy/Tech Tree/policy/overview screens and nonselection modes, including missed popup events.
3. **Five kits:** choose each kit on an eligible trainee; verify exclusivity, Kangaroo land-only movement, Veteran city retraining, cooldown persistence and unchanged numeric bonuses.
4. **Viper:** test melee and ranged attacks with zero retaliation, zero outgoing damage, surviving versus killed defenders, an attacker killed by retaliation and a defender healed after combat. Inspect the one poison block, refresh and exactly two five-damage ticks. Save/reload before and between ticks.
5. **Endermage:** test valid relocation, impassable/occupied/water destinations, enemy cities and invisible/embarked targets. Verify Stomper also rejects mountain targets and Thor still damages only one selected unit.
6. **AI Hardcore:** observe announced and active Feasts across mountain/water detours and choke points. Confirm units actually occupy the site, respect expiry, replan when blocked and stop repeated failed orders.
7. **AI CTF:** steal a flag, force a detour home and block the initial route. Check safer alternatives, real return actions, no carrier attacks, ownership/peace/embark invalidation and an eligible carrier with no kit selected.
8. **AI Sabotage:** observe recon approach, valid initiation, warning and a stationary operational hold. Eliminate or displace the infiltrator; capture/raze the city. Verify success/expiry/rewards and overlapping debuffs retain the original rules.
9. **Actual map generators:** run Tiny Islands, Small Continents, Continents and Pangaea, including narrow bridges, closed borders and isolated starts. Inspect whether McPvP and at least one rival can plausibly approach. No-site results must preserve all other Hardcore phases without free victory.
10. **Objective saves:** save before announcement, while the Feast is active, carrying a flag and infiltrating. Load both this update's saves and an initial-version McPvP save; locations, ledgers and rewards must not reroll or duplicate. Discarding route caches should only cause replanning.
11. **Upgrades:** upgrade Veterans with active ability/retraining cooldowns and poisoned foreign units. Confirm identity, kit, ordinary promotions, XP and poison timing survive; flags/mission conversions follow existing invalidation rules.
12. **Remembrance:** enter Information Era normally and through an unusual progression route. Check one event, continuing matches/kits, capped capital Culture after further Legacy, permanent XP and capital relocation.
13. **AI-only/multiple McPvP:** run at least one full three-mode sequence with two McPvP civilizations. Inspect nonoverlapping Feasts, independent rewards and useful native military behavior. Test a large army for repeated path attempts or noticeable turn stalls; simulations do not measure native performance.
14. **Logs and sign-off:** inspect Lua.log and Database.log at startup, combat, objectives and reload. Record map, speed, CP build, turn, save and exact observed behavior. Keep unperformed native cases marked pending; multiplayer/hotseat remain unsupported.
