# Validation record — 2026-10-22

All results below were run against this implementation in the local repository. **Civ V was not launched.** Python uses the repository `.venv`, with `lupa.lua51`, Pillow and py7zr; CP source is the pinned official DLL v151 revision recorded in SourceAudit.json.

| Command/check | Actual result |
| --- | --- |
| `tools/generate_circus.py` | Generated five SQL files from installed BNW/CP schema |
| `tools/prepare_circus_art.py` | Compiled 40 mipmapped DDS textures and static scene |
| `tools/validate_circus.py` | PASS actual-schema SQL after all released civilizations, active-cache activation, complete inheritance, preserved previous rows, additive Culture, exact yields, safe dummies, all English references and art |
| Circus Lua 5.1 suites | PASS 30 runs: timing, lifecycle and persistence at five speeds and two raw start turns |
| Circus source audit | PASS 29 pinned CP v151 contracts; no engine execution |
| `tools/validate_mod.py` | PASS all collection SQL/Lua regressions, original-collection coexistence, package/project/VFS/MD5/XML/DDS, gold frames and seven leader portraits |
| `tools/audit_cp.py` | PASS 182 shared pinned CP v151 source assertions |
| `tools/benchmark.py` | Completed existing Boundless simulation benchmark; generated timing changes were not retained in unrelated civilization documentation |
| Prior release comparison | PASS every original v8 game-file MD5 unchanged; entire old SQL load order remains the prefix of v9 SQL |
| `git diff --check` | PASS no whitespace errors |
| `tools/verify_release.py` | PASS complete ZIP/7z inventories, ZIP bytes, CRCs and extracted 7z manifest/runtime/SQL |

The Circus source-shaped fixture samples SQL-backed illustrative yields before PlayerDoTurn and restores actual fixture snapshots with distinct city markers and positions. Tests cover requested cases 1–42 as mapped in [Testing.md](Testing.md), including post-mutation setter exceptions, a 100-city/1,000-event dirty storm, and captured foreign Workers converted by native class rules. Native engine saves, economic rounding/modifiers, Worker automoves, UI rendering, diplomacy localization and older-save continuation still need the manual acceptance checklist. No native pass is implied by static checks, CP-derived arithmetic or Lua mocks.

The package builder produces ZIP and genuine 7z/LZMA `.civ5mod` archives under ignored `dist/`, with version 9 and unchanged collection UUID. Archive generation checks the 7z CRC; the accompanying release check compares both archives' complete inventories and unpacked modinfo to the source manifest. Build and installation commands are in [the guide](../README.md).
