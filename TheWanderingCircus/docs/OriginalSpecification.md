
Implement a complete Civilization V: Brave New World custom civilization called "The Wandering Circus", led by "Ringmaster Aurelio", directly in the existing CoolWackyCivs2 repository.

REPOSITORY:
https://github.com/SolusGo/CoolWackyCivs2

IMPORTANT:
This is a real implementation task, not a design proposal.

Inspect the repository, implement the civilization, integrate it into the existing collection, update the build tooling where necessary, and perform all available validation.

Do not modify existing civilizations' gameplay.

==================================================
1. ENVIRONMENT AND IMPLEMENTATION PRIORITIES
==================================================

Target:
- Civilization V: Brave New World
- Community Patch v151
- Lua 5.1
- SQL/XML
- Existing CoolWackyCivs2 packaging structure
- Windows single-player

Civilization settings:
Playable = 1
AIPlayable = 0

This civilization is intended for human players only.

Priorities:
1. Faithful mechanics
2. Save/load correctness
3. Exact festival timing
4. Compatibility with CP v151
5. Runtime performance
6. Artwork and presentation

Do not:
- Modify the Community Patch DLL.
- Replace native game files.
- Introduce unnecessary mechanics.
- Add custom strategic AI systems.
- Change the civilization's balance values.
- Implement permanent per-frame polling.
- Claim tests passed unless they actually ran.

==================================================
2. INSPECT THE EXISTING REPOSITORY
==================================================

Before modifying files:

Inspect:
- README.md
- Existing .modinfo
- Existing .civ5proj
- Current mod version
- Build and packaging scripts
- Validation scripts
- Existing civilization directories
- Relevant SQL inheritance helpers
- Existing art generation pipeline
- Community Patch source-audit utilities

Pay particular attention to existing approaches used by:

TheBoundlessCity
TheRepublicOfPigeons

Reuse their working conventions wherever appropriate.

Create a new civilization directory:

TheWanderingCircus/

Suggested structure:

TheWanderingCircus/
  Art/
  SQL/
  UI/
  docs/
  README.md
  CHANGELOG.md

Possible SQL files:

00_WCIRCUS_Core.sql
01_WCIRCUS_Inheritance.sql
02_WCIRCUS_Effects.sql
03_WCIRCUS_Art.sql
10_WCIRCUS_Text.sql

Possible runtime files:

UI/WanderingCircus.lua
UI/WanderingCircus.xml

Adapt names and locations if the repository uses a different convention.

Preserve the collection's existing mod UUID.

Increment the mod version according to existing repository conventions.

Do not overwrite or break previous civilization registrations.

==================================================
3. CIVILIZATION IDENTITY
==================================================

Civilization:
The Wandering Circus

Leader:
Ringmaster Aurelio

Capital:
Grand Pavilion

Unique Ability:
The Show Must Go On

Unique Unit:
Carnival Crew
Replaces Worker

Unique Building:
Ticket Office
Replaces Market

Primary Victory:
Culture

Secondary Victory:
Science

Implementation Complexity:
Intermediate (3/5)

Theme:
A whimsical wandering civilization of performers, acrobats, musicians, stagehands, entertainers and merchants.

Its workforce can travel between cities to activate temporary festivals, providing Culture, Gold and Production.

Gameplay should revolve around deciding when civilian units should develop infrastructure and when they should return to settlements to host performances.

The civilization should be mechanically simple to understand but rewarding to optimize.

There is no permanent empire-wide festival.

Festivals are local and managed separately in each city.

==================================================
4. UNIQUE ABILITY
THE SHOW MUST GO ON
==================================================

EXACT DESIGN:

When a Carnival Crew ends its turn inside a city owned by The Wandering Circus, that city may begin a Grand Festival.

A Grand Festival lasts three owner-turns.

During the festival, the city receives:

+3 Culture
+2 Gold

A city may begin another festival no earlier than 12 owner-turns after its previous festival began.

Multiple Carnival Crews do not stack the festival.

One festival per city at a time.

A Carnival Crew is NOT consumed when activating a festival.

A Carnival Crew may leave the city after triggering the festival.

The festival continues until its normal expiration, even if no Carnival Crew remains in the city.

The cooldown is attached to the CITY, not the unit.

Every city maintains independent festival timing.

The Capital may also host festivals.

==============================
4A. EXACT FESTIVAL TIMING
==============================

This section is especially important.

Define owner-turn T as the start of the Wandering Circus player's turn when a qualifying crew is detected.

A crew that ended the previous owner-turn inside a friendly city can activate a festival at the start of owner-turn T.

Do not trigger festivals immediately during mid-turn movement.

When a festival activates at T:

T: Festival ACTIVE
T+1: Festival ACTIVE
T+2: Festival ACTIVE
T+3: Festival INACTIVE

The same city cannot begin another festival before T+12.

T+11: Still on cooldown.
T+12: Eligible to activate again.

The 12-turn interval is counted FROM THE INITIAL ACTIVATION, not from the end of the festival.

A Carnival Crew must be inside the city at the next eligible owner-turn for a new festival to begin.

If a Carnival Crew stays permanently in the city, it automatically triggers a new festival at the first eligible turn.

Example:

Turn 20:
Festival begins.

Turns 20, 21, 22:
+3 Culture and +2 Gold.

Turn 23:
Festival bonuses disappear.

Turns 23 through 31:
No festival.

Turn 32:
Festival may begin again if a Carnival Crew is present.

Turns 32, 33, 34:
New festival active.

Turn 35:
Bonuses disappear.

Repeat.

Exact boundary conditions matter.

Never allow a festival to last four turns.

Never allow activation at T+11.

Never delay a valid new festival until T+13.

==============================
4B. FESTIVAL CONDITIONS
==============================

A festival can activate only if:

1. The owning civilization is The Wandering Circus.
2. The city is owned by that civilization.
3. At least one Carnival Crew belonging to the same player occupies the city-center plot at the beginning of the owner's turn.
4. The city's cooldown has expired.
5. The city is not already hosting a festival.

Only the unique Carnival Crew can activate festivals.

Ordinary Workers do not qualify.

Captured foreign Workers do not qualify.

Units merely passing through a city do not qualify unless they end the previous owner-turn there.

Multiple qualifying Carnival Crews produce exactly one festival.

No extra Culture, Gold, duration or cooldown reduction is granted by multiple crews.

==============================
4C. FESTIVAL YIELDS
==============================

Implement the following flat city yields:

+3 Culture
+2 Gold

These are normal city yields, not immediate one-time rewards.

They must appear in the city's actual economy and contribute to its relevant totals.

Do not grant the bonuses directly every turn using accumulated yield functions.

Prefer native city-yield dummy buildings.

The festival does not produce:
- Happiness
- Tourism
- Faith
- Science
- Great Person Points
- Golden Age Points
- Free units

Do not add any of these mechanics.

==================================================
5. FESTIVAL STATE AND PERSISTENCE
==================================================

The festival system must survive saving and loading.

Do not keep the authoritative festival state exclusively in Lua variables.

Use persistent native game state.

Preferred approach:
Invisible, unbuildable dummy buildings.

Suggested marker data:

A. Festival expiration marker.

Stores the exclusive festival expiration owner-turn.

If festival starts at T, its expiration boundary is T+3.

B. Next eligibility marker.

Stores the earliest owner-turn on which another festival may begin.

If festival starts at T, next eligible turn is T+12.

C. Optional last-evaluated-turn marker.

Prevents duplicate processing of the same owner-turn when necessary.

Encode absolute turn markers consistently, taking care that zero can represent an unset marker.

Do not decrement a cooldown based on how often an event happens.

Do not use transient Lua counters whose values would be lost on save/load.

When refreshing a city:

Determine whether its festival is active from the persisted state and verified current turn.

Apply the correct yield buildings.

Remove yield buildings when the festival is inactive.

Only begin a new festival during the verified owner-turn activation phase.

Do not allow unrelated city-dirty events to initiate festivals midway through a turn.

Suggested yield buildings:

BUILDING_WCIRCUS_FESTIVAL_YIELDS
  +3 Culture
  +2 Gold

BUILDING_WCIRCUS_TICKET_PRODUCTION
  +2 Production

Keep these effects separate.

Festival yield dummy count:
0 or 1.

Ticket Production dummy count:
0 or 1.

Never increase either above one.

The persistent timing markers should provide no yields, no normal buildings, and no economic benefits.

All dummies should be:
- Unbuildable
- Unpurchasable
- Hidden from Civilopedia/build lists
- Non-capturable
- Non-transferable
- Zero maintenance
- Free from construction rewards
- IsDummy where supported

Verify native CP v151 treatment of dummy buildings and building counts.

==============================
5A. EVENT TIMING VERIFICATION
==============================

Inspect CP v151 source behavior for:

GameEvents.PlayerDoTurn

and any relevant alternative turn-start hooks.

Determine whether the event fires before or after the native economic processing that awards city yields.

This must not be guessed.

Our required behavior is:

A festival activated at the start of owner-turn T must provide the intended yields during T, T+1 and T+2.

It must not provide yields during T+3.

If PlayerDoTurn happens at an unsuitable point in the native turn cycle, use another verified hook or a carefully designed phase-correct implementation.

Do not silently accept a one-turn delay or an additional payout.

Document the verified event order.

Where runtime behavior cannot be proven without launching Civ V, explicitly flag it for manual testing.

==============================
5B. CITY OWNERSHIP CHANGES
==============================

Handle:

- City capture
- City gifting
- City liberation
- City razing
- City destruction
- Civilization elimination
- Save/load
- Scripted city ownership transfers

If a Wandering Circus city is captured, all existing festival state must be cleared.

The new owner must not inherit:
- Festival Culture
- Festival Gold
- Conditional Ticket Office Production
- Previous festival duration
- Previous cooldown

When a city is transferred back to the Wandering Circus, it starts with no active festival and no inherited cooldown.

A new festival may activate normally at a qualifying future owner-turn.

Avoid accessing invalid or deleted City userdata.

==================================================
6. UNIQUE UNIT
CARNIVAL CREW
==================================================

Replaces:
Worker

EXACT ABILITIES:

Retains all normal Worker properties from the active Community Patch.

+1 Movement relative to the normal Worker.

May initiate a Grand Festival through the Unique Ability.

No other numerical bonuses.

Specifically:

Do NOT grant:
- +25% Work Rate
- Combat Strength
- Defensive bonuses
- Extra Sight
- Free promotions unrelated to movement
- Happiness
- Special build actions
- Free festivals without city presence

The Carnival Crew remains a civilian Worker replacement.

It should retain:
- Worker build actions
- Road construction
- Improvement construction
- Repair actions
- Normal terrain restrictions
- Normal capture behavior
- Standard Worker upgrade progression, if applicable
- Existing CP movement/building rules
- Correct civilian unit AI roles and class behavior

IMPLEMENTATION:

Clone the active UNIT_WORKER definition.

Set the Carnival Crew movement value equal to the inherited Worker movement plus one.

Do not assume the Worker has a particular hardcoded movement value.

Use:
Civilization_UnitClassOverrides

for the Worker replacement.

Clone all relevant companion data, including:
- Unit_Builds
- Unit_AITypes
- Unit_Flavors
- Unit_FreePromotions
- Resource requirements
- Upgrade-related data
- CP-specific companion records

Follow the repository's existing inheritance strategy.

If the active CP Worker possesses additional modded properties, preserve them.

Starting Workers created through the usual Worker unit class should resolve to the Carnival Crew where appropriate.

A Carnival Crew must be recognized by its specific unit type, not simply by civilian status.

==================================================
7. UNIQUE BUILDING
TICKET OFFICE
==================================================

Replaces:
Market

EXACT ABILITIES:

Retains all normal Market benefits from the active Community Patch.

Additional permanent effect:

+1 Culture.

Additional conditional effect:

While the city hosts an active Grand Festival:
+2 Production.

The Production effect ends immediately upon festival expiration at the correct owner-turn boundary.

Only one conditional Production bonus is allowed per city.

It does not stack with:
- Additional Carnival Crews
- Multiple attempts to trigger a festival
- Repeated Lua events
- Reloading a save

If the Ticket Office is removed or destroyed, its conditional Production bonus must disappear.

The Grand Festival itself continues normally.

Similarly, constructing a Ticket Office during an existing festival should activate its Production bonus while the festival remains active.

The Ticket Office does not change:
- Festival duration
- Festival cooldown
- Festival activation requirements
- Carnival Crew movement
- The amount of Culture or Gold from the UA

==============================
7A. BUILDING IMPLEMENTATION
==============================

Clone BUILDING_MARKET from the active CP database.

Preserve:
- Building class
- Technology prerequisite
- Production cost
- Maintenance
- Base yields
- Trade-related benefits
- Specialist effects
- Building modifiers
- All other active CP-specific bonuses

Copy relevant companion records.

Add the permanent +1 Culture through Building_YieldChanges.

If the Market already has Culture in the active CP version, increase that Culture by one rather than replacing the existing value.

Use a separate conditional Production dummy.

The Ticket Office itself should not have an unconditional +2 Production bonus.

Apply the Production dummy only when:

The city is owned by the Wandering Circus
AND
The city has a Ticket Office
AND
The city is hosting an active Grand Festival.

Otherwise:
Remove the conditional Production dummy.

==================================================
8. EXPECTED NUMERICAL RESULTS
==================================================

The following results are mandatory.

EXAMPLE A:
City without an active festival or Ticket Office.

Unique bonuses:
0 Culture
0 Gold
0 Production

EXAMPLE B:
City with active festival but no Ticket Office.

Unique bonuses:
+3 Culture
+2 Gold
+0 Production

EXAMPLE C:
City with Ticket Office but no festival.

Unique bonuses:
+1 Culture
+0 Gold
+0 Production

EXAMPLE D:
City with Ticket Office and active festival.

Unique bonuses:
+4 Culture
+2 Gold
+2 Production

These values exclude the Market's preserved baseline benefits.

EXAMPLE E:
Two cities hosting active festivals.

Total UA bonuses:
+6 Culture
+4 Gold

If both have Ticket Offices, add:
+2 permanent Culture across the two Offices
+4 conditional Production.

EXAMPLE F:
Six cities simultaneously hosting festivals.

Total UA bonuses:
+18 Culture
+12 Gold

If all six cities have Ticket Offices:

+12 conditional Production
+6 permanent Culture

Never multiply Production by the number of Carnival Crews.

==================================================
9. LEADER AND CIVILIZATION PRESENTATION
==================================================

Leader:
Ringmaster Aurelio

Personality:
Charismatic, theatrical, friendly, curious, and commercially minded.

Appearance:
A flamboyant ringmaster wearing an elaborate red ceremonial coat, tall black top hat, and golden gloves.

Diplomatic setting:
A spectacular circus tent with velvet curtains, lanterns, and performers in the background.

Leader dialogue should be whimsical but polished.

Suggested greeting:

"Welcome, welcome! A thousand greetings to our distinguished guest! Tell me, have you come for diplomacy, or would you prefer front-row seats?"

War declaration:

"Ladies and gentlemen! For our next spectacular performance... THE FALL OF AN EMPIRE!"

Defeat:

"The lights grow dim... the audience departs... but somewhere, someday, the show will begin again."

Write additional suitable peace and diplomacy responses.

Do not reuse another civilization's visible diplomacy text.

==================================================
10. DAWN OF MAN
==================================================

Use the following introductory text:

"Magnificent Ringmaster Aurelio, the world awaits your greatest performance!

Throughout history, kings have raised armies, emperors have constructed monuments, and scholars have sought the mysteries of existence.

But your people have discovered something equally powerful.

Joy.

Your traveling performers have crossed mountains, deserts and oceans, bringing laughter to those who have forgotten how to smile.

Now, the greatest stage of all awaits you.

Raise your tents. Gather your performers. Let every city hear the sound of celebration.

Will your civilization become the greatest spectacle the world has ever witnessed?"

Ensure correct Civ V localization formatting, including paragraph breaks.

Include:
- Civilization history
- Leader biography
- Civilopedia entries
- UA description
- Carnival Crew description
- Ticket Office description
- Gameplay strategy
- Leader greeting
- War declaration
- Defeat response
- Peace responses

==================================================
11. CITY NAMES
==================================================

Use:

1. Grand Pavilion
2. Laughing Hollow
3. Golden Tent
4. Moonlit Stage
5. Velvet Arcade
6. Lantern Square
7. Ringmaster's Rest
8. Starlight Fair
9. Tumbler's Crossing
10. Highwire Haven
11. Jubilee Fields
12. Silver Carousel
13. Masquerade Point
14. Festival Hollow
15. Brightwater Fair
16. Firelight Grove
17. Marvelous Mile
18. Crimson Canopy
19. Encore Harbor
20. Wonderwick
21. Golden Carousel
22. Moonbeam Circus
23. Mirthborough
24. Final Encore

Create original thematic spy names as well.

==================================================
12. ART AND ASSETS
==================================================

Provide an appropriate civilization icon, leader portrait, Dawn of Man artwork, map image, unique unit icon, unit flag, and Ticket Office icon.

Suggested visual identity:

Primary:
Deep crimson

Secondary:
Warm gold

Accent:
Midnight blue

Visual motifs:
- Circus tents
- Stars
- Spotlights
- Golden tickets
- Carousels
- Lanterns
- Musical instruments

Use the repository's existing DDS/atlas generation pipeline where possible.

Provide suitable resolutions and atlas registrations.

A custom 3D Carnival Crew model is optional.

Reusing a compatible Worker 3D model is acceptable.

A custom building model is not necessary.

If original art cannot be generated, use clearly documented compatible placeholders rather than pretending missing assets exist.

Ensure:
- Correct icon atlas dimensions
- Correct PortraitIndex values
- Correct DDS formats
- No missing art paths
- No missing TXT_KEY values
- No invalid unit flag references

==================================================
13. PERFORMANCE AND LUA ARCHITECTURE
==================================================

Prefer a dedicated Lua module.

Keep state and helpers local.

Avoid global namespace pollution.

Use event-driven updates.

The main activation check should occur at a verified beginning-of-owner-turn phase.

Additional events may reconcile bonus state after:
- Ticket Office construction
- Ticket Office removal
- City capture
- City transfer
- Game loading
- Other relevant building-state changes

Do not start new festivals from generic dirty-data events.

Use absolute building counts.

Example expected behavior:

If a festival is active:
Set festival yield dummy count to 1.

If inactive:
Set festival yield dummy count to 0.

If festival is active and the city has a Ticket Office:
Set production dummy count to 1.

Otherwise:
Set production dummy count to 0.

Only call SetNumRealBuilding when the count actually needs changing.

Where supported, use the native no-construction-bonus argument for dummy updates.

Avoid:
- GameEvents or Events subscriptions registered twice
- Infinite callback loops
- Permanent ContextPtr:SetUpdate polling
- Frame-based timers
- Frequent full-map scans
- Repeated City object caching across turns
- Accumulating yields directly instead of deriving them from state

The implementation should remain performant on Huge maps with many civilizations and cities.

==================================================
14. CP v151 COMPATIBILITY AUDIT
==================================================

Verify against the actual Community Patch v151 schema and, where available, corresponding source.

Check:

1. Worker scalar movement fields.
2. Worker companion-table inheritance.
3. Market scalar properties and yield companions.
4. Festival dummy-building yield processing.
5. Dummy-building persistence through saves.
6. SetNumRealBuilding count semantics.
7. PlayerDoTurn ordering relative to economic yields.
8. City capture and ownership-change event signatures.
9. City-center plot unit iteration.
10. GetGameTurn behavior in player turn processing.
11. UI addin registration and Lua 5.1 compatibility.
12. Building-construction and building-removal hooks.

Do not assume an undocumented event or function exists.

If native source inspection reveals that a chosen hook is unsuitable, select an alternative that preserves the mechanic.

Explicitly explain any unavoidable engine limitation.

Do not change the requested festival timing merely to simplify implementation.

==================================================
15. SAVE/LOAD TESTING
==================================================

Test the following:

A. Save with an inactive festival.

Reload:
No festival bonuses should appear unexpectedly.

B. Save on the first festival turn.

Reload:
Festival timing remains correct.

C. Save on the second festival turn.

Reload:
One intended owner-turn of festival remains after the current one, according to the documented turn-phase semantics.

D. Save on the third festival turn.

Reload:
Festival expires on the next required boundary.

E. Save during cooldown.

Reload:
Cooldown is preserved exactly.

F. Save immediately before the next eligible turn.

Reload:
Festival can reactivate on schedule.

G. Save with several cities having different festival states.

Reload:
Every city retains its independent timing.

H. Reload with a Carnival Crew still stationed in a city.

Ensure reloading does not cause an additional immediate festival or reset the cooldown.

==================================================
16. FUNCTIONAL TEST MATRIX
==================================================

Create automated Lua 5.1 simulations using the repository's existing testing conventions.

Test:

1. New civilization registration.
2. Unique Worker replacement.
3. Carnival Crew +1 Movement.
4. Worker build-action inheritance.
5. Unique Market replacement.
6. Permanent Ticket Office Culture.
7. Festival activation.
8. Festival yields.
9. Exactly three active turns.
10. Expiration at T+3.
11. No reactivation at T+11.
12. Reactivation eligibility at T+12.
13. Multiple Carnival Crews in one city.
14. One Crew visiting multiple cities.
15. Crew leaving after activation.
16. Crew remaining inside a city.
17. Crew captured during a festival.
18. Crew moving through a city without ending a turn.
19. Festival running without Ticket Office.
20. Ticket Office built during a festival.
21. Ticket Office removed during a festival.
22. Multiple simultaneous festivals.
23. Independent city cooldowns.
24. City capture.
25. City gifting.
26. City liberation.
27. City razing.
28. Player elimination.
29. Save/load on different festival turns.
30. Repeated event invocation.
31. Multiple same-turn refreshes.
32. Missing or invalid player/city references.
33. Preservation of existing civilizations.
34. Database integrity.
35. Modinfo registration.
36. Art atlas registration.
37. English localization.
38. Quick game speed.
39. Standard game speed.
40. Epic game speed.
41. Marathon game speed.
42. A custom modded game speed.

Festival duration and cooldown are fixed game-turn quantities.

Do not scale 3 or 12 using game-speed multipliers.

Where tests use mocks, make clear they are simulations rather than native engine verification.

==================================================
17. MANUAL IN-GAME ACCEPTANCE
==================================================

Provide a practical test plan for launching Civ V.

At minimum, verify:

- Wandering Circus appears in civilization selection.
- Ringmaster Aurelio displays correctly.
- Grand Pavilion is the starting capital.
- Starting and trained Worker-class units become Carnival Crews as appropriate.
- Carnival Crew has exactly +1 Movement.
- Carnival Crew retains normal improvements.
- Market is replaced with Ticket Office.
- Ticket Office retains normal Market effects.
- Active festival yields appear correctly.
- Actual per-turn Culture and Gold totals match the expected bonuses.
- Ticket Office Production activates only during festivals.
- Ending a festival removes the correct bonuses.
- Cooldowns remain accurate across save/load.
- Multiple cities function independently.
- Other civilizations do not receive circus bonuses.
- Existing Boundless City and Republic of Pigeons mechanics still function.

Check:
Database.log
Lua.log
xml.log

Add useful debug logging behind a disabled-by-default debug flag.

Do not repeatedly print logs every frame.

==================================================
18. REPOSITORY INTEGRATION
==================================================

Integrate the civilization into the existing CoolWackyCivs2 collection.

Update as necessary:
- ModBuddy project
- Modinfo
- SQL load order
- Art import registrations
- Lua UI entry points
- Localization
- Build tooling
- Manifest generation
- Validation scripts
- Civilization roster documentation
- Root README
- Changelog

Keep the existing collection architecture.

Retain the same collection identity.

Do not break old civilizations or rename existing identifiers.

Avoid unexpected changes to:
TheBoundlessCity
TheRepublicOfPigeons

Do not copy another civilization's runtime global namespace.

Use a unique WCIRCUS identifier namespace.

Retain appropriate existing BNW/Community Patch dependencies.

If a mod version change has save compatibility implications, document them clearly.

Do not claim compatibility with old saves without testing.

==================================================
19. FINAL DELIVERABLE
==================================================

Make the changes directly in the repository.

When finished, provide:

1. Implementation summary.
2. All created/modified file paths.
3. Explanation of the festival timing system.
4. Explanation of festival persistence.
5. Exact dummy-building structure.
6. Carnival Crew inheritance verification.
7. Ticket Office inheritance verification.
8. CP v151 compatibility findings.
9. Automated test results.
10. Tests that still require launching Civ V.
11. Performance considerations.
12. Save compatibility limitations.
13. Build and installation instructions.
14. Outstanding issues, if any.

Do not stop after generating skeleton files.

Produce the complete functional implementation.

Do not claim success if the actual implementation is incomplete.

==================================================
20. NON-NEGOTIABLE DESIGN SUMMARY
==================================================

Civilization:
The Wandering Circus

Leader:
Ringmaster Aurelio

UA:
The Show Must Go On

Carnival Crew ends previous turn in friendly city:
Can activate a Grand Festival at the start of the next owner-turn.

Festival:
Exactly 3 owner-turns.

Festival yields:
+3 Culture
+2 Gold

Cooldown:
12 owner-turns between activation starts.

Earliest next activation:
T+12.

Multiple crews:
No stacking.

Crew departure:
Festival continues.

UU:
Carnival Crew replaces Worker.
All normal Worker properties.
+1 Movement.
No additional Work Rate bonus.

UB:
Ticket Office replaces Market.
All normal Market properties.
+1 permanent Culture.
+2 Production during active festivals.

Settings:
Playable=1
AIPlayable=0

Target:
Civilization V BNW + Community Patch v151.

No DLL modifications.

No new gameplay mechanics.

Preserve EXACTLY this civilization's intended behavior.

The completed result should be fun, polished, save-safe, performant, and ready to play alongside the existing CoolWackyCivs2 civilizations.
