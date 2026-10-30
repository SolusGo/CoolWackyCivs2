# The Jin Dynasty

Wanyan Aguda leads a human-only Jurchen civilization adapted from **Age of Empires IV: Yue Fei's Legacy**. Requires Windows Civilization V: Brave New World and **Community Patch v151**. The original Cool Wacky Civs collection is not required.

**Status: 1.13.2 UI hotfix preview.** The launcher now recovers after AI turns; restart Civ V after updating, then reload the same save. Executable SQL/Lua simulations cover the systems below; actual Civ V gameplay, UI rendering, save-file reloads and balance have **not** been verified. See [Testing](docs/Testing.md), [hardening findings and measurements](docs/Hardening.md) and [engine adaptations](docs/AoE4Fidelity.md).

## Play flow

1. Train Mounted Villagers alongside ordinary Workers. They cost 110 Production, move 3, retain the active Worker's builds/routes/repairs and work at 150% of its base rate. The living-unit cap is 20, plus 3 for each active Tributary. Your first capital receives two Deer on suitable nearby land, or 6 Standard-speed Food for each unavailable placement, once.
2. Open **JIN DYNASTY** on the right. In Classical, Medieval and Renaissance choose one Landmark from each pair, then complete its native capital construction. A choice is permanent; completion, not clicking the button, grants its effects.
3. In **Grasslands**, choose one of up to three real locations for each completed tier. Each ordinary Grassland stores five Horses. The Great Pasture has its own additional five-Horse inventory. Generation takes 5/4/3 Standard owner-turns at tiers I/II/III, scaled through the actual game speed's TrainPercent. Pillaged sites retain inventory but produce nothing and contribute no health.
4. Every active stored Horse gives all your melee cavalry +2 maximum HP or ranged cavalry +1. Workers, infantry, siege, ships, helicopters and tanks do not qualify. Adding or removing maximum HP preserves current living HP; spending Horses never kills a wounded unit or creates repeat healing.
5. Build a War Stable in a city within two plots of an active Grassland. **Recruit** spends one Horse and 65% of the unit's normal native Gold price, rounded up. Technologies, resources, training rules, caps, resistance, razing and city deployment space are checked before spending. The Great Pasture is also its city's War Stable. Recruits finish their movement on arrival.
6. After your second Landmark, train up to two Emissaries. Move next to an independent peaceful City-State capital and use **Tributary**. Each supplies +2 native Food per turn to your current capital and raises the Mounted Villager cap by three. With one or more active Tributaries, a single native +15% modifier applies to outgoing international trade income. It includes native non-Gold international yields; it does not compound per Tributary or alter City-State influence.
7. Use **Bribe** against visible hostile land troops within two plots of a mobile Emissary. It affects up to three eligible units in a one-plot cluster, costing `150 + 2 × target Production` each before game-speed scaling. Successful replacements are Barbarian-controlled standard equivalents, hostile to both armies. No original is removed before its replacement exists. Cooldown: eight Standard turns; rebel lifetime: six.
8. Research named upgrades in **Upgrades**. Inspect automatic defenders, readiness, home locations and Grove production in **Defenses**.

## Units

| Unit | Unlock | Cost / movement | Combat role |
| --- | --- | --- | --- |
| Mounted Villager | Start | 110 / 3 | Noncombat Worker; 150% active baseline work rate |
| Iron Pagoda | Horseback Riding | 145 / 3 | 19 Strength; melee defense; 15% actual-damage collateral to up to 3 adjacent enemies |
| Mohe Tribesman | Horseback Riding | 75 / 5 | 8 melee / 9 ranged, range 2; move after attacking, infantry bonus |
| Bed Crossbow | Mathematics + Machine Workshop | 100 / 2 | 9 / 15, range 2; infantry bonus and a nonlethal second bolt worth 35% of primary damage |
| Zhanma Swordsman | Rifling | 300 / 2 | 42 Strength; +75% against mounted/armor combat classes |
| Eruptor | Chemistry | 260 / 2 | 18 / 42, range 1; 10% bounded scatter damage |
| Meng'an Mouke Defender | Automatic | Not trainable / 4 | 16 Strength, no city capture, home leash and expiry |
| Mounted Grenadier | Chemistry, automatic | Not trainable / 4 | 24 / 32, range 2; 20% bounded explosive collateral |
| Emissary | Second completed Landmark + Civil Service | 120 / 3 | Noncombat; neutral access, Tributary and Bribe actions |
| Reindeer Trader | Animal Husbandry | 90 / 2 | Surplus Food assists training at the cost of growth; reduced Gold hurry modifier; native Caravan routes |
| Nest of Bees | Machinery | 170 / 2 | 12 / 26, range 2; battlefield artillery, borrowed Catapult model |
| Traction Trebuchet | Physics | 125 / 2 | 12 / 14, range 2; conventional city siege and upgrade path |

Secondary damage is nonlethal and affects at most three adjacent hostile land combatants. Bed Crossbow's second bolt applies to the original target. These mechanics use CP's actual completed-combat damage arguments, not predicted damage. No custom projectile animations or new 3D models are claimed.

## Landmark paths

| Tier | Choice | Working effect |
| --- | --- | --- |
| I: Classical, 150 Production | Flower Pagoda | One placed Flower Garden; radius 2, +25% Worker work rate and +15% non-siege land military strength; relocate after 5 Standard turns |
| I | Great Pasture | Independent five-Horse stockpile and local recruitment, plus the ordinary tier-I Grassland choice |
| II: Medieval, 250 | Dragon Pavilion | One free Emissary, deferred while capped/blocked; +100% Emissary Production in all cities; automatic city emplacements |
| II | Mountain Hall | Monastery functions; +100% Jin Monastery Production; Karma, unit-death losses and Four Heavenly Kings blessing |
| III: Renaissance, 400 | Great Wall Bastion | +10 displayed city defense, +25% ranged strike, two defender slots and one automatic 20-HP shot per owner-turn |
| III | Pagoda Forest | One Grove every 5 Standard turns; at most 15 empire-wide / 5 per city; +1 worked Production and nearby enemy movement loss |

Meng'an Mouke Emplacement can also be purchased as an empire upgrade. It enables all cities and indexed owned Forts/Citadels. Radius 3, one defender per ordinary parent, five Standard turns replenishment, four Standard turns lifetime, four-plot leash. Defenders automatically choose visible hostile combat threats closest to home and make at most one attack or adjacent approach/return step during each active Jin owner-turn. They use native movement/range/line-of-sight checks, never capture cities, and ordinary player missions are blocked. A blocked route may leave them guarding in place; this is bounded local automation. Chemistry changes future spawns to Mounted Grenadiers. Bed Crossbow Emplacement enables one separate automatic 12-HP shot per parent and owner-turn. Destroyed, captured, pillaged or expired parents retire dependents after any ongoing combat finishes.

Reindeer Traders keep Cost 90 and Moves 2. While training, native surplus Food contributes Production and pauses growth, approximating AoE4's Food cost. Native Gold purchase is an alternative, with HurryCostModifier 0 instead of Caravan 20; final prices retain native speed, city and rounding rules. Pinned CP source uses the civilization's Caravan definition's Moves for land-route travel, so this existing 2-versus-1 difference also speeds automated travel. Circuit count/return duration and route capacity stay native. Extra HP cannot resist native plunder, which directly clears a route, so no ineffective protection is advertised. AoE4's 70 Food +30 Gold totals 100 versus the ordinary Trader's 95 resources; it is a different cost composition, not universally cheaper.

Mountain Hall's meter reaches 1,000 Karma. Worked nearby tiles generate 10 Karma, resources another 10; nearby Workers add 2 and Mounted Villagers 4. Turn gain is divided by TrainPercent. Death costs 25 once; native conversion and trade launch/return bookkeeping are excluded. Explicit route plunder still costs 25. At maximum, reset and activate four owner-turns of +1 worked Farm Food, +4 Faith per city, +10 city healing and +25% city ranged strike. The duration intentionally remains four economic turns on every speed.

## Configuration, installation and saves

All balance inputs are in [Balance.json](Balance.json), including the unit/building/landmark/upgrade inventories. Run `python tools/generate_jin.py` after editing it; ship the generated SQL and `JIN_Config.lua`. Support buildings initially cost 90 (War Stable/Machine Workshop) and 100 (Monastery). Native inherited CP companion effects remain subject to the active CP database.

Build from the repository root with the commands in the collection README. Extract `dist/Cool Wacky Civs 2 (v 16).zip` into your actual Civ V `MODS` directory so the version-16 modinfo sits directly inside its install folder. Remove the older collection install first; the collection UUID is preserved. Enable BNW, Community Patch and this collection, then **start a new single-player game** and select Aguda. No ModBuddy is needed.

New games are required to add Jin to a pre-Jin collection save. This hardening patch retains mod version 16, UUID and schema 1: valid existing Jin progression, Horse stocks, choices, rewards and deployed temporary units are retained. New order budgets and transaction receipts are optional saved fields. Runtime caches are rebuilt on load. Older native saves still require the acceptance checklist; back up saves before upgrading and avoid downgrading a save containing a pending transaction to 1.13.0. Single-player Windows only; no AI strategy, multiplayer, hotseat or Mac support.

See [Implementation](docs/Implementation.md), [AoE4 fidelity](docs/AoE4Fidelity.md), [testing](docs/Testing.md), [validation results](docs/Validation.json) and [changed-file inventory](docs/ChangedFiles.md).
