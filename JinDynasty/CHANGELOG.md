# Jin Dynasty changelog

## 1.13.3 Full visual refresh / collection 1.16.3, version 17 — 2026-10-30

- Refresh all existing art and add a complete upgrade atlas and council skin: 82 DDS textures total, with retained original painted inputs and full legacy mip chains. Update every unit/building/Landmark portrait, leader/Dawn, map, flags, civilization identity and HUD icon.
- Add illustrated action rows, five live metric cards, active-tab markers and coordinated native button states; hide the launcher behind the open council. Preserve all action and turn-transition behavior.
- Correct Zhanma's in-world appearance to the available sword-bearing Samurai model. Other animated models remain native Civ V assets; no custom meshes/animations are claimed. Gameplay and save schemas are unchanged. [Coverage, previews and tests](docs/Graphics.md).

## 1.13.2 UI hotfix / collection 1.16.1, version 17 — 2026-10-30

- Fix the disappearing launcher after an AI turn: visibility refreshes now run independently of the closed-panel gameplay optimization. Explicit end/start/load/player hooks close stale panels and recover the launcher after native turn flags settle, without idle polling or closed-panel row allocation.
- Reproduce the pre-fix failure and test 20 successive turn cycles, early turn notifications, dirty-event recovery, load and player changes. All 16 Jin suite/speed runs pass. Gameplay and native save state are unchanged; restart Civ V and reload the same save after updating.

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
