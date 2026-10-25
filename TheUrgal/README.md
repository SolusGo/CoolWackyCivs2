# The Urgal

**Leader:** Urgal. **Capital:** The Feast. **Origin:** MCPVP Hardcore Games. **Preferred victory:** Domination. **Requires:** Brave New World and Community Patch v151. Human and AI playable.

Urgal spends most of the game preparing for a handful of turns where everyone else should probably run away.

## Strength II — unique ability

Begin with **one Strength Potion**, then immediately gain one for every new Era. Bottles persist in the selected save, have no stockpile cap and are permanently consumed. An Ancient-start player who never drinks has five in Industrial and eight in Information. Skipped Era transitions award the difference; repeated callbacks award nothing extra. Advanced-era starts receive the initial one bottle, without retroactive grants for earlier Eras.

The compact upper-right **Strength Potions** inventory appears only for the active human Urgal. Its tooltip lists the current stockpile, eligible units and rules. **DRINK STRENGTH II** consumes one bottle and empowers eligible units currently owned by Urgal:

| Speed | Strength II | Aftertaste |
| --- | ---: | ---: |
| Quick | 3 turns | 2 turns |
| Standard | 5 turns | 2 turns |
| Epic | 7 turns | 2 turns |
| Marathon | 12 turns | 2 turns |

Eligible units gain **+50% attacking Combat Strength against units**. Defense is unchanged. The design's “does not affect Cities” is implemented as no city bombardment or city-attack strength bonus. Ranged attacks, naval units, aircraft, civilians, reconnaissance, siege and helicopters are excluded. Warriors, spears, swords, mounted melee, gunpowder melee, tanks and compatible custom land melee classes qualify. An isolated 34-strength unit attacks at 51; native combat modifiers combine additively with other bonuses and penalties.

Drinking snapshots the existing army, including eligible units currently embarked. Units trained, purchased, spawned or acquired afterwards never join that window. Normal same-owner upgrades preserve a participant's remaining duration if the new unit is still eligible; they never reset it. Ownership transfer removes the temporary benefit. Embarked participants use neither effect until disembarking within the original deadline.

The button reads **STRENGTH II ACTIVE** during the effect. Drinking is prohibited then and throughout **Aftertaste**, which has no combat penalty. On Standard, drinking on turn T empowers attacks on T through T+4. Strength expires at the beginning of T+5, drinking is blocked on T+5 and T+6, and the next bottle is available on T+7. Custom speeds use `floor(5 × TrainPercent / 100)`, minimum one. Aftertaste always lasts two turns.

## Urgal Rusher — Swordsman replacement

**14 Strength, 2 Movement, 80 Production, no Iron requirement.** Retains the active Swordsman model, animations, upgrade path and other companion benefits. The permanent **Pot Chaser** promotion survives upgrades. During Strength II, a Pot Chaser veteran heals **15 HP after killing an enemy unit**, up to maximum health. The native engine applies the heal once, including barbarian kills; native effects that prohibit healing still apply. Outside Strength II, Pot Chaser has no effect. No extra movement or attacks are granted.

## Brewing Stand — Barracks replacement

**75 Production, 1 maintenance**, plus the active Barracks XP and companion benefits: **15 training XP** on the supported baseline. Adds **+10% Production toward eligible melee land units in that city**. The native per-unit building modifier excludes ranged units even if another mod gives them a shared combat class. Modded units loaded before Urgal's SQL are supported by the same eligibility predicate.

**Brewing Stands never create Strength Potions.** Era progression is the only renewable source.

## Playing and counterplay

Prepare an army, roads and Brewing Stands; position the army before drinking. Commit when an opponent cannot easily retreat. Veteran Rushers reward successful kills, while hoarding bottles preserves later opportunities. A wasted potion cannot be replaced by Production or Gold. Mobile armies, terrain, fortifications and inexpensive screens can consume the limited window. Urgal has no direct economic, scientific, growth or cultural bonus.

The AI has high offense, boldness, hostility and military-training priorities. It drinks only with a stockpile, no active effect or Aftertaste, and at least three eligible units with movement and attacks concentrated within two tiles of an engagement. A unit must already have a legal adjacent attack against a visible enemy. It then requires either two nearby visible enemy units, an adjacent enemy city, or an invader on Urgal-owned land. It never drinks just because war was declared. Checks inspect at most 48 army anchors and radius-three local plots; normal Civ V AI chooses subsequent attacks.

## Installation and development

Included in **Cool Wacky Civs 2 v15 / 1.12.0 preview**. Build the collection using the root README and install its archive through the Mods menu. Start a new game to select Urgal. The collection is Windows single-player only; multiplayer and hotseat are disabled. No standalone package or custom 3D models are needed.

```powershell
.venv\Scripts\python.exe tools/generate_urgal.py
.venv\Scripts\python.exe tools/prepare_urgal_art.py
.venv\Scripts\python.exe tools/build_mod.py --manifest-only
.venv\Scripts\python.exe tools/validate_urgal.py
.venv\Scripts\python.exe tools/validate_mod.py
.venv\Scripts\python.exe tools/build_mod.py
.venv\Scripts\python.exe tools/verify_release.py
```

The manifest builder supplies gold framing and appends database content after all released civilizations. Regenerating paintings' atlas inputs after their masters exist also requires refreshing only the three Urgal colour atlas masters through `standardize_icons.py --refresh-sources URGAL_CIV_ATLAS URGAL_OBJECT_ATLAS URGAL_LEADER_ATLAS`.

[Implementation](docs/Implementation.md) · [Validation and native acceptance checklist](docs/Testing.md) · [Machine-readable record](docs/Validation.json) · [Artwork and exact imagegen prompts](../art-source/TheUrgal/Prompts.md) · [Changelog](CHANGELOG.md).
