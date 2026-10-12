# CODEX TASK — THE BOUNDLESS CITY: OVERCOMING THE FINAL ENGINE LIMITATIONS

**Repository:** https://github.com/SolusGo/CoolWackyCivs2

**Civilization:** The Boundless City — The First Architect

**Last reviewed commit:** `7f88eaeb349f3bddf0027017f3983d7c8d8b1ea7`

**Target:** Civilization V: Brave New World + Community Patch v151.

## OBJECTIVE

The Boundless City is now a substantial implementation, but six gameplay limitations remain.

This task is to investigate each limitation against the actual CP v151 DLL source, identify which can be overcome safely through Lua, SQL, XML, and existing engine APIs, and implement genuine solutions wherever possible.

**IMPORTANT: This is not another documentation-only audit.**

Actively search for solutions and implement them when technically safe.

However, do not introduce unsafe native operations, duplicate citizens, invalid ownership states, or global rule changes merely to satisfy the requirements.

The civilization's identity must remain:

**ONE CITY. ONE POPULATION. UNLIMITED TERRITORIAL AMBITION.**

Read the existing implementation and stability reports before making changes.

Do not modify CoolWackyCivs1 or replace the Community Patch DLL.

---

# LIMITATION 1 — ORIGINAL CAPITAL RECAPTURE

**Priority: CRITICAL**

## Current problem

All Boundless military units receive the `PROMOTION_BC_NO_CAPTURE` promotion.

This prevents them from occupying enemy settlements.

Unfortunately, it also prevents The Boundless City from capturing its own original capital after losing it.

We need a distinction between capturing a foreign settlement and **reclaiming The Heart of the World**.

## Required behavior

The Boundless City should be able to recapture its original capital through normal military action when it remains an eligible, living civilization.

Requirements:

1. Identify the genuine original capital using its recorded coordinates, founding identity, original ownership and native capital status.
2. Allow its recapture under appropriate conditions.
3. Never allow this exception to capture an unrelated settlement.
4. Never allow the civilization to retain a second city.
5. Restore the existing Unique Ability and associated UI after successful recapture.
6. Restore valid frontier expansion and remote workforce operation.
7. Prevent duplicate yield contributions or stale city references.
8. Preserve saved territorial progress and workforce preferences where appropriate.
9. Ensure no foreign capital can masquerade as the original capital.
10. Preserve all existing safeguards for normal foreign-city conquest.

## Investigate

Examine the CP v151 implementations of:

- Unit city capture permissions.
- NoCapture promotions.
- Unit promotion changes before combat.
- `CanMoveInto` and related movement/capture events.
- `AcquireCity` and its capture callbacks.
- Original-capital ownership and liberation.
- Player elimination and revival.

### Critical edge case: player elimination

Under normal Civ V rules, losing your only city can immediately eliminate the player.

Determine whether a genuine military recapture remains possible after losing the capital.

If elimination is immediate, distinguish two cases:

**Case A — Boundless remains alive:** Implement a safe original-capital recapture path.

**Case B — Boundless has already been eliminated:** Do not pretend military recapture remains available. Investigate whether an engine-supported, civilization-scoped survival or restoration path exists without creating another city or changing global elimination rules.

Do not fabricate extra cities, hidden capitals or dummy settlements to keep the civilization alive.

If full recovery is impossible, implement the most useful safe partial solution and disclose the unavoidable elimination limitation.

---

# LIMITATION 2 — GENERAL ENEMY CITY DEMOLITION

**Priority: CRITICAL**

Relevant file:

`TheBoundlessCity/Lua/BoundlessSiege.lua`

## Current problem

The existing siege mechanic only works where the current city owner passes the native `CanRaze` check.

This generally prevents demolition of enemy cities founded by their current owner.

Consequently, ordinary enemy settlements can become permanent obstacles to The Boundless City's territorial expansion.

We want genuine military conquest without permanent occupation.

## Desired mechanic: Conquest Without Occupation

When The Boundless City defeats an ordinary, legally destructible enemy settlement, it should be able to demolish the settlement without annexing or puppeting it.

Proposed sequence:

1. Reduce the enemy city to its defeat threshold.
2. Require an eligible adjacent melee unit with remaining movement.
3. Offer a demolition action.
4. Revalidate city identity, ownership, military conditions and destruction legality.
5. Resolve demolition outside unsafe combat/capture callbacks.
6. Destroy the settlement safely.
7. Consume the acting unit's movement.
8. Release territory as appropriate under native ownership rules.
9. Preserve enemy units and other game objects according to native cleanup rules.
10. Never award the Boundless City a second city or captured territory automatically.

## Research requirements

Inspect the exact CP v151 native code for:

- `CvPlayer::CanRaze`.
- `CvPlayer::Disband`.
- City destruction and `kill`.
- Native razing rules.
- Protected-city checks.
- Game-option restrictions.
- City-state and original-capital restrictions.
- Unique luxury protections.
- Lua vetoes.
- City capture and liberation hooks.

**Distinguish ownership-based API restrictions from genuine game-rule protection.**

For example, `CanRaze` rejecting a city because the caller does not own it does not automatically prove the city is intrinsically protected from demolition.

However, do not simply bypass `CanRaze` and call `Disband` without independently verifying every necessary protection and cleanup condition.

## Protected settlements

Never illegally destroy:

- Original capitals.
- Protected city-state cities.
- Holy cities.
- Settlements protected by game options.
- Settlements protected by CP-specific rules or applicable Lua vetoes.
- Any city whose safe native destruction cannot be established.

If an independent, complete destruction-permission check is impossible without changing the DLL, retain the protected behavior.

Investigate an alternative non-destructive military resolution for cities that cannot be removed.

Potentially allow a one-time **Subjugation** or **Siege Victory** action that acknowledges military defeat without transferring city ownership, provided it cannot farm rewards or violate other game systems.

Preserve NoCapture where necessary.

## AI and UI

The siege UI must clearly distinguish:

- Ready for demolition.
- Insufficient damage.
- No eligible melee unit.
- Protected capital.
- Protected city-state.
- Native destruction restriction.
- Already queued.
- Temporarily unavailable.

AI Boundless players should understand and use the same mechanics.

No repeatable demolition rewards.

---

# LIMITATION 3 — TRUE POPULATION-BASED REMOTE WORKING

**Priority: HIGH**

Relevant file:

`TheBoundlessCity/Lua/BoundlessCitizens.lua`

## Current problem

The virtual remote workforce uses real native default labourers, including verified local worker withdrawals and conservative population surplus.

This successfully avoids free citizens, but it does not always allow all available non-specialist citizens to be assigned to remote plots.

Current mock scenarios include:

| Population | Native local positions | Remote assignments |
|---|---|---|
| 40 | 30 | 30 |
| 80 | 30 | 50 |
| 150 | 30 | 120 |

The remaining capacity limitation is structural.

## Desired result

A population-80 city with sufficient eligible territory should be able to assign all 80 available non-specialist citizens across local and remote plots.

The native city center remains free.

Every other worked plot consumes exactly one real citizen.

No free yields are permitted.

## Required technical investigation

Study the exact CP v151 implementation of:

- `CvCityCitizens`.
- Default labourer assignment.
- Forced default specialists.
- Unassigned citizen accounting.
- Native city governor behavior.
- Citizen automation.
- Specialist reassignment.
- Population changes.
- `DoTask`.
- `AlterWorkingPlot`.
- Citizen-related Lua bindings.

Investigate whether additional existing APIs or safe combinations of native operations can achieve greater remote workforce capacity.

Do not revisit already disproven approaches unless new evidence establishes their safety.

Specifically avoid:

- Negative automatons.
- Fabricated specialist counts.
- Population inflation.
- Hidden cities.
- Unlimited dummy buildings.
- Unsupported Lua setters.
- Crediting remote yields without consuming real citizens.

## Acceptance criteria

The following relationship must remain correct:

`Local workers + remote workers + building specialists + idle population + genuinely unassigned citizens = ordinary population`

Handle native automatons separately and accurately.

Ensure remote workers cannot simultaneously be assigned elsewhere.

All six currently supported yield types must remain correct.

Maintain normal Food consumption and population growth.

### If full population-based allocation remains impossible

Retain the current safe implementation.

But provide exact proof of the missing native capability and identify the minimum DLL/API extension that would be needed.

Do not repeatedly redesign working citizen code without improving the result.

---

# LIMITATION 4 — NATIVE WORKED-TILE EFFECTS

**Priority: HIGH**

## Current problem

Remote tiles are evaluated using `Plot:GetYield` and their yields are credited virtually.

But the game does not consider them truly worked through its native city citizen arrays.

Consequently, some effects may not trigger.

These include:

- Worked-improvement counters.
- Worked-tile-specific yields and effects.
- Certain Tourism interactions.
- Conditional policies and traits.
- Improvement development.
- Modded effects that check native worked status.

## Required investigation

Audit CP v151 for gameplay behaviors depending specifically on a tile being worked.

Categorize effects into:

1. Already reproduced correctly by the virtual yield system.
2. Reproducible through additional Lua event handlers.
3. Reproducible through safe dummy buildings or promotions.
4. Requires native city-worker integration.
5. Impossible to reproduce fully without a DLL change.

Implement the most important missing compatible effects where safe.

Avoid double-counting when existing plot yields already include an effect.

For any supported adaptation, ensure that:

- One remotely assigned plot counts once.
- Removing the worker removes the effect.
- Population loss removes invalid contributions.
- Save/load restores the correct state.
- Other civilizations are unaffected.

Do not add passive yields from all owned territory.

If necessary, define a clear distinction between actual native worked plots and virtual remotely worked plots in documentation and UI.

---

# LIMITATION 5 — ABSOLUTE ONE-CITY ENFORCEMENT

**Priority: HIGH**

## Current problem

Ordinary settlement founding, annexation, puppeting and military capture are blocked.

However, externally scripted transfers can still produce an additional city temporarily.

Protected orphan settlements may remain quarantined if no legal recipient exists.

The current quarantine implementation is significantly improved, including resistance and production restrictions.

But absolute one-city ownership is not guaranteed.

## Required behavior

The Boundless City must never intentionally benefit from additional cities.

Investigate stronger safe protections against:

- Scripted city transfers.
- Diplomatic city gifts.
- Peace treaty settlements.
- City-state ownership changes.
- Special civilization abilities.
- Capital exchanges.
- Transfer chains involving eliminated civilizations.

## Improvements to consider

Investigate any CP-supported pre-acquisition veto that could reject unwanted transfers before native ownership changes.

If no such veto exists, improve deferred resolution.

Preserve the following recipient policy:

1. Valid previous living owner.
2. Valid original living owner.
3. Valid native liberation recipient.
4. Native-legal demolition where applicable.
5. Quarantine when no safe resolution exists.

Never hand a city to an unrelated civilization arbitrarily.

## Quarantine restrictions

A quarantined extra city should not provide exploitable:

- Production.
- Purchases.
- Specialist yields.
- Unintended territory-based remote assignments.
- City-specific military production.
- Repeatable bonuses.

Investigate whether empire-level effects such as strategic resources, Happiness, trade routes, buildings and city count can also be suppressed safely.

If any cannot, document those specific gaps.

Do not attempt unsafe city deletion merely to force the owned-city counter back to one.

---

# LIMITATION 6 — DOMINATION VICTORY

**Priority: MEDIUM**

## Current problem

Standard Civ V Domination Victory generally requires ownership of foreign original capitals.

The Boundless City cannot own any foreign city, so standard Domination is inaccessible.

This is understandable, but creates an interesting design opportunity.

## Investigate: Boundless Domination

Could this civilization earn a special domination victory through defeating enemy original capitals without permanently owning them?

### Proposed concept — The World Bends Before One City

Each foreign original capital can be militarily subjugated once.

The action must:

- Require genuine military supremacy.
- Be impossible to perform against friendly cities.
- Require appropriate war and siege conditions.
- Record the original capital and original civilization identity.
- Persist across saves.
- Prevent repeated progress from attacking the same capital.
- Handle liberated or transferred capitals correctly.

When every relevant rival original capital has been legitimately subjugated, investigate whether the Boundless player can receive a Domination Victory through an available native victory API.

**Critical restriction:** Do not change the victory conditions for other civilizations.

This must be strictly civilization-specific.

Do not change global ownership of capitals merely to trigger a victory.

If CP v151 cannot support this safely, leave Domination unavailable and explicitly document the limitation.

Do not force a custom victory system if it would disrupt the game's normal victory manager.

---

# PRIORITY 7 — SAFETY AND SAVE COMPATIBILITY

Preserve all existing improvements from mod versions 1–3.

In particular:

- Border expansion without a radius cap.
- Culture accumulator.
- Territory ownership caching.
- The Grand Registry.
- Frontier Surveyors.
- One-time Culture rewards.
- Workforce assignment modes.
- Workforce ledger journalling.
- Signed yield compensation.
- Yield refresh handling.
- Safe failure recovery.
- AI Worker improvements.
- Siege identity checks.
- Quarantine restrictions.
- Native-save persistence.
- Source-verified CP v151 APIs.

Do not change gameplay balance or existing numerical bonuses unless required to correct a bug.

Ensure existing saves migrate explicitly if the persisted schema changes.

Preserve original capital identity, Culture progress, territory, Surveyor rewards, and remote workforce selections.

No stale city references or duplicate yield contributions.

---

# PRIORITY 8 — REGRESSION TESTS

Expand the test suite.

## Test A — Capital recapture

Lose The Heart of the World to an enemy.

Determine whether the native game eliminates Boundless immediately.

If still alive, test the intended reclaim path.

Verify that the original capital is restored without acquiring a foreign city.

Verify workforce and frontier recovery.

## Test B — Ordinary city demolition

Attack a city founded by its current owner.

Reduce it to the defeat threshold.

Test the new demolition process or record the exact native restriction.

Repeat with previously captured settlements.

## Test C — Protected settlements

Test original capitals, city-states, holy cities and game-option restrictions.

Protected cities must never be illegally destroyed.

## Test D — Population 80

Use 80 Population and 500 owned plots.

Attempt to work all available eligible remote plots.

Verify exact capacity, native worker census and real yield changes.

## Test E — Worked-tile effects

Compare native and virtual assignments for ordinary improvements, worked-trigger bonuses and supported Tourism behavior.

Verify no duplicate rewards.

## Test F — Quarantine

Force an external city transfer with no valid recipient.

Verify city production, yields, resources, and interactions with the Boundless capital.

## Test G — Domination

If implemented, verify the custom victory requires legitimate subjugation of every required original capital.

No other civilization's victory rules may change.

## Test H — Save/reload

Save and reload during every new mechanic.

Verify records are not reset, repeated or duplicated.

## Test I — Huge-map performance

Test 1,000+ owned tiles, numerous units, and several active wars.

Verify the new mechanics do not reintroduce frequent whole-map scans or UI polling.

---

# PRIORITY 9 — NATIVE SOURCE VERIFICATION

Use the official CP v151 source and the pinned references already documented in this repository.

For each proposed change, identify:

- Exact native C++ function.
- Lua binding, if one exists.
- Relevant preconditions.
- Event timing.
- Risks to native city/unit objects.
- Interaction with Community Patch game rules.

Do not invent APIs.

Do not assume newer Vox Populi methods exist in CP v151.

If an operation requires a custom DLL, separate it into an **optional DLL extension proposal** with the minimum native interfaces required.

Do not implement or distribute a replacement DLL unless specifically authorized.

---

# PRIORITY 10 — FINAL REPORT

After making all safe feasible changes, provide a detailed report.

For each of the six limitations, use one of these statuses:

**SOLVED:** Implemented with verified behavior and tests.

**PARTIALLY SOLVED:** Meaningful improvement implemented, with remaining restrictions identified.

**ENGINE BLOCKED:** No safe solution exists using the current supported CP v151 interfaces.

**UNVERIFIED:** Implementation exists but requires actual in-game verification.

Provide:

1. Root cause of each limitation.
2. APIs and source files investigated.
3. Code changes implemented.
4. Tests and results.
5. Remaining technical restrictions.
6. Any optional DLL extension proposals.
7. Save compatibility status.
8. Performance implications.
9. Exact in-game testing instructions.

Do not count mocked tests as a complete in-game verification.

If the game executable is unavailable, explicitly identify those tests as outstanding.

Do not mark a limitation solved by merely updating documentation.

## FINAL DIRECTIVE

This is the last major engineering investigation before gameplay testing.

Prioritize meaningful functionality, not code churn.

If CP v151 can safely support a feature, implement it.

If an existing workaround can be improved without risking citizen accounting or game stability, improve it.

If the native interface fundamentally blocks the feature, preserve the current working implementation and demonstrate why.

**Do not remove existing mechanics to simplify the civilization.**

The Boundless City must remain a civilization with one capital, unlimited territorial ambition, distant citizens, and a completely distinct approach to empire building.

**ONE CITY. ONE WORLD. NO LIMIT TO ITS REACH.**
