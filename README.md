# Cool Wacky Civs 2

Twenty civilizations for Civilization V: Brave New World and **Community Patch v151**. This is an independent collection; the original Cool Wacky Civs mod is not required.

**Current source:** mod version 20 · **1.20.0 The Lantern Fleet**. [Changelog](CHANGELOG.md) · [GitHub](https://github.com/SolusGo/CoolWackyCivs2)

[The Lantern Fleet](TheLanternFleet/README.md), led by High Keeper Maren, turns owned naval combat ships inside coastal city centers into fixed turn-start Science/Culture snapshots. Its Beacon Cutter adds Sight and friendly-territory Strength; Signal Lighthouse adds permanent Culture and conditional Gold. Includes original navy/gold art and human-only selection. **Native timing acceptance is pending:** the earlier candidate UI notification has source publication evidence, but executable dispatch and same-turn payouts remain unverified after application permission blocked launch. [Evidence and tests](TheLanternFleet/docs/Testing.md).

[The Republic of First Drafts](TheRepublicOfFirstDrafts/README.md), led by Editor-in-Chief Marginalia, rewards each new qualifying Building Class once per game with speed-scaled Culture and Gold. Its Catapult-derived Ink Mortar gains +1 Movement/+1 Sight; its Revision Workshop adds Culture and capped Science from current city building diversity. Includes permanent save-scoped recognition, dynamic city reconciliation, original burgundy/parchment art and human-only selection. [Implementation and testing](TheRepublicOfFirstDrafts/docs/Implementation.md).

The [T1 corrective audit](T1ZOFGK/docs/Hardening.md) hardens delayed/returned gifts, roster authorization and genuine-upgrade accounting without changing balance or working artwork. [Fresh checkout validation setup](docs/ValidationSetup.md) documents the external BNW/CP snapshot, source fetch and read-only tests. Native acceptance remains pending.

[T1 - The ZOFGK Dynasty](T1ZOFGK/README.md), led by Faker, develops five Ancient Era Recruits into permanent Zeus/Oner/Faker/Gumayusi/Keria veterans. Genuine upgrades add +4% Strength each; compact formations activate Five as One. Includes native conditional role bonuses, localized support/pressure, Headquarters recruitment, a roster panel, the official red T1 emblem and original painted art. Human-only. [Validation and native acceptance](T1ZOFGK/docs/Testing.md).

The Civilopedia fix fills missing text keys on two Laureate recognition markers. Their incomplete metadata stopped the shared index before civilizations and leaders, leaving the navigation blank and Jin search unavailable. The regression replays all sixteen installed BNW indexing functions. Restart Civ V and reload the modded save after updating.

The [full Jin visual refresh](JinDynasty/docs/Graphics.md) replaces all 63 existing textures and adds 19: new leader/Dawn art, painted unit/building/upgrade atlases, map, flags, HUD symbols and an illustrated council. It retains the turn-recovery fix and gameplay/save rules.

The Laureate [recognition hardening](TheLaureateCommonwealth/docs/Hardening.md) prevents acquired foreign veterans from earning retrospective laurels and preserves legitimate low-level progression. Exact capture identities also protect genuine Great Person births on the same tile. Existing recognition markers remain valid; balance, SQL and artwork are unchanged.

The UI hotfix restores Jin's launcher after AI turns and replaces Threshold Court's undefined panel style. Game rules and save data are unchanged; restart Civ V after updating, then reload the existing save.

[The Laureate Commonwealth](TheLaureateCommonwealth/README.md), led by Laurea, Keeper of the Unfading Crown, earns Golden Age Points from completed World Wonders, newly created Great People and Level 3 military veterans. Golden Ages add 15% city Great Person generation and 15% combat XP. Includes the Swordsman-derived Laureate Champion, Hall of Laurels, original emerald/gold art and human-only selection. [Implementation and native acceptance](TheLaureateCommonwealth/docs/Testing.md).

[The Honeycomb Commonwealth](TheHoneycombCommonwealth/README.md), led by Speaker Mellia, develops worked Plantations into capped city Production/Culture and Honey Exchange Gold. Includes the active Scout-derived Forager, original bee art and human-only selection. CP v151 requires owner-end staging for the next payout; the documented interturn difference and native acceptance checklist are in the guide. No release package is generated for this addition.

Its [corrective audit](TheHoneycombCommonwealth/docs/CorrectiveAudit.md) adds frozen-target recovery for interrupted writes, reliable removal/reentrancy handling and independent CP source checks without changing balance or art. [Native acceptance](TheHoneycombCommonwealth/docs/NativeAcceptance.md) remains pending because Windows control could not initialize.

The Boundless City's [remote-workforce planner](TheBoundlessCity/docs/RemotePlanner.md) now compares jobs with displaced labour, offers a saved Food minimum, retains stable assignments and avoids rebuilding unchanged reservations. Large territories use cached yields and bounded candidate selection. Existing native capacity limits remain in force.

[The Threshold Court](TheThresholdCourt/README.md), led by Queen Elsewhere, connects owned Threshold House cities through real, unlimited-distance relocation of existing land melee units. One paid crossing per owner-turn, eight-turn origin cooldowns, save-scoped state, an explicit destination/confirmation panel and exhausted arrivals. Human-only; native gameplay/render/save acceptance remains pending.

The Court's [corrective audit](TheThresholdCourt/docs/Hardening.md) removes unintended Washington trait inheritance, handles eliminated origins, narrows movement-hook dispatch and protects new turns from delayed recovery receipts. Start a new Court game for a clean trait baseline; existing saves can retain native cached trait effects.

[The Jin Dynasty](JinDynasty/README.md) adds Wanyan Aguda's linked Mounted Villager, Grassland/Horse, cavalry recruitment, Emissary/Tributary, Bribe, six-Landmark and Meng'an Mouke systems. The [hardening pass](JinDynasty/docs/Hardening.md) adds bounded autonomous defenders, Food-assisted Reindeer Trader training, recoverable purchases and measured Lua optimizations. Includes a six-tab panel, thirteen named upgrades, original art and focused four-speed Lua validation. Human-only; native game/render/save acceptance remains pending.

[The Urgal](TheUrgal/README.md) brings MCPVP Hardcore Games timing attacks: stockpile one Strength Potion per Era, empower the current melee army for a short offensive window, then wait through Aftertaste. Includes the iron-free Urgal Rusher, Brewing Stand, potion inventory with a purple bottle icon, speed-scaled Aftertaste and human-only play. Eligible melee attacks gain Strength II against units and cities.

The Boundless City now has an extensive [lore library](TheBoundlessCity/Lore/README.md) explaining how one municipal charter governs distant wards: shared law and citizenship, delegated government, distributed food stores, public works, finance and everyday life. The same books supply its expanded in-game Civilopedia chapters and histories.

The Boundless Workforce has a new [custom graphical skin](TheBoundlessCity/docs/UIVisuals.md), with an engraved city header, brass/teal textures, matching controls and clearer district rows. [Layout preview and original art](art-source/TheBoundlessCity/WorkforceUI/README.md).

The [interface refresh](docs/UIRefresh.md) gives all nine custom panels/HUDs their own themed skin and adds recovery from missed popup, diplomacy and turn-transition events.

## Civilization roster

| Civilization | Leader | Playstyle | Guide |
| --- | --- | --- | --- |
| [The Boundless City](docs/civilizations/TheBoundlessCity.md) | The First Architect | Develop one sprawling city and manage its expanding workforce. | [Details](TheBoundlessCity/README.md) |
| [The Republic of Pigeons](docs/civilizations/TheRepublicOfPigeons.md) | Postmaster General Coo | Use land trade routes to generate stacking Science and Culture. | [Details](TheRepublicOfPigeons/README.md) |
| [The Indigo Champion](docs/civilizations/TrainerRed.md) | Trainer Red | Train military partners and assemble a six-slot Champion Team. | [Details](TrainerRed/README.md) |
| [McPvP — The Endless Lobby](docs/civilizations/McPvP.md) | The Old Guard | Choose kits, compete in three match modes and build Server Legacy. | [Details](McPvP/README.md) |
| [The Children of the Kingdom](docs/civilizations/TheChildrenOfTheKingdom.md) | The Faithful | Complete seven prayer petitions to earn permanent Grace bonuses. | [Details](TheChildrenOfTheKingdom/README.md) |
| [The Twelfth Hour](docs/civilizations/TheTwelfthHour.md) | The Keeper of Seconds | Synchronize cities for Production and Science boosts every sixth turn. | [Details](TheTwelfthHour/README.md) |
| [The Wandering Circus](docs/civilizations/TheWanderingCircus.md) | Ringmaster Aurelio | Send Carnival Crews to cities to prepare local Grand Festivals. | [Details](TheWanderingCircus/README.md) |
| [The 11 Cats](docs/civilizations/The11Cats.md) | Austin — King of the House | Welcome ten companions, settle warm homes and build local Family Bonds. | [Details](The11Cats/README.md) |
| [The Kingdom of Saba](docs/civilizations/KingdomOfSaba.md) | Karib'il Watar | Settle River and Desert cities, develop Cisterns and defend the wadis. | [Details](KingdomOfSaba/README.md) |
| [The Substitute Classroom](docs/civilizations/TheSubstituteClassroom.md) | Mr. Garvey | Take Roll Call, manage Insubordination and turn Detention into a military surge. | [Details](TheSubstituteClassroom/README.md) |
| [The Conical Union](docs/civilizations/TheConicalUnion.md) | High Marshal Bollard | Connect productive settlements with Road Crews and defensive Detour Offices. | [Details](TheConicalUnion/README.md) |
| [The Kingdom of the Unrung Bell](docs/civilizations/KingdomOfTheUnrungBell.md) | Keeper Sable | Build Quietude during peace, then consume it for five full windows of the Great Toll. | [Details](KingdomOfTheUnrungBell/README.md) |
| [The Urgal](docs/civilizations/TheUrgal.md) | Urgal | Stockpile rare Strength Potions and time overwhelming melee attacks. | [Details](TheUrgal/README.md) |
| [The Jin Dynasty](docs/civilizations/JinDynasty.md) | Wanyan Aguda | Manage Horse stockpiles, recruit cavalry, establish Tributaries and choose branching Landmarks. | [Details](JinDynasty/README.md) |
| [The Threshold Court](docs/civilizations/TheThresholdCourt.md) | Queen Elsewhere | Build distant doorways and pay to redeploy exhausted melee armies across the world. | [Details](TheThresholdCourt/README.md) |
| [The Honeycomb Commonwealth](docs/civilizations/TheHoneycombCommonwealth.md) | Speaker Mellia | Work Plantations for capped city Production/Culture and Honey Exchange Gold. | [Details](TheHoneycombCommonwealth/README.md) |
| [The Laureate Commonwealth](docs/civilizations/TheLaureateCommonwealth.md) | Laurea | Honor Wonders, Great People and military veterans to enter stronger Golden Ages. | [Details](TheLaureateCommonwealth/README.md) |
| [T1 - The ZOFGK Dynasty](docs/civilizations/T1ZOFGK.md) | Faker | Preserve five legendary recruits, develop veterans through upgrades and coordinate elite formations. | [Details](T1ZOFGK/README.md) |
| [The Republic of First Drafts](docs/civilizations/TheRepublicOfFirstDrafts.md) | Editor-in-Chief Marginalia | Diversify institutions for permanent Culture/Gold rewards and current-city Workshop Science. | [Details](TheRepublicOfFirstDrafts/README.md) |
| [The Lantern Fleet](docs/civilizations/TheLanternFleet.md) | High Keeper Maren | Guard coastal city centers for turn-start Science/Culture and Signal Lighthouse Gold. | [Details](TheLanternFleet/README.md) |

All twenty are human-playable. The Children of the Kingdom, The Twelfth Hour, The Wandering Circus, The 11 Cats, The Kingdom of Saba, The Substitute Classroom, The Conical Union, The Kingdom of the Unrung Bell, The Urgal, The Jin Dynasty, The Threshold Court, The Honeycomb Commonwealth, The Laureate Commonwealth, T1, The Republic of First Drafts and The Lantern Fleet are human-only. Each guide lists unique units/buildings, mechanics, engine limits and testing records.

**Status:** implementation preview. Native gameplay, rendering and save testing remain incomplete; see each civilization's testing record for the outstanding checks.

## Playing the mod

1. Install Civilization V with Brave New World and the Windows **Community Patch v151**.
2. Build the release below, or use the provided archive. Extract `dist/Cool Wacky Civs 2 (v 20).zip` into `Documents/My Games/Sid Meier's Civilization 5/MODS`. The extracted folder must contain `Cool Wacky Civs 2 (v 20).modinfo` directly. Remove the older installation before installing this version; all versions share one collection UUID.
3. Enable **Community Patch** and **Cool Wacky Civs 2** through the game's **Mods** menu, then enter modded single-player setup and choose a leader.
4. Follow the civilization's guide above for its opening moves and custom panel.

Back up older saves before upgrading; native save continuation has not been fully tested. Start a new game to play a newly added civilization. Multiplayer, hotseat and Mac are not supported.

## Building and checking

The pure-file builder does not require ModBuddy. Use Python 3.11 or later:

```powershell
python -m pip install -r requirements-dev.txt
python tools/prepare_art.py
python tools/build_mod.py --manifest-only --preserve-art
python tools/validate_mod.py
python tools/benchmark.py
python tools/build_mod.py --preserve-art
python tools/verify_release.py
```

`validate_mod.py` reads the installed game's backup debug database and Community Patch schema **read-only**, then runs SQL in an in-memory clone. See [Testing.md](TheBoundlessCity/docs/Testing.md) for paths, prerequisites, exact live test steps and the distinction between simulation and game verification. `generate_database.py` is for regenerating schema-derived SQL during development; it is unnecessary for installing the committed files.

Civilization-specific validation, source audits and regeneration commands are documented in each guide above. The [documentation convention](docs/AddingCivilizations.md) covers adding future civilizations, and the [icon build notes](docs/IconConsistency.md) explain atlas dimensions and gold framing.

Build products are a ZIP install folder and a genuine LZMA/7z `.civ5mod`, written to `dist/`. They are ignored by Git. ModBuddy users can open `CoolWackyCivs2.civ5sln`; `tools/build_mod.py` keeps its project and modinfo file lists, SQL ordering and VFS flags in sync.

`--preserve-art` validates the existing framed atlases and retains their compiled bytes/mipmaps. Omit it when intentionally recompiling all icon families from their retained masters.

## Repository layout

| Path | Contents |
| --- | --- |
| Each civilization's folder | Gameplay SQL/Lua, UI, DDS assets, guide, changelog and testing documentation |
| `docs/civilizations` | Short reference page for each civilization |
| `art-source` | Original artwork, icon previews, atlas masters and generation notes |
| `tools` | SQL/art/project/package builders and validation scripts |
| `dist` | Generated install archives; ignored by Git |
