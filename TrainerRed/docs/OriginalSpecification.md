# CODEX IMPLEMENTATION PROMPT
# Civilization V — Trainer Red: The Living Legend

## Objective

Create a fully playable Civilization V: Brave New World mod introducing:

**Civilization:** The Indigo Champion\
**Leader:** Trainer Red\
**Title:** The Silent Champion\
**Capital:** Pallet Town\
**Unique Ability:** The Living Legend\
**Unique Unit:** Pokémon Ace (replaces Great General)\
**Unique Building:** Pokémon Center (replaces Hospital)\
**Unique National Wonder:** Indigo Plateau (replaces Heroic Epic)\
**Unique Project:** Journey to Mt. Silver

The mod must be compatible with Civilization V Brave New World and the Community Patch (CP), targeting CP v151 where relevant.

Implement this as a complete civilization, not merely a design document or a set of placeholder scripts.

**Important: Preserve every gameplay mechanic, trigger, numerical bonus, promotion, Pokémon identity, feature, and flavour element specified below. Do not simplify or remove mechanics to make implementation easier.**

If the Civ V engine cannot implement a mechanic directly, investigate a workaround using Lua, XML, SQL, dummy promotions, buildings, projects, persistent state, or supported CP DLL events.

If an exact mechanic remains technically impossible, document the limitation and implement the closest reliable equivalent without silently omitting functionality.

---

# 1. Civilization Identity

Trainer Red should embody the legendary final opponent from Pokémon Gold, Silver, Crystal, HeartGold and SoulSilver.

He is the trainer who conquered Kanto, defeated the Pokémon League, surpassed his rivals, and eventually withdrew to Mt. Silver.

When the player finally challenges him, he is no longer merely another trainer. He is the ultimate benchmark of strength.

The civilization's progression should communicate this journey:

**Early game:** A young trainer beginning his adventure.

**Mid game:** An accomplished Champion training a carefully selected team.

**Late game:** The silent legend atop Mt. Silver, waiting for a worthy challenger.

The civilization should not rely on overwhelming unit quantities or early economic dominance.

Instead, Red should continuously train a small collection of irreplaceable units that become exceptionally powerful through experience.

His ultimate late-game transformation should make the player feel as though they are controlling the game's secret final boss.

Preferred victory: Domination.

Secondary victory: Science.

Personality: Quiet, reserved, loyal to his team, defensive early, formidable late.

---

# 2. Unique Ability — The Living Legend

The Unique Ability contains three major interconnected systems:

1. Pokémon Training.
2. A League of His Own.
3. The Final Boss.

All three must be implemented.

## 2.1 Pokémon Training

Every eligible military unit owned by Red possesses a persistent Training value.

Training begins at zero unless modified by another civilization ability or unique building.

Units gain Training through the following activities:

| Activity | Training |
|---|---|
| Defeat an enemy unit | +10 |
| Survive combat against a stronger opponent | +5 |
| Capture a city | +15 |
| Clear a Barbarian Camp | +8 |
| End a turn damaged inside Red's capital | +2 |
| Upgrade a military unit | Training is preserved |

For surviving combat against a stronger opponent, the enemy must possess at least 15% greater base Combat Strength than Red's unit.

Training rewards must not be applied multiple times for the same combat.

Training must survive:

- Game saving and loading.
- Unit upgrades.
- Changes in unit names.
- Era transitions.
- UI reloads.
- Normal unit healing.
- Pokémon Ace attachment and detachment.
- Mt. Silver withdrawal and return.

Destroyed units permanently lose their Training.

Use reliable persistent identifiers rather than assuming unit IDs remain constant.

### Training Ranks

Implement the following ranks:

**Caught**
- Requirement: 0 Training.
- No bonus.

**Trained**
- Requirement: 15 Training.
- +5% Combat Strength.

**Proven**
- Requirement: 35 Training.
- +10% Combat Strength.
- +5 additional HP whenever healed.

**Champion**
- Requirement: 65 Training.
- +15% Combat Strength.
- +1 Movement.

**Legendary**
- Requirement: 100 Training.
- +20% Combat Strength.
- Restores 10 HP after attacking and defeating an enemy.

These ranks REPLACE previous rank effects rather than stacking.

For example, a Legendary unit gets +20% Combat Strength from its Training rank, not +50%.

Use mutually exclusive dummy promotions, with Lua support for effects the promotion database cannot express.

Training may exceed 100 internally, but no additional rank exists.

Ensure that healing triggers are applied correctly and cannot loop indefinitely.

---

# 3. The Champion Team

Red can maintain a special roster of up to SIX military units.

These units represent his core Pokémon party.

Not every military unit may be part of the Champion Team.

### Initial Team Capacity

At the beginning of the game:

- Maximum 2 Champion Team members.

Upon entering the Classical Era:

- Maximum 3 members.

Upon entering the Medieval Era:

- Maximum 4 members.

After completing the first National Wonder:

- Maximum 6 members.

Indigo Plateau also unlocks the full six-member roster when completed.

These conditions must work even if eras are skipped or technologies are granted.

## Team Eligibility

Only eligible non-air military units may enter the Champion Team.

When a unit reaches Champion rank, it becomes eligible to occupy an available roster slot.

The first eligible units should be assigned automatically unless the player uses the custom roster UI to select eligible members.

Allow the player to choose an eligible unit for a vacant slot through the UI.

A unit that reaches Champion rank before a roster slot becomes available should remain eligible.

### Champion Team Benefits

Team members gain:

- Cannot be captured by enemies.
- +25% experience from combat.
- Retain all Training through upgrades.
- Heal 5 HP whenever another Champion Team member defeats an enemy within 3 tiles.
- Appear in the custom Champion Team panel.

The Champion Team has a strict limit of six active members.

If a member dies, its slot becomes empty and may be filled by another eligible unit.

Do not automatically restore destroyed members.

The team must never accidentally exceed six members due to upgrades, reloads, unit ownership transfers, or recreation.

---

# 4. A League of His Own

This system rewards Red for defeating worthy opponents.

## Champion's Momentum

Whenever a Champion Team unit defeats another civilization's strongest currently fielded military unit type:

- Gain Culture equal to 50% of the defeated unit's Production cost.
- Gain Science equal to 25% of the defeated unit's Production cost.
- The victorious unit receives +5 Training.

This reward may trigger once per enemy civilization per eligible defeated unit type.

Define the strongest currently fielded unit type using the highest base Combat Strength among that civilization's living combat units immediately before the kill.

Cache the relevant information before unit destruction if the event API requires it.

Use the defeated unit's effective Production cost with a consistent rule for nonstandard units.

Do not permit repeated reward farming through temporary unit conversion, capture, resurrection, or save-loading exploits.

Store claimed rewards persistently.

## Champion Ribbons

The first time Red captures an original capital belonging to another major civilization:

- All living Champion Team members heal completely.
- Red receives 100 Great General points, scaled appropriately for game speed.
- All current Champion Team members gain one Champion Ribbon.

Each Champion Ribbon provides:

- +3% Combat Strength.

Maximum:

- Five Ribbons per unit.
- +15% total Combat Strength.

Implement persistent Ribbon stacks.

Ribbon bonuses must survive upgrades and Mt. Silver transformation.

Later team members do not retroactively receive Ribbons earned before joining.

Prevent duplicate rewards if a capital changes ownership repeatedly.

A capital counts only when it is an original capital of a major civilization and has not already rewarded Red.

---

# 5. Unique National Wonder — Indigo Plateau

Replaces the Heroic Epic.

Requirements:

- Barracks in all eligible cities.
- National Wonder restrictions must function under Community Patch rules.

Effects:

- +15% military unit Production in the city.
- Grants the standard Morale promotion to units produced there.
- Unlocks all six Champion Team slots.
- Champion Team members beginning their turns in the capital gain +2 Training.
- Capital gains +1 Culture and +1 Science for each Training rank currently held by every Champion Team member.

For yield calculations, use the following rank values:

Caught: 0\
Trained: 1\
Proven: 2\
Champion: 3\
Legendary: 4

Therefore, six Legendary team members produce:

+24 Culture per turn.\
+24 Science per turn.

These values are dynamic.

If a team member dies or is replaced, update the yields immediately.

Avoid permanent yield accumulation and duplicates.

Use suitable dummy buildings or another reliable approach to apply changing city yields.

### Hall of Fame

Whenever Red captures an original capital:

Indigo Plateau permanently gains:

- +2 Culture.
- +2 Science.
- +1 Happiness.

Maximum five captured-capital rewards.

Track these rewards separately from individual Champion Ribbons.

If Indigo Plateau has not yet been constructed, store qualifying captures and apply the appropriate Hall of Fame effects after construction.

Avoid granting duplicate bonuses.

---

# 6. Unique Unit — Pokémon Ace

Replaces the Great General.

Movement: 3.

Obtained using the standard Great General generation system.

The Pokémon Ace represents expert trainers influenced by Red's journey.

It retains normal Great General functionality when detached, including:

- Great General combat aura.
- Citadel construction.
- Normal Great General actions that are supported by CP.

## Trainer Bond

The Pokémon Ace can attach itself to one eligible military unit.

While attached:

- The military unit gains +15% Combat Strength.
- Gains +50% Training from combat.
- Heals 5 HP every turn, including after movement.
- Unlocks the Battle Item ability.

The Ace is temporarily removed from the world map while attached.

Store its identity and attachment state persistently.

Allow detachment in friendly territory.

On detachment, recreate the Pokémon Ace on a valid adjacent or nearby friendly plot.

Do not duplicate or permanently lose the Ace during attachment, detachment, upgrades or reloads.

Only one Pokémon Ace may be attached to a unit.

### Additional Champion Team Effects

If attached to a Champion Team member:

- Training rank thresholds are reduced by 10%.
- At Legendary rank, the unit receives +1 Sight.

The 10% threshold reduction is applied while the Ace remains attached.

Ranks should be recalculated when the Ace detaches without deleting earned Training.

## Battle Item

Available once every 8 turns.

When activated:

- Restore 25 HP.
- Remove eligible negative combat-status promotions.
- Restore all movement points.

Restrictions:

- Cannot be activated after attacking that turn.
- Requires an attached Pokémon Ace.
- Cooldown is tracked persistently.
- No more than one use per 8 turns.

Ensure Battle Item uses an explicit button or action rather than triggering automatically.

Scale cooldowns for game speed only if appropriate, retaining the specified standard-speed value.

If temporary negative effects are introduced by this mod, register them for removal; do not indiscriminately remove legitimate permanent promotions belonging to other mods.

---

# 7. Unique Building — Pokémon Center

Replaces Hospital.

Technology: Biology.

Production Cost: Same as Hospital.

Maintenance: 4 Gold.

Effects:

- +5 Food.
- +25% Food retained after growth.
- +5 additional city HP regeneration per turn.
- Units healing within the city's healing territory receive +15 additional HP per turn.
- Champion Team units stationed in the city gain +3 Training per turn, capped at 65 Training.
- Newly trained military units begin with 15 Training.
- Upgrading military units in the city refunds 25% of the Gold upgrade cost.
- Allows one unit airlift per city per turn without requiring an Airport.

The airlift mechanic must be implemented through a valid custom action if normal game airlifting cannot be enabled without an Airport.

Verify that the destination is legal and that standard airlift restrictions are respected where applicable.

Do not provide arbitrary teleportation.

Avoid repeated upgrade refunds and repeated starting-Training rewards.

For Training granted by the Pokémon Center, the passive gain cannot raise units beyond Champion rank.

Legendary must be earned from normal Training activities or Mt. Silver.

---

# 8. Unique Project — Journey to Mt. Silver

This is the defining mechanic of the civilization.

## Requirements

- Red must reach the Modern Era.
- At least four living Champion Team members.
- At least one member at Legendary rank.
- Project may be completed only once.

Cost:

65% of a contemporary World Wonder's Production cost, using a deterministic standard-speed baseline with game-speed scaling.

Implement the project as a civilization-specific project or a building/project hybrid if necessary for Lua integration.

The project must appear correctly in the Production menu and Civilopedia.

## Upon Project Completion

Display a narrative notification:

*"Red has vanished from public life. Rumours place the former Champion atop Mt. Silver."*

Immediately:

1. Identify all current Champion Team members.
2. Record their persistent data.
3. Remove them from the map.
4. Begin an eight-turn countdown.
5. Apply temporary civilization-wide penalties.

During the absence:

- -10% Gold.
- -10% Production.
- Champion Team units cannot participate in combat.
- Units cannot be selected, moved, upgraded, or trained.
- No duplicate replacement units may be created.

The countdown must persist through saved games and reloads.

Never permanently lose the withdrawn units due to a reload.

### Recorded Unit Data

Preserve:

- Unique persistent unit serial.
- Unit type and upgrade lineage.
- Unit level.
- Experience.
- Valid promotions.
- Training points.
- Champion Ribbons.
- Pokémon Ace attachment data.
- Custom names.
- Team slot.
- Damage.
- Relevant combat state.
- Other recoverable persistent information.

## After Eight Turns

Red's Champion Team returns to the map.

Display the event:

**The Legend Has Returned**

All returning units:

- Immediately become Legendary.
- Upgrade freely to their most advanced available eligible unit type.
- Receive Summit-Trained.
- Are renamed after the appropriate members of Red's Pokémon team.
- Reappear in or near the capital.

Units must reappear on legal plots.

If no adjacent plot is available, use a deterministic search for the nearest valid plot.

Do not delete returning units when the capital is crowded.

If Red has lost the capital, return units to a valid surviving friendly city.

If Red has been eliminated, do not revive him accidentally.

The transformation occurs only once.

---

# 9. Summit-Trained Promotion

All returning Champion Team units receive:

- +15% Combat Strength.
- +10 Maximum HP.
- Ignores enemy Zone of Control.
- Restores 10 HP after defeating an enemy.
- No War Weariness generated by its combat.
- May move after attacking if movement remains.

This promotion stacks with Legendary Training rank.

Therefore, the normal fully developed unit receives:

+20% from Legendary Training.\
+15% from Summit-Trained.

Total: +35% Combat Strength before other promotions and modifiers.

Use the intended additive calculation where applicable.

Implement otherwise unsupported effects through Lua and verified Community Patch event hooks.

Ensure the bonus does not accidentally multiply itself or repeatedly apply.

---

# 10. Red's Six Legendary Pokémon

The six Legendary identities are:

1. Pikachu.
2. Charizard.
3. Blastoise.
4. Venusaur.
5. Snorlax.
6. Lapras.

All six should appear in the Champion Team UI after Mt. Silver.

Implement them using unique promotions and unit names.

They should retain their normal underlying Civilization V combat classes and upgrade lines.

Do not create literal Pokémon creatures that break Civ V combat rules.

The identities represent the strengths and roles of Red's iconic team.

Use an intelligent assignment algorithm that maps identities to combat roles and guarantees each identity is assigned only once.

Prioritise the most suitable units, then use deterministic fallbacks.

The default Champion Team contains non-air units, so Charizard should preferably be assigned to a suitable mobile ranged land unit. Do not require an air unit to complete the roster.

## Pikachu — Partner Above All

Assign preferably to the fastest available mobile unit.

Effects:

- +2 Movement.
- +25% Combat Strength against opponents with greater base Combat Strength.
- Deals 10 bonus damage when attacking units at full health.
- Can withdraw from melee combat once every 5 turns if the incoming attack would otherwise destroy it.

Use robust pre-combat and post-combat checks.

Prevent withdrawal into invalid tiles.

Cooldown must persist.

## Charizard — Blazing Ace

Assign preferably to a mobile ranged unit.

Effects:

- +1 Range for eligible ranged units.
- +25% attack strength against cities and fortified units.
- Ignores terrain movement costs.
- After attacking, deals 5 damage to enemy units adjacent to the target.

Additional range must not stack with another Range promotion.

Do not allow recursive damage triggers.

If the unit has no valid ranged attack, implement the closest appropriate legal attack behaviour without changing its basic unit class.

## Blastoise — Unbreakable Torrent

Assign preferably to a defensive gunpowder or armoured unit.

Effects:

- +25% Defence.
- Receives 25% less damage from ranged attacks.
- After defending against a melee attack, deals 10 retaliatory damage to the attacker if alive.
- May fortify immediately after attacking where the underlying unit supports fortification.

Retaliation must not trigger itself recursively.

## Venusaur — Ancient Bloom

Assign preferably to an infantry or defensive support unit.

Effects:

- Heals adjacent friendly units by 10 HP at the start of Red's turn.
- Enemy units beginning their turns adjacent to Venusaur suffer:
  - -15% Combat Strength.
  - -1 Movement.
- +25% Combat Strength in Forest or Jungle.

Multiple Venusaur effects must not stack.

Implement negative statuses using temporary promotions or another reliable technique.

Clean up status effects when their conditions expire.

## Snorlax — The Sleeping Mountain

Assign preferably to the highest-strength defensive melee unit.

Effects:

- +40% Defence while fortified.
- Cannot be displaced or forced to retreat.
- Exerts Zone of Control against land units, including enemies with normal Zone of Control immunity.
- Heals 15 HP per turn while fortified.
- Maximum Movement is limited to 1 after transformation.

Snorlax should be a defensive anchor, not a fast-moving offensive unit.

## Lapras — Across Every Horizon

Assign preferably to a naval or amphibious unit.

Effects:

- Can enter Ocean immediately.
- +1 Range for units with a valid ranged attack.
- Nearby embarked friendly units receive:
  - +1 Movement.
  - +15% Defence.
- +25% damage against naval and embarked targets.

If assigned to a land unit, grant amphibious movement and legal coastal access instead of transforming it into a naval unit.

Do not give land units unsupported Ocean movement that results in illegal plots or crashes.

---

# 11. Champion Team UI

Create a unique interface accessible through a top-panel button:

**Champion Team**

The interface should feel reminiscent of a Pokémon party screen while remaining consistent with Civilization V's existing art style.

Display six slots.

Each slot contains:

- Unit name.
- Pokémon identity, if unlocked.
- Unit portrait or icon.
- Current unit type.
- Training value.
- Training rank.
- Current HP and maximum HP.
- Experience and level.
- Champion Ribbons.
- Attached Pokémon Ace status.
- Summit-Trained status.

Provide buttons to:

- Select a unit on the map.
- Assign an eligible unit to an available slot.
- Inspect unit details.
- Attach or detach a Pokémon Ace when valid.
- Activate Battle Item when available.

Display:

- Current Champion Team capacity.
- Number of filled slots.
- Mt. Silver eligibility.
- Mt. Silver project progress or remaining turns.
- Current transformation state.

The UI must not execute gameplay effects simply because it is opened or refreshed.

All gameplay mutations must occur through explicit commands.

### Performance Requirements

Do not use high-frequency polling loops.

Prefer event-driven updates.

Refresh the UI when:

- A Training value changes.
- A unit is assigned.
- A unit dies.
- A unit upgrades.
- A Pokémon Ace attaches or detaches.
- Mt. Silver begins or finishes.
- The panel is explicitly opened.

Avoid frame-by-frame global scans.

Ensure the screen functions only where appropriate and does not interfere with city screens, diplomacy screens, or other incompatible UI contexts.

---

# 12. Leader Dialogue and Personality

Red should be almost entirely silent.

His personality is conveyed through actions rather than speeches.

Greeting:

"..."

War Declaration:

"..."

Attacked:

"..."

Defeat:

"..."

On meeting another civilization, Red silently adjusts his cap.

His Civilopedia and Dawn of Man narration should describe his journey and achievements.

Do not give him long, boastful speeches.

He is confident because he has nothing to prove.

### AI Personality

Use these approximate AI flavour values:

| Behaviour | Value |
|---|---:|
| Victory Competitiveness | 9 |
| Wonder Competitiveness | 6 |
| Boldness | 8 |
| Diplo Balance | 4 |
| Warmonger Hatred | 5 |
| Denouncement Willingness | 2 |
| Friendship Willingness | 2 |
| Loyalty | 9 |
| Forgiveness | 3 |
| Meanness | 2 |
| Offence | 7 |
| Defence | 9 |
| Military Training | 10 |
| Recon | 7 |
| City-State Interaction | 3 |
| Expansion | 4 |
| Science | 8 |
| Culture | 5 |
| Gold | 5 |

Map these values to actual supported Civ V leader fields where appropriate.

Do not invent invalid database columns.

Red should prefer:

- Quality over quantity.
- Preserving experienced units.
- Defending his core cities.
- Training units extensively.
- Maintaining a technologically advanced military.
- Avoiding reckless early aggression.
- Challenging powerful opponents after Mt. Silver.

### AI Support

This civilization must not be human-only.

The AI must understand the essential mechanics.

At minimum, implement AI-specific Lua logic that:

- Automatically assigns valid Champion Team units.
- Preserves heavily trained units when feasible.
- Maintains a balanced roster.
- Attaches Pokémon Aces appropriately.
- Uses Battle Items when tactically valuable.
- Prioritises Indigo Plateau.
- Attempts Mt. Silver when prerequisites are met and the empire is reasonably safe.
- Selects appropriate combat targets after returning.

The AI need not be as sophisticated as a human player, but it must be capable of progressing through every major mechanic without manual UI actions.

---

# 13. Civilization Art Assets

Generate or prepare all art assets required for a proper Civ V civilization.

If image-generation capabilities are available, use them to create the necessary custom artwork.

Do not leave unrelated civilization artwork as the final assets.

### Required Artwork

**Leader Art — Trainer Red**
- Red standing on the snowy summit of Mt. Silver.
- Iconic red cap.
- Red-and-white trainer outfit.
- Serious, silent expression.
- Snow blowing in the background.
- Cinematic lighting.
- Appropriate Civ V leader-screen composition.

**Dawn of Man**
- Red on Mt. Silver overlooking a vast frozen landscape.
- His silhouette should appear small but imposing.
- Evoke solitude, mastery and legend.

**Civilization Icon**
- Crimson-and-white Poké Ball motif.
- Silver summit detailing.
- Readable at small sizes.

**Civilization Map**
- Kanto and Johto-inspired map presentation.
- Pallet Town and Mt. Silver are focal locations.

**Unique Ability Icon**
- Trainer silhouette against a mountain summit.

**Pokémon Ace Icon**
- Trainer cap or badge motif.

**Pokémon Center Icon**
- Recognisable medical-centre motif with red-and-white colours.

**Indigo Plateau Icon**
- Champion's podium, badge or monumental league building.

**Journey to Mt. Silver Project Icon**
- Snowy mountain peak with a solitary trainer silhouette.

**Promotions**
- Five Training rank icons.
- Champion Ribbon.
- Summit-Trained.
- Six Pokémon identity promotions.
- Trainer Bond.
- Relevant temporary combat effects.

**Champion Team UI**
- Six distinct identity portraits or symbolic icons.
- Appropriate Training bars and status indicators.

**Unit Flag Art**
- Pokémon Ace flag.
- Any required unique unit or promotion markers.

Generate all required Civ V DDS sizes and mipmaps.

Use alpha channels where needed.

Ensure correct loading through the mod's Import into VFS settings and relevant XML/SQL art definitions.

If original Pokémon artwork cannot be generated, produce consistent stylised icons and original visual homages instead.

Do not use blank textures or invalid placeholder paths.

---

# 14. Audio and Atmosphere

Include appropriate audio definitions and support for:

- Peace theme.
- War theme.
- Optional post-Mt. Silver theme variation.

The peace theme should evoke the beginning of Red's journey.

The war theme should evoke his final confrontation at Mt. Silver.

Do not include copyrighted commercial music files unless they are already available in the repository with appropriate permission.

If original music generation is not supported, use a valid existing fallback and document the intended replacement.

Do not reference missing audio files.

---

# 15. City and Spy Names

### City Names

1. Pallet Town
2. Viridian City
3. Pewter City
4. Cerulean City
5. Vermilion City
6. Lavender Town
7. Celadon City
8. Fuchsia City
9. Saffron City
10. Cinnabar Island
11. Indigo Plateau
12. Mt. Moon
13. Rock Tunnel
14. Safari Zone
15. Seafoam Islands
16. Power Plant
17. Victory Road
18. Route 22
19. Pokémon Tower
20. Mt. Silver

### Spy Names

- Blue
- Leaf
- Chase
- Elaine
- Ethan
- Lyra
- Kris
- Brendan
- May
- Lucas

---

# 16. Implementation Architecture

Use the repository's existing Civ V mod conventions where available.

Inspect the current repository before implementation.

Identify:

- Existing civilization structure.
- XML/SQL loading conventions.
- Lua event helpers.
- Community Patch compatibility utilities.
- Save/load helpers.
- UI registration conventions.
- Art asset handling.
- Localisation conventions.

Create the mod within the current repository in a clean, maintainable structure.

Do not accidentally modify unrelated civilizations.

Suggested structure:

TrainerRed/
- TrainerRed.modinfo
- README.md
- SQL/
  - Red_Civilization.sql
  - Red_Units.sql
  - Red_Buildings.sql
  - Red_Promotions.sql
  - Red_Projects.sql
  - Red_Art.sql
  - Red_Localization.sql
- Lua/
  - Red_Core.lua
  - Red_Training.lua
  - Red_ChampionTeam.lua
  - Red_Combat.lua
  - Red_PokemonAce.lua
  - Red_MtSilver.lua
  - Red_PokemonAbilities.lua
  - Red_AI.lua
  - Red_SaveData.lua
- UI/
  - Red_TeamPanel.lua
  - Red_TeamPanel.xml
  - Red_TopPanelButton.lua
- Art/
  - Leader/
  - Civilization/
  - Buildings/
  - Units/
  - Promotions/
  - UI/
- Audio/

Adapt this layout to the existing repository.

Do not create unnecessary files merely to match the example.

## Technical Requirements

IMPORTANT: Civ V's Lua environment is not a modern game scripting environment.

Do not assume APIs such as `unit:SetProperty` or `unit:GetProperty` exist.

Use only APIs confirmed to exist in the targeted BNW + Community Patch runtime.

For persistence, investigate the repository's existing save-data mechanism or supported approaches such as `Modding.OpenSaveData()`.

Use actual verified CP event signatures.

Do not assume event signatures from other Civ V DLL versions are identical.

Investigate appropriate hooks for:

- Unit death.
- Unit creation.
- Unit upgrading.
- Combat start.
- Combat resolution.
- Unit healing.
- Unit movement.
- Unit capture.
- City capture.
- Barbarian camp clearing.
- Turn progression.
- Project completion.
- National Wonder completion.

Implement robust fallbacks where appropriate.

For effects that cannot be expressed as database promotions, use reliable Lua logic without creating repeated or recursive triggers.

When a mechanic requires damage modification, choose a verified pre-combat or post-combat approach that preserves valid combat results.

Prevent unit-killing effects from recursively triggering unrelated combat rewards.

Use consistent, collision-resistant identifiers prefixed with `RED_`.

Do not interfere with other civilizations' mechanics.

Avoid large scans of the entire world every turn unless unavoidable.

Prefer maintaining small indexes of Red's units and relevant persistent state.

---

# 17. Save Compatibility

Save compatibility is extremely important.

The following must survive saving and reloading:

- All unit Training.
- Training ranks.
- Champion Team membership.
- Individual unit serial identifiers.
- Champion Ribbons.
- Pokémon identities.
- Pokémon Ace attachments.
- Battle Item cooldowns.
- Pokémon ability cooldowns.
- Claimed Champion's Momentum rewards.
- Captured original capitals.
- Hall of Fame progress.
- Indigo Plateau dynamic yields.
- Mt. Silver completion status.
- Mt. Silver countdown.
- Withdrawn unit snapshots.
- Legendary transformation status.
- Temporary civilization modifiers.

Do not rely exclusively on Lua global variables.

After loading a game:

1. Reconstruct persistent state.
2. Verify stored unit references.
3. Restore applicable promotions.
4. Recalculate dynamic yields.
5. Reconcile missing or destroyed units.
6. Resume Mt. Silver countdown safely.
7. Refresh the UI.

Prevent reload duplication exploits.

The Mt. Silver transformation must never award an additional team simply because a saved game was reloaded.

Likewise, capital-capture rewards and Battle Item activations must not repeat.

Support starting a fresh game reliably.

Where feasible, ensure code updates remain compatible with saves made using earlier versions of this mod.

---

# 18. Game Speed Scaling

Support standard Civ V game speeds:

- Quick.
- Standard.
- Epic.
- Marathon.

The specified values are based on Standard speed.

Review which mechanics should scale with game speed, especially:

- Mt. Silver project cost.
- Mt. Silver absence duration.
- Pokémon Ace cooldowns.
- Pikachu withdrawal cooldown.
- Great General points.
- Training gained from passive per-turn sources.

Maintain the intended balance across speeds.

Combat-based Training rewards should remain consistent unless there is a compelling technical reason to scale them.

Do not accidentally make Marathon disproportionately easy through passive Training.

Document exact scaling choices.

---

# 19. Multiplayer and Compatibility

Prioritise correct single-player functionality.

Make multiplayer-safe decisions wherever practical.

Do not claim multiplayer compatibility without testing.

Avoid unsynchronised gameplay mutations in UI contexts.

Ensure the mod does not conflict with:

- Community Patch combat behaviour.
- Promotion handling.
- Great General creation.
- National Wonder replacement rules.
- Standard unit upgrades.
- Other civilization definitions.
- Existing top-panel modifications.

Where multiplayer support cannot be guaranteed, clearly document the limitation.

The civilization must function even when other custom civilizations are present.

---

# 20. Testing and Validation

Do not stop after generating code.

Perform a systematic implementation review.

### Database Tests

Verify:

- All SQL loads without errors.
- All referenced Types exist.
- No invalid columns are used.
- All units have valid classes.
- Pokémon Ace correctly replaces Great General.
- Pokémon Center correctly replaces Hospital.
- Indigo Plateau correctly replaces Heroic Epic.
- Journey to Mt. Silver is properly registered.
- All art paths exist.
- All localisation keys resolve.
- Civilopedia entries appear correctly.

### Training Tests

Verify:

- Training gained on kills.
- Training gained against stronger opponents.
- Training gained on city capture.
- Training gained from clearing camps.
- Passive Training.
- Rank thresholds.
- No duplicate rank promotions.
- Training survives upgrades.
- Training survives saves.
- Training is lost on unit death.

### Champion Team Tests

Verify:

- Initial two-member limit.
- Classical Era unlock.
- Medieval Era unlock.
- Full unlock from National Wonder.
- Maximum six team members.
- Team assignment.
- Team member death.
- Replacement of a dead team member.
- Roster UI.
- Team healing bonus.

### Pokémon Ace Tests

Verify:

- Normal spawning.
- Attachment.
- Detachment.
- Combat bonus.
- Training bonus.
- Healing.
- Battle Item.
- Cooldown.
- Upgrade preservation.
- Save/load preservation.

### Mt. Silver Tests

This is the highest-priority test category.

Verify:

- Requirements function correctly.
- Project cannot be repeated.
- Project cost is correct.
- Team members disappear.
- Gold and Production penalties apply.
- Countdown works.
- Saving during disappearance works.
- Reloading does not corrupt team data.
- Team returns after the correct duration.
- Unit upgrades are valid.
- Promotions are restored.
- All six Pokémon identities are assigned.
- All units receive Legendary.
- All units receive Summit-Trained.
- Missing capital fallback works.
- Blocked spawn tiles are handled.
- Transformation cannot duplicate units.
- Penalties are removed after return.

### Pokémon Ability Tests

Test all six Pokémon identities individually.

Verify damage, movement, healing, debuffs, cooldowns, terrain restrictions and special interactions.

### AI Tests

Run AI-only games and verify Red can:

- Train units.
- Assemble the Champion Team.
- Construct Indigo Plateau.
- Generate Pokémon Aces.
- Attach Pokémon Aces.
- Complete Mt. Silver.
- Receive Legendary units.
- Participate effectively in late-game combat.

### Runtime Validation

If Civilization V itself is not available in the development environment:

- Validate SQL against the relevant Civ V database schema where possible.
- Inspect event registrations and signatures against the available CP reference.
- Check all Lua files for syntax issues using compatible tooling.
- Verify referenced Lua functions exist.
- Verify the modinfo lists every required file and action.
- Check asset paths and DDS headers.
- Provide a clear list of tests requiring an actual game session.

Do not claim an in-game test was completed unless it actually ran.

---

# 21. Balance Philosophy

Red should be powerful when fully developed, but not an automatic win.

Maintain the following identity:

**Early Game:**
- Modest economic strength.
- Small team.
- Slow military progression.
- Vulnerable to losing experienced units.

**Mid Game:**
- Strong elite units.
- Increasing roster flexibility.
- Meaningful Champion's Momentum.
- Growing ability to challenge major opponents.

**Late Game:**
- One of the strongest individual six-unit teams in the game.
- Tremendous power after Mt. Silver.
- Excellent combat mobility, healing and specialisation.
- Vulnerable to strategic overstretch, air power, nuclear weapons and losing irreplaceable units.

DO NOT remove mechanics in the name of balance.

If balance adjustments are genuinely required, adjust numerical values only and document them separately, but retain the stated baseline values unless explicitly authorised.

This mod is meant to make Red feel like the GOAT of Pokémon trainers.

The player should need to earn that power.

---

# 22. Civilopedia and Flavour Text

Create complete Civilopedia entries for:

- Trainer Red.
- The Indigo Champion.
- The Living Legend.
- Pokémon Training.
- Champion Team.
- Pokémon Ace.
- Pokémon Center.
- Indigo Plateau.
- Journey to Mt. Silver.
- Summit-Trained.
- All six Pokémon identities.

Use high-quality narrative writing.

The Civilopedia should portray Red as the silent protagonist who became the ultimate challenge.

Do not describe him as evil, arrogant or hungry for conquest.

His strength comes from discipline, loyalty, persistence and his bond with the Pokémon he raised.

### Dawn of Man

Use the following narrative as inspiration:

"From the quiet paths of Pallet Town, a young trainer set forth with little more than a dream and a faithful companion. Across Kanto he travelled, challenging leaders, defeating rivals and overcoming the greatest trainers of his generation.

He became Champion, and yet the title was not enough to define him.

Leaving behind fame and recognition, he vanished into the wilderness, ascending the frozen heights of Mt. Silver. There he trained in silence, until the boy who once began his journey in Pallet Town had become something greater than a Champion.

He had become a legend.

And now, Red, the world awaits your return.

Will you once more become the very best?"

### Mt. Silver Event

"Red has vanished from public life. Rumours place the former Champion atop Mt. Silver."

### Return Event

"Red has returned from the summit.

No proclamation announces his arrival. No great army marches beneath his banner.

Only six companions stand at his side.

Those who would claim the title of greatest must now challenge the legend himself."

---

# 23. Final Deliverables

Produce a COMPLETE Civ V mod that can be placed in the Mods directory and enabled.

Include:

1. Fully defined civilization and leader.
2. Working Training system.
3. Working six-member Champion Team.
4. Working Champion's Momentum.
5. Working Champion Ribbon system.
6. Working Pokémon Ace.
7. Working Pokémon Center.
8. Working Indigo Plateau.
9. Working Journey to Mt. Silver.
10. All six Pokémon identity promotions and effects.
11. Functional Champion Team UI.
12. Functional AI support.
13. Required DDS art assets.
14. Dawn of Man artwork and text.
15. Civilization map art.
16. Correct unit flags.
17. Full Civilopedia.
18. Game-speed support.
19. Save/load persistence.
20. A README explaining mechanics and compatibility.

At the end, provide an implementation report containing:

- Files created or modified.
- Features completed.
- Technical workarounds used.
- Validation performed.
- Tests passed.
- Tests requiring in-game verification.
- Any remaining limitations.

Do not claim that unfinished mechanics are functional.

Do not report success merely because files were created.

Ensure the civilization's key features actually have complete implementations.

---

# FINAL DESIGN DIRECTIVE

Above all, preserve Red's identity.

He is not simply another powerful military leader.

He is the trainer whose journey began in Pallet Town.

He is the Champion who surpassed every rival.

He is the legend who disappeared to the summit of Mt. Silver.

The six units accompanying him should feel like partners that have grown alongside the player for thousands of years.

When Journey to Mt. Silver ends and those six units return, the experience must feel like the moment the player encounters Red in Pokémon Gold and Silver.

A silent figure.

A frozen summit.

Six legendary companions.

And the unmistakable feeling that the true final battle has only just begun.

**Implement Trainer Red — The Living Legend in full.**
