# The Twelfth Hour changelog

## 2026-10-19 — Second-pass technical audit

- Match Firaxis's dot-call OpenSaveData function contract; retain all existing v1 keys and per-save data without migration/reset.
- Open lazily inside protected work, retry idempotent synchronization once synchronously, and isolate player failures during initialization/load/batches.
- Mark notifications after successful delivery, preserving deduplication if persistence must retry. Reconcile Clocktower sales immediately in the verified post-removal hook.
- Replace permissive save/sale mock assumptions and add snapshot rewinds, same-turn independent games, absent-key saves, pre-staging autosaves, deletion/corrupt-count cleanup and fault regressions.
- Expand to 20 Lua suite runs, 43 freshly reviewed pinned CP contracts, CP-derived yield arithmetic and installed Firaxis save-API/schema evidence. No SQL, balance, art, identity or unrelated-civilization changes. Native gameplay/serializer acceptance remains pending; see [the audit](docs/AuditReport.md).

## 2026-10-19 — Initial implementation

- Added the human-only Keeper of Seconds, Last Minute and all twenty city names, When the Clock Strikes, Pendulum Guard and Municipal Clocktower.
- Added six-played-turn Chimes through native Production/Science modifiers; synchronized next-turn staging at CP PlayerDoneTurn avoids relying on the post-harvest PlayerDoTurn hook.
- Added deterministic save reconstruction, interturn phase persistence, once-per-Chime notifications and city/building/ownership lifecycle cleanup.
- Preserved all active Pikeman/Workshop scalar and installed direct companion rows; added upgrade-retained Movement/friendly-territory strength and additive permanent Culture.
- Added original painted icons/leader/loading art, alpha/flag assets, complete English text, generated packaging and validation.
- Added actual-schema SQL, altered baseline inheritance, ten Lua 5.1 simulation runs, seventeen pinned CP source contracts and full-collection packaging/regression checks. Native Civ V execution, actual yield settlement, autosave resumption and rendered UI acceptance remain pending.
