# Turn/movement crash investigation — 2026-10-12

**Hotfix:** 1.2.1 preview, native mod version 4 / state schema 3 unchanged. Baseline `8ff0225`. This fixes a confirmed native UI contract error. The player subsequently confirmed that the pre-crash turn/movement replay completed successfully; that is a campaign replay result, not certification of every gameplay path.

## Evidence

The reported crash occurred during a turn or movement. The current game's Lua.log ended at 19:58:45 and contained 531,276 lines / 38,626,601 bytes. It included **264,599** `LuaContext::SetUpdate could not be called: received an invalid argument` messages, paired with `Expected function but got nil`. The movement log last reported turn 13 and player 0, The First Architect.

The installed v4 BoundlessEvents.lua matched the repository byte-for-byte before the fix. Its deferred callback attempted `updateContext:SetUpdate(nil)` to detach itself. The native engine rejects that argument and leaves the registered update function installed. The callback can then run repeatedly without new work, generating errors every frame and defeating the intended coalescing/performance guarantee. This is a credible contributor to the crash, but no native fatal stack was obtained that proves it was the sole cause.

The installed official CP v151 UI demonstrates the supported operation: `ContextPtr:ClearUpdate()` in `LUA/CityView.lua`'s DoUpdate and `self.context:ClearUpdate()` in `Kit/Util/CPK.Util.Timer.lua`'s Detach. The installed DLL identifies itself as v151, Release-5.4.6, git `b9ddca9a9`; existing C++ feature audits use their documented pinned source commit. This fix concerns the native UI context contract rather than a replacement DLL.

## Correction and tests

BoundlessEvents now calls **ClearUpdate before dispatching any work**. This removes the callback through the proper API. Work scheduled during dispatch can install a fresh callback for the following frame, while idle frames perform no reconciliation, saves or source mutations.

The previous mock accepted SetUpdate(nil) and automatically cleared the callback before invoking it. Both behaviors hid the real error. The mock now rejects non-function update arguments, exposes ClearUpdate, and retains callbacks across simulated frames until explicitly cleared. The old dispatcher was reproduced failing under this stricter contract before the patch.

The new `dispatcher_contract.lua` verifies native callback persistence, rejected nil without detachment, explicit ClearUpdate, 1,000 events coalescing into one batch, 1,000 idle frames with no writes, scheduling during dispatch, detachment even when a batch raises, separate Boundless player states, and repeated hostile movement changes settling after one batch. All ten simulation suites pass under the corrected mock, along with SQL/Lua/manifest/art validation. This is an API/dispatcher regression test, not an automated native campaign replay.

The mod UUID, native package version 4, minimum compatible version 1, state schema 3, BCY2 ledger and numerical mechanics remain unchanged. No save/cache cleanup or migration is needed for this code-only hotfix. Original civilization files, other mods, game saves and database caches are untouched. User ModBuddy project/solution edits are preserved; its local .civ5suo state is ignored by Git.

Raw crash logs and pre-hotfix installed files are retained locally in ignored `dist/crash-2026-10-12/`; they are not published with the repository. Fresh ZIP/Civ5Mod archives contain the corrected dispatcher. The installed v4 hotfix changes only BoundlessEvents.lua and its declared MD5, preserving ModBuddy's other manifest metadata.

## Separate logged failures

The same session loaded **Cool Wacky Civs v21**, whose TokenPanel reported 845 repeated nil-state errors at lines 119/120. Several of that collection's runtimes failed startup because `rawget` was unavailable, and other unrelated mod/SQL errors were present. These are distinct issues and were not modified by this Boundless hotfix. The log alone cannot assign the fatal native crash to one of them.

## Native replay follow-up — 2026-10-15

When asked whether the turn/movement still crashed after a full restart and replay, the player answered **“Replay completes successfully.”** The subsequent log has no Boundless SetUpdate/nil flood. The player then reported that the Workforce button/panel disappeared; this is investigated separately in [UIVisibilityHotfix.md](UIVisibilityHotfix.md). If a fatal crash recurs, preserve its fresh log and exact action/turn. The successful replay and corrected simulation do not establish crash-free behavior for every native path.
