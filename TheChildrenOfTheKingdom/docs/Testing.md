# Validation and native test checklist

## Automated checks performed

- Executed every collection SQL file in load order in an in-memory clone of the installed BNW database plus CP v151 schema. Compared every Pikeman/Temple scalar and every active `Unit_`/`Building_` companion row; verified AI assignment disabled, human-only extras, native baseline preservation, exact modifiers and artwork/text references.
- Audited the pinned official v151 bindings, event signatures, native defense-only melee/ranged branches, native Culture modifier, flat Happiness accounting once, policy exclusion from counts/rewards/cost, finite production setters, and economic tick ordering.
- Parsed all module Lua as Lua 5.1; parsed XML and checked every UI control reference. Decoded all 34 DDS files, validated atlas dimensions/paths and collection icon padding/gold rims.
- `kingdom_cycle.lua`: all seven petitions, exact rewards/eras, five economic ticks, cities founded during Seek, post-creation Protection, civilians excluded, ranged-only military included, one empire Happiness bonus, seven Grace, further-cycle rewards, repeated reconciliation and Quick/Standard/Epic/Marathon/custom speed minimum.
- `kingdom_persistence.lua`: repeated controller reload with preserved native player data, cooldown and temporary effect deadlines, permanent Grace without rewards on reload, unrelated ScriptData preserved, empty/process/unit/project and nearly-complete queues, fractional progress preserved without overrun, unspent Production saved and applied once, final economic tick protected from early events, corrupt/future version fails closed.
- `kingdom_transfers.lua`: capital movement, captured old capital/dummy cleanup, recapture without extra Grace, friendly/neutral/foreign territory, border ownership, war/open-border/minor-access/diplomacy events, native promotion retention on upgrade, foreign gifts stripped, independent combined defense, AI/other human rejection, elimination and multiplayer/hotseat guards.
- `kingdom_ui.lua`: real panel Lua, localized dynamic values, all XML controls, activation/double click, active blessing durations, leader view, city view, nested/early/missed popups, Culture/Religion/Tech/Civilopedia/Game Menu contexts, interface mode, Escape, active-player switching, load/context closure, 1,000-event coalescing and 1,000 idle frames without callbacks or state changes.

The collection validator also reruns the existing Boundless City, Pigeon, Trainer Red and McPvP suites and verifies manifest checksums, SQL order, VFS names, project entries and coexistence with the original collection. A ZIP install folder and genuine 7z/LZMA `.civ5mod` are produced by `build_mod.py`; no ModBuddy install is needed.

Run:

```powershell
.\.venv\Scripts\python.exe tools/validate_kingdom.py
.\.venv\Scripts\python.exe tools/validate_mod.py
.\.venv\Scripts\python.exe tools/audit_cp.py
.\.venv\Scripts\python.exe tools/build_mod.py
```

These are **automated source/schema checks and simulations**, not live Civ V gameplay. There are **no claimed native runtime passes**. The native checklist below is entirely outstanding.

## Native initialization and packaging

- [ ] Enable only BNW, CP v151 and Wack2 v8 in Mods. Start The Faithful; confirm Sanctuary, leader portrait, alpha icon, loading image, map, both uniques, Civilopedia and palette.
- [ ] Confirm The Faithful cannot appear as a normal AI random choice. Force an AI Kingdom instance through a test setup and confirm no custom UA/Stand Firm/House extras or prayer automation.
- [ ] Confirm ordinary gameplay for all four existing Wack2 civs and coexistence with the original CoolWackyCivs collection. Check database.log and Lua.log for errors.
- [ ] Test a backed-up older collection save separately; existing UUID/schema identities are preserved but native continuation is not yet certified.

## Native prayer, yields and speed

- [ ] On Standard, Address on turn T is immediately reflected in capital yields; exactly five economic ticks gain +2 Faith/+1 Food. Turn T+4 remains on cooldown; T+5 allows Opening Glory. Repeat on Quick (3), Epic (8) and Marathon (15).
- [ ] Opening Glory awards exactly 10 × Era level, including Ancient=1 and an era change during cooldown.
- [ ] Seek changes actual city Culture by +15 percentage points, stacks additively with ordinary modifiers, applies to a newly founded/acquired city, and fully disappears after five Standard ticks.
- [ ] Ask grants 8 × Era Food and Production. Test unit/building/project, near-complete, empty, Wealth/Research and stockpile queues; inspect reserve, choose another item, reload, and ensure no duplicate yields, forced free items or native overflow exploits. Food and ordinary production finish at native ticks.
- [ ] Repent increases empire Happiness by exactly 2, irrespective of city count, and leaves social-policy costs/counts unchanged. Move the capital during the effect, save/reload, then check complete removal.
- [ ] Protection increases native City Strength by +20 percentage points in every owned city. Verify the documented native ranged-strike strength change. Test city founding/capture during the blessing.
- [ ] Protection units gain only +15% friendly-territory **defense** in both melee/ranged previews and real damage calculations. Check attacks from home into foreign land, foreign land into home, both sides at home, neutrality, allies/open borders, seas, embarkation, air combat and ownership changes. New purchases/training/upgrades receive the effect and expiration strips it.
- [ ] Closing Glory gives exactly 20 × Era Golden Age Points and 10 Faith per currently owned completed House; incomplete and lost Houses do not count. The next stage is Address with a new full cooldown.

## Native Grace, uniques and persistence

- [ ] Complete a cycle; Grace becomes exactly 1 with capital +1 Faith/+1 Culture. Reach seven; confirm exactly +7/+7. Complete another cycle; Grace remains 7, meter reward is (20+25) × Era.
- [ ] Save/reload immediately before/after every petition, midway through cooldown and temporary blessings, and at seven Grace. No repeated rewards, lost progress, duplicated dummies or duration resets.
- [ ] Move/lose the capital, capture/recapture cities, raze/lose the final city and eliminate the civilization. Check Grace stays with the player and bonuses/reserves transfer only to a legitimate current human Kingdom capital.
- [ ] Train/purchase Keeper; verify ordinary Pikeman stats, mounted combat role and native eligibility-based +5 HP friendly healing. Move/attack and confirm no unrestricted healing. Upgrade several eras; Stand Firm survives. Gift/capture it and verify foreign/AI custom effects are stripped.
- [ ] Keeper plus Protection gives two independent +15% friendly defense effects and no offensive bonus; remove Protection and retain Stand Firm.
- [ ] Build Houses; verify ordinary Temple effects/prerequisites/maintenance plus precisely +1 Faith/+1 Culture for human Kingdom owners. Test captured Houses under another civilization and forced AI.

## Native interface and long games

- [ ] Verify legibility at 1366×768 and larger resolutions, scroll behavior, artwork cropping, transparent atlas edges and unit flags.
- [ ] Open/close city screens, Culture/Religion/Technology/Civilopedia/Game Menu and all diplomacy/trade/popups. The launcher/panel hide safely and return on the world map without leaking clicks or intercepting another modal.
- [ ] Load an existing Kingdom save and open Prayer before/after ending a turn. Check current petition, every duration, reserve and Grace label; attempt double clicks.
- [ ] Play a long cultural/diplomatic campaign on every speed with the other Wack2 modules enabled. Check Lua.log, performance, new-unit/territory events and save round trips repeatedly. The one-shot UI transition callback must detach before rendering; there is no periodic/idle polling or frame-based gameplay work.
