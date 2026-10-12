# The Boundless City changelog

## 1.0.0 implementation preview — 2026-10-12

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
