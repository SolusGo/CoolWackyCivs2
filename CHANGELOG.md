# Changelog

## 1.14.0 Threshold Court implementation preview / mod version 17 — 2026-10-26

- Add human-only Queen Elsewhere and The Threshold Court, with active CP Pikeman/Market inheritance, Hingeguard +1 Movement/+15% friendly territory combat and Threshold House +1 Culture.
- Add real same-instance city-to-city Threshold Transfer, unlimited distance, exact Era Gold cost, one successful transfer per owner-turn, independent T+8 origin cooldowns and native save-serialized city/unit/player state.
- Add temporary native offensive restriction, zero movement, movement veto and upgrade deferral, recoverable relocation/payment receipts, stale city/unit checks and an event-driven destination/confirmation panel.
- Add original queen/guardian paintings, doorway heraldry, 48 mipmapped DDS textures, Civilopedia/Dawn/diplomacy text, guides, executable Lua tests and pinned v151 source contracts. Append SQL after the released inventory and retain collection UUID. Native game/render/save acceptance remains pending; see [testing](TheThresholdCourt/docs/Testing.md).

## 1.13.1 Jin Dynasty hardening preview / mod version 16 — 2026-10-26

- Automate localized Meng'an Mouke defense through deferred native orders, deterministic target selection, one saved order budget per owner-turn, return steps, mission vetoes and combat-safe retirement.
- Give Reindeer Traders native surplus-Food-assisted training and a reduced Gold hurry modifier; verify that their existing Moves 2 affects native land-route travel. Preserve route capacity, ordinary plunder and Tributary +15%; correct false Karma losses on route launch/return.
- Replace repeated HP-bank resets with deltas, cache spatial coverage and unchanged serialized snapshots, and coalesce UI updates. Add persistent recruitment/partial-Bribe receipts, corruption diagnostics, shutdown cleanup and executable failure/reload tests.
- Preserve other civilizations, existing art, Jin balance outside the targeted Trader changes, collection UUID/version 16 and save schema 1. See [findings, measurements and native limitations](JinDynasty/docs/Hardening.md) and the [fidelity classifications](JinDynasty/docs/AoE4Fidelity.md). Native gameplay/rendering/save acceptance remains pending.

## 1.13.0 Jin Dynasty implementation preview / mod version 16 — 2026-10-26

- Add human-only Jin Dynasty under Wanyan Aguda: active-baseline Mounted Villagers, chosen per-Landmark Grasslands, five-Horse inventories, native cavalry maximum HP and paid instant War Stable recruitment.
- Implement the full requested military/support roster, independent City-State Tributaries, hostile Barbarian Bribe replacements, all six constructed branching Landmarks, Flower Garden, Karma/blessing, Pagoda Groves and bounded temporary Meng'an Mouke defenders.
- Add thirteen named upgrades, functional six-tab crimson-and-gold panel, original Aguda painting, medallions/flags/map and retained art sources; preserve the collection UUID and append SQL after existing civilizations.
- Add focused executable Lua 5.1 tests on four speeds, installed-CP schema/inheritance/regression checks, pinned source audits, synthetic benchmark and package verification. See [Jin verification and native limitations](JinDynasty/docs/Testing.md). Native gameplay, rendering and save-file testing remain outstanding.

## 1.12.1 Urgal hardening preview / mod version 15 — 2026-10-26

- Correct Urgal to human-only, restore Strength II's +50% melee attack against enemy cities, and scale Aftertaste to 1/2/3/6 without changing the 3/5/7/12 Strength windows or other approved balance values.
- Reject embarked-only activation while preserving mixed-army snapshots and original deadlines; add immediate/embarked feedback and a dedicated purple potion UI icon.
- Harden save/event/context handling and expand generated-source, combat/healing, timing, UI and persistence checks. Retain the collection UUID, version 15 and existing save schema; in-progress legacy deadlines remain authoritative.
- Preserve other civilizations, including McPvP. See [Urgal's audit, exact changed files and validation limitations](TheUrgal/docs/Audit.md). Native gameplay/rendering/save acceptance remains pending.

## 1.12.0 Urgal implementation preview / mod version 15 — 2026-10-26

- Add human/AI-playable The Urgal from the supplied MCPVP Hardcore Games design: one initial Strength Potion plus one per new Era, uncapped persistent stockpiles, snapshot-only +50% melee attack against units, 3/5/7/12-turn speed windows and two-turn Aftertaste.
- Add the iron-free 14-strength/2-move/80-cost Urgal Rusher with permanent Pot Chaser and conditional native 15-HP kill healing. Add the Brewing Stand with Barracks training XP, 75 cost, 1 maintenance and local +10% eligible melee production; it never creates potions.
- Add the potion inventory/drink UI, visible-enemy/concentrated-army AI activation, English Civilopedia/Dawn/diplomacy, three original paintings, collection-style symbols/map and 48 DDS textures. Append new database IDs, retain collection UUID and update ModBuddy, manifests, guides and release verification.
- Add installed-schema inheritance/coexistence checks, four shipped-Lua lifecycle/UI/AI suites and pinned CP v151 combat, conversion and production source contracts. Native gameplay, rendering, saves and balance acceptance remain pending; see [Urgal validation](TheUrgal/docs/Testing.md).

## Boundless City lore and Civilopedia expansion — 2026-10-26

- Add five narrative books with more than eight thousand words on the One Charter, delegated government, citizenship, law, records, provision, infrastructure, finance, culture, crises and daily life. Expand the GitHub civ page and detailed README around that setting.
- Add 29 native civilization chapters, six leader chapters, complete leader metadata, Registry/Surveyor histories and a longer Dawn address. Supply the numbered Civilopedia keys required by Firaxis' article loader.
- Compile localization from the shared Markdown sources, add a safe text-only generation path and test the installed native chapter-discovery loops with modeled controls. Preserve version 14, mechanical Help/Strategy text, gameplay, saves and artwork. Native reading/scrolling remains pending; see [the lore integration record](TheBoundlessCity/docs/LoreIntegration.md).

## Boundless City map artwork repair — 2026-10-26

- Replace the leader painting in the civilization map slot with an original overhead parchment atlas of the Boundless metropolis.
- Compile the dedicated map for the native 360×410 display window on a 512×512 mipmapped DDS; route future art regeneration through its own compiler.
- Keep version 14, SQL references, gameplay, save formats and all other artwork. Preserve source/prompt/display preview and rebuild checked archives; native setup confirmation remains pending. See [the map report](TheBoundlessCity/docs/MapArtwork.md).

## Unrung Bell refinement audit — 2026-10-25

- Reject corrupt numeric Unrung save fields that overflow Lua numbers and previously granted maximum Quietude. Preserve valid v1 progression, all existing keys/identities, balance, artwork and collection version 14.
- Expand the Unrung audit to ten shipped-Lua suites, 44 pinned CP v151 source contracts, installed save/event/preview evidence and a precise native acceptance record. Correct the upgrade event-order documentation; retain working war/timer/city/promotion systems and the disclosed native combat approximation. See the [audit report](KingdomOfTheUnrungBell/docs/AuditReport.md). No other civilization implementation is changed; native gameplay/save acceptance remains pending.

## 1.11.0 Unrung Bell implementation preview / mod version 14 — 2026-10-25

- Add human-only Keeper Sable, Stillhaven, Bellwarden and Silent Belfry, with runtime inheritance of active Pikeman/Temple scalar and companion properties. No 3D model changes.
- Add persistent Quietude (one stack per five completed peaceful owner-turns, cap three), real city Culture, conditional Belfry Science and permanent Belfry Culture. Event-driven war consumption activates Great Toll tiers 5/10/15 through five full owner-turn windows; continuous wars cannot refresh it and complete peace removes it.
- Add English Civilopedia, strategy, supplied Dawn narrative and supported diplomacy responses, plus four original generated paintings/icons, tintable bell symbol, promotion badges and 48 DDS textures.
- Append new database IDs after all released content, retain collection UUID/minimum save version, update builder/ModBuddy/manifests and document the acceptance matrix. Native gameplay/save/rendering acceptance remains pending. **Verified CP limitation:** native friendly-land modifiers include open borders and ranged attacks use the shooter tile; exact exclusively owned-target combat is not implemented. See [guide and validation](KingdomOfTheUnrungBell/README.md).

## Conical Union reliability audit — 2026-10-25

- Fix recreated-context callback suppression, isolate per-city failures, retry targeted foreign cleanup and preserve cross-city reentrant events. Add bounded diagnostics, callback retirement/shutdown safety and one-time foreign load sanitation.
- Audit CP v151 connection/Production/Gold/Culture ordering. Retain deterministic lifecycle/owner-turn reconciliation: no supported general post-network/pre-settlement hook was verified, so the documented first-settlement limitation remains.
- Expand Conical validation to seven Lua 5.1 suites, 41 CP source contracts, installed Firaxis context/removal examples and altered Worker/Walls companion regressions. Preserve all numerical bonuses, human-only flags, SQL, artwork, UUID/version 13 and peer civilizations. Native quick-load, yields, Harbor routing, build progress and Huge-map acceptance remain pending; see [the audit report](TheConicalUnion/docs/AuditReport.md).

## 1.10.0 Conical Union implementation preview / mod version 13 — 2026-10-25

- Add human-only High Marshal Bollard and Permanent Detour. Connected non-capital cities receive exactly +2 Production/+1 Culture through an idempotent, stateless native-connection controller.
- Add Road Crew with complete runtime Worker inheritance, +1 Movement and 125% base Work Rate; add Detour Office with complete runtime Walls inheritance, +1 permanent Culture and +2 conditional Gold outside the Capital. No other unique mechanics or global Worker changes.
- Add full English identity, Civilopedia, diplomacy and silent Dawn of Man, four original generated paintings/icons, 40 mipmapped DDS textures and collection-standard atlas framing.
- Append database content after the released inventory, retain the collection UUID and minimum compatible save version, and extend ModBuddy/manifests, art preparation, collection validation and ZIP/7z verification.
- Add real-schema inheritance/regression checks, pinned CP v151 source contracts and three shipped-Lua 5.1 suites, including captures, reload reconstruction, API failures and large-empire idempotence. Native gameplay/rendering/save-load remain unverified. The cached connection flag and post-settlement turn callback can delay the first affected yield settlement; see [implementation timing](TheConicalUnion/docs/Implementation.md) and [testing record](TheConicalUnion/docs/Testing.md).

## Boundless Workforce graphical update — 2026-10-24

- Add an original engraved city panorama and six custom mipmapped DDS textures: brass/teal panel and launcher, row background, four-state native buttons and assignment/pending marks.
- Improve summary hierarchy, fit three complete district rows, and replace repeated yield words with native icons plus full-name hover tooltips. Retain all statistics, scrolling, callbacks, visibility guards and military controls.
- Preserve version 12, gameplay, Food mechanics, save formats and peer UI. Include reproducible sources/prompt, an actual-texture layout preview and extended asset/live-data UI validation. Native rendering remains pending; see [the visual guide](TheBoundlessCity/docs/UIVisuals.md).

## Substitute Classroom reliability audit — 2026-10-24

- Make Garvey's UnitPrekill enablement explicit and independently regression-tested; retain CP v151 compatibility and the 25% Culture formula.
- Use targeted city-dirty repair and cached Office counts, correct pre-removal razing relief, recover transient idempotent failures, and add three graphical patience pips without regenerating art.
- Preserve version 12, balance, human-only identity, v1 saves and all peer civilizations. Add 48 Lua 5.1 scenario runs, exact source contracts and a large-empire workload audit. Native testing remains unverified; see [the audit report](TheSubstituteClassroom/docs/AuditReport.md).

## 1.9.0 Substitute Classroom implementation preview / mod version 12 — 2026-10-24

- Add human-only Mr. Garvey and Room 101, persistent 12-turn Roll Call with five 8-turn student bonuses, corrections/Insubordination and five-turn Detention. Combat modifiers add; hidden native buildings/policies maintain yields and the non-stacking Office Happiness relief.
- Add Hall Monitor with complete active Pikeman inheritance and Principal's Office with complete active Public School inheritance; include a blackboard attendance UI, English Civilopedia/diplomacy, original leader painting and 41 mipmapped DDS textures.
- Append Classroom content after the existing collection to retain released IDs. Extend project/manifests, package verification, source/schema checks and 32 shipped-Lua scenario runs. Prior civilization art and mechanics remain intact.
- Automated validation is distinct from native acceptance: game rendering, native yields/combat/save-load and older-save continuation remain unverified. See [Classroom testing](TheSubstituteClassroom/docs/Testing.md).

## 1.8.0 Kingdom of Saba implementation preview / mod version 11 — 2026-10-23

- Add human-only Karib'il Watar, capital Ma'rib, and Where the Desert Blooms: River cities gain +1 Food/+1 Production; Desert city centers gain +1 Culture. Two invisible buildings and a stateless event/owner-turn controller maintain exact counts and ownership cleanup.
- Add Wadi Sentinel with complete active Spearman inheritance, native +15% Desert defense/+1 Sight, both lost on upgrade; add Ma'rib Cistern with complete active Water Mill inheritance and additive +1 Food/+1 Gold. CP's feature-aware TerrainModifiers table preserves defense on all underlying Desert.
- Add original generated leader/loading art, drawn collection-style emblems/UU/UB/map, 40 mipmapped DDS textures, full English identity/Civilopedia/diplomacy, guides, three shipped-Lua simulations and CP source contracts.
- Append Saba after the released SQL inventory; retain UUID, prior database IDs, save formats and peer mechanics/art. Extend optional metadata compatibility, real-schema adapter, build/validation registries and archive verification. See [Saba testing](KingdomOfSaba/docs/Testing.md) for actual checks and outstanding native acceptance.

## The 11 Cats Luna arrival hotfix — 2026-10-23

- Fix the native missing-UnitAITypes error that left unlocked Luna pending at zero turns. Use InitUnit's verified default AI argument and protect argument evaluation; existing save states resume without migration.
- Remove the fixture-only enum and add the native-context regression, bringing Cats coverage to fourteen suites. User logs confirm the original failure; post-fix native spawning awaits reload. No gameplay values, save formats or art changes.

## The 11 Cats final 2D quality and compatibility pass — 2026-10-23

- Verify silently rejected saves, block unidentified retained rollback births, merge queued lifecycle work and make screen transitions UI-only refreshes. Preserve every bonus, save format, UUID/version 10 and gameplay ID.
- Add eleven distinct source paintings, an exactly eleven-cat emblem, dedicated Austin leader/first-companion Dawn scenes, refined Cat Tree/paw/flag art and a quiet Household background. Improve row/card spacing, statuses and short-window height handling. All changes concern 2D presentation; existing House Cat 3D models/animations are unchanged.
- Preserve prompts and source masters; verify exact repeat builds and unchanged peer artwork. Expand to thirteen Cats simulation suites and stricter legacy DDS/mip/identity checks. Native acceptance remains pending; see [the quality report](The11Cats/docs/PolishReport.md) and [checklist](The11Cats/docs/NativeAcceptance.md).

## The 11 Cats reliability and Household polish — 2026-10-23

- Protect lifecycle guards and native save/spawn/remove failures, retain bounded deferred capture/era work, repair identities/duplicates/timers deterministically and stop stale city-effect writes after ownership changes.
- Add structured cat details, per-city portrait cards, four Bond diagnostics and optional saved settling/first-bond messages, using pooled controls and no polling.
- Preserve version 10/UUID, the gameplay save format, all numeric values/SQL IDs, six chapters, artwork and unrelated civilizations. Expand to eleven Cats simulation suites, exact source/SQL checks and stress/fault coverage. Native acceptance remains pending; see [the structured polish report](The11Cats/docs/PolishReport.md).

## 1.7.0 The 11 Cats implementation preview / mod version 10 — 2026-10-23

- Added human-only Austin, King of the House, and six era chapters welcoming the ten unique companions. Austin remains the leader and the first household member.
- Added persistent travel/residence/recovery identities; three resident slots per city; the exact ten personal bonuses and four Family Bonds; speed-scaled rehoming and protective recovery; Cat Tree Garden replacement; genuine-event WLTKD duration extension.
- Added the event-driven Household/Cats/Homes/details/story interface, English Civilopedia and diplomacy, and 50 mipmapped DDS textures prepared from the user's supplied emblem. Austin is white and crowned, and Sisi uses the dark tortoiseshell face at the lower left. No reference photographs were available.
- Appended all new SQL after released civilizations, retained the collection UUID and earlier database IDs, and updated the builder, manifest, ModBuddy project, roster and regression suite.
- Real-schema SQL, six Lua 5.1 simulation suites, CP source contracts, icon/XML/loading checks and full collection regression validation pass. In-game rendering, native save/load and gameplay acceptance remain unverified; see [the test matrix](The11Cats/docs/Testing.md). No full runtime-compatibility claim is made.

## Wandering Circus final implementation audit — 2026-10-22

- Protect an already-reserved Grand Festival once the owner's native turn has begun, preventing a same-turn Crew loss from splitting Production/Gold/Culture before the late PlayerDoTurn hook. Inactive-owner interturn loss still cancels normally, including a later human slot after raw rollover.
- Bound idempotent setter recovery per city so a persistently failing peer cannot block healthy cities' festival starts or expirations. Retain no authoritative Lua timing state.
- Add split economic phases, gated pre-staging autosave/automove replay, all before/after mutation points, pending transfers, Office purchase/removal timing, old-format snapshots, unit ownership and 128-city stress coverage: 40 Lua 5.1 suite runs and 59 pinned source contracts.
- Preserve all SQL, six marker identities/encoding, gameplay values, artwork, version 9/UUID and other civilizations. Native gameplay, saves/autosaves, rendering and release acceptance remain unverified. See the [ranked audit](TheWanderingCircus/docs/AuditReport.md).

## 1.6.0 Wandering Circus implementation preview / mod version 9 — 2026-10-22

- Added human-only Ringmaster Aurelio and The Show Must Go On: independent city festivals provide +3 Culture/+2 Gold for exactly three owner-turns, with twelve turns between starts. Native building markers persist boundaries; pre-economic staging uses CP v151's verified turn-end phase and cancels invalid pending Crew presence.
- Added Carnival Crew (complete active Worker inheritance, +1 Movement, unchanged WorkRate) and Ticket Office (complete active Market inheritance, +1 permanent Culture/+2 Production during local festivals).
- Added original leader/loading artwork, map, unit/civ/building/flag atlases, 40 DDS textures, English Civilopedia/diplomacy, all requested city names and original spy names.
- Appended SQL after all released content, retained the collection UUID, and left existing civilization gameplay/art files unchanged. Updated builder, ModBuddy project, manifest and validation.
- Focused checks pass: actual-schema/active-cache SQL, preservation of all previous rows, 30 Lua 5.1 simulation runs over five speeds/two start turns, and 29 pinned CP source contracts. Full collection regression/package checks are recorded in the implementation's validation record. Native yields, rendering, saves/autosave resumption and old-save continuation still require Civ V; no in-game pass is claimed.

## Twelfth Hour second-pass technical audit — 2026-10-19

- Corrected the OpenSaveData dot-call contract hidden by the original fixture, retaining existing save keys and all gameplay values.
- Added bounded synchronous recovery, isolated per-player repair, reliable notification persistence and verified post-sale cleanup.
- Added real fixture snapshot rewinds, identical-turn independent games, pre-staging autosaves and failure regressions; expanded source/yield/persistence evidence. See [the ranked audit report](TheTwelfthHour/docs/AuditReport.md).
- Preserved all SQL, artwork, identities, human-only flags and unrelated civilizations. Native yield/save/rendering acceptance remains outstanding.

## The Twelfth Hour implementation preview — 2026-10-19

- Added the human-only Keeper of Seconds and the Grand Chime: +75% city Production/+50% city Science every sixth played turn, synchronized with two native dummy buildings and CP next-turn staging.
- Added Pendulum Guard (full Pikeman inheritance, upgrade-retained +1 Movement/+15% friendly-territory strength) and Municipal Clocktower (full Workshop inheritance, +1 Culture, +2 flat Chime Production).
- Added original paintings, atlas/alpha/flag DDS assets, complete English Civilopedia/diplomacy text, all city names and event-driven notifications/load/ownership repair.
- Extended the builder, generated project/modinfo and collection validator; appended new SQL after the complete released inventory. Existing civilization gameplay/art files remain unchanged.
- Actual-schema SQL and active-cache activation, ten Lua 5.1 model runs, seventeen pinned source contracts and collection regression/package checks pass. Civ V was not launched; actual yield settlement, native saves/autosave resumption and rendering remain pending. See [timing limitations](TheTwelfthHour/docs/Implementation.md) and [all twenty acceptance scenarios](TheTwelfthHour/docs/Testing.md).

## Boundless Food growth hotfix — 2026-10-19

- Preserve existing remote yields through harmless native governor changes while actual default citizens still back them. This closes a reproduced pre-growth gap between the displayed and harvested Food rate.
- Keep conservative admission for new remote jobs and immediate removal for real citizen/eligibility losses. No Food-storage/population edits, balance changes, save migration or package-version change.
- Add the Food turn-order regression, six CP source contracts and updated guides. See [the hotfix report](TheBoundlessCity/docs/FoodGrowthHotfix.md) for evidence and the remaining native replay check.

## Kingdom implementation audit — 2026-10-18

- Fixed direct prayer activation across incompatible screens, frozen blessing expiry during temporary nonhuman control and Prayer reopening after missed popup events.
- Added three Kingdom regression suites, shared controller/panel interface validation, native healing/movement checks and explicit city-strength/ranged-strike source contracts. Retained the native +20% city-strength policy after reviewing defense-only alternatives.
- Preserved all gameplay values, seven petitions, Grace, uniques, human-only restrictions, IDs, save schema, artwork and other civilizations. See [the audit report](TheChildrenOfTheKingdom/docs/AuditReport.md) for severities, exact files and native verification still required.

## 1.5.0 Kingdom implementation preview / mod version 8 — 2026-10-18

- Added The Children of the Kingdom under The Faithful: human-only seven-stage Prayer, permanent Grace capped at seven, scaled deadlines, saved temporary blessings, safe ASK Production reserves and completed-House rewards.
- Added Keeper of the Faith with upgrade-retained native healing and separately gated friendly-territory defense; House of Prayer preserves the active Temple and adds human-only Faith/Culture. Normal AI assignment is disabled, with no AI prayer/strategy implementation.
- Added a dedicated event-driven panel, original generated/drawn artwork and 34 DDS textures, full English presentation, CP source audits, actual-schema inheritance checks, four shipped-Lua simulation suites and native test documentation.
- Updated builder/project/manifest and package version while retaining the collection UUID and existing civilization save formats. Native gameplay/rendering/save continuation remains unverified; see the [Kingdom guide](TheChildrenOfTheKingdom/README.md) and [precise implementation limits](TheChildrenOfTheKingdom/docs/Implementation.md).

## McPvP reliability and AI update — 2026-10-17

- Fixed Viper's reversed damage test using both verified CP v151 combat callbacks; added melee/ranged, survival, refresh, duplicate-event and poison save regressions.
- Added validated native objective routes, bounded weighted detours, planning budgets, failed-movement cooldowns, carrier survival and infiltration holds. Feast placement now checks legal access, rival approaches and practical arrival without a full-map scan.
- Added four McPvP regression suites and updated native testing/report documentation. Fixed Stomper mountain targets and Browser screen/status issues. Saved formats, original assets/localization, numerical balance, UUID and other civilizations are preserved.

## McPvP implementation preview / mod version 7 — 2026-10-17

- Added McPvP — The Endless Lobby under The Old Guard, with a persistent Server Browser, queued match cycles, contested Hardcore Games Feasts, Capture the Flag and warned Sabotage.
- Added five distinct kits, persistent Veteran Scout upgrades/retraining, Original Server Hub, capped Server Legacy, capital Culture milestones and Information Era remembrance.
- Added conservative AI using real objectives, original geometric artwork, 48 DDS assets, English presentation and complete player/implementation/testing documentation.
- Added actual-schema SQL, pinned CP v151 API/event checks and four Lua 5.1 simulation suites to the collection validator. The builder now loads Shared compatibility before every civilization, including names sorting before Shared.
- Full collection regressions and package/art checks pass. Native Civ V gameplay, rendering, save round trips and AI-only games remain unverified; multiplayer/hotseat remain unsupported. See the [McPvP report](McPvP/docs/ImplementationReport.md).

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
