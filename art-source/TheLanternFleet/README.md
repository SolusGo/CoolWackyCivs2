# Lantern Fleet art sources

Five original raster paintings generated with the built-in image_gen tool: Leader.png, Dawn.png, Icon.png, Unit.png and Building.png. Prompts.json retains the complete prompts and provenance. Leader: Maren in her stormy lighthouse chamber. Dawn: ships returning toward the beacon. Emblem: glowing brass lantern. Unit/building: Beacon Cutter and Signal Lighthouse. No third-party reference image was used.

Run `python tools/compile_lantern_art.py` to compile this family's 40 legacy DXT5 mipmapped DDS textures only. Uses the existing DirectXTex texconv installation and collection gold-frame helper. The harbor map texture uses Dawn's harbor illustration. Alpha/flag silhouettes are simplified lantern geometry for native recoloring. Existing civilization assets are untouched.
