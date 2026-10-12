# The Boundless City changelog

## 1.2.0 engine preview / mod version 4 — 2026-10-12

- Added native civilization-scoped zero-city survival while units remain, and a deferred original-capital-only siege reclaim action. Ordinary NoCapture remains. Eliminated players are not revived; older native trait caches need upgrade verification.
- Added one-time non-destructive subjugation for defeated protected/own-founded major settlements, shared human/AI validation, action/actor identity checks and a lost-capital military panel.
- Added an optional Boundless-only native Domination finish after all ever-alive other-team rival original capitals are subjugated. Missing/replaced originals and disabled/prior victories block it. Native victory behavior remains unplayed.
- Added assigned-only native-rate improvement upgrade progress and explicit native Tourism refresh after terrain Culture changes/removal.
- Added extra-city native border-selection and new-trade-route vetoes. Absolute ownership and empire-level quarantine effects remain engine limited.
- Migrated Lua state explicitly to schema 3; kept BCSTATE1/BCY2, UUID and minimum save compatibility 1. Prior progress, identity, preferences and rewards persist; no downgrade support.
- Expanded to nine Lua simulation suites and 176 pinned native-source checks; refreshed Huge-map simulations and v4 ZIP/Civ5Mod artifacts. Updated READMEs, civ page, implementation/API/live-test guides, effect matrix, six-status report and optional DLL proposal.

This is an implementation preview. Full population-only reservation and general own-founded enemy demolition remain blocked. Native gameplay, save/trait upgrade, AI tactics, victory ordering and FPS must be verified through the live checklist.


## 1.1.1 stability preview / mod version 3 — 2026-10-12

- Preserved the verified forced/surplus citizen model and all balance/art/unique mechanics.
- Added siege rejection reasons, hidden-city protection, native dirty-event refresh and current city-ID checks; AI skips invalid targets.
- Strengthened quarantine with native resistance, six cached-rate refreshes and associated remote/AI plot exclusion, without deleting protected cities.
- Fixed Settler cleanup after capital loss, overly permanent return suppression and safe original-capital return to a living empty Boundless owner.
- Fixed partial trim failure cleanup, automaton fast-path accounting and optional mirror failures.
- Added AI lifecycle/build-ID guards, busy target ownership, unreachable cooldown and fair/shared per-turn path budgets.
- Added repeated mode/source/rewind, sharp starvation, simultaneous eliminated-owner transfers, quarantine reload, native mirror/trim faults, AI lifecycle and fogged siege tests.
- Updated all current guides and the [final stability report](docs/FinalStabilityReport.md); eight suites and 129 source assertions passed. Native playtesting remains outstanding.

Save schema 2 and BCY2 remain unchanged; package version 3 distinguishes the update while retaining minimum save compatibility 1.

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
