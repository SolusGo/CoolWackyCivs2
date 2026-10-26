# Jin Dynasty changelog

## 1.13.1 hardening preview / collection version 16 — 2026-10-26

- Add deterministic autonomous local melee/ranged defense and return, deferred outside movement/turn callbacks. Prevent player missions and repeat activations; retain leash, capacity, cooldown, expiry, Chemistry and separate emplacement shots.
- Add Reindeer Trader surplus-Food production and HurryCostModifier 0 versus Caravan 20; retain Cost 90/Moves 2 and prove the route-speed connection in CP source. No fabricated trade HP protection or new income/slots.
- Apply HP promotion deltas, reuse spatial indexes, skip unchanged serialization and UI rebuilds, and release the UI rendering guard after errors.
- Add recoverable recruitment and partial-Bribe receipts, post-spawn rollback, exact payment intents, nested state validation, original-record preservation and combat-safe defender retirement. Exclude trade representation retirement from Karma; explicit native plunder still deducts a loss.
- Extend the original seven suites with autonomy, transaction and hardening suites; record baseline versus current workloads at 100/300/500 units and 15 emplacements/Groves. Audit named-tech fidelity without changing their balance.
- Keep the UUID, mod version 16 and schema 1; existing valid Jin state needs no reset. Native acceptance remains pending. Full findings: [Hardening.md](docs/Hardening.md).

## 1.13.0 preview / collection version 16 — 2026-10-26

- Add human-only Wanyan Aguda and Jurchen Legacy, full requested unit roster, active Worker/Caravan inheritance, Grassland selection, separate Horse inventories, exact native cavalry maximum HP and paid instant cavalry recruitment.
- Add Emissary caps, independent City-State Tributaries, native economic yields and neutral hostile Bribe replacements; implement all six branching constructed Landmarks, Garden, Karma/blessing, Groves and bounded automatic mounted defenders.
- Add thirteen named upgrades, six-tab Dynasty panel, original Aguda painting, deterministic crimson/gold iconography, flags and DDS assets. Preserve collection UUID, previous SQL insertion order and existing civilization gameplay files.
- Add executable Lua behavior tests on four game speeds, installed-schema regression/inheritance checks, source audits, benchmark and packaging integration. Detailed actual outcomes are in docs/Verification.md and docs/Validation.json. Native gameplay, rendering and saves remain unverified; this is an implementation preview.
