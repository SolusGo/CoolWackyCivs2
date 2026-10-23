# Saba verification record — 2026-10-23

**Native acceptance: NOT TESTED IN GAME.** Civ V was not launched for this implementation. Automated Lua fixtures, SQL execution and source inspection do not establish native gameplay, rendering or save compatibility.

## Automated coverage

`python tools/validate_saba.py` executes the actual shipped SQL against a read-only development-cache copy plus installed CP schema, after all released SQL. It snapshots every existing row including IDs, verifies full Spearman/Water Mill scalar and companion inheritance, changed-base/future-column inheritance, absent/present additive Food/Gold rows, human-only flags, first city, localization and icon references. The current menu cache has no CP loaded; a separate read-only copy augmented with installed CP schema exercises activation. Raw active-CP checks in existing suites explicitly skip that vanilla cache.

Seventeen pinned CP source/schema contracts verify native River/terrain bindings, feature-aware defense, hills, no attacking defense modifier, sight, upgrade loss, common conquest/nonconquest acquisition, liberation, NeverCapture and nonsellable dummy behavior. [SourceAudit.json](SourceAudit.json) records source commit and hashes. These are source contracts, not native executions.

Three Lua 5.1 suites execute the shipped controller with building-yield values read from actual SQL:

| Suite | Coverage |
| --- | --- |
| `saba_locations.lua` | Desert River +1 Food/+1 Production/+1 Culture; Desert only +1 Culture; River only +1 Food/+1 Production; neither zero; Desert Hills; Flood Plains; multiple independent cities; other owners unchanged; neighboring terrain ignored; immediate founding; repeat sync/load no stacking, writes or duplicate handlers |
| `saba_lifecycle.lua` | Acquisition/removal/restoration; trade/liberation modeled through the common hook; missed-event owner-turn repair; corrupt native counts; multiple Saba players; razing/destruction with stale-object traps; empty coordinates and reuse of a destroyed city site |
| `saba_reload_stress.lua` | Reconstructed native building counts after simulated save/load; changed ownership across load; missing counts repaired; 256 mixed-owner cities; 100 repeated owner-turns with zero extra writes; no-Saba no-op |

The art validator decodes all 40 DDS textures, verifies atlas dimensions/indices, legacy encoding, mipmaps and leader/loading/map paths. The collection validator parses all Lua as 5.1 and verifies XML, VFS flags, project/manifest contents, file hashes, atlas framing and earlier civilization regressions. Release verification compares ZIP bytes and samples extracted 7z bytes, including Saba SQL/runtime/art.

## Command results

Python commands use the repository's `.venv/Scripts/python.exe` runtime. Distribution archives and detailed console logs are generated under ignored `dist/`. An initial validation run caught color atlases reduced to one mip by shared finishing; Saba now uses the existing complete-mip compilation path. The final collection validator passes.

| Command | Result |
| --- | --- |
| `python tools/generate_saba.py` | PASS |
| `python tools/prepare_saba_art.py` | PASS |
| `python tools/prepare_art.py` | PASS |
| `python tools/build_mod.py --manifest-only` | PASS |
| `python tools/validate_mod.py` | PASS; all nine civilizations, with two raw-active-cache subchecks skipped because the current cache has no CP loaded |
| `python tools/benchmark.py` | PASS; existing synthetic Boundless benchmark, not native or Saba timing; its unrelated generated timing file was restored |
| `python tools/build_mod.py` | PASS; version 11 ZIP and genuine LZMA/7z Civ5Mod; repeat atlas finishing changes zero DDS bytes |
| `python tools/verify_release.py` | PASS; 579 packaged files / 485 game files, exact ZIP bytes, 7z CRC/inventory and extracted manifest/runtime/SQL/art |

An additional comparison with the committed version 10 manifest verifies identical prior SQL order, collection UUID and minimum save version. Git confirms no existing civilization file changed. The [complete file inventory](Files.md) lists new and updated sources. The command failures encountered during implementation were corrected; no final required command failed.

## Native reproduction checklist

Use Windows BNW with **Community Patch v151 only** plus this collection. Enable database/Lua logging, install the version 11 archive, select Karib'il Watar and start a new single-player game. Use a controlled map or an editor to create the conditions below. Compare base city yields against an equivalent ordinary civilization with the same population, terrain, buildings and policy modifiers; compare combat modifiers rather than rounded damage alone. Inspect `Database.log`, `xml.log` and `Lua.log` after each scenario.

Every row below is **NOT TESTED IN GAME**.

| Case | Required native result |
| --- | --- |
| Desert River, Desert dry, Grassland River, Grassland dry | Respectively +1 Food/+1 Production/+1 Culture; +1 Culture; +1 Food/+1 Production; no UA yields |
| Desert Hills city, Flood Plains city and adjacent-only Desert/River | Hills and underlying Desert features qualify; neighboring terrain/River alone does not |
| Multiple cities and 20 repeated turns | Independent yields and exactly zero/one of each Saba marker, with no stacking |
| Manual save/load and autosave reload | Correct counts/yields immediately after load and next owner-turn |
| Enemy conquest and recapture | No Saba UA left with the enemy; qualifying counts restored on return |
| Diplomatic trade, peace cession and liberation | Correct current-owner yields immediately after transfer; repeat after save/load |
| Raze and destroy, then resettle the same tile | No controller errors or stale references; replacement city gets its own correct effects |
| Non-Saba cities and prior civilization saves | No foreign UA changes; existing mechanics/save continuation behave as before |
| Wadi Sentinel construction | Spearman replacement with the active CP cost, strength, movement, tech, resource and upgrade properties; standard model |
| Sight | Exactly one more native Sight than an equivalent Spearman under the same terrain/visibility conditions |
| Defend on flat Desert, Desert Hills, Flood Plains/Oasis | Exactly +15 percentage points of terrain defensive modifier, once, including against ranged attacks |
| Defend on Grassland/Plains beside Desert; attack on/from Desert | No Saba defensive bonus off Desert and no unique attacking bonus |
| Sentinel save/load and upgrade | No duplicate unique promotions; both unique Sight and defense bonuses lost on upgrade |
| Cistern production menu and river restrictions | One Water Mill-class replacement; all active CP requirements preserved; no separately constructible normal Water Mill |
| Cistern yields, modifiers, maintenance and specialists | Full normal Water Mill effects plus exactly +1 Food/+1 Gold |
| Cistern removal/ownership transfer | No persistent Lua yield credit; normal native building/class conversion and destruction behavior |
| Desert River Cistern city | Beyond a normal Water Mill: +2 Food/+1 Production/+1 Culture/+1 Gold |
| Human selection and random AI roster | Saba selectable by the human, absent from random AI selection; Ma'rib first |
| Identity/art/localization | Correct civ/leader/unit/building/promotion icons, static diplomacy scene, Dawn of Man, map, Civilopedia and diplomacy; no missing TXT_KEY or asset |
| Logs and other civilization smoke tests | No new SQL/XML/Lua errors; all earlier collection civilizations remain functional |

Known native risks remain unverified yield settlement, combat rendering, native building conversion and old-save continuation. No automated gameplay defect remains accepted as a known bug. Artwork is supplied; no original-art placeholder remains. The static leader, native Spearman model and schematic map are intentional presentation limits. Ready for this in-game acceptance checklist after automated checks pass.
