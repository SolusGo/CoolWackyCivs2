# Validation record — 2026-10-16

Tests use an in-memory clone of the installed backup BNW debug database with CP v151 schema additions. The cache and CP files are opened read-only. No launched Civ V game was exercised for this implementation.

```powershell
python -m pip install -r requirements-dev.txt
python tools/prepare_art.py
python tools/build_mod.py --manifest-only
python tools/validate_mod.py
python tools/audit_cp.py
python tools/build_mod.py
```

Use `.venv/Scripts/python.exe` when dependencies are installed in the local environment. The schema adapter defaults to `Documents/My Games/Sid Meier's Civilization 5/cache_backup/Civ5DebugDatabase.db` and `MODS/(1) Community Patch`. The optional source cache comes from `python tools/audit_cp.py --fetch` at official commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`. Core Pigeon validation does not require source/network access; missing source contracts print SKIP explicitly.

Actual automated coverage:

- SQL runs against the local BNW/CP schema, validates playable identities/overrides/start data, all English keys/diplomacy wildcards/atlas references, unbuildable/unpurchasable/hidden/uncapturable dummies and SQLite integrity.
- Every Scout/Caravansary scalar and companion row is compared to the active baseline, allowing only identity/art/text changes, the sight promotion and additive Culture. A second database mutates Scout movement/sight, Caravansary cost/maintenance/range/Culture and adds extra CP scalar columns; all changes are inherited. Native and Boundless identity/mechanics records remain equal to their snapshots.
- Lua 5.1 simulations execute the actual addin, use the verified native route fields and reconstruct building yields through the SQL definitions. They cover the requested arithmetic, domestic food/Production/gold and international routes, sea exclusions, identical city names, overlapping IDs in different owners, malformed entries and multiple Pigeon players including AI.
- Lifecycle simulations cover completion before native removal, plunder owner argument order, caravan consumption, land/sea switching, war cancellation, Renaissance/team transition, Roost construction/sale/script removal, captured origins/destinations, razing/deletion, elimination, missing player slots and fresh-context load with deliberately stale saved counts.
- Repeated refreshes produce no extra writes. Five hundred dirty events coalesce into one update; synchronous dirty events emitted by dummy writes do not recurse. No callback remains installed while idle. The full scenario suite repeats for Quick, Standard, Epic, Marathon and a custom speed.
- Fourteen CP source contracts validate route field types and ownership, count-based building yields, reward suppression, hook names/signatures and native event ordering. Hashes are in `SourceAudit.json`. The collection's 176 existing CP source assertions also pass.
- Collection validation includes its ten existing Boundless Lua simulation suites, project/modinfo SQL order, hashes/VFS/import rules, XML parsing, Lua 5.1 syntax, DDS decoding and coexistence with the original collection. Archive creation validates the 7z package.

The following are **manual checks still required**. Simulation results do not establish engine event timing, native yields or visual integration.

| Test | In-game acceptance |
| --- | --- |
| 1. New game as Coo | Coo/civ visible in selection; Coopolis, Dawn image, map and Civilopedia render without missing keys/textures. |
| 2. Scout replacement | Carrier Pigeon appears in train lists/starting recon where a Scout class is requested, with correct unit portrait/flag and standard model. |
| 3. Sight/movement | One extra sight relative to current Scout, existing terrain-cost movement, normal mountain/ice/ocean/embarkation restrictions, recon promotions, ruins and upgrades. |
| 4. Roost | Current Caravansary cost, upkeep, tech, range, land trade Gold and all CP benefits remain; permanent Culture is exactly baseline +1. |
| 5. First land route | Medieval origin gains +2 Science/+2 Culture; destination/pass-through cities gain nothing. Roost origin gains +2 Production. |
| 6. Three same-origin routes | Medieval UA +6/+6; Roost remains +2 Production total. |
| 7. Different origins | Each city receives only its own outgoing route total; domestic and international routes both work. |
| 8. Sea route | No UA or conditional Roost Production. Switching all routes to sea clears land bonuses. |
| 9. Cancellation/plunder/war | Removed routes lose their bonuses after deferred refresh; check ordinary income timing over the next turn, expiration and recall. A recalled route remains eligible while CP still reports it active. |
| 10. Renaissance | Three active routes become +9 Science/+9 Culture, with no Production change. Repeat team-era transition. |
| 11–12. Conquest/transfer | Losing/capturing/gifting/liberating an origin or destination recomputes routes. Non-Pigeon recipients retain no postal dummies; razed/deleted city causes no Lua errors. |
| 13. Roost removal | Remove/sell Roost; Production disappears while route UA continues. Rebuild and check +2 returns. |
| 14. Save/load | Save with several origins, both domains and an active Roost; reload and verify exact yields, no duplication. Repeat after cancellation and after conquest. Also verify upgrading a prior Boundless save to collection v5. |
| 15. AI opponent | Play another civ against Coo; inspect AI origin yields and normal defense/trade behavior. No Boundless effects leak into Pigeon players. |
| 16. Speeds | Repeat route arithmetic at Quick/Standard/Epic/Marathon and a modded speed. Flat yields stay +2 or +3, Roost +2. |

Enable normal Civ V Lua/database logging and check `Lua.log`, `Database.log` and `xml.log` for this mod's errors. Verify city yield tooltips and diplomacy greeting, war, peace and defeat text. Inspect icon cropping at small sizes and static leader scene/loading/map presentation. All artwork is shipped; no missing-art placeholder is intended. Custom models/voice acting are optional future work.
