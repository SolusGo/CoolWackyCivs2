# Implementation reference

## Ownership and load order

The collection has mod UUID `f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392`. SQL loads in numeric order: core identities, inherited companions, unique effects, art atlases, localization. One `InGameUIAddin` loads `BoundlessWorkforce.xml`; its Lua includes `BoundlessCore`, which includes persistence and event modules. The load guard prevents duplicate gameplay owners. Included Lua and art import into the VFS; database SQL and UI entry XML do not.

All civilization-specific types use the `BC_` prefix except the descriptive `CIVILIZATION_BOUNDLESS_CITY` identity. Runtime state resides in `MapModData.BoundlessCity`. No other civilization is intentionally enrolled, and event vetoes return true for unrelated players. The new collection does not modify the old collection's files or core DLL.

## Frontier state and complexity

Initialization scans the map once per Boundless player to index its plots. `TileOwnershipChanged` maintains that index. A breadth-first walk over owned territory identifies the capital-connected component and adjacent unowned frontier. Custom expansion can only seed from that component; a disconnected citadel tile cannot seed additional claims. Ordinary engine border changes remain native and enter the same ownership cache.

Frontier selection scores the cached boundary rather than rescanning the map. Each successful `SetOwner` updates owned count, connected membership and adjacent frontier entries incrementally. Only an ownership change outside the current expansion batch requires a fresh component walk. Culture thresholds depend on owned count, speed and era. There is no coordinate-distance rejection or claim counter cap.

Ownership rebuild is O(owned plots); candidate sorting is O(owned plots × log owned plots); native accounting checks operate over the native city plot list and selected assignments. A turn that makes several claims scores the boundary for each claim. Artificially injecting millions of Culture can perform many claims in one action; normal costs/culture output constrain that work without a gameplay radius/count cap.

## Citizen and yield invariants

The relevant native census is:

```text
local tile workers + default labourers + building specialists = population
remote credited plots <= native reserved labourers
```

The city center is free and excluded from the worker census. Remote reservations do not alter population or food consumption. `AlterWorkingPlot` removes a local tile worker and creates one forced default labourer. The read-back check requires the plot to stop working and the default count to rise by exactly one before a remote assignment is accepted. If no safe native worker remains, additional locks stay pending.

For each of six yield types:

```text
remoteMiscContribution = sum(assigned remote GetYield)
                         - remoteCount × current GetSpecialistYield(default)
```

Native labourer production remains in the native specialist yield source, and the subtraction compensates for it. Local tile production has already been removed. The engine applies ordinary city/global modifiers after these base sources are combined; the mod does not repeat those modifiers or manually deposit Food/Production into storage.

The miscellaneous delta is stored as `|BCY1:v1,v2,...,v6|` in the capital plot's ScriptData, using the verified Plot bindings. City ScriptData methods are not assumed. Reconciliation first removes its own previous delta, releases its own reservations through `TASK_REMOVE_SLACKER`, and builds a new validated assignment set. It then applies only the new delta and updates the ledger. Other ScriptData and other miscellaneous yield contributions are retained. Native acquisition rebuilds city yield sources but leaves plot ScriptData intact; the capture hook retires the old-object ledger marker without subtracting a nonexistent contribution from the new city.

Dirty callbacks synchronously trim assignments against current ownership, valid plot state, native defaults and population. Trimming removes credits without adding workers. Full reallocation runs in a one-shot deferred callback. A post-reconcile signature checks mode, priority, direction, population, specialists, native work/lock state, owned count, assigned yields and current labourer yields. An unchanged dirty event does not release/recreate citizens, preventing a self-sustaining frame-update loop.

Auto management ranks local/remote plots together, subtracts native building specialists from capacity, and reserves only selected remote plots. It leaves the remaining local citizens with native city management; it is a deterministic approximation to a complete city/specialist optimizer. Manual requests and exclusions are validated again at execution. The original population-only unbounded reservation requirement is not achieved; see the limitations document.

## Persistence and save rewind

The authoritative player record is length-prefixed, nonexecutable data in native Player ScriptData:

```text
|BCSTATE1:<payload length>:<encoded table>|
```

The serializer encodes primitive values and sorted-key tables without `loadstring`. The record carries schema version, player identity, original capital identity, frontier progress/direction, mode/priority, assignments/locks/exclusions, Surveyor rewards, last processed turn and exceptional-city quarantine records. Index keys are validated against the loaded map; capital ownership and founding identity are resolved from current native objects. Unknown/corrupt schemas disable custom operation instead of resetting rewards.

`Modding.OpenSaveData` receives a redundant player snapshot. It is not used to overwrite native state on load: loading an older save must rewind the custom payload and its native yield ledger together. Unrelated player ScriptData is preserved. This avoids guessing whether a store mirror represents the same native save. A large late-game map can produce a large ScriptData record; native save size/performance should be measured during live testing.

## City transfers and defeat

Native `NoCapture` prevents normal military acquisitions. Founding/training guards are active before a new capital exists, while the engine-granted first Settler remains usable. Later scripted Settlers are cleaned up on owner turns. City-state buyouts are vetoed. Units gained by creation/conversion receive the promotion; foreign recipients have it stripped.

`CityCaptureComplete` records/schedules recovery and never deletes or retransfers its city object. Deferred recovery re-resolves coordinates, excludes the original capital, chooses an eligible living recipient and calls native `AcquireCity`. No recipient means explicit quarantine with production/training vetoes. These protections reduce normal loopholes but do not provide an absolute pre-acquisition veto against arbitrary other mods.

Loss of the original capital leaves no valid city for frontier or workforce operation. The old city object is destroyed/recreated by native acquisition; custom Lua does not keep stale references or create a new capital. Reclaiming the original coordinates/founding identity can restore operation when the native data matches. Reclaim and capital-loss yield cleanup remain native test items.

## AI and art

The AI uses the same border/reservation code and changes scoring priority for growth and defense. Idle Surveyors choose legal improvement targets in their current land area and use native movement/build missions. Later native AI can affect those missions; cross-area worker development and complete AI quality are unverified.

Art is original to this implementation. One generated illustration supplies the Dawn, static 2D diplomacy scene, fictional map vignette and leader crop. Code-drawn arch/infinity, Registry and surveying-compass insignia provide civilization/alpha/UU/UB/flag atlases. Thirty-four legacy uncompressed RGBA DDS textures are included; there are no missing art references or custom sounds. The Surveyor uses the active Worker's standard model.

## File inventory

| File/directory | Role |
| --- | --- |
| `SQL/00_BC_Core.sql` | Identities, replacements, starting data and event options |
| `SQL/01_BC_Inheritance.sql` | Schema-derived native companion inheritance |
| `SQL/02_BC_Effects.sql` | Registry Culture bits and leader flavors |
| `SQL/03_BC_Art.sql`, `10_BC_Text.sql` | Complete atlas and English text registration |
| `Lua/BoundlessCore.lua` | Frontier, scoring, accounting, ledgers, public commands |
| `Lua/BoundlessPersistence.lua` | Native-save codec and state validation |
| `Lua/BoundlessEvents.lua` | Deferred dispatcher, guard hooks, Surveyor rewards, AI missions |
| `UI/BoundlessWorkforce.xml`, `.lua` | Event-driven world-map panel |
| `Art/*` | 34 DDS files and diplomacy scene |
| Root project/solution/modinfo | Collection integration |
| `tools/*` | Build, SQL/art generation, actual-schema checks, Lua/UI simulations and benchmark |

Documentation, generated source art, collection/civ changelogs and the dedicated civ page are outside the game's gameplay file list. The builder includes Markdown guides in the release archives. `Benchmark.json` is a source-repository microbenchmark result, not gameplay content.
