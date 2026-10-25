# Changelog

## Refinement audit — 2026-10-25

- Fix a reproduced corrupt-record overflow: an oversized numeric peace counter became Lua infinity and incorrectly granted three Quietude stacks. Reject unsafe numeric fields while preserving the original invalid record and valid v1 keys/data.
- Correct the documented `UnitUpgraded` phase: native notification is pre-copy, and existing post-copy `UnitConverted` reconciliation provides the final promotion repair. Keep the working state machine, numerical design, IDs, schema, version 14, artwork and human-only flags.
- Expand to ten shipped-Lua suites and 44 pinned CP v151 contracts; add bound save-container/slot isolation and rollback models, team-ID/cascade order, pre-DoTurn/sixth-boundary reloads, changed owner plus ID, and free Belfry tests.
- Add installed Firaxis save/event/preview evidence, combat-alternative audit and per-row native acceptance records. No safe exact owned-target modifier was found; native same-team/open-border and ranged firing-plot approximation remains explicit in Civilopedia. Native gameplay/save round trips remain unverified.

## 1.11.0 implementation preview / collection v14 — 2026-10-25

- Add human-only Keeper Sable and Stillhaven, complete English identity/history/strategy, the supplied Dawn narrative and supported diplomacy response categories.
- Add civilization-wide 5-turn Quietude, cap 3, six binary Culture/Science dummy buildings and Silent Belfry with active Temple inheritance plus permanent +1 Culture.
- Add native friendly-land Great Toll tiers 5/10/15, immediate event-driven consumption, uninterrupted-war guard and persisted five-full-window duration with early peace removal.
- Add Bellwarden using active Pikeman scalar/companion/model/flag inheritance and permanent +1 Sight/+15% friendly-land promotion retained on upgrades.
- Add original generated leader/emblem/building/unit paintings, tintable alpha bell, promotion badges, silent static leader scene and mipmapped DDS atlases.
- Validate actual schema SQL, 176 companion tables, changed baselines, Lua 5.1 mock transitions and 18 pinned CP source contracts. Native gameplay/rendering/save/load remain pending. CP open-border territory and ranged shooter-tile combat deviations are verified and documented; exact owned-target semantics are not implemented.
