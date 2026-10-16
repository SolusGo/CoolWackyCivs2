# Trainer Red — The Living Legend

**The Indigo Champion**, led by **Trainer Red, the Silent Champion**. Capital: **Pallet Town**. A civilization for Brave New World and **Community Patch v151**, included in Cool Wacky Civs 2 **mod version 7 / 1.4.0 preview**. Domination is preferred; Science is secondary.

![Red on Mt. Silver](../art-source/TrainerRed/RedOnSilver.png)

This is a playable implementation with automated SQL, source-contract and Lua simulation validation. Native Civ V gameplay, AI-only matches and UI rendering have **not** been verified. Read the [implementation report](docs/ImplementationReport.md) and [native test checklist](docs/Testing.md), especially the precise engine workarounds.

## Raise partners, not replacements

All combat units earn persistent Training. Non-air units can join the Champion Team after reaching Champion rank. A unit's save-carried serial identifies it independently of its native ID, name, era or upgrade type. Death destroys that veteran's progress permanently.

| Activity | Training |
| --- | ---: |
| Defeat a unit in combat | 10 |
| Survive an opponent with at least 15% greater base strength | 5 |
| Capture a city | 15 |
| Clear a Barbarian Camp | 8 |
| End a turn damaged in the capital | 2 |

Base strength consistently means the greater of the native base melee and ranged strengths. Combat Training remains flat across speeds. A bonded Ace adds 50% to combat Training, including Momentum Training; captures, camps and passive Training retain their listed values.

| Rank | Training | Exclusive effects |
| --- | ---: | --- |
| Caught | 0 | None |
| Trained | 15 | +5% strength |
| Proven | 35 | +10% strength, +5 HP whenever healed |
| Champion | 65 | +15% strength, +1 Movement |
| Legendary | 100 | +20% strength, heal 10 after an attacking kill |

Ranks **replace**, rather than stack with, previous ranks. In particular Legendary does not retain Champion's Movement or Proven's healing. Training may exceed 100. A bonded team member uses thresholds **0, 13.5, 31.5, 58.5, 90**; detaching recalculates its rank without deleting Training.

The roster holds **2** partners initially, **3** from Classical, **4** from Medieval, and **6** after the first national wonder or Indigo Plateau. Era comparisons handle skipped eras. Existing eligible veterans automatically fill vacancies. The panel's **Roster: Manual** mode and **Release from team** button let you reserve vacancies and choose another eligible candidate; releasing never deletes the unit. AI assignment favors experienced veterans and missing combat roles.

Members cannot be captured and gain 25% combat XP. A member's victory heals other members within three tiles for 5 HP. A dead member leaves a real vacancy; the mod never creates a replacement military unit.

## A League of His Own

A team victory against an enemy major civilization's strongest living fielded type grants **50% of that unit's effective Production cost as Culture**, **25% as Science**, and **5 Training**. The strongest fielded value is cached before destruction. Ties qualify. Cost uses the victim owner's native `GetUnitProductionNeeded`, with nonpositive/unbuildable costs clamped to zero and fractional yields rounded down. Science enters research overflow. Each enemy-player/unit-type pair can reward Red only once, even across conversion, resurrection and reloads. Barbarians and city-states do not give Momentum.

Each first conquest of a rival major civilization's genuine original capital fully heals the living team, grants **100 Great General points** at Standard speed, and gives each current partner a **+3% strength Ribbon**, capped at five. Later recruits receive no old Ribbons. Repeated recapture gives no reward. Capital claims are separate from the **Hall of Fame**, which remembers up to five qualifying captures even before Indigo Plateau exists.

## Indigo Plateau — Heroic Epic replacement

The Plateau inherits the active Heroic Epic's class, costs, technology, Barracks-in-all-eligible-cities requirements and CP companion rules. It grants **+15% military Production** in its city and **Morale** to units trained there, and unlocks six slots.

With the Plateau present, members beginning turns in the capital gain **2 Training**. Every active member contributes its rank value, 0–4, as **Culture and Science in the current capital**: six Legendary members give 24 of each. Each stored Hall of Fame capture adds **2 Culture, 2 Science and 1 Happiness in the Plateau city**, to five captures. Binary 0/1 dummy buildings replace the current totals; they never accumulate stale bonuses. Withdrawing or losing members removes their dynamic contribution.

## Pokémon Ace — Great General replacement

The Ace has **3 Movement** and inherits every native General action, aura, Citadel build permission and generation rule. The detached world model remains the normal Great General, with custom cap portrait and flag.

An adjacent Ace can attach through the panel. Its complete recoverable snapshot leaves the map and stays with the host through upgrades and saves. The host gains **+15% strength, +50% combat Training, and 5 HP per turn**, including turns after moving. A bonded Legendary team member also gains **+1 Sight**. Detachment requires friendly territory and a legal nearby friendly civilian plot. If none exists, the bond remains intact. If its host dies, the Ace is held for safe recovery near a surviving capital; the military partner stays dead.

**Battle Item** is an explicit action: **25 HP**, removal of this mod's temporary Ancient Bloom status, and restored movement. It requires a bond, cannot follow an attack that turn, and has an **8-turn Standard** persistent cooldown. It never strips arbitrary permanent promotions from other mods.

## Pokémon Center — Hospital replacement

At Biology, with the active Hospital Production cost: **4 Gold maintenance, +5 Food, 25% Food retained**, and **+5 native city healing**. A real healing event in the city's owned three-tile healing territory adds **15 HP once per turn**, with an owner-turn fallback when a damage UI notification is unavailable. Overlapping Centers do not stack this extra healing.

Stationed team members gain **3 Training per Standard-speed turn, capped at 65**. A Center cannot passively train Legendary partners. Newly trained or purchased military units start with **15 Training**, once. Normal paid upgrades on the city tile refund **25% of the native upgrade price**, once per upgrade; free goody upgrades do not refund Gold.

The panel can airlift **one unmoved land unit per source Center per turn**, to another owned Center or Airport city. Choose the destination explicitly. Native `CanAirliftAt` and `MISSION_AIRLIFT` enforce legal movement, stacking and hostile destination adjacency. The allowance does not enable a general teleport command or an unlimited Airport action. Naval, embarked, busy and post-attack units are excluded.

## Journey to Mt. Silver

In the **Modern Era**, with **four living team members and at least one Legendary**, the one-time project appears in city Production. No particular Modern technology beyond reaching the era is required. Its standard baseline is **65% of the active Statue of Liberty cost** (689 from the validation database's 1060); native `CreatePercent` scales Production cost.

Completing the project journals every current partner, then removes those units from the map. For **8 Standard-speed turns**, each city has **-10% Gold and Production**. New cities and captured cities reconcile the modifier. Withdrawn units cannot fight, move, upgrade or be selected. Vacancies are not filled during withdrawal/return.

At the due turn, the same serials return near the capital, or a surviving friendly city. Units become Legendary, receive **Summit-Trained**, upgrade for free along their own available non-air lines, and gain distinct identities. The maximum-weight deterministic assignment considers movement, ranged roles, defensive strength, naval/amphibious suitability and combat class. Underlying unit classes remain normal Civ V units.

**Summit-Trained** gives **+15% strength, +10 maximum HP, ignore ZOC, 10 HP per kill, combat War Weariness reimbursement, and movement after attacking** where movement remains. It adds to Legendary's +20%, giving +35% before other effects. An attacking Legendary Summit kill heals 20 HP total. Damage is preserved during the Journey; returning is not an unlisted full heal.

The project needs four partners, so four- or five-member journeys return only that many units. The panel still displays all six identity symbols, with the unused identities reserved for later eligible recruits; recruits do not receive free Legendary Training or Summit-Trained. A full six-member journey returns all six. This resolves the specification's four-member eligibility without inventing replacement companions.

Crowded friendly territory causes a deterministic nearest-plot search. If no legal domain-compatible plot exists, the partner remains safely recorded and retries on later turns; already returned partners do not duplicate. Absence penalties end when the countdown ends. Eliminated Red is never revived.

| Identity | Effects |
| --- | --- |
| Pikachu | +2 Movement; +25% strength against stronger base opponents; +10 damage on attacks against full-health units; lethal melee withdrawal to a legal neighbor, once per 5 Standard-speed turns |
| Charizard | +1 Range for eligible ranged units without another Range bonus; +25% attack against cities/fortified units; ignores terrain movement cost; 5 splash damage beside the attacked target; melee fallback keeps melee attacks |
| Blastoise | +25% Defence; 25% less ranged damage; 10 retaliation after surviving melee defence; immediate fortification defence where fortification is supported |
| Venusaur | Heals adjacent friends 10 at Red's turn start; enemies starting adjacent get -15% strength and -1 Movement for that turn; +25% strength in Forest/Jungle; auras do not stack |
| Snorlax | +40% fortified Defence; 15 HP per fortified turn; maximum 1 Movement; anchor recovery against forced retreat; movement-based ZOC also stops normally immune land units |
| Lapras | Ocean access for naval units; safe native embarkation/amphibious access for land units; nonstacking +1 Range; embarked friends within two tiles gain +1 Movement/+15% Defence; +25% damage against naval/embarked targets |

## Interface, AI and compatibility

The upper-right **Champion Team** button opens six scrolling party slots, including names, icons, types, HP/max HP, Training/rank, XP/level, Ribbons, Ace and Summit status. It shows capacity and project/countdown state. Select, inspect, assign/release, bond, item and airlift commands are explicit. Opening/refreshing is read-only. The panel closes for city, diplomacy, popup and nonselection contexts. No permanent frame loop runs.

AI uses the same Training, assignments, bonds, Battle Items, project eligibility and return logic. It favors role diversity, retreats badly hurt veterans when a city path is available, prioritizes the Plateau and queues Mt. Silver when its capital is reasonably safe. Native tactical AI retains army command; returning ranged partners also choose legal visible high-value shots. AI-only gameplay remains a required native test.

Single-player Windows **BNW + CP v151** is the supported target. No replacement DLL, global top-panel file or other civilization's gameplay is replaced. Multiplayer/hotseat/Mac are not advertised. Other versions of CP and full Vox Populi are unverified. Native ScriptData persistence follows the selected game save; a newer sidecar cannot overwrite an older save's ledger. Existing Boundless/Pigeon state formats and the collection UUID are preserved. Existing collection saves do not automatically acquire a new playable civilization.

Music uses the inherited valid **America peace/war soundtrack** from the installed game. No commercial Pokémon audio is distributed, no missing music filename is referenced, and no new music is claimed. Bespoke journey/final-battle music and an optional summit variation remain replaceable aesthetic extensions.

## Speed policy

| Mechanic | Quick | Standard | Epic | Marathon |
| --- | ---: | ---: | ---: | ---: |
| Absence / Battle Item cooldown | 5 | 8 | 12 | 24 |
| Pikachu withdrawal cooldown | 3 | 5 | 8 | 15 |
| Passive Training multiplier | 100/67 | 1 | 2/3 | 1/3 |

Turn counts use rounded `TrainPercent` scaling; Training is stored to two decimal places. The General-point reward uses `GreatPeoplePercent`. Project Production uses native `CreatePercent`. Combat/capture/camp Training and flat HP effects do not scale. Marathon therefore does not multiply passive Training over an equivalent span of history.

For exact engine boundaries, build commands, test results and required native verification, see [ImplementationReport.md](docs/ImplementationReport.md) and [Testing.md](docs/Testing.md).
