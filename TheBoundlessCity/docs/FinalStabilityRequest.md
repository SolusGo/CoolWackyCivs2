# CODEX TASK — COOL WACKY CIVS 2: FINAL MECHANICS & STABILITY PASS

**Repository:** https://github.com/SolusGo/CoolWackyCivs2

**Civilization:** The Boundless City

**Current reviewed commit:** `fee9bed9b9d5517bec4ebb394c4543e15c4e7267`

**Target:** Civilization V: Brave New World + Community Patch v151

## OBJECTIVE

Perform another comprehensive implementation audit of The Boundless City, concentrating on remaining incomplete mechanics, native-engine compatibility, gameplay correctness, and stability.

The previous implementation pass significantly improved the civilization. Preserve those improvements.

This is an implementation task. Make actual code changes when a safe and verifiable improvement is identified.

Do not rewrite working systems unnecessarily.

**Core design:**

"One city. One population. An entire world of land to exploit."

The civilization must have:

- Exactly one permanent city.
- No Settlers after founding its original capital.
- No additional founded cities.
- No annexed cities.
- No puppet cities.
- Unlimited potential territorial expansion.
- Functional remote tile working at any distance.
- One real citizen per worked plot.
- No passive yields from unworked territory.
- Safe, civilization-specific military expansion mechanics.

Do not modify the original CoolWackyCivs repository.

---

# PRIORITY 1 — REMOTE WORKFORCE COMPLETION

Relevant file:

`TheBoundlessCity/Lua/BoundlessCitizens.lua`

## Current implementation

The latest implementation uses real default labourers, verified local worker withdrawals and a conservative surplus calculation.

The repository's mock tests report:

| Population | Owned plots | Remote workers |
|---|---|---|
| 10 | 30 | 10 |
| 40 | 150 | 10 |
| 80 | 500 | 50 |
| 150 | 1,000 | 120 |

These results represent a significant improvement.

However, they do not fully achieve population-only remote-worker capacity.

## Required investigation

Re-examine the exact native CP v151 citizen allocation and governor behavior.

Determine whether additional valid native citizen states can be safely converted into reserved remote workers.

Investigate:

1. Default specialists and their allocation.
2. Unassigned citizens.
3. Forced default specialists.
4. City automation and governor behavior.
5. Working plot reassignment.
6. Native specialist slot limitations.
7. Citizen reassignment during population changes.
8. Worker reservations after save/load.

**Do not manufacture citizens, create negative automatons, or modify population to simulate additional workers.**

The ideal behavior is for a population-80 capital to allocate all available non-specialist citizens to distant tiles if the player chooses.

However, achieving this must not come at the cost of incorrect accounting.

If CP v151 cannot safely support full remote allocation without DLL modifications, retain the verified implementation and document the restriction.

Do not introduce increasingly complicated workarounds that might cause crashes.

## Workforce correctness

Audit all three assignment modes:

- Automatic.
- Manual.
- Hybrid.

Verify that the following invariant is preserved:

`Local workers + remote workers + building specialists + idle citizens + genuinely unassigned citizens = available population`

Account separately for any native automatons or engine-specific population adjustments.

Ensure remote workers cannot simultaneously produce default labourer yields and full remote yields without the intended compensation.

Test specialist assignment, starvation, population growth, city governor updates, Golden Ages and policy changes.

Verify that actual Food, Production, Gold, Science, Culture and Faith rates change correctly.

The most important criterion is accurate yields with no duplicated citizens.

---

# PRIORITY 2 — CONQUEST WITHOUT OCCUPATION

Relevant file:

`TheBoundlessCity/Lua/BoundlessSiege.lua`

## Current problem

The new siege-demolition mechanic is limited by the native `CanRaze` check.

The check generally rejects settlements founded by their current owner.

Consequently, ordinary enemy cities frequently cannot be removed, even after being reduced to 1 HP.

This is a major limitation for The Boundless City.

We want to preserve the ability to destroy ordinary enemy settlements without retaining them as cities.

## Investigate alternative approaches

Carefully research CP v151's:

- City capture pipeline.
- `CanRaze`.
- `Disband`.
- City destruction.
- Native razing restrictions.
- Capture-related event timing.
- City ownership transfers.
- Protected-capital behavior.

Investigate whether a safe civilization-specific demolition action can be performed against legally razable ordinary enemy settlements without first acquiring the city.

Do not assume `CanRaze` is an ownership-independent legality check.

Distinguish between:

- Game-rule protection against destroying a city.
- Ownership restrictions imposed by the native razing interface.

Do not bypass protected-city rules or call native destruction routines in unsafe contexts.

## Desired behavior

When The Boundless City reduces an ordinary enemy city to 1 HP:

1. A suitable adjacent melee unit must be present.
2. The player can initiate a demolition action.
3. The action is executed outside unsafe combat/capture callbacks.
4. The city is safely destroyed if it satisfies verified destruction rules.
5. The attacker's movement is consumed.
6. The Boundless City never acquires a second city.
7. The former territory becomes available for normal cultural expansion where permitted.
8. No duplicate conquest rewards are possible.

### Protected cities

Original capitals, protected city-states, holy cities and any other legally protected settlements must remain safe.

Where destruction is prohibited, retain NoCapture behavior.

If general demolition is impossible without unsafe engine operations, do not fake it. Preserve the restricted mechanism and explain exactly what remains unsupported.

## Additional improvements

Improve the siege UI so it clearly explains why a target cannot be demolished.

Differentiate:

- Protected city.
- Insufficient damage.
- No eligible melee unit.
- Not at war.
- Not visible.
- Native-engine limitation.

Ensure AI siege behavior cannot repeatedly queue invalid demolitions.

---

# PRIORITY 3 — STRICT ONE-CITY ENFORCEMENT

Relevant file:

`TheBoundlessCity/Lua/BoundlessEvents.lua`

The previous pass successfully removed arbitrary city transfers to unrelated civilizations.

Preserve this correction.

Review the remaining quarantine fallback.

A city obtained through an unexpected scripted transfer can remain temporarily owned when it is protected and has no valid historical recipient.

Investigate whether any additional safe pre-transfer interception or post-transfer resolution is available.

Do not introduce dangerous recursive acquisition or city destruction.

Test:

- Scripted city transfers.
- Diplomatic city gifts.
- Cities received through peace treaties.
- City-state ownership changes.
- Capital loss.
- Original capital recapture.
- Transfers involving eliminated civilizations.
- Simultaneous ownership events.
- Reloading immediately after a transfer.

If a quarantined city cannot safely be removed, ensure it cannot become an exploitable second economic or military center.

Prevent any controllable production, projects, unit training or city-specific advantages where valid engine APIs permit.

Do not claim absolute one-city enforcement if native ownership still temporarily contradicts that requirement.

---

# PRIORITY 4 — YIELD ACCOUNTING AND SAVE SAFETY

Relevant files:

- `BoundlessCitizens.lua`
- `BoundlessPersistence.lua`
- `BoundlessEvents.lua`

The latest implementation separates remote terrain yields from default labourer compensation.

This is promising, but source-sensitive yield calculations need thorough verification.

## Audit the yield ledger

Investigate:

- Partial ledger updates.
- Failure during native yield mutations.
- Negative miscellaneous source adjustments.
- Terrain Culture and Tourism conversion.
- Cached yield refresh behavior.
- External mods modifying the same city.
- Religion and Golden Age yield changes.
- City ownership changes.
- Mid-turn citizen reassignment.

Verify that previous yield contributions are removed exactly once.

Ensure the capital cannot accumulate permanent phantom Food or Production after repeated assignment changes.

Test that switching Automatic → Manual → Hybrid → Automatic does not create duplicate sources.

## Persistence

Preserve compatibility with existing version 1 and version 2 saves wherever technically possible.

Test:

- Saving with remote assignments.
- Loading after population changes.
- Loading before territorial expansion.
- Loading after city demolition.
- Loading after losing territory.
- Loading when an assignment is pending.
- Repeated loading of an older save.
- Corrupted state recovery.

Do not silently reset accumulated Culture, unlocked territory, original-capital identity or Surveyor rewards.

Use explicit versioned migrations when data formats change.

---

# PRIORITY 5 — PERFORMANCE

The intended environment includes Huge maps, up to 22 major civilizations, and many city-states.

The Boundless City might eventually control more than 1,000 plots.

Review the latest optimization changes.

## Movement handling

Ensure `UnitSetXY` uses the indexed remote-plot watcher efficiently.

Avoid repeated full workforce reconciliation when units move far away from relevant territory.

Only update plots whose eligibility or yields may actually have changed.

## AI development

Review `BoundlessAI.lua`.

Ensure AI Surveyors:

- Select legal improvement targets.
- Recognize valuable distant resources.
- Reuse cached decisions safely.
- Respect native pathfinding.
- Avoid repeatedly targeting unreachable plots.
- Do not overwrite active missions unnecessarily.
- Do not monopolize turn-processing time.

Investigate stale AI target references after unit deaths, upgrades, plot ownership changes and save/load.

## Frontier expansion

Preserve unlimited potential radius.

Do not introduce artificial distance or territory caps to improve performance.

Profile border scoring, frontier maintenance and ownership updates at:

- 100 plots.
- 500 plots.
- 1,000 plots.
- 2,500 plots.
- 10,000 plots, if practical in a synthetic test.

## UI

Ensure the workforce panel is responsive with thousands of eligible plots.

Only rebuild cached rows when necessary.

Avoid permanent frame polling.

---

# PRIORITY 6 — AUDIT MOD INTEGRATION

Verify the version 2 mod packaging.

Check:

- Mod UUID.
- Community Patch dependency.
- SQL load ordering.
- Lua include ordering.
- VFS flags.
- UI addin registration.
- DDS references.
- Localization keys.
- Civilopedia entries.
- ModBuddy project references.
- Save compatibility metadata.

Confirm both CoolWackyCivs and CoolWackyCivs2 can be enabled independently and together without duplicate database identifiers or conflicting globals.

Do not modify the original collection.

---

# PRIORITY 7 — TESTS AND REGRESSION

Expand the existing tests to cover the actual remaining failure modes.

Prioritize adversarial scenarios rather than simply repeating successful mock cases.

### Required tests

**Test A — Population 80**

80 Population, 500 owned plots, numerous improved distant plots.

Verify exactly how many remote workers can be reserved without citizen duplication.

**Test B — Population 150**

150 Population, 1,000 owned plots.

Verify no arbitrary territory distance cap and accurate remote-worker limitations.

**Test C — Regular enemy city**

Reduce an enemy-founded city to 1 HP.

Verify demolition behavior and the reason for any rejection.

**Test D — Protected capital**

Reduce an original capital to 1 HP.

Confirm protected-city rules cannot be bypassed.

**Test E — Ledger consistency**

Repeatedly assign and remove remote workers, then save and reload.

Check all supported yield sources for duplication or leakage.

**Test F — Population loss**

Assign remote workers and then reduce population sharply.

Ensure excess assignments are removed and native citizen counts remain valid.

**Test G — External transfer**

Create an unexpected additional city through a scripted ownership change.

Verify safe recovery or quarantine without recursive city operations.

**Test H — Huge map**

Evaluate processing cost with thousands of owned plots and many military units moving across the map.

## Verification standards

Use the actual CP v151 source to check Lua methods and signatures.

Mock tests are useful but are not proof of native gameplay correctness.

If a running Civ V environment is unavailable, explicitly distinguish:

- Source-verified behavior.
- SQL/Lua validation.
- Mock-simulated behavior.
- Untested in-game behavior.

Do not claim to have playtested Civ V unless the actual game was launched.

---

# PRIORITY 8 — PRESERVE THE CIVILIZATION

Do not remove:

- Infinite border-growth mechanics.
- Unlimited potential remote-working distance.
- The Grand Registry.
- Frontier Surveyor.
- One-time Surveyor Culture rewards.
- Directional border preferences.
- Manual/Automatic/Hybrid workforce systems.
- Existing art and localization.
- AI support.
- Native-save persistence.

Do not add extra settlements, hidden cities, puppets or yield-generating dummy populations.

Do not redesign this into a conventional tall civilization.

The entire point is that **one city can control and economically exploit a vast geographical area**.

Maintain reasonable balance.

Avoid granting free yields merely to compensate for engine limitations.

---

# FINAL DELIVERABLE

Make all safe and justified changes directly in CoolWackyCivs2.

Provide:

1. Exact bugs identified.
2. Root causes.
3. Files modified.
4. Fixes implemented.
5. Tests performed and results.
6. Current maximum remote workforce behavior.
7. Current demolition behavior.
8. Remaining native-engine restrictions.
9. Save compatibility status.
10. In-game testing instructions.

Update the README, changelog, implementation documentation and limitations report.

**Do not produce a major rewrite merely to appear productive.**

Prefer small, well-supported corrections over speculative workarounds.

If the implementation is already the safest feasible solution without modifying the Community Patch DLL, say so and preserve it.

The end goal is a stable, enjoyable civilization that can be played for hundreds of turns on Huge maps.

**THE BOUNDLESS CITY**

"There shall be no second city. For the first shall have no end."
