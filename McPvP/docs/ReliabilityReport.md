# McPvP reliability and AI report — 2026-10-17

This updates the existing civilization. All three modes, five kits, reward amounts/caps, unit/building benefits, Legacy milestones, remembrance text, artwork and localization are preserved. The collection UUID, version 7 and native save version are unchanged. Other civilizations' source files are outside this change.

## Confirmed defects and fixes

| Finding | Resolution |
| --- | --- |
| Viper tested `CombatResult` argument 3, incoming damage to its attacker | Tests positive defender damage at argument 8 in both Result and the matching Ended callback, then verifies actual surviving military identity and war status before deferred poison |
| The original poison test supplied defender damage in the wrong slot and omitted real completion arguments | The engine double now emits all 15 arguments, applies native damage between callbacks and distinguishes per-hit damage from cumulative forecast damage |
| A single pending Viper hit could be consumed by an unrelated completion callback | Pending hits are correlated by attacker/defender player and unit IDs, creation turn and game turn; duplicate completion consumes no second application |
| Greedy movement could never take a necessary equal-distance or backwards detour | Native route queries plus bounded weighted land search navigate around obstacles and multiple approach positions |
| Queued moves could repeatedly fail or outlive a valid objective | Revalidate routes/targets, count actual position progress, release only our own failed step, cool down failures and preserve unrelated native orders |
| An AI flag carrier with no kit could repeatedly fail kit selection instead of returning | Carrier return has priority over kit selection; active infiltrators hold position by consuming AI movement |
| Same-area/neighbor tests did not prove a Feast route existed | Bounded access-aware regions, rival route scoring and practical unit arrival probes replace the full-map geometric scan |
| Stomper could treat a mountain as lower flat terrain | Mountain targets are explicitly excluded while other kits keep their existing target rules |
| Pending Feast preparation appeared as a final no-site result | Browser now distinguishes pending preparation from exhausted placement |
| Browser could remain visible over nonselection modes or missed popup events | Read-only checks hide it over incompatible modes and known full-screen controls, without polling |

## Verified combat semantics

Pinned official CP v151 source: `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`. `CvUnitCombat.cpp` emits this same argument list before and after native resolution:

| Arguments | Meaning |
| --- | --- |
| 1–2 | Attacking player and unit |
| 3 | Damage received by attacker: `getDamageInflicted(BATTLE_UNIT_DEFENDER)` |
| 4–5 | Predicted cumulative attacker damage and maximum HP |
| 6–7 | Defending player and unit; a city has no defending unit |
| 8 | Damage received by defender: `getDamageInflicted(BATTLE_UNIT_ATTACKER)` |
| 9–10 | Predicted cumulative defender damage and maximum HP |
| 11–13 | Interceptor player, unit and inflicted damage |
| 14–15 | Combat coordinates |

The setter and resolution paths confirm that the internal `DamageInflicted` value belongs to its SOURCE combat role, while the exposed local `attackerDamage` names the recipient. The new audit checks both emissions' exact order, each role mapping and native damage application. A ranged attack with zero incoming damage now correctly applies Viper. A zero-damage or suppressed resolved hit, civilian, friendly, invalid or dead defender does not. Post-combat healing can offset net wounds without erasing a real hit; detection uses resolved event damage and survival rather than net HP change.

Poison retains its existing `MCPPOISON1` block, refreshes one duration instead of stacking, ticks five damage at most once per owner turn, expires after two valid ticks, survives reload/normal upgrades and continues after the attacking unit dies. Padded deferred keys also retain combat chronology when a batch crosses sequence numbers such as 9/10, so later refreshes cannot be reordered by lexical sorting.

## AI routing and limits

`MCP_Navigation.lua` validates CP's native `GeneratePath(plot,maxTurns)` result as a table of route nodes. Native queries ignore friendly stacking, so each tile is rechecked using native `CanMoveThrough`, revelation, passable land, occupied tiles and foreign city restrictions. An empty table is a failed query, not a truthy reachability result. Normal and reversed path rows are normalized and validated.

When needed, weighted Dijkstra searches multiple objective positions, using native movement costs and a hard bound of 192 expanded nodes, radius 20 and 32 steps. Flag returns penalize native danger and exclude a currently predicted lethal destination. Current-turn movement remains available on the last active Feast turn; AI declines an infiltration that cannot finish before the cycle boundary. Per AI player and global turn, new plans share six native queries, 640 fallback expansions and four planning opportunities, including repeated callbacks. Native mode selection has a separate two-query/192-node budget once per cycle.

Only legal adjacent `MISSION_MOVE_TO` orders are issued, with no forced relocation or attack. Actual arrival events may continue along a validated route while movement remains, capped at eight orders per unit that turn. Deferred callbacks remove themselves; idle frames do no work. Native busy units and unrelated queued orders are preserved. Only a pending step recorded as ours can be popped when abandoned.

Two orders that fail to change position trigger a three-scaled-turn target cooldown. A fully searched unreachable objective also cools down. Exhausted search budgets are deferred rather than falsely proving unreachability; repeated exhaustion is briefly throttled. Routes replan when a step is occupied, access changes, a unit leaves its route, a city changes owner, a Feast ends or a new cycle starts. Planning opportunities rotate across units; returning carriers are prioritized. AI infiltrators retain their area until completion. AI scores still require the original actual occupancy/steal/return/infiltration actions.

## Feast placement

Each preparation attempt explores a legal region from the capital, up to 768 nodes within radius 22. Candidate tiles remain 4–16 hexes away, passable/revealed land on the same land area, with at least three reachable neighboring approaches. Water, mountains, foreign cities and unavailable territory cannot form a route. Friendly occupants may move before activation; enemy blockers remain relevant.

Two nearby rival civilizations can contribute regions of up to 384 nodes each. Scoring prefers actual rival access, neutral land, reasonable route cost and balanced travel distances. Another live McPvP Feast is excluded. Up to eight shortlisted candidates are checked against the two nearest available McPvP military units, sharing six native route queries and 384 fallback expansions. Arrival must fit before expiry. With no military unit yet, the legal capital route still allows future trainees and rival competition.

Initial, post-Grace and announcement-deadline attempts remain the only three preparation opportunities. There is no full-map traversal or endless retry. Missing capitals and unexplored starts remain safe. If no candidate fits within the budgets, the notification explains the missing Feast and the match continues with unchanged Grace Period, Final Battle and combat rewards; no fake victory is granted. Existing saved Feast locations/statuses remain intact, including older difficult sites.

## Files changed

- Gameplay: `MCP_Core.lua`, `MCP_Events.lua`, `MCP_Kits.lua`, `MCP_AI.lua`, `MCP_Matches.lua`; added `MCP_Navigation.lua`.
- Human interface: `MCP_ServerBrowser.lua`; XML and registered localization/art remain unchanged.
- Validation: `tools/validate_mcpvp.py`, McPvP's existing mock and match/kit/UI regressions; added `mcpvp_viper.lua`, `mcpvp_navigation.lua`, `mcpvp_objectives.lua`, `mcpvp_feasts.lua`.
- Integration: generated collection modinfo/project include the new Lua module with the existing VFS convention. Builder architecture and the collection UUID are unchanged.
- Documentation: McPvP guide/changelog/architecture/native checklist, this report and the supplied reliability request; collection roster/changelog wording updated.

## Validation and save compatibility

`tools/validate_mcpvp.py` passes actual-schema SQL, Lua 5.1 syntax, XML/control and 48 DDS checks, 83 pinned CP native method contracts and eight simulation suites. New tests cover the complete Viper matrix, native path row semantics, weighted detours around mountains/water, choke points, occupied tiles, borders, route invalidation, repeated failures, army budgets, real objective completions and deterministic map-shape models. Existing kit, reward, cap, upgrade, capital, remembrance, save rollback and screen regressions remain enabled.

The map-shape models represent Tiny Islands, Small Continents, Continents, Pangaea and bridges on the engine double. They do not execute the game's map generators. Native source contracts and simulated native queries likewise do not measure the real engine's pathfinder performance.

No saved-state schema change or migration is needed. `MCP_SaveData.lua`, `MCPSTATE1` and `MCPPOISON1` formats are unchanged. Route/failure caches are advisory runtime data outside player/unit ScriptData and can be discarded on load. Tests verify navigation does not change encoded authoritative state, and old-format objectives restore without rerolling or repaying rewards. Existing Feasts only gain the improved placement rules in a future cycle.

Full collection regressions, clean optional-schema compatibility, generated manifest/project hashes and package/art validation pass through `tools/validate_mod.py`; install archives are generated with `tools/build_mod.py`. The final diff check confirms unrelated civilization files, all original artwork and all McPvP SQL/localization are unchanged. The existing native saved-state serializer is unchanged as well.

## Remaining native work and limitations

**Civilization V has not been launched for this update. No native gameplay result is claimed.** Use the expanded [native checklist](Testing.md), especially melee/ranged poison, native path animations, AI flag return/infiltration, map generators and objective save round trips.

The planner is deliberately bounded, uses approximate future travel/danger costs and avoids occupied tiles conservatively. It may defer or decline a valid long detour, miss an unsampled distant rival, or lose a route when the world changes. Actual native tactical AI can change later orders, and a busy movement animation may postpone continuation until the next relevant event/turn. No reward bypass compensates for these limitations. Multiplayer/hotseat remain unsupported. Existing documented third-party summoning and native-exception boundaries remain unchanged.
