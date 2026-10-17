# Implementation and delivery record

## Files

All game files are under `TheChildrenOfTheKingdom/`, with isolated `CK_` names:

| File/group | Purpose |
| --- | --- |
| `SQL/00_CK_Core.sql` | Human-selectable/AI-disabled identity, leader, palette, UA, native Pikeman/Temple clones, overrides, city/spy names and CP hook options |
| `SQL/01_CK_Inheritance.sql` | Every active `Unit_` and `Building_` companion table, plus standard starting units/buildings/techs; no leader AI tables |
| `SQL/02_CK_Effects.sql` | Three promotions, six hidden dummy buildings, two branchless CP dummy policies and all native yield modifiers |
| `SQL/03_CK_Art.sql` | Civilization/alpha/object/portrait/flag atlases at the collection's supported sizes |
| `SQL/10_CK_Text.sql` | Complete natural English identity, Civilopedia, strategy, all petition words/effects and UI/notification/tooltips |
| `Lua/CK_Core.lua` | One namespaced controller, human guards, actual-speed duration, native promotion setter and module loading |
| `Lua/CK_State.lua` | Strict numeric versioned save serialization and validation, preserving foreign ScriptData |
| `Lua/CK_Blessings.lua` | Exact city/policy/unit reconciliation, safe Production credit, authoritative command validation and every petition reward |
| `Lua/CK_Events.lua` | Load/turn/capital/capture/building/unit/conversion/tile/war events and reserve queue handling |
| `UI/CK_Prayer.xml`, `UI/CK_Prayer.lua` | Dedicated panel, event-driven refresh, activation, modal visibility and input |
| `Art/*.dds`, `Art/CKLeaderScene.xml` | 34 original game-supported DDS assets and static diplomacy fallback |
| `README.md`, `CHANGELOG.md`, `docs/*` | Gameplay guide, dated changes, implementation, validation, original request and native checklist |

Outside the module: `tools/generate_kingdom.py` reproducibly emits SQL from the installed schema; `tools/prepare_kingdom_art.py` compiles original assets; `tools/validate_kingdom.py` and `tools/tests/kingdom_*.lua` validate shipped code. `tools/audit_cp.py` includes pinned policy source, `tools/validate_mod.py` runs Kingdom regressions, and `tools/build_mod.py` includes the fifth civilization/addin and version 8. The ModBuddy project, version 8 modinfo, collection README/changelog and `docs/civilizations/TheChildrenOfTheKingdom.md` are updated. The obsolete version 7 manifest is replaced. Generated PNG artwork/provenance and three retained icon masters are in `art-source/`.

## Prayer implementation

The XML addin is the sole simulation owner. Included Lua modules are VFS-imported; the entry XML and SQL are not. Prayer opens from the upper-right launcher on eligible human world-map turns. The current petition is the next action, and the cycle indicator highlights it. All effects, durations, readiness, Grace and saved reserve are visible without the Civilopedia. Refresh handlers read the state; they do not scan cities/units. Gameplay uses no update callbacks or timers. A **single coalesced, one-shot UI callback** settles screen transitions, following the collection's existing modal fix: it calls `ClearUpdate` before rendering and performs no gameplay work. It never stays attached or polls idle frames. Real modal visibility recovers missed popup events and handles notifications arriving before a popup actually closes. The reserve dirty-event handler checks one capital only when a nonzero reserve exists. Unit movement touches only that unit; border changes inspect only units on that tile. Full unit/city reconciliation is limited to initialization, prayer, a player's turn, transfers and human-control changes. War, score/open-border, minor-access and diplomacy-close events revisit only cached relevant units abroad, validating native IDs and creation turns. The cache is rebuilt from saved units on load and cannot grant persistent progress.

| Petition | Authoritative implementation |
| --- | --- |
| Address | Capital-only exact-count dummy: `Building_YieldChanges` +2 Faith/+1 Food; saved expiry |
| Opening Glory | `Player:ChangeFaith(10 * (GetCurrentEra()+1))` once |
| Seek | One `CultureRateModifier=15` dummy per owned city; CP merges it into native Culture yield modifiers, affecting actual production |
| Ask | Native `ChangeFood(8*Era)` plus the same amount in a saved Production reserve; a guarded integer `ChangeProduction` delta fills at most the remaining finite queue cost, measured using `GetProductionTimes100` to preserve fractions; no native overflow edits, `PopOrder`, `InitUnit`, or direct building completion |
| Repent | One native CP dummy policy with `ExtraHappiness=2`, granted free and removed at expiry; CP accounts for the flat policy happiness once in the capital, not once per city |
| Protection | One free CP dummy policy with `CityStrengthMod=20`; each military unit receives a distinct `DefenseMod=15` promotion only while on a native `IsFriendlyTerritory` plot; saved expiry |
| Closing Glory | Once: native Golden Age meter +20*Era; Grace +1 up to 7, otherwise +25*Era extra meter; Faith +10 per real completed owned House; stage resets to 1 |

All temporary statuses last `max(1, floor(5*TrainPercent/100 + 0.5))` turns, matching cooldown. No turn counter is decremented during activation. Native CP processes city economic ticks **before** `PlayerDoTurn`; the saved player clock advances at that hook, so the blessing survives its final economic tick and expires before the next human action. Other players' border/capture events cannot prematurely remove that last tick merely because the global turn has advanced. Opening a panel never changes this clock.

## Grace and persistence

The player ScriptData block `|CKPRAYER1:stage,grace,ready,address,seek,repent,protection,clock,bread|` stores nine bounded integers. Unrelated text is preserved. The parser never evaluates code. Unsupported/corrupt versions preserve the original payload, disable custom effects and report the issue in Lua.log and the panel.

The native saved game owns this ScriptData; there is no machine-global save cache. Stage, absolute ready turn, four expiry turns, resolved player clock and pending Production survive reload. The command verifies active player, alive/human/civilization, active turn, capital, mode, cooldown and the UI's expected stage/deadline. A reentrancy guard and advancing/persisting stage/deadline before synchronous one-shot rewards reject double clicks and stale requests. Reload reconciliation assigns effects without invoking any reward function.

Grace uses three binary dummy buildings worth 1/2/4 Faith and Culture. Counts are assigned exactly as 0 or 1, never incremented. Every owned city is reconciled so only the present capital carries these and Address. Capture strips dummies in the acquired city then reconciles both empires; capital changes move exact counts. Completed House bonuses are maintained separately, with no foreign-player benefits. Eliminated players have no eligible commands or yields.

Stand Firm's `FriendlyHealChange=5` uses native healing eligibility and has `LostWithUpgrade=0`. A separate conditional defense promotion has `DefenseMod=15`; native melee and ranged defense paths apply it, attack paths do not. Friendly checks are refreshed at creation, training, movement, conversion, ownership changes, load and turns. Protection uses another conditional defense promotion, so the two effects remain independent. Ranged-only military units are included. Gifts/captures remove persistent Kingdom promotions from foreign/nonhuman owners; an ordinary same-owner upgrade preserves Stand Firm. No direct HP grants occur.

## CP contracts and disclosed limits

- Target is Windows BNW + Community Patch v151, audited against official commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`. Other full DLL overhauls are not certified.
- CP's ordinary percentage city-strength policy affects both the city's defensive strength and its ranged strike strength. This is the native city-strength interpretation of the requested +20% City Defense. The **unit** bonuses remain strictly defensive. Normal additive modifier arithmetic and integer rounding apply.
- ASK awards all Production immediately as queue progress plus reserve, but safely delays spending credit that cannot fit a finite item. It follows the current capital and survives capital loss/reload; it is not loot for a captor. Native economic growth and production completion occur at their normal ticks. The reserve is explicitly shown in help/UI rather than silently discarding yield.
- The two temporary policies are CP `IsDummy=1`, branchless, unadoptable normally and granted with `bFree=true`. The pinned native source excludes dummy policies from all `GetNumPoliciesOwned` results and difficulty adoption rewards, and free policies from cost growth. No real policy or free-policy slot is consumed.
- Stand Firm/Protection obey native combat and healing rules. CP's embarked defense uses a separate path, so both conditional promotions also set the verified `EmbarkDefenseModifier=15`; this preserves the requested friendly defensive bonus while embarked without buffing attacks or double-applying ordinary defense. Native friendly territory includes own/team land, permitted major open borders and earned minor access. Naval/air edge cases, allied territory and combat-preview consistency require native verification. The standard Pikeman model and a static leader scene are deliberate compatible art choices.
- `AIPlayable=0` prevents normal AI assignment; external scripts/save editing can force a civ assignment, but Lua still withholds its custom systems. No AI strategies, AI automation or AI balancing are included. AI/non-Kingdom owners can retain only ordinary inherited Temple/Pikeman behavior.
- New types and a version 8 manifest retain the collection UUID and existing civ namespaces/save formats. Native old-save migration/continuation is unverified; back up saves. Start a new game to choose The Faithful. Multiplayer, hotseat and Mac remain disabled.
- Other mods that bypass the native ownership/conversion/turn events can require the next reconciliation. No global base UI or DLL file is changed, and no external sound/music dependencies are introduced.

## Validation

See [Testing.md](Testing.md) for completed automated work and the full outstanding native checklist. Automated tests use the real SQL, DDS, XML and shipped Lua with engine doubles and source-contract assertions. Native gameplay, graphics rendering, native save serialization round trips and long campaigns have **not** been performed.
