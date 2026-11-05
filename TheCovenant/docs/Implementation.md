# Covenant implementation

`CovenantGate.xml` is the sole simulation-owning InGameUIAddin. It includes the namespaced verse data and pure Lua 5.1 memory engine. The engine has no Civ API calls, so its exact matching, progression and numeric serialization are exercised directly by tests.

The gate checks for the living active human Covenant player and excludes network games and hotseat. It queues at `PopupPriority.eUtmost`, consumes unhandled input, covers the game surface and holds the standard turn-timer semaphore while shown. A quarter-second recovery check handles missed load/turn notifications or forced UI hiding; study countdowns update while visible. Native popup priority and actual keyboard dispatch still require play testing.

The word matcher lowercases text, standardises quotes, ignores punctuation and normalises whitespace. It retains word order and spelling. Reference comparison requires the canonical book and all chapter/verse digits while ignoring separators. A change callback rejects insertions of multiple characters, including replacement pastes; this is a practice control rather than a secure anti-cheat system.

`Modding.OpenSaveData()` stores a numeric-only serialized state after each submitted action. No saved text is executed as Lua. The key includes a checksum of passage references/wording and the player ID. Pending exam queues, assistance and section progress survive context reconstruction in the model; actual game-file save/load remains unverified. A separate per-turn reward marker prevents repeated rewards on an exam turn.

SQL adds new rows only. The new leader and civilization reference stock Ramesses/Egypt art. Replacement buildings copy selected native cost/technology/maintenance/art fields and Temple prerequisite classes, then apply fixed custom yields. This is not a complete clone of every possible companion-table effect supplied by unrelated building overhaul mods.

The collection retains its UUID, minimum compatible save version and all prior civilization identities. The new module is appended after the released SQL inventory. No existing civilization gameplay or art source is changed.
