# McPvP changelog

## Reliability and AI improvements — 2026-10-17

- Corrected Viper to use verified CP defender-damage arguments and matching combat completion; retained one persistent poison block and exactly two five-damage ticks, including ranged attacks without retaliation and post-combat healing.
- Replaced greedy objective movement with validated native routes, bounded weighted detours, shared planning budgets, safe flag returns, mission holds, replanning and failed-movement cooldowns.
- Replaced geometric full-map Feast placement with bounded legal capital/rival regions and practical military arrival checks. Preserved distance, timing, rewards, three preparation attempts and existing saved sites.
- Fixed mountain Stomper targets, no-kit AI carriers, pending Feast text and Browser hiding over incompatible modes/screens.
- Added four focused regression suites and exact CP callback/route contracts. Original artwork, SQL/localization, numeric balance, saved-state formats and unrelated civilizations are unchanged. Native gameplay remains untested; see the [reliability report](docs/ReliabilityReport.md).

## Initial implementation preview — 2026-10-17

- Added The Old Guard, Veteran PvPer, Original Server Hub, English presentation text and original geometric lobby/insignia art.
- Implemented the Server Browser, three persistent match modes, contested Feast, flags, warned Sabotage, five kits, Legacy progression, Veteran upgrades, speed scaling, remembrance and conservative AI.
- Added CP v151 source/API verification, actual-schema SQL checks and four Lua 5.1 simulation suites. Integrated collection manifests, builder and regression validation.
- Native gameplay, rendering, saves and AI-only matches remain unverified; multiplayer/hotseat remain unsupported. See the implementation report and testing checklist.
