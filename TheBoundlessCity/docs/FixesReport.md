# The Boundless City — implementation review and fixes

**Date:** 2026-10-12 · **Release:** 1.1.0 implementation preview / mod version 2 · **Target:** BNW + Community Patch v151

All safe implemented corrections are in CoolWackyCivs2. Existing theme/art/uniques/personality/border formula/rewards and mode/direction controls are preserved. The original CoolWackyCivs collection was only read for comparison; its pre-existing project modification remains its only reported change. This report distinguishes code/source/mock verification from native playtesting, which was not available.

## Confirmed bugs and causes

| Bug or design gap | Root cause | Correction / remaining restriction |
| --- | --- | --- |
| Remote capacity stopped at local workers | Only `AlterWorkingPlot` withdrawals counted; real surplus defaults ignored | Use conservative default surplus against all local jobs/building slots plus verified forced withdrawals, without adding overlapping bounds. 80/500 fixture credits 50 remotes, 150/1,000 credits 120. Full population-only assignment remains restricted. |
| Native DoTask argument error | Fourth option was a Lua boolean, but CP reads `luaL_optint` | Numeric flags throughout; mock rejects booleans. |
| Incorrect labourer compensation under specific extras | `GetSpecialistYield` mixes per-citizen player extras with count-multiplied city extras | Database base + native total type extras / actual defaults; six-source modifier/unrelated-yield tests. |
| Remote Culture missed source-sensitive conversion | Everything was injected into misc | Gross plot yields use terrain, compensation uses misc. Terrain-Culture conversion sees them; native worked-only effects remain partial. |
| Stale native yield caches after terrain changes | Terrain setter does not run `UpdateCityYields`; zero misc deltas do nothing | Apply terrain first and refresh six rates through compensation or journalled net-zero pulse. Same-frame Tourism cache is still a native test item. |
| Partial ledger cleanup could remove the wrong amounts | A multi-yield operation was recorded only as a batch | Journal each completed source delta/read-back even when a callback raises after mutation; pulses included. Fault tests preserve unrelated sources. |
| Manual unlock deselected / Auto respected old locks | Selection and locking were conflated | Independent selected/locked records, Auto ignores locks, Manual unlock keeps selection, Hybrid prioritizes locks. |
| Capacity counters understated/optimistic | Local workers used as a proxy, no safe-pool/eligible-inventory distinction | Full census, movable citizens, safe additional capacity, structural limit, idle/unassigned, pending/locked intents and gross/comp/net yields. |
| Mountain wonders rejected, water unlocked too early | Blanket mountain exclusion and missing native water technology check | Native HasYield, water-work tech, enemy/blockade checks; yielding mountains allowed. |
| Arbitrary city custodian | Recovery searched unrelated alive players after historical owners | Previous/original legal living owner, then native-identified living liberation recipient. No arbitrary fallback. |
| Return ping-pong and capital workforce loss | Repeat recipient not remembered; any Boundless city transfer reset capital reservations | Remember city founding/recipient; reset capital records only when original capital is transferred. Legal orphan removal or protected quarantine. |
| Replacement city could be mistaken for original capital | Initialization trusted whichever city held capital status | Require native original-capital/original-owner identity initially, then immutable coordinates/founding turn. |
| Extra-city production gaps | Only training/construction were guarded | Clear queue/production automation; veto projects/processes too. Native protected-city effects remain a quarantine limitation. |
| Movement/AI/UI repeated expensive scans | Every move revalidated assignments; worker planning repeated territory/build work; rows rebuilt repeatedly | Indexed nearby eligibility/credits, relevant-war filtering and coalescing; cached shared AI/build lists with 24-candidate/12-path budgets; revision/sort row cache and 16-row paging. |
| Save shape / migration weaknesses | No explicit new-schema migration and incomplete nested-table validation | Version 2 migration, canonical keys/records, partial phase recovery, native-save rewind authority, future/corrupt payload preservation. |
| New Lua include shadowed UI basename during development | Civ V VFS/include resolution is filename-based | Helper named BoundlessCitizens; manifest validator rejects duplicate imported basenames. |

## Population accounting and exact capacity

The city center is free. Supported ordinary population satisfies:

```text
native local + credited remote + building specialists + idle defaults + unassigned = population
credited remote <= protected real native defaults
```

Let surplus = max(0, population - owned native local job positions - static slots in present specialist buildings). Even an adversarial governor cannot consume all those surplus defaults. Protected count is the real default count capped by the **maximum** of surplus and verified forced withdrawals. These bounds overlap and cannot be summed. Specialists/local locks are preserved; external worker automatons conservatively disable credits. Population and Food consumption remain native.

With 30 native positions/no specialist slots, the requested fixtures result in 10/30/50/120 remote credits at populations 10/40/80/150 respectively. Higher surplus exceeds the previous 30-job ceiling. The 80-population fixture still has 30 pending requests, because forcing every default against future governor allocation requires a setter that CP v151 does not expose. Real unassigned citizens are not manufactured into defaults. [Implementation.md](Implementation.md) defines the exact accounting and source formulas.

## Conquest and strict one-city enforcement

Normal occupation remains blocked by NoCapture. Restricted siege demolition is implemented: enemy city at 1 HP, visible, at war, adjacent non-embarked melee with moves, hard protected exclusions, and current-owner native CanRaze. Deferred execution revalidates owner/founding identity, consumes moves, disbands through the current owner and releases associated acquired plots. Boundless receives no city, territory or capture reward.

This does **not** solve ordinary conquest. Native CanRaze requires ownership and rejects the owner's own-founded city; therefore most normal enemy towns remain capture-blocked. The safe action generally applies to previously captured settlements. Original capitals, holy cities and current/original city-state settlements cannot be demolished. No universal safe pre-acquisition veto or ownership-independent legal raze check was found.

Unexpected extras use historical/native recipients, return-loop suppression, native-legal disband fallback, or protected quarantine. Capture callbacks never acquire/delete/raze. Normal founding/training/buyout paths are blocked; later gifted/scripted Settlers are cleaned up. External scripts can still create a transient second city, and a protected/own-founded orphan can remain quarantined. Queues and production gates reduce use, but native yields/UI cannot be guaranteed absent. Capital identity never changes; loss suspends the UA and military recapture is also NoCapture-blocked. These limitations are retained prominently in [EngineLimitations.md](EngineLimitations.md).

## Save compatibility and performance

The mod UUID remains unchanged; mod version increases to 2 with minimum compatible save version 1. The BCSTATE1 envelope now carries schema 2. Version 1 locks become explicit selections, reservations become withdrawal cleanup records, and capital/progress/rewards/modes/direction survive. BCY1 net-misc ledgers migrate to BCY2 split sources. Unknown/corrupt state is preserved and disabled. Native ScriptData is authoritative, so older saves rewind properly; mirror data never overwrites a loaded native snapshot. Downgrading migrated saves is unsupported.

Movement touches only old/new neighborhoods and indexed owned remote plots. No changed eligibility/credits means no reallocation. Native scalar changes use the full safety path. Frontier remains cached/incremental without a tile cap. AI uses legal paths/builds, persistent target identities and budgets; no busy-order overwrite, area cap or teleport. UI is event-driven and builds at most sixteen rows with cached sorting; no idle polling. The native governor still chooses remaining local/specialist allocations, so Auto is a constrained weighted optimizer.

Measured results are in [Benchmark.json](Benchmark.json), covering assignment changes, reconciliation, movement, AI, claims and open/closed UI at 100–10,000 owned plots on a 16,000-plot map. They measure this host's **mock Lua execution**, not native FPS/pathfinding. Native turn timing, save size and AI path completion remain outstanding.

## Exact changed files

New runtime files:

- `TheBoundlessCity/Lua/BoundlessCitizens.lua`
- `TheBoundlessCity/Lua/BoundlessAI.lua`
- `TheBoundlessCity/Lua/BoundlessSiege.lua`

Updated runtime/integration:

- `TheBoundlessCity/Lua/BoundlessCore.lua`
- `TheBoundlessCity/Lua/BoundlessEvents.lua`
- `TheBoundlessCity/Lua/BoundlessPersistence.lua`
- `TheBoundlessCity/UI/BoundlessWorkforce.lua`
- `TheBoundlessCity/UI/BoundlessWorkforce.xml`
- `TheBoundlessCity/SQL/10_BC_Text.sql`
- `CoolWackyCivs2.civ5proj`
- `Cool Wacky Civs 2 (v 2).modinfo` (replaces version 1 manifest)

Tools/tests:

- `tools/audit_cp.py` (new)
- `tools/benchmark.py`
- `tools/build_mod.py`
- `tools/generate_database.py`
- `tools/validate_mod.py`
- `tools/tests/boundless_mock.lua`
- `tools/tests/boundless_assertions.lua`
- `tools/tests/frontier_assertions.lua`
- `tools/tests/ui_assertions.lua`
- `tools/tests/workforce_stress.lua` (new)
- `tools/tests/completion_safety.lua` (new)
- `tools/tests/siege_safety.lua` (new)

Documentation/records:

- `README.md`, `CHANGELOG.md`
- `TheBoundlessCity/README.md`, `TheBoundlessCity/CHANGELOG.md`
- `docs/civilizations/TheBoundlessCity.md`
- `TheBoundlessCity/docs/APIAudit.md`
- `TheBoundlessCity/docs/Implementation.md`
- `TheBoundlessCity/docs/EngineLimitations.md`
- `TheBoundlessCity/docs/Testing.md`
- `TheBoundlessCity/docs/Benchmark.json`
- `TheBoundlessCity/docs/SourceAudit.json` (new)
- `TheBoundlessCity/docs/FixesRequest.md` (supplied specification, new)
- `TheBoundlessCity/docs/FixesReport.md` (this report, new)

Existing SQL identities/inheritance/effects/art definitions, all artwork and original specification remain unchanged. Generated v2 ZIP/Civ5Mod packages are local ignored build products.

## Verification and release gates

All six Lua simulation suites passed, including the requested workforce cases, adversarial native allocation model, source arithmetic/modifiers, partial failures, migration, conquest/protected transfers, UI/movement and wrapped growth. Actual-schema SQL/package/art and read-only coexistence audits passed. The pinned source audit passed 121 assertions. Archive integrity is checked by the builder. See [Testing.md](Testing.md) for scope and reproducible commands.

**Native Civ V gameplay was not run:** no controllable game session is available in the tool environment. Native governor/event ordering, six cached rates/Tourism, Golden Age/religion recalculation, source rebuilding during capture, migration/save loads, transient quarantine UI, demolition cleanup, Surveyor pathfinding and Huge-map FPS remain mandatory live checks. The detailed setup and step-by-step cases are in Testing.md. Passing mocks does not promote these mechanics to native-verified status.
