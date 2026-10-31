# Republic of First Drafts art sources

Six original raster masters generated with the built-in image generation tool on 2026-10-31. Final PNGs live in this folder. `tools/compile_rfd_art.py` packages them with Pillow for crop/scale/atlas framing and the existing DirectXTex converter for legacy DXT5 DDS with full mip chains. It writes only the new civilization's Art folder; released textures are retained. There are no external images or downloaded third-party art dependencies.

Shared exact prompt prefix for all six:

> Use case: stylized-concept. Original painted Civilization V expansion artwork for The Republic of First Drafts. Deep burgundy, parchment cream, antique gold, industrial black ink. Elegant scholarly eccentricity, warm light, painterly rich materials. No modern devices, no readable text, no watermark.

Each prefix was followed by this asset's exact prompt:

| Master | Prompt suffix |
| --- | --- |
| Leader.png | Landscape 4:3 diplomacy portrait. Elderly distinguished woman Editor-in-Chief Marginalia wearing enormous academic burgundy robe covered in fine handwritten annotations, crooked spectacles, seated behind desk piled with unfinished manuscripts, towering bookshelves and rewritten documents. Scholarly authoritative slightly comedic expression. Face and upper body in central half for circular icon crop. No border. |
| Dawn.png | Landscape 4:3 grand editorial chamber, ornate architecture, parchment manuscripts, tall bookshelves, drafting instruments and intricate architectural construction plans spread on huge desks; morning sun. Sweeping establishing scene. No border. |
| Icon.png | Square civilization emblem: elegant cream parchment manuscript with bold black corrections and prominent large quill pen, deep burgundy round background, gold circular outer rim. Simple strong silhouette readable at small sizes, centered with margin. No text. |
| Unit.png | Square unit portrait, heavy wheeled medieval mechanical Catapult launching an enormous barrel of black ink, splashing ink in air. Three quarter view, whole siege engine centered in square with margin for circular crop, parchment sky and dark burgundy pennant. No border. |
| Building.png | Square building portrait, ornate government engineering workshop with arched stone windows, huge drafting table visible through doorway, parchment construction plans, drafting instruments, unfinished architectural blueprints. Centered for circular crop. No border. |
| Map.png | Landscape 4:3 illustrated parchment fantasy map of a republic of scholarly cities along rivers, inked coastlines, burgundy urban markers and ornate quill compass rose, handwritten-looking corrections without readable labels. Cream and burgundy cartographic illustration. No text. |

The 37 atlas/flag textures include nine sizes each of the civ icon, alpha, two-cell building/unit atlas and leader portrait, plus a 32px unit flag. The three scene textures are a 1600×900 static leader, 1024×768 Dawn and 1024×768 map. Alpha/flag use a simple purpose-drawn monochrome parchment/quill silhouette. Normal Catapult 3D art is inherited from the game; static diplomacy is the intended valid fallback for a custom animated 3D leader.
