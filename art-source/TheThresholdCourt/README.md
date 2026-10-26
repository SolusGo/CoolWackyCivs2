# Threshold Court art sources

`QueenElsewhere.png` and `Hingeguard.png` were generated using the built-in imagegen tool on 2026-10-26. [Exact prompts](Prompts.md). `Preview.png` shows the civ symbol, queen portrait, guardian and Threshold House.

`tools/prepare_threshold_art.py` compiles the retained paintings, deterministic doorway heraldry/alpha, house/promotion symbols and illustrative kingdom map into 48 legacy RGBA mipmapped DDS textures. The collection standardizer retains atlas masters in `art-source/IconAtlasMasters`, then applies the normal gold frame/padding. The queen portrait crop is source-relative and all nine atlas sizes are generated. The static leader scene references `THC_Leader.dds`; no missing texture fallback or new 3D model is required. Hingeguard uses the inherited Pikeman field model/flag.

Rebuild with `python tools/prepare_threshold_art.py` followed by `python tools/build_mod.py --manifest-only`. When intentionally revising an existing atlas master, use `tools/standardize_icons.py --refresh-sources THC_CIV_ATLAS` (and the corresponding changed atlas families) per the collection icon documentation.
