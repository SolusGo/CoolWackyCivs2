# Testing and native acceptance

Automated entry point: `tools/validate_rfd.py`. Collection entry point: `tools/validate_mod.py`. Use the existing [prerequisite setup](../../docs/ValidationSetup.md). No added dependencies are needed. `docs/Validation.json` records executed results and fixture provenance.

The tests run the **shipped Lua controller under Lua 5.1**, with actual-schema building/class/speed rows and mock engine events. They are not in-game testing. SQL checks execute every released civilization before RFD, assert no previous rows/IDs disappear or change, compare inherited scalar/companion rows, alter baseline stats/prerequisites/yields to detect hardcoding, and validate text/art/manifest registrations. Lifecycle tests cover thresholds, duplicates, exclusions, purchases/free grants/capture, turn timing, removal, stale identities, human guards, restart, ledger corruption and interrupted payout/dummy writes.

## Native checks still required (A–S)

Enable Lua/database logging, activate BNW + CP v151 + this collection, and begin a new human Republic game on Standard. Use an ordinary small map with another civilization. Compare changes to pre-evaluation balances, accounting for ordinary turn income. Use FireTuner or a test save for controlled building additions/removals. Check Lua.log and Database.log for errors.

| Test | Native acceptance expectation |
| --- | --- |
| A: first qualifying class | Monument present at next PlayerDoTurn gives +12 Culture/+20 Gold. |
| B: repeated class | Another Monument in any city gives no second reward. |
| C: five distinct classes | Lifetime UA total +60 Culture/+100 Gold. |
| D: loss/rebuild/save | Sell/remove the Monument, save/quit/reload, rebuild it: no further reward. |
| E: capture | An unfamiliar qualifying captured class rewards only if it remains at evaluation. |
| F: wonder/Palace exclusion | World/national/team wonders and Palace give no UA reward or UB class count. |
| G: purchases/free buildings | Eligible Gold/Faith purchases and free buildings count; transient removed ones do not. |
| H: Workshop thresholds | Including the UB, test 0–3/4–7/8–11/12+ classes: 0/1/2/3 additional Science and +1 Culture. |
| I: dynamic loss | At 8 classes remove one: Science falls from +2 to +1 at the supported event/turn boundary. |
| J: remove Workshop | All associated Science markers clear. Rebuilding never creates cumulative yields. |
| K: dummy safety | No dummy class reward, runaway events, purchase/build/sale visibility or accumulated marker counts. |
| L: Ink Mortar | Active Catapult +1 Move/+1 Sight, identical strength/range/cost/resources/setup/siege/upgrade. Test trained and purchased units, then upgrade: extra Sight disappears. |
| M: Marathon | Read active ConstructPercent; at 300% each class gives 36 Culture/60 Gold. |
| N: human-only | Selection works; AI selection excludes RFD. Forced AI ownership receives no Lua bonuses. |
| O: permanent ledger | Save/quit/restart after multiple discoveries; exact exhausted classes and balances survive. |
| P: old save | On a progressed RFD save without an RFD1 block, current classes seed without payouts; future new classes reward. |
| Q: transfer/recapture/raze | No foreign Science leaks. Recapture recalculates from current city; razing/reused IDs cannot reset national history. |
| R: UI/art | Check setup civ/leader/UU/UB icons, player colors, flag, map, Dawn text/chamber, static diplomacy, Civilopedia index and tooltips at several resolutions. |
| S: multi-civ | Start other collection civilizations and inspect logs; their registrations, art and gameplay remain available. |

Also test an advanced-era start, save/reload on the starting turn, and a silent external building removal followed by the next owner-turn boundary. Native rendering, engine serialization and siege-promotion behavior cannot be certified by the mock runtime.
