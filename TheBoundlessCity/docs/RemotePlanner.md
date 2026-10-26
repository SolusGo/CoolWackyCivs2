# Remote workforce planner — 2026-10-26

Automatic and Hybrid assignment compare distant work with ordinary labourer output and the local jobs required to support it. Safe unchanged reservations and their yield ledger can stay in place. Candidate yields are cached, and only a bounded best set is sorted. Manual mode retains direct control.

## Useful jobs and stable choices

The existing six-yield priority weights remain unchanged; frontier expansion scoring is also unchanged. Automatic remote candidates must beat native ordinary labourer output. A one-Gold remote tile no longer consumes a one-Production labourer under Production priority. Explicit Manual requests and Hybrid locks can still choose that trade.

For each possible job count, the planner subtracts labourer compensation and the opportunity cost of the local withdrawals needed for native proof. Surplus and forced reservations **overlap**: crossing a surplus of ten to request eleven jobs can require eleven forced withdrawals, not one. The calculation accounts for that complete cost. Recorded withdrawal origins remain in the session cache so an already displaced Farm is not mistaken for free idle labour later; those records guide scoring and do not authorize workers.

Existing assignments receive a one-weighted-point switching margin; incumbents win ties before plot index. Decisive improvements still replace them. Eligibility and citizen exclusivity always override stability. Native specialists and local locks keep their existing rules.

This remains a constrained heuristic around the native governor. It does not optimize every possible local/specialist placement, great-person progress, worked-only effects or production-queue outcome. Safe capacity limits remain unchanged.

## Food minimum

The **Food minimum** button beside **Siege demolition** cycles **Off → 0 → +2 → +4 → +6 → Off**. The default is **0 net Food**, aiming to avoid starvation. The optional preference is saved in existing schema-3 state. Old saves receive the default without a migration. `B.Config.RemoteFoodTarget` controls that default; the action API accepts integers from -1 (Off) to 20.

Automatic and Hybrid modes make economic choices, then read actual native `FoodDifferenceTimes100`. If the minimum is unmet, up to five planning passes increase Food's value. The final rescue weight scales with the available economy, so an unusually large Production yield cannot defeat a modest feasible Food target merely by exceeding a fixed bias. Native feedback includes consumption, growth modifiers, trade and Food production; there are no guessed growth multipliers or stored-Food grants.

An unchanged environment reuses its successful Food bias. Candidate, census, priority, target or actual net-Food changes trigger reconsideration. This bounded feedback heuristic does not guarantee the most profitable possible allocation satisfying a Food constraint.

Manual mode ignores the safeguard and disables its button, retaining the preference for later. Hybrid remote locks and native local locks remain authoritative. If available land, locks, safe capacity, native allocation or Food-to-Production conversion prevent the target, a red **!** appears on the button and its tooltip reports the current rate. A zero minimum does not promise growth. An impossible positive minimum never creates Food or citizens.

## Reconciliation and recovery

Unchanged validated jobs no longer require removing every remote yield, returning every labourer and reserving them again. Actual source changes remain delta-based and journalled; transactions save a recoverable phase before mutation. Identical player/plot ScriptData is not rewritten. A physical terrain source smaller than its saved contribution is still rejected, including when desired jobs are unchanged.

Full reservation renewal remains necessary on initialization/recovery, an unexpected census/governor change, releasing excess forced workers and the mandatory end-turn check. That check cannot be removed merely because cached jobs look unchanged: the supported DLL exposes no trustworthy forced-default getter.

## Territory scaling and measurements

The cache stores native six-yield vectors and eligibility. Improvement/feature/route events invalidate the affected owned plot and adjacent owned plots. Hostile movement uses the existing affected-plot index. Broad technology/policy refreshes invalidate globally. Ownership changes rebuild membership. The first reconciliation in each game turn rechecks owned territory to catch missed updates.

Only the best **K** remote candidates, bounded by safe capacity, enter a heap and final sort. Changed ranking contexts still inspect cached candidates, but no longer sort all owned plots. Unchanged facts reuse rankings. Watch indexes rebuild only when their membership inputs change.

The [actual-Lua comparison](RemotePlannerBenchmark.json) used the same native model, 150 population, a 16,000-plot world and seven samples per measurement:

| Owned plots | Previous forced full update | Updated forced full validation | Updated known-unchanged update |
| --- | ---: | ---: | ---: |
| 250 | 5.203 ms | 3.967 ms | 2.686 ms |
| 2,500 | 20.392 ms | 14.847 ms | 2.977 ms |
| 10,000 | 55.608 ms | 46.634 ms | 2.444 ms |

Repeated unchanged updates in that fixture went from 34 modeled native mutations and two player ScriptData writes to **zero of each**. A known-unchanged update read 2,520 plot yields independently of owned territory. Full rechecks still scale with land size. These are synthetic Lua timings, **not native Civ V FPS or turn-time measurements**. Run `tools/benchmark_remote_planner.py` to repeat them; timing varies between runs.

## Validation and continuation

`tools/tests/remote_planner.lua` covers idle/local opportunity cost, the overlapping reservation boundary, switching stability, unchanged/event-storm updates, mandatory renewal, native Food feedback with positive-only growth modifiers and extreme economic yields, impossible Hybrid locks, Manual authority, save normalization/reload, an independent exhaustive small-job oracle and 2,500-plot incremental reads. Existing workforce, fault-journal, growth, ownership, siege, dispatcher and UI suites remain enabled. Native Food feedback is checked against pinned official CP source.

The update adds `BoundlessPlanner.lua`, changes the Boundless Core/Citizens/Events/Persistence and Workforce Lua/XML, and adds five Food-control strings. Gameplay SQL, textures, collection UUID/version 17, schema 3 and BCY2 remain unchanged. A guarded existing-installation hotfix can update matching v7/v8/v10/v14/v17 Boundless modules and append just the new localization values; older mismatched installs are left alone.

Fully exit Civ V before installation, then restart through **Mods**. Existing saves need no new campaign. Native acceptance remains pending: verify the Food control at your resolution; try Production with a Food minimum, Hybrid locks and Manual mode; end several turns and compare stored Food with the displayed rate; save/reload; and test a blockade or reclaimed worker. Keep the pre-update save. Installation does not edit saves, logs or cache databases.
