# Changelog

## 1.0.0 implementation preview — 2026-10-12

- Created CoolWackyCivs2 as an independent collection and Git repository with its own mod identity.
- Added The Boundless City, led by The First Architect, with a single original capital.
- Added a separate Culture accumulator and deterministic, contiguous frontier growth without a distance limit.
- Added remote plot assignment through verified native labourer reservations and exact evaluated plot yields, subtracting replacement labourer yields.
- Added Automatic, Manual and Hybrid modes, Food/Production/Gold/Balanced priorities, persistent locks/exclusions, directional borders, paged browsing and plot location controls.
- Added The Grand Registry's +3 Culture, capped territorial Culture and 15% frontier-cost discount; inherited the active Monument's other effects.
- Added a 3-Movement Frontier Surveyor with 125% base Worker work rate, inherited build/AI/upgrade relations, and persistent one-time distant improvement rewards.
- Added native no-capture promotions, founding/training vetoes, Settler cleanup and deferred safe transfer recovery.
- Added player-save persistence, a native city yield ledger, deterministic AI allocation and idle Surveyor missions.
- Added original illustration and 34 DDS assets, ModBuddy solution/project, load-ordered modinfo, ZIP/Civ5Mod builders and focused SQL/Lua/UI/package tests.
- Added a detailed collection README, dedicated civilization page, civ README/changelog, API audit, implementation guide, limitations and CP v151 testing checklist.

### Remaining verification and design gaps

- Live game selection, native save/load, capture/transfer UI ordering and Huge-map FPS have not been tested.
- Remote distance is unlimited, but remote count depends on native tiles from which citizens can be safely withdrawn; the original population-only capacity requirement is unmet.
- Military city capture is blocked. Automatic destruction of ordinary conquered cities and a civilization-specific Domination victory are not implemented.
- Unexpected transfers recover after the native action. If no eligible living recipient exists, the extra city is quarantined; an absolute synchronous one-city guarantee against arbitrary external scripts is unmet.
- Virtual tiles do not count as natively worked tiles for conditional worked-tile triggers, improvement evolution or worked-tile tourism. Six ordinary plot yields are supported.
- AI deployment is implemented and simulation-tested in parts; complete native builder/pathfinding behavior still needs game verification.
