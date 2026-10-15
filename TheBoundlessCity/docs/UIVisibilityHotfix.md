# Workforce visibility hotfix — 2026-10-15

**Release:** 1.2.2 preview / native mod version 4, schema 3 unchanged. The reported symptom is the missing **Boundless Workforce button or panel** after the successful crash-hotfix replay.

## Evidence and scope

The latest available Lua.log contains the Boundless runtime-loaded message and no Boundless runtime errors or rejected-update flood. The installed Workforce and dispatcher scripts matched the pre-fix repository. The most recent turn-60 autosave was inspected read-only: its native Boundless envelope retains the original capital, HYBRID mode, two remote assignments, two reservations and frontier progress. This establishes saved data is present; it does not reveal the live UI's hidden flags or prove the precise triggering screen.

The old launcher depended on cached city/diplomacy/mode and popup-event flags. A missing close notification could keep it hidden indefinitely. Most city-info UI refreshes also stopped when the panel was closed, and close handlers refreshed immediately before the native transition necessarily finished. These are reproducible code weaknesses; no native UI stack or controlled gameplay session was available to establish which one caused this report. Separate original Cool Wacky Civs v21 TokenPanel errors remain outside this patch.

## Correction

- Read the current native city-screen and interface-mode state. Check actual BNW popup contexts and the leader context/root-up state rather than relying solely on remembered events.
- Bind popup Shown records to the native screens visible after the transition. Clear them when those screens hide, even without Processed; keep hiding while native screens remain visible after an early Processed.
- Refresh after transitions and game/city UI dirtiness, including with the panel closed. Reset unknown-popup flags on turn start, load, active-player change and addon context return. Visible native screens still block after these resets.
- Share one coalesced, self-detaching ClearUpdate callback with gameplay dispatch. UI-only requests do not run reconciliation. Older captured callbacks cannot clear a newer transition queued during dispatch.
- Release the rendering guard even after an error. Log visibility-reason changes and distinct rendering failures, without logging every idle frame.

The native context IDs and IsHidden behavior were checked against the installed BNW InGame.xml, SocialPolicyPopup and LeaderHeadRoot sources; the official TopPanel demonstrates absolute InGame control lookup. Missing contexts are tolerated. Other mods' unknown popups retain event/turn fallback; arbitrary custom UI replacements still require native testing.

## Verification and installation

All ten Lua 5.1 simulation suites pass, including expanded UI and dispatcher cases for missed/early/nested popup events, current city/mode/leader state, delayed close, lifecycle return, render exceptions, transitions during gameplay dispatch, 1,000 coalesced requests, idle frames and shared gameplay/UI work. SQL, package, manifest, XML and DDS checks also pass. These tests do not measure native UI layout or event timing.

The installed hotfix updates only the two affected Lua scripts and their manifest hashes, preserving other installed metadata. Pre-patch files are retained locally under ignored `dist/ui-investigation-2026-10-12/`. Release ZIP/Civ5Mod archives include the fix and guides. Native mod version, save envelope/schema, BCY2 ledger, UUID and numerical gameplay rules stay unchanged.

Fully restart Civ V, load the existing modded save and open the upper-right Workforce button. Verify saved mode/assignments; enter and leave CityView, production, policies and leader diplomacy, then reopen the panel and end a turn. The launcher must hide over incompatible screens and return on the world map. Native confirmation of this UI patch is still pending. If it disappears again, preserve the fresh Lua.log; `[BoundlessCity] Workforce visibility:` now records the reason, and `Workforce refresh failed:` identifies rendering errors.
