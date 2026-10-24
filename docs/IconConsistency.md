# Civilization icon framing

The Conical Union (version 13) adds four original generated images and the same
nine-size atlas families, monochrome flag, silent Dawn and static leader scene.
Its mipmapped textures compile with `tools/prepare_conical_art.py`; originals and
exact prompts are in `art-source/TheConicalUnion`. Existing atlas slots are preserved.

Saba (version 11) adds nine-size civilization/alpha/object/leader atlas families,
a 32px unit flag and original static leader/loading art through the same pipeline.
Source art and the exact generation prompt are retained in
`art-source/KingdomOfSaba`; `tools/prepare_saba_art.py` builds its DDS inputs.
Existing civilization artwork is preserved.

Version 6 finishes both civilizations' existing leader portraits, civilization
emblems and unique unit/building icons with matching beveled gold rims.

Leader artwork uses 75% of its atlas cell: a 96px circle in the 128px portrait
slot, with 16px transparent padding on each side. This fits the installed
base-game civilization selector's 100px rows. Other colour medallions use 90%
of their cell. Atlas dimensions, cell indices and filenames are preserved.
Alpha atlases and unit flags remain monochrome for the game to tint.

`tools/standardize_icons.py` retains the original largest DDS atlases as
lossless PNG masters in `art-source/IconAtlasMasters/`. Every rebuild uses
those masters, preventing cumulative cropping or resizing. The builder runs
this step before generating manifests. It needs Pillow and Microsoft
DirectXTex `texconv` on PATH or in its WinGet directory. Block-aligned outputs
use legacy DXT5; non-aligned outputs, including 45px cells, use legacy RGBA.

```powershell
python tools/standardize_icons.py --check
python tools/build_mod.py
```

After deliberately regenerating original art, refresh only the affected atlas
masters; for example:

```powershell
python tools/prepare_pigeon_art.py
python tools/standardize_icons.py --refresh-sources PIGEON_CIV_ATLAS PIGEON_OBJECT_ATLAS PIGEON_LEADER_ATLAS
```

Do not refresh masters from already finished output. The main validator now
decodes all atlas textures, checks declared dimensions and centred padding,
and samples gold around every finished medallion. The texture preview has been
visually checked; a live civilization-selection check remains necessary,
particularly when another mod replaces the setup UI.
