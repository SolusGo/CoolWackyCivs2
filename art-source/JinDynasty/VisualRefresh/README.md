# Jin Dynasty full visual refresh — 2026-10-30

All five painted inputs were generated with the built-in **imagegen** tool, then copied into this directory. These are original historical interpretations, not redistributed Age of Empires assets. The previous paintings/geometric masters remain in the parent directory as historical source material.

| Retained input | Purpose |
| --- | --- |
| Leader.png | Aguda leader scene, Dawn image, circular portrait and council header |
| UnitPaintings.png | Twelve unit illustrations, exact four-column/three-row atlas order |
| BuildingPaintings.png | Ten building/Landmark illustrations, five columns/two rows |
| UpgradePaintings.png | Thirteen named upgrades plus Horse HP, Garden and temporary defender illustrations; four by four |
| Map.png | Decorative parchment map; an artistic regional interpretation, not a precise political-boundary dataset |

[Prompts.md](Prompts.md) records the generation specifications. The selected source pixels are retained, so asset compilation does not require regenerating any image or making network calls.

`python tools/prepare_jin_art.py` invokes `prepare_jin_visuals.py`: deterministic atlas slicing, standard native medallion framing, high-resolution monochrome insignia, five HUD symbols in two sizes, a drawn lacquer/gold interface skin and complete legacy RGBA DDS mip chains. It updates the Jin-only atlas masters used by the collection finisher. The compiler also generates the XML layout through `generate_jin_ui.py`. Other civilizations' art is untouched.

`python tools/preview_jin_visuals.py` executes the shipped Jin Lua and renders its actual XML/textures at 1280×720 and 1920×1080. These are **modeled layout previews**, not native screenshots: font metrics are approximated, and packed vanilla unit portraits use a crest placeholder. `ArtOverview.jpg` is a contact sheet, not a game screenshot. Original paintings and compiled native assets were visually inspected.

The update covers all 63 previously shipped Jin DDS textures and adds 19, for 82 total. Animated in-world models remain Civ V assets; Zhanma's rifleman appearance is corrected to the existing sword-bearing Samurai model. No custom GR2 models, skeletal animations or new projectile effects are claimed. Full coverage, testing and installation notes are in [Graphics.md](../../../JinDynasty/docs/Graphics.md).
