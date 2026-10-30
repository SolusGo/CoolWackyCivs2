# Testing and native acceptance

Automated results are **static checks and Lua 5.1 simulations**, not a launched Civilization V test. The machine's installed schema/cache is opened read-only; test SQL runs in memory. No existing game database or installed mod is edited.

## Reproduce

From the repository root, with `requirements-dev.txt` installed:

```powershell
python tools/generate_t1zofgk.py
python tools/prepare_t1zofgk_art.py
python tools/build_mod.py --manifest-only --preserve-art
python tools/validate_t1zofgk.py
python tools/audit_cp.py
python tools/validate_mod.py
python tools/build_mod.py --preserve-art
python tools/verify_release.py
```

Use the repository `.venv/Scripts/python.exe` where available. Artwork regeneration reads the committed paintings and official mark; it does not call a paid image service. The built-in imagegen prompts and provenance are retained with the sources.

## Automated coverage

`tools/validate_t1zofgk.py` owns the dedicated validation. `tools/validate_mod.py` calls it as part of collection regression. `tools/tests/t1zofgk_mock.lua` models the pinned native event order: UnitCreated before identity finalization, promotion copying before UnitConverted, source availability during conversion, then delayed and final UnitPrekill. `t1zofgk_assertions.lua` executes the shipped controller, with its actual SQL promotion values and localization.

| Requested cases | Automated evidence |
| --- | --- |
| 1-7: selection, AI, Faker, replacements, localization, textures | Actual SQL flags/links, complete inheritance, text keys, VFS/MD5, all DDS decoded |
| 8-12: initial roster, sixth unit, starting replacement, purchases, delayed replacement | Ordered births, starting-unit fixture, duplicate callbacks, four-speed cooldowns and production-only real-HQ checks |
| 13-18: genuine upgrades, level-ups, reloads, roles, long chains, new units | Native-order conversion model, duplicate delivery, new IDs, hard/context reloads, 18 upgrades, same-type rejection and ordinary late-game units |
| 19-20: Zeus/Oner | Exact SQL fields and Forest/Jungle rows; source audit of native promotion mechanics |
| 21-23: Faker/Gumayusi/Keria | Hostility/domain/movement/creation/peace/death tests, native wounded-source contract, recipient healing flag/rate model and native canHeal source gates |
| 24-29: formation | 2/3/4/5 roles, radius boundary, normal troop exclusion, corrupted roles, embarked coordinates, tier exclusivity, moves/deaths/conversions |
| 30-34: Headquarters | Full base/companion inheritance with altered fixtures, native per-unit Production coverage including modded/mixed classes and defensive-only units, no Lua grants, local ownership/real-building eligibility |
| 35-40: persistence and isolation | Same-turn reloads, repeat notices, simultaneous vacancies, no free spawns, gift/recapture exclusion, reused IDs, no-T1 fixture and unchanged existing database rows |

The four speeds run the same lifecycle cases, with expected delays 7/10/15/30. Exact assertion counts, CP source hashes, longest upgrade path, DDS inventory and scope are recorded in [Validation.json](Validation.json). The focused run contains more than 700 runtime assertions across four speeds and 52 source/API checks; the collection source audit adds 184 checks. The current report is authoritative.

`--preserve-art` keeps earlier civilization textures byte-for-byte unchanged. The full collection validator checks all Lua syntax, every XML/texture/manifest and existing civ regressions. `verify_release.py` compares complete ZIP bytes and 7z inventories/CRC, then extracts an authoritative sample including T1 runtime/SQL/art.

## Native checks still required

None of the following is claimed to have run in the actual game:

1. With only BNW, CP v151 and this collection, start a new game at each speed. Confirm T1 is selectable by the human, absent from AI random selection, Faker's leader setup/Dawn art, T1 HQ capital and the starting Recruit as Zeus.
2. Produce/purchase four more Recruits. Inspect exact Z-O-F-G-K order, clear promotion names and help, and an ordinary sixth Recruit. Open/close the roster panel, Civilopedia, diplomacy, city view and end turns; confirm the launcher recovers and scrolls at the smallest supported resolution.
3. Inspect active Warrior/Barracks requirements, strength/cost/moves, inherited promotions and Barracks XP. Confirm +1 Headquarters Culture and +10% city-local Production on every qualifying land class. Compare ranged/civilian/naval production, a city without Headquarters, switched queues and overflow.
4. Upgrade each original member through the normal tech tree. Confirm one +4% increment per changed type, retained XP/roles, current development tooltip, no false loss notice and exactly one cumulative tier. Level-ups and purchased promotions must not add development. Save/reload before and after each upgrade; compare a newly constructed late-game unit.
5. Compare Zeus attacking a city versus a unit and defending. Test Oner Forest/Jungle sight/path costs against other terrain, rivers, roads and embarkation. Compare Gumayusi attacks on full-health/wounded military units, defense and cities, including units with modified maximum HP.
6. Place enemy land/naval/air military, civilians, friendly/neutral units and barbarians around Faker. Inspect attack/defense modifiers, movement in/out, peace/war, upgrade, transport, cities and death. A temporary debuff must disappear with its condition and never stack.
7. Place wounded friendly units next to Keria. Compare native legal resting healing to moving, attacking, embarked, blockaded, enemy/neutral territory, healing-forbidden terrain and maximum HP. Check ordinary Medic combination, another support source, same-team allies, Keria himself and civilian exclusion. Save/reload on the same turn; no Lua healing should replay.
8. Test 1/2/3/4/5 distinct roster roles within two hexes, then split the formation. Include normal troops, embarked/carried units, cities and an upgrading member. Confirm exactly 0/10/15% and no stacked/ghost tier.
9. Kill, delete, disband and gift members, including several in one turn. Save/reload during the cooldown. Confirm 7/10/15/30-turn eligibility, ready notices, no free replacements and Z-O-F-G-K priority. Try early units, purchases, captures, gifts, ranged/civilian/naval/defensive-only units and a city with a free/dummy rather than real Headquarters. Each successor should inherit only the role.
10. Return/recapture an originally local Recruit, then create another unit with the old native ID. Confirm no duplicated role/history. Test direct native capture-site quarantine and a genuine city training event at that tile. Inspect Database.log and Lua.log for errors.
11. Load an existing non-T1 save and start a different civilization. Confirm existing gameplay, panels, IDs and artwork remain correct. Multiplayer/hotseat/Mac are outside the collection's supported scope.

## Known engine boundary

The only intentional conservative assignment edge is a non-city free Recruit born at exactly a direct capture site on the same turn: CP exposes no correlated destination-ID callback, so it is barred from the initial roster unless a CityTrained event proves a local birth. Native free births elsewhere settle at an owner boundary. See [Implementation](Implementation.md) for the reason and saved contract. Native healing and combat calculations remain engine-owned; the simulations do not reproduce the complete engine.
