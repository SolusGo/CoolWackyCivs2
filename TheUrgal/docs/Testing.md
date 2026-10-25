# Urgal validation and native acceptance

Tests execute shipped SQL in an in-memory clone of installed BNW/CP v151 schema and shipped Lua through Lupa Lua 5.1. Live game/cache files are read-only. The installed native SupportFunctions.lua text helper is executed with modeled font metrics. Combat/healing arithmetic models use actual SQL promotion values and recipients selected by shipped Lua, backed by pinned CP source checks. **No native Civ V gameplay or UI rendering is claimed.**

## Automated coverage

`tools/validate_urgal.py` checks human-only flags, replacement scalar/176-companion inheritance, preserved unrelated rows, 50 AttackMod/zero CityAttack cancellation, unchanged defense/city fields, 15-HP recovery, exact production/resource values, localization and custom melee/ranged-hybrid production eligibility. It decodes 49 DDS textures, verifies the purple icon's transparency, 32px dimensions, full legacy mip chain and VFS reference, and checks XML panel geometry at 1024x768, 1280x720 and 1920x1080.

| Suite | Coverage |
| --- | --- |
| urgal_potions.lua | Initial/Industrial/Information inventories, duplicate/skipped/regressive Era events, uncapped stockpiles, unit exclusions and mixed snapshots |
| urgal_lifecycle.lua | Reload/context retirement, upgrades and excluded replacements, new Rushers, embark/disembark, gifts, ID reuse, corrupt data, independent players and advanced starts |
| urgal_ai.lua | Human-only runtime, unsupported AI residue cleanup, no AI-module dependency and inert legacy entry |
| urgal_ui.lua, four speeds | Embarked-only disable/reason, immediate count, nested popups/city/diplomacy/turns, active/Aftertaste reloads, large-title truncation, stale callbacks, same-context includes and detached updates |
| urgal_speeds.lua | Every active/expiry/Aftertaste/reactivation boundary on four speeds and a custom speed, duplicate turns, repeated reloads, fallback/minimum and legacy deadlines |
| urgal_combat.lua | Actual applied promotions plus SQL-backed arithmetic for melee attacks against units/cities, unchanged defense/exclusions, conditional/capped healing, native CannotHeal and normal post-expiry combat |
| urgal_reliability.lua | Embarked-only rejection, mixed feedback, duplicate creation, isolated setter retries, notification failures, reentrant spending, independent players, large integer round trips and malformed/future tags |

The focused runner performs **10 suite runs** and source contracts recorded in Validation.json. Full `validate_mod.py` checks all collection civilizations, Lua 5.1 parsing, manifests/MD5s/VFS, atlas gold framing and namespace coexistence. `benchmark.py` measures the repository's existing synthetic Boundless workloads; it is not an Urgal/native FPS benchmark. `verify_release.py` checks exact ZIP bytes/inventory, genuine 7z/LZMA CRC and extracted bytes including the potion icon. Generation is also checked for byte-identical repeated output.

## Outstanding native checks

1. Start a new game with BNW, CP v151 and the updated v15 build. Confirm Urgal is human selectable and absent from AI selection. Confirm other civilization flags and McPvP behavior are unchanged.
2. Inspect the bottle, title, status and button at 1024x768, 1280x720 and 1920x1080. Check long stockpile tooltip, overlays, nested popups, diplomacy, city entry/exit, turn end and reload. Static checks cannot verify native font/render behavior.
3. Drink with eligible melee classes and inspect both preview and resolved melee attacks against units and enemy cities: +50% additive attack. Verify no extra defensive strength, city bombardment, ranged, siege, naval, air or civilian bonus; garrisoning a boosted unit must not raise city strength.
4. Test embarked-only rejection, mixed snapshot activation, disembarkation before/after expiry and newly trained/purchased/spawned/acquired units. Confirm no new unit joins the window.
5. Count active/Aftertaste turns and first reactivation: Quick 3/1/T+4, Standard 5/2/T+7, Epic 7/3/T+10, Marathon 12/6/T+18. Save/load and autosave around every boundary. Existing v15 committed deadlines must persist without refreshing; new activations use corrected values.
6. Kill units with/without Pot Chaser during/after Strength II, including barbarians. Verify exactly 15 HP capped at max, native healing restrictions and no extra movement/attacks. Upgrade a participant and gift/return another; check deadlines, permanent Pot Chaser and temporary cleanup.
7. Check initial/per-Era potions, hoards and two unusual human Urgal slots. Verify Rusher 14/2/80/no Iron and Brewing Stand 75/1/inherited XP/+10% melee Production, including local removal/sale and no potion generation.
8. Play a full game to evaluate actual tactical behavior and balance. Native continuation of older collection saves remains unverified; back them up and prefer a new game for acceptance.

Civ V installation files are available for read-only source checks, but native gameplay has not been run for this audit. See [Audit.md](Audit.md) for severity classification and actual command results, and [Validation.json](Validation.json) for machine-readable focused results.
