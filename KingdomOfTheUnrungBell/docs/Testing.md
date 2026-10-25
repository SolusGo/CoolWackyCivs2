# Validation and native acceptance matrix

Automated tests execute the shipped controller under Lua 5.1 mocks, not Civ V. SQL runs in a writable in-memory copy of the backup BNW database plus the installed CP v151 schema. Source checks use pinned official CP v151 files; DDS files are decoded. **No native in-game test has been performed for this addition.** [Validation.json](Validation.json) records actual automated status; [SourceAudit.json](SourceAudit.json) records source contracts and verified limits.

## Reproduction

From the repository, use the existing `.venv/Scripts/python.exe` or install `requirements-dev.txt` into Python 3.11+:

```powershell
python tools/generate_unrung.py
python tools/prepare_unrung_art.py
python tools/build_mod.py --manifest-only
python tools/validate_unrung.py
python tools/validate_mod.py
python tools/build_mod.py
python tools/verify_release.py
```

The source audit expects official files in ignored `tools/reference`; use `python tools/validate_unrung.py --fetch` to download its exact pinned source inventory when missing. The shared player-binding source can also be populated by the repository's `tools/audit_cp.py --fetch`. The validator never edits the installed game database. The current cache is not a CP-activated live session; the validator explicitly records this.

## Static and automated coverage

| Area | Performed check |
| --- | --- |
| Database | All SQL executes against installed schema; integrity check; every existing released row/ID preserved; only named notification options enabled. |
| Inheritance | All active scalar properties except displayed identity/art retained; all 176 unit/building companion tables compared, including upgrade classes, resources, prereqs, promotions, sounds and baseline yields. Changed-baseline regression uses Combat 33, Moves 4, Cost 321, future scalar columns, extra promotion and Temple Culture/Science. |
| Human only | `Playable=1`, `AIPlayable=0`; correct Pikeman/Temple overrides; no AI flavor strategy added. |
| Yield definitions | Six one-copy dummies, +1 per tier, no costs/upkeep/prereqs/capture/defense; permanent Belfry Culture additive over baseline; exact promotion strength/sight/upgrade flags and zero generic combat. |
| Localization | Every custom SQL text reference resolves, including diplomacy wildcard categories; full unique city-name list. |
| Code/assets | Lua 5.1 parse, XML parse, DDS decode and atlas dimensions, VFS/entry point and collection manifest/project checks. |
| Engine contracts | 18 checks of pinned CP v151 version, war-write/notification ordering, lifecycle event ABIs and native combat modifier behavior. Source evidence is not native execution. |

## Gameplay test matrix

“Mock pass” means an actual Lua 5.1 assertion ran. Every row still needs native acceptance where applicable. “Source/SQL only” or “manual only” never means in-game passed.

| Scenario | Expected result | Automated evidence |
| --- | --- | --- |
| 0–4 peaceful owner-turns | No Quietude Culture/Science. | Mock pass |
| 5 peaceful owner-turns | Stack I, +1 Culture everywhere, +1 Science only in Belfry cities. | Mock pass |
| 10 peaceful owner-turns | Stack II, +2 Culture/+2 conditional Science. | Mock pass |
| 15 / 25 peaceful owner-turns | Stack III and remain capped; progress retained. | Mock pass |
| Duplicate begin/end callbacks | No extra peace progress or duration advancement. | Mock pass |
| Barbarian war/conflict | Counter continues; no consumption. | Mock pass for relationship event; native combat manual |
| War at 0 / 1 / 2 / 3 stacks | Zero effect / Toll I / II / III, peace counter zero. | Mock pass |
| Own declaration and incoming declaration | Immediate consumption and yield removal in both directions. | Mock pass |
| City-state war / alliance cascade | Counts as war; same state transition rules. | Mock pass for team events; native alliance action manual |
| First half of two-sided flag update | Overlay handles notified pair despite stale opposite flag. | Mock pass + source |
| Two wars together / second during Toll | No second activation or refresh. | Mock pass |
| Additional war after expiry, still at war | No activation. | Mock pass |
| Complete peace before next owner callback | Remove Toll immediately without waiting. | Mock pass |
| War then peace during own turn | No peaceful turn awarded for that interrupted window. | Mock pass |
| War after short peace with zero stacks | No manufactured Toll. | Mock pass |
| War during own turn | Immediate bonus; activation remainder does not count. | Mock pass |
| War off turn | Immediate bonus; next five full owner windows count. | Mock pass |
| Five windows and intervening opponents | Bonus retained through fifth interturn; sixth owner-start removes it. | Mock pass |
| Many other players' callbacks | No timer/Quietude changes or foreign list scans. | Mock pass, 5,000 foreign turns |
| New city at stack III | Immediately +3 Culture; +3 Science only if Belfry exists. | Mock pass |
| City acquired/lost/liberated in peace | Reconcile current owner's effects; clear foreign markers. | Mock pass for reconstruction event |
| City acquired during Toll | No peaceful Culture/Science. | Mock pass |
| City razed | No stored city identity reused; remaining cities unaffected. | Mock pass |
| Belfry constructed or purchased | Conditional Science matches stacks immediately. | Mock pass for common completion/dirty events |
| Ordinary Temple only | No conditional Science. | Mock pass |
| Belfry sold/removed | Conditional Science disappears; ability Culture remains. | Mock pass |
| Native capture Temple-to-Belfry conversion | Correct replacement class and conditional check. | SQL/source only; native conversion manual |
| Trained/purchased/new military unit | Current single Toll tier applied. | Mock pass |
| Land ranged unit | Eligible, native modifier semantics below. | Mock pass for promotion, combat manual |
| Worker/settler/special noncombat/ship/aircraft | No Toll promotion. | Mock pass for zero combat/domain properties |
| Upgrade during Toll | Reconcile after native promotion copy; permanent Bellwarden bonus retained. | Mock pass for lifecycle; native retention source/SQL |
| Ownership transfer/gift | Strip old temporary Toll or apply new owner's active tier; preserve permanent bonus. | Mock pass for conversion |
| Unit moves across border | Native territory test changes applicability without promotion scan. | Source/SQL only; native previews manual |
| Bellwarden at Toll III | +30% additive friendly-land modifier, +1 Sight. | Source/SQL only; native damage/preview manual |
| Melee attack from friendly into enemy target | Unique modifier absent on enemy battle plot. | Source only; native preview manual |
| Melee attack into Kingdom-owned target | Modifier present on battle plot. | Source only; native preview manual |
| Defense on Kingdom-owned plot | Modifier present. | Source only; native preview manual |
| Open-border / same-team territory | Native modifier also applies: **known specification deviation**. | Source verified; native preview manual |
| Ranged fires from friendly at enemy target | Native modifier applies using shooter tile: **known specification deviation**. | Source verified; native preview manual |
| Ranged fires from foreign at owned target | Native friendly bonus absent: **known specification deviation**. | Source verified; native preview manual |
| Expiration while units outside friendly territory | Temporary promotions removed regardless of unit position. | Mock pass via position-independent reconciliation; movement manual |
| Save/reload at peace 4 / 5 / max | No bonus turn, duplicated yields or lost progress. | Mock pass at 4/5 and idempotent init; native save file manual |
| Save/reload during Toll / before expiry | Exact begun-window state retained. | Mock pass each window; native save file manual |
| Reload immediately after declaration / many wars | War guard preserved, no repeated consumption. | State-machine mock; native save file manual |
| Retained/recreated UI contexts | One live owner; old callbacks/shutdown cannot remove new owner. | Mock pass, ten reloads |
| Save API failure / unknown version | Disable derived effects, preserve unknown record, recover from authoritative record. | Mock pass |
| Native end-turn/turn-start autosaves | No duplicated/missed completed turn or duration window after engine resumes. | Manual only |
| Huge map, 22 majors and many minors | No continuous polling; measure native performance. | Synthetic foreign-turn cost only; native manual |

## Native acceptance procedure

1. Install BNW, standalone CP v151 and collection v14. Start a new modded single-player game as Sable, with another major and city-state nearby. Confirm Sable appears for the human and never in an AI slot. Check database/Lua logs for errors and confirm static leader/Dawn, all icon sizes and strategic view.
2. Settle two cities; build/purchase a Silent Belfry in one. Compare native Temple cost, tech, prerequisites, maintenance and Faith. End exactly 4, 5, 10, 15 and 25 peaceful owner-turns. Record city Culture/Science breakdown and actual policy/research progress, not just dummy counts. Save and reload at each boundary.
3. Make/receive war at each stack strength. Verify immediate city yield loss, retained Belfry +1 Culture, one promotion tier and unchanged Pikeman base stats. Add a second enemy on window 2. Record windows 1–5 and the sixth owner start, including opponent attacks during the fifth interturn. Make complete peace early in a second run and verify immediate removal.
4. Use both melee and ranged combat previews on owned, unowned, enemy, same-team and open-border plots, attacking in each direction. Verify additive 30% and Sight retention after Bellwarden upgrades. Record the documented native deviations; do not mark exact owned-target combat as passed.
5. Train, purchase, upgrade, gift, capture and liberate units/cities during peace and Toll. Check foreign dummy/promotions cleanup, ordinary Temples, Belfry removal and razing. Repeat with immediate saves and quick-loads.
6. Load native end-turn autosaves taken before DoneTurn as well as turn-start saves. Record whether the engine replays the pending boundary, then compare exact progress/timer/yields with an uninterrupted game. This cannot be established by mocks alone.

## Requirement checklist

Human-only flags, exact 5/3/1 values, major/minor/barbarian distinctions, immediate consumption model, nonrefreshing five-window timing, early peace removal, active Pikeman/Temple inheritance, permanent Bellwarden promotion, permanent/conditional Belfry yields, idempotent persistence reconciliation, original artwork and no per-frame/map polling are implemented with static/mock evidence above. No unrelated civilization implementation was changed. **Native save/event/rendering acceptance is outstanding. Exclusively Kingdom-owned battle-target bonuses are not satisfied by the native modifier and remain a verified technical limitation.**
