# Mr. Garvey reliability audit — 2026-10-24

Target: **BNW + Community Patch v151**, collection **version 12**, human-only. Mechanics, balance, identity, all art/3D assets and v1 save formats are preserved. Native Civ V was **not executed**.

## Findings and fixes

| Finding | Resolution |
| --- | --- |
| Garvey's own SQL omitted `EVENTS_UNIT_PREKILL`; whole-collection tests could hide this because The 11 Cats already enabled it. | Enable the option explicitly in the generator and regenerated core SQL. Validate Garvey in isolation with every option reset to zero. A mutated copy omitting the option must fail validation. No additional gameplay features are enabled. |
| Every generic `SerialEventGameDataDirty` caused a full city scan and six dummy reconciliations per city; the open panel separately scanned cities for Offices. | Generic GameData/CityInfo events now refresh UI only. Use verified CP `SpecificCityInfoDirty(player, city, updateType)` for coalesced city-ID repairs, including scripted real/free building changes. Read Office presence through CP's maintained `CountNumBuildings` cache. No generic refresh touches a Lua city/unit iterator or building/promotion getter. |
| `CityRazed` is emitted before deletion, so synchronously counting the dying Office could preserve relief during the rest of native settlement. | Immediately compute relief excluding that city's Office, then verify remaining policies in a deferred, one-shot post-deletion pass. Missing/captured cities are looked up afresh; no native city object is retained. |
| A native setter that mutated then threw could leave only part of the empire reconciled. Transient save/ledger errors could disable a valid save or consume a paid marker without delivering its reward. | Reproduce with fault injection, then retry idempotent reads/writes/reconciliation once synchronously. A selection retries the same committed candidate. RNG, notifications and native Culture delivery are never retried. Persistent failures remain bounded and logged. |
| The patience indicator was text-only. | Add three native bullet pips: grey at Calm, one warning pip at Irritated, two red pips at Furious, three red pips during Detention. The internal reset counter remains zero. No asset regeneration, polling or new timer. |

## Concerns investigated and not confirmed as bugs

- **An absent hook was not proven by the disabled option.** Pinned v151 `CvUnit::kill` invokes the seven-argument `UnitPrekill` hook through a legacy fallback when the option is disabled; the existing collection also enables it through Cats. Explicit Garvey enablement and independent regression enforcement are still appropriate.
- **Turn timing remains correct.** CP settles city Production, Gold, Culture, research and Faith before `PlayerDoTurn`. The saved owner clock retains the final economic tick and expires effects before the next actions. Interturn reloads preserve that clock. First availability remains founding +12; pending choices wait; selection starts a fresh 12-turn cooldown. Bonuses and Detention remain eight and five turns, respectively, on all four speeds.
- **Combat and replacements remain unchanged.** Native promotion modifiers add, with no damage multiplication. Hall Monitor retains complete active Pikeman inheritance and native friendly-territory strength; Hall training is lost on upgrade and temporary empire bonuses are reapplied where appropriate. Office retains complete Public School inheritance, +2 Culture/+2 Production, local +10% Detention Science and exactly one empire relief policy. Foreign owners receive no temporary Classroom effects.
- **Culture formula and deduplication remain unchanged.** Each eligible effect pays `max(1, floor(max(base melee, base ranged) * 25 / 100 + 0.5))`. Separate Hall/Detention markers permit intended stacking. UnitPrekill handles attributed lethal military damage; ordinary combat snapshots supply the Hall battle tile. Captures, conversions, civilians, disbands and friendly fire do not pay.

## Changed files

- Gameplay: `Lua/GARVEY_Core.lua`, `Lua/GARVEY_Events.lua`, `SQL/00_GARVEY_Core.sql`.
- Presentation: `UI/GARVEY_RollCall.lua`, `UI/GARVEY_RollCall.xml`. Existing `GARVEY_Interface.lua` and screen gates are preserved.
- Tooling: `tools/generate_garvey.py`, `tools/validate_garvey.py`, existing `garvey_mock.lua`, `garvey_combat.lua`, `garvey_ui.lua`; new `garvey_audit.lua` and `garvey_faults.lua` fixtures.
- Documentation: this report, Testing/Implementation, civilization and collection changelogs, generated Validation.json. The version 12 modinfo receives updated checksums; no addin/file identities change.

## Automated evidence

`generate_garvey.py`, `validate_garvey.py`, `build_mod.py --manifest-only`, the full `validate_mod.py` collection runner, `build_mod.py` and `verify_release.py` are the acceptance workflow. See [Validation.json](Validation.json) for current scenario results and exact CP source/UI/schema contracts.

The six Garvey suites run in Lua 5.1 for Quick/Standard/Epic/Marathon at starting turns 0 and 150: **48 runs**. Coverage includes exact durations and pending choices, legacy state/rewinds, corruption and rejected saves, deterministic corrections/Timothy, three-correction trigger/reset, melee/ranged/defensive/city bombardment/nuclear/collateral rewards, delayed/final death callbacks across load, duplicate result/completion pairs, unit lifecycle/gifts, captured and scripted real/free Offices, scripted dummy repair, pre-removal razing, transient faults, all four graphical patience states and modal/Strategic View gates.

The large-empire fixture has **201 cities and 2,003 units**. One thousand separate generic GameData/CityInfo refresh frames while the panel is open perform **zero Lua city scans, unit scans, building reads or promotion reads**. A thousand duplicate specific-city events coalesce into one city lookup. This is an API-workload assertion, not a native FPS measurement. Every callback detaches before work; no idle frame handler remains.

SQL checks use an in-memory clone of the actual BNW cache plus installed CP schema, check complete inheritance and changed-base fixtures, preserve peer rows/IDs and default balance, and enforce human-only play. All 41 DDS textures are decoded and validated; existing source art remains untouched. Collection/package checks exercise peer civilizations and compare ZIP/7z inventories and game-file bytes.

## Compatibility and remaining native work

No save migration is needed: `GARVEY:v1:state:<player>`, its version plus eight integer fields, and all `GARVEY:v1:kill:...` lifetime/effect markers remain byte-compatible. Legacy ledger data is read directly; progression is never reset. The collection UUID/version, released database IDs and other civilizations' code/assets are unchanged.

CP v151 argument order, unit lifecycle, building dirty/capture/sale/raze ordering, cached counts, native yield/promotion/Happiness behavior and Lua 5.1 syntax are checked against local pinned official source and installed CP UI/schema. UI automation/native rendering and the game's actual serializer have not been exercised. Complete the [native acceptance checklist](Testing.md): real yield settlements and combat/purchases/upgrades/gifts, delayed-death saves, last-Office destruction, every modal screen, old-save continuation and Huge/Marathon FPS.

Remaining risks are native integration not represented by the fixture, third-party mods that bypass normal building setters/events, and persistent engine/storage failures. Bounded retries recover tested transient failures; they cannot guarantee delivery or durable persistence if the underlying native APIs continue failing. Turn/load/lifecycle reconciliation remains as a repair boundary. No benchmark result here measures native FPS.
