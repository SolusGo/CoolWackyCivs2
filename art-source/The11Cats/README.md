# The 11 Cats art source

`Emblem.png` is the exact supplied 1254×1254 image, copied without altering it. It already depicts Austin as a white, long-haired crowned King. No separate family reference photographs were available. No external artwork was downloaded.

`tools/prepare_cats_art.py` normalizes a working copy to 1280 square for reproducible crop coordinates. `Cats.png` is a 4×3 atlas in canonical order: Austin, Luna, Bonnie, Appa / Loki, Kuro, Oscar, Boomie / Charlotte, Sisi, Max, unused. Crops are assigned from the supplied appearances. **Sisi uses the dark tortoiseshell face in the lower-left inset**. The decorative tail is excluded from the eleven portraits. These are illustrated source crops, not exact photographic matches.

`Icon.png` retains the full group for larger civ imagery; 16–48px civ cells use a clean paw/crown/11 symbol. `Portrait.png` crops white Austin. `Objects.png` contains the custom Cat Tree drawing and Luna House Cat icon. `Alpha.png` and the unit flag are transparent white paw/crown silhouettes for native tinting. Full group artwork supplies leader, Dawn of Man, Household background and map/loading imagery.

All 50 game textures are built as legacy DDS with complete mip chains. The standard atlas finisher adds the collection's transparent padding/gold rims and compiles aligned cells to DXT5; nonaligned cells use RGBA. Alpha/flag art remains tintable. Atlas indices, dimensions and references are checked by `validate_cats.py` and the collection validator. Retained atlas masters live in `art-source/IconAtlasMasters` to prevent cumulative resampling.

Rebuild with `python tools/prepare_cats_art.py`, then `python tools/build_mod.py --manifest-only`. To intentionally replace the retained largest atlas artwork, refresh only the affected `THE11CATS_*_ATLAS` master through `standardize_icons.py --refresh-sources` before rebuilding. No conversion runs or downloads are needed during gameplay.
