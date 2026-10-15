# Cool Wacky Civs 2

An independent Civilization V: Brave New World collection for **Community Patch v151**, maintained in [SolusGo/CoolWackyCivs2](https://github.com/SolusGo/CoolWackyCivs2).

Mod version 4 (collection release **1.2.2 preview**) starts with **The Boundless City**. This repository has its own mod ID, project, manifests, assets and documentation. The original CoolWackyCivs collection remains separate; its eighteen civilizations have not been copied here.

**Status: implementation preview.** Ten gameplay/UI simulation suites, 176 pinned CP v151 source checks, actual-schema SQL and package/art validation pass. The player confirmed that the pre-crash turn/movement replay completed after the dispatcher hotfix; [crash investigation](TheBoundlessCity/docs/CrashHotfixReport.md). The latest [Workforce UI hotfix](TheBoundlessCity/docs/UIVisibilityHotfix.md) repairs stale screen visibility and awaits an in-game retry. This release adds survival while units remain, original-capital siege reclaim, one-time subjugation, a native Boundless Domination finish, remote improvement development and Tourism refresh. Full population-only remote allocation, general demolition and absolute ownership enforcement against scripts remain engine limited. Read the [final engine report](TheBoundlessCity/docs/EngineCompletionReport.md) and [precise limits](TheBoundlessCity/docs/EngineLimitations.md).

![The First Architect and the endless city](art-source/TheBoundlessCity/ArchitectAndWorld.png)

## Civilization roster

| Civilization | Leader | Unique ability | Unique building | Unique unit | Guide |
| --- | --- | --- | --- | --- | --- |
| The Boundless City | The First Architect | The World Is One City | The Grand Registry, replacing Monument | Frontier Surveyor, replacing Worker | [Civ page](docs/civilizations/TheBoundlessCity.md) · [Detailed README](TheBoundlessCity/README.md) |

Every future civilization should receive a dedicated roster page, a gameplay README, a changelog and a validation record. The [documentation convention](docs/AddingCivilizations.md) describes the layout.

## Playing the mod

1. Install Civilization V with Brave New World and the Windows Community Patch **v151**. The Community Patch dependency is declared in the modinfo; no replacement DLL is included.
2. Build the release archives as below, or use a provided archive from this repository's distribution output.
3. Extract `dist/Cool Wacky Civs 2 (v 4).zip` into `Documents/My Games/Sid Meier's Civilization 5/MODS`. The extracted folder must contain `Cool Wacky Civs 2 (v 4).modinfo` directly. Remove the older install folder before installing this version; all versions use the same collection UUID.
4. Enable Community Patch and **Cool Wacky Civs 2** through the game's **Mods** menu. Proceed to the modded single-player setup and start a new game as **The First Architect**.
5. Found **The Heart of the World**, build The Grand Registry, and open **The Boundless Workforce** from the compact button at the upper right of the world map.

The initial Settler is preserved so the capital can be founded. Later Settlers are removed through safe deferred dispatch, including after capital loss; additional founding remains blocked. Multiplayer, hotseat and Mac are not enabled. The original collection is not required. Version 1 saves migrate explicitly, while version 2 state migrates to schema 3 without resetting progress. Back up version 1–3 saves before upgrading; native save testing is outstanding. Downgrading is unsupported. Older native saves can retain the previous survival-trait cache until a normal technology or policy refresh; test that separately before relying on capital-loss survival.

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

Optional source audit: `python tools/audit_cp.py --fetch` downloads the pinned official v151 sources into ignored `tools/reference/` and verifies 176 API/signature assertions. Later runs can omit `--fetch`. A read-only coexistence check compares UUIDs, VFS files, database identifiers and globals when the original collection is available as a sibling folder; combined live gameplay still needs testing.

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
