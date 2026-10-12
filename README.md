# Cool Wacky Civs 2

An independent Civilization V: Brave New World collection for **Community Patch v151**, maintained in [SolusGo/CoolWackyCivs2](https://github.com/SolusGo/CoolWackyCivs2).

Version 1 starts with **The Boundless City**. This repository has its own mod ID, project, manifests, assets and documentation. The original CoolWackyCivs collection remains separate; its eighteen civilizations have not been copied here.

**Status: implementation preview.** SQL, Lua 5.1, simulated gameplay, UI behavior and package references have been validated. Live Civ V/CP v151 playtesting has **not** been performed. Two original requirements remain restricted by the available DLL APIs: population-only unlimited remote-worker capacity and immediate resolution of every possible externally scripted city transfer. Read the [precise engine limitations](TheBoundlessCity/docs/EngineLimitations.md) before starting a campaign. This release does not claim full completion of the original design.

![The First Architect and the endless city](art-source/TheBoundlessCity/ArchitectAndWorld.png)

## Civilization roster

| Civilization | Leader | Unique ability | Unique building | Unique unit | Guide |
| --- | --- | --- | --- | --- | --- |
| The Boundless City | The First Architect | The World Is One City | The Grand Registry, replacing Monument | Frontier Surveyor, replacing Worker | [Civ page](docs/civilizations/TheBoundlessCity.md) · [Detailed README](TheBoundlessCity/README.md) |

Every future civilization should receive a dedicated roster page, a gameplay README, a changelog and a validation record. The [documentation convention](docs/AddingCivilizations.md) describes the layout.

## Playing the mod

1. Install Civilization V with Brave New World and the Windows Community Patch **v151**. The Community Patch dependency is declared in the modinfo; no replacement DLL is included.
2. Build the release archives as below, or use a provided archive from this repository's distribution output.
3. Extract `dist/Cool Wacky Civs 2 (v 1).zip` into `Documents/My Games/Sid Meier's Civilization 5/MODS`. The extracted folder must contain `Cool Wacky Civs 2 (v 1).modinfo` directly.
4. Enable Community Patch and **Cool Wacky Civs 2** through the game's **Mods** menu. Proceed to the modded single-player setup and start a new game as **The First Architect**.
5. Found **The Heart of the World**, build The Grand Registry, and open **The Boundless Workforce** from the compact button at the upper right of the world map.

The initial Settler is preserved so the capital can be founded. Later Settlers and additional founding are blocked. Multiplayer, hotseat and Mac are not enabled. The original collection is not required. Avoid adding this civilization mid-campaign or changing mod versions without a backup save.

## Building and checking

The pure-file builder does not require ModBuddy. Use Python 3.11 or later:

```powershell
python -m pip install -r requirements-dev.txt
python tools/prepare_art.py
python tools/build_mod.py --manifest-only
python tools/validate_mod.py
python tools/benchmark.py
python tools/build_mod.py
```

`validate_mod.py` reads the installed game's backup debug database and Community Patch schema **read-only**, then runs SQL in an in-memory clone. See [Testing.md](TheBoundlessCity/docs/Testing.md) for paths, prerequisites, exact live test steps and the distinction between simulation and game verification. `generate_database.py` is for regenerating schema-derived SQL during development; it is unnecessary for installing the committed files.

Build products are a ZIP install folder and a genuine LZMA/7z `.civ5mod`, written to `dist/`. They are ignored by Git. ModBuddy users can open `CoolWackyCivs2.civ5sln`; `tools/build_mod.py` keeps its project and modinfo file lists, SQL ordering and VFS flags in sync.

## Repository layout

| Path | Contents |
| --- | --- |
| `TheBoundlessCity/SQL` | Civilization identity, active Worker/Monument inheritance, effects, atlases, English localization |
| `TheBoundlessCity/Lua` | Isolated frontier, workforce, persistence, enforcement and AI systems |
| `TheBoundlessCity/UI` | The Boundless Workforce XML/Lua addin; one simulation owner |
| `TheBoundlessCity/Art` | 34 referenced DDS textures and static diplomacy scene |
| `TheBoundlessCity/docs` | API audit, implementation, limitations, live test checklist, benchmark and original specification |
| `docs/civilizations` | One dedicated Markdown page per civilization |
| `art-source/TheBoundlessCity` | Original generated illustration, insignia preview and asset provenance |
| `tools` | Reproducible SQL/art/project/package builders and focused validation |

Read the [collection changelog](CHANGELOG.md), [civilization changelog](TheBoundlessCity/CHANGELOG.md), and [implementation notes](TheBoundlessCity/docs/Implementation.md) for mechanics, invariants and performance details.
