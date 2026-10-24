# Source inventory

| Path | Purpose |
| --- | --- |
| `SQL/00_CONICAL_Core.sql` | Native notification options, human-only civ/leader/trait, runtime scalar Worker/Walls clones, overrides, 28 cities and ten spy names. |
| `SQL/01_CONICAL_Inheritance.sql` | Active starting setup and all applicable Worker/Walls companion rows from the installed schema. |
| `SQL/02_CONICAL_Effects.sql` | Permanent Office Culture, two invisible conditional yield buildings and diplomacy responses. |
| `SQL/03_CONICAL_Art.sql` | Atlas families, all sizes/slots and unit flag. |
| `SQL/10_CONICAL_Text.sql` | English identity, uniques/help/strategy, Civilopedia, leader biography, city/spy names, diplomacy and supplied Dawn narrative. |
| `Lua/ConicalUnion.lua` | Sole simulation owner, shared native-connection reconciliation, context-owned callbacks, per-city fault isolation, targeted retry and lifecycle/ownership cleanup. |
| `Lua/ConicalUnion.xml` | Invisible matching InGameUIAddin entry context. |
| `Art/CONICAL_*.dds`, `Art/CONICAL_LeaderScene.xml` | 40 mipmapped game textures and static 2D leader-scene reference. |
| `README.md`, `CHANGELOG.md`, `docs/Implementation.md`, `docs/Testing.md`, `docs/AuditReport.md` | Player guide, release changes, audited findings, mechanics/API/timing documentation and native acceptance checklist. |
| `docs/SourceAudit.json`, `docs/Validation.json` | Pinned official CP contracts/digests and actual automated results. |

Paths below are relative to the collection root:

| Added or modified source | Purpose |
| --- | --- |
| `tools/generate_conical.py` | Reproducible schema-derived SQL and localization generation. |
| `tools/prepare_conical_art.py` | Original-image and drawn alpha/map DDS compilation. |
| `tools/validate_conical_union.py` | Real-schema, source-contract, shipped-Lua and art/integration validation. |
| `tools/tests/conical_mock.lua` | Synthetic native boundary with native-shaped events and explicit transfer semantics. |
| `tools/tests/conical_connections.lua` | Combined yield matrix, connection transitions, Offices and Capitals. |
| `tools/tests/conical_lifecycle.lua` | Capture/transfer, new cities, reload reconstruction, missing/dead/destroyed objects and duplicate guard. |
| `tools/tests/conical_resilience.lua` | API faults, reentrancy, retries, missing hooks and large-empire steady-state workload. |
| `tools/tests/conical_context.lua` | Shared-data quick-load/context recreation, retained callbacks, shutdown, same-context includes and foreign load sanitation. |
| `tools/tests/conical_faults.lua` | Persistent/partial per-city failures, bounded diagnostics, targeted foreign retries, cross-city dirty events and vanished pending IDs. |
| `tools/tests/conical_timing.lua` | Explicit old cache, native refresh, first settlement, Lua repair and following settlement phases. |
| `tools/tests/conical_ownership.lua` | Conquest/gift/liberation-shaped transfers, capital lifecycle, real Office requirement and missing/replaced native objects. |
| `tools/build_mod.py` | Append inventory and single controller entry, version 13, updated roster metadata and preserved SQL ordering. |
| `tools/prepare_art.py` | Include the new compiler in standard preparation. |
| `tools/standardize_icons.py` | Enable the existing complete-mip paths for the new atlas prefix only. |
| `tools/validate_mod.py` | Include focused validation in the collection check. |
| `tools/verify_release.py` | Check extracted Conical runtime, SQL, art and validation bytes in the 7z package. |
| `Cool Wacky Civs 2 (v 13).modinfo`, `CoolWackyCivs2.civ5proj` | Regenerated file lists, hashes, entry points, SQL order and VFS flags; replaces the version 12 manifest while retaining UUID. |
| `README.md`, `CHANGELOG.md`, `docs/IconConsistency.md` | Roster/release/install/art documentation. |
| `docs/civilizations/TheConicalUnion.md` | Short civilization reference page. |
| `art-source/TheConicalUnion/` | Four original imagegen sources, preview and exact prompts/provenance. |
| `art-source/IconAtlasMasters/CONICAL_*.png` | Three retained color atlas masters for deterministic gold framing. |

Generated ZIP/7z archives and diagnostic logs live in ignored `dist/`. No unrelated civilization art, gameplay or validation timing output is committed.
