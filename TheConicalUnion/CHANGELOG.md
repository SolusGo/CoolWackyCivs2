# Changelog

## 1.0.1 reliability audit — 2026-10-25

- Replace the shared loaded boolean with context ownership, callback retirement/removal and a shutdown hook; stale wrappers are inert and same-context includes do not duplicate handlers.
- Isolate synchronous retries per city, bound repeated diagnostics, retain only failed foreign city IDs for owner-turn retry, and sanitize persisted foreign markers once per context. Coalesce other-city/ownership notifications during reconciliation instead of dropping them.
- Preserve version 13, UUID, all three exact uniques, SQL/inheritance, human-only selection, artwork and other civilizations. The cached connection flag/post-settlement engine limitation remains; no query hook or polling workaround is added.
- Expand to seven shipped Lua 5.1 suites and 41 pinned CP source contracts plus three installed Firaxis UI API examples. Add explicit economic-phase, quick-load/context, retained-handler, fault-isolation and liberation-shaped scenarios. Native acceptance remains pending; see the audit report and updated testing record.

## 1.0.0 implementation preview — 2026-10-25

- Add High Marshal Bollard, Permanent Detour and 27 additional cities; human-only selection, English Civilopedia/strategy/biography/diplomacy and the supplied silent Dawn of Man.
- Add exactly the specified three uniques. Use two invisible binary yield buildings, native Worker base Work Rate and full runtime Worker/Walls inheritance. Keep ownership cleanup explicit and avoid persistent save data, route searches, frame handlers and accumulating grants.
- Integrate original art, 40 mipmapped DDS textures, ModBuddy, version 13 manifests, build inventory and archive verification.
- Add schema-aware inheritance checks, 26 pinned CP source contracts and three Lua 5.1 suites. Native tests remain pending. Document cached connection timing and the first-settlement synchronization gap precisely in the implementation guide.
