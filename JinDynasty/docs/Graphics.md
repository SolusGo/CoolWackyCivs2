# Full Jin visual refresh — 2026-10-30

This updates the entire shipped Jin 2D visual set, rather than only the council panel. Five original painted inputs were generated using the built-in imagegen tool; sources and [generation specifications](../../art-source/JinDynasty/VisualRefresh/Prompts.md) are retained in the repository. The original source paintings are preserved as historical material.

| Visual group | Compiled textures | Change |
| --- | ---: | --- |
| Civilization medallion / tintable insignia | 18 | Painted horse-head identity and cleaner high-resolution monochrome heraldry |
| Leader portrait / leader scene / Dawn | 11 | New detailed Aguda painting, intentional portrait crop and loading composition |
| Unit portraits / flags | 18 | Twelve distinct illustrated units, including an actual antlered Reindeer Trader; supersampled tintable flags |
| Buildings / Landmarks | 9 | Ten painted architectural vignettes in existing atlas slots |
| Upgrades / promotion icons | 9 | New sixteen-cell atlas: thirteen named upgrades and Horse/Garden/defender effects |
| Civilization map | 1 | Illustrated parchment regional map; artistic interpretation, not precise boundaries |
| Council header | 1 | Illustrated banner drawn from the new painting |
| HUD symbols | 10 | Five consistent medallions at 32 and 64 pixels |
| Interface materials | 5 | Lacquer panel, resource card, illustrated row, native four-state buttons and selected-tab accent |
| **Total** | **82** | **All 63 old DDS textures replaced, 19 added** |

The council keeps the 980×680 footprint, six tabs, native scroll controls and all actions. Five metric cards replace the dense summary block; 64-pixel atlas portraits, clearer row titles/status, selected-tab markers and matching buttons improve hierarchy. The launcher hides while the council is open. The turn-start/load recovery fix, cached refreshes, closed-panel row avoidance and action validation remain covered by the executable suites.

In-world art still uses native Civ V models and animations. Zhanma now references the installed sword-bearing Samurai model rather than a Rifleman, a visual stand-in without stat changes. This pass does not create custom GR2 models, skeletons or particle effects. Other units retain their native animated models. There is no new DLC requirement beyond the existing game/mod requirements.

`validate_jin_visuals.py` verifies every old texture changed, all 82 files decode, each has a complete legacy mip chain, flags remain monochrome/tintable, every UI style exists in installed Styles.xml, new textures resolve, and the frame/cards fit 1280×720 and 1920×1080. It activates old/current SQL against the same database and requires identical gameplay columns; only icon metadata, the new atlas and Zhanma's model reference differ. `GraphicsValidation.json` records the results. The existing sixteen Jin suite/speed runs also cover cards, thirteen distinct upgrade portraits, selected tabs and twenty turn transitions.

Reproduce: `python tools/generate_jin.py`, `python tools/prepare_jin_art.py`, `python tools/validate_jin.py`, `python tools/validate_jin_visuals.py`, `python tools/preview_jin_visuals.py`, then `python tools/build_mod.py --manifest-only --preserve-art`. The collection finisher also retains Jin mip chains during ordinary future builds. No other civilization's texture or gameplay source is changed.

[Art contact sheet](../../art-source/JinDynasty/VisualRefresh/ArtOverview.jpg) · [1280 panel preview](../../art-source/JinDynasty/VisualRefresh/UI-Landmarks-1280.png) · [1920 panel preview](../../art-source/JinDynasty/VisualRefresh/UI-Landmarks-1920.png).

Previews execute shipped Lua/XML with modeled fonts and placeholders for packed vanilla portraits. They are not native game screenshots. Native rendering, font wrapping, animation and real saves still need an in-game check. Restart Civ V after installation and reload the same save; version 17, the UUID, gameplay values and save schemas are unchanged.
