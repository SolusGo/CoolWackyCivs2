# Urgal validation and acceptance

Automated checks execute the shipped SQL in an in-memory clone of the installed BNW database with CP v151 schema changes. Live game/cache files are read-only. Shipped Lua runs through Lupa's Lua 5.1 interpreter with modeled players, units, events and UI controls. These are automated simulations, **not in-game tests**.

`tools/validate_urgal.py` checks replacement scalar and companion inheritance, exact costs/strength/resources, AI flags/personality, all three promotion fields, local production eligibility including custom melee and ranged hybrids, English text, unrelated-row preservation, XML/VFS/control references, all 48 decoded DDS textures and pinned native source contracts. Four shipped-Lua suites cover:

| Suite | Coverage |
| --- | --- |
| `urgal_potions.lua` | One initial bottle, Industrial/Information hoards, immediate/duplicate/skipped Era events, stockpile, eligibility, new recruits, named speed durations, expiration and two-turn Aftertaste |
| `urgal_lifecycle.lua` | Reload, context replacement, upgrades and ineligible replacements, new Rushers, embarking, gifting, ID reuse, corrupt saves, independent Urgal players and advanced starts |
| `urgal_ai.lua` | War alone, enemy count, visibility/invisibility, blocked attacks, exhausted units, concentration, invasion and cooldown |
| `urgal_ui.lua` | Stockpile and disabled states, repeated clicks, nested popups, city screens, diplomacy, turn changes, active player and detached one-shot refresh |

`tools/validate_mod.py` additionally parses every shipped Lua file as Lua 5.1, validates all collection civs, manifests, checksums, entry points, gold-framed atlases and namespace coexistence. `tools/verify_release.py` checks ZIP inventory and exact bytes, genuine 7z/LZMA CRC, and extracted sample bytes including Urgal.

## Native checks still pending

1. Start a new Standard Ancient game with BNW, Community Patch v151 and v15 enabled. Select Urgal; inspect leader, civilization, unit/building icons, map, Dawn text and Civilopedia. Repeat UI inspection at 1024×768 and 1920×1080. Confirm other civilizations never see the potion inventory.
2. Confirm one initial potion. Advance through every Era, including an unusual skipped transition, save/reload and compare counts. Without drinking, confirm five in Industrial and eight in Information.
3. Create warriors, spears, swords, mounted melee, guns, armor, archers, siege, reconnaissance, ships, aircraft and civilians. Drink. Inspect native attack/defense previews and resolved damage: only snapshot melee units gain +50% against units; city attacks and city bombardment remain unchanged. Check the native additive modifier display.
4. Train/purchase/spawn units after drinking; ensure they lack the current effect. Upgrade a participating Rusher twice; ensure the deadline remains fixed and Pot Chaser survives. Gift a participant away and return it; ensure it remains excluded. Embark/disembark a participant within its deadline.
5. Kill enemy units with a Pot Chaser veteran during Strength II, including a barbarian. Verify exactly 15 HP recovered up to max, native healing restrictions, no extra attacks or movement, and no recovery after expiry. Confirm ordinary potion recipients do not heal.
6. On each named speed, count 3/5/7/12 turns. On Standard, activate at T, check expiration at T+5 and blocked drinking until T+7. Save/reload during active and Aftertaste windows; durations must not restart. Inspect autosaves around those boundaries.
7. Confirm Brewing Stand cost/maintenance/15 XP on the supported baseline and native +10% production in its own city for melee units only. Destroy/sell it and confirm normal production. Verify no building can create a potion.
8. Set an AI Urgal against a neighbor. War alone should not drink. Bring three ready melee units into contact with two visible enemies or an invasion; confirm one bottle consumed and subsequent native attacks. Observe a full game for timing quality, cooldown and balance.
9. Test nested production/tech/diplomacy popups, city entry/exit, end turns and saves for obscured or stuck controls. Native continuation of pre-v15 saves remains unverified; new games are recommended for the new civ.

The machine-readable [Validation.json](Validation.json) records actual automated results separately from these outstanding checks. No claim of native combat, rendering, save or balance acceptance is made.
