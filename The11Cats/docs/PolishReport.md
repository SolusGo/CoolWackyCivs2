# Quality, 2D artwork and compatibility report — 2026-10-23

## Native Luna arrival hotfix

The user's rendered Household showed Luna unlocked at 2/11 but permanently pending at zero turns. Their game log identified `THE11CATS_Manager.lua:237: attempt to index global 'UnitAITypes' (a nil value)`. The model had incorrectly defined that enum. Argument evaluation occurred before `pcall`, so no native unit constructor was reached and the spawning guard also stayed set.

The constructor now omits its optional AI argument, using the verified native `NO_UNITAI` default, and evaluates coordinates inside the protected call. The fixture no longer exposes `UnitAITypes`. A fourteenth suite loads the stalled state into an owned home, checks exactly one immediate arrival, repeated events, rehome, recovery, preserved cooldown and cleared guards after an accessor failure. All fourteen suites pass. No data/art/balance/3D changes or save migration are required. This confirms the cause and model repair; native post-hotfix success still needs reload confirmation.

## Final pass from 95671d8

### Gameplay fixes

| Confirmed defect / cause | Repair | Evidence |
| --- | --- | --- |
| `H.SaveSafe` trusted a setter that returned normally even if the record was not stored. Settle could consume a traveller without persistent residence. | `H.Save` verifies changed writes; `H.SaveSafe` still accepts after-write exceptions only when the exact block reads back. `H.SaveNotices` also verifies normal-return writes. | `cats_transactions` first reproduced the silent-setter failure; now keeps the original unit/status/native record. `cats_notices` suppresses unsaved narrative messages and retries. |
| A failed unit setup before identity promotion plus failed cleanup left an unknown birth; `H.CanRehome` only checked recognised identities and allowed another attempt. | `H.PendingUnit` gates both spawning and rehome using promotions/backup metadata, blocking unknown retained cats until cleanup succeeds. Residence/cooldown remain unchanged on failed mutation. | Regression failed before this fix, then passed with five repeated clicks, bounded failed cleanup and eventual repair. Identified rollback births and after-write rehome exceptions also pass. |
| A direct lifecycle pass could leave the same player queued for redundant work; screen transitions requested gameplay reconciliation. | Consume/merge the queued player/unlock intent before a synchronous pass; retain newly arriving events. UI transitions call `H.Refresh`. | One effects pass for queued+direct work, existing reentrant capture/era tests, exhausted retry/UI stress tests and all context reloads pass. |

No defect was found requiring a bonus/SQL/WLTKD redesign. Pinned CP v151 contracts and actual schema continue to support local GP rate, general Production, defense hundredths, uncapped Happiness, independent reversible +5/+5 positive-surplus Growth, Cat Tree Food and native-counter WLTKD. The new growth fault suite exercises before/after activation/cancellation errors and active-state queries without double application.

### Artwork and interface improvements

- **Eleven portraits:** separate retained paintings in canonical order, matching the supplied illustration/descriptions. White crowned Austin; grey-white Luna; gentle calico Bonnie; orange arrowback Appa; petite calico Boomie; black Kuro; dark tortoiseshell Sisi. Loki's blue collar/narrow blaze, Oscar's broader muzzle/gold bell, Charlotte's long ruff and Max's forward white paws distinguish similar coats. No reference photos were available; exact photographic fidelity is not claimed.
- **Civ emblem/atlases:** exactly eleven nonoverlapping named medallions around larger Austin, assembled deterministically from those portraits. Clear four-toe paw/open crown through 80px, detailed family at larger sizes; no decorative text. Existing atlas definitions/indices and 50 DDS paths/dimensions retained.
- **Dedicated paintings:** Austin seated on a purple cushion in a golden household leader scene; Dawn with first companions Austin and Luna; recognizable sisal-post/platform/cubby Cat Tree; quiet plum/cream parchment/gold Household background; map image uses the new full emblem. House Cat portrait uses new Luna; alpha/flag use the refined symbol.
- **Technical quality:** full mip chains, legacy DDS, BC3 scenes/atlases where aligned, RGBA nonaligned/alpha cells. Cats frames skip obsolete border trimming to preserve ears/crown. Repeat build is exact for 51 game art files plus 12 derived masters/metadata/previews; all 295 peer-art files unchanged. Original reference, prompts and selected PNGs remain in `art-source/The11Cats`; rebuilding has no generation/network step.
- **UI:** status colors, wrapped roster height, heading-aware Bond spacing, wrapped capacity/tree labels and short-viewport panel/scroll sizing on render. Footer room adapts to feedback. Eleven cat rows/four bond cards and city pooling remain; no polling was added. Native fonts/layout and widths below 920px remain unverified/limited.

### Preservation and save compatibility

Every gameplay SQL file (including art assignments) retains its fingerprint. All ten companions, Austin leader-only, genders, relations, six eras/stories, four bonds, exact bonuses, Cat Tree, three slots, +25% WLTKD, cooldowns/recovery and human-only gates remain. UUID/version 10, database IDs, the 82-number `THE11CATS1` format and `THE11CATS_N1` preference/notice format are unchanged. Existing simulated v10 states need no migration; art does not require a new save. Native old-save/autosave continuation remains pending.

### Validation and limitations

Thirteen Lua 5.1 behavioral suites pass, alongside real-schema SQL, unchanged earlier rows, pinned CP source, XML/localization/atlas/legacy mip/source identity checks. Full collection regression and built ZIP/7z package verification are recorded in `Testing.md`. Decoded source/finished atlas images were inspected offline; this is not native rendering. Stress fixtures retain the 720 turns, 12 rehomes, 50 reloads, 200 opens, 1,000 dirty signals and 1,000 stable reconciliations, without extra persistent callbacks/listeners/instances or redundant stable saves.

The installed game/schema/source were readable, but no controlled native UI/test bridge was available. Civ V was not launched; actual yields, save/autosave resumption, capture/embarkation timing, texture display, resolution/font layout and FPS/memory remain pending. See `NativeAcceptance.md` for the concise checklist.

**Existing House Cat 3D unit models and animations were not modified.** No new investigation or alteration of meshes, animations, rigs, formations, 3D art defines or movement visuals occurred in this pass.

## Previous reliability pass (a1d2fb3 to 95671d8)

This is a targeted revision of the shipped implementation at `a1d2fb3`, not a redesign. No native Civ V session was launched. Results below distinguish executed Lua 5.1 simulations, actual-schema SQL and pinned CP source checks from pending native acceptance.

## A. Confirmed problems fixed

| Severity | Root cause and affected function | Implemented fix | Executed regression / result |
| --- | --- | --- | --- |
| Critical | An exception in `Manager.lua` reconciliation/command/spawn/removal could leave shared guards set, blocking future household work. | `Safety.lua` wraps `H.Reconcile`/`H.Command`; `H.Spawn`/`H.Remove` protect native calls and always clear guards. Per-city effect failures are isolated. | `cats_faults`: injected before/after save/birth errors, persistent setters and retained kills; guards clear and later actions recover. Passed in simulation. |
| High | Reentrant events returned while busy/syncing without retaining their player/unlock request. | `H.Request`/`H.Schedule` retain pending work and era intent, with deterministic per-player dispatch and two deferred gameplay attempts per event wave. | `cats_faults`: capture plus era transition inside an effect setter; correct recovery, earlier chapter arrivals and foreign cleanup after flush. Passed. |
| High | Duplicate-unit repair chose the first iterator result, potentially discarding the saved travelling unit; missing promotions could hide an otherwise recoverable identity. | `H.Reconcile` prefers the saved ID then the lowest ID; crosschecks registry, promotions and owner/identity backup; logs deterministic repairs. Unidentified retained orphans block new births. | `cats_faults`: reverse unit iteration, duplicate Luna and missing/conflicting promotions; saved unit retained and one canonical companion. Passed. |
| High | A save failure during settle could consume an uncommitted cat; a rehome write or interrupted constructor could leave an extra birth or changed cooldown. | `H.SaveSafe` verifies readback; commands restore uncommitted records and remove tentative births; `H.Spawn` can adopt exactly one after-error birth. Pending retained units prohibit rehome duplication. | `cats_faults`: failures before/after native write/constructor and failed kill; residence/unit/cooldown preserved or committed exactly once. Passed. |
| High | A city transfer during a setter allowed the old update to continue applying resident effects to the new owner. | `H.ApplyCity` checks current ownership/founding identity after setters; `H.Effects` stops stale work, cleans the current city and queues follow-up. Capture cleanup handles errors and identity changes. | `cats_faults`: transfer triggered while Luna's dummy is added; all Cats dummies are zero in the lost city and Luna recovers. Passed. |
| High | Structurally valid but impossible recovery/cooldown values could strand companions; ambiguous duplicate/future gameplay records were not explicitly rejected together. | `H.Reconcile` clamps impossible timers once to the normal full interval. `H.State` rejects duplicate/mixed gameplay versions, preserving original data and disabling effects. | `cats_faults` and `cats_resilience`: extreme timers, repeated reconciliation, duplicate/mixed/corrupt blocks, ten simultaneous recoveries and elimination. Passed. |
| Medium | Dense text-only Homes and bond descriptions obscured individual effects, host cities and missing members. | Reusable HomeCard/BondCard views, structured details, actual travel location, exact effects/icons and explanatory action states in `Household.lua/.xml`; `H.BondReport` supplies gameplay-derived diagnostics. | `cats_ui`/`cats_notices`: hosts, missing Oscar, capacity/tree/portraits, callbacks, renderer recovery and instance counts. Passed in model; visual layout pending. |
| Medium | A repeated same-context include could register handlers/instances twice; renderer failures could interrupt refresh. | Context include guards, protected display notifications/rendering, one coalescing callback detached before work; UI-only refresh cannot replenish exhausted gameplay retries. | `cats_metadata`, `cats_ui`, `cats_faults`: listener counts unchanged, 1,000 dirty signals, persistent faults stop, explicit reopening works. Passed. |

No reproduced defect required changing the existing SQL bonus definitions or replacing the WLTKD algorithm. Those implementations were retained and tested more deeply.

## B. Enhancements implemented

- Cats details label personality, current home/state, individual resident effects, family, biography and active bonds. All eleven names, genders and illustrated portraits remain canonical, with Austin first.
- Homes displays each owned city's three-slot capacity, resident portraits/traits/effects, active bonds and Cat Tree Food status. Home cards are pooled and released on city removal.
- Bonds displays each exact requirement, active/inactive status, host or suggested city, effects and missing companions. Bonnie's diagnostic requires Bonnie plus any one kitten, without implying all five are necessary.
- Optional settling messages and once-per-city bond messages have saved preference/seen bits. A reload silently baselines existing bonds, including saves created before the sidecar. Notifications award no gameplay resources. Failed narrative saves suppress unsaved bond notices and retry later.
- Chapter stories remain optional and nonblocking. The six histories and **11 / 11 — Everyone Is Home** milestone are retained without rewards or reload replay.
- Existing artwork was preserved. No reference photographs were available. A verified cat rig/animation/export pipeline was unavailable, so the stable Worker world model remains; see the art investigation in `Implementation.md`.

## C. Mechanics preserved

Austin remains leader-only. All ten companion identities, exact genders/biological relationships, six era chapters and later-era catch-up remain. Settling requires a travelling canonical cat, an owned city, a free slot and expired cooldown. Rehoming, safe pending arrival, three-turn Standard recovery, ten-turn Standard cooldown and all speed scaling remain. All four bonds, current-capital recalculation, Cat Tree and genuine-event +25% WLTKD remain. Human-only and single-player gates, one private UI addin and other civilizations' rules remain unchanged.

## D. Balance verification

Core, inheritance, effects and atlas SQL retain the shipped fingerprints: no numeric or gameplay-ID changes. SQL-backed checks cover every personal flat yield, Luna's local +10% GP, Bonnie's general +5% Production, Charlotte's 500 defense hundredths, four uncapped +1 Happiness effects, and Sisi's exact positive-surplus +5% Growth. Independent Mother and Daughter adds another five percentage points, without extra gross Food. CP source confirms choice activation/cancellation and native serialization; choices have no selectable parent event.

The 240-event WLTKD simulation confirms cumulative floor(added duration / 4) extension with fractional carry, across four speeds/two cities and ownership/refounding changes. The native setter avoids recursively emitting duration/instant-yield events. Silent direct counter edits by another script remain undetectable and are not inferred retroactively. Cat Tree Food remains once with any residents. None of these source/model checks claims native yield execution.

## E. Performance

No high-frequency polling, map scan, idle callback or global interface replacement was added. Eleven cat rows and four bond cards are created once; Homes uses a reusable pool. Gameplay scans only the player's units/cities at lifecycle points. The shared deferred callback clears itself before work, retains reentrant changes and stops after two deferred gameplay attempts if errors persist. A later real lifecycle event permits retry; UI-only events permit rendering without waking persistent gameplay failures.

Executed stress models cover 1,000 stable reconciliations (under 0.3 seconds in recorded local runs, zero redundant native-state writes/notices), six cities/ten cats over 720 turn transitions, 12 rehomes, 50 context reloads, 200 panel opens and 1,000 dirty signals. Listener and instance counts remain bounded. These are model timings/counts, not native FPS or memory profiling.

## F. Save compatibility

The collection UUID/version 10 and existing database IDs are retained. The fixed 82-number `THE11CATS1` gameplay format, field order and meaning are unchanged. Existing chapter bits, assignments, recovery boundaries and cooldowns load without migration in simulations. Other ScriptData is preserved. Only optional narrative preference/seen bits use `THE11CATS_N1`; missing sidecars are initialized silently, and unsupported narrative versions disable only optional messages. Unsupported/ambiguous gameplay data is preserved rather than reset. Invalid numeric timers receive narrowly scoped repair.

Native pre-polish save/autosave continuation has not been observed. Format tests support compatibility but cannot prove native loading.

## G. Outstanding native risks and verification

All eleven Lua behavioral suites, actual-schema/source/static/asset checks, collection regression and release-package verification pass. See `Testing.md` for the complete test matrix and executable commands.

Native Civ V acceptance remains pending for luxury activation/refresh, actual yields/GP/Happiness/displayed strength/Growth, persisted native growth choices, land/embarked death and delayed removal, gifting/trading/capture event order, original-capital loss, actual older-save/autosave continuation, screen transitions, font wrapping/resolution/portraits and late-game FPS/memory. The art limitation is the unchanged Worker world model. No simulated result is presented as native compatibility proof.
