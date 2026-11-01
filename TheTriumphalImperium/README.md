# The Triumphal Imperium

**Imperator Aurelion — One Victory Demands Another.**

A human-only Civilization V: Brave New World civilization for Windows Community
Patch **v151**, without Vox Populi or a custom DLL. Capital: Corona Invicta.
Preferred victory: Domination. Imperial crimson and antique gold; Roman architecture.

## Playing

Choose either the standalone release or Cool Wacky Civs 2 v23. Enable it through
the Mods menu with BNW and Community Patch v151, then start a new modded single-player
game as Imperator Aurelion. The two releases contain the same civilization and
must not be enabled together. The standalone manifest blocks the collection v23+.
No original collection or Laureate Commonwealth is required by the standalone.

The source module is isolated in this folder. Generated standalone installers are
`../dist/The Triumphal Imperium (v 1).zip` and `.civ5mod`; the ZIP has a normal
installable mod folder. The collection release is `../dist/Cool Wacky Civs 2 (v 23).zip`.
Extract the chosen ZIP into the game's user `MODS` directory. No vanilla files change.

## Rules

**Victory Begets Victory:** Victory Momentum starts at 0, cannot exceed 6, and is
shared across your empire. Defeating another major civilization's military unit
in normal combat grants +1. First military conquest of a major city site grants
+2. Defensive victories, ranged combat, naval and air combat, interception, and
city bombardment kills count. Barbarians, City-States, civilians, diplomatic city
transfers, unit deletion and friendly/neutral deaths do not count. Nuclear combat
counts only when the engine reports an attributed enemy military combat kill.

Each city site gives conquest Momentum once per Imperium player for the entire
game, even if razed and refounded. This is the recapture-farming safeguard.
Subsequent genuine recaptures still reset inactivity and renew Hall eligibility.
Each full cycle between your turn starts without a qualifying victory loses 1
Momentum. Victories during opponents' turns count; a victory at the cap also
prevents decay. The first turn never decays. This turn-cycle rule is identical on
Quick, Standard, Epic and Marathon.

| Momentum | Military strength | Military unit Production | Threshold effects |
| --- | --- | --- | --- |
| 0 | 0% | 0% | Inactive |
| 1 | +2% | +4% | Inactive |
| 2 | +4% | +8% | Inactive |
| 3 | +6% | +12% | Inactive |
| 4 | +8% | +16% | Active |
| 5 | +10% | +20% | Active |
| 6 | +12% | +24% | Active |

**The Unbroken:** Swordsman replacement preserving the active base unit's cost,
strength, Iron, Movement, technology, other promotions and upgrade chain.
Unbroken Advance adds +10% attacking strength and survives upgrades. At Momentum
4+, only original Unbroken gain +1 maximum Movement. Activation does not refill
their current moves. Deactivation removes only this promotion and clamps any
remaining movement above the new allowance. Upgrades retain Advance and lose March.

**Hall of Triumphs:** Barracks replacement preserving the active building's cost,
maintenance, prerequisite, experience and companions. Adds +1 Culture. At Momentum
4+, each Hall city gains +10% military unit Production, additive with the empire
bonus: +34 percentage points at Momentum 6. Neither bonus affects civilian units,
buildings, wonders or projects. A military conquest from another major qualifies
that city for the actual Hall after Bronze Working. Earlier conquests wait in the
save. Lost, liberated or razed cities cannot carry pending eligibility into a
different owner or newly founded city. Puppets and annexed cities both qualify.

## Interface and art

A compact six-laurel panel at the upper right shows `VICTORY MOMENTUM: X / 6`
and the current strength/production percentages. Hover it for both threshold
statuses and the full rules. It appears only for the active human Imperium player,
hides in city/leader screens and reconstructs on load. No TopPanel replacement,
frame dispatcher, or UI framework is used. Ordinary gain notifications are limited
to one per global turn, with separate maximum and decay messages.

Six original built-in imagegen paintings supply civilization, leader, unit,
building, Dawn of Man and selection-map art. Forty legacy full-mip DDS textures
include standard 16/24/32/45/48/64/80/128/256 atlases, a monochrome flag, 1600×900
static leader, 1024×768 dawn and 512×512 map. The unit uses the existing Swordsman
animated model. No new animated leader, spoken dialogue or soundtrack is supplied.
Sources and the generation prompt set are retained in `../art-source/TheTriumphalImperium/`.

## Build and verification

From the repository root, using the existing `.venv`:

```powershell
.\.venv\Scripts\python.exe tools\generate_triumphal.py
.\.venv\Scripts\python.exe tools\triumphal_strategy.py
.\.venv\Scripts\python.exe tools\prepare_triumphal_art.py
.\.venv\Scripts\python.exe tools\validate_triumphal.py
.\.venv\Scripts\python.exe tools\build_mod.py --preserve-art
.\.venv\Scripts\python.exe tools\build_triumphal.py
```

The database generator uses a read-only installed BNW snapshot and CP v151 schema;
test libraries are development dependencies only. The standalone has no Python
or external runtime dependency. Existing civilization generators and art are not
run by the Imperium tooling.

See [implementation and source contracts](docs/Implementation.md),
[testing and native acceptance](docs/Testing.md), [machine results](docs/Validation.json),
the [collection regression](docs/Regression.md), and [file inventory](docs/Files.md). Static/database and Lua-mock testing have been
performed; native Civ V gameplay, save-file loading and rendering have **not**.

The native `PlayerDoTurn` boundary follows economic settlement for the preceding
cycle and precedes unit-turn processing. Decay changes the displayed/new-cycle
bonuses there; it does not retroactively recalculate already-settled production.

The original Laureate Commonwealth remains byte-for-byte unchanged.
