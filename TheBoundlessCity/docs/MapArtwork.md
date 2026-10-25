# Civilization map artwork repair — 2026-10-26

The civilization selection screen showed the First Architect painting in its map slot. `tools/prepare_art.py` created `BoundlessMap.dds` by resizing the same `ArchitectAndWorld.png` used for the leader/loading scene. The civilization's `MapImage` reference was already correct; its texture content was wrong.

The map now has its own original parchment atlas: a continuous golden city plan, river crossings, coastline and connected island districts. [Source artwork, exact built-in image-generation prompt and provenance](../../art-source/TheBoundlessCity/README.md) are retained in the repository.

The installed Firaxis `Assets/UI/FrontEnd/GameSetup/GameSetupScreen.xml` defines `LargeMapImage` as 360×410, and its Lua selects `Civilizations.MapImage` directly. `tools/prepare_boundless_map.py` fits the map into the upper-left 360×410 window of a 512×512 legacy RGBA DDS, with transparent right/bottom gutters and a complete mip chain. [BoundlessMapPreview.png](../../art-source/TheBoundlessCity/BoundlessMapPreview.png) shows the active window.

Regenerate only this asset with:

```powershell
python tools/prepare_boundless_map.py
```

The general art pipeline now calls that compiler, so future regeneration keeps the dedicated map. `BoundlessMap.dds`, its VFS name, civilization SQL reference, collection version 14 and save formats stay unchanged. The leader, Dawn scene, portraits, UI textures and other civilization artwork are preserved.

Validation checks the decoded DDS, active-window pixels, transparent gutters, mip chain, actual SQL map binding and manifest/project/art package contracts. ZIP/7z archives are rebuilt and checked against stable source files. Native setup rendering still needs confirmation after restarting Civ V and selecting The First Architect.
