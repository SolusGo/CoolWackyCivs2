# The Boundless City changelog

## 1.1.0 implementation preview — 2026-10-12

- Extended real-citizen reservations using a conservative governor-proof surplus; no free workers, negative counts or population changes.
- Corrected default specialist extras, native yield-cache ordering and terrain-Culture source handling; journalled both ordinary mutations and net-zero refresh pulses.
- Added explicit Manual selections, independent unlocks, Automatic lock isolation, pending requests and precise UI census/capacity/yield figures.
- Added native-legal siege demolition for qualifying captured settlements, with 1-HP/melee/war/visibility checks, protected-city exclusions, deferred revalidation and territory release.
- Added historical/native liberation recovery, no arbitrary recipient, return-loop detection, legal orphan removal and protected quarantine. Returning an extra city preserves capital workforce records.
- Added plot-indexed movement invalidation, eligibility caching, cached/budgeted Surveyor plans and event-driven cached UI rows.
- Added state version 2 and BCY2 ledger migration, malformed/future state preservation, shape validation and partial-failure tests.
- Added 10/40/80/150 population stress cases, adversarial governor/specialist/modifier checks, wrapped water growth, conquest safety and measured performance through 10,000 owned plots.
- Preserved all original art, uniques, flavor, direction controls and balance numbers. Updated every gameplay/audit/testing guide; see [FixesReport.md](docs/FixesReport.md).

Full population-only remote allocation, demolition of first-founded enemy settlements and immediate resolution of all external transfers remain engine restrictions. Native game testing is still required.

## 1.0.0 implementation preview — 2026-10-12

Historical initial implementation; limitations below describe that version.

- Added civilization, leader, original capital, localization, AI personality, Monument replacement and Worker replacement.
- Added unlimited-distance contiguous cultural frontier expansion with a separate persistent pool, speed/era/territory costs, deterministic ranking and direction preferences.
- Added six evaluated remote plot yields and verified population reservations using native forced labourers; compensated labourer yields through a replacement ledger.
- Added automatic/manual/hybrid management, manual locks, exclusions, priorities and a sixteen-row paged workforce UI.
- Added Registry territorial Culture bits and a 15% custom expansion discount.
- Added Surveyor speed/movement changes and once-per-plot distant improvement Culture rewards.
- Added founding and Settler guards, native no-capture enforcement, deferred city return and explicit quarantine for no-recipient transfers.
- Added authoritative native-save state, redundant OpenSaveData mirror, save validation, synchronous removal of invalid remote contributions and event-driven deferred reallocation.
- Added deterministic AI allocation and idle native Worker missions, original gold/ivory/blue artwork and 34 supported DDS assets.
- Validated actual SQL inheritance, Lua 5.1 syntax, simulated population/yield/save/frontier/UI invariants and matching project/package references.

### Known gaps

Population-only unlimited reservation capacity, same-action resolution of all transfers, automatic razing of ordinary conquered cities, native worked-tile conditional effects and standard Domination are not implemented as originally envisioned. Live CP v151 save/UI/AI tests and actual Huge-map FPS benchmarking remain open. See [EngineLimitations.md](docs/EngineLimitations.md) and [Testing.md](docs/Testing.md).
