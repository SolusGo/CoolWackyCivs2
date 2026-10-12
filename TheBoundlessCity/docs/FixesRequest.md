# CODEX TASK — THE BOUNDLESS CITY: IMPLEMENTATION FIXES & COMPLETION

**Repository:** https://github.com/SolusGo/CoolWackyCivs2

**Civilization:** The Boundless City

**Target:** Civilization V: Brave New World + Community Patch v151

## OBJECTIVE

Perform a comprehensive implementation review and correction of The Boundless City.

The existing implementation is substantial but has several incomplete mechanics and potential issues.

**Do not redesign the civilization. Do not simplify or remove mechanics. Fix the existing implementation while preserving its intended gameplay.**

The fundamental design is:

> One city. One population. An entire world of land to exploit.

The civilization has one capital throughout the entire game, unlimited potential cultural border expansion, and the ability to assign citizens to tiles at any distance.

The original CoolWackyCivs repository must remain completely untouched.

Work only within CoolWackyCivs2.

---

# PRIORITY 1 — FIX REMOTE WORKFORCE CAPACITY

**Severity: CRITICAL**

Current implementation:

`TheBoundlessCity/Lua/BoundlessCore.lua`

The virtual remote-worker system currently creates reservations by withdrawing citizens from normally worked local plots.

This prevents citizen duplication, but introduces a major limitation.

### Example

Suppose the capital has:

- 80 Population.
- 30 normally workable local plots.
- 500 owned plots.
- 150 improved remote plots.

The current system can potentially reserve only the citizens already working native local plots.

However, the intended design allows the capital to assign its available population across its entire empire.

A population of 80 should be able to allocate up to 80 citizens among local plots, remote plots, and specialists, excluding any non-working population accounting imposed by the engine.

**The number of nearby workable plots must not impose an artificial remote-worker ceiling.**

## Required investigation

Research Community Patch v151's actual citizen-management implementation.

Inspect:

- CvCityCitizens.cpp
- CvCity.cpp
- CvLuaCity.cpp
- Default citizen allocation.
- Specialist assignments.
- Forced-working plot behavior.
- Unassigned citizens.
- Citizen governor behavior.
- Relevant city Lua APIs.

Investigate whether existing default labourers or other legitimately available citizens can safely be reserved for remote work without requiring a previously worked local plot.

A citizen already represented by a legitimate native default labourer may be a potential remote-worker candidate if native accounting can guarantee exclusive assignment.

Do not assume that all default labourers are freely available. Verify their actual semantics.

## Required behavior

Every remote assignment must consume exactly one real citizen.

The following invariant must always hold:

`Local workers + remote workers + native specialists + genuinely unassigned citizens = total assignable population`

Ensure there is no double counting.

Remote workers:

1. Consume ordinary citizen capacity.
2. Remain subject to normal Food consumption.
3. Cannot simultaneously work local plots.
4. Cannot simultaneously occupy native specialist slots.
5. Contribute the evaluated yields of their assigned remote plots.
6. Can be reassigned freely when the underlying citizen capacity permits.
7. Automatically respond to population growth and starvation.
8. Retain correct assignments across save/load.
9. Never artificially increase city population.

### Important

A city with 80 Population and sufficient remote tiles should not be restricted to 30 remote workers merely because its native workable radius contains only 30 tiles.

Investigate safe approaches to achieve the intended behavior without a custom DLL.

If native APIs fundamentally prevent this, implement the most complete verified solution possible and describe the exact remaining restriction.

Never manufacture citizens, use negative citizen counts, or grant free yields.

Correctness and save stability take precedence over pretending the limitation has been solved.

## Yield accounting

Continue supporting:

- Food
- Production
- Gold
- Science
- Culture
- Faith

Audit whether the current `ChangeBaseYieldRateFromMisc` approach accurately handles yield modifiers.

Check for:

- Double-applied modifiers.
- Missing city modifiers.
- Specialist replacement yields.
- Worked-tile-specific effects.
- Golden Age interactions.
- Negative yield deltas.
- Yield recalculation ordering.

Do not accidentally apply the same multiplier twice.

If possible, support additional CP-specific worked-plot effects, while keeping accurate accounting.

Document any effects that cannot be reproduced without DLL access.

---

# PRIORITY 2 — IMPROVE CONQUEST WITHOUT OCCUPATION

**Severity: HIGH**

Current implementation:

`TheBoundlessCity/Lua/BoundlessEvents.lua`

The current civilization-wide NoCapture promotion prevents units from taking enemy cities.

This successfully protects normal one-city gameplay, but creates another problem:

**Enemy cities cannot be removed through ordinary conquest, even when they are legally razable.**

The Boundless City should be capable of military expansion without becoming a multi-city civilization.

## Desired behavior

The civilization must never retain a second city.

However, it should be able to eliminate ordinary enemy settlements through warfare where the game rules legally permit their removal.

### Ordinary enemy cities

Preferred behavior:

1. Reduce the enemy city to the normal capture threshold.
2. Resolve conquest safely.
3. Destroy the city if it is legally razable.
4. Leave the resulting territory available for future border expansion.
5. Never retain an annexed or puppeted second city.

Do not award an entire captured city's tile territory automatically.

The capital must still expand into the cleared territory through normal frontier growth.

### Original capitals and protected cities

Never illegally destroy:

- Original capitals.
- Protected city-state settlements.
- Cities that cannot legally be razed.
- Other settlements protected by CP/game rules.

For protected cities, prefer liberation to an eligible owner where a safe, valid mechanism exists.

Otherwise, block occupation and preserve the original settlement.

## Technical constraints

The current implementation correctly avoids recursive city mutation inside `CityCaptureComplete`.

Preserve that safety principle.

Investigate whether CP v151 provides a pre-acquisition hook, legal capture-resolution API, or safe deferred conquest mechanism.

Do not call `AcquireCity`, city destruction, or razing methods from an unsafe native capture callback.

If safe destruction cannot be achieved without temporarily acquiring the city, prioritize the strict one-city invariant and retain NoCapture for that case.

An alternative civilization-specific siege or demolition action may be appropriate if it can be implemented through verified APIs without breaking protected-city rules.

Ensure:

- No infinite capture loops.
- No repeated conquest rewards.
- No illegal capital destruction.
- No dangling city references.
- No duplicate cities after loading.
- No unintended changes to other civilizations' conquest mechanics.

Do not claim that automatic destruction is supported unless it is actually implemented and verified.

---

# PRIORITY 3 — STRENGTHEN STRICT ONE-CITY ENFORCEMENT

**Severity: HIGH**

Investigate:

`BoundlessEvents.lua — RecoverCities`

The current recovery process attempts to return unexpected additional cities to another civilization.

However, if their previous and original owners are unavailable, it can select an arbitrary living civilization.

This can create bizarre outcomes.

For example, a city in Europe might suddenly become owned by an unrelated civilization on another continent.

## Required changes

Replace arbitrary recipient selection with a deterministic, logically defensible recovery policy.

Preferred order:

1. Previous legal living owner.
2. Original legal living owner.
3. Valid liberation recipient.
4. Another explicitly justified native resolution.

Do not give a settlement to an unrelated player solely because that player is alive.

If no safe legal recipient exists, use the safest supported fallback and clearly disclose any unavoidable temporary ownership limitation.

Also audit every possible path to acquiring an extra city:

- Normal founding.
- Settler gifts.
- Script-created Settlers.
- City capture.
- Diplomatic transfers.
- Peace treaties.
- City-state transfers.
- Modded abilities.
- Capital loss and recapture.
- Save/load recovery.
- Ownership-changing effects from other civilizations.

The capital must retain its original identity.

A replacement capital or accidental second settlement must not activate the Unique Ability.

Preserve the initial Settler so the civilization can found its original city normally.

---

# PRIORITY 4 — FIX WORKFORCE UI ACCURACY

Files:

- `TheBoundlessCity/UI/BoundlessWorkforce.lua`
- `TheBoundlessCity/UI/BoundlessWorkforce.xml`
- `TheBoundlessCity/Lua/BoundlessCore.lua`

The current UI reports available reservations using the count of local workers.

This may not equal the number of remote assignments that are actually possible.

## Required changes

Report accurate figures for:

- Total Population.
- Local workers.
- Remote workers.
- Native specialists.
- Available citizens.
- Available remote-worker capacity.
- Pending remote assignments.
- Locked assignments.
- Total remote yield contribution.

Distinguish between:

**Available citizens:** Citizens not committed to mandatory or locked roles, as defined by the verified accounting model.

**Available remote capacity:** Additional citizens that can genuinely be allocated to remote assignments through the implemented reservation system.

These values may differ if unavoidable native limitations remain.

Do not display an optimistic capacity that the assignment engine cannot fulfill.

## Manual and automatic assignment

Audit all three modes.

**Automatic:** Choose the most useful available plots according to the selected yield priorities.

**Manual:** Only remotely work explicitly selected plots.

**Hybrid:** Respect manual locks and automatically allocate remaining available workers.

Prevent:

- Duplicate assignments.
- Ghost assignments.
- Incorrect lock states.
- Yield contributions from lost territory.
- UI counters becoming stale.
- Assignments exceeding population.
- Stuck pending assignments after capacity becomes available.

Retain pagination, sorting, plot-location controls, and directional expansion preferences.

Do not introduce unnecessary UI polling.

---

# PRIORITY 5 — PERFORMANCE OPTIMIZATION

**Severity: MEDIUM**

This civilization may eventually own thousands of plots.

Huge maps with many civilizations must remain practical.

## Unit movement event

Inspect the `UnitSetXY` handler.

Currently, unit movement can cause remote workforce assignments to be checked repeatedly.

Investigate replacing this with:

- Plot-indexed assignment lookup.
- Spatial indexing.
- Cached nearby assignments.
- Relevant-player filtering.
- Event coalescing.
- Other scalable approaches.

Do not iterate over every remote assignment for every unit movement if the same result can be achieved more efficiently.

## AI Surveyor behavior

The AI Worker planner currently examines owned plots and possible builds.

Optimize candidate selection and caching.

Prioritize plots with:

- Valuable resources.
- Strong yields.
- Existing remote assignments.
- Relevant strategic value.
- Reachable paths.

Avoid repeatedly scanning every owned plot and every available build for every Surveyor.

Preserve real pathfinding and legal build checks.

Do not teleport units or fabricate improvements.

## Border expansion

Keep the existing cached-frontier approach.

Verify that large territory claims remain efficient when a city owns 100, 500, 1,000, or more plots.

Do not introduce a maximum radius or tile cap as a performance shortcut.

## UI

No recurring 0.1-second polling.

Refresh only when necessary.

Avoid expensive world-map scans merely because the panel is open.

Preserve reasonable FPS when the panel is closed.

---

# PRIORITY 6 — SAVE/LOAD AND EVENT SAFETY

Audit:

- `BoundlessPersistence.lua`
- `BoundlessCore.lua`
- `BoundlessEvents.lua`

Pay special attention to partial workforce reconciliation.

A save or load must not create:

- Duplicate yield bonuses.
- Negative citizen capacity.
- Unreserved remote assignments.
- Lost Culture progress.
- Repeated Surveyor rewards.
- Orphaned remote-worker assignments.
- Incorrect territory ownership.
- Corrupt ScriptData.
- Stale native city references.

Audit `B.Reconcile`, `B.Trim`, `B.ApplyLedger`, and `B.Save`.

Verify that removing previous miscellaneous yield contributions and reapplying them cannot accidentally remove unrelated yield sources.

Investigate whether native citizen-governor actions occurring between callbacks can invalidate the saved workforce state.

Ensure recovery is deterministic and idempotent.

Preserve existing save compatibility where possible.

If state migration is required, implement explicit versioned migration rather than silently resetting the civilization's progress.

---

# PRIORITY 7 — CP V151 COMPATIBILITY AUDIT

Verify every relevant API against actual Community Patch v151 sources.

Do not rely on newer Vox Populi APIs unless they are present in the target CP build.

Inspect:

- Event names.
- Event signatures.
- City task methods.
- Plot ownership setters.
- Worker build events.
- Unit conversion events.
- City capture behavior.
- Specialist methods.
- ScriptData persistence.
- Yield calculation.

Review the SQL, Lua and UI registration.

Confirm that the separate CoolWackyCivs2 mod can coexist with CoolWackyCivs1.

Preserve unique namespaces and database identifiers.

Do not modify shared CP source or the base game's global mechanics.

---

# PRIORITY 8 — ACTUAL VERIFICATION

Update the test suite with new cases.

Existing simulation tests are useful but must not be treated as proof of native game compatibility.

## Workforce stress tests

Test:

- Population 10 / 30 owned tiles.
- Population 40 / 150 owned tiles.
- Population 80 / 500 owned tiles.
- Population 150 / 1,000 owned tiles.

For each case verify that remote capacity is not inadvertently limited by the native working radius.

Test population changes, specialists, pillaging, changing improvements, and loading older saves.

## Conquest tests

Test normal razable cities, original capitals, city-states, non-razable cities, and unexpected diplomatic transfers.

Verify the strict one-city rule and protected-city safety.

## Border growth

Verify expansion beyond five, ten, twenty, and thirty hexes.

Verify adjacent claims across water and on wrapped maps.

Ensure unworked tiles grant no automatic worker yields.

## Performance

Benchmark:

- Remote assignment changes.
- Full workforce reconciliation.
- Unit movement event processing.
- AI Surveyor planning.
- Expansion with 1,000+ owned tiles.
- UI refresh with hundreds of remote plots.

Record real execution measurements when possible.

If native Civ V cannot be launched from the current environment, state that explicitly and provide detailed live-game test instructions.

Do not fabricate test results.

---

# PRIORITY 9 — PRESERVE EXISTING CONTENT

Do not remove or redesign:

- The World Is One City.
- Unlimited cultural border expansion.
- Unlimited-distance remote working.
- The Grand Registry.
- Frontier Surveyor.
- Frontier Surveyor Culture rewards.
- Automatic/Manual/Hybrid workforce modes.
- Border direction preferences.
- One-city restrictions.
- Existing art.
- Civilopedia content.
- Leader personality.
- AI support.
- Save persistence.
- Existing localization.

Do not replace remote working with a flat per-tile or per-population yield bonus.

Do not simply increase the native working radius to a finite number.

Do not introduce a second settlement, puppet, administrative city, or hidden city as a substitute for the original capital.

Numerical balance changes are acceptable where necessary, but explain them.

Preserve the existing civilization's identity and mechanics.

---

# FINAL DELIVERABLES

Implement all safe, technically feasible fixes directly in the repository.

Update documentation and changelogs.

Provide a final report containing:

1. Confirmed bugs discovered.
2. Root cause of each bug.
3. Exact files changed.
4. Fixes implemented.
5. Remote workforce population-accounting explanation.
6. Conquest and one-city enforcement explanation.
7. AI/performance improvements.
8. Save compatibility changes.
9. Automated test results.
10. Remaining CP engine limitations.
11. Required in-game verification steps.

Do not mark a feature fixed solely because tests using mocked APIs pass.

Where a requirement is impossible with the available CP v151 Lua interfaces, identify the exact native limitation and preserve stable gameplay instead of implementing unsafe workarounds.

**Priority order:**

1. Citizen-accounting correctness.
2. True population-based workforce availability.
3. Strict one-city preservation.
4. Safe conquest behavior.
5. Save/load correctness.
6. Performance.
7. UI accuracy and usability.
8. AI improvements.

## FINAL DESIGN PRINCIPLE

The Boundless City should become extraordinarily powerful by developing a single population center with access to a potentially unlimited amount of land.

Its strength should come from choosing and improving valuable tiles across vast distances.

Its weaknesses should remain those of a true one-city civilization: one production queue, one capital, one concentrated population, and the military challenge of protecting distant territory.

Do not compromise those strengths or weaknesses.

**One city. No puppets. No annexation. No second settlement. Unlimited territorial ambition.**

Implement the fixes now, validate everything possible, and document any remaining engine-level restrictions precisely.
