# CODEX IMPLEMENTATION TASK
## The Boundless City — A Civilization V Civilization

**Repository:** https://github.com/SolusGo/CoolWackyCivs

**Target:** Civilization V: Brave New World with Community Patch (CP), targeting CP v151.

Implement a completely new, fully playable civilization called **The Boundless City** in the existing CoolWackyCivs mod.

This is an implementation task, not merely a design document. Write the actual SQL/XML, Lua, UI, localization, art references, and other required files. Integrate the civilization into the existing mod project.

Study the architecture of TheLastCity, TheKingdoms, and TheShatteredEmpire before implementing. Follow existing conventions while keeping all new gameplay systems isolated.

Do not modify the core Community Patch DLL or introduce a new custom DLL.

---

# 1. Civilization Identity

**Civilization:** The Boundless City

**Leader:** The First Architect

**Capital:** The Heart of the World

**Unique Ability:** The World Is One City

**Unique Building:** The Grand Registry (replaces Monument)

**Unique Unit:** Frontier Surveyor (replaces Worker)

**Leader personality:** Expansionist, highly defensive, infrastructure-oriented, reluctant to engage in unnecessary wars.

**Civilization quote:**

"There shall be no second city. For the first shall have no end."

## Core Vision

This civilization possesses exactly one city for the entire game.

Its defining feature is that the capital has no artificial territorial expansion limit and may functionally work tiles at any distance.

The capital can theoretically spread across continents, coastlines, islands, and eventually much of the map.

Unlike conventional civilizations, it does not need Settlers or captured cities to develop a geographically massive empire.

The goal is for the player to see a giant contiguous national territory, controlled by one extraordinarily developed city.

**The civilization is not allowed to create or retain any additional cities under any circumstances.**

---

# 2. Unique Ability — The World Is One City

Implement these rules:

1. The player can own only their original capital.
2. Cannot construct or purchase Settlers.
3. Cannot found additional cities through any mechanism.
4. Cannot annex cities.
5. Cannot puppet cities.
6. Cannot retain cities obtained through conquest, diplomacy, events, special abilities, or transfers.
7. The capital may expand its borders indefinitely, constrained only by the actual map and legal ownership.
8. Any eligible owned tile may contribute yields through citizen assignment, regardless of distance.
9. Working a distant tile requires one citizen, just as working a normal tile does.
10. Distant tiles retain their ordinary tile yields. There is no distance penalty.
11. The capital's population, specialists, and workforce must remain internally consistent.
12. Owning additional territory must not automatically grant all its tile yields.

The civilization must remain balanced around the fundamental limitation of having only one city.

Do not introduce arbitrary maximum borders, maximum remote-working distance, or remote-worker count caps independent of population.

---

# 3. Infinite Territorial Expansion

This is the first major engineering challenge.

Civ V normally restricts culture-driven city growth to a limited geographical area.

We need a custom system that can claim territory beyond the normal city border growth constraints.

## Requirements

Create a culture-driven territorial expansion system.

- The capital continues expanding beyond five hexes.
- There is no fixed maximum expansion radius.
- Expansion continues as long as valid unowned adjacent tiles exist.
- Expansion is possible across water and onto distant landmasses through contiguous territorial growth.
- Enemy-owned territory cannot simply be stolen.
- The system must respect map boundaries and wrapped maps.
- Expansion must not create disconnected owned territory accidentally.
- Ordinary Culture, Social Policies, and Tourism must not be disrupted.
- City and civilization ownership must remain correct.

## Implementation approach

Investigate the available Civ V and CP Lua APIs.

Implement a separate frontier-expansion accumulator driven by the capital's culture output.

Do not consume or overwrite the game's normal policy Culture unless explicitly required and accounted for.

Select valid plots next to existing Boundless City territory, checking ownership and accessibility constraints.

Use the appropriate verified plot ownership API to assign the plot to The Boundless City and, where supported, associate it with the capital.

### Expansion cost

Use a tunable formula depending on:

- Total tiles already owned.
- Current era.
- Game speed.
- Relevant UB modifiers.

Expansion must become progressively more expensive as territory grows.

However, never implement an exponential curve that renders expansion practically impossible after the first few hundred tiles.

Aim for meaningful large-map expansion over an entire game without making the civilization able to consume a continent in 30 turns.

Culture output should remain the most important driver of expansion.

## Border selection

Prioritize useful nearby tiles:

- Resources.
- High-yield terrain.
- Strategic chokepoints.
- Tiles aligned with the chosen expansion direction.

Provide a simple way to influence expansion direction if feasible.

Make the automatic algorithm deterministic and suitable for both human and AI players.

**Important:** This must be genuinely unlimited in principle, not an increase from three rings to five, six, or ten.

---

# 4. Infinite Working Radius — CRITICAL

This is the most important feature of the entire civilization.

Do not simulate infinite working radius by giving a flat yield bonus based on territory.

Do not simply raise MAX_CITY_RADIUS to a slightly larger number.

Do not claim the feature is implemented if distant plots cannot actually contribute their correct yields to the capital.

## Desired behaviour

Suppose the capital has 40 Population and owns 300 plots.

The player should be able to assign citizens to selected owned plots regardless of distance.

For example:

- Citizen 1: Works a farm two tiles from the capital.
- Citizen 2: Works a mine twelve tiles from the capital.
- Citizen 3: Works a trading post thirty tiles away.
- Citizen 4: Works a fishing boat on another coastline.

All their yields contribute to the same capital.

No distance-based penalty applies.

However, only the actual available workforce can be assigned.

## Technical architecture

Investigate whether Community Patch v151 exposes a genuinely suitable method for expanding citizen assignment.

If no reliable native solution exists, implement a **Virtual Remote Workforce** system.

This system should allow distant plots to function as worked tiles without modifying the DLL.

### Virtual citizen assignment

Maintain persistent records associating citizen assignments with eligible remote plot coordinates.

Rules:

1. One remote plot requires one assigned citizen.
2. Each plot can have no more than one worker.
3. Remote workers must be removed from the pool available to normal tiles and specialists.
4. The city's effective population must not increase because remote workers exist.
5. Remote plot yields must be credited to the capital exactly once.
6. Citizens cannot produce yields both locally and remotely.
7. Removing a remote worker removes its corresponding yield contribution.
8. Population growth increases available working capacity normally.
9. Starvation or population loss must trigger reassignment.
10. Remote assignments must survive saving and loading.

Use a verifiable citizen-accounting mechanism. Investigate zero-yield specialist slots, appropriate city citizen APIs, or an equivalent carefully reconciled approach.

Do not assume arbitrary Lua setters or specialist capacities exist without checking.

If the engine cannot support a required invariant, investigate alternatives and disclose the exact limitation rather than silently granting free yields.

### Tile yields

Remote plots should use their real current yields, including:

- Food.
- Production.
- Gold.
- Science, Culture, Faith, or other plot yields where supported.
- Terrain modifiers.
- Improvements.
- Resource-related tile yields.
- Technology and policy effects.
- Relevant civilization modifiers.

Respect differences between base plot yields and conditional city modifiers to avoid double applying bonuses.

Use the engine's evaluated plot yields wherever possible.

If a farm generates 5 Food, a remotely assigned citizen should contribute the appropriate 5 Food, subject to any applicable global game rules.

### Automatic updates

Recalculate remote contributions when relevant events occur:

- A tile improvement is completed.
- A tile improvement is pillaged or repaired.
- Technology changes a plot's yield.
- Ownership changes.
- Population changes.
- An assigned plot becomes invalid.
- A saved game is loaded.
- A city or player changes state.

Use event-driven invalidation and scheduled reconciliation rather than constantly recalculating the entire map.

### Workforce automatic management

Provide three modes:

**Automatic:** Select the strongest available combination of plots, accounting for yields and configurable priorities.

**Manual:** Let the player assign individual remote plots.

**Hybrid:** Preserve manually locked assignments while automatically allocating the remaining available workforce.

The automatic system should consider ordinary local plots and remote plots as part of one workforce, not blindly prefer remote tiles.

Support sensible priority choices such as Food, Production, Gold, or Balanced.

---

# 5. Remote Workforce UI

Create a custom interface named:

**The Boundless Workforce**

It should be accessible during normal gameplay through a compact button near the relevant city interface or another non-obstructive location consistent with the mod's UI patterns.

The panel should display:

- Capital population.
- Total owned plots.
- Available working citizens.
- Locally assigned citizens.
- Remotely assigned citizens.
- Specialists.
- Remote workforce yields.
- Current workforce management mode.

Allow the player to browse remote plots and select or deselect assignments.

Useful features include sorting by distance, yield, resource, and improvement type.

Clearly display which tiles are already assigned.

Prevent selecting invalid or enemy-owned plots.

## Performance requirements

Do not run a whole-map scan every 0.1 seconds.

Do not use aggressive ContextPtr update loops or frame polling.

The user's other mods have experienced significant FPS degradation from frequent UI polling.

Prefer:

- Event-driven updates.
- Cached plot lists.
- Incremental dirty flags.
- Turn-based reconciliation.
- UI refreshes only when open or when relevant state changes.

Avoid changing global CityView.lua unless absolutely necessary. Prefer isolated UI extensions or addins.

The UI must disappear or behave appropriately in diplomacy, city screens, and other incompatible game contexts.

---

# 6. Strict One-City Enforcement

This requirement is non-negotiable.

The Boundless City can NEVER retain a second city.

No loopholes through:

- Annexation.
- Puppeting.
- Settlers.
- Peace treaties.
- City trades.
- Diplomatic gifts.
- Special abilities.
- Scripted ownership changes.
- Conquest.
- Liberation-related edge cases.

Enforce this on both the human player and AI.

## Conquest Without Occupation

When The Boundless City defeats an enemy city, resolve the conquest without permanently acquiring an additional city.

For ordinary razable cities, implement automatic destruction where technically and legally supported.

For cities that cannot be razed, investigate safe alternatives.

Possible choices include:

1. Liberation to a valid former owner.
2. Immediate return to another eligible owner.
3. Preventing final acquisition while recording that the city's defenses were defeated.

The original capital prohibition, city-state restrictions, religious holy cities, and other non-razable cases must be handled safely.

Do not delete non-razable cities by bypassing engine invariants.

Do not accidentally destroy the original capital required for domination victory.

Do not make the player keep a puppet temporarily as the intended final resolution.

Examine conquest event ordering and the native capture-decision interface carefully. If the engine creates an unavoidable transient ownership state during capture, ensure it is resolved safely within the same action and never becomes a usable second city.

For original capitals that cannot be liberated, favor a safe siege-victory or capture-blocking resolution instead of forcing illegal ownership.

Ensure repeat attacks cannot farm conquest rewards.

## Victory conditions

Science, Culture, and Diplomatic victories should remain playable.

Investigate how normal Domination Victory interacts with the strict one-city rule.

If standard Domination Victory cannot be achieved without retaining foreign original capitals, document that limitation explicitly.

Do not secretly change global domination rules affecting other civilizations.

If a robust civilization-specific domination alternative is possible without DLL changes or altering other civilizations' victories, it may be implemented, but must be fully tested and clearly documented.

---

# 7. Unique Building — The Grand Registry

**Replaces:** Monument

Effects:

- Provides +3 Culture instead of the Monument's normal +2.
- Provides +1 additional Culture for every 10 plots owned by the capital.
- Territorial bonus capped at +10 Culture.
- Reduces the custom culture cost of frontier expansion by 15%.
- Retains the Monument's normal functionality and prerequisites.

The bonus should update as territory expands or contracts.

Do not accidentally create additional buildings or stack duplicate effects when the plot count changes.

Use appropriately maintained dummy buildings or Lua-derived values if required.

Ensure it functions for the AI.

Keep the effects modest because unlimited territory is already extremely powerful.

---

# 8. Unique Unit — Frontier Surveyor

**Replaces:** Worker

Effects:

- 3 Movement instead of 2.
- Builds improvements 25% faster than an ordinary Worker.
- Completing an eligible improvement more than five hexes from the capital grants +5 Culture.

The improvement Culture bonus applies once per qualifying plot, per civilization.

It must not trigger repeatedly through:

- Pillaging and repairing.
- Replacing improvements.
- Unit cancellation.
- Reloading the game.
- Repeated ownership changes.

A normal repair must not count as a newly completed improvement.

Verify the replacement's build permissions, movement, upgrade/replacement relationships, AI behavior, worker automation, and improvement-speed implementation under CP.

Avoid adding unnecessary combat powers.

The Surveyor is a civilian unit, intended to develop enormous territories.

---

# 9. Civilization Balance

Do not make the civilization automatically overpowered simply because it is geographically large.

The central strength is **access to a much larger selection of workable plots**, not free yields from every owned tile.

### Advantages

- Extremely broad access to valuable territory.
- Can reach distant resources.
- Can acquire territory without Settlers.
- Flexible Food and Production economy.
- Strong long-term potential.
- All worked-tile yields flow into one capital.

### Disadvantages

- Only one production queue.
- Only one city capable of producing units.
- No extra cities for additional buildings and specialist infrastructure.
- Vulnerable to capital loss.
- Workers must spend time developing distant land.
- Remote improvements are vulnerable to pillaging.
- Territorial growth costs Culture and takes time.
- Population still limits the number of productive worked plots.

Do not introduce additional percentage yield multipliers without a compelling balance reason.

Scale relevant thresholds with game speed using existing project patterns.

The civilization should feel modest in the Ancient Era, flexible in the Medieval Era, and potentially formidable in the Industrial and Information Eras.

Do not hardcode calculations assuming Standard speed.

---

# 10. AI Support

The civilization must not require human-only mechanics to function.

Implement AI behavior or safe deterministic automation so the AI can:

- Expand beyond normal borders.
- Allocate remote workers.
- Prioritize Food when growth is needed.
- Prioritize Production appropriately.
- Improve useful distant territory.
- Operate with only one city.
- Avoid trying to build additional Settlers.
- Resolve conquest without retaining cities.

Do not claim full AI compatibility simply because the AI can spawn and take turns.

Use an AI strategy that recognizes its single-city limitations, with sensible defensive emphasis.

Do not make unrelated civilizations use these mechanics.

---

# 11. Save Compatibility and Persistence

All stateful systems must survive saves and reloads.

Persist at minimum:

- Frontier Culture progress.
- Border expansion preferences.
- Remote workforce assignments.
- Locked manual assignments.
- Worker priority mode.
- One-time Surveyor rewards.
- Any conquest-related temporary state.

Follow established save-data patterns in the repository.

On load, validate city ownership, plots, population, and stored coordinates.

Do not duplicate yields or re-award bonuses when initialization runs multiple times.

Ensure loading a save immediately before border expansion or conquest behaves predictably.

The new civilization should not corrupt existing save games using other civilizations from the same mod.

---

# 12. Art and Presentation

Provide the necessary Civ V presentation assets.

Theme:

A civilization that begins as a single medieval settlement and eventually becomes an impossibly vast metropolis encompassing an entire world.

Use elegant gold, ivory, and deep blue tones.

Provide or prepare correctly referenced assets for:

- Civilization icon and alpha.
- Leader portrait.
- Dawn of Man / loading illustration.
- Diplomacy artwork.
- Unique Building icon.
- Unique Unit icon.
- Required unit flags.
- Appropriate atlas entries.
- Civilopedia and localization.

You may generate original art assets if your environment supports it.

Ensure final files are in formats genuinely supported by Civilization V, such as correctly prepared DDS atlases where necessary.

Do not use unrelated placeholder graphics as if they were finished assets.

If complete image generation is unavailable, prepare the art integration and clearly identify remaining assets rather than referencing nonexistent files.

Use no unnecessary sounds.

---

# 13. Repository Integration

Create a dedicated directory:

`TheBoundlessCity/`

Follow the existing civilization directory conventions.

Include SQL/XML data, Lua systems, UI code, assets, and documentation as appropriate.

Register all required SQL/XML, Lua, UI, and art files in:

- The main Cool Wacky Civs modinfo.
- The ModBuddy project.
- Any relevant project manifests.

Inspect load ordering carefully.

Ensure SQL gameplay data is loaded before Lua references it.

Do not overwrite similarly named resources belonging to other civilizations.

Prefix new types, tables, and Lua globals appropriately to avoid collisions.

Update the repository README and patch notes.

Provide a civilization-specific README explaining mechanics, UI, balance, CP dependencies, and known engine limitations.

---

# 14. Performance and Stability

Huge maps and long games are important use cases.

Target maps with thousands of plots and dozens of civilizations.

Avoid:

- Full map scans every frame.
- Unnecessary repeated ownership checks.
- Frequent UI polling.
- Rebuilding large plot tables without invalidation.
- Infinite loops when no legal frontier plots remain.
- Excessive dummy-building updates.
- Re-entrant city capture handlers.
- Repeated Culture rewards.
- Expensive calculation during UI rendering.

Cache the frontier and workforce data wherever practical.

Use a scalable frontier algorithm that primarily examines plots adjacent to existing territory instead of scanning the entire world after every claim.

Maintain stable behavior when hundreds or thousands of tiles are owned.

Keep work bounded per update and use deterministic state reconciliation.

Do not introduce excessive memory consumption.

---

# 15. Testing and Verification

Provide a meaningful verification plan and implement automated checks wherever possible.

### Test A — Ancient Era

Found The Heart of the World.

Confirm:

- One city exists.
- No Settlers can be constructed.
- Monument replacement works.
- Surveyor replaces Worker.
- Basic territorial growth operates correctly.

### Test B — Beyond Normal Borders

Expand beyond the fifth ring.

Verify plots are genuinely owned and logically associated with the capital where supported.

Repeat until the capital has at least 100 plots.

### Test C — Remote Plot Working

Own an improved tile 15 hexes away.

Assign one citizen to it.

Check that:

- The correct yields appear.
- Available citizen count decreases appropriately.
- No duplicate local assignment exists.
- Removing the citizen removes those yields.
- Reloading does not change the result.

### Test D — Huge Territory

Test at 300 and 1,000 owned tiles where map space permits.

Verify border expansion still works and performance is acceptable.

### Test E — Conquest

Capture an ordinary enemy city.

Confirm no second city is retained.

Repeat against:

- An original capital.
- A city-state.
- A holy city.
- A non-razable city.
- A city previously belonging to another civilization.

Confirm no illegal city destruction, conquest loop, permanent puppet, or crash occurs.

### Test F — Workforce Edge Cases

Test:

- Population growth.
- Starvation.
- Pillaged improvements.
- Technology-dependent yields.
- Specialist reassignment.
- Lost territory.
- Workable water tiles.
- AI workforce assignment.
- Saving and reloading.

### Test G — Performance

Benchmark turn processing and UI behavior on a Huge map.

Pay particular attention to late-game plot counts.

### Test H — Regression

Confirm existing civilizations, including TheLastCity, TheKingdoms, and TheShatteredEmpire, remain unaffected.

Validate all modified manifests and references.

If the actual game executable is unavailable, distinguish static validation from runtime verification. Do not claim game tests were performed when they were not.

---

# 16. Final Deliverables

Complete the implementation.

At the end, provide:

1. Summary of implemented functionality.
2. Files created and modified.
3. Explanation of how unlimited cultural border growth works.
4. Explanation of how remote citizens consume population and produce real yields.
5. Explanation of how conquest enforces one-city ownership.
6. Summary of AI support.
7. Results of available validation and testing.
8. Performance considerations.
9. Any remaining limitations requiring in-game verification.
10. Exact steps to test the civilization with CP v151.

**Non-negotiable final checks:**

- Truly unlimited potential border growth.
- Functional unlimited-distance tile working.
- No free yields from unworked plots.
- Remote workers cannot duplicate citizens.
- Exactly one owned city.
- No annexed or puppeted cities.
- No unsafe destruction of protected capitals.
- No excessive continuous polling.
- No dependencies on a custom replacement DLL.
- Correct integration into CoolWackyCivs.

Do not silently substitute weaker mechanics because an implementation is difficult.

If engine restrictions make a perfect solution impossible without modifying the DLL, implement the closest robust solution, document the precise difference, and state clearly which requirements remain unmet.

**The fundamental fantasy must remain intact:**

One city, one population, one production centre, and potentially an entire world of land to exploit.

"There shall be no second city. For the first shall have no end."
