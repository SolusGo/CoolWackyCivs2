# Hardening file inventory

This patch extends the existing civilization; original art assets and other civilizations' gameplay sources remain unchanged. The original implementation inventory is [ChangedFiles.md](ChangedFiles.md).

The complete patch paths are generated below from the final working tree before commit. Runtime changes are in Jin Core/State/Military, new Runtime/Autonomy/Transactions modules and the existing panel. Generator/Balance changes affect only Reindeer fields and the native plunder-event option. SQL/Config are regenerated outputs. Test/profiler/release-verifier files supply executable coverage; manifests register the three imported modules. Guides, reports and changelogs document the patch.

Complete patch inventory: **37 files**. No other civilization directory is changed.

- `CHANGELOG.md`
- `Cool Wacky Civs 2 (v 16).modinfo`
- `CoolWackyCivs2.civ5proj`
- `JinDynasty/Balance.json`
- `JinDynasty/CHANGELOG.md`
- `JinDynasty/Lua/JIN_Autonomy.lua`
- `JinDynasty/Lua/JIN_Config.lua`
- `JinDynasty/Lua/JIN_Core.lua`
- `JinDynasty/Lua/JIN_Military.lua`
- `JinDynasty/Lua/JIN_Runtime.lua`
- `JinDynasty/Lua/JIN_State.lua`
- `JinDynasty/Lua/JIN_Transactions.lua`
- `JinDynasty/README.md`
- `JinDynasty/SQL/00_JIN_Core.sql`
- `JinDynasty/SQL/10_JIN_Text.sql`
- `JinDynasty/UI/JIN_Dynasty.lua`
- `JinDynasty/docs/AoE4Fidelity.md`
- `JinDynasty/docs/Benchmark.json`
- `JinDynasty/docs/Hardening.md`
- `JinDynasty/docs/HardeningBenchmark.json`
- `JinDynasty/docs/HardeningChangedFiles.md`
- `JinDynasty/docs/Implementation.md`
- `JinDynasty/docs/SourceAudit.json`
- `JinDynasty/docs/Testing.md`
- `JinDynasty/docs/Validation.json`
- `JinDynasty/docs/Verification.md`
- `README.md`
- `docs/civilizations/JinDynasty.md`
- `tools/benchmark_jin.py`
- `tools/benchmark_jin_hardening.py`
- `tools/generate_jin.py`
- `tools/tests/jin_autonomy.lua`
- `tools/tests/jin_hardening.lua`
- `tools/tests/jin_mock.lua`
- `tools/tests/jin_transactions.lua`
- `tools/validate_jin.py`
- `tools/verify_release.py`
