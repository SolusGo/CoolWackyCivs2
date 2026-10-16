# Original McPvP artwork

`tools/prepare_mcpvp_art.py` draws all imagery deterministically from geometric shapes with Pillow. `Lobby.png` is an original night-time block arena, spawn hall and generic competitors, used for loading, diplomacy and the map illustration. `Portrait.png` and the emblem/object/promotion strips are original symbols. No Minecraft texture, third-party illustration, music or voice asset is used.

The 48 shipped DDS textures cover nine sizes for five atlases plus leader, dawn and map images. The collection's standard icon finishing supplies matching gold rims and leader padding from four retained original masters in `art-source/IconAtlasMasters/`. Player-color alpha masks stay monochrome. The battlefield model and unit flag retain the native Scout definitions inherited from CP.

Regenerate the geometric sources with `prepare_mcpvp_art.py`, then refresh only the four `MCPVP_*` color atlas sources in `standardize_icons.py` before rebuilding manifests. No manual asset preparation is required. This release uses static diplomacy and no custom audio.
