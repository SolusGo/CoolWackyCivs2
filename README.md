# Cool Wacky Civs 2

20 human-only civilizations for Civilization V: Brave New World and Windows **Community Patch v151**. An independent collection; the original mod is not required.

**Current source:** mod version 22 - **Civilopedia and strategy handbook**. [Changelog](CHANGELOG.md)

**Start here:** [Choose a playstyle](docs/StrategyGuide.md) · [Who pressures whom](docs/Matchups.md) · [Installation and builds](#playing-the-mod)

Every guide includes opening priorities, development, late-game conversion, pros, cons, mistakes, counterplay and four named matchup examples. The in-game civilization and leader Civilopedia pages show practical guidance before their preserved lore.

Named custom-civ matchups are conditional theorycraft or scenario comparisons, not tested win rates. All custom civs are human-only, and multiplayer/hotseat are unsupported. General counterplay advice still applies against normal single-player opponents.

## Civilization roster

| Civilization | Leader | Playstyle | Guide |
| --- | --- | --- | --- |
| The Boundless City | The First Architect | One expanding municipality with a finite workforce | [Strategy](docs/strategy/TheBoundlessCity.md) · [Full rules](TheBoundlessCity/README.md) |
| Pigeon Republic | Postmaster General Coo | Protected land trade and distributed origin-city yields | [Strategy](docs/strategy/TheRepublicOfPigeons.md) · [Full rules](TheRepublicOfPigeons/README.md) |
| Indigo Champion | Trainer Red | An irreplaceable veteran team and selected tactical tools | [Strategy](docs/strategy/TrainerRed.md) · [Full rules](TrainerRed/README.md) |
| McPvP | The Old Guard | Objective warfare, mobility and persistent Server Legacy | [Strategy](docs/strategy/McPvP.md) · [Full rules](McPvP/README.md) |
| Children of the Kingdom | The Faithful | A fixed prayer cycle with permanent capital development | [Strategy](docs/strategy/TheChildrenOfTheKingdom.md) · [Full rules](TheChildrenOfTheKingdom/README.md) |
| The Twelfth Hour | The Keeper of Seconds | Developed-city industry and a synchronized six-turn economy | [Strategy](docs/strategy/TheTwelfthHour.md) · [Full rules](TheTwelfthHour/README.md) |
| The Wandering Circus | Ringmaster Aurelio | Worker logistics and recurring local cultural festivals | [Strategy](docs/strategy/TheWanderingCircus.md) · [Full rules](TheWanderingCircus/README.md) |
| The 11 Cats | Austin | Peaceful city specialization through a persistent household | [Strategy](docs/strategy/The11Cats.md) · [Full rules](The11Cats/README.md) |
| Saba | Karib'il Watar | Low-management River settlement and practical early defense | [Strategy](docs/strategy/KingdomOfSaba.md) · [Full rules](KingdomOfSaba/README.md) |
| Substitute Classroom | Mr. Garvey | Timed economic choices with a risky combat surge | [Strategy](docs/strategy/TheSubstituteClassroom.md) · [Full rules](TheSubstituteClassroom/README.md) |
| The Conical Union | High Marshal Bollard | Connected secondary cities and efficient worker logistics | [Strategy](docs/strategy/TheConicalUnion.md) · [Full rules](TheConicalUnion/README.md) |
| Unrung Bell | Keeper Sable | Peaceful accumulation followed by a limited territorial response | [Strategy](docs/strategy/KingdomOfTheUnrungBell.md) · [Full rules](KingdomOfTheUnrungBell/README.md) |
| The Urgal | Urgal | Snapshot-based melee timing attacks | [Strategy](docs/strategy/TheUrgal.md) · [Full rules](TheUrgal/README.md) |
| Jin | Wanyan Aguda | Resource-backed cavalry, selected landmarks and tributary logistics | [Strategy](docs/strategy/JinDynasty.md) · [Full rules](JinDynasty/README.md) |
| The Threshold Court | Queen Elsewhere | A paid defensive reinforcement network between owned cities | [Strategy](docs/strategy/TheThresholdCourt.md) · [Full rules](TheThresholdCourt/README.md) |
| Honeycomb Commonwealth | Speaker Mellia | Worked-Plantation specialization and protected agrarian development | [Strategy](docs/strategy/TheHoneycombCommonwealth.md) · [Full rules](TheHoneycombCommonwealth/README.md) |
| Laureate Commonwealth | Laurea | Achievement-fed Golden Ages and cultured military finishing | [Strategy](docs/strategy/TheLaureateCommonwealth.md) · [Full rules](TheLaureateCommonwealth/README.md) |
| T1 | Faker | Five persistent roles and long-lived upgrade development | [Strategy](docs/strategy/T1ZOFGK.md) · [Full rules](T1ZOFGK/README.md) |
| The Republic of First Drafts | Editor-in-Chief Marginalia | Institutional variety and permanent first-possession rewards | [Strategy](docs/strategy/TheRepublicOfFirstDrafts.md) · [Full rules](TheRepublicOfFirstDrafts/README.md) |
| The Lantern Fleet | High Keeper Maren | Defensive coastal development and turn-start naval snapshots | [Strategy](docs/strategy/TheLanternFleet.md) · [Full rules](TheLanternFleet/README.md) |

All 20 have `Playable=1`, `AIPlayable=0`. Native gameplay, rendering and save acceptance remain incomplete; the full rules and testing records distinguish implemented mechanics from outstanding engine checks.

## Playing the mod

1. Install Civilization V with Brave New World and the Windows **Community Patch v151**.
2. Build the release below, or use the provided archive. Extract `dist/Cool Wacky Civs 2 (v 22).zip` into `Documents/My Games/Sid Meier's Civilization 5/MODS`. The extracted folder must contain `Cool Wacky Civs 2 (v 22).modinfo` directly. Remove the older installation before installing this version; all versions share one collection UUID.
3. Enable **Community Patch** and **Cool Wacky Civs 2** through the game's **Mods** menu, then enter modded single-player setup and choose a leader.
4. Follow the civilization's guide above for its opening moves and custom panel.

Back up older saves before upgrading; native save continuation has not been fully tested. Start a new game to play a newly added civilization. Multiplayer, hotseat and Mac are not supported.

## Building and checking

The pure-file builder does not require ModBuddy. Use Python 3.11 or later:

```powershell
python -m pip install -r requirements-dev.txt
python tools/prepare_art.py
python tools/build_mod.py --manifest-only --preserve-art
python tools/validate_mod.py
python tools/benchmark.py
python tools/build_mod.py --preserve-art
python tools/verify_release.py
```

`validate_mod.py` reads the installed game's backup debug database and Community Patch schema **read-only**, then runs SQL in an in-memory clone. See [Testing.md](TheBoundlessCity/docs/Testing.md) for paths, prerequisites, exact live test steps and the distinction between simulation and game verification. `generate_database.py` is for regenerating schema-derived SQL during development; it is unnecessary for installing the committed files.

Civilization-specific validation, source audits and regeneration commands are documented in each guide above. The [documentation convention](docs/AddingCivilizations.md) covers adding future civilizations, and the [icon build notes](docs/IconConsistency.md) explain atlas dimensions and gold framing.

Build products are a ZIP install folder and a genuine LZMA/7z `.civ5mod`, written to `dist/`. They are ignored by Git. ModBuddy users can open `CoolWackyCivs2.civ5sln`; `tools/build_mod.py` keeps its project and modinfo file lists, SQL ordering and VFS flags in sync.

`--preserve-art` validates the existing framed atlases and retains their compiled bytes/mipmaps. Omit it when intentionally recompiling all icon families from their retained masters.

## Repository layout

| Path | Contents |
| --- | --- |
| Each civilization's folder | Gameplay SQL/Lua, UI, DDS assets, guide, changelog and testing documentation |
| `docs/civilizations` | Short reference page for each civilization |
| `art-source` | Original artwork, icon previews, atlas masters and generation notes |
| `tools` | SQL/art/project/package builders and validation scripts |
| `dist` | Generated install archives; ignored by Git |
