# Validation and native test checklist

## Automated reproduction

Use Python 3.11+ with `requirements-dev.txt`, DirectXTex `texconv`, the installed BNW backup debug database and CP v151 schema. The database adapter reads those files **read-only** and executes all changes in memory.

```powershell
python tools/generate_red.py
python tools/prepare_red_art.py
python tools/build_mod.py --manifest-only
python tools/build_mod.py --manifest-only
python tools/validate_red.py --fetch
python tools/validate_mod.py
python tools/audit_cp.py
python tools/benchmark.py
python tools/build_mod.py
```

The second initial manifest pass lets the shared icon finisher discover a newly added civilization; subsequent builds need only one pass. The retained `art-source/IconAtlasMasters/RED_*.png` masters make later builds deterministic. Regenerating original icons requires refreshing those masters with `standardize_icons.py --refresh-sources` for the relevant atlas, as described in the shared icon notes.

`validate_red.py` checks the actual installed schema and all six SQL actions, General inheritance/overrides, Heroic Epic prerequisites, Hospital/project costs, native one-completion restriction, English references and icon bounds. It audits 120 native method names and exact critical CP contracts, parses Lua as 5.1 and executes shipped gameplay against an engine double. All seven Red suites are **simulations**, not game sessions. Art checks decode every Red DDS, require mipmaps, and resolve scene/atlas paths. `validate_mod.py` also runs existing Boundless/Pigeon/summary regression suites and collection package/coexistence checks.

The additional suites are `red_no_red.lua` (global vetoes without Red), `red_stability.lua` (project prerequisites, 1/5/20-city queues, asynchronous/canceled/reloaded airlift, legal spawn terrain, Snorlax item/anchor/ZOC, aura/Range and unit creation/reused IDs), and `red_recovery.lua` (all-six snapshot commit, third-turn reload, partial return, preserved veteran data, filtered upgrade promotions, injected failures during withdrawal/return/Ace restoration/detachment). Injected failures deliberately print deferred-transaction diagnostics; assertions require suppression to return to zero and recovery to avoid duplicate units.

Exact source assertions cover the five-value city queue tuple, actual boolean pop/append parameters, global project-veto argument order and TESTALL semantics, unit-specific airlift hook ABIs/early bypass, destination checks, movement-before-arrival ordering, native nonnegative movement and absence of a fallback veto. These establish pinned API contracts; they do not prove live engine scheduling, UI behavior or native serialization.

## Required native checks

1. Restart Civ V fully, enable BNW + Community Patch v151 + Cool Wacky Civs 2 version 7 in Mods. Start Red at Standard speed; check leader selection, Pallet Town, Dawn art/text, map, all unique Civilopedia entries, custom flags and peace/war fallback music. Inspect `Database.log`/`Lua.log` for Red errors.
2. Fight melee/ranged/barbarian/city battles. Verify +10 kill, +5 stronger survival, +15 capture, +8 camp and +2 damaged capital Training. Save/reload at each rank; rename and upgrade a veteran. Confirm only one rank promotion and only the current rank's effects. Check ranged/air Training independently of team eligibility.
3. Verify capacity at Ancient/Classical/Medieval, a skipped era, a non-Plateau national wonder and Indigo Plateau. Kill a member and fill the vacancy manually. Test Manual/Automatic mode, one-time 5 HP nearby victory healing and native +25% combat XP/capture protection.
4. Defeat the strongest native fielded type, including ties and a weaker nonqualifying type. Verify production-based Culture/Science and claimed-type reload protection. Conquer, lose and reconquer an original capital; verify no duplicate General points/Ribbons/Hall reward. Construct the Plateau after earlier captures. Kill/release/withdraw members and confirm dynamic yields fall immediately.
5. Generate an Ace naturally using General points. Test aura/Citadel while detached, adjacency attachment, saved identity/name, 90% team thresholds, Legendary Sight, upgrades, reload, host death recovery and blocked detachment. Verify Bond heals after movement; item healing/status removal/full Movement, post-attack restriction and saved cooldown.
6. Check Center Food/growth retention/city healing and the owned three-tile unit-healing boundary. Verify no stacked overlapping-Center bonus. Test starting Training for produced/purchased units, no upgrade replay, capped passive gain and paid/free upgrade refunds. Airlift an unmoved land unit to an owned Center and Airport; test occupied/hostile-adjacent targets, wrong domains, moved units and a second source-city departure. Watch mission completion and allowance persistence after reload.
7. At Modern with four partners/one Legendary, check project visibility/cost and one-time completion. Save before completion, on each absence turn and immediately before return. Confirm -10% Gold/Production in every city including newly acquired cities. Confirm no withdrawn units can be selected or replaced and no extra partner appears after reload. Confirm the exact speed-scaled due turn.
8. Test six-member and four-member journeys. Check returned XP/level/promotions/name transformation, saved serials/lineage/Ribbons/Ace/cooldowns, preserved damage, legal advanced upgrades through obsolete intermediates, +10 maximum HP and additive +35% Training/Summit strength. Crowd the capital, lose it, block all friendly plots, allow only one partial return and reload, then free space. Eliminate Red during absence: no revival.
9. Test **each identity**: Pikachu stronger bonus/full-health damage/lethal legal escape/cooldown; Charizard range nonstack/city/fortified attack/terrain/splash; Blastoise ranged reduction/retaliation/fortification bridge; Venusaur heal/debuff/turn expiry/Forest-Jungle; Snorlax maximum Movement/fortified heal/ZOC against ignore-ZOC units/native heavy charge; Lapras naval ocean/land embarkation/range/embarked aura/naval-target damage. Verify no secondary-damage reward recursion. Check CP's displayed damage preview versus post-combat bonuses.
10. Open/close the roster during movement, city, diplomacy, policies, notifications, end-turn and reload. Verify all six icons/rows, HP, XP, Training bars, eligibility and countdown. Native fonts and scrolling need visual verification at multiple resolutions.
11. Run AI-only games on Quick, Standard, Epic and Marathon. Observe survival of veterans, balanced recruiting, Ace approach/attachment, item use, Plateau priority, safe project scheduling and effective late-game fighting. Simulated command scheduling does not establish strategic AI competence.
12. Enable the original Cool Wacky Civs alongside the collection. Check separate identifiers and live coexistence. Back up a version-6 collection save before upgrading. Multiplayer/hotseat remain disabled and untested.

Record actual game version, mod list, speed, save/replay and logs when completing these checks. No native checkbox is implied complete by an automated result.

## Outstanding corrective-pass checks — all NOT RUN

- Start a game without Red and inspect every production menu; repeat with Red Ancient/Modern/eligible/completed and after reload. Confirm the project stays exclusive, scales with native CreatePercent and cannot complete twice.
- Observe AI Red with 1/5/20 cities: active project, inactive queued project, interrupted production, captured producer, reload and completion. Confirm one project and preserved invested Production.
- Use Center-to-Center and Center-to-Airport, including a mission that executes after the Lua callback. Check pending UI/reservations, occupied/hostile-adjacent/invalid targets, insufficient or refilled-but-used movement, post-attack, cancellation, timeout and save/reload before/after arrival. Verify no permanent Center native action. Existing Airports retain native behavior.
- Native melee heavy charge, morale retreat, normal withdrawal, escorted units and AI push/swap against Snorlax: check occupied/impassable anchors, attacker advance, no remote correction, no stacked units, no recursion, maximum one tile after an item, +40% fortified Defence, 15 fortified HP and ZOC against immune opponents.
- Native save round trips on absence turn three, all-six and all-four return, partial return, blocked land/naval terrain, capital loss, elimination and obsolete upgrade intermediates. Confirm every serial, Training value, Ribbon, Ace, XP/level, eligible promotion, identity and cooldown; inspect logs for recovery diagnostics.
- Duplicate turn/visibility notifications around Venusaur, Range acquired midturn, upgraded/captured/recycled IDs and all roster screen transitions. Verify no render mutations or persistent frame polling after bounded work ends.

Results and limits are recorded in [StabilityAudit.md](StabilityAudit.md) and [Validation.json](Validation.json). No native result has been inferred from simulation success.
