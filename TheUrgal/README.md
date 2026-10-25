# The Urgal

**Leader:** Urgal. **Capital:** The Feast. **Origin:** MCPVP Hardcore Games. **Preferred victory:** Domination. **Requires:** BNW and Community Patch v151. **Human-only:** `Playable=1`, `AIPlayable=0` in setup, with human-only runtime guards.

Prepare your army. Position your units. Drink Strength II. Become terrifying for five Standard-speed turns, then return to normal combat.

## Strength II

Begin with **one Strength Potion**, then immediately gain **one per new Era**. Stockpile without a gameplay cap. An Ancient-start player who never drinks has five in Industrial and eight in Information. Duplicate Era events cannot pay twice; skipped Era transitions award the difference. Advanced starts receive one initial bottle without retroactive awards for earlier Eras. Inventory and deadlines persist in the selected save.

**+50% attacking Combat Strength applies to eligible melee attacks against units and enemy cities.** There is no defensive, city bombardment, ranged, naval or air bonus. Warriors, spears, swords, mounted melee, melee gunpowder, armor and compatible custom land melee classes qualify. Reconnaissance, siege, helicopters and civilians are excluded. Native modifiers add: an otherwise unmodified 34-strength attacker attacks at 51 against units and cities. No permanent strength is added.

| Speed | Strength II | Aftertaste | First next drink after activation at T |
| --- | ---: | ---: | --- |
| Quick | 3 turns | 1 turn | T+4 |
| Standard | 5 turns | 2 turns | T+7 |
| Epic | 7 turns | 3 turns | T+10 |
| Marathon | 12 turns | 6 turns | T+18 |

Aftertaste **only blocks another drink**, with no combat penalty. Standard Strength covers T through T+4, followed by Aftertaste on T+5 and T+6. Marathon Strength covers T through T+11, followed by Aftertaste on T+12 through T+17.

For unknown custom speeds, Strength retains `floor(5 * TrainPercent / 100)` turns and Aftertaste uses `floor(2 * TrainPercent / 100 + 0.5)`, each minimum one. Missing, nonpositive or nonfinite percentages default to 100. Loading never recalculates committed deadlines. Existing v15 saves retain any already-recorded legacy two-turn Aftertaste; subsequent drinks use the corrected speed values.

## Drinking and the snapshot

The upper-right inventory uses a transparent purple bottle, stockpile, status and disabled/active button states. The tooltip explains all rules and shows the number of units that can benefit immediately. **At least one eligible unembarked land melee unit is required.** An embarked-only army cannot drink; the tooltip says: “Requires at least one eligible unembarked land melee unit.”

Mixed armies can drink. Existing eligible embarked units join the snapshot but use neither effect until disembarking before the original expiration. Activation feedback separates immediate beneficiaries and embarked participants. New trained, purchased, spawned or acquired units never join the current window. Same-owner normal upgrades preserve an eligible participant's deadline without resetting it. Ownership transfer removes participation. Repeated or reentrant clicks cannot stack effects or consume another bottle.

The panel closes during city screens, diplomacy, nested popups and inactive turns. It refreshes on events and a detached one-shot update, with no permanent frame polling. Long inventories use native text truncation and keep the full value in the tooltip.

## Urgal Rusher and Brewing Stand

**Urgal Rusher:** Swordsman replacement, **14 Strength, 2 Movement, 80 Production, zero Iron**. Other active Swordsman companion effects, model and upgrade path are inherited. **Pot Chaser** survives upgrades and heals **15 HP per enemy-unit kill only while Strength II is active**, capped at maximum health. Native healing restrictions still apply. No extra movement or attacks are granted.

**Brewing Stand:** Barracks replacement, **75 Production, 1 maintenance**, inherited Barracks training XP (**15** on the supported baseline) and companion benefits. It adds **+10% local Production toward eligible melee land units**, including compatible custom types loaded before this collection's SQL. Ranged hybrids sharing a combat class are excluded. **Brewing Stands never create potions.** There are no extra economic yields or potion regeneration.

Urgal is comparatively ordinary between potion windows. Prepare roads and an army before drinking; retreating enemies, terrain, fortifications and cheap screens can waste a permanently consumed bottle. The legacy AI file is retained but not loaded or called; Urgal needs no AI module to function. McPvP remains independent.

## Installation and validation

Included in **Cool Wacky Civs 2 v15 / 1.12.1 preview** with the existing collection UUID and save tags. Start a new game to select Urgal. Windows single-player only; multiplayer and hotseat remain disabled. No standalone package or custom 3D models are needed.

```powershell
.venv\Scripts\python.exe tools/generate_urgal.py
.venv\Scripts\python.exe tools/prepare_urgal_art.py
.venv\Scripts\python.exe tools/build_mod.py --manifest-only
.venv\Scripts\python.exe tools/validate_urgal.py
.venv\Scripts\python.exe tools/validate_mod.py
.venv\Scripts\python.exe tools/benchmark.py
.venv\Scripts\python.exe tools/build_mod.py
.venv\Scripts\python.exe tools/verify_release.py
```

The manifest builder finishes gold-framed atlas artwork and includes the new icon. After deliberately changing the original atlas inputs, refresh only Urgal masters using `standardize_icons.py --refresh-sources URGAL_CIV_ATLAS URGAL_OBJECT_ATLAS URGAL_LEADER_ATLAS`.

[Implementation](docs/Implementation.md) · [Audit and exact changed files](docs/Audit.md) · [Testing and native checklist](docs/Testing.md) · [Validation record](docs/Validation.json) · [Artwork/prompts](../art-source/TheUrgal/Prompts.md) · [Changelog](CHANGELOG.md).
