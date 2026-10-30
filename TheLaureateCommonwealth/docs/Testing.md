# Validation and native acceptance

Automated checks execute the shipped SQL against an in-memory clone of the installed BNW backup plus actual CP v151 schema, then execute the unchanged gameplay Lua under Lua 5.1 test doubles. `Validation.json` records the official source pin, file hashes and results. Tests distinguish native source evidence from simulated behavior.

**Original implementation validation, 2026-10-30:** focused and full collection checks passed with 67 source contracts. The [recognition hardening](Hardening.md) extends this to **91 pinned CP v151 source contracts and 26 isolated cases across four speeds (104 runs)**, preserving all earlier checks. Current execution results are recorded in `Validation.json`; native acceptance remains pending.

**Hardening execution, 2026-10-30:** both `validate_laureate.py` and the full `validate_mod.py` suite completed with exit code **0**. The full suite ran all 104 hardening cases against the final gameplay Lua, plus the original Lua lifecycle, actual-schema integrity/inheritance/balance, syntax, hook bindings, manifest/project and existing DDS checks. Before/after reproductions confirmed the three unearned-veteran paths, same-tile GP suppression and the reentrant capture-receipt regression. Documentation links, Python compilation, whitespace and unchanged SQL/art/registration checks passed. Unrelated regenerated reports were excluded from the change.

```powershell
.\.venv\Scripts\python.exe tools/validate_laureate.py
.\.venv\Scripts\python.exe tools/validate_mod.py
git diff --check
```

| Required scenario | Automated evidence | Remaining engine acceptance |
| --- | --- | --- |
| Civilization/leader load | Human-only SQL identity, text/reference integrity, single addin, ordered manifests, complete Lua syntax | Select Laurea in Mods setup and start a new BNW/CP-only game; inspect Database.log/Lua.log |
| Icons/loading | Decode 40 real DDS, exact atlas dimensions, full mip chains, XML references and frame/padding checks; inspect original preview | Observe setup, diplomacy, unit flags, Civilopedia and Dawn screens at normal UI scales |
| World Wonders | Ancient 40 and Medieval 60 on Standard; reject National/Team/foreign/invalid city; duplicate and reload receipts; source confirms acquisition has no completion event | Complete two World Wonders in the appropriate eras; capture an existing one and observe zero award |
| Great People | Nine GP fixtures, faith purchase through CityTrained, free/natural creation, birth-era retention, expenditure before turn end, duplicate events, reload, upgrade/replacement, foreign capture and original-owner recapture | Generate/purchase/choose each native type, consume one immediately, capture/return a Prophet, save/reload pending and settled births |
| Veteran | All 14 requested acquisition/progression/ID/reload cases; legacy migration, native capture reset levels, conversion level refunds, qualified-before-save, delayed death and exact same-tile identity; naval/civilian/dead/direct SetLevel regressions retained | Acquire foreign Level 2/3/4 units through gifts and actual military capture, promote/reload/upgrade them, and compare marker and meter behavior |
| Several achievements | GP and veteran on one turn both contribute; source plus threshold model retains overflow at native GA processing | Trigger a Wonder/GP/promotion together near a threshold and compare actual meter/next-turn overflow |
| Four speeds | Actual installed `GreatPeoplePercent`: 67/100/150/300; entire Lua lifecycle suite repeats at each speed | Repeat point checks on Quick, Standard, Epic and Marathon |
| GA bonuses | Actual policy SQL is injected into lifecycle tests; verify start/end, extension, reload inside/outside, ordinary civ exclusion and blocked adoption; native source traces policy caches to city GPP and combat XP | Record city specialist GPP at 100 base: +15 during GA; record combat XP in hundredths with the same base/policy modifiers; repeat after GA ends and after real save/load |
| Champion requirements | Full Swordsman row/companion equality, Iron/technology/cost/Strength/Movement/model/upgrade inheritance; repeat with altered active baseline | Train with and without Iron and inspect technology/production/combat stats |
| Wounded attack | Native field loader and attack/defense formula contracts; no unconditional combat/Movement bonus | Compare preview against healthy/wounded unit, defending and city targets |
| Kill healing | Native field loader and military kill-resolution/HP cap static checks; no duplicate Lua heal handler | Kill a hostile military unit at 40 damage: heal 15, at 5 damage: heal 5; observe no heal for surviving target/civilian capture, no resurrection, and retention after upgrade |
| Hall inheritance | Every Amphitheater field/companion retained except identity and +1 ordinary Happiness; Writing slot/yields/prereqs/cost/maintenance are equal; altered baseline test | Inspect Writing slot, yields, local population-capped Happiness and purchase/build requirements |
| Hall payouts | Three Halls = 3 points; removed/resistance/razing/anarchy cases; repeated callback/reload cannot duplicate; Halls still pay during GA | Earn a real turn, sell/remove/capture Hall, test resistance, compare before/after save within a turn |
| Isolation/performance | SQL/art/identifiers unchanged; no map scan; owner-end resolves pending IDs rather than sweeping armies; 1,000 foreign event batches without army iteration; capture ScenarioData restored; duplicate contexts retired | Native long-game/save and coexistence smoke testing, especially mods that use ScenarioData |

**Native acceptance is pending.** No claim is made that mocked events prove UI rendering, in-engine XP, runtime database logs or real save serialization. No live game was controlled in this implementation. The source-supported numerical modifiers are exact; the documented timing differences are deferred GP recognition, owner-turn polling for direct level setters, and normal engine Golden Age threshold processing. No external art dependencies remain.

Pending native creation candidates now also wait for a safe classification boundary. Existing rewarded markers remain valid on old saves; untracked high-level veterans are closed without retrospective awards. Capture receipts temporarily occupy the native-carried ScenarioData integer and restore its previous value; mods that claim exclusive use of that field during pending capture need a compatibility check. See [Hardening](Hardening.md) for source order and the full test list.

The source audit also records an unresolved native civilian-return path: a returned Great Prophet is recreated by `DoCivilianReturnLogic` with no identity/conversion handoff and can still be counted as a fresh birth. This is outside the correlated capture/recapture cases that pass; it is not presented as a passed GP correctness test. See the [exact limitation](Hardening.md#native-acceptance-still-required).
