# Repeatable native acceptance

Status: **NEEDS NATIVE TEST**. Civ V/CP are installed here, but Windows control could not initialize, including after reset. No native gameplay was observed. These steps verify economic settlement, not merely dummy presence.

## Prepare one controlled game

1. Back up saves and the installed collection. Deploy the audited source files listed by the repository modinfo into one collection v17 installation; the inspected installed copy predates Honeycomb. Enable **BNW + (1) Community Patch v151 + Cool Wacky Civs 2 only**. Use Windows single player; disable other ruleset mods and duplicate collection versions. Do not enable Vox Populi. Confirm the collection UUID/version are unchanged.
2. Enable logging in the game's config (`LoggingEnabled=1`); if using FireTuner, enable it deliberately and load a disposable test save. Start a **new Speaker Mellia game**, first Standard speed, then repeat the core thresholds on Marathon. Confirm human selection and exclusion from random AI selection, original Dawn/dialogue, icons, alpha/flag, map and static leader scene.
3. Prepare a stable, non-resisting Commonwealth city with **population 9**, no specialists, and **eight owned, unpillaged, completed Plantations within three tiles**. Use WorldBuilder/a prepared map or FireTuner. Give it enough spare non-Plantation tiles to assign the remaining citizens when testing 0–7 Plantations. Keep Food below its growth threshold, citizen locks fixed, no Golden Age/anarchy and no new policy/tech/route changes during a measurement. Record difficulty, speed and all modifiers.
4. Prepare a Honey Exchange and an otherwise identical no-Exchange state/save. Preserve inherited Market effects. Keep a non-Food-produced item in the queue with enough remaining cost not to finish during the observation; avoid Settlers/Workers and Wealth/Research processes. Keep units/maintenance and other cities stable. Prepare a neighboring foreign civilization for transfer/pillage tests.

## Record and compare actual payouts

Use the city yield breakdown/FireTuner to record flat building yields and full modified rates, current queue Production, stored Food, empire Gold (including fractional values where available), empire Culture and city border Culture. Save or photograph the ledger. The city center's normal yields, terrain/resource yields, Palace, inherited Market benefits, maintenance and every ordinary modifier are part of the baseline, not HCC's unique contribution.

| Worked Plantations | Additional base Production | Additional base Culture | Exchange additional Food | Exchange conditional base Gold |
| --- | --- | --- | --- | --- |
| 0 | 0 | 0 | 1 | 0 |
| 1 | 1 | 0 | 1 | 0 |
| 2 | 2 | 1 | 1 | 1 |
| 3 | 3 | 1 | 1 | 1 |
| 4 | 4 | 1 | 1 | 2 |
| 8 | 4 | 1 | 1 | 2 |

Without an Exchange, both Exchange columns are zero. Four qualifying worked Plantations plus Exchange must add **+4 Production, +1 Culture, +1 Food and +2 Gold as flat base yields**, beyond ordinary Market effects. The actual rate/payout uses native modifiers: with only the inspected Market's +25% Gold modifier, the +2 conditional base Gold adds **2.50 Gold per turn**, not an unmodified treasury increment of 2. Compare hundredths or multiple stable turns to avoid UI rounding. Gold net of empire expenses must be reconciled separately.

For each row:

1. During playable turn T, assign exactly N Plantations and lock the remaining citizens elsewhere. Owning all eight while working one must still use row 1. Record that existing snapshot bonuses have **not** immediately changed.
2. End the owner turn T. HCC stages the next payout using those assignments. Record the staged full rates and stored balances after this boundary if using FireTuner/log observers.
3. At the next owner activation T+1, verify the actual queue Production increase, Food-store change net of consumption, treasury change net of expenses, empire Culture and border-Culture change. Reconcile the increments with the staged full native rates; do not accept only “all dummies are present” as proof. Discard any run that grows, completes the queue item, enters anarchy or changes modifiers.
4. Confirm PlayerDoTurn does not recount changed assignments. Repeat the next boundary, then repeat unchanged assignments and confirm no stacking. Repeat core rows at Marathon; the unique flat rates/caps must remain the same.

## Separate timing and lifecycle cases

- **Interturn pillage:** stage four, pillage one after T ends but before T+1 economics. T+1 still uses staged +4 Production/+1 Culture/+2 conditional Gold. End T+1 with the three remaining Plantations worked; T+2 must use +3/+1/+1. Food remains +1 with Exchange.
- **Interturn repair:** while one remains pillaged, stage three, repair it before the next payout. That payout remains +3/+1/+1; the following owner-end count restores +4/+1/+2. This difference from owner-start sampling is expected.
- **Citizen change/load:** stage four, then change to one during the next playable turn and save before ending. Reload must retain the existing four-Plantation snapshot, without extra stored Production/Gold. End that turn; the subsequent payout uses one-Plantation bonuses. Repeat around the owner-end autosave and after context recreation.
- **New Exchange:** construct/grant it after a snapshot. Food follows native building possession; conditional Gold waits for a new owner-end snapshot. Save/reload immediately after construction and confirm no early Gold.
- **Removal/rebuild:** pure CP's zero-maintenance Market/Exchange cannot normally be manually sold. Do not add maintenance to enable a test. Use FireTuner/notified scripted removal to test disappearance: Food and conditional Gold disappear, UA Production/Culture remain. Grant/rebuild Exchange: Food returns, Gold waits for the next snapshot. A legal CitySoldBuilding path can be tested only in an explicitly separate altered-Market-baseline fixture; it is not claimed available in ordinary CP. Test a silent/coalesced removal separately and record when the dirty/owner-turn defense actually detects absence.
- **Transfer:** stage four plus Exchange, then separately conquer, gift, liberate and recapture. Inspect the reconstructed city's ownership and yields. Foreign recipients must have no HCC dummy contribution; newly acquired/founded Commonwealth cities wait for their next owner-end snapshot. Repeat an HCC→HCC transfer if a test harness can create a second owner without enabling normal AI selection. Raze/destroy and refound a city, then save/reload: no stale city-ID target may replay.
- **Forager:** compare to the active Scout record and a native Scout control. Expect identical Combat, requirements, terrain/recon/ruin behavior and normal upgrade relations, Moves+1 and Sight+1 only. Verify ordinary upgrade removes the unique Sight. No Worker action, resource harvest or combat modifier should appear.
- **Foreign control/multicity:** repeat Market/Scout/Plantation observations with another civ. Build the four-city example (4+Exchange, 2+Exchange, 1 without Exchange, 0+Exchange); unique base totals must be Production **7**, Culture **2**, Food **3**, Gold **3**, before normal modifiers.

## Logs and acceptance record

Inspect **Database.log** for failed SQL, unknown columns/tables, duplicate identities and invalid localization/art references. Inspect **Lua.log** for `HCC:` failures, invalid journal/city messages or callback exceptions. Injected mock diagnostics in the automated suite are not live-game evidence. If a native write fault is deliberately injected, retain the save/journal and confirm bounded recovery replays the original target rather than changed assignments; do not claim a missed payout was retroactively restored.

For every native row/case record save name, speed, turn, owner/city, assignments, pillage/Exchange state, base/full rates, before/after stored balances, expected/actual result, screenshots/log extracts and classification. Mark **PASS** only after observing both rates and settlement. Leave render/save/event-delivery cases **NEEDS NATIVE TEST** until executed.
