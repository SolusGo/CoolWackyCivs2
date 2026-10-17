# CODEX IMPLEMENTATION REQUEST
## Civilization V — The Children of the Kingdom

Implement a complete, polished, fully playable custom civilization called **The Children of the Kingdom**, inspired by the Lord's Prayer (Matthew 6:9–13).

**Target:** Civilization V: Brave New World with Community Patch (CP v151 compatibility).

**Repository:** CoolWackyCivs2. Inspect the repository structure before modifying anything. Follow its existing conventions, localization, packaging, asset loading, and modular organization.

This is a real implementation request, not a request for pseudocode, a prototype, or a design document. Create the necessary files and implement the mechanics.

### IMPORTANT GLOBAL REQUIREMENTS

- **HUMAN-PLAYABLE ONLY.** Do not implement AI strategies, AI prayer automation, or AI-specific balancing logic. Apply custom gameplay mechanics only to human players controlling this civilization. Where the game supports it, prevent AI assignment of this civilization without introducing unsupported database properties.
- Preserve compatibility with existing civilizations and mods.
- Do not modify base-game DLLs.
- Use Lua, SQL, XML, and UI assets as appropriate.
- Avoid constant polling or expensive UI update loops.
- Ensure saving and loading preserves all progression.
- Scale turn-based mechanics with game speed.
- Generate original visual assets where tooling permits.
- Keep the civilization fully functional even if optional artwork generation is unavailable.
- Prioritize correct gameplay implementation over decorative features.

---

# 1. CIVILIZATION IDENTITY

**Civilization:** The Children of the Kingdom
**Leader:** The Faithful
**Capital:** Sanctuary
**Unique Ability:** Thy Kingdom Come
**Unique Unit:** Keeper of the Faith
**Unique Building:** House of Prayer

**Primary playstyle:** Faith, Culture, defensive warfare, long-term spiritual progression.

**Preferred victories:** Cultural and Diplomatic.

Thematically, this civilization should emphasize devotion, humility, forgiveness, spiritual perseverance, and trust in God's will.

Its central mechanic is a prayer cycle based on the Lord's Prayer.

The civilization should not rely on conquest for its primary power progression.

# 2. UNIQUE ABILITY — THY KINGDOM COME

*"Your kingdom come, Your will be done, on earth as it is in heaven."*

Implement a unique, interactive **Seven-Stage Prayer System**.

The player progresses through seven petitions in a fixed order.

Each petition provides a unique blessing.

On Standard speed, the player can activate one petition every **5 turns**.

After completing the seventh petition, the cycle resets to the first.

Successfully completing a full prayer cycle generates permanent Grace.

## Prayer stages

### Stage 1 — ADDRESS
*"Our Father in heaven."*

Effect:
- Capital gains +2 Faith per turn.
- Capital gains +1 Food per turn.
- Both bonuses last 5 Standard-speed turns.

### Stage 2 — OPENING GLORY
*"Hallowed be Your name."*

Effect:
- Immediately receive 10 Faith multiplied by the current Era level.

Era level starts at 1 in the Ancient Era and increases by one each era.

### Stage 3 — SEEK
*"Your kingdom come, Your will be done."*

Effect:
- Every owned city receives +15% Culture.
- Lasts 5 Standard-speed turns.
- The bonus must affect actual city Culture production, not merely display text.

### Stage 4 — ASK
*"Give us this day our daily bread."*

Effect:
- Capital immediately gains 8 Food per current Era level.
- Capital immediately gains 8 Production per current Era level.

Implement immediate yields safely, including cases where the Capital has an unusual or empty production queue.

Do not accidentally grant units or buildings through overflow exploits.

### Stage 5 — REPENT
*"Forgive us our debts, as we forgive our debtors."*

Effect:
- Receive +2 Global Happiness for 5 Standard-speed turns.

Use a reliable global Happiness implementation rather than applying the bonus multiple times across cities.

### Stage 6 — PROTECTION
*"Lead us not into temptation, but deliver us from evil."*

Effect:
- All owned cities receive +20% City Defense for 5 Standard-speed turns.
- Military units receive +15% defensive Combat Strength while in friendly territory for 5 Standard-speed turns.

The military bonus is defensive only. It must not accidentally buff offensive attacks.

Ensure newly created units during the blessing period receive the appropriate effect, and remove all temporary effects correctly at expiration.

### Stage 7 — CLOSING GLORY
*"For Yours is the kingdom, the power, and the glory forever."*

Effect:
- Gain 20 Golden Age Points per current Era level.
- Gain one permanent Grace stack, up to the maximum of seven.
- Receive the House of Prayer completion bonuses described below.
- Reset the prayer cycle to Address.

The closing Glory follows the traditional doxology. Preserve this seven-stage gameplay structure.

# 3. PERMANENT GRACE SYSTEM

Each fully completed seven-stage prayer cycle grants **one permanent Grace stack**.

Maximum: **7 Grace stacks**.

Each Grace stack provides:
- +1 Faith per turn in the Capital.
- +1 Culture per turn in the Capital.

At seven Grace stacks, the Capital therefore receives:
- +7 Faith per turn.
- +7 Culture per turn.

These bonuses are permanent.

When completing further prayer cycles while already at seven Grace stacks:
- Do not grant additional Grace stacks.
- Instead, grant an additional 25 Golden Age Points per Era level.

This bonus is in addition to the ordinary Closing Glory reward.

## Persistence and edge cases

- Persist Grace stacks across save/load.
- Never award more than seven.
- Ensure permanent Capital bonuses cannot duplicate.
- If the Capital changes, move Capital-specific bonuses safely to the new Capital.
- Handle city capture and recapture.
- Do not allow save/reload to activate a petition twice.
- Ensure temporary effects expire correctly if the game is saved midway through their duration.
- Ensure eliminated players do not generate errors.

# 4. UNIQUE UNIT — KEEPER OF THE FAITH

**Replaces:** Pikeman.

Preserve the standard Pikeman's normal role and base characteristics unless explicitly changed below.

Unique promotion: **Stand Firm**

Effects:
- +15% Combat Strength when defending in friendly territory.
- +5 additional HP healed per turn when eligible to heal in friendly territory.
- Promotion persists through upgrades.

This unit represents steadfast defenders of the kingdom.

Ensure the promotion remains functional on upgraded units.

Its defensive bonuses should interact correctly with, but remain distinct from, the temporary Protection blessing.

Do not create an offensive snowball or unrestricted healing exploit.

# 5. UNIQUE BUILDING — HOUSE OF PRAYER

**Replaces:** Temple.

Preserve the Temple's normal functionality, costs, prerequisites, and relevant Community Patch behavior.

Additional effects:
- +1 Faith.
- +1 Culture.

Unique civilization interaction:

Every time the player completes the Closing Glory petition, gain an additional **10 Faith for every currently owned House of Prayer**.

Example:
- 1 House of Prayer: +10 Faith.
- 4 Houses of Prayer: +40 Faith.
- 8 Houses of Prayer: +80 Faith.

Only count actual, completed Houses of Prayer owned by the player.

Avoid counting buildings under construction or duplicating the reward on save/load.

# 6. PRAYER INTERFACE

Implement a dedicated, polished **Prayer Interface** accessible to the human player.

The player should be able to easily understand and activate the UA without opening the Civilopedia.

The interface should display:

- Current petition.
- Relevant scripture-inspired text.
- Description of its gameplay effect.
- Turns remaining until the next prayer.
- Current Grace stacks (0–7).
- Progress through the seven-stage cycle.
- An activation button.
- Active temporary blessings and their remaining durations.

## Recommended layout

Top:

**THE CHILDREN OF THE KINGDOM — PRAYER**

Middle:

**Current Petition: SEEK**

*"Your kingdom come, Your will be done."*

**Blessing:** +15% Culture in every city for 5 turns.

Bottom:

Grace: 3/7
Cycle: 3/7
Next Prayer: Available

**[PRAY]**

After praying:
- Apply the blessing exactly once.
- Advance the prayer stage.
- Start the appropriate cooldown.
- Show a subtle confirmation notification.

## UI performance requirements

This is particularly important.

- Do NOT use `ContextPtr:SetUpdate()` with frequent polling.
- Do NOT refresh every 0.1 seconds.
- Do NOT repeatedly scan all units or cities every frame.
- Use game events to update gameplay state.
- Update interface elements when relevant events occur, when the interface is opened, or when the player changes.
- Hide the interface in incompatible screens such as Diplomacy, City View, Culture Overview, and other modal screens.
- Avoid interfering with the normal interface and existing mod panels.
- Do not break the UI if the player loads a saved game while already controlling this civilization.

Follow existing repository conventions where possible.

# 7. GAME SPEED SCALING

All turn-based mechanics must scale appropriately with game speed.

Use Standard speed as the baseline.

| Speed | Approximate multiplier |
|---|---:|
| Quick | 0.67 |
| Standard | 1.00 |
| Epic | 1.50 |
| Marathon | 3.00 |

Use the active game's actual speed settings instead of relying solely on hardcoded speed names.

Scale:
- Prayer activation cooldown.
- Temporary blessing durations.

Round consistently and enforce a minimum sensible duration.

Ensure that effects are not immediately decremented on the same turn they are activated.

The system must remain coherent on every supported game speed.

# 8. IMPLEMENTATION ARCHITECTURE

Please design the implementation to be robust and maintainable.

Suggested modules:
- Civilization SQL/XML definitions.
- Unique Unit and promotion definitions.
- Unique Building definitions.
- Prayer gameplay controller.
- Grace persistence manager.
- Temporary blessing management.
- Prayer UI.
- Localization.
- Art definitions.
- Civilopedia and strategy text.

Use existing repository patterns rather than creating unnecessary architectural complexity.

## Gameplay implementation details

Prefer reliable game-event-based Lua.

Use dummy buildings and promotions where appropriate to implement temporary or permanent modifiers.

Inspect actual Community Patch and Civ V database columns and Lua APIs before choosing implementation methods.

Do not assume an API exists without verifying its usage.

Important:
- Each prayer must activate only once per eligible click.
- The next stage must not become available prematurely.
- Effects must not stack unintentionally.
- Expired effects must be fully removed.
- Grace bonuses must not be reapplied cumulatively on reload.
- Human-player checks must be applied consistently.
- Persist player-specific state reliably.
- Support changing the human player's Capital.
- Use nil checks for player, city, and unit references.
- Avoid expensive repeated iteration where event-driven handling suffices.

Do not silently substitute a mechanically different bonus because an API is inconvenient. Find a supported approach or explicitly document an unavoidable limitation.

# 9. CIVILIZATION ARTWORK

Create a coherent original visual identity inspired by heavenly kingdoms, sacred architecture, devotion, and golden light.

Suggested palette:
- Ivory white.
- Soft gold.
- Warm sunlight.
- Muted blue.
- Marble and stone.

Generate original images/assets when supported by the environment.

Required assets where supported:
- Civilization icon.
- Civilization alpha icon.
- Civilization atlas at appropriate resolutions.
- Leader portrait.
- Dawn of Man image.
- Civilization map/loading image.
- Keeper of the Faith icon.
- Keeper unit flag icon.
- House of Prayer icon.
- Suitable Prayer UI icons.
- Civilopedia artwork if appropriate.

Ensure all art is correctly referenced and converted into valid game-supported formats.

Avoid placeholder paths and broken DDS references.

If asset generation is unavailable, leave the system functional, use appropriate verified existing assets temporarily, and clearly document any remaining art tasks.

Do not introduce sound or music dependencies.

# 10. CIVILOPEDIA AND LOCALIZATION

Provide complete, natural English localization.

Include:
- Civilization name, adjective, and description.
- Leader name.
- Unique Ability description.
- Unique Unit description.
- Unique Building description.
- Strategy text.
- Civilopedia history/flavour text.
- Prayer Interface labels.
- Petition descriptions.
- Blessing notifications.
- Grace progression notifications.
- Cooldown and unavailable-state tooltips.

Tone should be respectful, reverent, and sincere.

The civilization is inspired by Christian prayer. Avoid making its religious subject matter into a parody.

The player should clearly understand that completing prayer cycles strengthens the civilization spiritually and mechanically.

# 11. TESTING REQUIREMENTS

Inspect and verify the following scenarios.

### Initialization
- Start a new game as The Children of the Kingdom.
- Confirm that the proper civilization, leader, icons, and uniques load.
- Confirm the Prayer Interface appears.

### Prayer cycle
- Activate Address.
- Confirm its temporary bonuses apply.
- Wait for the cooldown.
- Activate Opening Glory.
- Continue through all seven stages.
- Confirm each stage produces the correct reward.
- Confirm the cycle resets after Closing Glory.

### Grace
- Complete one prayer cycle.
- Confirm exactly one Grace stack.
- Verify permanent Capital yields.
- Continue until seven stacks.
- Verify the cap.
- Confirm excess completed cycles grant Golden Age Points instead of additional Grace.

### Persistence
- Save during a cooldown.
- Reload.
- Confirm cooldown is preserved.
- Save during an active temporary blessing.
- Reload.
- Confirm the blessing expires at the correct time.
- Save with permanent Grace stacks.
- Reload.
- Confirm no duplication or loss.

### Unique content
- Train Keeper of the Faith.
- Test friendly-territory defensive combat.
- Test healing.
- Upgrade the unit and verify promotion retention.
- Construct multiple Houses of Prayer.
- Complete Closing Glory.
- Verify the exact Faith reward.

### Other scenarios
- Capture and lose cities.
- Lose or move the Capital.
- Change eras.
- Play on Quick, Standard, Epic, and Marathon.
- Eliminate the civilization.
- Play alongside other custom civilizations.
- Enter and leave different game interface screens.
- Confirm all systems continue to function in long games.

If executable in-game testing cannot be performed, distinguish static code validation from actual gameplay verification. Do not claim successful runtime tests without performing them.

# 12. MOD PACKAGING

Register all files correctly with the game's mod loading mechanisms.

Check:
- Database loading.
- InGameUIAddin registration.
- Lua context registration.
- Localization.
- Art atlases and DDS references.
- Dependencies.
- Community Patch compatibility.
- Mod activation.
- Existing save compatibility where feasible.

Preserve other civilizations already present in CoolWackyCivs2.

Do not overwrite unrelated systems.

# 13. FINAL DELIVERABLE

Implement the entire civilization, not merely the design.

After implementation:

1. Summarize all files created or modified.
2. Describe how the Prayer Interface works.
3. Explain how each prayer blessing was implemented.
4. Explain how Grace and cooldown persistence work.
5. Identify any gameplay or engine limitations.
6. Report what tests were actually performed.
7. List anything requiring in-game verification.
8. Confirm that only human-controlled instances receive these custom systems.

Prioritize correct mechanics, stability, performance, and Civ V compatibility.

**DESIGN PHILOSOPHY**

The Children of the Kingdom should not become powerful through conquest, exploitation, or overwhelming early bonuses.

Their power should come from consistently completing the Lord's Prayer, strengthening their faith, seeking God's will, and gradually accumulating Grace.

They should feel vulnerable but purposeful in the early game, steadily more resilient through the middle game, and spiritually influential by the late game.

Preserve all seven prayer stages, the Grace system, the Keeper of the Faith, and the House of Prayer.

**Please proceed with implementation directly.**
