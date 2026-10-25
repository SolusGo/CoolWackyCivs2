# Original asset provenance

`ArchitectAndWorld.png` was generated using the built-in imagegen tool on 2026-10-12. It is copied into this repository and does not depend on the user's generated-image cache. It depicts an original fictional First Architect with an ivory/gold/deep-blue interconnected world city. `InsigniaPreview.png` previews code-drawn civilization, Registry and Surveyor icons.

Final prompt:

> Use case: stylized-concept. Asset type: Civilization V mod Dawn of Man and diplomacy artwork, landscape composition. Create an original richly painted historical fantasy scene for The Boundless City, a single medieval settlement whose unending interconnected metropolis spans an entire world. Foreground left third: The First Architect, a dignified older androgynous human master builder, full upper body in deep navy and ivory ceremonial robes with tasteful gold architectural motifs, holding a parchment city plan and brass compass, face clearly visible. Background center and right: an impossibly vast ivory medieval metropolis with golden domes, deep blue roofs, bridges and aqueducts sweeping continuously over coastlines and distant islands towards a curved horizon; sunrise, quiet ambition, intricate hand-painted stone details. Elegant gold, ivory, and deep blue palette. Polished strategy-game loading illustration, believable architecture, dramatic atmospheric depth. 1536 by 1024 landscape. No writing, no lettering, no watermark, no UI, no collage.

`tools/prepare_art.py` prepares supported DDS sizes/crops and draws the geometric insignia. The source portrait/scene supplies the Dawn, static diplomacy and leader portraits. The 3D Worker model remains the active game's own model; no Firaxis model or unrelated placeholder artwork is redistributed. Icon atlas names are registered by `03_BC_Art.sql`; the civilization identity references the map and Dawn images. The [Workforce interface artwork](WorkforceUI/README.md) has its own sources and compiler.

## Dedicated civilization map — 2026-10-26

`BoundlessCityMap.png` is an original overhead fantasy atlas generated with the **built-in image_gen tool**, replacing the reused leader painting in the map slot. The exact final request is preserved in [BoundlessCityMap.prompt.txt](BoundlessCityMap.prompt.txt). No CLI fallback or third-party artwork was used.

`tools/prepare_boundless_map.py` compiles it to `TheBoundlessCity/Art/BoundlessMap.dds`: a 360×410 active window on a transparent 512×512 legacy RGBA canvas, with full mipmaps. `BoundlessMapPreview.png` shows that window at its display size. The general art script calls this dedicated compiler; leader artwork remains sourced from `ArchitectAndWorld.png`. See [MapArtwork.md](../../TheBoundlessCity/docs/MapArtwork.md).

![Civilization map display preview](BoundlessMapPreview.png)
