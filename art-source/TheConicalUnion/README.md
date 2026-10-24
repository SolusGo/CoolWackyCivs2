# Conical Union original artwork

Four original raster images were created with the **built-in imagegen tool** on 2026-10-25 for this civilization. No third-party images or custom 3D unit models are included. These are finished original illustrations, not temporary asset stand-ins. The static leader painting is reused for the silent Dawn scene; the Worker 3D model is inherited unchanged.

| Source | Use |
| --- | --- |
| `Bollard.png` | Leader throne scene, cropped portrait and Dawn of Man. |
| `ConeEmblem.png` | Orange cone civilization medallion. |
| `RoadCrew.png` | Unique Worker icon, tools/plans/paving materials. |
| `DetourOffice.png` | Walls replacement icon, municipal defenses, cones and signage. |
| `Preview.png` | Deterministic source contact sheet from the compiler. |

`tools/prepare_conical_art.py` compiles these sources to 40 legacy RGBA DDS files with full mip chains: four nine-size atlas families (civilization/alpha/leader/two-slot objects), 32px flag, 1600×900 leader, 1024×768 Dawn and 512×512 schematic map. The map is an original code-drawn administrative road-network illustration. Monochrome cone/flag marks are original code-drawn silhouettes for native player tinting.

The collection builder's `standardize_icons.py` retains the largest color masters in `art-source/IconAtlasMasters/CONICAL_*.png`, adds the shared gold rim and transparent padding, and encodes block-aligned atlases as legacy DXT5. Other sizes retain legacy RGBA. Both paths use complete mipmaps for this civilization; no DX10 DDS headers. Object slot 0 is Detour Office; slot 1 is Road Crew. Alpha/flag sheets are untinted white with transparent band cutouts. The DDS outputs and gold framing are deterministic; generation itself is not a reproducible pixel-for-pixel operation.

Rebuild with `python tools/prepare_conical_art.py` then `python tools/build_mod.py --manifest-only`. Only after deliberately changing source images, refresh these three families from newly regenerated unframed outputs:

```powershell
python tools/standardize_icons.py --refresh-sources CONICAL_CIV_ATLAS CONICAL_OBJECT_ATLAS CONICAL_LEADER_ATLAS
```

All assets are under this repository, including originals and retained atlas masters. Native selection/diplomacy rendering still requires game acceptance. The exact prompt set follows.

## Bollard.png

> Use case: stylized-concept. Original Civilization V mod leader illustration, wide 16:9 landscape. High Marshal Bollard is a towering SENTIENT ORANGE TRAFFIC CONE, an actual cone not a human wearing one, with broad silver reflective ceremonial bands and tiny dignified eyes. Seated upright on an elaborate throne made from discarded road signs, arrows and metal signposts. Regal grand municipal bureaucratic chamber, orange banners, construction barriers, polished dark stone, warm dramatic light. Detailed serious painterly strategy-game art, intentionally ridiculous subject rendered with conviction. Cone ruler dominates center; full throne visible, beautiful chamber behind. No writing, no logos, no watermarks. Finished production art.

## ConeEmblem.png

> Use case: stylized-concept. Original square Civilization V civilization emblem for The Conical Union. One bold upright orange traffic cone, broad white silver reflective stripes and dark wide base, centrally placed, dramatic black industrial metal circular medallion background. Simple strong silhouette, orange and white prominent, crisp detailed painterly enamel, luxurious but restrained bronze gold circular rim, dark charcoal outside. Identifiable at 32 pixels. Centered symmetrically with generous padding. No letters, no text, no logo, no watermark. Finished game icon.

## RoadCrew.png

> Use case: stylized-concept. Original square Civilization V unique civilian unit icon: Road Crew of a nation of SENTIENT TRAFFIC CONES. One upright bright orange traffic cone construction worker, two silver-white reflective bands, small dignified eyes; not a human wearing a cone. A shovel and pickaxe crossed behind it, orderly rolled road plans at its base, a few grey paving stones. Dark charcoal industrial background. Detailed serious painterly game illustration matching brass gold Civ V medallions, strong centered silhouette readable at small icon sizes. Square composition and generous padding. No writing, no text, no watermark. Finished original game artwork.

## DetourOffice.png

> Use case: stylized-concept. Original square Civilization V unique building icon, Detour Office for a nation of sentient orange traffic cones. Imposing dignified municipal administration building, symmetrical pale stone facade, defensible heavy stone walls and parapets, grand central doorway, orange banners with white reflective chevrons. Two traffic cone clerks at the steps, a few construction barriers and clear arrow-shaped detour signs. Detailed serious painterly strategy-game icon, warm orange and bronze lights against dark charcoal backdrop. Strong building silhouette, centered whole building within generous padding; optional restrained gold medallion rim. Readable small icon. No lettering, no writing, no logos, no watermarks. Finished original game artwork.
