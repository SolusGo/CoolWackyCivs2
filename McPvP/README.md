# McPvP — The Endless Lobby

**Leader:** The Old Guard. **Capital:** Lobby One. **UA:** Just One More Game. **UU:** Veteran PvPer (Scout). **UB:** Original Server Hub (Barracks). Built for BNW and Community Patch v151. Preferred victories: Domination and Culture.

The match ends. The memories don't.

Open **McPvP Server Browser** from the upper-right world-map button. The panel shows the active and queued mode, countdown, current and lifetime Server Legacy, victories, objective progress, Feast coordinates, last match summary and selected-unit actions. Choose a mode for the **next** cycle; the first cycle defaults to Hardcore Games. Queueing does not reset progress. Select a military unit on the map, choose a kit, then cycle the available targets and use the corresponding action. Tooltips explain eligibility, range and cooldowns. Panels close during diplomacy, city screens, popups and turn transitions.

## Matches

| Mode | Objective and rewards, before speed/era scaling |
| --- | --- |
| Hardcore Games | Three opening turns grant +10% defensive strength. The Feast is announced three turns before activation at match turn 10, and expires at turn 15. The first eligible non-barbarian land military occupant claims 75 Gold, 20 XP and 25 healing, including rival civilizations. McPvP gains 15 Legacy for claiming. In Final Battle, military units gain +20% combat XP; eligible major-civilization kills grant 3 Legacy, capped at 15 per match. One additional 10 Legacy is available for a kill within two tiles of the active, unclaimed Feast. Securing the Feast wins. |
| Capture the Flag | An unembarked land military unit adjacent to a visible city at war can steal its flag, consuming movement. Each city can be raided once per cycle, including failed returns. Carriers retain movement but cannot attack and suffer -15% defense. Return with movement remaining on a land tile belonging to one of your cities, using **Return flag**. Gain 25 Legacy, 40 Culture, 50 Golden Age Points and 15 XP. One return wins the match. |
| Sabotage | A Veteran or reconnaissance unit within two tiles of a visible city at war starts a three-turn infiltration. Remain within range and keep the city visible; death, ownership change, leaving the area or the match ending interrupts it. The defender receives the infiltrator's coordinates after the first turn. Completion grants 20 Legacy, 15 XP and 25 Gold, and applies -20% Production and -15% Gold to the target for five turns. Each city pays once per cycle. One completion wins. |

Winning grants an additional **10 Legacy once per match**. Mode victories and completed matches are tracked separately. Sabotage debuffs can outlive their originating match, expire normally, and never stack when multiple McPvP players target the same city.

Feasts use revealed, passable land four to sixteen tiles from the capital, connected by a legal land route and with at least three reachable neighboring approaches. Bounded searches account for water, mountains, closed territory, movement costs, rival access and whether an available McPvP military unit can arrive before expiry. Another McPvP player's reserved Feast is excluded. There are at most three preparation searches, allowing turn-zero capital founding and early exploration. Notification coordinates and **Locate Feast** provide the map indication. Secure the tile with a unit that remains there until the deferred native movement check. If no suitable site is found within the search budgets, the match proceeds with Grace Period, Final Battle and kill rewards; no Feast victory is awarded.

## Kits and veteran progression

Kit selection requires movement and consumes it. Units trained or purchased in a Hub receive kit eligibility; the Veteran starts eligible. Active kit abilities require an unembarked land military unit, movement, a valid visible enemy at war and a completed cooldown. Units carrying flags or infiltrating cannot activate kits or retrain. Kangaroo and Viper are passive.

| Kit | Effect |
| --- | --- |
| Kangaroo | +1 land Movement and -10% defensive strength; normal movement and terrain legality. |
| Stomper | From a hill, deal 20 damage to one adjacent enemy land military unit on flat ground; five-turn cooldown. |
| Endermage | Pull one enemy land military unit within two tiles onto an empty, passable adjacent land tile legal for the victim; seven-turn cooldown. Cities, occupied destinations, embarked units and invisible targets are excluded. |
| Thor | Deal 15 damage to one visible enemy military unit within two tiles; five-turn cooldown. Units inside cities are excluded. |
| Viper | A direct attack that damages a surviving enemy military unit applies 5 poison damage at the start of its next two owner turns. Reapplication refreshes the two ticks, without stacking. The poison remains functional if the attacker dies. |

The Veteran has **6 strength**, the active Scout's normal mobility, reconnaissance promotions and upgrade path, and **+25% combat XP**. Native Recon promotions remain additive. Veteran identity, kit eligibility, chosen kit, XP bonus and cooldowns survive normal upgrades. A Veteran may change kits every **15 turns** inside an owned city. Other units keep their initial kit. A change consumes movement and starts the new ability's recharge without shortening an existing cooldown. Normal earned promotions and experience remain intact.

Ordinary upgrade, gift and disband commands are blocked while carrying a flag. Embarking, forced conversion/upgrade, losing the target, making peace or ending the cycle loses the flag. Forced upgrades also interrupt infiltration. Ownership transfers clear kit privileges and objective metadata. These checks prevent carrying an invalid flag through native edge cases.

The Hub retains the active Barracks scalar values and companion-table benefits, adds **+1 Culture and +1 Gold**, and grants **2 Legacy once per military unit trained or purchased there**. Free creation, captures and upgrades receive no training award. Land military trainees can select kits; naval and air trainees receive the training Legacy but do not use land kits.

## Server Legacy and remembrance

Current and lifetime Legacy increase together; nothing arbitrarily spends the balance. Every 25 lifetime Legacy grants +1 Culture in the current capital, capped at +8. Capital relocation moves this bonus. The first entry into the Information Era triggers **THANKS FOR PLAYING — Legacy Unforgotten** exactly once: all military units gain permanent +10% combat XP and the capital gains `floor(lifetime / 50)` additional Culture, capped at +10. This Culture continues to grow after the event. Matches and kits continue.

## Scaling, saves and AI

Time-based mechanics use the actual GameSpeed `TrainPercent`, rounded to the nearest turn with a minimum of one. Matches last **13 / 20 / 30 / 60** turns on Quick / Standard / Epic / Marathon. Cooldowns, Grace Period, Feast timing, infiltration and debuff durations scale the same way. Economic rewards use `GoldPercent`; Culture and Golden Age Points use `CulturePercent`, each multiplied by `1 + 0.25 × era index`. Listed percentages, movement, XP awards, Legacy and fixed damage stay constant. Viper always delivers two 5-damage ticks.

Authoritative state lives in the selected save's player and unit ScriptData, preserving other mods' data. Serial-tagged records, creation turns and explicit upgrade handoffs protect against stale IDs. Save/load restores modes, Legacy, cooldowns, flag origins, missions, debuff expiry and remembrance. Corrupt or future state is rejected without overwriting it. The other collection civilizations keep their own save formats.

AI McPvP checks reachable military/recon opportunities, assigns role-based kits and uses real objective actions. Verified native route queries are checked for legal land travel; a bounded weighted search provides detours when necessary. Carriers prefer safer return routes, and infiltrators hold their operational area. Routes are rechecked as units, access and targets change; repeatedly failed movement is released and briefly cooled down. Busy units and unrelated native orders are preserved. Search limits may defer or decline distant objectives, and the game's tactical AI can still change plans. No objective is awarded for free. See the [reliability report](docs/ReliabilityReport.md) for exact budgets and remaining native checks.

Single-player is the supported target. Multiplayer and hotseat remain disabled in the collection; Browser mutation commands also reject network multiplayer. Custom actions use the collection's existing single simulation-owning UI-addin pattern and have not been proven synchronized in multiplayer.

## Install and validate

Build/install the collection using the root README; McPvP is included automatically. Start a new game and select **The Old Guard**. Adding this module to an existing save does not turn an existing civilization into McPvP.

```powershell
.\.venv\Scripts\python.exe tools/generate_mcpvp.py
.\.venv\Scripts\python.exe tools/prepare_mcpvp_art.py
.\.venv\Scripts\python.exe tools/build_mod.py --manifest-only
.\.venv\Scripts\python.exe tools/validate_mod.py
.\.venv\Scripts\python.exe tools/build_mod.py
```

Regenerating artwork requires refreshing its retained icon masters through `standardize_icons.py --refresh-sources MCPVP_CIV_ATLAS MCPVP_OBJECT_ATLAS MCPVP_LEADER_ATLAS MCPVP_PROMO_ATLAS`. Ordinary builds reuse the committed originals.

See [implementation and limits](docs/Implementation.md), [delivery report](docs/ImplementationReport.md), [native testing checklist](docs/Testing.md), and [changelog](CHANGELOG.md). SQL, CP source contracts and Lua simulations pass; native Civ V gameplay, rendering and save round trips have not been tested.
