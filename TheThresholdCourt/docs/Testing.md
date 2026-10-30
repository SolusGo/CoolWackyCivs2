# Testing record and native acceptance checklist

## 2026-10-30 style hotfix

The reported Control Definition Error identifies `THC_Transfer.xml` and `GridBlack`. The installed native `Assets/UI/Styles.xml` contains `GridBlackIndent8`, but no `GridBlack`; XML syntax validation had missed this undefined style. The panel now uses the native definition and validation checks all requested Threshold styles against that installed inventory. All 32 four-speed suite runs and 65 pinned source contracts pass. No gameplay or save-schema change is involved. Restart Civ V after updating to reload the add-in XML; native dialog/panel rendering after the fix remains unverified.

**Native Civ V gameplay, UI rendering and real save-file testing: NOT RUN.** Do not interpret the modeled Lua tests or installed-schema SQL checks as a native acceptance result. See [Validation.json](Validation.json) for executed suite/source-check details.

## Corrective 1.14.1 regression pass

The complete primary trait relation must be exactly one `TRAIT_DOOR_IN_EVERY_WALL` row. Tests also populate Washington's optional shared-policy table and a previously unknown leader gameplay table, regenerate inheritance in memory, activate it and prove neither relation reaches Queen Elsewhere. Washington and other leaders' complete trait relations remain unchanged. The generated inheritance on disk must equal the generator's current output.

Eight shipped-Lua suites run on Quick, Standard, Epic and Marathon (32 modeled runs): original transfers/rejections/faults/UI/lifecycle, plus elimination, movement composition and receipt recovery. Native source checks now include 65 CP v151 contracts. [Audit, exact files and failure evidence](Hardening.md).

Before correction, executed tests failed for the extra Washington trait, gifted exhaustion after elimination, a stray promotion vetoing unrelated movement, and a late confirmed receipt exhausting a new owner-turn. These are genuine pre-fix failures, distinct from deliberately injected faults inside passing recovery suites. Logs under ignored `dist/threshold-hardening-*.log` retain the local runs; Validation.json records the final executed suites.

Elimination tests cover major and city-state recipients, converted units, same-turn elimination, context rebuild, dead-unit skipping, revival before/after cleanup, missing/corrupt unit and player records, isolated write failures and retry. They assert identity, unrelated promotions, damage/XP, movement and attack counters remain unchanged by cleanup. The movement suite executes the actual `J.CanMoveInto` function extracted from the shipped Jin controller alongside Threshold's handler on a modeled CP TestAll bus; its geometry/save adapters are modeled, not native pathfinding.

Recovery tests now include receipts finalized in a later owner-turn, origin capture, House removal after confirmed arrival, unit disappearance/ID reuse, unexpected adjacent relocation, no speculative payment, no next-turn exhaustion, and numeric-but-invalid receipts. Late receipt recovery must not grant or consume new-turn movement/attacks. Invalid financial data is preserved and new transfers remain unavailable.

An additional executed failure showed that a malformed player ledger could also prevent an independent valid unit deadline from expiring. The verified owner-turn branch now releases that unit without resetting financial data or granting moves/attacks. This case is included in all four speed runs.

Additional native acceptance remains pending: elimination and conversion timing inside combat, city-state gifting, revival, load during orphan quarantine, scoped movement dispatch and Jin composition, delayed financial recovery at real turn boundaries, and old v17 trait-cache behavior. Start a new game for a clean trait baseline; source inspection shows old saves restore cached aggregate trait data, and this pass does not mutate policies or claim automatic repair of previously granted Washington bonuses.

Run from the collection root using its Python environment:

```powershell
.venv/Scripts/python.exe tools/generate_threshold.py
.venv/Scripts/python.exe tools/prepare_threshold_art.py
.venv/Scripts/python.exe tools/build_mod.py --manifest-only
.venv/Scripts/python.exe tools/validate_threshold.py
.venv/Scripts/python.exe tools/validate_mod.py
.venv/Scripts/python.exe tools/build_mod.py
.venv/Scripts/python.exe tools/verify_release.py
```

The DB adapter reads the installed backup debug database and CP schema read-only and executes SQL in memory. Dynamic sentinel tests deliberately change Pikeman/Market values there before activation to verify inherited values instead of hardcoded BNW numbers. All matching companion tables are compared, including CP additions. Other civilization rows remain identical apart from the explicit movement-notification opt-ins. The Lua suites execute the shipped gameplay and UI scripts under Lua 5.1 with a modeled native API. Tests repeat on Quick/Standard/Epic/Marathon; cooldowns and costs remain unscaled.

Pinned engine contracts use official CP commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb` (DLL version 151), with URLs and content hashes recorded in Validation.json. The repository's ignored `tools/reference` source cache is required for this audit; populate it using `tools/audit_cp.py --fetch` plus the promotion source listed in Validation.json when checking on a fresh machine. The primary API sources are [CvLuaUnit.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/Lua/CvLuaUnit.cpp) and [CvUnit.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvUnit.cpp).

The package validator parses XML, syntax-checks Lua 5.1, resolves localization/art paths, decodes DDS files, compares manifest MD5/VFS flags and verifies SQL ordering. ZIP and extracted 7z samples must match working files exactly. Existing collection regression suites must also pass before release.

## Native setup

Enable logging in the game's config, enable BNW + Community Patch v151 + this collection, start Queen Elsewhere in modded single player, and follow the [first crossing instructions](../README.md). Inspect `Database.log`, `xml.log` and `Lua.log` after activation and each failure test. Use a test save with at least three city plots, enough Gold, ordinary Pikemen/Hingeguards, ranged and civilian units, and a late-game melee unit with Blitz or additional attacks. Repeat geography tests on Standard, Large and Huge with separate continents.

All rows below remain **pending in game**; modeled coverage does not change that status.

| Test | Expected result |
| --- | --- |
| Build first Threshold House | It is an endpoint; no destination yet, no usable crossing. |
| Build second Threshold House | Empty military slot creates a usable network. |
| Select eligible melee unit | Threshold Transfer button appears on the city tile. |
| Select civilian, Great Person, ranged/siege, embarked, sea or air unit | Transfer inaccessible. |
| Select melee unit on ordinary tile | No transfer button. |
| Open selector | Every other owned city appears; missing houses and occupied slots have disabled explanations and current cost. |
| Choose and cancel | No movement, Gold, cooldown or empire use consumed. |
| Cross ocean/mountains/different continent/Huge map | Same unit appears on exact destination city tile without embarkation; no adjacent fallback. |
| Military occupied destination; then civilian only | Military rejects; compatible civilian permits transfer. |
| Exact Gold; one Gold below | Exact amount succeeds; below fails without side effects. |
| Successful transfer | Correct Era cost, original identity/XP/damage/promotions/history and no healing. |
| Arrive with Blitz, extra attacks or restored moves | Zero normal movement and no offensive attack; ordinary defense works. |
| Try to upgrade exhausted unit | Deferred until next owner-turn. |
| Same-turn second click or another origin | Only the first succeeds. |
| Origin at T+7, then T+8 | T+7 rejects; T+8 allows if other conditions hold. |
| Destination as origin on next turn | Available unless it had its own previous departure cooldown. |
| Save/reload just after crossing; manual save, autosave, application restart | Same-turn use, origin cooldown and exhaustion remain. |
| Select/deselect; close/reopen UI | No state reset; same-turn use and cooldown remain. |
| Next owner-turn | Temporary restriction removed, native movement/attack recovery normal. |
| Delete/upgrade/replace selected unit while panel open | Stale selection rejects safely; no other unit is substituted. |
| Fill selected destination while panel open | Confirmation revalidates and rejects freely. |
| Remove Threshold House | Endpoint immediately rejects, including at confirmation. |
| Capture, recapture, raze and rebuild origin/destination; rename cities | Ownership/current buildings and fresh generations determine validity; names never affect identity. |
| Gift/convert exhausted unit | Restriction persists until original owner's next turn, then removes. |
| Non-Court obtains a Threshold House | No transfer ability or UI. |
| Human setup and random AI selection | Queen selectable for human; AI excludes Court. |
| Hingeguard vs CP Pikeman | Same combat/cost/resources/sight/upgrade/free promotions, +1 Movement only. |
| Hingeguard combat on friendly/neutral/enemy battle plot | +15% on friendly attack and defense only; no bonus elsewhere. |
| Threshold House vs CP Market | All scalar/companion effects inherited, exactly +1 Culture over baseline. |
| Return to main menu, load another save/new game | No old save data, stale references or duplicated handlers. |
| UI at 1024×768, 1280×720 and 1920×1080 | Panel fits, rows scroll, confirmation/cancel visible; long names readable. |
| Four game speeds | Exact eight owner-turn cooldown and unscaled Era Gold formula. |
| Other collection civilizations | Their rules, art and custom panels behave as before. |

No engine launch was attempted by the automated validator. Remaining work is native acceptance and balance observation, not missing signature-transfer code. Forced arbitrary relocations or script-data destruction by other mods are outside the supported contract. A persistent receipt with ambiguous treasury is deliberately left visible in diagnostics rather than guessed away.
