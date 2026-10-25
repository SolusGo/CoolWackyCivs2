# The Urgal changelog

## 1.0.1 hardening preview — 2026-10-26

- Make Urgal human-only in setup and runtime; retain the legacy AI file dormant and leave McPvP unchanged.
- Remove city-attack cancellation: eligible melee units retain the full +50% AttackMod against units and cities. Defense and city bombardment are unchanged.
- Keep Strength II at 3/5/7/12 turns; scale Aftertaste to 1/2/3/6. Preserve already-recorded save deadlines and use documented TrainPercent fallbacks for custom speeds.
- Require an eligible unembarked unit to drink, while preserving embarked participants in mixed snapshots. Separate immediate and embarked activation feedback.
- Replace the wine glyph with a transparent 32px purple potion DDS adapted from existing artwork. Keep the panel bounded, truncate long titles using the native helper, and retain the full inventory tooltip.
- Guard reentrant clicks, duplicate creation events, corrupt/future records, large integer encoding, transient setter/notification faults and stale/same-context UI callbacks.
- Expand to seven shipped-Lua suites (ten runs), SQL-backed combat/healing models, native source contracts, icon/layout checks and generation reproducibility. Native acceptance remains pending; see [the audit report](docs/Audit.md).

## 1.0.0 implementation preview — 2026-10-26

- Add human/AI-playable Urgal from the supplied MCPVP Hardcore Games design: finite persistent Era potions, a snapshot-only offensive Strength II window, fixed two-turn Aftertaste and speed durations 3/5/7/12.
- Add the 14-strength, 2-move, 80-cost iron-free Rusher and permanent Pot Chaser, whose conditional native kill healing restores 15 HP. Add the 75-cost/1-maintenance Brewing Stand with inherited Barracks XP and local +10% eligible melee production, without potion generation.
- Add the compact event-driven stockpile/drink UI, concentrated-army AI activation, Civilopedia, Dawn/diplomacy text, original leader/Rusher/Brewing Stand paintings, potion emblem, map and 48 DDS textures.
- Add actual-schema replacement/coexistence checks, four shipped-Lua lifecycle/UI/AI suites and a pinned CP v151 source audit. Native rendering, gameplay, save round trips, AI and balance acceptance remain pending; see [Testing.md](docs/Testing.md).
