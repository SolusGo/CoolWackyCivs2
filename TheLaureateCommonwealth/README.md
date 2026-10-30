# The Laureate Commonwealth

**Laurea — Keeper of the Unfading Crown** leads a human-only civilization for Civilization V: Brave New World and **Community Patch v151 only**. Capital: **Daphne**. Dark emerald and gold; emblem: a golden laurel wreath and white star. No Vox Populi or additional DLL is required.

Victory is the recognition of excellence. Pursue Culture through Wonders, writers and civic institutions; a disciplined army and a prosperous republic also support Domination and Diplomacy.

| Feature | Effect |
| --- | --- |
| **The Evergreen Crown** | Completed global World Wonder: **40 + 10 × Era** Golden Age Points. Newly created Great Person: **20 + 5 × Era**. Military unit first reaching Level 3: **10 + 2 × Era**, once per lifetime. Ancient Era = 0. |
| Golden Ages | **+15% Great Person generation in all cities** and **+15% military combat XP**, additive native policy modifiers. |
| **Laureate Champion** | Swordsman replacement. All installed Swordsman stats, Iron, cost, technology, model, promotions and upgrades retained. **Crowning Blow:** +15% attacking wounded units; heal 15 HP on military kills. Promotion survives upgrades. |
| **Hall of Laurels** | Amphitheater replacement. Retains normal yields, maintenance, prerequisites and Writing slot. Adds **+1 Local Happiness** and **+1 Golden Age Point per functioning Hall per owner turn**. |

Instant awards use the actual `GameSpeeds.GreatPeoplePercent`, the same speed multiplier CP v151 uses for Golden Age thresholds. Fractions round down. Halls produce one point per turn without speed multiplication, as a continuous output.

| Speed | Multiplier | Ancient Wonder / Person / Veteran |
| --- | --- | --- |
| Quick | 67% | 26 / 13 / 6 |
| Standard | 100% | 40 / 20 / 10 |
| Epic | 150% | 60 / 30 / 15 |
| Marathon | 300% | 120 / 60 / 30 |

Complete Wonders, create Great People and train veterans to accelerate the **ordinary** Golden Age meter. There is no additional currency, free Golden Age, duration extension or repeat promotion reward. Captured Wonders, National/Team Wonders and captured or replacement Great People do not earn creation rewards. Natural, faith-purchased, policy and Wonder Great People all qualify.

Great Person rewards settle after native capture/conversion processing, by the next native turn boundary, city training/purchase completion, or expenditure/death if earlier. The reward amount is fixed at creation using its Era. A point award can cross the threshold; **the engine starts the Golden Age at its next normal Golden Age processing step** and preserves overflow. The mod never starts its own timer or adjusts thresholds.

The city Great Person bonus applies to specialist generation, including Writers, Artists and Musicians. General/Admiral combat meters and Prophet Faith thresholds are separate native systems. The military bonus affects combat XP, including defensive combat, and does not boost free starting XP. Crowning Blow's Strength bonus applies to attacks against wounded units, with no defensive, healthy-target or city Strength bonus. Its native kill heal follows the engine's ordinary healing restrictions and HP cap.

Ordinary trained-unit Level 3 promotions are recognized immediately. Genuine new Laureate units can also qualify when created at Level 3; native initialization candidates wait for training completion or a safe turn boundary. A foreign Level 3+ veteran earns no retrospective reward, even after a later promotion or level refund. Acquired units below Level 3 remain eligible to reach it under Laureate ownership. Once awarded, recognition survives upgrades, transfers and captures.

CP exposes no event for a direct scripted `SetLevel` or the insta-heal promotion path, so those cases are recognized at the next owner-turn check, using the Era at that check. The fallback is one army pass per owner turn. Older saves retain existing rewarded markers; untracked units already at Level 3+ are conservatively closed to retrospective rewards, while untracked low-level units can continue progressing. See the [hardening report](docs/Hardening.md) for capture identity handling and compatibility acceptance.

Halls stop contributing when removed, obsolete/inactive, in resistance or razing, or while the owner is in anarchy. A captured city contributes only if its current owner is Laureate and an active Hall survives the ordinary building conversion rules. The owner-turn payout has a saved receipt, so reloading cannot repeat it. Local Happiness follows ordinary population limits.

**Validation status:** installed-schema SQL, actual shipped Lua simulations on four speeds, source contracts, decoded artwork and collection regressions are documented in [Testing](docs/Testing.md). Native gameplay, texture rendering and real save/load acceptance remain pending. Existing Laureate saves migrate their recognition state when loaded. Civilization identifiers, collection UUID, SQL order and mod version 17 are preserved.

Implementation: [mechanics and files](docs/Implementation.md). Original paintings, export details and exact prompts: [art sources](../art-source/TheLaureateCommonwealth/README.md). Short guide: [civilization reference](../docs/civilizations/TheLaureateCommonwealth.md).

Known CP interface gap: native **civilian return**, as distinct from capture/recapture, recreates a Great Prophet without a correlated return hook or copied identity. That path can still count as a new GP birth. [Exact limitation and remaining acceptance](docs/Hardening.md#native-acceptance-still-required).

Regenerate and validate from the repository root:

```powershell
.\.venv\Scripts\python.exe tools/generate_laureate.py
.\.venv\Scripts\python.exe tools/prepare_laureate_art.py
.\.venv\Scripts\python.exe tools/build_mod.py --manifest-only --preserve-art
.\.venv\Scripts\python.exe tools/validate_laureate.py
.\.venv\Scripts\python.exe tools/validate_mod.py
```

`--preserve-art` validates framing and preserves the compiled textures and full mip chains. Omit `--manifest-only` to build the collection ZIP and `.civ5mod`. Install through the root collection's normal Mods workflow; this is not a second mod.
