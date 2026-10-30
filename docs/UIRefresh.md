# Civilization interface refresh — 2026-10-31

Version 18 audits and refreshes all 9 visible custom interfaces in this collection. Invisible simulation-only contexts remain invisible.

## Recovery fixes

- Reconcile actual native fullscreen contexts as well as popup events. A missed city/diplomacy/popup close notification can no longer leave a permanent local blocker after returning to the map.
- Restore closed launchers on turn start, late turn-active flags, active-player changes, loading, parent-context restoration and bulk UI restoration; retired presentation hosts cannot touch a replacement context.
- Keep nested popup types independent. Handle Culture Overview completing before native dequeue, and never create a persistent blocker from a popup request that may be rejected.
- Hide during targeting, strategic view, city screens and other fullscreens. Keep UI state transient and never take over a gameplay SetUpdate dispatcher.
- Protect renderers against a failing row or control leaving a reentrancy latch set. Pending narrative acknowledgements remain under their original runtime ownership.
- Preserve the existing Boundless/Jin timing fixes, Cat instance pooling and civ-specific command validation. Jin keeps its render cache.

## Native presentation

Each interface receives its own illustrated skin, palette, nine-slice button states, framed list rows, visible native scrollbars and a concise in-world help tooltip. Existing control IDs and gameplay actions are retained. Dual Order, Masaya and Urgal also receive expanded HUD cards with clearer progress or army information.

| Civilization | Theme |
| --- | --- |
| THE BOUNDLESS WORKFORCE | Blueprint · `#d4b873` |
| CHAMPION TEAM | Circuit · `#eb8075` |
| MCPVP / SERVER BROWSER | Pixel · `#b2db6b` |
| THE BOOK OF PRAYER | Arches · `#dfc997` |
| THE HOUSEHOLD | Paws · `#e2b16e` |
| MR. GARVEY / ROLL CALL | Ruled · `#ddca86` |
| THE URGAL / BREWING STAND | Orbits · `#c396e9` |
| THE JIN DYNASTY | Heraldry · `#d3ad68` |
| THE THRESHOLD COURT | Arches · `#b49ee5` |

## Verification

`python tools/validate_ui_refresh.py` compiles the shipped Lua, checks XML control references and scrollbars, decodes every theme texture at its native pixel size and checks full legacy mip chains, and runs the presentation recovery contract under Lua 5.1. The main validator includes it.

The contract exercises 100 turn cycles, early native flags, missed exit events, nested/unknown popup recovery, completion-before-dequeue, targeting/strategic/bulk UI transitions, context hiding, reload, player changes and an injected renderer failure. It asserts zero calls to SetUpdate or ClearUpdate from the recovery layer. Every shipped keyboard callback is also executed with the screen gate closed to verify it yields input.

Previews in `art-source/UIRefresh/` are generated from the shipped XML geometry and DDS files with sample data and Windows fonts. **They are layout previews, not native game screenshots.** The workspace contact sheet is `UIRefreshReview.png`.

Civ V was not running during this pass; another game was active. Native acceptance remains to be performed after installing the updated package. For each civ: open/close its panel, inspect scrolling and text at 1280×768 and 1920×1080, enter/leave city and diplomacy screens, open/close Tech/Policy/Culture overviews, end a turn, and reload a save. Verify pending stories/choices remain available.

UI changes do not introduce a new save schema or rebalance abilities. The release build also reapplies the existing icon-finishing pipeline to registered atlases.
