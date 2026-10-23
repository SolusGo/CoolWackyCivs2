# The Substitute Classroom — Mr. Garvey

Human-only civilization for **Brave New World + Community Patch v151**. No Vox Populi requirement. Capital: **Room 101**. Included in collection version 12 / 1.9.0 preview.

## Insubordinate and Churlish

Open **ROLL CALL** on the right side of the normal game view to inspect the attendance sheet. The first choice unlocks 12 player turns after founding your capital. An available choice waits indefinitely. Selecting a student starts a new 12-turn cooldown and gives exactly eight turns of one bonus:

| Student | Bonus | Correction chance |
| --- | --- | --- |
| A-A-Ron (Aaron) | +15% military unit Production in every city | 50% |
| Dee-Nice (Denise) | +15% city Culture in every city | 50% |
| Jay-Quell-In (Jacqueline) | +15% city Science in every city | 50% |
| Buh-Lah-Kay (Blake) | +15% Combat Strength for eligible military units | 50% |
| Timothy | +10% city Production, Gold, Science, Culture and Faith | **0%** |

These are native percentage modifiers to ordinary city yield pipelines, with normal Civ V rounding, resistance and queue rules. They do not multiply instant rewards or maintenance. All turn counts are fixed on Quick, Standard, Epic and Marathon. No turn expires merely because you open a panel or load a save.

Each correction adds one persistent Insubordination: **0/3 Calm**, **1/3 Irritated**, **2/3 Furious**. The third correction immediately triggers **DETENTION**, then resets the counter to zero. The panel shows the triggered 3/3 banner and explicitly reports the reset counter while Detention is active.

## DETENTION!

For five player turns: +20% military strength, +20% military unit Production in every city, Culture from enemy military kills, and **-2 Global Happiness**. One or more Principal's Offices reduce the penalty to **-1**, once per empire. Office construction, sale, capture and capital changes reconcile the effects. All temporary effects are removed on expiry.

Kill Culture is `max(1, floor(max(base melee strength, base ranged strength) * 25 / 100 + 0.5))` per effect. This matches CP's choice of base strength; the configured reward is fixed, without additional era or speed scaling. Hall Monitor and Detention rewards each round separately and may stack. Civilians, city captures, surviving targets and duplicate combat completions pay nothing. Detention uses attributed lethal military damage, including nuclear and collateral damage. Hall Monitor rewards use CP's ordinary result/completion pair and the actual battle tile. Captures, disbands and nonlethal scripted removals do not award Culture. Saved unit-lifetime markers prevent delayed death callbacks from paying twice, including across loads.

Roll Call and Detention are independent: Buh-Lah-Kay and Detention grant **+35%**, as additive native modifiers. A Hall Monitor also receives its own +10% during Detention, and +15% when fighting in friendly territory.

## Unique replacements

- **Hall Monitor / Pikeman:** preserves all active CP Pikeman properties, free promotions, resource requirements and upgrade rows. Adds +15% strength in native friendly territory, Culture for military kills on friendly battle tiles, and +10% strength during Detention. Uses the ordinary Pikeman model with a distinct shield/checkmark icon and flag. Hall-specific training ends on upgrade; eligible upgraded units still receive active empire bonuses.
- **Principal's Office / Public School:** preserves all active Public School benefits, specialists, requirements and companion rows; adds +2 Culture and +2 Production. Each Office gets +10% Science during Detention. Only the first Office is needed for the non-stacking Happiness relief. BNW has no generic `BUILDING_SCHOOL`; the appropriate replacement is `BUILDING_PUBLIC_SCHOOL`.

Captured Offices follow native replacement/capture rules. A foreign owner receives no classroom temporary effects. The civilization is `Playable=1, AIPlayable=0`; the runtime requires a living human Classroom player.

## Strategy and configuration

Choose A-A-Ron for an army buildup, Jay-Quell-In for a research push, Dee-Nice for policies, or Buh-Lah-Kay for a campaign. Timothy offers the broadest reliable economy and never raises Insubordination. Choose riskier students when the next correction would align Detention with a planned war. Build an Office before that third correction when possible, and defend friendly ground with Hall Monitors.

The clearly named **CONFIGURATION** block in [the generator](../tools/generate_garvey.py) defines intervals, durations, all five correction probabilities, combat/yield percentages, Office bonuses and kill rounding minimum. Regenerate with `python tools/generate_garvey.py`; its `GARVEY_Config` SQL table supplies both native database modifiers and Lua. Initial English descriptions reflect the default balance.

Install the collection's version 12 ZIP or `.civ5mod`, enable Community Patch and this collection through Mods, and start a new modded single-player game. Only English and static 2D diplomacy art are supplied. Multiplayer, hotseat and Mac are unsupported. Existing identities and save formats are retained; native continuation of old collection saves has not been verified.

[Implementation](docs/Implementation.md) · [Testing and native checklist](docs/Testing.md) · [Validation report](docs/Validation.json) · [Changelog](CHANGELOG.md)
