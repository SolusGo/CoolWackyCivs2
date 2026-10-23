# Test matrix and results — 2026-10-23

**Implementation preview. No native Civ V launch, rendered-screen inspection or native save/load test has been performed for this civilization. Every native acceptance item below remains pending.** Passing SQL, source contracts and simulated Lua behavior must not be described as full runtime compatibility.

## Available checks performed

- `python tools/validate_cats.py`: passes actual BNW/installed CP-schema SQL activation, all prior collection-table row preservation, exact bonuses, full Garden replacement inheritance, native API/source contracts, Lua 5.1 syntax, thirteen behavioral simulation suites, XML/control/localization/atlas references and all 50 decoded mipmapped DDS files. Core/inheritance/effects/art SQL fingerprints match the shipped implementation.
- `python tools/verify_cats_art.py`: passes exact repeat-build comparison for 51 Cats art files (50 DDS plus leader XML), 12 derived masters/metadata/previews, and 295 unchanged peer-art files. Source/decoded atlas inspection confirms eleven distinct portraits, white crowned Austin, dark tortoiseshell Sisi, Appa's illustrative arrowback and correct named slots. This is offline art inspection, not native rendering.
- `python tools/validate_mod.py`: full collection regression suite passes, including existing civilizations' SQL, gameplay/UI simulations, pinned CP contracts, distinct VFS namespaces and original-collection coexistence checks.
- `python tools/build_mod.py --manifest-only`: produces matching version 10 manifest and ModBuddy project, ordered SQL and eight InGameUIAddin entry points. The collection icon validator verifies 313 atlas-size records and eight leader atlases.
- `python tools/build_mod.py` and `python tools/verify_release.py`: build and check the installable ZIP and genuine 7z/LZMA `.civ5mod`, exact packaged bytes/inventory/CRC. Build outputs are ignored by Git.
- `git diff --check`: passes.

The native-contract audit reads CP v151 source already pinned by this repository at commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`, and uses the installed database schema read-only. SQLite mutations occur only in memory.

## Automated evidence and remaining native acceptance

| Area / scenario | Automated evidence | Native Civ V |
| --- | --- | --- |
| Ancient start; Luna once | Fresh start simulation, exact count 2/11, repeated chapter event | Pending |
| Medieval start; all earlier cats | Fresh start simulation, 6/11 immediately | Pending |
| Modern start | Fresh start simulation, 11/11 immediately | Pending |
| Save/load immediately after initialization | ScriptData restoration; no additional chapter notification | Pending |
| No capital before first founding | Pending identities; no units; founding resumes arrival | Pending |
| Six chapters / Bonnie once | All era counts 2,3,6,8,10,11; repeated event is idempotent | Pending |
| First litter together | Medieval Appa/Loki/Kuro unlocked in same pass | Pending |
| Second litter together | Renaissance Oscar/Boomie in registry and final totals | Pending |
| Charlotte and Sisi together | Industrial pair and final totals | Pending |
| Max final arrival; Austin no unit | Exactly ten companion units, eleven canonical identities | Pending |
| Empty home / third resident | Actual command path and capacity assertions | Pending |
| Fourth resident rejected | Capacity gate; state/effects unchanged | Pending |
| Enemy or razing home rejected; owned resistance is allowed | Command ownership/state gates; razing displacement | Pending |
| Exact personal yields immediately | Actual SQL rows and authoritative reconciliation model | Pending native yields/tooltips |
| Effects end when resident leaves | Rehome paths; every absent dummy set to zero | Pending |
| No duplicate effects after save/load | Repeated effects and restored registry | Pending |
| Luna current capital / relocation | Both capital movement directions recompute First Pair | Pending |
| Bonnie with one or two kittens | One bond building in either composition | Pending |
| Appa/Loki/Oscar; remove any requirement | Exact three-member predicate; removal ends bond | Pending |
| Charlotte/Sisi; independent growth | Both native growth choices active (+10); removing Charlotte leaves +5; removing Sisi leaves zero | Pending native surplus/growth tooltip |
| Rehome valid / blocked or failed spawn | Actual command path; failure keeps resident and effects | Pending |
| No settling during cooldown | Authoritative gate; UI displays remaining turns | Pending |
| Quick/Standard/Epic/Marathon timing | Rehome 7/10/15/30, recovery 2/3/5/9 | Pending |
| Cooldown survives reload/recovery | Stored per identity, no reset by respawn | Pending |
| Resident city capture/gifting/trade | Post-transfer owner cleanup; all dummies removed | Pending native transfer flows |
| Razing, destruction, replacement city | Displacement and founding-identity tests | Pending |
| Travelling removal / capture | Prekill model; capture NULL field and native source branch | Pending native combat/embarkation |
| Script-removed/missing unit | Registry scan detects loss without removal hook | Pending |
| Multiple simultaneous recoveries | All ten displaced; save during recovery; independent return | Pending |
| Original capital loss / moved capital | Stable city identity; current safe home chosen | Pending |
| Occupied or absent spawn locations | Pending until space opens; seven hexes per isolated city | Pending |
| Elimination and later city ownership | Pending records retained; no enemy-owned return | Pending |
| No repeated respawn / duplicates | Canonical promotion/unit registry and orphan removal | Pending |
| WLTKD activation once | 20 native turns become 25 in counter model | Pending luxury activation |
| Legitimate positive refresh | +8 native turns extend by +2 once | Pending native refresh |
| Repeated turns / reload | No extension without native event; fractional carry persists | Pending |
| Other civ WLTKD / native rows | Foreign counter untouched; earlier database rows preserved | Pending coexistence game |
| Cat Tree no Fresh Water | Actual inherited SQL row FreshWater=0 | Pending build selection |
| Cat Tree +1 Food with 1–3 residents | Single independent dummy; zero without residents | Pending native yield |
| Civ/leader selectable; icons/diplomacy | Actual registration/atlas/scenes; installed Firaxis setup reads explicit unit overrides | Pending rendered setup/diplomacy |
| Household launcher / details / Homes / Bonds | Callback model, structured details, city cards/portraits/tree, required/missing bond members, host city and disabled-action explanations | Pending rendering/legibility |
| City/diplomacy/popups | Transition closure and shared mutation gates | Pending native early/late modal timing |
| No high-frequency polling | No UI SetUpdate, fixed eleven rows/four bond cards; pooled home cards; one-shot dispatcher clears itself | Pending FPS observation |
| AI-forced setup | No progression/bonuses; created orphan purged; Cat Tree veto | Pending unusual scenario |
| Corrupt/future state | Original block preserved; all effects fail closed | Pending native edited save |
| Interrupted native save before/after mutation | Uncommitted settle/rehome rolls back; post-write exceptions verified by readback; no consumed/duplicated cat | Pending native fault behavior |
| Interrupted native unit constructor | Before-birth failure leaves residence; one after-birth unit adopted; all guards clear | Pending native fault behavior |
| Capture and era event inside effect update | Follow-up retained, new chapter processed, stale city update stops and foreign effects cleared | Pending real event ordering |
| Persistent native setter failure | Two deferred attempts, callback detached; UI-only refresh cannot restart gameplay retries; later lifecycle retries | Pending engine error behavior |
| Missing/conflicting promotions; reversed duplicate order | Independent metadata repairs identity, saved unit wins, duplicates removed deterministically | Pending edited native units |
| Failed unit cleanup | No stuck removal guard or rehome duplication; later cleanup succeeds; human cleanup request does not purge valid cats | Pending native delayed removal |
| Impossible timers; duplicate/mixed core versions | Timers repaired once; unsupported/ambiguous blocks preserved and disabled | Pending edited native saves |
| Optional settling / first bond messages | Once per stable city across reactivation/reload, saved preference, no gameplay block changes; narrative write failure retries without unsaved bond notice | Pending native notification delivery |
| Existing v1 save without sidecar / future sidecar | Assignments/cooldowns/chapters unchanged; silent baseline; unknown narrative data preserved | Pending actual pre-polish save |
| Canonical identity/art metadata | Eleven exact genders, ten eras, mothers/litters and portrait slots; Austin never spawns | Pending visual likeness inspection |
| Save setter silently discards data | Actual command path rejects commit, keeps traveller/native record; narrative save marks dirty and suppresses unsaved bond notice | Pending engine integration |
| Rollback birth survives without an identity | Repeated rehome rejected, one retained birth, unchanged resident effects/cooldown; cleanup later resumes | Pending native failure/delayed removal |
| Save throws after successful rehome write | Verified travelling record, exactly one unit, original full cooldown, removed local effects and correct reload | Pending native save continuation |
| Growth activation/cancellation before/after fault | Active-state queries prevent reapplication, independent +5/+10, bounded repairs and correct eventual zero | Pending native choice execution |
| Queued plus synchronous lifecycle pass | Queued era intent merged, one effects pass rather than a redundant deferred rerun | Pending native event sequencing |
| Long names / short viewport | Wrapped row/card geometry and 1024×600/480 height model; fixed instance counts | Pending font/layout screenshots |
| Enhanced DDS technical quality | Full mip count, legacy header/no DX10, BC3 scenes, exact atlas dimensions, eleven unique cells/indices, empty twelfth slot and nonoverlapping eleven-cat emblem | Pending native texture loading |

## Performance model

The full ten-companion/four-city fixture performs **1,000 reconciliations in under 0.3 seconds total** in the recorded local Lua 5.1 runs, with **zero redundant ScriptData writes or notifications** after stabilization. A separate six-city fixture covers **720 turn transitions, 12 rehomes and 50 context reloads**, checking stable listener counts and no idle callback. The UI fixture covers **200 opens and 1,000 dirty notifications**, retaining eleven cat rows, four bond cards and a bounded home-card pool; a renderer fault closes safely and permits reopening. These are simulation measurements, not game turn timings, native memory profiling or FPS claims. Actual late-game/native memory and rendering tests remain pending.

Suite inventory: `cats_starts`, `cats_lifecycle`, `cats_bonds`, `cats_edges`, `cats_ui`, `cats_resilience`, `cats_faults`, `cats_notices`, `cats_wltkd`, `cats_performance`, `cats_metadata`, `cats_transactions`, `cats_growth_faults`. The WLTKD fixture exercises **240 genuine positive-duration events** across two cities and four speeds, with exact cumulative quarter-turn carry, independent ownership/founding keys and silent loads. Per-cat SQL arithmetic separately checks general Production, local GP rate, strength hundredths, Happiness and positive-surplus Growth (+5/+10 percentage points, no starvation substitution). These do not execute the native DLL.

The two new transaction assertions were first run against the pre-fix implementation: silent-setter settling failed, followed by an unidentified failed-rollback birth bypassing the rehome gate. Both pass after the repairs. Growth fault cases exercise the shipped native-API calls through the model and verify post-mutation idempotence; they do not invent substitute yield mechanics.

## Native acceptance procedure

Use [the concise acceptance checklist](NativeAcceptance.md) to record the next actual game session. Installed executable/schema/source access was available, but this task had no controlled native UI/test bridge; Civ V was not launched or driven. No native row below has been marked Passed.

1. Install the generated version 10 package, enable only BNW, Community Patch v151 and this collection, and enable Logging/Lua logging in Civ V's config. Preserve existing saves/installations first.
2. In modded setup confirm Austin/The 11 Cats appears with the white King, civilization emblem, House Cat and Cat Tree. Start Ancient, Medieval and Modern games separately. Inspect Database.log and Lua.log for `[The11Cats]` or SQL/texture errors.
3. Found four cities. For each era, confirm the exact unlocked names/genders and the 2/3/6/8/10/11 count. Save/load immediately, before founding, while travelling, settled, rehoming and recovering. Confirm no repeated chapter messages or duplicate units.
4. Settle each cat and record native city Culture/Food/Gold/Production, Happiness, GP rate, strength and growth before/after. Test both +5 Growth choices together against positive surplus and existing modifiers; test starvation and Settler production. Compare Charlotte's displayed strength before/after. Rehome each and confirm complete removal.
5. Exercise each bond, two Bonnie kittens, current-capital relocation, third/fourth resident, enemy city, all speed cooldowns, blocked rehome and safe embarkation/ocean movement. Confirm ordinary training/purchase/faith/gift/upgrade/disband actions are unavailable.
6. Lose or trade resident cities, raze a home, lose a travelling cat on land/embarked, delete a unit through a test script, lose multiple homes together and lose the original capital. Check the three scaled recovery turns and pending state when every safe space is blocked. Test elimination in a controlled scenario without altering a valued save.
7. Satisfy a city's demanded luxury and record the native initial duration plus the proportional extension. Let it tick down normally. Trigger a genuine refresh, save/load mid-celebration and confirm no additional extension. Verify another civilization's counter is unchanged.
8. Build/sell/remove Cat Trees in dry and occupied homes. Inspect 1, 2 and 3 residents, then remove the last resident. Verify the conditional Food remains exactly one or zero.
9. Open Cats, Homes, Bonds, each biography and the optional chapter panel at several resolutions. Check wrapped city names and effect text, portraits, missing-member diagnostics, disabled-action reasons and Cat Tree status. Toggle Messages; activate a bond, rehome/reunite it and save/load to verify only the first per-city notice. Confirm the final 11/11 story has no rewards or replay. Test city view, diplomacy, Culture, Technology, Social Policies, Religion, Espionage, World Congress, native popup opening/closing, turn end and reload. Confirm no texture placeholders, overlapping panels or stranded launcher state.
10. In a late-game save with all companions and several bonds, watch FPS/turn time and Lua.log while opening/closing the panel and saving/loading repeatedly. Confirm no persistent update callback, extra UI rows/listeners or growing save block. Play a different collection civilization and confirm its ordinary mechanics and interface.

Record actual save names, game speeds, CP/DLL version, observed yields, screenshots and log findings here before changing any native item to Passed. Current blocking verification gap: this task did not drive a native Civ V session; automated checks are the available evidence.

For save acceptance, keep a copy of an actual save created with commit `a1d2fb3` and compare each identity's residence, rehoming/recovery boundary and chapter count after loading this polish. The collection UUID/version 10, gameplay IDs and 82-number v1 record are unchanged. Matching simulated ScriptData is evidence of format compatibility; it cannot replace a native save/autosave continuation test.
