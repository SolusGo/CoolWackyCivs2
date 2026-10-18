# Remote Food turn-order hotfix — 2026-10-19

The player recorded stored Food of 203.20, 216.95 and 230.70 on turns 318–320 while the city displayed +37 Food. Storage increased by 13.75 each turn. An earlier screenshot showed an optimistic growth countdown; the player also observed a brief negative Food rate between turns.

## Reproduced failure and repair

`B.Census` invalidates its cached forced-reservation proof whenever the native governor changes local jobs, even when the same default labourers remain. `B.Trim` previously used that conservative admission bound to remove existing remote assignments. Their yields disappeared until the deferred reconciliation rebuilt them. If native growth runs in that interval, it harvests the reduced rate.

The regression starts with two real reserved citizens, 19 remote Food and +25% growth. A local worker moves between two equally yielding tiles; the native default/forced-default counts stay at two. It fires the city dirty callback, harvests Food before dispatching the deferred frame, then runs PlayerDoTurn. The old code harvests **13.75 instead of the advertised 37.50**, reproducing the size of the reported discrepancy. The repaired code harvests 37.50 in all three tested cycles.

Retention now checks the current native census: an existing remote job survives while an ordinary default labourer actually backs it. Real default losses remove excess assignments immediately. Eligibility, ownership, native-worked-plot and automaton checks still apply. This change never creates an assignment; reconciliation still requires its original forced/surplus admission proof. Labourer compensation and all six yield sources keep their existing accounting.

There are no Food-storage/population setters, catch-up Food grants, extra yield multipliers, new events or frame polling. UUID, package version 8, save schema 3 and BCY2 remain unchanged. Old saves need no migration for this repair.

## Evidence and validation

- `tools/tests/food_turn_order.lua`: displayed versus harvested Food across three cycles, immediate worker/specialist reclaim, automata and no unsolicited assignments. Its Food calculation and harvest clock are a separate native model; they do not call a mod Food-grant routine.
- All eleven Boundless Lua 5.1 suites cover source conservation, eligibility, growth/starvation, population exclusivity, ownership, save reload, fault cleanup and dispatcher/UI behavior.
- Six additional contracts in `tools/audit_cp.py` check governor-before-growth ordering, PlayerDoTurn after city economics, cached Food harvesting, preservation of forced defaults and native rate refreshes. The audit now has 182 checks against pinned official CP v151 commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`.
- Full collection SQL, other civilization suites and package/art/hash checks passed. ZIP and genuine 7z Civ5Mod archives were rebuilt with 278 game files; no DDS artwork changed.

The pinned source supports the failure window. It is not the exact `b9ddca9a9` build hash reported by the installed DLL, and the running campaign has not been replayed with this patch. The simulation proves the repaired callback sequence; it does not prove that no other mod or native allocation can change Food between turns.

The existing v7 installation can receive just `BoundlessCitizens.lua` and its manifest MD5 update, with backups, after exiting Civ V. This avoids adding the newer collection content to the current campaign. The full v8 archives include the same repair for normal installations.

## Native continuation check

1. Fully exit Civ V before applying the patch, then restart and load the existing modded save.
2. Record the Food tooltip's **Progress** value and displayed net Food after assignments settle. End one complete turn and reopen the city; compare the new stored value. Repeat once.
3. With stable population, jobs, modifiers and no growth/food-production conversion, the stored increase should match the net rate in hundredths. The integer city label truncates fractions.
4. If population grows, retained Food and the growth threshold affect the difference. Blockades, lost plots, changed specialists, resistance and policy/building changes can also legitimately change the rate.

Do not expect repayment for earlier turns. The fix preserves future credits rather than guessing historical losses. Keep the pre-update save for comparison.
