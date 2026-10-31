# Lantern Fleet file inventory

Paths below are relative to the collection root. Existing civilization gameplay and artwork are unchanged.

## New files

- `TheLanternFleet/Art/LANTERN_Alpha128.dds`
- `TheLanternFleet/Art/LANTERN_Alpha16.dds`
- `TheLanternFleet/Art/LANTERN_Alpha24.dds`
- `TheLanternFleet/Art/LANTERN_Alpha256.dds`
- `TheLanternFleet/Art/LANTERN_Alpha32.dds`
- `TheLanternFleet/Art/LANTERN_Alpha45.dds`
- `TheLanternFleet/Art/LANTERN_Alpha48.dds`
- `TheLanternFleet/Art/LANTERN_Alpha64.dds`
- `TheLanternFleet/Art/LANTERN_Alpha80.dds`
- `TheLanternFleet/Art/LANTERN_Dawn.dds`
- `TheLanternFleet/Art/LANTERN_Flag32.dds`
- `TheLanternFleet/Art/LANTERN_Icon128.dds`
- `TheLanternFleet/Art/LANTERN_Icon16.dds`
- `TheLanternFleet/Art/LANTERN_Icon24.dds`
- `TheLanternFleet/Art/LANTERN_Icon256.dds`
- `TheLanternFleet/Art/LANTERN_Icon32.dds`
- `TheLanternFleet/Art/LANTERN_Icon45.dds`
- `TheLanternFleet/Art/LANTERN_Icon48.dds`
- `TheLanternFleet/Art/LANTERN_Icon64.dds`
- `TheLanternFleet/Art/LANTERN_Icon80.dds`
- `TheLanternFleet/Art/LANTERN_Leader.dds`
- `TheLanternFleet/Art/LANTERN_LeaderScene.xml`
- `TheLanternFleet/Art/LANTERN_Map.dds`
- `TheLanternFleet/Art/LANTERN_Objects128.dds`
- `TheLanternFleet/Art/LANTERN_Objects16.dds`
- `TheLanternFleet/Art/LANTERN_Objects24.dds`
- `TheLanternFleet/Art/LANTERN_Objects256.dds`
- `TheLanternFleet/Art/LANTERN_Objects32.dds`
- `TheLanternFleet/Art/LANTERN_Objects45.dds`
- `TheLanternFleet/Art/LANTERN_Objects48.dds`
- `TheLanternFleet/Art/LANTERN_Objects64.dds`
- `TheLanternFleet/Art/LANTERN_Objects80.dds`
- `TheLanternFleet/Art/LANTERN_Portrait128.dds`
- `TheLanternFleet/Art/LANTERN_Portrait16.dds`
- `TheLanternFleet/Art/LANTERN_Portrait24.dds`
- `TheLanternFleet/Art/LANTERN_Portrait256.dds`
- `TheLanternFleet/Art/LANTERN_Portrait32.dds`
- `TheLanternFleet/Art/LANTERN_Portrait45.dds`
- `TheLanternFleet/Art/LANTERN_Portrait48.dds`
- `TheLanternFleet/Art/LANTERN_Portrait64.dds`
- `TheLanternFleet/Art/LANTERN_Portrait80.dds`
- `TheLanternFleet/CHANGELOG.md`
- `TheLanternFleet/docs/Implementation.md`
- `TheLanternFleet/docs/Testing.md`
- `TheLanternFleet/docs/Validation.json`
- `TheLanternFleet/Lua/LANTERN_Harbors.lua`
- `TheLanternFleet/Lua/LANTERN_Harbors.xml`
- `TheLanternFleet/Lua/LANTERN_TimingProbe.lua`
- `TheLanternFleet/README.md`
- `TheLanternFleet/SQL/00_LANTERN_Core.sql`
- `TheLanternFleet/SQL/01_LANTERN_Inheritance.sql`
- `TheLanternFleet/SQL/02_LANTERN_Effects.sql`
- `TheLanternFleet/SQL/03_LANTERN_Art.sql`
- `TheLanternFleet/SQL/10_LANTERN_Text.sql`
- `art-source/TheLanternFleet/Building.png`
- `art-source/TheLanternFleet/Dawn.png`
- `art-source/TheLanternFleet/Icon.png`
- `art-source/TheLanternFleet/Leader.png`
- `art-source/TheLanternFleet/Preview.png`
- `art-source/TheLanternFleet/Prompts.json`
- `art-source/TheLanternFleet/README.md`
- `art-source/TheLanternFleet/Unit.png`
- `TheLanternFleet/docs/Files.md` (this inventory)

## New development files

- `tools/generate_lantern.py`
- `tools/compile_lantern_art.py`
- `tools/validate_lantern.py`
- `tools/tests/lantern_mock.lua`
- `tools/tests/lantern_assertions.lua`

## Collection integration changes

- `tools/build_mod.py`: append civilization and one simulation entry; version 20 metadata and SQL ordering.
- `tools/validate_mod.py`: run Lantern validation.
- `tools/validate_rfd.py`: allow later appended civilizations while checking the same RFD SQL sequence.
- `tools/validate_t1zofgk.py`: compare the manifest with the builder version rather than hardcoding version 19.
- `tools/verify_release.py`: extract/check Lantern files in the built 7z archive.
- `CoolWackyCivs2.civ5proj`: generated file/action/entry registration.
- `Cool Wacky Civs 2 (v 20).modinfo`: replaces the version 19 manifest; same collection UUID/save compatibility version.
- `README.md`, `CHANGELOG.md`: roster, mechanics, status and version 20 installation.
- `docs/civilizations/TheLanternFleet.md`: short play guide.

Generated ZIP/7z packages and validation logs live in ignored `dist/` and `tools/reference/`; proprietary game files are not committed.
