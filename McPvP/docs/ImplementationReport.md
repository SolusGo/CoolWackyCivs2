# McPvP implementation report — 2026-10-17

McPvP is integrated as the fourth isolated civilization in Cool Wacky Civs 2, keeping the collection UUID, mod version 7 and minimum compatible save version. Existing civilization identities, gameplay files and persistence formats are unchanged. New games can select The Old Guard; live selection and gameplay still require the native checks below.

## Created files

| Files | Purpose |
| --- | --- |
| `McPvP/SQL/00_MCP_Core.sql` | Playable identity, leader, Scout/Barracks clones, overrides, cities and event options |
| `McPvP/SQL/01_MCP_Inheritance.sql` | Active native unit/building/leader companion rows and civilization starting content |
| `McPvP/SQL/02_MCP_Effects.sql` | Promotions, Hub bonuses, capital Culture, temporary city penalties, AI flavors and diplomacy |
| `McPvP/SQL/03_MCP_Art.sql`, `10_MCP_Text.sql` | Atlases and English selection/help/Civilopedia/diplomacy/loading text |
| `McPvP/Lua/MCP_Core.lua`, `MCP_SaveData.lua` | Shared helpers, Legacy, remembrance, reconciliation and save-bound serial records |
| `McPvP/Lua/MCP_Matches.lua` | Cycles, contested Feast, flags, Sabotage, reward ledgers and expiry |
| `McPvP/Lua/MCP_Kits.lua` | All five kits, cooldowns, native damage, legal relocation and persistent poison |
| `McPvP/Lua/MCP_AI.lua`, `MCP_Events.lua` | Autonomous decisions, native hooks, validated human commands and deferred dispatch |
| `McPvP/UI/MCP_ServerBrowser.xml`, `.lua` | Event-driven Browser, mode queue, statistics, targets, kit/objective controls |
| `McPvP/Art/` | 48 DDS files and static leader scene XML; native Scout model/flag retained |
| `art-source/McPvP/`, four `art-source/IconAtlasMasters/MCP_*.png` files | Original deterministic geometric source artwork and retained collection-style atlas masters |
| `tools/generate_mcpvp.py`, `prepare_mcpvp_art.py`, `validate_mcpvp.py` | Reproducible database/art generation and validation |
| `tools/tests/mcpvp_mock.lua`, four `mcpvp_*.lua` scenario suites | Focused shipped-Lua simulations using the collection engine double |
| `McPvP/README.md`, `CHANGELOG.md`, `docs/` and `docs/civilizations/McPvP.md` | Player guide, source specification, architecture, limits and native checklist |

## Modified files

- `tools/build_mod.py`: fourth module/addin, collection selection text and Shared-first dependency ordering. This ordering also works on a clean CP install without optional metadata mods.
- `tools/validate_mod.py`: validate builder-defined SQL order and include McPvP's validator.
- Collection modinfo and ModBuddy project: all McPvP SQL, Lua, UI and art registered with proper VFS flags and hashes.
- Root README and changelog: fourth civilization, how to play and preview status.

## Mechanics delivered

All three rotating modes, human queueing, objective progress/summaries, Grace/Final Battle, rival-contestable Feast rewards, flag stealing/carrying/return, warned infiltration and expiring debuffs are implemented. All five kits differ mechanically. Veteran identity and cooldowns transfer through normal upgrades. Hubs preserve active Barracks behavior and grant training Legacy once. Current/lifetime Legacy, per-mode wins, milestones, capital relocation and the one-time Information Era event persist. AI performs real valid actions with a conservative movement fallback. Multiple McPvP player states remain isolated.

All time systems use actual game speed; economic/Culture rewards also scale with era. Viper retains two fixed damage ticks. Victory and combat caps bound rewards. No custom DLL, spawned opponents, external music, frame polling or permanent native-yield mutations are required.

## Validation and delivery status

The module passes actual-schema SQL, Lua 5.1 parsing, pinned CP v151 source contracts, XML/control checks, decoded DDS validation and four gameplay/UI simulation suites. Full collection regression, optional-schema compatibility, namespace, atlas and manifest/project checks pass. The builder creates the ordinary ZIP install folder and genuine 7z/LZMA `.civ5mod` in ignored `dist/`.

**Native Civ V gameplay, rendering, save round trips and AI-only games were not runtime-tested.** The [testing checklist](Testing.md) lists the remaining checks; the [implementation document](Implementation.md) details the engine boundaries. Multiplayer/hotseat are unsupported. No manual asset preparation is required for this static-art implementation; animated leader models, custom unit models and voiced diplomacy are outside its asset scope.

The main compromises are bounded greedy AI movement, a notification/Locate map indication rather than a physical Feast improvement, failed raids consuming their city's cycle opportunity, and exclusion of city-occupying targets from kit attacks. The public API cannot universally distinguish permanent ordinary units spawned by unrelated third-party scripts; zero-cost military types, barbarians and city-states are excluded from kill Legacy, and creation itself never pays training Legacy.
