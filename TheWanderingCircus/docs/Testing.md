# Validation and native acceptance

## Automated evidence

`python tools/validate_circus.py` runs actual-schema in-memory SQL after all six prior civilizations, snapshots every existing row, checks all inherited scalar/companion properties and the active game cache, verifies human-only flags, Worker/Market overrides, starting class records, localization, exact yields, safe dummies and art paths. It decodes all 40 DDS textures and checks atlas capacities and the unit flag. It also tests modified CP baselines including existing Market Culture and new scalar columns.

The **shipped** runtime executes under `lupa.lua51` in three isolated suites at Quick, Standard, Epic, Marathon and a custom speed, with raw start turns 0 and 150: **30 suite runs**. SQL-backed illustrative yields are sampled BEFORE PlayerDoTurn. Native engine economics and serialization are not executed. The 29 pinned-source contracts in [SourceAudit.json](SourceAudit.json) independently check the native order/API. The collection validator additionally parses every Lua file as Lua 5.1 and checks manifest/project SQL order, MD5, VFS, XML, DDS and every existing civilization regression suite.

| Requested test numbers | Coverage |
| --- | --- |
| 1–6 | SQL registration, overrides, all scalar/companion inheritance, +1 Movement, unchanged WorkRate, additive Culture |
| 7–18 | `circus_timing.lua`: pre-economic activation, exact T..T+2, expiration T+3, T+11 blocked/T+12 eligible, duplicates, travel, departure, stationary repetition, Crew capture, passing through, ordinary/foreign Workers, pending death/relocation |
| 19–21 | `circus_lifecycle.lua`: no Office, construction, post-sale and scripted removal |
| 22–23 | Timing/persistence suites: six simultaneous festivals, distinct city start/cooldown boundaries |
| 24–28 | Lifecycle suite: capture/gift/liberation/scripted AcquireCity callback, return, razing/destruction model, elimination |
| 29 | `circus_persistence.lua`: inactive/first/second/third turns, cooldown, immediately before eligibility, distinct cities, stationed Crew, same-turn different saves, rewinds, interturn/pre-staging autosaves |
| 30–32 | All suites: repeat turn events, dirty storms, idempotent counts, missing players/cities, no-Circus game, bounded post-mutation exception recovery |
| 33–37 | Full previous-row snapshot, SQLite integrity, collection package validator, art dimensions/indices/paths and all English references |
| 38–42 | Every runtime suite at all five speeds; fixed 3 and 12, including advanced raw start |

## Manual in-game test plan — NOT RUN

Enable game logging in `config.ini` before testing. Use Windows BNW with CP **v151** and only the intended collection/compatibility mods. Install v9 per [README](../README.md), start a fresh game, and retain a clean baseline save. Inspect `Database.log`, `Lua.log` and `xml.log` after setup and each lifecycle test. Record both raw `Game.GetGameTurn()` and the visible turn label; use raw T in this checklist.

1. Confirm all seven civilizations remain selectable. Choose Aurelio; verify leader portrait/static diplomacy, supplied Dawn text, crimson/gold colors, civ icon, unit flag, original city map and Grand Pavilion as capital. Confirm Circus does not enter random AI assignments.
2. Grant a Worker through `UNITCLASS_WORKER`, and train another. Both should resolve to Carnival Crew. Compare against CP's normal Worker: exactly +1 Movement, identical WorkRate, build actions, repairs, roads, improvements, restrictions, civilian roles and any upgrade progression. Capture a foreign Worker, including a native-converted Crew: it must not initiate a festival.
3. Compare Ticket Office against the current CP Market: same prerequisite, cost, maintenance, base commercial benefits and specialists, with exactly +1 additional Culture. It has no unconditional additional Production.
4. Establish six test cities; keep one without an Office. Record ordinary base Culture/Gold/Production and relevant modifiers. End a Crew turn on a city-center plot at raw T-1. Check actual stored Culture and Gold gains at the next economic pass T as well as displayed city yields. The festival adds +3/+2 and the Office adds +1 permanent Culture/+2 conditional Production, subject to native modifiers. Do not infer payout solely from a tooltip.
5. Repeat through T+1, T+2, T+3: exactly three economic passes receive the festival. T+3 must have zero festival bonus and zero conditional Production. Keep the Crew stationed: T+11 remains inactive, T+12 must restart immediately, then expire at T+15. Check actual construction progress, not just Production display.
6. Have a Crew leave after activation; its show continues. Move through a city and leave before ending the turn; no festival. Test multiple eligible Crews with stacking permitted by your test setup: still exactly one show. Move one Crew between two cities and verify independent cooldowns. Run six festivals together: +18 base UA Culture/+12 base Gold; six Offices add +6 permanent Culture/+12 conditional Production. Another civilization receives no Circus effects.
7. During a festival, construct/buy an Office, sell it, and use a normal script setter to remove it. Production appears/disappears with Office presence; Culture/Gold and original timing persist. Also finish an Office during native city economic processing, checking subsequent displayed/current rates and next harvest.
8. End a turn with a pending Crew, then destroy/capture or relocate it during another player's turn. There must be no first festival payout or new cooldown if no qualifying Crew remains at T. Test delayed death, multiple Crews, attrition at turn activation and queued/automated Worker missions. Capture a Crew after an already active show: the show continues.
9. Capture, gift, liberate and script-transfer an active/cooling-down city through native AcquireCity. Inspect all six dummy counts: no state or conditional bonus transfers, even to another Circus player. Return the city: no inherited festival/cooldown; only a future qualifying ended turn can start one. Raze/destroy another city, then eliminate the player; no Lua errors from deleted city objects.
10. Save/reload separately with no festival, on its first/second/third active turn, during cooldown, and at T+11 just before eligibility. Compare absolute markers and actual next harvests. Repeat with several cities on different schedules and a Crew continuously stationed. Reloading itself must not activate/reset a show.
11. Save during AI turns immediately after preparation, then reload. **Separately load native end-turn autosaves**, which precede PlayerDoneTurn, and turn-start autosaves. Verify deactivation replay, pending marker, next harvest and T+3/T+12 boundaries. Repeat after rewinding to an older save and loading a distinct game at the same raw turn.
12. Repeat core boundary tests at Quick, Standard, Epic, Marathon and a custom modded speed, and an advanced-era start. There must always be three active owner-turns and twelve turns between starts. Test ordinary resistance/anarchy/razing suppression with city modifiers.
13. Play Boundless City and Republic of Pigeons smoke tests: Workforce/remote Food and Pigeon trade/roost bonuses. Also smoke-test Red, McPvP, Kingdom and Twelfth Hour. Check all three logs for SQL/UI/Lua issues.

Optional: set `DEBUG=true` near the top of the Circus runtime and regenerate the manifest to log preparation/activation coordinates. Restore false for release. No per-frame debug output is installed. A successful automated run does not certify any of the manual steps above. Older version 8 native save continuation remains untested.
