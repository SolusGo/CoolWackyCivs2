
Implement a complete new Civilization V: Brave New World civilization in the existing repository:

https://github.com/SolusGo/CoolWackyCivs2

CIVILIZATION: The Republic of First Drafts
LEADER: Editor-in-Chief Marginalia
CAPITAL: First Edition

UA: Nothing Is Ever Final
UU: Ink Mortar (replaces Catapult)
UB: Revision Workshop (replaces Workshop)

Compatibility: Civilization V BNW + Community Patch v151 ONLY.
Playable=1
AIPlayable=0
Target complexity: Intermediate (3/5).
Preferred victory: Science / Culture.

IMPORTANT: I want the actual implementation, not pseudocode, a design proposal, or a collection of suggestions.

Create and modify the necessary repository files directly. Implement complete, working SQL/XML/Lua integrations, localization, art registration, and tests.

Do not introduce additional gameplay mechanics, rebalance the requested numbers, or make the civilization dependent on Vox Populi.

============================================================
1. REPOSITORY INTEGRATION
============================================================

FIRST inspect the repository's actual structure.

At the time of this request, Wacky2 contains independently organized civilization folders such as:

- TheHoneycombCommonwealth/
- TheConicalUnion/
- TheBoundlessCity/
- TheRepublicOfPigeons/

The project currently uses:

- Cool Wacky Civs 2 (v 19).modinfo
- CoolWackyCivs2.civ5proj
- Shared/
- Civilization-specific SQL, Lua, Art and documentation folders.

Verify the current filenames before changing anything.

Create a new dedicated folder:

TheRepublicOfFirstDrafts/

Recommended organization:

TheRepublicOfFirstDrafts/
  SQL/
    00_RFD_Core.sql
    01_RFD_Inheritance.sql
    02_RFD_Effects.sql
    03_RFD_Art.sql
    10_RFD_Text.sql
  Lua/
    RFD_FirstDrafts.lua
    RFD_FirstDrafts.xml
  Art/
  README.md
  CHANGELOG.md
  docs/

Adjust the individual filenames if needed to match established repository conventions.

Use the identifier prefix RFD for every custom database object, Lua controller, saved-data key and art atlas.

Integrate everything into the existing mod.

Requirements:

- Register SQL files in the correct database load order.
- Register the Lua gameplay context correctly.
- Register required art files and VFS settings.
- Update the existing .modinfo rather than creating an unrelated mod.
- Update the existing project references if the repository workflow requires it.
- Preserve all other civilizations.
- Avoid conflicting identifiers and duplicated registrations.
- Avoid unnecessary shared infrastructure changes.
- Do not add new external dependencies.
- Do not create a separate ModBuddy solution.
- Keep gameplay code inside the new civilization's folder where practical.

Do not assume that the current repo uses a generic Civ V implementation pattern. Inspect existing working implementations and copy their proven registration conventions.

============================================================
2. CIVILIZATION IDENTITY
============================================================

Civilization:
The Republic of First Drafts

Leader:
Editor-in-Chief Marginalia

Capital:
First Edition

Unique Ability:
Nothing Is Ever Final

Unique Unit:
Ink Mortar

Unique Building:
Revision Workshop

Theme:

A republic of writers, architects, engineers, scholars and publishers who believe that no creation is truly complete.

Its government rewards experimentation, architectural diversity and continuous revision.

Its military employs mechanical siege engines that launch enormous barrels of black ink.

Its greatest institution is the Editorial Department.

Its philosophy:

"Nothing Is Ever Final."

Create all standard Civ V civilization and leader registrations.

Provide:

- Civilization definition
- Leader definition
- Leader trait
- Civilization_Leaders mapping
- Leader_Traits mapping
- Unit class override
- Building class override
- City names
- Spy names
- Civilization colors
- Diplomacy text
- Civilopedia text
- Unique ability help text
- Unique unit help text
- Unique building help text
- Dawn of Man description

Use Playable=1 and AIPlayable=0.

Lua gameplay effects must only activate for an eligible human player using this civilization.

============================================================
3. UNIQUE ABILITY: NOTHING IS EVER FINAL
============================================================

CORE MECHANIC:

The first time the Republic possesses a new qualifying Building Class, award:

+12 Culture
+20 Gold

These values are for Standard speed.

Each qualifying Building Class rewards the civilization ONCE PER GAME.

The reward is empire-wide, not per city.

Examples:

First Monument:
+12 Culture / +20 Gold

First Granary:
+12 Culture / +20 Gold

First Shrine:
+12 Culture / +20 Gold

Second Monument:
No reward

First Library:
+12 Culture / +20 Gold

Second Library:
No reward

First Workshop or Revision Workshop:
+12 Culture / +20 Gold

If five distinct qualifying Building Classes are acquired on Standard speed, total lifetime rewards are:

+60 Culture
+100 Gold

Do not interpret "distinct buildings" as different individual building types or repeated copies.

The ledger MUST be keyed by Building Class.

Unique buildings count under their replacement Building Class.

For example:

Revision Workshop = BUILDINGCLASS_WORKSHOP

Do not award a separate reward for both the normal Workshop class and its unique replacement.

------------------------------------------------------------
3A. BUILDING ELIGIBILITY
------------------------------------------------------------

Only normal, constructible, non-wonder Building Classes qualify.

Exclude:

- World Wonders
- National Wonders
- Team Wonders, if applicable
- Palace
- Dummy buildings
- Hidden gameplay-control buildings
- Nonconstructible special buildings
- Any buildings not meeting the intended constructible-class eligibility rules

Buildings bought with Gold or Faith can count when otherwise eligible.

Free, gifted, and captured qualifying buildings can count.

A qualifying building does not have to be completed by normal Production.

Use the actual active CP v151 building database to identify eligibility.

Inspect:

- Buildings
- BuildingClasses
- BuildingClass relationships
- Constructibility flags
- Wonder instance limits
- Dummy flags
- Other applicable CP-specific properties

Do not assume that checking a single Cost column is sufficient for every valid building.

Use one centralized eligibility function or lookup shared by the UA and UB.

The eligibility decision must be based on actual building definitions and not a manually maintained shortlist.

Ensure new custom hidden buildings from other Wacky2 civilizations cannot accidentally count.

------------------------------------------------------------
3B. REWARD TIMING
------------------------------------------------------------

Rewards occur at the next verified owner-turn evaluation after acquiring a building.

At the evaluation:

1. Enumerate the Republic's current cities.
2. Read the currently possessed qualifying buildings.
3. Resolve each building to its Building Class.
4. Build the set of currently possessed qualifying classes.
5. Compare against the permanently rewarded class ledger.
6. Award the rewards for each newly discovered class.
7. Record all newly rewarded classes permanently.

A building must still be present at the evaluation to count.

A building acquired and removed completely between evaluations must not qualify.

Use a verified CP v151-compatible owner-turn hook.

Avoid per-frame polling.

If event-driven updates are used, they must complement rather than replace the authoritative owner-turn evaluation.

------------------------------------------------------------
3C. GAME SPEED SCALING
------------------------------------------------------------

The UA rewards scale with the active game's construction-speed percentage.

Standard values:

Culture = 12
Gold = 20

Formula:

CultureReward =
round(12 * ConstructionPercent / 100)

GoldReward =
round(20 * ConstructionPercent / 100)

Read ConstructionPercent from the actual active game-speed definition.

Do not hardcode Standard, Epic or Marathon multipliers.

Use positive-number rounding to the nearest whole yield.

Each newly discovered class receives one individually scaled reward.

For multiple classes discovered together, sum the individual scaled rewards.

Verify the actual Civ V API and GameSpeeds database field before using it.

Test Standard and Marathon specifically.

------------------------------------------------------------
3D. PERMANENT SAVE PERSISTENCE
------------------------------------------------------------

THIS IS A CRITICAL REQUIREMENT.

The awarded Building Class ledger must persist through:

- Save/load
- Game restarts
- Turn transitions
- City capture
- City destruction
- City sale or razing
- Building sale
- Building removal
- Building reconstruction
- City recapture

Never use ordinary Lua globals as the only persistent record.

Use a verified save-scoped persistence method compatible with BNW and CP v151.

Inspect existing Wacky2 scripts for persistence patterns, including carefully namespaced Player ScriptData or another verified mechanism.

Do not overwrite unrelated ScriptData belonging to other civilizations or systems.

A Building Class already rewarded is permanently exhausted.

Even if the Republic loses all copies of that building and later reconstructs it, no new reward is granted.

Example:

Turn 40:
Construct Monument.
Receive +12 Culture / +20 Gold.

Turn 50:
Sell Monument.

Turn 60:
Construct Monument again.

Result:
No additional reward.

A save/reload between these turns must not change the result.

Avoid duplicate payouts from multiple callbacks, repeated context initialization or overlapping turn-event handlers.

If your implementation needs a journal or idempotency mechanism for safe payouts, implement one consistent with the actual Civ V APIs.

Do not use an unsafe increment-only counter.

------------------------------------------------------------
3E. EXISTING SAVES
------------------------------------------------------------

The implementation must handle initialization in an existing game.

If this civilization's persistent ledger does not exist when an already-progressed save is initialized:

- Detect already-owned qualifying classes.
- Seed those classes into the permanent ledger.
- Do not grant retroactive rewards.
- Continue normally for future first-time classes.

Distinguish this situation from a genuinely new game where qualifying buildings should naturally be rewarded as they are first acquired.

Do not reset the ledger if the Lua context is reloaded.

Document how the initialization distinction is handled.

============================================================
4. UNIQUE UNIT: INK MORTAR
============================================================

Replaces:
Catapult

Identity:
A mobile mechanical siege weapon that launches barrels of industrial black ink.

STATS:

Combat Strength:
Same as the active CP Catapult.

Ranged Strength:
Same as the active CP Catapult.

Movement:
Active CP Catapult movement +1.

Sight:
Active CP Catapult sight +1.

Range:
Same as active CP Catapult.

Setup requirements:
Preserved.

Siege properties:
Preserved.

Upgrade path:
Preserved.

Strategic resource requirements:
Preserved.

Production cost:
Preserved.

Maintenance:
Preserved.

All other baseline Catapult properties:
Preserved.

IMPORTANT:

The Ink Mortar is NOT supposed to receive additional city damage.

It does NOT bypass walls.

It does NOT apply a unique ink debuff.

It does NOT have a special ranged attack effect.

It cannot freely attack after moving unless that is already permitted by the inherited CP Catapult rules.

The defining benefit is improved battlefield positioning and awareness.

------------------------------------------------------------
4A. CATAPULT INHERITANCE
------------------------------------------------------------

Inspect the active Catapult definition.

Clone the Catapult into:

UNIT_RFD_INK_MORTAR

Preserve compatible records from relevant companion tables, including:

- Unit promotions
- Unit AI registrations
- Upgrade relationships
- Required resources
- Combat data
- Other active CP companion records

Do not blindly duplicate primary keys or unique constraints.

Use the correct schema and avoid assuming vanilla-only columns.

Increase Moves by exactly 1 over the active Catapult.

For Sight, create a unique free promotion providing +1 VisibilityChange.

Example identifier:

PROMOTION_RFD_INK_MORTAR_SIGHT

The promotion should be nonselectable and should not unintentionally provide a permanent sight bonus to unrelated upgraded units.

Preserve the original Catapult's normal free promotions.

Make sure promotions and the sight effect work immediately when the unit is created or purchased.

Register the unit using:

Civilization_UnitClassOverrides

Use the standard Catapult 3D model if no fully working custom unit model is supplied.

Custom model creation is not required.

Provide functional unit icon and unit flag art registration.

============================================================
5. UNIQUE BUILDING: REVISION WORKSHOP
============================================================

Replaces:
Workshop

The Revision Workshop is a government-controlled engineering and architectural institution dedicated to improving construction designs.

It retains every ordinary Workshop benefit from the active Community Patch.

ADDITIONAL EFFECTS:

+1 Culture

+1 Science for every 4 distinct qualifying Building Classes currently present in the city.

Science bonus capped at +3.

Formula:

ScienceBonus =
min(3, floor(DistinctQualifyingClasses / 4))

Thresholds:

0-3 classes:
+1 Culture, +0 Science

4-7 classes:
+1 Culture, +1 Science

8-11 classes:
+1 Culture, +2 Science

12 or more classes:
+1 Culture, +3 Science

Important:

The Revision Workshop itself counts as one qualifying Building Class.

The +1 Culture is a permanent part of the Revision Workshop's normal yields while the building exists.

The Science effect is dynamic and must be recalculated.

Example:

City contains nine qualifying classes, including the Revision Workshop.

Result:
+1 Culture
+2 Science

Another city has five classes including the Revision Workshop.

Result:
+1 Culture
+1 Science

These are additional to all normal CP Workshop benefits.

------------------------------------------------------------
5A. WORKSHOP INHERITANCE
------------------------------------------------------------

Clone the active CP Workshop rather than reconstructing it from remembered vanilla values.

Use:

BUILDING_RFD_REVISION_WORKSHOP

Preserve:

- Cost
- Maintenance
- Specialist slots
- Production bonuses
- Existing yields
- Prerequisite technology
- Specialist-related effects
- Building requirements
- Other active CP Workshop properties
- Compatible companion-table records

Add exactly +1 Culture.

If the inherited Workshop already has a Culture yield entry, increment that entry appropriately.

Otherwise create the needed entry.

Never accidentally replace an existing Workshop yield with a fixed value.

Register the building using:

Civilization_BuildingClassOverrides

It must satisfy ordinary Workshop construction and purchase requirements.

------------------------------------------------------------
5B. DYNAMIC SCIENCE
------------------------------------------------------------

Implement the Science bonus through a verified method compatible with CP v151.

Preferred method:

Create three hidden dummy buildings, each producing +1 Science.

Suggested identifiers:

BUILDING_RFD_SCIENCE_1
BUILDING_RFD_SCIENCE_2
BUILDING_RFD_SCIENCE_3

Each dummy is a hidden, nonconstructible, nonpurchasable, non-wonder internal building.

It must not be capturable or grant any other gameplay benefits.

Use the existing Wacky2 hidden-dummy conventions.

For each city with a Revision Workshop:

Count distinct qualifying Building Classes currently possessed.

Calculate the target Science bonus between 0 and 3.

Set the appropriate dummy buildings to represent that exact amount.

Do not add dummies cumulatively each turn.

Do not increment bonus yields without checking current state.

If using three binary dummy buildings, the total dummy Science yield must equal the target exactly.

If another verified implementation is safer, use it and explain why.

------------------------------------------------------------
5C. RECALCULATION
------------------------------------------------------------

Recalculate when relevant city buildings change, including:

- Production completion
- Purchase
- Free building acquisition
- City capture
- City recapture
- Building sale
- Building removal
- Revision Workshop construction
- Revision Workshop removal

Use supported event hooks when possible.

Also use a reliable owner-turn fallback scan.

If a city loses qualifying buildings, its Science bonus must decrease.

Example:

City has 8 qualifying classes:
+2 Science.

One building is removed:
7 classes remain.
Science becomes +1.

Another building is removed:
6 classes remain.
Science remains +1.

No old bonus may remain incorrectly.

When the Revision Workshop is removed, clear all of its associated Science dummies.

On city capture, ensure hidden buildings cannot leak benefits to a civilization that does not have the correct UB.

When a city is acquired by the Republic, calculate the new appropriate bonus.

Ensure city identity is handled safely during capture, razing and recapture.

Avoid applying effects to stale city objects.

The dummy buildings themselves must never count as qualifying classes.

============================================================
6. LUA SAFETY AND PERFORMANCE
============================================================

The Republic is human-only.

Use efficient event handlers.

Requirements:

1. Resolve all necessary GameInfoTypes safely.
2. Check the player civilization before running expensive logic.
3. Check that the player is alive and eligible.
4. Avoid duplicate Lua event registration.
5. Avoid per-frame processing.
6. Avoid recursive updates caused by dummy building changes.
7. Use deterministic building-class resolution.
8. Keep the permanent UA ledger separate from dynamic UB yields.
9. Never reset permanent rewards during dynamic recalculation.
10. Avoid unsupported or unverified API calls.
11. Handle city destruction and transfer.
12. Handle absent data and newly initialized games.
13. Ensure data does not leak between players.
14. Use clear, namespaced diagnostics.
15. Keep the system compatible with existing Wacky2 Lua controllers.

The dynamic building scan may be combined with the permanent UA evaluation for efficiency, but the two systems must remain logically independent.

IMPORTANT:

The permanent UA uses the historical rewarded-class ledger.

The UB uses the city's CURRENT qualifying classes.

Do not use the UA ledger to calculate the city's Science.

A city can benefit from a qualifying building even when the UA reward for that class was earned hundreds of turns earlier.

============================================================
7. ART AND PRESENTATION
============================================================

Provide coherent civilization presentation following the repository's existing DDS and icon-atlas conventions.

Use original art where tooling supports it.

Do not leave broken asset paths, undefined atlases or missing required DDS references.

If a custom image cannot be generated, use an existing valid fallback rather than referencing an absent file. Clearly disclose such fallback art.

CIVILIZATION ICON:

Concept:

- An elegant parchment manuscript.
- A prominent quill pen.
- Ink markings and handwritten corrections.
- Dark burgundy and cream colors.
- Gold outer circular rim.
- Recognizable at small icon sizes.

The icon should communicate writing, invention and endless revision.

LEADER PORTRAIT:

Editor-in-Chief Marginalia is:

- An elderly, distinguished woman.
- Wearing an enormous academic robe.
- Robe decorated with handwritten annotations.
- Wearing slightly crooked spectacles.
- Seated behind a desk covered in unfinished manuscripts.
- Surrounded by towering bookshelves and stacks of rewritten documents.

Visual direction:
Scholarly, eccentric, authoritative, slightly comedic.

DAWN OF MAN IMAGE:

A grand editorial chamber with manuscripts, ornate architecture, parchment, books and intricate construction plans.

Preferred target:
1024x768, consistent with existing project assets.

UNIT ICON:

A heavy wheeled siege engine launching a black ink barrel.

BUILDING ICON:

An ornate workshop with parchment plans, drafting instruments and unfinished architectural blueprints.

Map image:
An appropriate parchment-style map illustration.

Do not make custom 3D unit models a dependency.

Use the existing Civ V Catapult graphics for the in-game Ink Mortar.

Ensure correct art atlases, portrait indices, alpha icons and unit flags.

============================================================
8. CIVILIZATION TEXT
============================================================

Create polished English localization for all necessary identifiers.

UA NAME:
Nothing Is Ever Final

UA HELP:

"The first time your civilization possesses a new qualifying non-wonder Building Class, gain 12 Culture and 20 Gold (scaled by game speed). Each Building Class can grant this reward only once."

Clarify within the Civilopedia that the building must be present at the owner-turn evaluation.

UU NAME:
Ink Mortar

UU HELP:

"Replaces the Catapult. Has +1 Movement and +1 Sight compared to the normal Catapult. Retains normal siege setup requirements, attacks and upgrade paths."

UB NAME:
Revision Workshop

UB HELP:

"Replaces the Workshop. Retains its normal benefits and provides +1 Culture. Gains +1 Science for every 4 distinct qualifying Building Classes currently present in this city, up to +3 Science."

All tooltips must reflect actual implemented mechanics.

Do not claim instant construction-time payouts when the implementation grants them at owner-turn evaluation.

------------------------------------------------------------
8A. DAWN OF MAN
------------------------------------------------------------

Use this text:

"Esteemed Editor-in-Chief Marginalia, First Author of the Republic, your people await your next great revision.

Throughout history, civilizations have constructed monuments, established institutions and recorded their achievements for future generations.

Yet your people have recognized a fundamental truth.

No creation is ever truly complete.

Every building can be improved. Every discovery can be reconsidered. Every great work begins with an imperfect first draft.

Now, the scattered scholars and architects of your Republic have united beneath a common purpose.

Build your cities. Gather your knowledge. Let every new institution become another chapter in the history of your people.

Will you write the greatest civilization the world has ever known?

Or will history remember you as another unfinished manuscript?"

------------------------------------------------------------
8B. DIPLOMACY
------------------------------------------------------------

First greeting:

"Welcome, esteemed visitor! Before we begin negotiations, I must ask you to review the seventeen amendments to our preliminary diplomatic introduction."

Declaration of war:

"Your civilization has been reviewed. Unfortunately, the editorial board has recommended its complete removal."

Defeat:

"I see... perhaps... we should have considered another draft."

Use valid BNW diplomacy response keys following the current repository's implementation patterns.

Additional diplomacy responses may be authored consistently with the character, but do not modify gameplay behavior.

------------------------------------------------------------
8C. CITY NAMES
------------------------------------------------------------

Capital:
First Edition

Create a thematic city list using names such as:

Second Edition
The Red Margin
Footnote Harbor
Inkfall
Revised Heights
The Proofing Grounds
Quillhaven
New Appendix
Errata
The Grand Index
Citation Point
Drafting Hall
The Unfinished Quarter
Margin's End
The Printing District
Bibliograph
Inkspire
Final Proof
The Seventeenth Amendment
Neverending Manuscript

Register them properly as localized city names.

Add unique thematic spy names.

============================================================
9. GAMEPLAY BALANCE
============================================================

Preserve the EXACT numbers.

Do not buff the UA.

Do not add extra Science from the UA.

Do not make the UA scale with empire size.

Do not reward multiple copies of the same Building Class.

Do not buff the Ink Mortar's damage.

Do not remove the Ink Mortar's setup requirement.

Do not increase the Revision Workshop's Science cap.

Do not add new mechanics.

The civilization should remain:

- Strongest in early infrastructure diversification.
- Rewarded for constructing new types of useful buildings.
- Modestly accelerated in early Culture and Gold.
- Encouraged to develop diverse buildings within each city.
- Capable of supporting Science and Culture victories.
- Equipped with a tactically flexible early siege unit.
- Not an overwhelming late-game scaling civilization.

It should remain balanced under Standard-speed games and large Marathon simulations.

This is a modest infrastructure-diversity civilization, not an infinitely stacking economic powerhouse.

============================================================
10. REQUIRED TESTING
============================================================

Provide repeatable tests and validation instructions.

Where the available environment cannot execute Civilization V itself, distinguish static verification from actual in-game testing.

Do not claim to have completed in-game testing unless it was genuinely performed.

TEST A: ONE-TIME REWARDS

Construct first Monument.
Confirm +12 Culture/+20 Gold on Standard.

Construct second Monument.
Confirm no reward.

Construct Granary.
Confirm another +12/+20.

TEST B: MULTIPLE NEW CLASSES

Acquire five distinct qualifying classes.

Total lifetime UA rewards should be:

60 Culture
100 Gold

on Standard speed.

TEST C: SELL AND REBUILD

Construct Monument.
Receive reward.
Sell it.
Reconstruct.

Confirm no additional reward.

TEST D: SAVE/LOAD

Receive a class reward.
Save.
Reload.
Evaluate subsequent turns.

Confirm no duplicate reward.

TEST E: PURCHASED BUILDINGS

Purchase first qualifying building.
Confirm the class counts.

TEST F: CAPTURED BUILDINGS

Capture a city containing a previously unseen qualifying class.

Confirm one reward on the next owner-turn evaluation.

Lose or recapture that city.

Confirm no repeated reward for the same class.

TEST G: WONDERS AND DUMMIES

Acquire Palace, World Wonder, National Wonder or hidden dummy.

Confirm they do not grant UA rewards.

TEST H: REVISION WORKSHOP THRESHOLDS

Verify:

3 classes -> 0 Science
4 classes -> 1 Science
7 classes -> 1 Science
8 classes -> 2 Science
11 classes -> 2 Science
12 classes -> 3 Science
16 classes -> 3 Science

The Workshop itself counts.

TEST I: BUILDING REMOVAL

City has 8 qualifying classes and +2 Science.

Remove one qualifying class.

Confirm the bonus becomes +1 Science.

TEST J: REMOVE WORKSHOP

Remove the Revision Workshop.

Confirm the additional Science immediately or reliably clears at the supported recalculation boundary.

TEST K: DUMMY BUILDING SAFETY

Confirm no dummy building generates a UA reward.

Confirm dummy writes do not recursively trigger runaway events.

Confirm no duplicate dummy yields accumulate.

TEST L: UNIT STATS

Compare the Ink Mortar to the active CP Catapult.

Verify:

+1 Movement
+1 Sight
Same Combat Strength
Same Ranged Strength
Same Range
Same setup requirement
Same upgrade path
Same baseline siege bonuses

TEST M: MARATHON

Verify the active ConstructionPercent is read correctly.

Confirm the one-time Culture and Gold rewards are scaled and rounded correctly.

TEST N: HUMAN ONLY

Verify the civilization appears in the human selection screen.

Verify AIPlayable=0.

Verify the Lua effects are properly guarded.

TEST O: PERSISTENT LEDGER

Save and reload after multiple class discoveries.

Ensure the ledger retains the exact classes previously rewarded.

TEST P: EXISTING SAVE INITIALIZATION

Initialize the system on an already-progressed game with qualifying buildings.

Ensure already-owned classes are seeded without retroactive payouts.

Future new classes should still reward normally.

TEST Q: CITY TRANSFER

Capture or lose a city containing a Revision Workshop.

Ensure Science dummies are never incorrectly retained by the wrong owner.

TEST R: UI AND ART

Check:

- Civilization selection
- Leader portrait
- Civilization icon
- Unit portrait
- Building portrait
- Unit flag
- Dawn of Man
- Civilopedia entries
- Unique ability description
- Unit and building tooltips

TEST S: MULTI-CIV COMPATIBILITY

Verify that other Wacky2 civilizations remain registered.

Verify no SQL, art atlas, Lua global, or save-data collisions occur.

============================================================
11. STATIC VALIDATION
============================================================

After implementation:

1. Inspect all newly created SQL.
2. Validate referenced tables and column names against the expected CP v151 schema.
3. Inspect every XML file.
4. Inspect every Lua file for syntax errors.
5. Verify every registered localization key.
6. Verify all units and buildings reference existing classes.
7. Verify every custom trait is registered.
8. Verify the .modinfo includes the required files.
9. Verify correct VFS settings for art.
10. Verify InGameUIAddin or equivalent Lua context registration.
11. Check duplicate database identifiers.
12. Check unresolved asset references.
13. Check all SQL and Lua execution-order dependencies.
14. Confirm all existing civilizations are unaffected.
15. Check that the game-speed scaling is implemented from runtime data rather than assumed constants.

Where possible, create automated static checks using available repository tools.

Do not introduce dependencies solely for test convenience.

============================================================
12. DOCUMENTATION
============================================================

Create a README explaining:

- Civilization background
- Leader
- UA
- UU
- UB
- Exact balance values
- Gameplay strategy
- CP v151 requirements
- Human-only status
- Installation/registration details
- Save-state handling
- Known technical limitations
- Testing instructions

Document that:

The UA rewards each qualifying Building Class once per game.

The UB counts CURRENT qualifying classes in the individual city.

The UA ledger is permanent.

The UB Science is dynamic.

They must not share the same progression counter.

============================================================
13. FINAL IMPLEMENTATION REPORT
============================================================

When finished, provide:

A. Summary of all implemented systems.

B. Every created or modified file.

C. Explanation of how the permanent rewarded-class ledger is saved.

D. Explanation of how the dynamic Workshop Science updates.

E. Verification that the Catapult and Workshop inherit active CP values.

F. Static validations completed.

G. In-game tests still requiring manual verification.

H. Any genuine technical limitations or unresolved issues.

I. Confirmation that unrelated Wacky2 civilizations were not intentionally modified.

Do not simply say "implementation complete".

Report concrete evidence of what is implemented and what has actually been verified.

PRIORITIES:

1. Exact mechanics.
2. Reliable save/load persistence.
3. Correct dynamic Science yields.
4. CP v151 compatibility.
5. Correct Wacky2 registration.
6. No regressions to existing civilizations.
7. Complete localization and presentation.

Implement the civilization now.

The Republic of First Drafts must be fully playable, internally consistent and faithful to the specification.

Nothing Is Ever Final.
