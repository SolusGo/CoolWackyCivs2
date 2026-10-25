# Life under one charter

The Boundless City is an original fictional civilization whose territory is one municipal jurisdiction. Its people inhabit many districts, including farms and islands; they share one charter, citizenship, treasury and final seat of government. The setting uses distributed administration to explain a city that grows across a world.

## Read the setting

- [The Charter of One Threshold](TheCity.md): the complete civic chronicle, from the Seven Crossings to government, work, provision, water, law, trade, culture, crises and daily life.
- [The First Architect](TheFirstArchitect.md): the founder, the office, the limits of planning and the legacy inherited by later generations.
- [The Grand Registry](TheGrandRegistry.md): records, distributed archives, correction, privacy and civic memory.
- [Frontier Surveyors](FrontierSurveyors.md): fieldwork, practical construction, existing land claims and the duty to return.
- [At the First Threshold](Dawn.md): the in-game Dawn of Man address.

These books supply the in-game Civilopedia and are included in release archives. The civilization and leader use numbered, separately headed native articles; the Registry and Surveyor use their normal historical entries.

## Who decides what?

| Institution | Responsibility | Answerable through |
| --- | --- | --- |
| Street committees and ward councils | Local services, residents' testimony, immediate repairs and emergency action | Residents, public accounts and appeals |
| Reach boards | Services crossing several wards: watersheds, passes, ferry corridors | Delegated mandates and the common charter |
| Council of Wards | Common law, major taxation, appropriations and executive authority | District representation and the Common Bench |
| First Architect and College of Works | An integrated program of works and competent administration | Council funding, inspection, records and legal challenge |
| Common Bench | Final appeals, charter rights and review of officials | Public judgments and the charter's procedures |
| Grand Registry | Reliable records, revisions, obligations and the means to prove a claim | Witnesses, audit, lawful decisions and correction |

The relationships are deliberately capable of conflict. The city has experienced exclusion, coercion, overcentralization and public works that served officials better than residents. Its founding ideals remain standards people can use against their government.

## Reading the lore beside the game

| Existing game abstraction | Interpretation in the setting |
| --- | --- |
| One city and original capital | One municipal legal identity and enduring common seat; inhabited districts can extend far beyond it |
| One population, local/remote work and specialists | One shared account of labor; distant workers live in their districts and cannot be assigned twice |
| One production queue | Major appropriations compete for the same citywide pool of skilled labor, materials and commitments |
| Food credited to the capital | Provision moves among wards and local stores; the common account combines it without implying every meal travels through one granary |
| Culture-driven contiguous growth | Shared institutions, measures, trust and obligations extend outward from established neighborhoods |
| Registry territorial Culture | District records, public memory and an increasingly broad common civic identity |
| Frontier Surveyor improvements | A proposed district becomes useful through actual work, with the first completion entering civic memory |
| Original-capital loss and reclamation | Institutions in exile preserve a duty to return to the founding seat |

The institutions and events are worldbuilding. This update adds text; it does not implement ward elections, transport networks, tax rates, local reserves, new resources, additional queues, extra population or new combat systems. Existing mechanics and their documented engine limits remain the rules of play.

## Editing and compiling

The Markdown books are the text source. `tools/boundless_lore.py` converts their paragraphs into native localization and builds contiguous Civilopedia chapter keys. Run `python tools/generate_database.py --text-only` to refresh only `TheBoundlessCity/SQL/10_BC_Text.sql`. The general database generator uses the same content.

For the in-game reading locations, installation notes and validation scope, see [LoreIntegration.md](../docs/LoreIntegration.md).
