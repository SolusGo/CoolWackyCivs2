# The Threshold Court

**Queen Elsewhere — Every Door Leads Somewhere.** Human-playable only, for Windows Civilization V: Brave New World and Community Patch v151. Included in Cool Wacky Civs 2 version 17. Single player; no multiplayer/hotseat or AI portal behavior.

**1.14.1 corrective hardening:** [audit, exact changed files and regression results](docs/Hardening.md). Queen Elsewhere now has only her intended trait. Start a new game for a clean baseline: older v17 saves may retain native cached Washington effects, and no automatic aggregate-trait migration is claimed.

The queen's throne room has thirteen doors. Twelve lead throughout her ancient kingdom. The thirteenth has never been opened.

| Component | Rules |
| --- | --- |
| A Door in Every Wall | Once per owner-turn, move an existing eligible land melee military unit from an owned Threshold House city tile to another owned Threshold House city tile. No distance limit or pathfinding. |
| Cost | `50 + 25 × player:GetCurrentEra()`, using the native zero-based Era index. Exactly enough Gold is accepted. Payment follows confirmed arrival. |
| Origin recharge | Successful departure at T makes this origin ready at T+8. Other origins have independent cooldowns. Receiving never starts a cooldown. |
| Exhaustion | Zero remaining movement and no offensive attacks until the next originating owner-turn. Defense remains normal. The unit cannot upgrade while exhausted. |
| Hingeguard | Pikeman replacement; all active CP properties, plus 1 Movement and a permanent +15% friendly-territory combat promotion. Native Pikeman field model/animations. |
| Threshold House | Market replacement; all active CP scalar/companion effects, plus exactly 1 Culture. This building enables the endpoint. No free houses or additional passive yields. |

Military occupancy is deliberately strict: any combat unit on the destination makes it unavailable, even when an unusual stacking rule could allow another. A compatible civilian can coexist. Foreign cities, civilian units, ranged/siege units, aircraft, naval units, embarked units, defensive-only/noncombat units and the origin itself are rejected. There is no adjacent-tile fallback.

## First crossing

1. Build the package from the root using `python tools/build_mod.py`, or install the generated `dist/Cool Wacky Civs 2 (v 17).zip`. Extract its folder into the game's `MODS` directory. The `.modinfo` must be directly inside the installed folder. Use one version of the collection at a time.
2. Enable Community Patch v151 and Cool Wacky Civs 2 in **Mods**, enter modded single-player setup and select **Queen Elsewhere**. Start a new game for the new civilization.
3. Found The First Door and another city. Research the active CP Market prerequisite and construct a Threshold House in each city.
4. Put a Hingeguard or another eligible land melee combat unit with movement remaining on The First Door's city tile. Leave the other city's military slot empty. Reserve at least the displayed Gold cost.
5. Click **Threshold Transfer**, select a destination row, then **Confirm Transfer to [city]**. Cancel is free. The same unit arrives exhausted; Gold is charged and the departure city recharges for eight turns.

Use the network to reinforce a distant continent, then wait until the next owner-turn before fighting. Plan departures from several cities: the empire gets one crossing each turn, but each sending city must recharge. Domination/Science are suggested plans, not forced victory conditions.

## Verification and limits

The implementation includes actual SQL, gameplay Lua and a destination UI, with original leader/unit paintings and valid DDS atlases. [Implementation and file inventory](docs/Implementation.md), [executed checks and native testing checklist](docs/Testing.md), [machine-readable validation](docs/Validation.json), [changelog](CHANGELOG.md).

**Not verified inside Civ V.** Installed-schema SQL, executable modeled Lua behavior and pinned engine source checks do not prove native UI rendering, real save files or resolved combat. Those checks remain necessary. Art uses a static diplomacy painting, ordinary Pikeman model/animations and inherited flag, not a new 3D model or voice recording.

Other mods that directly force `SetXY`, strip promotions or modify saved script data can bypass ordinary engine rules. Normal movement-restoration and Blitz behavior are guarded by a native movement veto and defensive-only promotion. Persistent write failures preserve a recovery receipt and disable new transfers rather than permit repeat free actions. An ambiguous receipt/treasury requires investigation in `Lua.log`; it is never guessed away. Existing saves should be backed up before upgrading the collection; native continuation has not been tested.

Combat types added by a later-loading external mod need CP's `SendCanMoveIntoEvent` opt-in. Types lacking that hook cannot transfer, because their movement exhaustion could not be enforced. Only potential transfer types receive a new opt-in: land combat units with a combat class, zero ranged strength and none of the existing excluded archer/siege/helicopter classes. Existing opt-ins on other types are retained for their own controllers. This remains shared metadata for each unit type; compatibility with arbitrary unscoped third-party vetoes cannot be guaranteed.

If the originating Court is eliminated, surviving marked gifts/conversions recover on the first eligible `PlayerDoTurn` sweep strictly after the crossing turn. That sweep changes no movement/attack counters. Missing/corrupt origin records wait a saved quarantine turn and are cleared only when no Court owner remains alive; ambiguous origins with a living Court stay diagnosed rather than guessed. Cleanup never changes Gold, city cooldowns or financial receipts.
