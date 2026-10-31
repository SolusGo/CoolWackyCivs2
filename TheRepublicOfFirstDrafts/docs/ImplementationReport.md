# Final implementation report

## A. Implemented systems

The Republic of First Drafts is registered in the existing v19 collection with Editor-in-Chief Marginalia, First Edition, a fresh trait, human-only selection, full English localization, diplomacy, Civilopedia, names, player colors and original art. Nothing Is Ever Final pays once per qualifying national Building Class at the next verified owner-turn evaluation, using individually rounded active construction-speed rewards. The Ink Mortar and Revision Workshop inherit active baseline data. Workshop Science reflects current local classes and uses exact hidden-building targets.

## B. Created and modified files

[Files.md](Files.md) lists every source, registration, documentation, test and art file. The collection UUID and existing modinfo/project are retained. No separate solution, external gameplay dependency or shared gameplay controller is added.

## C. Permanent saved class ledger

Sorted class TYPE names, last evaluation turn and an optional before/after payout journal live in a namespaced player ScriptData block. The verified CP DLL serializes that field. Updates preserve unrelated data. The permanent class set survives loss, razing, recapture, sale, reconstruction and a complete Lua VM restart. Old progressed saves without a ledger seed current classes without retroactive awards; advanced starts at the actual StartTurn remain new games. Duplicate callbacks and context initialization do not pay again.

## D. Dynamic Workshop Science

Current per-city classes are counted using the shared active-definition eligibility lookup, including the UB's ordinary Workshop class. Three hidden +1 Science buildings encode the exact 0–3 target without accumulation. Construction/purchase, sale, city-dirty and capture events update it; owner-turn scans cover silent grants/removals. Capture handlers reacquire the current city from its plot. Foreign/AI owners receive no bonus, and the markers cannot survive native capture. Historical UA state never determines Science, including when UA state is corrupt.

## E. Active CP inheritance

Scalar SQL clones use runtime `SELECT *` and reset IDs. The generated companion SQL covers **176 unit/building tables**, including active promotions, AI registrations, upgrade paths, resource requirements and gameplay 2D scripts. Validation compares all inherited columns and companion records. An altered fixture changes Catapult cost/strength/range/sight/movement, Workshop cost/maintenance/specialists/technology, adds unknown scalar columns, an extra promotion and multiple Culture yield rows: clones preserve the changed values while adding exactly the specified bonuses. No fixed vanilla balance values are reconstructed.

## F. Executed validation

On 2026-10-31:

- `tools/validate_rfd.py` passed actual-schema SQL, released-row preservation, inheritance, localization, syntax, XML, VFS, checksums, SQL order and all 40 mipmapped DDS textures.
- **26 shipped Lua 5.1 scenarios** passed: Standard, Marathon, Quick/Epic, altered runtime rounding, empire class deduplication, wonders/dummies/Palace exclusion, Gold/Faith/free/captured acquisition, transient removal, thresholds/cap, building loss, transfer/recapture/stale city objects, human guards, repeated initialization, full VM restart, progressed saves, advanced starts, payout and dummy faults, corruption and ambiguous recovery.
- **14 checksum-pinned official CP v151 source contracts** passed, including saved ScriptData, owner-turn hook, yield APIs, upgrade-lost Sight and the actual `GameSpeeds.ConstructPercent` field.
- `tools/validate_mod.py` completed with exit code 0 across the entire collection: prior civilization suites, all Lua syntax, package registrations, 779 atlas sizes, 19 leader portraits, 1,269 framed cells, original-collection collision checks and the new RFD suite.
- `tools/audit_cp.py --fetch` downloaded the official pinned sources and passed **184 existing collection source assertions**. The source inventory now includes `CvInfos.cpp` for game-speed verification.
- The compiled civ, leader, unit, building, map and Dawn artwork was visually inspected. All released textures were preserved byte-for-byte by the builder.
- A separate MD5 comparison confirmed that **all 1,079 previously registered game files** match the prior commit byte-for-byte.

The fixture is an installed BNW debug snapshot with the installed **CP v151 schema overlaid in memory**. These results do not claim native DLL gameplay acceptance. [Focused results](Validation.json) and [collection execution record](CollectionValidation.json) preserve the evidence.

## G. In-game tests requiring verification

All A–S native checks remain listed in [Testing.md](Testing.md): actual human selection, unit training/purchase/setup/upgrades, owner-turn economy settlement, dynamic city yields, real engine save/quit/load, capture/recapture/raze, and rendering/Civilopedia/tooltips at game resolutions. No native Civ V session was launched for this implementation.

## H. Technical limitations

Static leader diplomacy and the normal Catapult 3D model are intentional working fallbacks; custom portraits/icons and Dawn/map are supplied. There is no custom voice or animated leader. Silent external building removals correct at the next owner-turn scan, without changing yields already settled by the engine. An install on the exact initial turn cannot be distinguished from new-game initialization. An interrupted payout followed by unrelated changes to an unacknowledged balance cannot be inferred safely, so its saved journal fails closed for investigation. Future schema/companion additions require regeneration/audit. No ordinary mechanic, registration or automated-test failure is unresolved.

## I. Existing civilizations

Unrelated civilization gameplay, art, SQL and save contracts were not intentionally modified. SQL is appended after the released inventory, and automated comparisons preserve their database rows and IDs. Collection-wide validation passed. Regenerated timing-only reports for older civilizations were restored to avoid unrelated source changes.
