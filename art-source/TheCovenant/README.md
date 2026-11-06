# Covenant original artwork

Five original paintings were generated with the built-in `image_gen` tool on 2026-11-06. Exact prompts and execution mode are retained in [Prompts.json](Prompts.json). The raw outputs are retained unchanged as `Scribe.png`, `Scriptorium.png`, `Tabernacle.png`, `Dawn.png` and `Map.png`; all runtime references point to compiled files inside `TheCovenant/Art`.

The visual identity is navy, ivory and old gold: the fictional Scribe among scrolls, a lamplit sandstone writing sanctuary, a linen tabernacle, a scholarly city at dawn and a fictional illuminated map. The Scripture/quill emblem and UI materials are deterministic code-native assets extending the pack's established heraldry/skin system. No extracted Egyptian/Ramesses stock images are shipped.

`CivIcon.png`, `Alpha.png`, `Portrait.png`, `UI_Panel.png`, `UI_Buttons.png` and `UI_Trim.png` are deterministic intermediates. Three unframed 256px atlas masters are retained in `art-source/IconAtlasMasters/COVENANT_*256.png` for the shared finisher. The preview is composed from actual compiled DDS exports.

## Compile and review

```powershell
.venv/Scripts/python.exe tools/prepare_covenant_art.py
.venv/Scripts/python.exe tools/build_mod.py --manifest-only --preserve-art
.venv/Scripts/python.exe tools/preview_covenant.py
.venv/Scripts/python.exe tools/validate_covenant.py
.venv/Scripts/python.exe tools/build_mod.py --preserve-art
.venv/Scripts/python.exe tools/verify_release.py
```

There are 43 legacy RGBA DDS files with full mip chains. Sizes 16, 24, 32, 45, 48, 64, 80, 128 and 256 are supplied for civilization, alpha, leader and two-cell building atlases. The static scene is 1600x900; Dawn is 1024x768; map is 512x512; flag is 32x32. UI materials are exactly 920x640, 44x180 (four native 44px states at a 45px stride), and 844x3. Native 3D models remain inherited.

`Preview.png` shows the finished atlas cells and scene exports. `UI-Study.png`, `UI-Reference.png`, `UI-Recall.png` and `UI-Error.png` render shipped Lua/XML state and DDS materials with modeled Windows font metrics. They are not native game screenshots. The study screen and Dawn image were later observed in native DX11; setup, Civilopedia, tinting, leader scenes and detailed-feedback/input acceptance remain pending.
