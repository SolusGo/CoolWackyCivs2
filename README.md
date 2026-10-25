# Cool Wacky Civs 2

Twelve civilizations for Civilization V: Brave New World and **Community Patch v151**. This is an independent collection; the original Cool Wacky Civs mod is not required.

**Current release:** mod version 14 · **1.11.0 preview**. [Changelog](CHANGELOG.md) · [GitHub](https://github.com/SolusGo/CoolWackyCivs2)

The Boundless Workforce has a new [custom graphical skin](TheBoundlessCity/docs/UIVisuals.md), with an engraved city header, brass/teal textures, matching controls and clearer district rows. [Layout preview and original art](art-source/TheBoundlessCity/WorkforceUI/README.md).

## Civilization roster

| Civilization | Leader | Playstyle | Guide |
| --- | --- | --- | --- |
| [The Boundless City](docs/civilizations/TheBoundlessCity.md) | The First Architect | Develop one sprawling city and manage its expanding workforce. | [Details](TheBoundlessCity/README.md) |
| [The Republic of Pigeons](docs/civilizations/TheRepublicOfPigeons.md) | Postmaster General Coo | Use land trade routes to generate stacking Science and Culture. | [Details](TheRepublicOfPigeons/README.md) |
| [The Indigo Champion](docs/civilizations/TrainerRed.md) | Trainer Red | Train military partners and assemble a six-slot Champion Team. | [Details](TrainerRed/README.md) |
| [McPvP — The Endless Lobby](docs/civilizations/McPvP.md) | The Old Guard | Choose kits, compete in three match modes and build Server Legacy. | [Details](McPvP/README.md) |
| [The Children of the Kingdom](docs/civilizations/TheChildrenOfTheKingdom.md) | The Faithful | Complete seven prayer petitions to earn permanent Grace bonuses. | [Details](TheChildrenOfTheKingdom/README.md) |
| [The Twelfth Hour](docs/civilizations/TheTwelfthHour.md) | The Keeper of Seconds | Synchronize cities for Production and Science boosts every sixth turn. | [Details](TheTwelfthHour/README.md) |
| [The Wandering Circus](docs/civilizations/TheWanderingCircus.md) | Ringmaster Aurelio | Send Carnival Crews to cities to prepare local Grand Festivals. | [Details](TheWanderingCircus/README.md) |
| [The 11 Cats](docs/civilizations/The11Cats.md) | Austin — King of the House | Welcome ten companions, settle warm homes and build local Family Bonds. | [Details](The11Cats/README.md) |
| [The Kingdom of Saba](docs/civilizations/KingdomOfSaba.md) | Karib'il Watar | Settle River and Desert cities, develop Cisterns and defend the wadis. | [Details](KingdomOfSaba/README.md) |
| [The Substitute Classroom](docs/civilizations/TheSubstituteClassroom.md) | Mr. Garvey | Take Roll Call, manage Insubordination and turn Detention into a military surge. | [Details](TheSubstituteClassroom/README.md) |
| [The Conical Union](docs/civilizations/TheConicalUnion.md) | High Marshal Bollard | Connect productive settlements with Road Crews and defensive Detour Offices. | [Details](TheConicalUnion/README.md) |
| [The Kingdom of the Unrung Bell](docs/civilizations/KingdomOfTheUnrungBell.md) | Keeper Sable | Build Quietude during peace, then consume it for five full windows of the Great Toll. | [Details](KingdomOfTheUnrungBell/README.md) |

All twelve are human-playable. The Children of the Kingdom, The Twelfth Hour, The Wandering Circus, The 11 Cats, The Kingdom of Saba, The Substitute Classroom, The Conical Union and The Kingdom of the Unrung Bell are human-only. Each guide lists unique units/buildings, mechanics, engine limits and testing records.

**Status:** implementation preview. Native gameplay, rendering and save testing remain incomplete; see each civilization's testing record for the outstanding checks.

## Playing the mod

1. Install Civilization V with Brave New World and the Windows **Community Patch v151**.
2. Build the release below, or use the provided archive. Extract `dist/Cool Wacky Civs 2 (v 14).zip` into `Documents/My Games/Sid Meier's Civilization 5/MODS`. The extracted folder must contain `Cool Wacky Civs 2 (v 14).modinfo` directly. Remove the older installation before installing this version; all versions share one collection UUID.
3. Enable **Community Patch** and **Cool Wacky Civs 2** through the game's **Mods** menu, then enter modded single-player setup and choose a leader.
4. Follow the civilization's guide above for its opening moves and custom panel.

Back up older saves before upgrading; native save continuation has not been fully tested. Start a new game to play a newly added civilization. Multiplayer, hotseat and Mac are not supported.

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

Civilization-specific validation, source audits and regeneration commands are documented in each guide above. The [documentation convention](docs/AddingCivilizations.md) covers adding future civilizations, and the [icon build notes](docs/IconConsistency.md) explain atlas dimensions and gold framing.

Build products are a ZIP install folder and a genuine LZMA/7z `.civ5mod`, written to `dist/`. They are ignored by Git. ModBuddy users can open `CoolWackyCivs2.civ5sln`; `tools/build_mod.py` keeps its project and modinfo file lists, SQL ordering and VFS flags in sync.

## Repository layout

| Path | Contents |
| --- | --- |
| Each civilization's folder | Gameplay SQL/Lua, UI, DDS assets, guide, changelog and testing documentation |
| `docs/civilizations` | Short reference page for each civilization |
| `art-source` | Original artwork, icon previews, atlas masters and generation notes |
| `tools` | SQL/art/project/package builders and validation scripts |
| `dist` | Generated install archives; ignored by Git |
