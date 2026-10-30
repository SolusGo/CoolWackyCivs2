# The Honeycomb Commonwealth

**Speaker Mellia — A Thousand Small Hands.** Human-playable only (`Playable=1`, `AIPlayable=0`) in Civilization V: Brave New World + **Community Patch v151 only**. Integrated into Cool Wacky Civs 2, mod version 17; no Vox Populi, additional DLL or custom-civ dependency. Capital: **First Comb**. Preferred victories: **Science / Culture**. Complexity: **3/5**.

The elected Council of Hives turns agricultural specialization into collective prosperity. Mellia is polite, organized and protective of the workers; disagreements traditionally require elaborate interpretive dances.

| Qualifying worked Plantations | UA Production | UA Culture | Exchange Food | Exchange additional Gold |
| --- | --- | --- | --- | --- |
| 0 | 0 | 0 | +1 | 0 |
| 1 | +1 | 0 | +1 | 0 |
| 2 | +2 | +1 | +1 | +1 |
| 3 | +3 | +1 | +1 | +1 |
| 4+ | +4 | +1 | +1 | +2 |

The Exchange columns apply only while the city has a **Honey Exchange**, which replaces Market and inherits all active Market effects and requirements. Its Food is unconditional; its extra Gold uses the same Plantation count as the UA. Bonuses are flat city yields, additive to normal effects and subject to normal final modifiers. No Plantation tile yields or era/speed/population scaling are added.

A Plantation qualifies only when actually built, unpillaged, owned by this player, within three tiles and assigned to and worked by this particular city. Owning four but working one grants only +1 Production. One count drives all seven binary yield dummies.

**Timing limitation:** CP v151 processes cities, Gold and Culture before `PlayerDoTurn`. No guaranteed synchronous pre-economic owner-start Lua hook was established from the pinned source. Following the collection's existing staging convention, `PlayerDoneTurn` snapshots assignments **when the owner ends their turn**, ready for the next payout. Midturn reassignment does not update existing bonuses. Interturn pillage or reassignment can make the staged snapshot differ from a literal next-turn-start snapshot; these changes are reflected at the following end-turn boundary. This is the specification's permitted closest reliable fallback. See [implementation](docs/Implementation.md).

**Forager:** a genuine Scout-class replacement. Copies the active Scout's Combat, requirements, terrain flags, native model, AI roles, promotions and upgrade relations; adds exactly **+1 Movement** and a unique **+1 Sight** promotion. The unique Sight is lost on upgrade; no additional combat, Worker, harvesting or pillaging ability is added.

The applied snapshot lives in the city's actual buildings. Loading a completed snapshot leaves it unchanged. A namespaced ScriptData receipt prevents duplicate processing; an unfinished write has a temporary binary-target journal so recovery never recounts changed assignments. Captures/transfers clear dummies even between Commonwealth players. Newly acquired/founded cities wait for their next boundary. Observed Exchange removal clears Gold; rebuilding waits for a new snapshot. Pure CP's zero-maintenance Market/Exchange is not normally manually sellable; native Market behavior is preserved.

Start a new modded game and select **Speaker Mellia** after enabling BNW, CP v151 and this collection. Seek Plantation resources, assign citizens deliberately and protect the fields. Exchange growth supports Science while the UA supports policies; no direct Science or Tourism is granted. Collection multiplayer/hotseat support remains disabled, although the controller uses the processed owner and handles multiple Commonwealth owners independently.

Original bee, leader, Forager and marketplace art is included, with 40 real mipmapped DDS exports, a 1024×768 Dawn composition and a static 2D diplomacy scene. The unit uses the ordinary Scout model. [Art sources and exact prompts](../art-source/TheHoneycombCommonwealth/README.md).

[Corrective audit](docs/CorrectiveAudit.md) · [Implementation](docs/Implementation.md) · [Tests](docs/Testing.md) · [Native acceptance checklist](docs/NativeAcceptance.md) · [Changelog](CHANGELOG.md)
