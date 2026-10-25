# Lore expansion and native Civilopedia integration — 2026-10-26

The Boundless City's setting now explains its scale through one municipal charter and distributed administration. Residents live in wards across the territory; common citizenship, final law and major appropriations connect them to the Heart. The books cover government, courts, public records, privacy, work, food, water, transport, money, housing, learning, faith, war, historical crises and daily life.

## Shared text sources

[The lore library](../Lore/README.md) contains five books: the 29-chapter civic chronicle, a six-part First Architect biography, Registry and Surveyor histories, and a 153-word Dawn address. Together they contain more than eight thousand words of narrative. The civ README and [GitHub civ page](../../docs/civilizations/TheBoundlessCity.md) add substantial readable introductions and explain how the institutions fit together.

The books are also the source of the in-game text. `tools/boundless_lore.py` converts their paragraphs into localization, keeping chapter bodies reasonably sized. `tools/generate_database.py --text-only` refreshes only `SQL/10_BC_Text.sql`. The general database generator uses the same content. No gameplay SQL regeneration is needed for editing the lore.

## Why the native chapter keys matter

The installed Firaxis BNW `Assets/DLC/Expansion2/UI/Civilopedia/CivilopediaScreen.lua` reads civilization and leader history through numbered pairs under their `CivilopediaTag`. It starts at one and stops at the first missing heading or body. Merely enlarging the existing `Civilopedia` field would leave the normal civilization article without these chapters.

The existing pointers already select `TXT_KEY_CIV5_BC` for the civilization and `TXT_KEY_CIVILOPEDIA_LEADERS_BC_ARCHITECT` for the leader. This update supplies:

- `TXT_KEY_CIV5_BC_HEADING_1` / `TEXT_1` through `HEADING_29` / `TEXT_29`, plus a native factoid.
- Six corresponding leader chapter pairs and the native name, subtitle, lived, title and fact strings. Missing metadata can otherwise display untranslated keys in the leader article.
- Expanded `TXT_KEY_BC_CIV_PEDIA` and `LEADER_PEDIA` fallback fields for other consumers; the normal civilization page still uses the complete chapter sequence.
- Expanded `REGISTRY_PEDIA`, `SURVEYOR_PEDIA` and `DAWN` strings in their existing locations. Gameplay Help/Strategy strings and every workforce statistic remain unchanged.

Only five existing localization values change and eighty new native Civilopedia strings are added. All prose remains in English localization with normal fallback behavior. The civilization, leader, units, buildings, traits, gameplay IDs, save formats, version 14 and artwork remain unchanged.

## Verification

`tools/validate_boundless_lore.py` loads the actual BNW/CP schema and shipped SQL, verifies the live database text pointers and checks exact correspondence with the Markdown compiler. It checks safe paragraph/color markup, localization form delimiters, complete chapter sequences, metadata and bounded individual field lengths.

When the installed BNW script is available, the validator extracts and executes its actual civilization and leader heading loops against the shipped localization with a small control/locale model. It verifies all 29 and six chapters, then removes the first heading and a later body to test the native early-termination behavior. `CIV5_PATH` can identify the game directory on other machines. This is a source-contract execution with modeled controls; native fonts, localization DLL behavior and scrolling are not claimed as tested.

The validation is part of `validate_mod.py`'s actual-SQL checks. `verify_release.py` also extracts the updated localization from the Civ5Mod archive. Localization-only installation preserves other text in older installed versions, backs up the original text SQL/manifest and updates the one affected MD5.

## Reading in-game

After installation, restart Civ V and enter through **Mods**, ensuring the collection is enabled so its localization SQL is activated. Continue the existing modded save or enter setup. There is no lore-related save migration and no need to begin a new campaign.

Open **Civilopedia → Civilizations → The Boundless City** and scroll its headed articles. Select **The First Architect** for the biography; open **The Grand Registry** under buildings and **Frontier Surveyor** under units for their histories. The expanded prologue appears on a new game's Dawn of Man screen.

Native acceptance still requires checking chapter rendering, long-page scrolling and the Dawn address in Civ V. Election procedures, transport, local reserves and other institutions described in the setting are fiction explaining the existing civilization; this update does not introduce those as new simulated systems.
