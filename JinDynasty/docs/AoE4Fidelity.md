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
| Reindeer Trader | Higher-cost Caravan replacement, native route limits and trade behavior | Uses safe existing trade-unit model; +15% native international trade income with any Tributary |
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
| Meng'an Mouke replenishing defenders | City/Fort parents, bounded capacity/cooldown, early cavalry or Chemistry Grenadiers, expiry and leash | Human-controlled local units, not a custom autonomous RTS combat AI; cannot become permanent offensive troops |

## Named technologies

All thirteen requested priority upgrades have working effects; none is left as an inert technology label. They are purchased once per empire through the Jin panel, staged as saved upgrades and native promotions/dummies. The global technology tree is unchanged.

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

Gold upgrade costs, cooldowns, generation, rebel/defender lifetimes and Grove intervals scale by TrainPercent. Native production and Gold purchase costs retain the game's speed rules. Permanent per-turn yields are rates, not lump sums multiplied by speed. Actual numerical inputs are in `JinDynasty/Balance.json`; generated SQL/Lua must be rebuilt together after tuning.
