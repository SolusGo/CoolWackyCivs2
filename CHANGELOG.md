# Changelog

## 1.4.0 Trainer Red preview / mod version 7 — 2026-10-16

- Added The Indigo Champion under Trainer Red with persistent Training, a six-slot Champion Team, Momentum/Ribbons, Pokémon Ace/Center, Indigo Plateau and journalled Journey to Mt. Silver.
- Added Summit-Trained and six distinct role-assigned Pokémon identities, explicit roster/bond/item/airlift actions, AI progression and game-speed support.
- Included original leader/Dawn paintings, original map and symbols, 58 mipmapped DDS assets, full English help/Civilopedia and an installed-game peace/war audio fallback.
- Added actual-schema/source/Lua-state/ability/UI/art validation and extended the collection builder/project/manifests. Existing Boundless/Pigeon gameplay and save schemas remain intact.
- Preview: native gameplay, AI-only matches, rendering and native save round trips still require verification. The report documents CP damage/fortification/airlift workarounds and the limit on universal forced-displacement immunity. See [the Red report](TrainerRed/docs/ImplementationReport.md).

## Unreleased — Workforce summary display — 2026-10-16

- Fixed the summary's literal pipe separators, which Civ V interprets as alternative localized text forms. The first form ended at Population, hiding Owned Plots and subsequent fields.
- Displayed all fifteen statistics in individual localized labels under Territory, Workforce and Management. Frontier Culture and next-claim cost are explicit; occupied-capital census values show an unavailable message while territory and siege information remain accessible.
- Added natural-height wrapped columns and a scrollable overview containing the summary and yields. Kept the 900×700 panel, existing controls, row paging, visibility/refresh behavior, gameplay and save schema.
- Added SQL-backed localization, all-field/zero/large-value, layout-boundary, live-data, action, load and transition regression checks. Native font rendering and in-game confirmation remain manual; see the summary display report.

## 1.3.1 Icon consistency / mod version 6 — 2026-10-16

- Added matching beveled gold rims to both leader portraits, civilization emblems and unique unit/building icons.
- Centred leader artwork in 75% of each slot, giving a 96px visible portrait in the native 128px selection slot. Other colour icons use 90%; every registered atlas keeps its exact dimensions and cell indices.
- Retained lossless atlas masters and added automatic build finishing plus decoded DDS dimension, padding and gold-rim checks. Player-colour masks and unit flags remain monochrome.

## 1.3.0 Pigeon Republic / mod version 5 — 2026-10-16

- Added The Republic of Pigeons under Postmaster General Coo, with Coopolis and 23 additional original city names, full English Civilopedia/strategy/diplomacy text and trade-oriented AI flavors.
- Messages on the Wing gives each outgoing land route's origin +2 Science/+2 Culture, increasing to +3 each in the Renaissance. Domestic/international routes stack; sea/incoming routes do not qualify. Native counts are rebuilt on turns, load and coalesced route/city/era/war events.
- Carrier Pigeon inherits the active Scout and all companion rows, preserves its existing ignore-terrain promotion and adds +1 Sight. Rooftop Roost inherits the complete active Caravansary, adds +1 Culture and a binary +2 Production while dispatching land trade.
- Included original Coo leader/loading artwork, 34 DDS textures, postal civ/unit/building/alpha/flag atlases and an original postal map. The standard Scout 3D model is retained.
- Extended package/project generation to both civilizations and two isolated addin contexts. Retained the collection UUID, minimum compatible save version and Boundless gameplay/persistence files. Existing native saves and new Pigeon games require the documented manual verification.
- Added actual-schema inheritance/regression checks, Lua 5.1 simulations including fresh-context load and five game speeds, and 14 pinned CP v151 route/building/event contracts. Existing Boundless suites remain part of collection validation. See the Pigeon validation record for actual results and native test requirements.

## 1.2.2 Workforce UI hotfix / mod version 4 — 2026-10-15

- Replaced cached city-screen/interface-mode decisions with current native queries. Observe actual BNW popup and leader context visibility so missed close notifications recover and early Processed notifications cannot expose the launcher over a visible screen.
- Refresh the closed launcher after game/city UI changes and screen transitions. Reset unrecognized popup event flags on load, player/turn start and context return; actual native screens still take precedence.
- Coalesce one-shot UI refreshes through the existing ClearUpdate dispatcher, without replacing queued gameplay work. Guard newer transitions during dispatch; release the rendering guard after failures and log visibility changes for diagnosis.
- Expanded the ten simulation suites with missed/early/nested popup, native city/mode/diplomacy, lifecycle, rendering-fault, UI/gameplay/reentrant dispatch and 1,000-event/idle regressions. Updated guides and rebuilt archives. Native UI retry remains required.
- Recorded the player's successful replay of the prior crash. Native mod version 4, schema 3, UUID, BCY2 and existing saves remain compatible.

## 1.2.1 dispatcher hotfix / mod version 4 — 2026-10-12

- Fixed the rejected native SetUpdate(nil) call that left the deferred update installed and flooded the live game's Lua log. Use ClearUpdate before dispatch.
- Corrected the mock to require function callbacks and keep updates registered until explicitly cleared; added a persistent-frame, event-storm, reentrant/failure/movement regression suite. Ten suites pass under the stricter contract.
- Preserved native mod version 4, schema 3, UUID, yield ledger, gameplay values, user ModBuddy edits and save compatibility. Rebuilt hotfix archives; native crash replay remains outstanding. The original collection's separately logged errors are unchanged.


## 1.2.0 engine preview / mod version 4 — 2026-10-12

- Added native civilization-scoped zero-city survival while units remain, and a deferred original-capital-only siege reclaim action. Ordinary NoCapture remains. Eliminated players are not revived; older native trait caches need upgrade verification.
- Added one-time non-destructive subjugation for defeated protected/own-founded major settlements, shared human/AI validation, action/actor identity checks and a lost-capital military panel.
- Added an optional Boundless-only native Domination finish after all ever-alive other-team rival original capitals are subjugated. Missing/replaced originals and disabled/prior victories block it. Native victory behavior remains unplayed.
- Added assigned-only native-rate improvement upgrade progress and explicit native Tourism refresh after terrain Culture changes/removal.
- Added extra-city native border-selection and new-trade-route vetoes. Absolute ownership and empire-level quarantine effects remain engine limited.
- Migrated Lua state explicitly to schema 3; kept BCSTATE1/BCY2, UUID and minimum save compatibility 1. Prior progress, identity, preferences and rewards persist; no downgrade support.
- Expanded to nine Lua simulation suites and 176 pinned native-source checks; refreshed Huge-map simulations and v4 ZIP/Civ5Mod artifacts. Updated READMEs, civ page, implementation/API/live-test guides, effect matrix, six-status report and optional DLL proposal.

This is an implementation preview. Full population-only reservation and general own-founded enemy demolition remain blocked. Native gameplay, save/trait upgrade, AI tactics, victory ordering and FPS must be verified through the live checklist.


## 1.1.1 stability preview / mod version 3 — 2026-10-12

- Added visible/previously revealed siege targets with explicit protection, damage, melee, war, visibility and native-limit reasons; invalid actions are disabled and AI queues only ready targets.
- Added city-ID revalidation for new demolition records and protected other city centers during territory release.
- Added native resistance and cached-rate refresh to quarantine, plus remote/Surveyor exclusion for its associated plots. Transient ownership and empire-level effects remain restrictions.
- Removed created/converted Settlers outside native callbacks even after original-capital loss, while preserving the initial Settler.
- Restricted return-loop suppression to the same turn and allowed a living empty Boundless player to receive only its recorded original capital.
- Cleared workforce credits/cache immediately after indexed or full trim failures; included automatons in the fast-path census and exposed them separately in UI.
- Made optional save-mirror open/write failures nonfatal to authoritative Player ScriptData.
- Added stale/dead/upgraded AI target cleanup, native build-ID guards, busy-target reservations, three-turn unreachable cooldown, fair unit rotation and a shared 12-path budget per owner turn.
- Passed eight simulation suites, actual SQL/package/art checks and 129 source assertions; expanded measurements to 22 major-player records, 40 minor-player slots and 200 military units at up to 10,000 owned plots.
- Kept native save schema 2, BCY2 ledger and minimum compatible mod save version 1. Version 1 migration and version 2 progress remain supported; native upgrade testing is outstanding.

Existing art, civilization mechanics and balance numbers are unchanged. Full population-only reservations and demolition of first-founded enemy settlements remain unsupported through the verified CP v151 APIs. See the [final report](TheBoundlessCity/docs/FinalStabilityReport.md).

## 1.1.0 implementation preview / mod version 2 — 2026-10-12

- Added verified surplus labourers alongside forced local withdrawals. The 80/500 and 150/1,000 stress fixtures now support 50 and 120 remote citizens; full population-only capacity remains unavailable through CP Lua.
- Corrected count-multiplied specialist extras, split gross terrain yields from labourer compensation, refreshed native cached rates, and journalled partial mutations.
- Separated Manual selection from locks, made Automatic ignore old locks, and added accurate citizen/capacity/pending/lock/yield counters with eligible-inventory limits.
- Added restricted native-legal siege demolition with deferred execution and protection checks. First-founded enemy settlements still fail native legality.
- Replaced arbitrary extra-city recipients with historical/native liberation recipients, return-loop suppression, legal disband fallback and protected-city quarantine.
- Preserved original capital identity and its workforce when returning another city; strengthened Settler, project/process and quarantine guards.
- Added indexed movement checks, coalesced change dispatch, cached AI targets/build lists with path budgets, and cached paged UI rows.
- Added explicit version 1 state/ledger migration, schema-shape validation and future/corrupt payload preservation.
- Passed six Lua simulation suites, actual-schema SQL/package/art checks, 121 pinned source assertions and read-only original-collection namespace checks. Recorded benchmarks through 10,000 owned plots.
- Updated the collection/civ guides, civ page, limitations, native test checklist and detailed [fixes report](TheBoundlessCity/docs/FixesReport.md). Existing art, uniques, personality and numeric balance remain unchanged.

Native gameplay, save/load, AI path completion and FPS remain untested. Version 2 keeps the mod UUID and minimum compatible save version 1; back up old saves and do not downgrade migrated saves.

## 1.0.0 implementation preview — 2026-10-12

The following records the original version's behavior; see 1.1.0 above for current limits.

- Created CoolWackyCivs2 as an independent collection and Git repository with its own mod identity.
- Added The Boundless City, led by The First Architect, with a single original capital.
- Added a separate Culture accumulator and deterministic, contiguous frontier growth without a distance limit.
- Added remote plot assignment through verified native labourer reservations and exact evaluated plot yields, subtracting replacement labourer yields.
- Added Automatic, Manual and Hybrid modes, Food/Production/Gold/Balanced priorities, persistent locks/exclusions, directional borders, paged browsing and plot location controls.
- Added The Grand Registry's +3 Culture, capped territorial Culture and 15% frontier-cost discount; inherited the active Monument's other effects.
- Added a 3-Movement Frontier Surveyor with 125% base Worker work rate, inherited build/AI/upgrade relations, and persistent one-time distant improvement rewards.
- Added native no-capture promotions, founding/training vetoes, Settler cleanup and deferred safe transfer recovery.
- Added player-save persistence, a native city yield ledger, deterministic AI allocation and idle Surveyor missions.
- Added original illustration and 34 DDS assets, ModBuddy solution/project, load-ordered modinfo, ZIP/Civ5Mod builders and focused SQL/Lua/UI/package tests.
- Fixed LF line endings for text assets so committed manifest checksums remain valid on Windows and fresh checkouts.
- Added a detailed collection README, dedicated civilization page, civ README/changelog, API audit, implementation guide, limitations and CP v151 testing checklist.

### Remaining verification and design gaps

- Live game selection, native save/load, capture/transfer UI ordering and Huge-map FPS have not been tested.
- Remote distance is unlimited, but remote count depends on native tiles from which citizens can be safely withdrawn; the original population-only capacity requirement is unmet.
- Military city capture is blocked. Automatic destruction of ordinary conquered cities and a civilization-specific Domination victory are not implemented.
- Unexpected transfers recover after the native action. If no eligible living recipient exists, the extra city is quarantined; an absolute synchronous one-city guarantee against arbitrary external scripts is unmet.
- Virtual tiles do not count as natively worked tiles for conditional worked-tile triggers, improvement evolution or worked-tile tourism. Six ordinary plot yields are supported.
- AI deployment is implemented and simulation-tested in parts; complete native builder/pathfinding behavior still needs game verification.
