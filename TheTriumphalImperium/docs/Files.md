# Files

* `SQL/00_TRI_Core.sql`: civilization, leader, trait, replacements, names, colors and CP hook opt-ins.
* `SQL/01_TRI_Inheritance.sql`: schema-derived active Swordsman/Barracks companions and starting/leader rows.
* `SQL/02_TRI_Effects.sql`: permanent/temporary/tier promotions, military-production dummies, Culture and diplomacy responses.
* `SQL/03_TRI_Art.sql`: 37 atlas registrations; 40 textures including three scenes.
* `SQL/10_TRI_Text.sql`: English localization, lore, dawn, diplomacy, UI and rules.
* `SQL/90_PlayerGuide.sql`: repository-style practical Civilopedia guide; only Imperium metadata is changed.
* `Lua/TRI_State.lua`: namespaced native-save persistence and classification.
* `Lua/TRI_Bonuses.lua`: exact-tier reconstruction, Hall eligibility, movement and notifications.
* `Lua/TRI_Gameplay.lua`: authoritative events, combat/capture receipts, turn cycles and listener lifecycle.
* `UI/TRI_Panel.xml` and `.lua`: compact six-laurel in-game add-in; no vanilla overrides.
* `Art/`: 40 DDS textures and static leader scene XML, all imported under unique `TRI_` names.
* `README.md`, `docs/Implementation.md`, `docs/Testing.md`, `docs/Validation.json`: rules, contracts and evidence.
* `../art-source/TheTriumphalImperium/`: all six generated PNG masters, review contact sheet and exact generation prompts.
* `../tools/generate_triumphal.py`, `prepare_triumphal_art.py`, `triumphal_strategy.py`: isolated regeneration tools.
* `../tools/validate_triumphal.py`, `tests/triumphal_mock.lua`, `tests/triumphal_cases.lua`: source/schema and shipped-Lua contract checks.
* `../tools/validate_triumphal_integration.py`: complete collection regression with released civilization report writes suppressed; results in `docs/Regression.md`.
* `../tools/build_triumphal.py`: independent installable ZIP/7z Civ5Mod packaging from the same source module.

Collection integration changes the build registry, generated v23 manifest/project,
README/changelog, strategy registry/indexes and release/test inventory. Earlier
civilization source and art files, including The Laureate Commonwealth, are not modified.
