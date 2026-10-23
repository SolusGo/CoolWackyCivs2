# Saba artwork sources

`KaribilWatar.png` is original artwork generated with the **built-in imagegen tool**, 2026-10-23. [Prompt.txt](Prompt.txt) preserves the exact prompt. It is an artistic reconstruction, not an authenticated likeness, exact archaeological reconstruction or third-party photograph. It supplies static diplomacy, Dawn of Man and portrait crops. No animated leader, custom 3D unit or voice audio is claimed.

`tools/prepare_saba_art.py` draws the original twin-sluice/water-drop emblem, spear/shield Sentinel, masonry Cistern and schematic South Arabian map. PNG masters and `Preview.png` retain the production art. Symbols follow the existing collection's drawn medallion system. The map does not claim precise ancient borders. There are no missing-art placeholders.

The script compiles 40 mipmapped legacy DDS textures: nine sizes each for civ/alpha/leader/object atlases, one flag, leader scene, Dawn scene and map. Shared finishing supplies gold rims/portrait padding and legacy DXT5 when block aligned, otherwise RGBA. First registration retains PNG atlas masters in `art-source/IconAtlasMasters`.

Rebuild with `python tools/prepare_saba_art.py` and `python tools/build_mod.py --manifest-only`. After intentional art changes, refresh only the affected SABA atlas family via `standardize_icons.py --refresh-sources`. Existing sources need no generation service. Native rendering remains unverified.
