# Delivery record — 2026-10-16

Implemented in collection mod version 5. The UA, UU and UB match the requested values. Human/AI bonuses share the same isolated Lua code. Absolute invisible building counts are rebuilt from real outgoing land routes, ownership and era; there is no saved Lua ledger. The Scout and Caravansary inherit the active CP baseline and all known companion tables. Database updates and the separate InGameUIAddin are registered in both the generated modinfo and ModBuddy project.

Validation passed: actual-schema SQL and inheritance (including changed CP scalar fields), English keys and assets, all Lua 5.1 syntax, focused gameplay/save/event simulations repeated for five speeds, ten existing Boundless regression suites, 14 Pigeon plus 176 existing CP source checks, XML/VFS/manifest hashes, 68 decoded DDS textures and transparent masks. Original Coo master art, portraits, map, postal icons and flag were visually inspected outside the game. ZIP and LZMA/7z Civ5Mod packages are built in ignored `dist/`.

No native in-game run was performed. Game-start/selection, native turn accounting and event delivery, save/load, conquest, AI play, tooltip and texture integration still require the [manual checklist](Testing.md). The static diplomacy scene and standard Scout 3D model are intentional; all requested artwork is included. Later mods that change the baseline after this mod loads, or add unknown companion tables, require a compatibility audit. There are no external DLL or vanilla-file edits. See [Implementation.md](Implementation.md) and the original request for precise mechanics and limitations.

Created files:

- `Cool Wacky Civs 2 (v 5).modinfo`
- `TheRepublicOfPigeons/Art/PigeonAlpha128.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha16.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha24.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha256.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha32.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha45.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha48.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha64.dds`
- `TheRepublicOfPigeons/Art/PigeonAlpha80.dds`
- `TheRepublicOfPigeons/Art/PigeonDawn.dds`
- `TheRepublicOfPigeons/Art/PigeonFlag32.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon128.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon16.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon24.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon256.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon32.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon45.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon48.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon64.dds`
- `TheRepublicOfPigeons/Art/PigeonIcon80.dds`
- `TheRepublicOfPigeons/Art/PigeonLeader.dds`
- `TheRepublicOfPigeons/Art/PigeonLeaderScene.xml`
- `TheRepublicOfPigeons/Art/PigeonMap.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects128.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects16.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects24.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects256.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects32.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects45.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects48.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects64.dds`
- `TheRepublicOfPigeons/Art/PigeonObjects80.dds`
- `TheRepublicOfPigeons/Art/PigeonPortrait128.dds`
- `TheRepublicOfPigeons/Art/PigeonPortrait256.dds`
- `TheRepublicOfPigeons/Art/PigeonPortrait64.dds`
- `TheRepublicOfPigeons/CHANGELOG.md`
- `TheRepublicOfPigeons/README.md`
- `TheRepublicOfPigeons/SQL/00_PIGEON_Core.sql`
- `TheRepublicOfPigeons/SQL/01_PIGEON_Inheritance.sql`
- `TheRepublicOfPigeons/SQL/02_PIGEON_Effects.sql`
- `TheRepublicOfPigeons/SQL/03_PIGEON_Art.sql`
- `TheRepublicOfPigeons/SQL/10_PIGEON_Text.sql`
- `TheRepublicOfPigeons/UI/PigeonTrade.lua`
- `TheRepublicOfPigeons/UI/PigeonTrade.xml`
- `TheRepublicOfPigeons/docs/Delivery.md`
- `TheRepublicOfPigeons/docs/Implementation.md`
- `TheRepublicOfPigeons/docs/OriginalRequest.md`
- `TheRepublicOfPigeons/docs/SourceAudit.json`
- `TheRepublicOfPigeons/docs/Testing.md`
- `art-source/TheRepublicOfPigeons/CooAndCoopolis.png`
- `art-source/TheRepublicOfPigeons/InsigniaPreview.png`
- `art-source/TheRepublicOfPigeons/README.md`
- `docs/civilizations/TheRepublicOfPigeons.md`
- `tools/generate_pigeons.py`
- `tools/prepare_pigeon_art.py`
- `tools/tests/pigeon_assertions.lua`
- `tools/tests/pigeon_mock.lua`
- `tools/validate_pigeons.py`

Modified files:

- `README.md`
- `CHANGELOG.md`
- `CoolWackyCivs2.civ5proj`
- `tools/build_mod.py`
- `tools/prepare_art.py`
- `tools/validate_mod.py`
- `tools/audit_cp.py`
- `TheBoundlessCity/docs/SourceAudit.json`

Replaced the version 4 modinfo with version 5; retained the collection UUID and minimum compatible save version. The Boundless source audit changes only to include the additional pinned building-source hash. Boundless gameplay, art and persistence sources are unchanged.
