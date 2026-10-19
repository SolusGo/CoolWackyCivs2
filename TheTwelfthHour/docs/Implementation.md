# Implementation and turn timing

## Six-turn schedule

`playedTurn = Game.GetGameTurn() - Game.GetStartTurn() + 1`; a positive played turn divisible by six is a Chime. For a normal Ancient start the raw values are 0–4 (normal), 5 (Chime), 6 (normal), 11 (Chime). Subtracting the saved immutable start turn also keeps the first five **played** turns normal in advanced-era starts. Speed, city age, era and capital are not inputs. There are no city countdowns or random rolls.

## Native processing evidence and chosen hook

The official CP v151 source pinned at commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb` is audited by `tools/validate_twelfth.py`; hashes and direct source URLs are retained in [SourceAudit.json](SourceAudit.json). In [CvPlayer.cpp](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlayer.cpp):

1. `setTurnActive(true)` calls `doTurn()`, then `doTurnPostDiplomacy()` (AI diplomacy can defer this).
2. `doTurnPostDiplomacy()` calls each city's `doTurn()`, which runs `doProduction()`.
3. `doResearch()` credits `GetScienceTimes100()` to team research, including ordinary city Science rates.
4. **Only then** does `PlayerDoTurn` fire.
5. During player deactivation, `PlayerDoneTurn` fires, gated by `EVENTS_PLAYER_TURN`. The new module enables that option.
6. The global game turn increments before the next player-turn round.

Applying a dummy only at `PlayerDoTurn` would change the display after the harvest and credit the bonus on the following turn. The implementation instead stages the **next** played turn synchronously at `PlayerDoneTurn`. Ending played turn 5 sets the dummies for the sixth-turn economic pass; ending 6 removes them before the seventh-turn pass. `PlayerDoTurn` performs idempotent repair and sends the once-per-cycle notification after settlement; it does not grant resources.

The normal city display during active turn 6 agrees with that turn's economic state. Between the player finishing turn 5 and beginning turn 6, the saved city state is deliberately prepared for turn 6. This staging interval is necessary for the available hooks: there is no verified general pre-city-harvest Lua event in this source. An inspector viewing cities during other players' moves may therefore see the upcoming modifier before the global counter advances. This is a documented timing limitation, not an extra economic harvest. The native economy credits the queue prepared before entering turn 6; changes made after its economic pass cannot retroactively affect that pass.

**Evidence limit:** this is source-supported staging plus a source-shaped simulation, not an empirically tested native timing guarantee. The native end-turn autosave occurs early in `setTurnActive(false)`, before `PlayerDoneTurn`. The second-pass audit traced the ordinary resume path through serialized active/end/automove flags, rebuilt processed-automove state, and deactivation; its new snapshot model tests that path. Actual engine loading/mission cancellation still needs the explicit autosave acceptance test. No arbitrary Production or research compensation is attempted. A save first given this module after its Chime harvest can repair current dummies but cannot retroactively change that already-settled harvest. See [AuditReport.md](AuditReport.md).

## Database and dummy buildings

`BUILDING_TWELFTH_GRAND_CHIME` has exactly two `Building_YieldModifiers` rows: Production 75, Science 50. `BUILDING_TWELFTH_CLOCKTOWER_CHIME` adds Production 2 through `Building_YieldChanges`. Only an eligible city with the actual Municipal Clocktower gets the latter. Both dummies have zero maintenance, no prerequisites/obsolescence, `Cost=-1`, `FaithCost=-1`, `GreatWorkCount=-1`, `IsDummy=1`, `ShowInPedia=0`, `NeverCapture=1`, `ConquestProb=0`, and valid fallback icons. Counts are strictly 0 or 1.

`SetNumRealBuilding(..., true)` suppresses construction rewards while invoking normal native building/yield updates. Counts are changed only when different. No Lua arithmetic adds resources, modifies queues, or changes research progress. The engine combines the Clocktower's two base Production with the native percentage modifiers, rounding, resistance, anarchy, overflow and item rules.

Units and buildings are cloned using temporary `SELECT *` tables **at activation**, preserving active CP scalar columns, including subsequently added scalar fields. The schema-aware generator copies every installed direct `Unit_* / UnitType` and `Building_* / BuildingType` companion table, including promotion, resource, specialist-related yield, prerequisite and modifier data. Class-based rules continue through the original Pikeman/Workshop class. The only building yield adjustment is an additive +1 Culture; an existing Workshop Culture row is incremented. Unit Movement stays at its inherited scalar value; the new promotion alone adds one Movement and one `FriendlyLandsModifier=15`. `FriendlyLandsAttackModifier` remains zero; `LostWithUpgrade=0`. Native territory semantics determine what counts as friendly territory and the relevant battle plot.

## Saves, ownership and event handling

The cycle derives solely from saved game/start turns. Two namespaced `Modding.OpenSaveData()` keys exist per player: the raw turn on which next-turn staging occurred, and the last raw turn notified. This is the savegame database, shared by mods within one save, not the per-user `OpenUserData` store. Its returned `GetValue` and `SetValue` functions use **dot calls**, matching installed Firaxis scenarios. The second-pass fix preserves the existing keys and data; no migration/reset is needed. The staging key is a phase marker, not a running clock: it is relevant only while equal to the current raw turn and expires automatically when the game advances. Interturn loads retain the staged next-turn counts; active-turn loads reconstruct current-turn counts. Notifications record successful delivery; an in-context marker prevents duplicate delivery when only persistence needs retrying. See [SaveApiAudit.json](SaveApiAudit.json) for evidence and native verification limits.

Context creation synchronously repairs all owners once, including stale foreign dummies. Founding and capture/gifting/liberation update affected owners synchronously. Constructing/purchasing the Clocktower activates its conditional dummy when the native completion hook permits; it cannot change already-spent Production. The verified post-removal sale hook reconciles synchronously. Generic game-data dirty events coalesce into one detached callback to cover scripted changes; end-turn synchronization is synchronous regardless. Protected work retries once immediately, including transient database-open/read/write or post-mutation setter faults; persistent failures are bounded/logged. One player's failure does not abort the remaining players' load/batch repair. No city userdata is retained. Dead players are scrubbed; invalid players and zero-city civilizations are safe. Unusual AI-controlled instances retain the existing deterministic behavior without human notifications; no AI feature was added.

Normal work is limited to affected players' cities, plus a bounded civilization-ID loop on dirty events. There are no map scans, unit scans, timer polling or permanent frame callbacks. During synchronization, self-generated dirty events are ignored to avoid repeated yield recalculation.

## Packaging and compatibility

Five ordered SQL files, a single simulation-owning XML/Lua entry context, uniquely prefixed Lua/texture names, DDS atlases and fallback scene are registered by the existing builder. New SQL is appended **after the complete previous SQL inventory**, preserving existing content's insertion order. No existing civilization source or art is edited. Shared changes are limited to the builder, validator, generated manifests and collection documentation. Event options are additive; their preexisting handlers remain intact. Compatibility still requires native save acceptance testing; other mods changing turn hooks or the database after this module can affect results. Multiplayer/hotseat/Mac remain outside the collection's supported configurations.

## Changed-file inventory and completed validation

- `TheTwelfthHour/SQL/`: `00_TWELFTH_Core.sql`, `01_TWELFTH_Inheritance.sql`, `02_TWELFTH_Effects.sql`, `03_TWELFTH_Art.sql`, `10_TWELFTH_Text.sql`.
- `TheTwelfthHour/Lua/TWELFTH_Chime.lua` and `UI/TWELFTH_Clock.xml/.lua`: one event-driven simulation context.
- `TheTwelfthHour/Art/`: forty DDS textures and `TWELFTH_LeaderScene.xml`.
- `TheTwelfthHour/README.md`, `CHANGELOG.md`, and `docs/Implementation.md`, `Testing.md`, `SourceAudit.json`, `Validation.json`.
- `art-source/TheTwelfthHour/`: three original PNG paintings, atlas preview and provenance/prompts; `art-source/IconAtlasMasters/TWELFTH_*.png`: three retained medallion masters.
- `tools/generate_twelfth.py`, `prepare_twelfth_art.py`, `validate_twelfth.py`, and `tools/tests/twelfth_mock.lua`, `twelfth_assertions.lua`.
- Second pass: `tools/tests/twelfth_audit_assertions.lua`, `docs/AuditReport.md`, `docs/SaveApiAudit.json`; updated runtime, fixtures, validator and civilization/collection documentation. No gameplay SQL or artwork changed.
- Shared integration: `tools/build_mod.py`, `tools/validate_mod.py`, generated `CoolWackyCivs2.civ5proj` and `Cool Wacky Civs 2 (v 8).modinfo`, root `README.md`/`CHANGELOG.md`, `docs/AddingCivilizations.md`, and `docs/civilizations/TheTwelfthHour.md`.

The initial implementation passed the collection validator with ten Twelfth model runs and seventeen source contracts. The second pass expands that to **20 suite runs and 43 CP source contracts**, plus actual fixture snapshot restoration, pre-staging autosave paths, synchronous fault recovery, CP-derived yield arithmetic and installed Firaxis save-API evidence. The collection still has 230 atlas-size entries and 327 gameplay files. All **278 unrelated gameplay files** retain their original hashes/VFS flags and the previous **27 SQL actions** remain an exact prefix. See [AuditReport.md](AuditReport.md) and [Validation.json](Validation.json) for current results; **actual native gameplay is still untested**.
