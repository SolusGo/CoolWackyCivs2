# The Wandering Circus

**Ringmaster Aurelio** leads this human-only civilization for Civilization V: Brave New World and Windows **Community Patch v151**. Capital: **Grand Pavilion**. Favor Culture, with Science as a secondary path.

**The Show Must Go On:** end a Carnival Crew's turn on one of your city-center plots. At the next owner-turn, an eligible city hosts a Grand Festival: **+3 Culture and +2 Gold for three owner-turns**. A festival beginning at T is active at T, T+1 and T+2, expires at T+3, and permits its next start at T+12. Each city has its own schedule, including the capital. Extra Crews never stack. Crews are not consumed; after activation they can leave and the show continues. Ordinary and captured foreign Workers cannot trigger shows.

**Carnival Crew:** replaces Worker, inherits all active CP Worker properties/build permissions and gains exactly **+1 Movement**. Work Rate is unchanged. Starting Worker-class grants resolve through the native civilization override; captured foreign workers retain the normal native capture rules but do not qualify for festivals.

**Ticket Office:** replaces Market and retains its active CP benefits, adding **+1 permanent Culture**. During the city's festival only, it adds **+2 flat Production**. Constructing or selling it changes that conditional bonus; the festival's duration and cooldown continue normally.

| City state | Extra Culture | Extra Gold | Extra Production |
| --- | ---: | ---: | ---: |
| Neither Office nor festival | 0 | 0 | 0 |
| Festival, no Office | 3 | 2 | 0 |
| Office, no festival | 1 | 0 | 0 |
| Office and festival | 4 | 2 | 2 |

These are added base yields, excluding inherited Market effects. Ordinary city modifiers and native anarchy/resistance/razing rules still apply. Six festivals provide +18 Culture/+12 Gold; six Offices add +6 permanent Culture and +12 conditional Production.

Develop improvements between festivals, then bring a Crew back before an eligible turn. Leaving a Crew permanently in town automatically prepares the next show at T+12, at the cost of time spent improving the countryside. Duration and cooldown stay at 3 and 12 turns at every speed.

## Installation and validation

Build the collection with `.venv\Scripts\python.exe tools/build_mod.py` (or Python with `requirements-dev.txt` installed). Extract `dist/Cool Wacky Civs 2 (v 9).zip` into the Civ V `MODS` directory; the versioned folder must contain its `.modinfo` directly. Remove the older collection install folder, enable Community Patch and Cool Wacky Civs 2 in Mods, then choose Ringmaster Aurelio in single-player setup. The collection UUID is unchanged. The original CoolWackyCivs mod is separate and unnecessary.

Focused validation: `python tools/validate_circus.py`. Collection validation: `python tools/validate_mod.py`. Development regeneration: `python tools/generate_circus.py`, `python tools/prepare_circus_art.py`, then `python tools/build_mod.py --manifest-only`. The builder registers new atlas families before finishing their textures and hashing them. The shared icon compiler requires DirectXTex `texconv`; committed assets are sufficient for installation. After deliberately changing retained 256px icon artwork, use the shared compiler's `--refresh-sources` option for the affected atlas.

Native gameplay, economic payouts, render quality and engine save round trips remain **unverified**. Start a new game for acceptance testing. Old version 8 saves have not been certified for version 9; make backups and avoid downgrading. Festival state uses native city buildings rather than Lua variables or a new save database.

The [final implementation audit](docs/AuditReport.md) fixes two conditional runtime defects and adds split-phase economics, native-shaped autosave gates, per-city failure isolation and 128-city tests. Forty Lua 5.1 suite runs and 59 source contracts pass; native acceptance remains pending. Existing valid version 9 marker layouts are retained without migration, while native save continuation is not certified.

Read [implementation and source findings](docs/Implementation.md), [test matrix and native acceptance](docs/Testing.md), [machine-readable validation](docs/Validation.json), [file inventory](docs/Files.md), and [changelog](CHANGELOG.md). No strategic AI is included; `Playable=1`, `AIPlayable=0`.
