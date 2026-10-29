# Honeycomb Commonwealth artwork

Created with the built-in **imagegen** tool, one request per original asset. [Prompts.json](Prompts.json) retains the exact final prompts. Originals: `Mellia.png`, `CivIcon.png`, `Forager.png`, `Exchange.png`.

Mellia's painting supplies diplomacy, the 1024×768 Dawn export and portrait crop. The emblem shows a golden bee on honeycomb with a gold rim; the Forager surveys flowering land; the Exchange is a hexagonal wax marketplace. `Icon.png`, `Portrait.png`, `Objects.png`, `Alpha.png` and `Preview.png` are export masters/previews. The monochrome bee, unit flag and hive map use the collection's code-native workflow.

`tools/prepare_honeycomb_art.py` performs technical crops/resizes, existing gold-rim framing and real legacy RGBA DDS encoding with complete mipmaps. It writes 40 textures/static-scene XML in `TheHoneycombCommonwealth/Art` and three retained atlas masters in `art-source/IconAtlasMasters`. No referenced asset remains only in the generation tool's default directory. No unrelated art or shared unit models are replaced.

No missing texture or corrupt placeholder is used. The normal Scout model is the explicit 3D fallback; diplomacy uses an original static painting without animation or voice.
