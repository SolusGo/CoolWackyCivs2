
Implement a complete, playable Civilization V: Brave New World custom civilization named "The Republic of Pigeons", led by "Postmaster General Coo".

Target repository:
https://github.com/SolusGo/CoolWackyCivs2

If the repository structure differs from expectations, inspect it and adapt. Follow the existing conventions for civilizations, assets, mod packaging, and localization.

This is a new civilization, not a modification of an existing one.

TARGET ENVIRONMENT
- Civilization V: Brave New World
- Community Patch v151
- Lua, XML and SQL
- Human and AI compatibility
- Standard and modded game speeds
- Save/load compatibility
- No external DLL modifications

Implement the actual mod files, not merely documentation or pseudocode.

========================================
1. CIVILIZATION IDENTITY
========================================

Civilization: The Republic of Pigeons
Leader: Postmaster General Coo
Capital: Coopolis
UA: Messages on the Wing
UU: Carrier Pigeon (replaces Scout)
UB: Rooftop Roost (replaces Caravansary)

Theme:
A whimsical civilization built around communication, exploration, commerce and messenger pigeons.

Despite its absurd premise, the civilization should function as a serious, balanced, playable Civ V civilization.

Personality:
- Friendly and inquisitive
- Prefers diplomacy and commerce
- Highly values exploration
- Dislikes civilizations that disrupt trade
- Not entirely helpless in warfare

Preferred victories:
1. Science
2. Culture
3. Diplomacy

Visual identity:
- Slate blue-grey
- Soft cream
- Postal imagery
- Pigeon and feather motifs

========================================
2. UNIQUE ABILITY
MESSAGES ON THE WING
========================================

For every active outgoing LAND trade route, the origin city receives:

Ancient through Medieval:
+2 Science
+2 Culture

Renaissance and later:
+3 Science
+3 Culture

These bonuses apply to both domestic and international land trade routes.

Sea trade routes do not qualify.

Multiple qualifying routes from one origin city stack additively.

Example:

Coopolis has 3 outgoing land routes.

In the Medieval Era:
+6 Science
+6 Culture

In the Renaissance Era:
+9 Science
+9 Culture

No bonus is granted merely because a route passes through or arrives at a city.

IMPLEMENTATION:

Use an efficient Lua system to inspect player:GetTradeRoutes() and identify qualifying routes by domain and origin city.

Verify the relevant Civ V / Community Patch API fields rather than guessing them.

Compare the route domain with DomainTypes.DOMAIN_LAND.

Identify origin cities by player ownership and city ID, not city name.

Implement the yields through invisible, unbuildable dummy buildings.

Recommended approach:
- One stackable dummy building providing +1 Science.
- One stackable dummy building providing +1 Culture.
- Set their counts based on the calculated bonus in each origin city.

Refresh bonuses on PlayerDoTurn and on additional verified trade-route events where available.

IMPORTANT:
- No cumulative yield duplication.
- No permanent bonuses after routes disappear.
- No incorrect bonuses after conquest.
- Correctly handle deleted or razed cities.
- Correctly handle civilization elimination.
- Correctly handle war-related trade route cancellation.
- Correctly handle switching from land to sea routes.
- Correctly handle Renaissance era transition.
- Correctly restore yields after saving and loading.
- Do not grant the bonus to other civilizations.

Avoid expensive per-frame or per-second polling.

========================================
3. UNIQUE UNIT
CARRIER PIGEON
========================================

Replaces: Scout

Retains the Scout's standard properties unless explicitly modified.

Unique advantages:
- +1 Sight relative to a standard Scout.
- Ignores terrain movement costs.

Implementation details:

Create a proper unique unit using the Scout unit class and the appropriate Civilization_UnitClassOverrides registration.

Use a supported promotion or unit property to grant the additional sight.

Ensure the Ignore Terrain Cost effect works under Community Patch v151.

Inspect the standard Scout's existing promotions first. If Scouts already ignore terrain costs, preserve that effect without applying redundant or conflicting promotions.

Do not make the unit capable of illegally entering mountains, ice, oceans or otherwise impassable terrain.

Preserve:
- Scout combat role
- Scout upgrade progression
- Ruin interaction
- Reconnaissance promotions
- Appropriate AI behavior

Provide a unique unit icon and unit flag icon.

A custom 3D model is optional. Reusing a compatible vanilla Scout model is acceptable.

========================================
4. UNIQUE BUILDING
ROOFTOP ROOST
========================================

Replaces: Caravansary

Retains ALL normal Caravansary benefits from the active Community Patch version.

Additional bonuses:

+1 Culture.

While the city has at least one active outgoing LAND trade route:

+2 Production.

The Production bonus is binary:
- Zero active outgoing land routes = +0 Production.
- One or more active outgoing land routes = +2 Production.

It does NOT increase for additional routes.

IMPLEMENTATION:

Use the existing Caravansary as the baseline.

Preserve its prerequisites, cost, maintenance, land trade range benefits and other CP-specific properties.

Use a normal building yield for the permanent +1 Culture.

Use an invisible dummy building for the conditional +2 Production if necessary.

Refresh the conditional bonus whenever the active routes change.

On removal or destruction of the qualifying route, the Production bonus must disappear.

If the building is removed or the city changes ownership, clean up the associated dummy building.

Do not accidentally double-count this bonus with the civilization's UA.

========================================
5. LEADER PERSONALITY AND AI
========================================

Postmaster General Coo should be a believable trade-oriented AI leader.

Preferred behaviors:
- Builds trade infrastructure.
- Explores extensively.
- Pursues scientific and cultural development.
- Establishes international trade where practical.
- Maintains sufficient defensive forces.
- Prefers peaceful cooperation.

Avoid making the AI excessively aggressive.

However, it should still defend itself and participate in wars when appropriate.

Use appropriate leader flavors and diplomacy settings.

Ensure the AI understands the civilization's conventional trade and recon strengths as much as the base engine permits.

Do not claim the AI can strategically understand custom Lua mechanics unless explicitly implemented.

========================================
6. PRESENTATION AND ASSETS
========================================

Create a complete civilization selection and Civilopedia presentation.

Include:
- Civilization icon
- Leader portrait
- Dawn of Man / loading image
- Unit icon
- Unit flag icon
- Building icon
- Alpha/icon atlases as necessary
- Map and civilization flag assets
- Working text localization

Use original art or appropriately licensed assets.

If asset generation is supported, create original imagery using pigeon, messenger, rooftop and postal aesthetics.

If image generation is unavailable, use compatible existing assets as safe temporary fallbacks and document what remains.

Avoid missing texture icons.

LEADER FLAVOR:

Postmaster General Coo should look like an absurdly dignified pigeon statesman.

Possible visual direction:
A grey pigeon wearing ceremonial postal attire, standing on a rooftop balcony overlooking an enormous medieval city full of towers, courier pigeons and messenger stations.

========================================
7. TEXT AND CIVILOPEDIA
========================================

Write:
- Unique ability description
- Unit description
- Building description
- Civilization history
- Leader biography
- Strategy section
- Dawn of Man introduction
- Diplomacy greeting
- Peace declaration
- War declaration
- Defeat quote

Suggested leader greeting:

"Greetings, stranger. I am Postmaster General Coo, guardian of every message that takes wing. May our correspondence be fruitful, and our breadcrumbs plentiful."

Suggested war declaration:

"You have intercepted our correspondence for the last time. The skies themselves shall carry our displeasure!"

Suggested defeat quote:

"Our roosts lie empty, our messages undelivered. Even the mightiest wings must someday rest."

The writing should be whimsical but polished, fitting naturally into the Civilization V presentation.

Create an original city-name list including:

Coopolis
Nestminster
Featherford
Coochester
Rooftopia
Winghaven
Breadcrumb Bay
Pigeonholm
Perchfield
Dovecourt
Greyfeather
Skypost
Posthaven
Featherbridge
Highperch

========================================
8. MOD ARCHITECTURE
========================================

Use a clean standalone civilization implementation within the repository.

Requirements:
- Unique PIGEON-prefixed database identifiers.
- Correct database load order.
- Correct OnModActivated / UpdateDatabase setup.
- Correct InGameUIAddin or other appropriate Lua registration.
- No global variable pollution.
- No unnecessary UI polling.
- No modifications to vanilla game files.
- No unexpected changes to other civilizations.
- No duplicate registrations.
- No missing TXT_KEY entries.
- No Lua errors from nil city/player references.

Inspect how the existing repository packages mods before adding new files.

If the repository uses source files plus a generated .modinfo package, update both appropriately.

========================================
9. SAVE AND GAMEPLAY SAFETY
========================================

Prioritize save/load stability.

All dynamic trade-route bonuses must be reconstructed from actual game state.

Avoid relying on transient Lua variables as the authoritative state of the civilization's bonuses.

Ensure dummy buildings cannot:
- Be built manually.
- Be purchased.
- Appear as normal selectable buildings.
- Accidentally transfer permanent trade bonuses to another civilization.

Handle ownership changes carefully.

Do not require constant UI updates to function correctly.

========================================
10. TESTING AND VALIDATION
========================================

Perform static verification and any available runtime tests.

Test cases:

1. Starting a game as the Republic of Pigeons.
2. Confirming the Scout replacement works.
3. Confirming Carrier Pigeon sight and movement.
4. Building the Rooftop Roost.
5. Creating the first land trade route.
6. Creating multiple routes from the same city.
7. Creating land routes from different cities.
8. Creating a sea trade route.
9. Cancelling or destroying a land trade route.
10. Reaching the Renaissance Era.
11. Capturing a Pigeon city with active bonuses.
12. Losing a Pigeon city to another civilization.
13. Removing the Rooftop Roost.
14. Saving and reloading the game.
15. Playing as another civilization against Pigeon AI.
16. Testing different game speeds.

Validate that:

One Medieval land route gives:
+2 Science, +2 Culture to its origin city.

Three Medieval land routes give:
+6 Science, +6 Culture.

Three Renaissance land routes give:
+9 Science, +9 Culture.

One Rooftop Roost with an outgoing land route gives:
+1 Culture and +2 Production, in addition to preserved Caravansary benefits.

The Rooftop Roost's conditional Production does not stack beyond +2.

Check for incorrect tooltip text, missing icons, database errors and unintended mechanics.

========================================
11. FINAL DELIVERABLE
========================================

Implement all necessary files directly in the repository.

Provide:
1. A summary of implemented mechanics.
2. List of created and modified files.
3. Explanation of the trade-route Lua implementation.
4. Confirmation of database and modinfo registration.
5. Confirmation of Community Patch compatibility considerations.
6. Results of static or runtime tests actually performed.
7. Any engine limitations or unverified assumptions.
8. Remaining artwork or manual in-game testing requirements.

Do not claim that in-game tests passed unless they were actually run.

PRIORITIES:

Correctness > Save Compatibility > Performance > Polish.

Keep all three unique mechanics faithful to this specification.

Do not introduce additional abilities or balance changes without a compelling technical reason.

The finished Republic of Pigeons should be funny in concept, but robust and strategically interesting in practice.
