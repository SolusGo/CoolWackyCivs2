# The Boundless Workforce summary display — 2026-10-16

## Cause and evidence

The old `TXT_KEY_BC_SUMMARY` used literal `|` characters as visual separators. Civ V interprets those as boundaries between alternative localized text forms. Its first form was only `Population: {1_Num} `; Owned Plots and all following census/frontier fields belonged to later forms. Subjugation was appended separately after localization, explaining the reported Population plus Original Capitals Subjugated output. This is a formatting defect, rather than evidence that the census values were missing or that fourteen arguments exceed a native limit.

The current source and the installed read-only `cache/Localization-Merged.db` both contained that exact string in `LocalizedText`. The shipped `Localization-BaseGame.db` uses, for example, `Engineer|Engineers` with plurality `1|2`. The [pinned public SDK interface](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvLocalization/include/CvLocalization.h) exposes multiple forms and defaults `String::toUTF8`, Compose and Parse to form 1. Together these establish the form-selection explanation and match the symptom. The focused formatter model reproduces it; the native localization DLL was not executed by the test runner.

The old fixed 852×110 summary label was also fragile: fourteen values, five lines, wrapping, automaton warnings and subjugation shared its space. There was no native font measurement or screenshot capture available to establish additional live clipping. The replacement prevents content growth from overlapping the controls below.

## Implementation

`UI/BoundlessWorkforce.lua` now fills individual localized labels from the current `B.Summary` result: Population, Owned Plots, Local Workers, Remote Workers, Specialists, Idle Labourers, Unassigned Citizens, Available Citizens, Additional Remote Capacity, Maximum Remote Capacity, Pending Requests, Locked Requests, Frontier Culture and next-claim Culture cost. The fifteenth statistic, Original Capitals Subjugated, uses the existing live domination-progress function.

`UI/BoundlessWorkforce.xml` groups these under Territory, Workforce and Management. Labels have WrapWidth and natural height. After their vertical stacks recalculate, the tallest measured stack determines the summary body height. Summary, occupied-capital/automaton warnings and yields share a scrollable overview; the fixed controls and independently scrolling paged plot list remain outside it. The panel stays **900×700**. Longer translations or large values can extend the scroll content without growing the panel.

`SQL/10_BC_Text.sql` and its source dictionary in `tools/generate_database.py` supply small localized labels. The legacy combined key is retained with commas instead of reserved pipes. If the original capital is occupied, territory/progress/cost remain current; unavailable census data is labeled explicitly and the military/reclaim panel remains usable.

Existing game-data/city-data, BoundlessChanged, load, turn and screen-transition refresh paths are reused. No additional gameplay handlers, simulation owners or polling loops were added. Frontier formulas, Culture/Registry bonuses, citizen/yield calculations, military/victory rules, balance, UUID and saved schemas remain unchanged. Existing saves need no migration for this UI change.

## Automated verification

`tools/validate_summary.py` reads actual localization SQL, checks every label/token and verifies XML bounds, natural wrapping, scroll containment and the unchanged panel size. `summary_assertions.lua` runs after the existing UI fixture with a model of default-form selection and simple positional tokens. It checks all fields, zero and 2,147,483,647 values, long text, forced stack-height growth, real fixture census/ownership/frontier/Registry changes, row Assign/Release and Lock/Unlock, mode/priority/direction/sort controls, save/load, capital loss/return and screen transitions. UI-only refreshes perform no full-map scan or gameplay mutation and leave no idle callback.

The existing ten Boundless suites, Pigeon checks, SQL/Lua/manifest/XML/DDS and ZIP/Civ5Mod package checks also run. The summary check is part of `python tools/validate_mod.py` and can run alone with `python tools/validate_summary.py`. Font rendering, scrolling behavior and exact native event timing still require the live test below; modeled geometry is not a native screenshot.

## In-game acceptance check

1. Fully exit Civ V, install the updated package, re-enable the mod through Mods, and load the existing modded save. The localization SQL must be activated again; replacing only the Lua file cannot register the new text keys.
2. Open the upper-right Workforce button. Confirm **Owned Plots** and every field listed above appear alongside Population and Original Capitals Subjugated. Both zero and nonzero values must be readable; no raw TXT_KEY or positional placeholders should appear.
3. Scroll the overview through its yield breakdown. At a smaller supported resolution, check long labels, warnings and large values remain reachable and do not overlap mode buttons or plot rows.
4. Assign/release and lock/unlock a remote plot, change workforce modes, grow the capital, gain/lose a tile, make a frontier claim, and construct/remove the Registry. Check census, counts, pending/locks, progress and cost update.
5. Save/reload, enter/leave CityView, policies and diplomacy, then reopen. Verify the same values and all row/global controls. On a test save, lose/reclaim the original capital: census values should become unavailable during occupation and return afterward; the siege controls must continue to work.

Native verification of this summary update remains pending. Preserve a fresh Lua.log if it reports `Workforce refresh failed` or any text key remains unresolved. No cache/save deletion is part of this fix.
