# Changelog

## 2026-10-23 — final quality and 2D artwork pass

- Verify successful native save writes as well as exceptions; silently rejected saves no longer consume travelling cats or announce unsaved bonds.
- Block new births/rehome while an unidentified failed-setup/rollback unit remains; preserve residence/cooldown and retry cleanup within the existing bounded dispatcher.
- Merge already queued work into synchronous reconciliation without losing era intent. Screen transitions now request UI-only refreshes.
- Replace the fifty 2D textures with eleven individually painted portraits, an exactly eleven-member assembled emblem, refined paw/crown alpha/flag, clearer Cat Tree art, dedicated Austin leader and first-companion Dawn scenes and a quiet Household background. Preserve original reference, prompts, selected sources and deterministic masters.
- Preserve ears/crown in circular crops; use small-symbol icons through 80px; improve status colors, wrapped roster row heights and Bond/card spacing. All gameplay numbers, IDs, UUID/version 10 and save formats remain unchanged.
- Thirteen Lua suites plus stronger mip/identity/asset validation and exact repeat-build checks pass. No 3D art was changed or investigated. Native acceptance remains pending; see the updated report and checklist.

## 2026-10-23 — reliability and Household polish

- Clear busy, synchronization, spawning and removal guards after interrupted calls; retain reentrant capture/era work and bound deferred retries without idle polling.
- Prefer saved travelling unit IDs when repairing duplicates; restore identity promotions from independent metadata; repair impossible timers and prevent rehoming while cleanup remains pending.
- Verify native ScriptData writes, roll back unsaved settle/rehome actions and adopt a single interrupted native unit birth. Stop effect updates if a city changes identity/owner mid-mutation.
- Add structured personal details, per-city portrait cards, four Bond diagnostics and explanatory disabled actions. Reuse UI instances and prevent duplicate registration within a context.
- Add optional settling and once-per-city bond feedback with a separate saved presentation record. Existing gameplay format, IDs, all numeric bonuses, six stories, milestone and artwork remain unchanged.
- Expand from six to eleven Lua 5.1 suites, covering faults, metadata, optional notices, 240 WLTKD events, 720 turn transitions, 12 rehomes, 50 reloads and UI event storms. Static/source/simulation checks pass; native acceptance is pending. See [the report](docs/PolishReport.md).

## 2026-10-23 — implementation preview

- Registered human-only The 11 Cats and Austin, King of the House, in collection version 10.
- Implemented all six chapters, ten companion identities, settling, exact resident effects, four bonds, Cat Tree, rehoming/cooldowns, no-loss recovery and genuine-event WLTKD duration.
- Added the event-driven Household/Cats/Homes/details/latest-story interface and complete personal histories, Civilopedia concepts and unvoiced diplomacy.
- Prepared fifty mipmapped DDS files from the supplied emblem; white Austin, eleven distinct source insets, readable small paw/crown icons, Cat Tree icon and static leader/loading scenes.
- Added real-schema validation, six Lua 5.1 behavioral suites, CP source checks, failure/reload/ownership tests and an explicitly separate native acceptance matrix.
- Full collection regression validation passes. Native in-game behavior/rendering/save acceptance is pending and is not claimed as passed.
