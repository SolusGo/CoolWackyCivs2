# Unrung Bell original artwork

Four original raster assets were generated with the built-in **imagegen** tool on 2026-10-25. They are finished generated illustrations, not stock portraits or placeholder game assets. No external API/CLI was used. Source prompts are retained in [Prompts.md](Prompts.md).

| Source | Use |
| --- | --- |
| `Sable.png` | Silent static leader background, Dawn of Man and cropped portrait. |
| `ChainedBell.png` | Civilization emblem, silver chained bell against dark navy. |
| `SilentBelfry.png` | Building portrait, chained bell in a candlelit stone belfry. |
| `Bellwarden.png` | Unit portrait, charcoal/silver pikeman and bell tabard. |
| `Preview.png` | Contact sheet of the four implemented crops. |

`python tools/prepare_unrung_art.py` compiles 48 legacy DDS textures with full mip chains: five atlas families at nine sizes (16/24/32/45/48/64/80/128/256), a 1600×900 leader background, 1024×768 Dawn background and 512×512 illustrative kingdom map. Alpha is preserved for the code-authored tintable bell and promotion badges. The map is decorative fictional geography. Pikeman 3D models, flags and strategic-view art remain inherited.

`python tools/build_mod.py --manifest-only` registers the files and runs the collection's `standardize_icons.py`, compiling three colored portrait families with centered gold rims using DirectXTex DXT5, with uncompressed legacy RGBA at non-block-aligned sizes. Retained pre-frame atlas masters are in `art-source/IconAtlasMasters/UNRUNG_*256.png`; later builds use those masters rather than repeatedly framing the output. Promotion badges carry their own rim; alpha atlas stays tintable. After regenerating original colored atlas artwork intentionally, run `python tools/standardize_icons.py --refresh-sources UNRUNG_CIV_ATLAS UNRUNG_OBJECT_ATLAS UNRUNG_LEADER_ATLAS` before updating manifests.

DDS decoding/dimensions and framing are checked automatically. Actual game rendering, mip selection, small icons, strategic view and leader scene remain manual acceptance tests. There is no custom animation, voice or 3D model.
