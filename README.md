# Cool Wacky Civs 2

An independent Civilization V: Brave New World collection for **Community Patch v151**, maintained in [SolusGo/CoolWackyCivs2](https://github.com/SolusGo/CoolWackyCivs2).

Mod version 9 (collection release **1.6.0 preview**) includes **The Boundless City**, **The Republic of Pigeons**, **The Indigo Champion**, **McPvP — The Endless Lobby**, **The Children of the Kingdom**, **The Twelfth Hour** and **The Wandering Circus**, with consistent gold icon frames and corrected portrait padding. This repository has its own mod ID, project, manifests, assets and documentation. The original CoolWackyCivs collection remains separate; its eighteen civilizations have not been copied here. See the [icon build notes](docs/IconConsistency.md).

**New: The Wandering Circus**, led by **Ringmaster Aurelio**. Carnival Crews preserve all Worker properties with +1 Movement; ending a turn in a city prepares a local three-turn Grand Festival (+3 Culture/+2 Gold), with twelve turns between starts. Ticket Offices preserve Markets and add +1 Culture plus +2 Production during that city's festival. Human-only, with original artwork, native persistent timing, full English text, 30 Lua 5.1 simulation runs and 29 pinned CP source contracts. Native yields, rendering and save round trips remain unverified. See the [guide](TheWanderingCircus/README.md), [timing/source findings](TheWanderingCircus/docs/Implementation.md) and [acceptance checklist](TheWanderingCircus/docs/Testing.md).

**New: The Twelfth Hour**, led by **The Keeper of Seconds**. This human-only clockwork society synchronizes all cities on played turns 6, 12, 18… for +75% Production and +50% Science. Pendulum Guards preserve Pikeman benefits and retain +1 Movement/+15% friendly-territory strength through upgrades; Municipal Clocktowers preserve Workshops and add +1 Culture plus +2 flat Production during Chime. Original paintings, complete English text, actual-schema SQL, twenty Lua 5.1 suite runs and forty-three CP source contracts are included. The [second-pass audit](TheTwelfthHour/docs/AuditReport.md) fixes the save-function contract and exception/sale paths and tests snapshot rewinds, same-turn games and pre-staging autosaves. Native yields/save round trips remain unverified; see the [implementation report](TheTwelfthHour/docs/Implementation.md), [guide](TheTwelfthHour/README.md) and [twenty-scenario native checklist](TheTwelfthHour/docs/Testing.md).

**New: The Children of the Kingdom**, led by **The Faithful**. This human-only civilization follows seven petitions of the Lord's Prayer through an event-driven Prayer panel. Complete cycles for permanent capital Faith/Culture through Grace, preserve upgrade-retained Keepers of the Faith, and raise Houses of Prayer. Original leader/loading art, complete localization, CP v151 source contracts and seven shipped-Lua simulation suites are included. The [implementation audit](TheChildrenOfTheKingdom/docs/AuditReport.md) fixes command/screen validation, control-change expiry and missed-popup behavior, and verifies native healing/movement eligibility without rebalancing. Native gameplay/rendering/save round trips remain unverified. See the [guide](TheChildrenOfTheKingdom/README.md), [implementation and engine limits](TheChildrenOfTheKingdom/docs/Implementation.md) and [native checklist](TheChildrenOfTheKingdom/docs/Testing.md).

**New: McPvP — The Endless Lobby**, led by **The Old Guard**. Choose Kangaroo, Stomper, Endermage, Thor or Viper, then queue Hardcore Games, Capture the Flag or Sabotage in the Server Browser. Contested Feasts, returned flags and warned infiltrations build persistent Server Legacy. Veteran PvPers keep their identity through upgrades; Original Server Hubs preserve Barracks benefits and train kit-ready units. Information Era brings Legacy Unforgotten while play continues. The reliability update fixes Viper's native combat argument handling, adds bounded AI detours and checks real Feast accessibility. SQL, pinned CP v151 APIs, original art and eight Lua simulation suites pass; native gameplay/rendering/save round trips remain unverified. See the [guide](McPvP/README.md), [reliability report](McPvP/docs/ReliabilityReport.md) and [native checklist](McPvP/docs/Testing.md).

**New: Trainer Red — The Indigo Champion.** Train persistent military partners, assemble a six-slot Champion Team, bond Pokémon Aces and complete Journey to Mt. Silver. Includes Pokémon Centers, Indigo Plateau, six legendary identities, original artwork and a roster/actions panel. Red SQL, CP source-contract checks and four Lua simulation suites pass; native gameplay and AI-only matches remain unverified. See the [civ guide](TrainerRed/README.md), [implementation report](TrainerRed/docs/ImplementationReport.md) and [native checklist](TrainerRed/docs/Testing.md).

**The Republic of Pigeons**, led by **Postmaster General Coo**. Outgoing land Trade Routes grant their origin cities stacking Science and Culture. Carrier Pigeons explore with extra sight; Rooftop Roosts retain Caravansary benefits, add Culture, and gain Production while dispatching caravans. Original leader/loading art, postal icons, AI flavors and English Civilopedia text are included. Pigeon SQL, Lua simulations and pinned CP source checks pass; native gameplay verification is still required. See the [civilization guide](TheRepublicOfPigeons/README.md) and [validation record](TheRepublicOfPigeons/docs/Testing.md).

**Status: implementation preview.** Eleven Boundless gameplay/UI simulation suites, focused summary-display tests, 182 pinned CP v151 source checks, actual-schema SQL and package/art validation pass. The player confirmed that the pre-crash turn/movement replay completed after the dispatcher hotfix; [crash investigation](TheBoundlessCity/docs/CrashHotfixReport.md). The [Workforce UI hotfix](TheBoundlessCity/docs/UIVisibilityHotfix.md) repairs stale screen visibility. The latest [summary-display fix](TheBoundlessCity/docs/SummaryDisplayFix.md) restores Owned Plots and every workforce/capacity statistic with individual localized labels and a scrolling overview; native rendering verification remains pending. This release adds survival while units remain, original-capital siege reclaim, one-time subjugation, a native Boundless Domination finish, remote improvement development and Tourism refresh. Full population-only remote allocation, general demolition and absolute ownership enforcement against scripts remain engine limited. Read the [final engine report](TheBoundlessCity/docs/EngineCompletionReport.md) and [precise limits](TheBoundlessCity/docs/EngineLimitations.md).

The [Boundless Food growth hotfix](TheBoundlessCity/docs/FoodGrowthHotfix.md) preserves remote yields backed by real citizens through local governor changes. The regression reproduces +37.50 displayed versus +13.75 harvested before the repair; the corrected sequence stores the advertised rate. Existing saves need no migration; native replay confirmation remains pending.

![The First Architect and the endless city](art-source/TheBoundlessCity/ArchitectAndWorld.png)

## Civilization roster

| Civilization | Leader | Unique ability | Unique building | Unique unit | Guide |
| --- | --- | --- | --- | --- | --- |
| The Boundless City | The First Architect | The World Is One City | The Grand Registry, replacing Monument | Frontier Surveyor, replacing Worker | [Civ page](docs/civilizations/TheBoundlessCity.md) · [Detailed README](TheBoundlessCity/README.md) |
| The Republic of Pigeons | Postmaster General Coo | Messages on the Wing | Rooftop Roost, replacing Caravansary | Carrier Pigeon, replacing Scout | [Civ page](docs/civilizations/TheRepublicOfPigeons.md) · [Detailed README](TheRepublicOfPigeons/README.md) |
| The Indigo Champion | Trainer Red | The Living Legend | Pokémon Center (Hospital), Indigo Plateau (Heroic Epic), Journey to Mt. Silver project | Pokémon Ace, replacing Great General | [Civ page](docs/civilizations/TrainerRed.md) · [Detailed README](TrainerRed/README.md) |
| McPvP — The Endless Lobby | The Old Guard | Just One More Game | Original Server Hub, replacing Barracks | Veteran PvPer, replacing Scout | [Civ page](docs/civilizations/McPvP.md) · [Detailed README](McPvP/README.md) |
| The Children of the Kingdom | The Faithful | Thy Kingdom Come | House of Prayer, replacing Temple | Keeper of the Faith, replacing Pikeman | [Civ page](docs/civilizations/TheChildrenOfTheKingdom.md) · [Detailed README](TheChildrenOfTheKingdom/README.md) |
| The Twelfth Hour | The Keeper of Seconds | When the Clock Strikes | Municipal Clocktower, replacing Workshop | Pendulum Guard, replacing Pikeman | [Civ page](docs/civilizations/TheTwelfthHour.md) · [Detailed README](TheTwelfthHour/README.md) |
| The Wandering Circus | Ringmaster Aurelio | The Show Must Go On | Ticket Office, replacing Market | Carnival Crew, replacing Worker | [Civ page](docs/civilizations/TheWanderingCircus.md) · [Detailed README](TheWanderingCircus/README.md) |

Every future civilization should receive a dedicated roster page, a gameplay README, a changelog and a validation record. The [documentation convention](docs/AddingCivilizations.md) describes the layout.

## Playing the mod

1. Install Civilization V with Brave New World and the Windows Community Patch **v151**. The Community Patch dependency is declared in the modinfo; no replacement DLL is included.
2. Build the release archives as below, or use a provided archive from this repository's distribution output.
3. Extract `dist/Cool Wacky Civs 2 (v 9).zip` into `Documents/My Games/Sid Meier's Civilization 5/MODS`. The extracted folder must contain `Cool Wacky Civs 2 (v 9).modinfo` directly. Remove the older install folder before installing this version; all versions use the same collection UUID.
4. Enable Community Patch and **Cool Wacky Civs 2** through the game's **Mods** menu. Proceed to the modded single-player setup and choose any of the seven leaders.
5. As **Trainer Red**, found **Pallet Town**, preserve trained military partners and open **Champion Team** from the upper-right button. As **Postmaster General Coo**, found **Coopolis**, explore with Carrier Pigeons, and establish outgoing land Trade Routes. As **The First Architect**, found **The Heart of the World**, build The Grand Registry, and open **The Boundless Workforce** from the compact button at the upper right of the world map.
6. As **The Old Guard**, found **Lobby One** and open **McPvP Server Browser** at the upper right. Select a Veteran on the map, choose a kit and queue the next match. Train military units in Original Server Hubs to unlock more kits and earn Legacy.
7. As **The Faithful**, found **Sanctuary** and open **Prayer** at the upper right. Activate the next petition when its cooldown is ready. Complete seven petitions to gain permanent Grace; Houses of Prayer add Faith to every completed cycle. The civilization is excluded from normal AI assignment.
8. As **The Keeper of Seconds**, found **Last Minute**, develop research/industry across several cities, and prepare builds for the sixth-turn Grand Chime. Municipal Clocktowers improve every Chime; Pendulum Guards reinforce friendly territory. The civilization is excluded from normal AI assignment.
9. As **Ringmaster Aurelio**, found **Grand Pavilion**. Use Carnival Crews to build infrastructure, then end their turns in eligible cities to prepare local Grand Festivals. Build Ticket Offices for permanent Culture and festival Production. The civilization is excluded from normal AI assignment. Version 8 native save continuation has not been tested; back up older saves and prefer a new game for the new civilization.

For The Boundless City, the initial Settler is preserved so the capital can be founded. Later Settlers are removed through safe deferred dispatch, including after capital loss; additional founding remains blocked. The Pigeon Republic and Indigo Champion follow ordinary settlement rules. Multiplayer, hotseat and Mac are not enabled. The original collection is not required. Boundless version 1 saves migrate explicitly, while version 2 state migrates to schema 3 without resetting progress. Back up older saves before upgrading; native save testing is outstanding. Downgrading is unsupported. Older native saves can retain the previous survival-trait cache until a normal technology or policy refresh; test that separately before relying on capital-loss survival.

## Building and checking

The pure-file builder does not require ModBuddy. Use Python 3.11 or later:

```powershell
python -m pip install -r requirements-dev.txt
python tools/prepare_art.py
python tools/build_mod.py --manifest-only
python tools/validate_mod.py
python tools/benchmark.py
python tools/build_mod.py
python tools/verify_release.py
```

`validate_mod.py` reads the installed game's backup debug database and Community Patch schema **read-only**, then runs SQL in an in-memory clone. See [Testing.md](TheBoundlessCity/docs/Testing.md) for paths, prerequisites, exact live test steps and the distinction between simulation and game verification. `generate_database.py` is for regenerating schema-derived SQL during development; it is unnecessary for installing the committed files.

Optional source audit: `python tools/audit_cp.py --fetch` and `python tools/validate_red.py --fetch` downloads the pinned official v151 sources into ignored `tools/reference/` and verifies 182 API/signature assertions. Later runs can omit `--fetch`. A read-only coexistence check compares UUIDs, VFS files, database identifiers and globals when the original collection is available as a sibling folder; combined live gameplay still needs testing.

Kingdom-specific checks: `python tools/validate_kingdom.py` (also included in `validate_mod.py`). Use `python tools/validate_kingdom.py --fetch` to fetch its additional pinned policy source when updating an existing source cache. The [Kingdom test record](TheChildrenOfTheKingdom/docs/Testing.md) distinguishes static checks/simulations from the outstanding native checklist.

Twelfth Hour checks: `python tools/validate_twelfth.py` (also included in `validate_mod.py`). SQL/art can be regenerated with `tools/generate_twelfth.py` and `tools/prepare_twelfth_art.py`. The [test record](TheTwelfthHour/docs/Testing.md) separates static/source/model results from pending native checks. New SQL is appended after all previously released SQL to preserve existing insertion order.

Wandering Circus checks: `python tools/validate_circus.py` (also included in `validate_mod.py`). SQL/art regeneration uses `tools/generate_circus.py` and `tools/prepare_circus_art.py`. The [implementation](TheWanderingCircus/docs/Implementation.md) explains pre-economic preparation, persistent dummy markers and captured-Worker handling; the [test record](TheWanderingCircus/docs/Testing.md) maps all 42 requested scenarios and lists the outstanding native tests.

Build products are a ZIP install folder and a genuine LZMA/7z `.civ5mod`, written to `dist/`. They are ignored by Git. ModBuddy users can open `CoolWackyCivs2.civ5sln`; `tools/build_mod.py` keeps its project and modinfo file lists, SQL ordering and VFS flags in sync.

## Repository layout

| Path | Contents |
| --- | --- |
| `TheBoundlessCity/SQL` | Civilization identity, active Worker/Monument inheritance, effects, atlases, English localization |
| `TheBoundlessCity/Lua` | Isolated frontier, workforce, persistence, enforcement and AI systems |
| `TheBoundlessCity/UI` | The Boundless Workforce XML/Lua addin; one simulation owner |
| `TheBoundlessCity/Art` | 34 referenced DDS textures and static diplomacy scene |
| `TheBoundlessCity/docs` | API audit, implementation, limitations, live test checklist, benchmark and original specification |
| `TheRepublicOfPigeons` | Pigeon SQL, event-driven trade addin, 34 DDS textures, gameplay and validation guides |
| `TrainerRed` | Red SQL, persistent Training/roster/combat/Ace/Mt. Silver/AI Lua, party panel, 58 mipmapped DDS assets and gameplay/testing documentation |
| `McPvP` | Three persistent match modes, five kits, Server Browser, Legacy/remembrance, conservative AI, 48 DDS assets and validation/report guides |
| `art-source/McPvP` | Original deterministic geometric lobby, Old Guard portrait and kit/object symbols |
| `TheChildrenOfTheKingdom` | Human-only seven-stage Prayer, persistent Grace/reserve, Keepers/Houses, 34 DDS textures and detailed implementation/native testing guides |
| `TheTwelfthHour` | Human-only six-turn Grand Chime, inherited Pikeman/Workshop uniques, 40 DDS textures, full English text and timing/native test documentation |
| `art-source/TheTwelfthHour` | Original clockwork paintings, retained atlas masters and exact generation prompts |
| `TheWanderingCircus` | Human-only local Grand Festivals, complete Worker/Market inheritance, 40 DDS textures, English text and timing/save/native test documentation |
| `art-source/TheWanderingCircus` | Original Ringmaster painting, drawn circus/ticket/Crew symbols, fictional caravan map and exact prompt |
| `art-source/TheChildrenOfTheKingdom` | Original Faithful/Sanctuary painting, drawn prayer/book/shield/sanctuary icons, map and exact generation prompt |
| `art-source/TrainerRed` | Original generated summit leader/loading paintings, icon preview and provenance |
| `docs/civilizations` | One dedicated Markdown page per civilization |
| `art-source/TheBoundlessCity` | Original generated illustration, insignia preview and asset provenance |
| `art-source/TheRepublicOfPigeons` | Original Coo illustration, postal insignia preview and generation prompt |
| `tools` | Reproducible SQL/art/project/package builders and focused validation |

Read the [collection changelog](CHANGELOG.md), [civilization changelog](TheBoundlessCity/CHANGELOG.md), and [implementation notes](TheBoundlessCity/docs/Implementation.md) for mechanics, invariants and performance details.
