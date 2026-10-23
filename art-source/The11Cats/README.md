# The 11 Cats — retained 2D source artwork

`Emblem.png` is the original supplied 1254-square reference and is never overwritten. No individual reference photographs were available. The new paintings use the illustrated reference and the supplied coat/personality descriptions; they are not claims of exact photographic likeness. No stock images or external gameplay downloads are used.

## Selected sources and identity

`Portraits/` contains eleven separate high-resolution PNG paintings created with the built-in `image_gen` tool. `Prompts.json` records the exact prompt set, including Appa's targeted pose/arrowback revision. The selected files are retained inputs; rebuilding never calls an image service.

| Atlas index | Cat | Distinguishing treatment |
| --- | --- | --- |
| 0 | Austin | White long-haired, affectionate pale eyes, gold crown |
| 1 | Luna | Grey-and-white long-haired, pink heart pendant |
| 2 | Bonnie | Gentle calico/tortoiseshell-and-white, gold bell |
| 3 | Appa | Orange tabby, turned shoulder with dark arrow-shaped marking |
| 4 | Loki | Smooth black-and-white tuxedo, narrow blaze, blue collar |
| 5 | Kuro | Solid black, red bow collar |
| 6 | Oscar | Friendly rounder tuxedo, broader white muzzle, gold bell |
| 7 | Boomie | Petite calico, violet collar |
| 8 | Charlotte | Alert black-and-white, long white ruff |
| 9 | Sisi | Dark tortoiseshell with orange flecks, no white bib |
| 10 | Max | Friendly black-and-white, prominent forward white paws |

Collars are illustrated cues retained from the emblem or presentation choices, not new biographical claims. Gender/family/era metadata is independent of appearance and is regression-tested. All share soft painterly fur, golden side light, purple backgrounds and circular framing. `Identity.json` binds each source hash to its canonical atlas index and emblem position; `PortraitPreview.png` is a labelled QA sheet, not a game screenshot.

`Sources/Leader.png` depicts Austin on a purple cushion in a welcoming home. `Sources/Dawn.png` shows the first companions Austin and Luna, with room for a growing family. `Sources/CatTree.png` is a clear sisal-post/perch/cubby painting. `Sources/Household.png` supplies a quiet dark plum field with cream parchment, gold rules and small corner paws, keeping bright text readable.

## Deterministic assembly and conversion

`tools/prepare_cats_art.py` assembles `Group.png` from exactly eleven nonoverlapping named medallions, with larger central Austin. No generative counting or duplicate faces are used in this emblem. `Icon.png`, `Portrait.png`, `Cats.png` (4 columns × 3 rows, final slot transparent) and `Objects.png` (Cat Tree, Luna House Cat) are built directly from retained originals. `Alpha.png` and the flag use a refined four-toe paw and open crown; small 16–80px civilization icons use the clear symbol rather than the group. No decorative text is baked into game art.

All 50 DDS filenames, dimensions, atlas definitions and indices are preserved. Four scene/map textures use legacy DXT5/BC3 with full mip chains; aligned portrait atlases are finished as DXT5, nonaligned cells as legacy RGBA, and tintable alpha/flag textures retain white alpha masks. No DX10 header is emitted. Cats atlas masters are updated from uncompressed PNG sources in `art-source/IconAtlasMasters`, and their finished cells skip the old rim-trimming crop so ears and Austin's crown remain inside the frame. Peer families retain their existing crop behavior.

```powershell
python tools/prepare_cats_art.py
python tools/build_mod.py --manifest-only
python tools/verify_cats_art.py
python tools/validate_cats.py
```

The repeat-build check compares exact output bytes and all peer artwork using the same Pillow/DirectXTex environment. Do not refresh these masters from already framed DDS textures: that would introduce cumulative resampling. Technical masks, resizing, atlas composition and compression are offline operations; source paintings remain untouched.

**Existing House Cat 3D unit models and animations were not modified.** This pass neither investigates nor changes meshes, rigs, formations, art defines or movement visuals. Native game texture/rendering acceptance remains pending.
