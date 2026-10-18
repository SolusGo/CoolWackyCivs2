# Changelog

## Implementation audit and stability fixes — 2026-10-18

- Shared native screen eligibility between the controller and Prayer panel; reject direct requests during city/diplomacy/modal/mode transitions, hidden contexts and reentrant reconciliation without changing rewards or saved progression.
- Keep existing blessing deadlines aging during temporary nonhuman control, without initializing AI prayer or progressing stages/Grace.
- Verified native Keeper healing against movement eligibility; no reachable foreign-city healing defect was established. Original promotion definitions and serialized counters remain unchanged.
- Close hidden panels after missed popup events and coalesce city/game dirtiness through the existing self-detaching UI callback. Added three regression suites and expanded UI/CP source checks.
- Retain native `CityStrengthMod=20` after inspecting alternatives; disclose its ranged-strike effect in Prayer help. All seven petitions, Grace, Keeper, House, human-only rules and numerical balance remain intact. See [the audit report](docs/AuditReport.md) for severities, changed files, evidence and native limitations.

## Initial implementation — 2026-10-18

- Added The Children of the Kingdom, The Faithful, Sanctuary, all seven prayer petitions, scaled cooldown/durations, permanent Grace capped at seven, excess-cycle rewards and completed-House Faith rewards.
- Added a fully event-driven Prayer panel, save-bound player state, exact dummy/policy reconciliation and city/unit ownership cleanup. Every custom system requires human Kingdom control; ordinary AI assignment is disabled.
- Added Pikeman/Temple inheritance, upgrade-retained Stand Firm, separately gated defensive promotions, native healing, safe full-value Production reserves and complete English help/Civilopedia/UI text.
- Added an original generated Faithful/Sanctuary painting, original drawn insignia/map, 34 DDS assets, static leader scene and gold-framed collection atlases.
- Added four shipped-Lua simulation suites, actual-schema and pinned-source audits, artwork/XML/package validation and a native verification checklist. No native game runs or native save round trips are claimed.
