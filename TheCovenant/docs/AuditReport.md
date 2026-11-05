# Covenant v24 reliability audit — 2026-11-06

Scope: implementation correctness, reliability and regression coverage, rechecked after the original-graphics revision. Scripture wording, all numerical balance, the collection UUID and civilization identifiers are unchanged. Native Civ V was not launched or tested during this audit.

## Confirmed defects corrected

- Reference normalization collapsed chapter and verse digits: Revelation 31:7-18 could match 3:17-18. Structured parsing now compares book, chapter, first verse and range end separately and rejects malformed/ambiguous input.
- The periodic popup check dequeued every hidden owned context. Legitimately waiting/preempted contexts now retain queue ownership with no visibility-based churn. Own close/reopen transitions and semaphore ownership are idempotent; temporary reopening preserves the draft.
- UTF-8 byte counting rejected a legitimate single-character quote as a multi-character edit. Insertion checks now count characters. This remains a bulk-change heuristic, not reliable clipboard-origin detection.
- A carried session scheduled and cleared the old session turn. It now settles on its completion turn, so a second ordinary review cannot appear in that turn. Skipped examination boundaries remain due, and completion checks that obligation before releasing the gate.
- The v24 addition omitted Covenant from the generated strategy registry. Full-pack validation rejected its roster. Existing Covenant strategy content is now registered, with a generated Civilopedia presentation overlay and shared index entries.
- Rechecking the current release reproduced a permanently latched Submit guard after an injected UI refresh exception. Submit and Study now release their shared guard on exceptions. The periodic check retries persistence and refreshes the current prompt before accepting another action, preserving queue ownership without replaying an answer or reward. Four new regression scenarios cover rendering, transient save failure, failure after Faith mutation and a newly due exam after recovery.

The Covenant used colon calls for SaveData, whereas installed Firaxis scenarios use returned dot-call functions. The call mismatch and failure under the strict shipped-contract fixture are confirmed. The closed native binding's acceptance/rejection of the old colon form was not tested; this is an API compatibility correction, not a claim of observed native failure.

## Preventive hardening

- Completion/progression and the reward-turn cap are journalled in the same numeric payload before applying yields; the legacy reward marker remains available. Repeated submit/turn/load callbacks, all-five examinations and modeled reloads cannot duplicate tested rewards.
- Submission requires a fresh edit after advancing; unchanged Enter/lost-focus callbacks do not submit or corrupt the next prompt. A deliberate edit followed by deleting everything still fails recall. Ineligible/other-player callbacks cannot change progression or grant yields.
- Numeric save decoding checks bounded input, flags, queue uniqueness/count, phases, section bounds and progression consistency. Unknown/corrupt/future-dated data falls back to mandatory assisted study without executing saved text.
- Tests check both player-key separation and era-correct rewards to the active Covenant player. Other civilizations, AI, multiplayer and hotseat are excluded.
- An initial render exception or failed queue request cannot permanently latch the periodic check or leave a falsely owned queue. Known failed requests roll back and retry; legitimate hidden queues remain untouched. Stale show/missing hide notifications cannot leak an owned timer in the tested paths.
- Action recovery persists the already-advanced state, clears stale input and repairs the view. It does not retry yield grants: a failure after Faith mutation may leave a partial reward, but cannot duplicate the journalled grant through tested recovery paths. A permanent storage/control error remains an underlying failure requiring repair.

## Files and reasons

| Files | Purpose |
| --- | --- |
| `TheCovenant/Lua/CovenantMemory.lua` | Structured reference matching, Unicode edits/whitespace, carried scheduling, overdue exams, schema 2 reward journal and safe v1 decoding |
| `TheCovenant/UI/CovenantGate.lua` | Queue/timer ownership, preserved focus/draft, exception-safe Submit/Study guards and recovery, native-compatible SaveData calls, migration and reward ordering |
| `tools/tests/covenant_engine.lua`, `covenant_mock.lua`, `covenant_lifecycle.lua` | Extend existing engine/strict API fixtures and add lifecycle/persistence regression scenarios |
| `tools/validate_covenant.py` | Execute regressions, inspect installed Firaxis contracts and validate exact SQL/art/localization properties |
| `tools/verify_release.py` | Extract/compare Covenant runtime, SQL and audit documents from the actual 7z release |
| `tools/validate_saba.py`, `tools/validate_conical_union.py` | Repair optional already-activated-cache inspection using the existing Twelfth/Circus read-only clone pattern; keep clean-baseline validation strict and change no gameplay |
| `tools/covenant_strategy.py`, `docs/StrategyGuides.json` | Register Covenant in the existing generation workflow without regenerating other civilizations |
| `TheCovenant/SQL/90_PlayerGuide.sql`, `docs/strategy/TheCovenant.md`, `docs/StrategyGuide.md`, `docs/Matchups.md` | Covenant-only Civilopedia metadata/text and corresponding strategy/index pages |
| `Cool Wacky Civs 2 (v 24).modinfo`, `CoolWackyCivs2.civ5proj` | Regenerated hashes, VFS inventory and new guide SQL activation |
| Covenant README, implementation/testing/audit docs, `SourceAudit.json`, Covenant/root changelogs | Save migration, primary-source evidence, test scope, remaining native limitations |
| `TheCovenant/Art/*`, `SQL/03_COVENANT_Art.sql`, gate XML, art sources/compiler/preview and graphics docs | Original graphics from the user's preceding request, retained and revalidated; 43 legacy full-mip DDS textures, 37 atlas declarations and a static leader scene |

`CovenantVerses.lua` remains byte-identical to the supplied v24 Scripture. SQL checks confirm exact requested yields, inherited costs/tech/maintenance/prerequisite classes, city Culture, civilization/leader/trait links, human-only flags and starting units/technologies. The original stock-art baseline is overridden by the separately requested original graphics: the art overlay changes only presentation, while native unit/building models remain inherited. Core SQL changed only an art comment; text SQL received presentation/lore changes during that graphics work. Gate XML uses the themed panel and an installed title font. Guide SQL changes only Covenant presentation.

This recheck adds action recovery in `CovenantGate.lua` and four scenarios in `tools/tests/covenant_lifecycle.lua`, plus documentation/changelog updates and refreshed manifest hashes. Comparing all game files with the verified graphics-release ZIP before rebuilding found exactly one changed game file: `TheCovenant/UI/CovenantGate.lua`. The memory engine, Scripture, SQL, XML and all art were unchanged by this recheck.

The local checkout originally contained v23 plus user edits. It was fast-forwarded to the supplied repository's v24 commit (`982d3c9`) with Git autostash; local edits reapplied cleanly. Existing Boundless City/tool changes were not authored as part of this audit. Legacy validation evidence writes are restored from a byte snapshot so they do not modify other civilizations' documents.

## Save and compatibility assessment

BNW and Community Patch v151 remain the only game requirements. Source assertions use CP commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`; database validation uses a read-only installed BNW baseline with CP151 schema overlaid in memory. No Vox Populi component or new Python dependency is introduced.

The existing curriculum checksum/player keys are preserved. `OpenSaveData` is per saved campaign, so separate campaigns do not need a new global campaign key. Schema 1 pending references/sections, assisted status, failures, due dates, examination queues, streaks and legacy reward markers migrate in place to schema 2. Existing start-turn anchors are retained. Original schema-1-only code cannot read upgraded schema 2 payloads; back up before upgrading if a downgrade may be needed. Native save continuation remains unverified.

## Validation

Use the repository `.venv` Python (the host's bare `python` lacks the development dependencies). The suite deliberately labels UI mocks, source inspection and Civilopedia source replay separately from native game execution.

| Command (repository root) | Result |
| --- | --- |
| `.venv/Scripts/python.exe tools/validate_covenant.py` | PASS 15 Lua 5.1 engine groups, 22 additional UI/persistence groups, installed-script contracts, manifest, original graphics and actual BNW/CP SQL |
| `.venv/Scripts/python.exe tools/validate_strategy_guides.py` | PASS all 22 guides, 77 preserved lore chapters, installed Civilopedia source indexing/search replay, idempotence and unchanged gameplay |
| `.venv/Scripts/python.exe tools/audit_cp.py` | PASS 185 pinned CP v151 source assertions |
| `.venv/Scripts/python.exe tools/build_mod.py --manifest-only --preserve-art` | PASS 1,300 game-file manifest/project inventory; 890 atlas-size declarations, 22 custom leaders and 1,377 framed cells |
| `.venv/Scripts/python.exe -u tools/validate_mod.py` | PASS complete collection suite, all 22 civilizations, SQL, Lua, UI contracts, source replay, manifest/project/VFS and decoded textures; exit 0 |

Initial full-pack invocations exposed the missing Covenant guide registration and legacy Saba/Conical optional-cache checks that incorrectly passed an already-activated collection cache to the clean-baseline adapter. Both paths were corrected rather than excluded from validation. The live cache remains read-only; no clean-baseline safeguard was weakened. The final complete rerun, including the action-recovery correction and all 22 UI/persistence groups, exited successfully (0). Its 911-line output is retained in `dist/CovenantFullValidation.log`.

After the final complete validation, all 1,443 files in the other 21 civilization folders match the preservation snapshot, including the user's existing local changes. Generated evidence-only JSON writes were restored byte-for-byte and the full inventory and SHA-256 hashes were checked before packaging. The supplied Scripture and every numerical balance value are preserved.

Release delivery uses `.venv/Scripts/python.exe tools/build_mod.py --preserve-art`, followed by `.venv/Scripts/python.exe tools/verify_release.py`. The latter checks exact ZIP bytes/inventory, genuine LZMA/7z CRC/inventory, and extracted manifest/runtime/SQL/art/document bytes, including Covenant. The current inventory is 1,559 packaged files, including 1,300 game files. Final validation/release results and archive hashes are recorded in ignored `dist/CovenantReleaseVerification.json`.

## Native limits and verdict

Clipboard origin cannot be reliably inferred from EditBox text changes. One-character paste and shared-text selection replacements may pass; native batching/IME may look like bulk insertion. Ordinary typing, Backspace/Delete, navigation/selections, Enter/Escape, shortcuts, paste, outside clicks and focus restoration require the native checklist in [Testing.md](Testing.md).

There is no verified per-context queue membership query in the inspected shipped API patterns. The module recovers known local transitions and missed notifications; it does not guess from a hidden flag. Arbitrary foreign mods forcibly dequeuing/hiding this context remain outside the guaranteed recovery contract. Native priority arbitration, semaphore behavior and mandatory turn blocking must be checked in Civ V. Journalling before yields prevents tested duplicate grants but cannot prove native save/resource atomicity after an engine/script failure.

The complete offline collection suite passes. Ready for in-game acceptance testing once release verification confirms the delivered archives; native acceptance is not claimed.
