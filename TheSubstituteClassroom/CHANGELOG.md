# Changelog

## Reliability and final audit — 2026-10-24

- Explicitly enable UnitPrekill in this module and test it in isolation; document CP v151's disabled-option fallback and Cats' existing enablement.
- Replace generic dirty-event empire reconciliation with coalesced specific-city repair and native Office count queries. Exclude a razed city's Office before removal and verify relief afterward.
- Recover transient idempotent save/ledger/setter failures with one synchronous retry; never reroll or repeat Culture/notification side effects. Add three patience pips using existing native glyphs.
- Expand to 48 Lua 5.1 runs, a negative option mutation, exact CP/UI contracts, combat/lifecycle/fault coverage and 201-city/2,003-unit dirty storms. Preserve balance, art, identity, version 12 and v1 saves. See [the audit report](docs/AuditReport.md); native acceptance remains outstanding.

## 1.0.0 implementation preview — 2026-10-24

- Add human-only Mr. Garvey and Room 101; selectable 12-turn Roll Call, five 8-turn student bonuses, persistent corrections and 5-turn Detention with additive combat/production, Culture rewards and non-stacking Office Happiness relief.
- Add fully inherited Pikeman Hall Monitor and Public School Principal's Office, event-driven blackboard attendance panel, English Civilopedia/dialogue/notifications and 41 original/generated or drawn DDS assets.
- Register one simulation-owning addin, versioned per-save state, all SQL/Lua/art/project inputs, guides and 32 Lua 5.1 scenario runs, real-schema checks and pinned CP source contracts.
- Native rendering, gameplay and save acceptance remain unverified. See docs/Testing.md and docs/Validation.json for the distinction between automated checks and game tests.
