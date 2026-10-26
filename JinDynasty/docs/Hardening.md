# Jin hardening — 1.13.1 preview, 2026-10-26

Baseline was the clean `main` checkout at `f252c632ec00ce675f0c73e32cec59cef7a2b0a1` (1.13.0 / mod 16). Before source changes, `validate_jin.py` passed all 13 original suite/speed runs and `benchmark_jin.py` completed. The expanded profiler also executes baseline Lua directly from that Git object against the same fixtures/database as the hardened code. Ignored raw logs are in `dist/jin-hardening-*`; committed reports are Validation.json, SourceAudit.json, Benchmark.json and HardeningBenchmark.json.

## Findings and changes

| Finding | Actual implementation |
| --- | --- |
| Temporary defenders required player orders; issuing missions inside movement or before unit reset would be unsafe | Autonomy module uses one coalesced deferred callback that clears itself before work. Native source places PlayerDoTurn before doTurnUnits. Sorted local threat selection, native legality/LOS, one saved order budget per owner-turn, bounded approach/return, mission veto and existing transfer cleanup now supply autonomous local defense |
| Defender cleanup could kill a unit during native combat | Busy/fighting retirement remains pending and occupies capacity; reconciliation removes the unit after combat finishes |
| Every HP synchronization searched/cleared the entire 40-promotion bank | Reconstruct once on owner/birth/type/load, then remove only obsolete HP and add desired HP; total Horses once per army pass. Preserve current living HP and fresh recruit full HP |
| Distant valid enemy movement rebuilt all emplacements and decoded state | Derived threat/Grove coverage indexes select only relevant parents; event invalidation and live parent checks prevent stale captures/pillage from granting defenses |
| Repeated unchanged state saves encoded the full ledger | Raw-fingerprint read snapshots, copied returns and structurally compared write snapshots skip redundant decode/encode/write. Caches are disposable and weak-keyed; native ScriptData remains authoritative |
| An exception could leave the panel's rendering guard stuck; generic events rebuilt rows | Always release guard, retry after error, cache static roster/targets, coalesce refreshes, skip closed/unchanged rows and invalidate visible Bribe targets on movement/creation/death |
| Recruitment lacked an interrupted-payment ledger; synchronous creation can precede InitUnit returning | Save optional receipts and unit markers before effects, reserve only after real deployment, persist treasury intent, recover exactly once, find unreturned created units and roll back failed recruitment |
| Multi-target Bribe could stop between replacement creation, original deletion and payment | Per-target receipt records identity/spawn/birth, preserves completed conversions, discards uncommitted clones, settles actual successes and applies cooldown once. Recheck Barbarian hostility before deletion |
| Malformed nested saved records could reach arithmetic/indexing operations | Validate fields/bounds/identities/choices/upgrades/receipts; retain original raw data, log the reason, disable derived benefits, and never silently reset progression |
| Captured Forts beyond initialization city neighborhoods could be missed | Ownership events now index the actual gained Fort/Citadel; captures and improvement changes invalidate coverage |
| Reindeer cost composition had no Food distinction; route benefits were undocumented | Native Food-assisted Production/growth pause and zero unit hurry surcharge give two understandable recruitment alternatives; existing Cost 90 and Moves 2 remain. Pinned native source confirms the civilization's Caravan Moves controls land-route speed and circuit scheduling |
| Generic UnitPrekill treated native trade object retirement as a death | Exclude NO_PLAYER trade removals; the explicit native plunder event charges Karma once. Voluntary idle-trader disband is also treated as noncombat removal. Ordinary combat deaths remain unchanged |

The balance delta is limited to Reindeer `Food=1` and `HurryCostModifier=0`. Existing Horse economy, +2/+1 HP, recruit price, Villager caps, Tributary yields/+15%, Bribe cost/cooldown/lifetime, all six Landmarks, Karma rates, Groves, units, capacities/cooldowns/lifetimes and named upgrade values remain. The additional plunder-event option enables a CP hook, not a new DLL dependency. Existing civilizations' gameplay/art files and database rows remain unchanged.

## Automation and Trader limits

Defenders act only in the active human Jin turn. Enemy-turn movement deploys/reconciles and schedules the next safe owner opportunity. A defender can make one adjacent native approach/return step or one native attack; it does not spend its full movement searching for paths. It favors visible hostile combat threats nearest the parent, excludes cities/civilians/neutrals, respects the four-plot leash and can guard in place at obstacles. A return stops beside a city because entering/capturing cities is prohibited. Grenadiers prefer native ranged legality and retain the existing explosive collateral. Automatic emplacement shots have a separate per-parent/turn budget. There is no continuous polling, global path search, offensive campaign or claim of exact RTS AI.

The Trader's Food flag uses native surplus-Food conversion while training and pauses growth. Gold purchase is an alternative, not a simultaneous fixed Food/Gold bill. Final Gold prices still depend on higher base Production cost, speed, city modifiers and rounding. Moves 2 versus Caravan 1 is an existing coarse integer adaptation, not AoE4's exact +10%. Native route capacity, launch, circuits, returns, cancellation and income are untouched. Native plunder clears the route outright; extra HP would not protect it, so no ineffective HP benefit is added. The [fidelity guide](AoE4Fidelity.md) separates exact mechanics, adaptations, missing secondary details and incorrect named-tech mappings.

## Save compatibility and recovery

Keep UUID `f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392`, mod version 16 and Player ScriptData schema/tag `JIN_P1` version 1. This follows the collection's patch convention. Existing valid Jin saves retain progression; missing acted/receipt fields mean legacy normal state. Runtime HP/spatial/read/write caches reset at bootstrap or context replacement and are reconstructed from native objects/data. Foreign ScriptData is preserved. Same-turn older-save rollback and switching games do not use external Modding SaveData.

Receipt writes cannot make arbitrary external treasury edits atomic. If the saved before/after treasury states no longer match, recovery preserves the receipt, logs the ambiguity and blocks new panel actions. It does not guess a charge or reset a valid economy. Back up real saves before upgrading; downgrade to 1.13.0 is unsupported while a receipt is pending. Native save serialization and mission/animation timing still require [the acceptance checklist](Testing.md).

## Verification boundary

The original seven Jin suites are retained and extended by three behavior suites, for 16 suite/speed runs. These exercise shipped Lua, SQL-backed native doubles and pinned source/API contracts; failure injection covers post-create exceptions, silent ScriptData writes, saved payment acknowledgement, missing deployments, partial Bribes, UI errors and corrupt nested data. Full collection validation also checks unchanged database rows, syntax, entry points, VFS/manifest/project registration, art, coexistence and all previous civilizations. Source validation outcomes and the repeatable measurements are recorded below.

Civ V was **not launched**. Native rendering, animations/mission scheduling, real saves and route lifecycle remain **NOT RUN**. The actual XML frame fits 1280×720 and 1920×1080 geometrically; that is not native visual verification. Large native maps and balance require play testing. Synthetic timings measure Lua against deterministic doubles, never FPS or real pathfinding.

File-by-file scope is in [HardeningChangedFiles.md](HardeningChangedFiles.md). The original implementation report [Verification.md](Verification.md) remains historical; this document and the current JSON reports describe the patch.

## Measured performance

Three repeats per workload; timings below are medians in milliseconds. Operation counts in the JSON are the first pass, including cold coverage construction. Later repetitions reuse derived caches. Both versions use the current SQL and identical fixtures, with baseline Lua loaded directly from Git. The fixture uses distinct army plots, 12 valid enemy IDs, 15 city emplacements, three changed Horse sources and 15 Groves attributed five each to three nearby cities. Garden work includes one entry and one exit per army member. Plot occupancy is constant-time rather than the original mock's global unit search. Deferred native orders are not pumped in this profiler; their behavior is tested separately.

| Units | Workload | Baseline ms | Hardened ms |
| --- | --- | ---: | ---: |
| 100 | unchanged_hp | 2.906 | 0.697 |
| 100 | changed_horses | 3.365 | 1.527 |
| 100 | distant_enemy_1000 | 372.552 | 1.109 |
| 100 | garden_army | 151.968 | 8.767 |
| 100 | near_enemy_100 | 321.635 | 40.242 |
| 100 | unchanged_saves_100 | 54.914 | 2.246 |
| 300 | unchanged_hp | 8.481 | 2.197 |
| 300 | changed_horses | 9.020 | 3.498 |
| 300 | distant_enemy_1000 | 372.274 | 1.221 |
| 300 | garden_army | 457.872 | 26.767 |
| 300 | near_enemy_100 | 352.217 | 39.953 |
| 300 | unchanged_saves_100 | 55.108 | 2.267 |
| 500 | unchanged_hp | 13.678 | 3.951 |
| 500 | changed_horses | 14.771 | 5.594 |
| 500 | distant_enemy_1000 | 362.354 | 1.271 |
| 500 | garden_army | 751.793 | 46.213 |
| 500 | near_enemy_100 | 342.367 | 45.327 |
| 500 | unchanged_saves_100 | 54.437 | 2.310 |

Selected first-pass operations at 500 units (all sizes and counters are in [HardeningBenchmark.json](HardeningBenchmark.json)):

| Workload | Operation | Baseline | Hardened |
| --- | --- | ---: | ---: |
| unchanged_hp | promotion_reads | 26552 | 6512 |
| unchanged_hp | promotion_writes | 1000 | 0 |
| changed_horses | promotion_reads | 26552 | 7012 |
| changed_horses | promotion_writes | 1000 | 1000 |
| distant_enemy_1000 | emplacements | 1000 | 1 |
| distant_enemy_1000 | decodes | 1000 | 1 |
| garden_army | emplacements | 1000 | 0 |
| garden_army | encodes | 1000 | 0 |
| garden_army | promotion_writes | 3000 | 1000 |
| near_enemy_100 | emplacements | 200 | 0 |
| near_enemy_100 | neighborhoods | 1503 | 263 |
| near_enemy_100 | encodes | 106 | 6 |
| unchanged_saves_100 | encodes | 100 | 0 |
| unchanged_saves_100 | player_writes | 0 | 0 |

Unchanged army synchronization performs zero HP promotion writes; a real Horse-count change still needs two writes per qualifying unit. The distant-movement workload builds coverage once on the first pass and zero times while warm. Unchanged saves perform zero encoding and zero native writes. Timing variation depends on the test host; none of these figures predicts native FPS.

## Completed source checks

| Command | Result |
| --- | --- |
| `python tools/generate_jin.py` | PASS; SQL, text and balance Lua regenerated |
| `python tools/validate_jin.py` | PASS; 16 suite/speed runs, installed schema, source contracts, DDS/localization and viewport geometry |
| `python tools/validate_mod.py` | PASS; full collection and coexistence checks including all 16 Jin runs |
| `python tools/benchmark.py` | PASS; original collection workloads and Jin profiler |
| `python tools/benchmark_jin.py` | PASS; original Jin scenarios and final expanded before/after profiler |
| `python tools/build_mod.py --manifest-only` | PASS; 784 game files, one Jin owner, three additional VFS modules |
| Final Lua syntax / package checks | PASS; Lua 5.1, XML, MD5, project/load order, VFS and decoded DDS |

Release packaging uses `python tools/build_mod.py` followed by `python tools/verify_release.py`; the latter compares every ZIP byte, both archive inventories/CRCs and extracted native/runtime/SQL samples, including the new modules and report. Delivery command logs are retained under ignored `dist/jin-hardening-*`. These checks do not install the mod or certify native gameplay.
