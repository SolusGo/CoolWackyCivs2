# The 11 Cats

**Austin — King of the House.** A peaceful, human-only civilization for Brave New World and Community Patch v151. Austin, adopted in 2013, is permanently the first member of this real family. Ten companions join across six historical chapters. The household's final milestone is **11 / 11 — Everyone Is Home.** It grants no extra yields.

## Play

Install the collection's version 10 ZIP or `.civ5mod` through the instructions in the [root README](../README.md). Enable BNW, Community Patch v151 and this collection, then start a **new modded single-player game** and choose Austin / The 11 Cats. No additional gameplay dependencies are required. Multiplayer, hotseat, Mac and autonomous AI play are unsupported.

Open **The Household** at the right of the normal world view. Select a travelling cat, use **Locate Cat** to select its unit, move it into an owned city, then click **Settle In** in its details. The home must have fewer than three residents. The Cats view lists all eleven identities, with structured details for personality, current home, exact resident effects, family, biography and active bonds. Travellers show their current city or coordinates. Disabled actions explain missing units, recovery, capacity, cooldown or unsafe arrival.

**Homes** shows reusable city cards with capacity, resident portraits and effects, active bonds and Cat Tree Food status. **Bonds** shows all four requirements, active hosts and which cats are missing from a suggested home. **Messages: On/Off** controls optional settling and first-time bond notices; chapter and recovery notices remain available. Each bond is announced at most once per city identity, including after reload. Read Latest Chapter opens an optional story panel; the final title remains **11 / 11 — Everyone Is Home**. The launcher closes during city view, diplomacy and native modal screens.

The panel count includes Austin and all companions who have joined, including travelling and recovering cats. Austin is the leader and never spawns as a civilian. Unplaced companions wait safely if no capital or legal arrival plot exists.

## King of the House

Genuine WLTKD celebrations receive **25% longer duration**, using the positive duration supplied by CP's start/extension events. Resource demand and luxury activation rules are unchanged. The actual remaining counter is extended once; it is never extended by merely taking another turn or loading a save. Fractional quarter-turns are retained on the city's plot and carried into later celebrations. Existing celebrations newly encountered on load are not guessed at or extended retroactively.

| Era | Chapter | Companions |
| --- | --- | --- |
| Ancient | The First Companion | Luna |
| Classical | A Lucky Stray | Bonnie |
| Medieval | The First Litter | Appa, Loki, Kuro |
| Renaissance | The Second Litter | Oscar, Boomie |
| Industrial | A Second Rescue | Charlotte, Sisi |
| Modern | Found Again | Max |

Later-era starts immediately process every eligible chapter. Chapters are saved before notifications and never replay after a normal reload.

## Residents and Family Bonds

Every resident provides **+1 Culture** in its home, plus the following personal effect. Boomie's entry includes her additional Culture separately.

| Cat | Gender | Trait | Additional resident effect |
| --- | --- | --- | --- |
| Luna | Female | One-Person Loyalty | +10% Great Person generation |
| Bonnie | Female | Lucky Arrival | +1 Gold, +5% Production |
| Appa | Male | Arrowback Playfulness | +1 Food, +1 Production |
| Loki | Female | Familiar Comfort | +1 Food, +1 Happiness |
| Kuro | Female | Treat Seeker | +1 Food, +1 Gold |
| Oscar | Male | Purring Appetite | +2 Food |
| Boomie | Female | Little Licker | +1 additional Culture, +1 Happiness |
| Charlotte | Female | On Her Terms | +5 City Strength, +1 Production |
| Sisi | Female | Little Survivor | +1 Happiness, +5% Growth |
| Max | Male | Found Again | +1 Gold, +1 Happiness |

| Bond | Exact requirement | Local effect, once |
| --- | --- | --- |
| The First Pair | Luna in the current capital | +1 Culture |
| Bonnie's Family | Bonnie with Appa, Loki, Kuro, Oscar or Boomie | +1 Food, +1 Gold |
| Sister's Bed | Appa, Loki and Oscar together | +1 Happiness, +10% Great Person generation |
| Mother and Daughter | Charlotte and Sisi together | +1 Happiness, +5% Growth |

Bonnie with two kittens still receives her bond once. Sisi and Mother and Daughter stack independently for +10 percentage points of local Growth. Each city has **three resident slots**, requiring at least four homes for all ten companions.

## House Cat and Cat Tree

House Cats are maintenance-free civilian units with 2 Movement and no combat, work, founding, Great Work or upgrade abilities. They cannot be trained, purchased, gifted or disbanded. They have custom source-image portraits and a paw-and-crown flag; the standard Worker map model is the visual stand-in. Embarkation and ocean travel are provided by their private promotion. An enemy can remove a travelling unit but cannot receive a cat or Worker as a capture reward.

The **Cat Tree** replaces Garden. It retains the active Garden's technology, cost, upkeep and other replacement rules, guarantees the specified +25% Great Person generation, adds +1 Culture, and removes Fresh Water. With any residents it provides **+1 Food once**, whether one, two or three cats live there. No free Cat Trees are granted.

## Rehoming and recovery

Select a resident and click **Rehome Cat**. Its travelling unit appears in or adjacent to its former home; its resident effects and invalidated bonds end immediately. A **10-turn Standard cooldown** prevents settling again. If no safe adjacent arrival is possible, rehoming is rejected and the cat remains a resident with its effects intact.

City loss, razing, destroyed/missing units and capture displace cats into **Recovering** for **3 Standard turns**. Their identities and existing rehoming cooldowns persist. Recovery returns a travelling unit at a currently owned safe city or an adjacent owned land tile. Occupied, hostile, impassable, razing and resistant locations are avoided. Pending cats retry on lifecycle events/turns and remain safe while no suitable home exists. Elimination preserves identities but cannot return cats until the human owns a valid city again. No loss/recovery rewards are granted.

| Speed | Rehoming | Recovery |
| --- | ---: | ---: |
| Quick | 7 | 2 |
| Standard | 10 | 3 |
| Epic | 15 | 5 |
| Marathon | 30 | 9 |

## Balance and compatibility

Four to six peaceful cities, Culture and Diplomacy are the intended plan; Science is secondary. Slow chapter progression, city capacity, local combinations and relocation delays constrain the benefits. No direct Science or offensive combat bonus was added. Charlotte and Sisi celebrate security and affection; their suffering is never rewarded.

`AIPlayable=0` follows the collection convention. Forced AI/scenario selection receives no household progression, WLTKD extension or resident effects; orphan cat units are removed and Cat Tree construction is vetoed. Other civilization selection flags and gameplay remain unchanged. The normal interface is extended through one private InGameUIAddin; no global interface replacement is installed. Existing saves from this civilization's version 10 implementation retain the same gameplay record, UUID, database IDs, assignments, cooldowns and chapters in simulations. Native continuation still needs acceptance testing. Older collection saves without this civilization remain unverified; start a new game to select it.

The supplied emblem is retained in [art-source](../art-source/The11Cats/README.md). No individual reference photographs were available; portraits are source-image crops chosen by the stated appearances, not claims of exact photographic matches. Sisi uses the dark tortoiseshell face at the lower left; the decorative tail is excluded from the eleven portraits.

## Validation and development

See the [ranked fixes and polish report](docs/PolishReport.md), [implementation and native API notes](docs/Implementation.md), [balance](docs/Balance.md) and [test matrix/results](docs/Testing.md). In-game acceptance remains pending; automated passing checks do not prove native gameplay or rendering.

```powershell
python tools/generate_cats.py
python tools/prepare_cats_art.py
python tools/build_mod.py --manifest-only
python tools/validate_cats.py
python tools/validate_mod.py
python tools/build_mod.py
python tools/verify_release.py
```

Use the repository's existing development requirements. DDS compilation uses Pillow and DirectXTex `texconv`, already supported by the collection builder. Set `MapModData.THE11CATS.DEBUG=true` in the InGameUIAddin's Lua context for diagnostic `[The11Cats]` messages; normal operation is quiet except repairs/errors. Authoritative state is namespaced player ScriptData inside the savegame, never global user settings.
