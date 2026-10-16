# Implementation reference — mod version 4, save schema 3

## Load ownership and files

The collection UUID remains `f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392`, distinct from the original collection. Mod version is 4; minimum compatible save version stays 1. SQL loads identities, inherited companions, effects, art and text in numeric order. One InGameUIAddin loads the Workforce XML/Lua. Its guarded `BoundlessCore` includes Citizens, Persistence and Events; Events includes Siege and AI. Every imported basename is unique, including the separation of `BoundlessCitizens.lua` from UI `BoundlessWorkforce.lua`. The package validator checks UUID, version, BNW/CP dependencies and save metadata as well as file contents.

Types use the BC namespace except the descriptive civilization identity; runtime is `MapModData.BoundlessCity`. Event vetoes pass unrelated players. Native DLL/game files and the original collection remain untouched.

| File | Responsibility |
| --- | --- |
| `Lua/BoundlessCore.lua` | IDs, configuration, weighted yields, original-city lookup, ownership/frontier, Registry and expansion |
| `Lua/BoundlessCitizens.lua` | Census, capacity, eligibility/watch indexes, source ledger, reconciliation/trim, summary, cached rows and commands |
| `Lua/BoundlessPersistence.lua` | Nonexecutable native-save codec, validation, migration and mirror |
| `Lua/BoundlessEvents.lua` | One-shot dispatcher, turn/ownership/unit/build hooks, historical city recovery, founding/production guards |
| `Lua/BoundlessSiege.lua` | Native legality, queued military actions, revalidation and protected exclusions |
| `Lua/BoundlessMilitary.lua` | Original-only reclaim, one-time subjugation/native victory, assigned-only improvement development |
| `Lua/BoundlessAI.lua` | Cached build/plot candidates, persistent targets and path-budgeted native missions |
| `UI/BoundlessWorkforce.xml/.lua` | Sixteen-row pages, census/source summaries, mode/priority/direction, siege view and context hiding |
| `SQL/*` | Existing civilization/leader/uniques, inheritance, effects, atlases and English text |
| `Art/*` | Existing 34 DDS files and static diplomacy scene, unchanged |
| `tools/*` | SQL/art/manifest/package builders, source audit, actual-schema validation, simulations and measurements |

## Real population and remote credits

Let P be population, L current native local workers, S building specialists, D native defaults, U genuinely unassigned. Center is free:

```text
L + D + S + U = P
D = remote credited defaults + idle native defaults
L + remote + S + idle + U = P
```

The second form makes unused citizens visible instead of disguising them as assigned. External positive automatons make attribution ambiguous; remote credits become zero until they are removed. Food consumption stays native and population never changes through this mod.

Let M be all owned non-city native local positions, including temporarily blocked/zero-yield/water-locked positions. Let Q be all static specialist slots in currently present buildings, respecting the native per-building cap. A conservative default lower bound after governor allocation is `max(0, P - M - Q)`. Forced defaults verified through local withdrawal provide another bound F. The protected pool is `min(real defaults, max(F, surplus))`: **F and surplus are not additive**.

At P=80, M=30, Q=0, the surplus is 50 and all 50 assignments remain represented by real defaults even if the governor fills all 30 native jobs. At P=40 with 30 jobs, forcing 30 withdrawn citizens supports 30 remote credits, leaving 10 defaults/native jobs. Full population-only reservation still cannot be guaranteed because CP exposes no arbitrary forced-default count setter.

Reconciliation clears this mod's previous source credits, releases only its recorded forced withdrawals with numeric `TASK_REMOVE_SLACKER`, gathers legal candidates and rechecks current native census. Manual takes explicitly selected remote plots; Hybrid prioritizes locks; Auto ignores locks and ranks local/remote candidates together. Local forced jobs are mandatory outside Auto. Specialists remain native. Low-scoring/unselected local workers are withdrawn only as needed. Read-back verifies one ceased local job and one additional default. Credits never exceed the verified protected pool.

The displayed maximum is structural safe citizen capacity, while additional remote capacity also subtracts existing assignments and is capped by eligible unassigned remote inventory. Available citizens exclude native specialists and active locked roles and may include local workers that cannot all become protected remotes. Native allocations still govern remaining local/specialist roles; weighted Auto is a constrained approximation to a complete optimizer.

## Yield sources and failure journal

For every supported yield:

```text
terrain adjustment = sum(evaluated assigned Plot:GetYield)
misc adjustment = -remote count × (database default base + native total type extras / actual defaults)
```

The existing native default source still supplies its own base/extra yields, so compensation cancels only the credited defaults. Modifiers apply through native rates once. Terrain-Culture conversion receives remote Culture, with explicit City:RefreshTourism after Culture source changes/removal. Remote improvement development is adapted once per owner turn; other worked-state effects remain limited. Cached rates are refreshed after terrain changes through a nonzero misc delta or a journalled net-zero pulse; see the source audit for Tourism/cache restrictions.

BCY2 on the capital **plot** stores six misc and six terrain adjustments. BCY1's six old net-misc values are recognized and removed before new-source application. Every completed native mutation writes its new journal immediately. If a native callback raises after changing a source, read-back identifies the completed change and records it before propagating the failure. Cleanup removes only journalled adjustments, preserving unrelated misc and terrain sources. Net-zero pulses are journalled too. An externally malformed journal cannot safely identify its contribution and is reported rather than guessed away.

Reconciliation writes phase RECONCILE and empty credits before mutation. Reconciliation and both trim paths share failure cleanup: remove known contributions, clear assignment/source/scalar caches, record RECOVER/failure and retain withdrawal cleanup information. No new capacity is displayed during recovery. A negative terrain total is rejected before entering the native setter; unannounced source resets/corrupt journals cannot be guessed away and are reported as needing recovery. Save/load rebuilds real assignments without blindly adding another copy. Capture/founding retires old plot markers because native acquisition creates a different city yield object. Capital loss clears its workforce records; returning another city does not clear the capital's records.

## Persistence and rewind

Native Player ScriptData contains `|BCSTATE1:<length>:<encoded table>|`. The envelope name remains compatible, while the table schema is version 3. Sorted-key primitive/table encoding never runs saved code. Validation checks envelope termination, known versions, identity, map keys, table shapes, canonical assignment coordinates and key record fields. Malformed/future payloads remain intact and disable custom operation.

Version 1 migration preserves capital identity, frontier progress/direction, priority/mode, reward bits, last turn and old intent. Old locks become explicit Manual selections, and old reserved counts become forced-withdrawal cleanup records. Schema 2 migrates explicitly to 3 without resetting progress; BCY2 remains unchanged. New optional subjugation, military action/actor identity and development-turn records are validated. Legacy military queues stay demolition-only. Optional return timestamps and siege city IDs are backward-compatible record extensions; legacy return records get one fresh guarded attempt, and legacy siege records retain owner/founding revalidation. No progress is reset. OpenSaveData is a redundant mirror: opening/writing it may fail without aborting a successful native Player ScriptData save. An older native save rewinds state and sources together. Large ScriptData size and native version 1/2 upgrades still need live testing.

## Frontier and scalable events

Initialization scans once per Boundless player, maintaining an owned index through ownership hooks. A breadth-first walk identifies capital-connected land and adjacent unowned frontier; isolated citadel land cannot seed claims. The unchanged expansion formula scores the boundary, claims through native SetOwner and updates frontier entries incrementally, with no radius/tile cap.

`UnitSetXY` uses recorded old/new positions and at most two six-neighbor rings. A plot-to-player index covers remote territory/intent/blocked entries. Friendly/peace movement is filtered; relevant hostile movement rechecks touched eligibility and credited yields. An unchanged native scalar census permits incremental source adjustment instead of scanning all assignments. No changed eligibility/credit means no scheduled reconcile. Rare war/peace and census changes use full validation.

Dirty events coalesce into a single update callback which uninstalls itself before work; there is no idle loop. Owner turns provide fallback reconciliation; end turns always renew reservations because forced-default resets may be opaque. Native event ordering remains unverified. Unit death or unexposed changes recover through subsequent events/turn fallback.

Rows sort/cache by revision and sort key; paging constructs at most sixteen controls. Closed refreshes stop before census/row work. Siege rows also refresh on native city-info dirtiness, so damage/visibility changes need no workforce mutation. Surveyors share candidate/build caches and resource/remote/yield ranking. The 24-candidate checks rotate, units rotate fairly, and all calls share at most 12 native path requests per owner turn. Dead/upgraded/changed-birth targets are pruned, saved build IDs must belong to inherited Surveyor builds, and busy/no-move targets reserve their plots. A failed unit/plot path cools down for three turns; exhausted budget defers rather than loses a valid target. Cooldowns/cursors are ephemeral caches, rebuilt after load. No area/distance cap, teleport or fabricated improvement is used.

Workforce visibility reads current native city-screen/interface mode and the BNW popup/leader contexts. Shown events bind to the native screens visible after the transition; their eventual hidden state retires stale event blockers even without Processed. Visible native contexts still block after an early Processed. Unknown mod popups use event blocking with turn/load/player/context recovery. Context lookups, including absent ones, are cached until those boundaries. Game/city UI dirtiness refreshes the closed launcher. `B.DeferUI` shares the existing single callback with `B.Schedule`, coalesces requests and snapshots before dispatch; ClearUpdate still precedes all work. A transition revision stops older UI callbacks from clearing a newer transition queued during reconciliation. UI-only batches never reconcile gameplay. The render guard resets after errors, and transition-only diagnostics report why the launcher hides. See [UIVisibilityHotfix.md](UIVisibilityHotfix.md) for evidence and native limits.

The summary renderer reads a fresh `B.Summary`/native census and `B.DominationProgress` on existing open-panel refreshes. Fourteen individual statistic labels plus subjugation replace the combined fourteen-argument localization call. Literal pipes are reserved localization form separators and are absent from the new labels and sanitized legacy key. Naturally sized wrapped labels form three vertical stacks; their measured maximum height sets SummaryBody, followed by warnings/yields in a vertical overview scroll area. The viewport ends before the existing action/list controls, so growth stays scrollable. With the capital occupied, current ownership/frontier data remains visible and unavailable census values are labeled instead of retaining stale numbers. No simulation owner, event handler, balance calculation or persistence field was added. See [SummaryDisplayFix.md](SummaryDisplayFix.md).

## Ownership, siege and quarantine

Original identity remains saved coordinates/founding plus native original owner/capital. No replacement activates the UA. Founding/training/buyout/NoCapture and deferred Settler cleanup remain. Boundless's native StaysAliveZeroCities trait preserves a zero-city player only while units remain and elimination rules permit it. Native older-save trait caches can remain stale until ordinary tech/policy refresh; no reward/personality mutation is forced.

Native acquisition has no universal pre-veto. Recovery still chooses historical previous living → original living → native living liberation recipient → native-legal disband → quarantine. Boundless recipients must be empty and regain only their genuine original. Same-turn loop records remain; later legitimate returns can proceed. Quarantine retains resistance/queue/production/remote guards, plus original-only CityCanAcquirePlot and PlayerCanCreateTradeRoute vetoes. Existing routes/resources/Happiness/global building/GPP/city-count effects remain gaps.

Military conditions resolve fresh plot/city/unit identities at queue and deferred execution: living active player, war, visibility, defeat threshold, eligible adjacent melee force. Reclaim additionally requires zero cities and immutable original identity; AcquireCity(true,false) reinstates the native capital outside callbacks, then caches/ledger/workforce rebuild. Subjugation records original civ/founding/coordinates once and grants no ownership/bonus. Only native-legal unprotected targets use Disband. Queued action kinds cannot silently change. Actor birth and native city IDs guard replacement/reuse. Source constraints and native consequences are detailed in [EngineCompletionReport.md](EngineCompletionReport.md).

Optional subjugation Domination checks every ever-alive other-team rival major's native original plot and recorded founding/civ identity. Missing originals block. Boundless must hold only its Heart, Domination must be enabled and no winner/victory can exist. Game.SetWinner uses native completion. Ordinary other-civ conditions stay unchanged. AI shares queued checks at owner turns and deferred adjacent movement/city-dirty events; native tactics remain unverified.

Improvement development operates once per owner turn on eligible assigned remotes, excluding local/native-worked plots. Persisted developmentTurn precedes mutation, rate/threshold/upgrade are native, builder attribution persists and upgraded yields trim/reconcile. This prevents reload duplication and passive owned-tile development, but interrupted updates may skip remaining progress for that turn. [WorkedTileEffects.md](WorkedTileEffects.md) distinguishes adapted effects from missing native worked integration.
