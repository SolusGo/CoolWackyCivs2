# Changelog

## 1.1.1 stability preview / mod version 3 — 2026-10-12

- Added visible/previously revealed siege targets with explicit protection, damage, melee, war, visibility and native-limit reasons; invalid actions are disabled and AI queues only ready targets.
- Added city-ID revalidation for new demolition records and protected other city centers during territory release.
- Added native resistance and cached-rate refresh to quarantine, plus remote/Surveyor exclusion for its associated plots. Transient ownership and empire-level effects remain restrictions.
- Removed created/converted Settlers outside native callbacks even after original-capital loss, while preserving the initial Settler.
- Restricted return-loop suppression to the same turn and allowed a living empty Boundless player to receive only its recorded original capital.
- Cleared workforce credits/cache immediately after indexed or full trim failures; included automatons in the fast-path census and exposed them separately in UI.
- Made optional save-mirror open/write failures nonfatal to authoritative Player ScriptData.
- Added stale/dead/upgraded AI target cleanup, native build-ID guards, busy-target reservations, three-turn unreachable cooldown, fair unit rotation and a shared 12-path budget per owner turn.
- Passed eight simulation suites, actual SQL/package/art checks and 129 source assertions; expanded measurements to 22 major-player records, 40 minor-player slots and 200 military units at up to 10,000 owned plots.
- Kept native save schema 2, BCY2 ledger and minimum compatible mod save version 1. Version 1 migration and version 2 progress remain supported; native upgrade testing is outstanding.

Existing art, civilization mechanics and balance numbers are unchanged. Full population-only reservations and demolition of first-founded enemy settlements remain unsupported through the verified CP v151 APIs. See the [final report](TheBoundlessCity/docs/FinalStabilityReport.md).

## 1.1.0 implementation preview / mod version 2 — 2026-10-12

- Added verified surplus labourers alongside forced local withdrawals. The 80/500 and 150/1,000 stress fixtures now support 50 and 120 remote citizens; full population-only capacity remains unavailable through CP Lua.
- Corrected count-multiplied specialist extras, split gross terrain yields from labourer compensation, refreshed native cached rates, and journalled partial mutations.
- Separated Manual selection from locks, made Automatic ignore old locks, and added accurate citizen/capacity/pending/lock/yield counters with eligible-inventory limits.
- Added restricted native-legal siege demolition with deferred execution and protection checks. First-founded enemy settlements still fail native legality.
- Replaced arbitrary extra-city recipients with historical/native liberation recipients, return-loop suppression, legal disband fallback and protected-city quarantine.
- Preserved original capital identity and its workforce when returning another city; strengthened Settler, project/process and quarantine guards.
- Added indexed movement checks, coalesced change dispatch, cached AI targets/build lists with path budgets, and cached paged UI rows.
- Added explicit version 1 state/ledger migration, schema-shape validation and future/corrupt payload preservation.
- Passed six Lua simulation suites, actual-schema SQL/package/art checks, 121 pinned source assertions and read-only original-collection namespace checks. Recorded benchmarks through 10,000 owned plots.
- Updated the collection/civ guides, civ page, limitations, native test checklist and detailed [fixes report](TheBoundlessCity/docs/FixesReport.md). Existing art, uniques, personality and numeric balance remain unchanged.

Native gameplay, save/load, AI path completion and FPS remain untested. Version 2 keeps the mod UUID and minimum compatible save version 1; back up old saves and do not downgrade migrated saves.

## 1.0.0 implementation preview — 2026-10-12

The following records the original version's behavior; see 1.1.0 above for current limits.

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
- Fixed LF line endings for text assets so committed manifest checksums remain valid on Windows and fresh checkouts.
- Added a detailed collection README, dedicated civilization page, civ README/changelog, API audit, implementation guide, limitations and CP v151 testing checklist.

### Remaining verification and design gaps

- Live game selection, native save/load, capture/transfer UI ordering and Huge-map FPS have not been tested.
- Remote distance is unlimited, but remote count depends on native tiles from which citizens can be safely withdrawn; the original population-only capacity requirement is unmet.
- Military city capture is blocked. Automatic destruction of ordinary conquered cities and a civilization-specific Domination victory are not implemented.
- Unexpected transfers recover after the native action. If no eligible living recipient exists, the extra city is quarantined; an absolute synchronous one-city guarantee against arbitrary external scripts is unmet.
- Virtual tiles do not count as natively worked tiles for conditional worked-tile triggers, improvement evolution or worked-tile tourism. Six ordinary plot yields are supported.
- AI deployment is implemented and simulation-tested in parts; complete native builder/pathfinding behavior still needs game verification.
