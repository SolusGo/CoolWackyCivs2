# Jin testing record

No native Civ V session has been launched for this implementation. **Gameplay, UI rendering and actual save-file acceptance are NOT RUN.** SQL/serialization/movement/combat tests below use Lupa Lua 5.1 with behavioral native doubles and the actual installed database output. They do not establish in-game correctness.

## Reproduce

From the repository root, using the existing `.venv/Scripts/python.exe` on this machine (or another Python 3.11+ with `requirements-dev.txt` installed):

```powershell
python -m pip install -r requirements-dev.txt
python tools/generate_jin.py
python tools/prepare_art.py
python tools/build_mod.py --manifest-only
python tools/audit_cp.py --fetch
python tools/audit_jin.py --fetch
python tools/validate_jin.py
python tools/validate_mod.py
python tools/benchmark.py
python tools/benchmark_jin.py
python tools/benchmark_jin_hardening.py # standalone before/after profiler; also invoked by both benchmarks above
python tools/build_mod.py
python tools/verify_release.py
```

The source audits fetch pinned official v151 source into ignored `tools/reference`. Database validation opens the installed backup cache/CP schema read-only and executes changes in memory. No game cache, active saves or installed mod folder is modified.

`docs/Validation.json` records actual successful Jin runs. `SourceAudit.json` records pinned source identities; `Benchmark.json` records the original synthetic scenarios and `HardeningBenchmark.json` compares baseline commit `f252c63` to the shipped Lua at 100/300/500 units. Neither measures native FPS/pathfinding. [Hardening.md](Hardening.md) records findings and verification limits. `Verification.md` preserves the original implementation's command outcomes. A failed or stale manifest check requires regenerating manifests after the final source changes.

## Automated coverage

- Installed CP schema: human selectable / AI disabled; all unit/landmark definitions, localization, prerequisites, native effects, atlas dimensions and DDS decoding. Unknown scalar columns and Worker/Caravan companion inheritance are exercised with injected future baseline data. Existing collection rows are compared before/after Jin SQL.
- Economy on Quick, Standard, Epic and Marathon: one chosen site from three, independent Pasture/Grassland stockpiles, timing, five-Horse caps, duplicate turns, reload, exact melee/ranged HP, pillage, ownership loss, old-state rollback, separate-game state, stale clicks, failed placement/spawn/resource checks and 20-unit cap.
- Diplomacy: two Emissaries, free award once, independent persistent Tributaries, native Food staging, boolean trade modifier, war/elimination, protected civilians/neutrals, failed replacement, Barbarian ownership/hostility, charged successful Bribe, cooldown and rebel expiry.
- Combat: actual CP argument order, primary-target second bolt, per-unit scatter amounts, friend/neutral protection, duplicate suppression, nonlethal collateral, automatic defender cap/cooldown, native movement leash, parent loss/expiry and Chemistry upgrade.
- Landmarks on all speeds: paired locks, real production order, all six choices across scenarios, pending opportunities, local Garden promotions/relocation/reload, Karma generation/death deduplication, four economic-turn blessing, all named upgrade purchases, Grove count/per-city caps, once-per-turn slowing and crowded/coastal site handling.
- UI/context/lifecycle: all six tabs and callbacks, era/choice gating, real site selection, active-player isolation, old-context detachment, lost-capital state, eliminated-player behavior, corrupted-data rejection and no-Jin dispatch.

## Required native acceptance matrix

The hardening pass extends the seven original suites with **jin_autonomy.lua**, **jin_transactions.lua** and **jin_hardening.lua**: 16 total suite/speed runs, including the original four-speed economy and Landmark coverage. These execute shipped functions for deferred melee/ranged engagement, priority/LOS, return/leash, turn ownership, saved budgets, combat-busy expiry, Fort pillage/capture, overlapping caps, exact HP deltas, unchanged writes, immutable snapshots, actual distant enemy movement, synchronous post-create failure, silent write failure, saved payment/refund, partial Bribe recovery, altered Barbarian diplomacy, UI burst/error recovery, player switch and shutdown. Expected injected diagnostics are asserted; unexplained Jin errors fail validation. Source checks establish the actual numeric mission ABI, event phase, Food/purchase/trade speed/plunder contracts. They do not simulate the full native trade engine.

XML geometry review uses the actual centered 980×680 frame, 932×365 scroll area and 910×62 rows at 1280×720 and 1920×1080. The frame fits both; font wrapping and scrollbar operation remain native acceptance, not a screenshot claim.

Run a **new game** with CP v151. First use Standard, then repeat major systems and saves on Marathon; make focused Quick/Epic timing checks.

1. Verify setup icon/alpha/portrait/map, city names, Civilopedia, Dawn, silent static diplomacy, unit flags, model visibility and crimson-and-gold panel at 1280×720 and 1920×1080. Scroll all tabs and inspect disabled reasons.
2. Confirm regular Worker remains trainable, Mounted Villager cost/movement/work speed and all Worker improvements/routes/repair. Verify 20 active units are allowed and the next is blocked; a Tributary permits three more. Confirm the mounted model's borrowed animation limitations are acceptable.
3. Complete both possible paths in each tier in separate games. Check costs, true production completion, no selling, permanent alternative lock, Grassland offer and one selection only. Test tiny islands, occupied neighborhoods, capital loss before choosing, later legal land and no overwritten infrastructure.
4. Measure every ordinary stockpile and Pasture across intervals/full cap, pillage/repair, improvement destruction, border transfer, capture and recapture. Spend exactly one Horse plus discounted Gold. Test insufficient Gold, missing technology/resource, full city tile, native caps, resistance/razing, queued duplicates and rapid clicks/reopening.
5. Inspect max/current HP before/after Horse generation/spending, wounded-army transitions, new training/purchasing/upgrading/gifting/capture, ranged cavalry and excluded units. No Horse effect may remain on enemies or grow by reloading.
6. Attack units and cities with all unique military types; verify primary outcomes, nonlethal collateral, three-target limits, anti-cavalry and ranged defenses, Mohe movement with one attack, Bed second damage, Eruptor range and Grenadier explosive damage. Confirm native `CombatEnded` unit handles and visibility checks at dispatch.
7. Walk two Emissaries to two independent City-States. Verify Food in displayed/native growth rates, capacity and one +15% native trade modifier, then war, City-State conquest/elimination, Jin capital transfer and Jin elimination. Ordinary City-State influence must remain normal.
8. Bribe protected/ineligible/eligible hostile groups; use no-barbarian scenario settings too. Confirm rebels fight both sides, original units survive failed replacements, Gold/cooldown charge once, finite lifespan, no foreign unique promotions and no player command over rebels.
9. Trigger defenders from enemy movement and owner turns at cities, Forts and Citadels. Confirm orders execute only after native movement/unit-turn processing returns and during the active Jin turn. Compare Quick Combat/Quick Movement enabled and disabled. Test simultaneous threats, closest-to-parent priorities, melee approach/attack, native ranged LOS/war/range, blocked greedy paths, guard/return, one order per owner-turn, overlap/capacity/cooldown, city capture and ordinary move/gift/upgrade attempts. Kill a defender; pillage/capture/destroy its parent; expire it while fighting. Confirm it retires after combat, and Chemistry future spawns use Grenadiers. Save deployed/acted defenders and reload before/after the unit reset boundary.
10. Place/relocate Garden; leave/reenter its radius with workers/military/siege. Verify exactly one active effect. Generate/lose Karma, trigger/reload/expire blessing and inspect actual Farm/Faith/healing/strike changes. Produce 15 Groves across three cities; verify five-per-city, worked Production, destruction/capture and movement slowing once per turn.

Save/reload at each of these points: before first choice; while a Grassland offer is pending; partial stockpiles; immediately after recruitment; several Tributaries; Bribe cooldown; live defenders; active blessing; Garden relocation cooldown; all three tiers; loss of an ordinary city; loss of capital; Jin elimination. Load an older save of the same match, then alternate two distinct matches at the same turn number. Check Lua.log/Database.log for errors and verify that no counter, unit, yield or reward leaks or duplicates.

Finally play an existing civilization and a game with no Jin. Repeat existing civilization suites; inspect their unchanged gameplay and save behavior. Native performance and practical balance require a large-map game with many cities/units; synthetic timings are not an FPS estimate.

Additional hardening acceptance: train a Reindeer Trader in a growing city and verify Food conversion/growth pause, cancel training and verify growth resumes, compare native Gold prices with an ordinary Caravan under equivalent modifiers, launch to native capacity, observe the faster route progression, wait for completion/idle-unit return and recall, then plunder a route. Confirm no extra route slot or Lua income, ordinary plunder still destroys it, and Mountain Hall loses no Karma on launch/return but loses one death penalty on plunder. The shipped code does not replace these native route operations.

Use a debugger/save harness to snapshot between a recruit's UnitCreated and its settlement, and between successful/failed members of a Bribe group. Reload each snapshot, confirm exactly one Horse/Gold charge per retained recruit and only real Bribe conversions paid, and verify that a pending ambiguous receipt logs and blocks further purchases without resetting progression. Actual save-file snapshots at these native call boundaries remain untested.
