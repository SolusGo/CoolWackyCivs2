# Testing record — 2026-10-25

Automated checks execute committed SQL in an in-memory copy of the installed BNW backup database, extended with installed Community Patch **v151** schema. The available game caches are menu/non-CP caches, so **CP-activated live-cache validation is unavailable**. No installed game files/cache are modified. Pinned official DLL source supplies additional API/formula/ABI evidence.

The controller runs under Lupa's **Lua 5.1** with a synthetic native boundary. These are not Civ V runs. Native route finding, Harbor rules, rendering, actual yield settlement, Worker build progress, save/load and older-save continuation remain **NOT TESTED IN GAME**. See [Implementation.md](Implementation.md) for the cached-flag/post-settlement synchronization limitation.

## Reproduce

Use Python 3.11+ with `requirements-dev.txt`; this workspace already has `.venv/Scripts/python.exe` with Lupa, Pillow and py7zr. Activate that environment before the documented `python` commands. Gold framing also requires DirectXTex `texconv` (available through the existing pipeline). Preserve source masters when rebuilding art.

```powershell
python tools/generate_conical.py
python tools/prepare_art.py
python tools/build_mod.py --manifest-only
python tools/validate_conical_union.py
python tools/validate_mod.py
python tools/benchmark.py
python tools/build_mod.py
python tools/verify_release.py
```

For a fresh checkout, source contracts require the ignored `tools/reference` cache. `python tools/validate_conical_union.py --fetch` downloads this validator's exact pinned official inputs. The collection's other validators have their own source-cache prerequisites. Art prompts and four original source images are committed in `art-source/TheConicalUnion`. Generated install archives and diagnostic logs are ignored in `dist/`.

The focused validator checks all released database rows and numeric IDs remain present after activation, allowing only the two explicitly enabled native event options. It tests every exposed scalar and 176 companion tables, native Worker movement/rate inheritance, road/railroad/repair/farm/mine permissions, untouched ordinary Workers, exact dummy yields, invisibility/no-purchase fields, class overrides, localization, alternate baseline properties/yields and atlas/VFS/package registration. `SourceAudit.json` records 26 CP source assertions and exact input hashes. `Validation.json` records the latest focused results and synthetic suite timings.

## Scenario coverage

| Requested cases | Automated evidence |
| --- | --- |
| 1–3, 11–15 | `conical_connections.lua`: exact six-state yield matrix, combining actual SQL yield values with shipped controller counts; Capital exclusion and permanent Office Culture. |
| 4–9 | Connection break/repair/reconnection; repeated and multiple route-shaped native true flags; simulated Harbor/mixed flags. This verifies binary handling, not native Harbor pathfinding. |
| 10 | Capital relocation and missing-Capital removal across the relevant empire. |
| 16–17 | Office sale, construction, scripted removal/dirty notifications, repeated reconciliation and zero additional writes. |
| 18–24 | SQL class overrides, all scalar/companion comparisons, movement/rate deltas, unchanged baselines and mutated active-row regressions; source formula/build-progress/capture contracts. |
| 25–26, 30 | `conical_lifecycle.lua`: conquest/nonconquest-shaped transfers retaining dummy rows deliberately, foreign cleanup, recapture, two Conical players and newly acquired cities. |
| 27 | Fresh Lua context with retained city/building data repairs stale counts and changed connections; duplicate registration guard and load notifications. Native save serialization is not simulated as a passed game test. |
| 28–29 | Missing/deleted city/plot, missing player, dead player, destroyed capital and optional event availability. |
| Additional | `conical_resilience.lua`: missing/throwing API, exception before/after mutation, reentrant native-shaped dirty events, 202-city steady state and 6,300 foreign turns with zero city iteration/writes. |

The collection validator parses every shipped Lua and test source as Lua 5.1, runs all existing civilization suites, decodes all DDS, checks atlas frames/indices, XML, manifest hashes, SQL order, VFS flags, ModBuddy contents and original-collection coexistence. The existing benchmark concerns the Boundless City; the Conical workload is in the focused resilience suite. Neither benchmark is native FPS evidence.

## Native acceptance checklist — all pending

Start a **new modded single-player game** with BNW, standalone CP v151 and the version 13 collection, choosing High Marshal Bollard. Enable logging and retain Database.log/Lua.log and before/after saves.

1. Confirm the civilization is selectable by a human and excluded from random AI selection. Confirm names, supplied Dawn text and silent playback.
2. Confirm civilization/leader/UU/UB icons at multiple sizes, flag tint, static throne painting and loading/map art render correctly. Confirm Worker 3D model reuse.
3. Construct a Road Crew; verify ordinary Worker requirements, automation, improvement menu, embarkation, terrain access, capture and available upgrade behavior. Verify a Worker-class grant uses the override where natively supported.
4. Compare Road Crew movement with an ordinary CP Worker under identical conditions: native baseline +1, normally 3 versus 2.
5. Compare **per-action build progress**, not just whole completion turns, on roads, repairs and at least a farm/mine. Expect 125 versus 100 base before shared modifiers/final integer truncation. Add a common speed modifier and confirm the ratio remains 1.25 before rounding.
6. Found two additional cities and complete a road connection. In the **ConicalUnion InGameUIAddin Lua gameplay context** (not the front end), inspect a city with `type(city.IsConnectedToCapital)` and call `city:IsConnectedToCapital()`. Compare with the game's city-connection indicator. This runtime API check has not yet been performed.
7. Record yields and dummy counts across native refresh, `PlayerDoTurn` and next settlement. Connected non-capitals must converge to UA count 1 and +2 Production/+1 Culture; Capital counts remain 0. Measure the documented transition delay.
8. Pillage the only essential road, then repair it. Repeat with alternate/multiple roads: losing one of two valid connections must not remove a still-native-connected bonus; multiple paths never stack.
9. Repeat on railroad, Harbor, mixed land/sea connections and naval blockade/unblockade according to native CP rules. No custom definition of connection is imposed.
10. Confirm Detour Office replaces Walls exclusively and retains identical native defense, HP, cost, maintenance, technology and other active Walls effects.
11. Verify the full six-state matrix in the README using city yield tooltips. A disconnected Office retains +1 Culture; a connected non-capital Office adds +2 Gold. Capital Office gives Culture only.
12. Remove/sell an Office where native sale rules permit. CP Walls have zero maintenance, normally preventing sale; a scripted removal is a useful additional test. Conditional Gold must disappear at the supported notification or fallback.
13. Capture/gift/liberate Conical cities into foreign ownership; check both markers are absent immediately after acquisition. Acquire foreign cities, capture/relocate the Capital, raze a noncapital, and temporarily test no-Capital states. Recheck every remaining city.
14. Save/load with connected, disconnected and Office cities, including after capture and Capital relocation. Verify exact 0/1 reconstruction with no accumulated yields. Separately load a version 12 save for an existing civilization and confirm its mechanics/state continue; no native continuation result is claimed yet.
15. Run a Huge-map game with many foreign players/cities. Confirm no frame callbacks, map scans, excessive city writes, new Lua errors or detectable event overhead. Foreign ordinary Workers and Walls must remain unchanged.

## Build/check results

| Command | Actual automated result |
| --- | --- |
| `prepare_art.py` | PASS: complete collection preparation, including 40 new Conical textures. Subsequent standardization leaves released artwork byte-identical. |
| `build_mod.py --manifest-only` | PASS: version 13 ModBuddy/modinfo, 591 game files, 11 simulation entries, preserved UUID and previous SQL order. |
| `validate_conical_union.py` | PASS: real-schema SQL/inheritance, all released rows/IDs, 176 companion tables, 26 source contracts, three shipped Lua 5.1 suites and 40 decoded DDS/VFS checks. |
| `validate_mod.py` | PASS: collection SQL, all Lua syntax/simulations, 11 leaders, 36 framed atlas families, XML/hashes/VFS/project consistency and original-collection coexistence. Expected fault-injection diagnostics are present in the log. |
| `benchmark.py` | PASS: existing Boundless synthetic workload. Conical's own workload passes in `conical_resilience.lua`; no native FPS claim. |
| `build_mod.py` | PASS: version 13 ZIP and genuine LZMA/7z `.civ5mod` generated; builder's archive CRC check passes. |

Final release gate: `verify_release.py` must match exact inventories and ZIP bytes, verify archive CRCs and compare extracted manifest/runtime/SQL/art/validation samples, including Conical files. The delivery message reports the final gate result. Diagnostic output is retained locally in ignored `dist/conical-*.log`. Released civilization benchmark/validation files that only changed timings were restored verbatim to keep the commit focused. See [source inventory](Files.md).

**Native acceptance remains pending regardless of automated status.**
