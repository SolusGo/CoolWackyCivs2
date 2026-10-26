# AoE4 fidelity and Civ V conversions

Research date: **2026-10-26**. The [official Jin overview](https://www.ageofempires.com/games/age-of-empires-iv/civilizations/jin-dynasty/) and [Yue Fei's Legacy overview](https://www.ageofempires.com/games/age-of-empires-iv/yue-feis-legacy/) establish the linked mobile economy, Horse cavalry engine, Emissaries and automatic defenses. The user-supplied implementation specification supplies the requested numerical targets. [AoE4 Helper's Jin database](https://www.aoe4.club/en/civs/jindynasty) corroborates the roster, Landmark names, 20/+3 Villagers, two Emissaries, five Horses and 75/60/45-second generation schedule. The supplied [AoE4 World Explorer link](https://www.aoe4world.com/explorer/civs/jindynasty) returned its navigation shell rather than detailed Jin data during research; no numerical verification is attributed to that page.

## Main conversions

| AoE4 system | Implemented Civ V behavior | Difference / reason |
| --- | --- | --- |
| Mounted Villagers move/work/gather faster | 3 movement; 150% active Worker base WorkRate; cap 20 +3/Tributary; regular Workers remain | Civ V citizens gather tile yields, rather than Worker units carrying resources |
| Two starting Reindeer | Two eligible owned nearby Deer; Food fallback per failed placement | No huntable livestock unit system; avoids illegal resource plots |
| Three Grassland posts, choose one per age-up | Up to three deterministic local empty owned sites after each completed native Landmark; choose one in panel | Candidate coordinates and Locate controls replace AoE4 physical post entities; no illegal dummy posts |
| Five Horses each, 75/60/45-second production | Five each; 5/4/3 Standard owner-turns, rounded through native TrainPercent | Real-time intervals become turn intervals; three ordinary sources plus separate Pasture |
| +2 melee/+1 ranged cavalry max health per Horse | Exact native CP maximum HP changes | Current living HP is preserved to prevent healing by stockpile cycling; no damage-resistance approximation was necessary |
| Nearby War Stable spends livestock for fast discounted training | One Horse +65% native Gold cost; city within two plots; immediate legal spawn | Buildings occupy city centers; production discount becomes a paid Gold recruit action |
| Iron Pagoda melee armor and splash | +15% defense versus relevant melee classes; 15% actual-damage collateral | Nonlethal secondary damage, maximum three adjacent visible hostile land combatants |
| Mohe mobile archery | Early ranged cavalry; move after one attack; infantry bonus | One normal ranged action avoids unintended multiple attacks |
| Bed Crossbow two-bolt salvo | Native primary attack plus nonlethal 35% actual-damage second bolt | No custom projectile animation; early anti-infantry rather than inherited city siege |
| Late Zhanma and Eruptor | Rifling heavy anti-cavalry infantry; Chemistry range-1 gunpowder with scatter | Civ V technology eras differ from the four-age system |
| Nest of Bees / Traction Trebuchet | Field artillery / conventional siege, Jin data and icons | Existing Catapult/Trebuchet models; no new 3D rockets or requirement for Korea DLC |
| Reindeer Trader | Cost 90, native surplus-Food training, HurryCostModifier 0, Moves 2, native route limits | Food-assisted training or Gold purchase approximates mixed costs; native route speed really reads Moves. Extra HP cannot resist direct native route plunder; Tributary +15% remains separate |
| Two Emissaries; neutral travel | Noncombat units, cap two, RivalTerritory and explicit action validation | Ordinary capture/death rules still apply |
| Neutral Trade Settlement Tributaries | Independent peaceful City-State capitals; +2 native capital Food each, +3 Villager cap, one trade modifier | City-States remain independent; no permanent alliance or influence overwrite |
| +15% Trader income | Native `TradeRouteYieldModifier=15` while any Tributary exists | Yield-specific legacy hook is compiled out in pinned v151; working native modifier also affects non-Gold outgoing international yields and sea trade. No guessed Gold payout |
| Bribe causes neutral rebellion | Up to three nearby hostile troops replaced by independent Barbarian standard equivalents, with health fraction and finite life | No neutral free-agent player exists. Foreign unique skills/XP are not copied; heroes/limited/custom-only classes are protected |
| Flower Garden local gathering/attack speed | One movable improvement: radius 2, +25% Worker speed, +15% non-siege military strength | Civ V lacks continuous attack-speed/gathering loops; effects are local and nonstacking |
| Great Pasture Grassland + stable | Separate five-Horse city source and immediate recruitment | Does not consume the ordinary tier-I Grassland opportunity |
| Dragon Pavilion Emissaries + defenses | Free Emissary once; +100% production; all city emplacements | Production modifier approximates half cost; a blocked free award waits safely |
| Mountain Hall, Karma, Four Heavenly Kings | Monastery effects/discount, visible 1,000 Karma, worked resources/workers, death losses; four-turn Farm/Faith/healing/strike blessing | +1 Farm Food approximates +30%; Faith replaces relic income; city recovery/strike replaces building regeneration/attack speed |
| Great Wall Bastion enhanced keep | Capital defense/ranged bonus, two defender slots, one automatic 20-HP shot per turn | Single capital building, not a freestanding multiweapon Keep |
| Pagoda Forest Wood and slowing | Up to 15 Groves, five/city, +1 worked Production, once-per-turn nearby movement loss | Production represents Wood; native improved tiles replace small forest entities |
| Meng'an Mouke replenishing defenders | City/Fort parents, bounded capacity/cooldown, early cavalry or Chemistry Grenadiers, expiry and leash; automatic native attacks/adjacent approach/return | At most one saved local order per active Jin owner-turn; native range/LOS/war checks, player mission veto. Greedy bounded movement can guard in place at obstacles; no unrestricted RTS pursuit |

## Explicit fidelity classification after hardening

These categories describe mechanics, not numerical balance equivalence. The [official overview](https://www.ageofempires.com/games/age-of-empires-iv/civilizations/jin-dynasty/) supports the main linked economy and signature roles; the detailed database links below support narrower comparisons.

| Classification | System | Assessment |
| --- | --- | --- |
| Faithfully reproduced core rule | Horse stocks and cavalry HP | Independent capped sources; exact +2 melee/+1 ranged maximum HP per active Horse; spend livestock for instant cavalry |
| Necessary turn-based adaptation | Grasslands, Pasture and age-up | Site selection after completed native Landmark; 5/4/3 owner-turn production instead of seconds; city buildings replace RTS structures |
| Approximate equivalent | Mounted Villagers | Faster native Worker movement/work and 20/+3 cap; citizens supply tile yields. Carry capacity, exposed-resource gathering and the Food/Gold training mix are not reproduced |
| Faithful signature with bounded adaptation | Iron Pagoda, Mohe, Bed Crossbow | Melee durability/splash, fast mounted archery, and second bolt exist; strength percentages, nonlethal collateral and borrowed models adapt Civ V combat |
| Approximate equivalent | Zhanma, Eruptor, Nest of Bees, Traction Trebuchet | Requested roles preserved in Civ V's technology/combat system; no new RTS weapon animations |
| Approximate equivalent, improved | Reindeer Trader | Native Food/Gold alternatives and faster land travel; simultaneous AoE4 resource bill and HP protection remain unimplemented |
| Approximate equivalent | Emissary Tributaries and Bribe | Independent City-State capital relationships; hostile Barbarian standard-unit replacements. No neutral free-agent faction or foreign unique skills/XP copying |
| Necessary turn-based adaptation, improved | Meng'an Mouke | Local automatic native orders replace manual control. AoE4's five rallying troops/global replenishment pool becomes existing one/two-parent capacity and cooldown; Chemistry still gates Grenadiers |
| Approximate equivalent | Flower Pagoda/Garden, Great Pasture, Dragon Pavilion | Garden work/strength replace gathering/attack-speed, Pasture has independent Horses, Pavilion grants one Emissary and production/emplacements |
| Approximate equivalent | Mountain Hall, Great Wall Bastion, Pagoda Forest | Karma/blessing, capital defenses and worked Production/Grove slowing preserve themes. Relic income, physical freestanding multiweapon Keep and Wood harvesting are not exact |
| Incorrect translations retained for later balance pass | Named upgrades below | Functional effects do not establish fidelity; explicit mismatches are flagged rather than silently rewritten |
| Unimplemented secondary details | RTS logistics and presentation | Gather/carry simulation, real-time attack/cooldown cycles, custom projectiles, proprietary models/audio and exact livestock entities |

The [Reindeer](https://www.aoe4.club/en/civs/jindynasty/units/reindeer-trader) / [ordinary Trader](https://www.aoe4.club/en/civs/jindynasty/units/trader) comparison is 70 Food +30 Gold versus 35 Wood +60 Gold, totals 100 versus 95. Speed is 1.1 versus 1.0 and HP 100 versus 90. The cost composition changes; it is not universally cheaper. Civ V's integer Moves 2 versus 1 is coarser and predates this patch; it is preserved, not advertised as an exact 10% translation. Native Gold price also reflects higher Production cost, so removing the +20 hurry modifier does not mean a universal 20% discount.

## Named technologies

All thirteen requested priority upgrades have working effects. They are purchased once per empire through the Jin panel, staged as saved upgrades and native promotions/dummies. Several names were previously mapped to different mechanics. Their effects and costs below are retained in this hardening patch; functional implementation is not a claim of exact AoE4 fidelity. The global technology tree is unchanged.

| Upgrade | Gold base cost / prerequisite | Effect |
| --- | --- | --- |
| Collective Hunting | 100 / Trapping | +1 Food on Camps in Jin cities |
| Mohe Ancestry | 150 / Horseback Riding | Mohe +15% ranged attack |
| Quilted Armor | 150 / Horseback Riding | Cavalry +10 maximum HP |
| Draft Horses | 250 / Chivalry | Cavalry +1 movement; Mounted Villager +25% work rate |
| Storm Lances | 250 / Chivalry | Iron Pagoda +20% attack |
| Bed Crossbow Emplacement | 200 / Machinery | One automatic 12-HP defensive shot per parent/turn |
| Meng'an Mouke Emplacement | 200 / Civil Service | City/Fort/Citadel temporary defenders |
| Porcupine Defense | 200 / Metal Casting | Melee/gun infantry +25% against mounted/armor classes |
| Padded Lamellar | 350 / Metallurgy | Cavalry +15 maximum HP |
| Tower Shields | 300 / Gunpowder | Melee/gun infantry +25% ranged defense |
| Flying Fire Battalions | 350 / Chemistry | Eruptor/Grenadier +15% ranged attack |
| Heaven Shaking Thunder | 350 / Chemistry | Eruptor/Grenadier scatter increases 50% |
| Pili Pao | 400 / Fertilizer | Siege +15% ranged attack |

| Upgrade / detailed reference | AoE4 effect checked on 2026-10-26 | Classification of current Civ V effect |
| --- | --- | --- |
| [Collective Hunting](https://www.aoe4.club/en/civs/jindynasty/technologies/collective-hunting) | Four Reindeer spawn at Town Center | **Incorrect translation:** permanent Camp Food replaces a one-time livestock award |
| [Mohe Ancestry](https://www.aoe4.club/en/civs/jindynasty/technologies/mohe-ancestry) | Villager hunted-meat gathering +20% | **Incorrect translation:** Mohe ranged attack is a different beneficiary and mechanic |
| [Quilted Armor](https://www.aoe4.club/en/civs/jindynasty/technologies/quilted-armor) | Mohe take 50% less bonus damage | **Incorrect translation:** +10 HP to all cavalry is neither Mohe-specific nor bonus-damage mitigation |
| [Draft Horses](https://www.aoe4.club/en/civs/jindynasty/technologies/draft-horses) | Villager Wood gathering/carry improves | **Incorrect translation:** generic Worker work rate is approximate, cavalry movement is unrelated |
| [Storm Lances](https://www.aoe4.club/en/civs/jindynasty/technologies/storm-lances) | Spearmen gain a cooldown explosive ranged attack | **Incorrect translation:** Iron Pagoda attack modifier has the wrong unit and ability |
| [Bed Crossbow Emplacement](https://www.aoe4.club/en/civs/jindynasty/technologies/bed-crossbow-emplacement) | Defensive weapon on a building | **Approximate equivalent:** one automatic bounded 12-HP shot per parent/turn |
| [Meng'an Mouke Emplacement](https://www.aoe4.club/en/civs/jindynasty/technologies/mengan-mouke-emplacement) | Uncontrolled local defenders and global replenishment | **Necessary turn-based adaptation:** bounded autonomous orders now reproduce control intent; pool/count remain adapted |
| Porcupine Defense | Detailed database page timed out twice | **Not independently verified:** current infantry anti-mounted bonus retained; no invented exact match |
| [Padded Lamellar](https://www.aoe4.club/en/civs/jindynasty/technologies/padded-lamellar) | Cavalry and melee infantry HP +25% | **Incorrect scope / approximate magnitude:** fixed +15 cavalry HP excludes infantry |
| Tower Shields | Official overview: Man-at-Arms ranged durability; detailed page timed out | **Approximate equivalent:** ranged defense exists, but current melee/gun infantry scope is broader; exact value not verified |
| [Flying Fire Battalions](https://www.aoe4.club/en/civs/jindynasty/technologies/flying-fire-battalions) | Grenadier support and +10 defender availability | **Incorrect translation:** damage modifier replaces support/capacity; Chemistry independently supplies Grenadiers |
| [Heaven Shaking Thunder](https://www.aoe4.club/en/civs/jindynasty/technologies/heaven-shaking-thunder) | Eruptor/Storm Lance fear reduces nearby enemy cavalry damage briefly | **Incorrect translation:** increased outgoing collateral replaces a temporary enemy debuff |
| [Pili Pao](https://www.aoe4.club/en/civs/jindynasty/technologies/pili-pao) | Trebuchet/Nest of Bees +1 range and short building-damage suppression | **Incorrect translation:** generic siege damage lacks the range/debuff and narrower roster |

A later dedicated fidelity pass should assess these beneficiary/ability mismatches and their costs together. They are not silently rebalanced here. The database is a secondary reference whose values may change; the official overview is used for broad identity, not to certify these detailed numbers.

Gold upgrade costs, cooldowns, generation, rebel/defender lifetimes and Grove intervals scale by TrainPercent. Native production and Gold purchase costs retain the game's speed rules. Permanent per-turn yields are rates, not lump sums multiplied by speed. Actual numerical inputs are in `JinDynasty/Balance.json`; generated SQL/Lua must be rebuilt together after tuning.
