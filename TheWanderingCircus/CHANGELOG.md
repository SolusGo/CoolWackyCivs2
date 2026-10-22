# Changelog

## Final audit — 2026-10-22 / collection v9 unchanged

- Fixed conditional cancellation of an already-begun reserved show during owner economic processing, preserving all three yields and original T+3/T+12 boundaries after Crew loss. Inactive interturn losses still cancel.
- Isolated bounded setter retries per city, preventing a failing city from starving healthy peers at preparation/expiration.
- Added the audit suite: split economic phases, real resume gates, all partial-write boundaries, later human/AI order, pending transfers, Office purchase/removal timing, saved Crew departure/death and 128 cities. Forty Lua 5.1 suite runs and 59 source contracts pass.
- Preserved SQL, all values, six native state markers, human-only flags, artwork and collection identity/version. No native gameplay/save/rendering pass is claimed; see [AuditReport.md](docs/AuditReport.md).

## 1.0.0 implementation preview — 2026-10-22 / collection v9

- Added human-only Wandering Circus, Ringmaster Aurelio, Grand Pavilion, all 24 requested city names and ten original spy names.
- Added exact local 3-turn festivals with a 12-turn start interval, native persistent boundaries and pre-economic staging with cancellation of invalid pending starts.
- Added complete active Worker/Market inheritance, +1 Crew Movement, +1 Office Culture and conditional +2 Production. No Work Rate change or extra festival yields.
- Added original Aurelio painting, drawn circus/ticket/Crew symbols and map, 40 mipmapped DDS textures, static diplomacy scene and complete English text.
- Added real-schema SQL validation, 30 shipped-Lua 5.1 simulation runs, 29 pinned CP v151 source contracts and the native test checklist. Civ V was not launched; native acceptance and older-save compatibility are pending.
- Appended Circus SQL after all released civilizations without changing their gameplay files or the collection UUID.
