# Implementation reference — version 2

## Load ownership and files

The collection UUID remains `f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392`, distinct from the original collection. Mod version is 2; minimum compatible save version stays 1. SQL loads identities, inherited companions, effects, art and text in numeric order. One InGameUIAddin loads the Workforce XML/Lua. Its guarded `BoundlessCore` includes Citizens, Persistence and Events; Events includes Siege and AI. Every imported basename is unique, including the separation of `BoundlessCitizens.lua` from UI `BoundlessWorkforce.lua`.

Types use the BC namespace except the descriptive civilization identity; runtime is `MapModData.BoundlessCity`. Event vetoes pass unrelated players. Native DLL/game files and the original collection remain untouched.

| File | Responsibility |
| --- | --- |
| `Lua/BoundlessCore.lua` | IDs, configuration, weighted yields, original-city lookup, ownership/frontier, Registry and expansion |
| `Lua/BoundlessCitizens.lua` | Census, capacity, eligibility/watch indexes, source ledger, reconciliation/trim, summary, cached rows and commands |
| `Lua/BoundlessPersistence.lua` | Nonexecutable native-save codec, validation, migration and mirror |
| `Lua/BoundlessEvents.lua` | One-shot dispatcher, turn/ownership/unit/build hooks, historical city recovery, founding/production guards |
| `Lua/BoundlessSiege.lua` | Native legality, queued demolition, revalidation and protected exclusions |
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

The existing native default source still supplies its own base/extra yields, so compensation cancels only the credited defaults. Modifiers apply through native rates once. Terrain-Culture conversion receives remote Culture; other worked-state effects are not simulated. Cached rates are refreshed after terrain changes through a nonzero misc delta or a journalled net-zero pulse; see the source audit for Tourism/cache restrictions.

BCY2 on the capital **plot** stores six misc and six terrain adjustments. BCY1's six old net-misc values are recognized and removed before new-source application. Every completed native mutation writes its new journal immediately. If a native callback raises after changing a source, read-back identifies the completed change and records it before propagating the failure. Cleanup removes only journalled adjustments, preserving unrelated misc and terrain sources. Net-zero pulses are journalled too. An externally malformed journal cannot safely identify its contribution and is reported rather than guessed away.

Reconciliation writes phase RECONCILE and empty credits before mutation. A failed operation clears known source credits, records RECOVER/failure, and retains withdrawn cleanup information. Save/load starts by clearing verified old credits and rebuilding real assignments; it does not blindly add another copy. Capture/founding retires old plot markers because native acquisition creates a different city yield object. Capital loss clears its workforce records; returning another city does not clear the capital's records.

## Persistence and rewind

Native Player ScriptData contains `|BCSTATE1:<length>:<encoded table>|`. The envelope name remains compatible, while the table schema is version 2. Sorted-key primitive/table encoding never runs saved code. Validation checks envelope termination, known versions, identity, map keys, table shapes, canonical assignment coordinates and key record fields. Malformed/future payloads remain intact and disable custom operation.

Version 1 migration preserves capital identity, frontier progress/direction, priority/mode, reward bits, last turn and old intent. Old locks become explicit Manual selections, and old reserved counts become forced-withdrawal cleanup records. New return/siege/AI records have safe empty defaults. OpenSaveData receives a mirror but is never authoritative: loading an older native save must rewind custom progress and native yield sources together. Large ScriptData size needs native late-game testing.

## Frontier and scalable events

Initialization scans once per Boundless player, maintaining an owned index through ownership hooks. A breadth-first walk identifies capital-connected land and adjacent unowned frontier; isolated citadel land cannot seed claims. The unchanged expansion formula scores the boundary, claims through native SetOwner and updates frontier entries incrementally, with no radius/tile cap.

`UnitSetXY` uses recorded old/new positions and at most two six-neighbor rings. A plot-to-player index covers remote territory/intent/blocked entries. Friendly/peace movement is filtered; relevant hostile movement rechecks touched eligibility and credited yields. An unchanged native scalar census permits incremental source adjustment instead of scanning all assignments. No changed eligibility/credit means no scheduled reconcile. Rare war/peace and census changes use full validation.

Dirty events coalesce into a single update callback which uninstalls itself before work; there is no idle loop. Owner turns provide fallback reconciliation; end turns always renew reservations because forced-default resets may be opaque. Native event ordering remains unverified. Unit death or unexposed changes recover through subsequent events/turn fallback.

Rows sort/cache by revision and sort key; paging constructs at most sixteen controls. Closed refreshes stop before census/row work. Surveyors share eligible candidate/build caches, resource/remote/yield ranking, rotating 24-candidate checks and at most 12 native path requests per pass. Existing targets use unit ID plus creation turn, with native CanBuild/path revalidation. Busy units keep orders; no area/distance cap, teleport or fabricated improvement is used.

## Ownership, siege and quarantine

Original capital identity is immutable coordinates/founding turn, recognized initially only from the player's native original capital. No replacement city activates the UA. Founding/training/buyout/NoCapture prevent normal additional-city paths; gifted/scripted Settlers are cleaned on turns. Production gates apply only to the original city.

Unexpected cities are processed outside capture callbacks: previous living legal owner, original living legal owner, then native-identified living liberation recipient. A saved recipient/founding identity suppresses return loops. Native-legal extras without a recipient can be disbanded and their associated plots released; protected or own-founded extras have queues/automation cleared and remain quarantined. This is not an absolute guarantee against arbitrary external acquisition.

Siege demolition validates war, visibility, 1 HP, adjacent melee moves, protected exclusions and current-owner CanRaze, then queues coordinates/founding identity. Execution rechecks legality and consumes remaining unit moves before native Disband. A rare map scan records that city's acquired plots for release; opening the siege panel never scans the world. No territory or capture rewards are granted to Boundless. First-founded enemy settlements generally fail native CanRaze and remain capture-blocked. Do not hold stale native references across city destruction.
