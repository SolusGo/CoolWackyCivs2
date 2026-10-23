# Workforce graphical update — 2026-10-24

The Boundless Workforce now uses original engraved-city artwork, a dark teal civic desk, brass edging, separate summary wells and matching textured controls. This pass focuses on the Boundless panel.

- Six custom DDS textures provide the panel, launcher, row, native nine-slice buttons and status marks. The retained [source artwork, prompt and preview](../../art-source/TheBoundlessCity/WorkforceUI/README.md) make them reproducible.
- The 900×700 panel keeps its existing controls, fifteen statistics, overview scrolling, paging and military view. Three complete 66px rows now fit the 210px district viewport.
- Population, remote workers and Frontier Culture have stronger visual hierarchy. Teal marks identify assigned districts or ready military actions; amber marks identify pending requests. Existing text/buttons also communicate these states.
- Six native yield glyphs replace long repeated yield names. Hover tooltips retain the full names and values. Each refresh reads a row's yields once and uses the same snapshot for its text and tooltip.
- Decorations ignore mouse input. Local GridData textures use the game's existing button slice/state geometry; vanilla styles and peer panels are not replaced.

There are no gameplay, Food, reservation, expansion, save-format, SQL or balance changes. UUID, collection version 12 and save compatibility remain unchanged. The earlier Food hotfix remains intact.

## Verification

`tools/validate_summary.py` verifies all six legacy DDS headers, dimensions, complete mip chains, exact lossless master pixels, four distinct button-state cells, XML references, click-through decoration and three-row fit. It also runs the existing localization, wrapping, screen-transition, military, callback, reload and read-only refresh checks. Added assertions follow actual assignment → pending under external automatons → assignment recovery and check icon text plus full-name tooltips.

Collection validation and archive verification cover manifest/project/VFS registration, DDS decoding and peer civilizations. The layout preview is composed from actual assets/XML geometry with approximate fonts and sample data. It does not verify the native renderer.

## Native check after restart

1. Open Workforce in the existing modded game. Check the city header, frame, summary labels and three complete district rows at your normal resolution/UI scale.
2. Hover, press and disable controls, including Previous on page one. Check their labels and state textures; click Locate/Assign/Lock and confirm decorative images do not intercept input.
3. Confirm assigned/pending marks agree with the text, yield icons appear, and full yield names appear in hover tooltips. Scroll the overview for the yield breakdown and any long labels.
4. Toggle military view, close with X/Escape, enter/leave the city and reopen the panel. Verify that the launcher returns and the existing screen guards still apply.

Native rendering and continuation are pending until performed in Civ V. Installation updates only matching Boundless UI files/textures and their manifest entries, after backing up the installed files and checking that Civ V is closed.
