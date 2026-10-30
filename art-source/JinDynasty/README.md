# Original Jin artwork

**Current graphics:** the [2026-10-30 full visual refresh](VisualRefresh/README.md) supersedes the compiled textures described below. All five new painted inputs, atlas masters, prompt specifications and layout previews are retained in VisualRefresh/. `prepare_jin_art.py` now invokes that complete 82-texture compiler. The files and original generation record below are preserved as the initial 2026-10-26 artwork, not the current production inputs.

`Aguda.png` was generated with the built-in imagegen tool on 2026-10-26. It is an original historical interpretation of Aguda, not an official portrait or redistributed Age of Empires artwork. The approved generated output is retained in this repository. The leader, portrait crop and Dawn DDS derive from that one painting.

Exact prompt:

> Create an original painted historical strategy game loading screen, landscape 16:9. Wanyan Aguda, Jurchen founder of the Jin Dynasty of 1115, a weathered northeast Asian man in his late forties, narrow moustache and beard, fur-trimmed dark crimson lamellar armor and gold fittings, holding a sheathed sword, shown waist-up on the LEFT THIRD facing slightly right. Northern Chinese timber palisades and a Jurchen pagoda, rolling pasture and small heavily armored cavalry in the distant RIGHT HALF. Cold dawn mist, deep imperial crimson and antique gold, restrained cinematic historical oil painting, believable 12th-century materials. No modern symbols, no text, no lettering, no logos, no borrowed game artwork. Strong readable face suitable for a circular portrait crop. Complete original composition.

`tools/prepare_jin_art.py` draws original geometric insignia, twelve distinct unit medallions/monochrome flags, ten building/Landmark symbols, five dedicated HUD symbols and a schematic historical map, then compiles 63 legacy mipmapped DDS files. PNG masters and the preview are retained here; the collection atlas finisher retains its own untouched inputs in `art-source/IconAtlasMasters/JIN_*.png` and applies consistent gold rims/padding. Alpha/flags remain monochrome for engine tinting. No generated art is referenced outside the repository.

The preview was visually inspected; the original loading painting was inspected when generated. Native setup/UI/model rendering remains unverified. Existing Civ V models and animations are used; no custom 3D unit artwork, audio or projectile effects are claimed.
