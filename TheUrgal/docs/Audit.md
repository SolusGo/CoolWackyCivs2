# Urgal hardening audit — 2026-10-26

The existing civilization was corrected in place. The collection UUID, mod version 15, released database ordering, P1/U1 save tags, artwork masters and other civilizations' gameplay are preserved. McPvP files are unchanged.

## Corrections

- **Human-only:** SQL and generator use Playable=1/AIPlayable=0. The runtime excludes nonhuman slots and cleans temporary residue. The legacy AI module remains dormant; no gameplay depends on it.
- **Melee city attacks:** AttackMod=50 with CityAttack=0 gives eligible melee attacks the full +50% against units and cities. No defensive, city bombardment, ranged, siege, naval or air bonus is introduced. Source contracts pin native attack, defense and city/garrison branches; SQL-backed tests execute the actual applied promotion choices with modeled native arithmetic.
- **Speed-aware Aftertaste:** active durations remain 3/5/7/12; Aftertaste is 1/2/3/6. First reactivation offsets are T+4/T+7/T+10/T+18. Custom speeds use floor(5*TrainPercent/100) Strength and nearest-integer 2*TrainPercent/100 Aftertaste, each minimum one, with a 100% fallback for invalid/missing percentages.
- **Embarked activation:** at least one eligible unembarked melee unit is required. Existing embarked members of a mixed snapshot retain the original deadline and activate upon disembarking within it. Counts/feedback distinguish immediate and embarked participants. New units stay excluded; upgrades preserve remaining time and transfers clear participation.
- **Potion UI:** replace the wine glyph with URGAL_PotionUI32.dds, adapted from existing bottle art. The 32x32 transparent legacy RGBA texture has six mip levels, a purple glass silhouette and a non-interactive Image control. Manifest/ModBuddy import it. Separate bounded icon/title/status/button regions and native TruncateString protect the 290x112 panel; the tooltip retains the complete stockpile. Event-driven refresh handles movement, creation, conversion, reload, city/diplomacy/popups and turn transitions without permanent polling. Same-type nested popups are reference-counted and covered by a regression that reproduced the former early-show bug.
- **Reliability:** retire callbacks and queued updates on their owning context, make same-context includes idempotent, block reentrant clicks, preserve duplicate-creation snapshots, reject corrupt/future/duplicate save records, encode large integers consistently and isolate transient promotion/notification faults. Pot Chaser's native 15-HP capped healing remains conditional on active Strength II and its permanent veteran marker.

## Preserved balance

| Mechanic | Value |
| --- | --- |
| Melee attacking bonus against units/cities | +50% |
| Initial/per-new-Era potions | 1 / 1, no gameplay stockpile cap |
| Rusher | 14 Strength, 2 Movement, 80 Production, zero Iron |
| Pot Chaser | 15 HP per enemy-unit kill during Strength II, capped at max |
| Brewing Stand | 75 Production, 1 maintenance, inherited Barracks XP/companion benefits, +10% local eligible melee Production |
| Other effects | No potion regeneration, extra yields, extra movement/attacks, permanent strength or Aftertaste combat penalty |

## Automated validation

- PASS generate_urgal.py and prepare_urgal_art.py; repeated generation produced byte-identical outputs. The manifest builder reapplies the existing atlas gold framing deterministically.
- PASS build_mod.py --manifest-only: one Urgal owner, 706 game files, correct texture imports and unchanged collection UUID/other civ registration.
- PASS validate_urgal.py: 176 replacement companion tables, unrelated rows retained, human-only flags, exact balance/promotion values and localization; 10 shipped-Lua runs over seven suites, four UI speeds, exact all-speed boundaries/reloads, combat/healing arithmetic models, embarked rules, upgrades/transfers, reentrancy and context ownership.
- PASS 49 decoded DDS textures, dedicated purple/transparent full-mip UI icon, XML/VFS bindings and viewport geometry at 1024x768, 1280x720 and 1920x1080. The installed native text helper ran with synthetic font metrics.
- PASS 17 pinned CP v151 source contracts. These are source checks, not native gameplay execution.
- PASS validate_mod.py across the entire collection, including McPvP, Lua 5.1 syntax, manifests/checksums/entry points, gold framing and namespace coexistence. After the final same-type popup fix, focused Lua and static manifest/syntax checks were repeated. Optional raw-cache reactivation checks skip civilizations already present; their clean-schema checks remain active.
- PASS benchmark.py: five existing synthetic Boundless scenarios. The captured run is in RepositoryBenchmark.json, with the current run date separated from the script's legacy fixed metadata. This is not an Urgal/native FPS benchmark.
- Final ZIP/7z build and verify_release.py are performed immediately after this report is written. The completion response records their actual result; all document bytes are included in that verification.

[Focused machine record](Validation.json) · [Benchmark record](RepositoryBenchmark.json) · [Detailed native checklist](Testing.md).

## Remaining findings and limitations

- **Critical:** no unresolved implementation defect identified by this review and automated checks.
- **Major — native verification gap:** native combat/preview behavior, city bombardment, Pot Chaser kills, game save/autosave round trips and rendered UI/icon acceptance remain untested. Installed game files were used read-only; Civ V gameplay was not launched. This remains an implementation preview, not native acceptance.
- **Minor — legacy timing:** already-committed v15 windows retain their saved deadlines, including the former two-turn Aftertaste. No consumed potion or timer resets; subsequent activations use the corrected values.
- **Minor — mod compatibility:** unit types loaded after Urgal's SQL require suitable load ordering for the Brewing Stand's per-unit production rows. This existing limitation is unchanged.
- **Minor — measurement scope:** static geometry and modeled font/native arithmetic do not prove native rendering, combat or performance. Permanent native setter failures still require engine recovery; transient failure/retry isolation is tested.

## Exact changed files

Paths are repository-relative. Generated historical report churn from other civilizations is excluded.

- `CHANGELOG.md`
- `Cool Wacky Civs 2 (v 15).modinfo`
- `CoolWackyCivs2.civ5proj`
- `README.md`
- `TheUrgal/Art/URGAL_PotionUI32.dds`
- `TheUrgal/CHANGELOG.md`
- `TheUrgal/Lua/URGAL_AI.lua`
- `TheUrgal/Lua/URGAL_Core.lua`
- `TheUrgal/README.md`
- `TheUrgal/SQL/00_URGAL_Core.sql`
- `TheUrgal/SQL/02_URGAL_Effects.sql`
- `TheUrgal/SQL/10_URGAL_Text.sql`
- `TheUrgal/UI/URGAL_Potions.lua`
- `TheUrgal/UI/URGAL_Potions.xml`
- `TheUrgal/docs/Audit.md`
- `TheUrgal/docs/Implementation.md`
- `TheUrgal/docs/RepositoryBenchmark.json`
- `TheUrgal/docs/Testing.md`
- `TheUrgal/docs/Validation.json`
- `art-source/TheUrgal/PotionUI32.png`
- `art-source/TheUrgal/Prompts.md`
- `docs/IconConsistency.md`
- `docs/civilizations/TheUrgal.md`
- `tools/build_mod.py`
- `tools/generate_urgal.py`
- `tools/prepare_urgal_art.py`
- `tools/tests/urgal_ai.lua`
- `tools/tests/urgal_combat.lua`
- `tools/tests/urgal_lifecycle.lua`
- `tools/tests/urgal_mock.lua`
- `tools/tests/urgal_potions.lua`
- `tools/tests/urgal_reliability.lua`
- `tools/tests/urgal_speeds.lua`
- `tools/tests/urgal_ui.lua`
- `tools/validate_urgal.py`
- `tools/verify_release.py`
