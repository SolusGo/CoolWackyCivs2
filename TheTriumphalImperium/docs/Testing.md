# Validation and native acceptance

`tools/validate_triumphal.py` activates the actual SQL over a read-only BNW
snapshot with explicitly overlaid installed CP v151 schema, then runs the shipped
Lua under Lua 5.1 through the existing Lupa development dependency.
`Validation.json` records the actual results and local prerequisite paths.

Database checks cover full collection co-activation, preservation of all prior
rows, complete Swordsman/Barracks field and companion inheritance (including a
mutated baseline to catch hardcoded balance), replacements, human-only selection,
unique types, localization, exact modifiers, atlas references and SQLite integrity.
All module XML/Lua parses. All 40 DDS files decode and have complete mip chains.
Pinned C++ source assertions check event arguments/order and native modifiers.

The Lua fixture uses real database promotion/building values. It exercises:

* Initial zero, distinct melee/ranged/air deaths, city shots, defensive victories,
  cap and victory activity at the cap; duplicate prekill/kill/capture callbacks.
* Exclusion of barbarians, minors, civilians, unmatched events, full-health
  script deletion, friendly/neutral blast deaths; inclusion of native attributed
  enemy military nuclear combat deaths and nuclear payload classification.
* Conquest 3→5, free actual Hall, 6→+12%/+24%, and additive +34% in a Hall city.
* Diplomatic transfers, recapture farming, immediate foreign-city cleanup,
  Bronze Working deferral, load while pending, loss/liberation, razing and
  refounding, repeat technology events, founded cities and native free Halls.
* Full-cycle decay, intervening defensive victories, duplicate boundaries,
  zero floor, cap, save-at-five reconstruction and late-era first turns.
* Creation/purchase, completed upgrades, gifts/returns, permanent Advance,
  removal of temporary March, unrelated movement and no move refill.
* Hall construction and sale, active human UI ownership, six segments, threshold/tooltips, city-screen
  hiding/recovery, construction-list guards and subscription retirement.

The complete contract suite runs separately on Quick, Standard, Epic and
Marathon. It does not substitute a mock-derived result for native acceptance.
Game speed intentionally does not scale the specified one-owner-cycle decay.

## Native tests still required

No Civilization V process was started for this implementation. The following
remain **NOT RUN** in the actual game, rather than failed or silently omitted:

| Scenario | Required native observation |
| --- | --- |
| A | New Imperium starts at 0, no empire bonus or free founded-city Hall |
| B | Three major military combat kills give 3, +6% Strength and +12% military Production |
| C | Conquest at 3 gives 5 and a real Hall after Bronze Working, including a puppet |
| D | At 6, combat preview shows +12%; native production help includes +24%, plus +10% in Hall cities |
| E | Quiet complete cycle decays once; defensive interturn victory prevents it; city production settles under native ordering |
| F | Upgrade retains +10% attack, loses March, keeps other promotions and does not refill moves |
| G | Save at 5; exit and load the actual save; remain at 5 with correct modifiers and pending eligibility |
| H | Barbarian, minor, civilian, disband, out-of-combat script Kill and city gift give no Momentum |
| I | Land/naval/air defense, interception and city bombardment kills register once |
| J | Quick/Epic/Marathon and late-era starts obey prerequisites and identical cycle timing |
| UI | At supported resolutions the small panel, gold laurels, hover text, city/diplomacy hiding and leader/dawn/map art render correctly |
| Saves | Native autosave/manual save before and after a boundary cannot replay decay, conquest or kill awards |

No missing custom art references, pseudocode, custom DLL or new gameplay
framework remains. New animated leader art and voiceover use a static/silent
presentation by design. Arbitrary third-party code that forges native events is
outside what Lua can authenticate; ordinary deletion is covered by the lethal
battle-participant and authoritative-callback checks.
