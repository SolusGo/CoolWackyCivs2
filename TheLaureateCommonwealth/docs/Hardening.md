# Recognition hardening — 2026-10-30

The original `Veteran()` checked only current Level and the existing rewarded promotion. `Converted()` called it on incoming units, and the owner-turn sweep repeated that check. A foreign Level 3/4 unit therefore earned a laurel without reaching Level 3 while Laureate-owned. Native captures that reset level could also reopen the same lifetime threshold later. The original capture filter consumed a receipt by tile and unit class, so an unrelated genuine Great Person could lose its creation reward.

Reproduction uses the actual previous controller from Git and the corrected native-order test double, at Standard speed in the Ancient Era:

| Scenario | Before | After |
| --- | --- | --- |
| Foreign Level 3 gift | 10 GAP | 0 |
| Foreign Level 4 military capture/conversion | 10 GAP | 0 |
| Foreign veteran captured with reset level, later reaches Level 3 | 10 GAP | 0 |
| Genuine same-tile Prophet born while another Prophet is captured | 0 GAP | 20 GAP |

These are shipped-Lua simulations, not native Civ V runs.

## Eligibility and migration

Unit ScriptData gains `[LC1_VET=2:owner:state]` with four internal states: `N` (native creation still pending), `E` (eligible), `B` (threshold already achieved abroad or unprovable legacy veteran), and `R` (already rewarded). `PROMOTION_LAUREL_LEVEL_REWARDED` remains authoritative and is never redefined. Missing history at Level 3+ migrates to `B`; existing rewarded promotions migrate to `R`; low-level legacy units remain eligible. This avoids retrospective awards while preserving ordinary progression. Past incorrectly awarded points are not clawed back.

Fresh military `UnitCreated` candidates retain `N` through reload and earn nothing during native initialization. Training completion or a safe native boundary establishes eligibility. Trained eligible units progressing 2 → 3 earn the unchanged speed-scaled `10 + 2 × Era`, once. Foreign units arriving below Level 3 can progress legitimately. Foreign-achieved Level 3+ history stays closed even if capture or conversion lowers the current level. Foreign promotion events close tracked eligibility when the threshold is reached there.

`UnitConverted` receives explicit source/destination IDs. It reads source history while the source still exists, preserves a source's already-earned recognition and Crowning Blow, and establishes incoming history before any incoming award is possible. Duplicate operation receipts are unit-local; stale callbacks with missing sources do nothing. Fresh native objects reusing IDs receive fresh metadata. Original owner is only an additional GP/capture check, not the veteran eligibility rule.

No new promotion, database column, unit, building, resource or gameplay modifier is introduced. Saved Wonder, Hall, Golden Age and pending-GP fields remain interpretable. Older low-level units with no historical data are treated as prospective progression; historical foreign levels that were erased before bookkeeping existed cannot be reconstructed from an old save.

## Verified CP v151 order and capture identity

Pinned source: `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`. The validator enforces the previously recorded hashes of `CustomMods.h`, `CvUnit.cpp` and `CvLuaUnit.cpp` and audits the native formulas and bindings.

1. Native unit initialization emits `UnitCreated` before capture metadata is assigned or `convert()` copies the source level/promotions.
2. `convert()` emits `UnitConverted` after copying level/promotions and before killing the source. It can refund levels for lost promotions.
3. Movement capture emits `UnitCaptured(reason=0)`, snapshots the capture definition, clears capturing-player state, kills the source and creates replacements after the movement operation. It does **not** also emit the combat capture notification for that source.
4. Combat `kill()` emits `UnitPrekill`, snapshots the capture definition, emits `UnitCaptured(reason=1)`, deletes the source and initializes its replacement. The reason-1 second argument is the capture unit **type**, not a dependable capturing-unit ID.
5. `createCaptureUnit` assigns original owner and then copies **ScenarioData** after `UnitCreated`. It does not copy level, promotions or ScriptData. Delayed final death calls `kill(false)` without the earlier killer argument.

The old tile/class association cannot establish exact replacement identity. The hardened controller temporarily puts a unique signed identity in the native-carried ScenarioData field. A source-player ScriptData receipt saves its previous integer, original owner, threshold/recognition state, source identity and capture destination. The native replacement carries the exact tag; the controller restores the original integer, copies the recognition history and rejects a captured GP before removing the receipt. Ordinary failed-capture/kill receipts are removed at safe boundaries; surviving sources regain their prior integer. Delayed deaths retain receipts until final deletion. All candidate and receipt state is recoverable after context reconstruction.

This preserves nonzero preexisting ScenarioData and other ScriptData text. **Compatibility limit:** code that treats ScenarioData as an exclusive field must not overwrite it while a native capture receipt is pending. Its prior value is restored before recognition, but other mods that read or write that field during the pending interval need a coexistence smoke test. A perfect unlinked replacement correlation is unavailable from CP's capture event arguments alone. No map scan or per-frame loop is used; foreign armies are scanned on load only if outstanding capture receipts require recovery.

## Secondary audits and tests

The genuine Great Person amount/receipt mechanism is retained. The identity correction fixes same-tile suppression and preserves natural, faith, policy, Wonder, immediate-expenditure, conversion, upgrade and original-owner Prophet recapture behavior. Native Golden Age policy SQL and all Hall SQL remain byte-identical. Golden Age activation, expiration, extensions, repeated initialization and reload use the existing exact +15/+15 policy; no additional modifier is introduced. Hall ownership, resistance, razing, anarchy, destruction, active-GA payout and same-turn save behavior remain covered.

`laureate_assertions.lua` now runs **26 isolated hardening cases on each of Quick, Standard, Epic and Marathon (104 runs)**, in addition to the original lifecycle suite. The first fourteen cases correspond directly to the requested veteran tests. Additional cases cover legacy migration, a qualified-but-unpaid save, foreign progression followed by a level decrease, nonzero ScenarioData restoration, failed capture cleanup, delayed death, original-owner Prophet recapture with same-tile births, ordinary kills, Great Person/GA lifecycle, captured-city Halls, immediate upgrades before classification, level refunds, and 1,000 foreign event batches without army enumeration.

Final review also reproduced an extra 14-point award if a capture was created synchronously while another achievement was being paid. Receipt cleanup now operates only on the set present when processing began and preserves identities still carried by queued replacements, including reused receipts from retries. The final case exercises this against the production Lua on all four speeds.

The mock now initializes conversion targets at Level 1 before copying source values and models movement/combat snapshots separately. Native capture replacement is created after source deletion, at Level 1 with no copied source promotions/ScriptData; original owner and ScenarioData are assigned after `UnitCreated`. Tests run the production Lua without rewriting its recognition logic.

The focused validator checks **91 CP source contracts**, real-schema SQL integrity and exact balance, Lua 5.1 syntax, all game-file checksums, registration, 40 existing DDS/mip chains and inherited Iron/Writing-slot properties. [Testing](Testing.md) and [Validation.json](Validation.json) record execution results.

Both the focused validator and full collection suite completed successfully on 2026-10-30 (exit code 0). Final gameplay Lua passed all 104 hardening runs. Whitespace, Python syntax, documentation links and unchanged SQL/art/project registrations also passed. Regenerated reports for other civilizations were restored before committing.

Files modified for this hardening: `Lua/LC_Commonwealth.lua`; `tools/tests/laureate_mock.lua`; `tools/tests/laureate_assertions.lua`; `tools/validate_laureate.py`; the existing modinfo's Lua checksum; root and Laureate README/changelogs; Laureate implementation/testing/file-inventory/validation records. This report is new. Project registrations, SQL, localization, artwork, identifiers, dependencies, UUID, version 17 and unrelated civilization source files remain unchanged.

## Native acceptance still required

**Unresolved native civilian-return path:** `CvPlayer::DoCivilianReturnLogic(bReturn=true)` kills the captured civilian and calls the original owner's `initUnit` without copying ScenarioData, ScriptData or promotions and without emitting a conversion/return hook. If this path returns a Great Prophet, the recreation is indistinguishable from a genuine new GP to the available creation event and can still earn a birth award. A source-order model reproduces 20 GAP at Ancient/Standard. This is distinct from recapture through `UnitCaptured`, which is filtered and regression-tested. The validator records this known limitation separately; it is not a passing correctness test or a claim that all native return paths are fixed. Reliable exact filtering needs a correlated native return hook or identity handoff; broad tile/type suppression would also reject legitimate same-tile births and was deliberately removed. No custom DLL or ambiguous replacement heuristic was added.

Run BNW with CP v151 only: acquire/gift Level 2 and Level 3+ soldiers, promote them, upgrade a rewarded Champion, recapture a rewarded veteran and a Prophet, and test real saves before/after recognition and while native delayed capture is pending. Observe original ScenarioData restoration and repeat with any mod that uses that opaque field. Verify displayed/earned city GPP and military XP during/after native Golden Ages, and functioning Hall payouts. Inspect Database.log and Lua.log. Mock save/context reconstruction and source contracts do not prove native serialization or live UI/gameplay behavior.
