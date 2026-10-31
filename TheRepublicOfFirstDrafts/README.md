# The Republic of First Drafts

**Leader:** Editor-in-Chief Marginalia · **Capital:** First Edition · **Complexity:** Intermediate (3/5) · **Preferred victories:** Science / Culture.

A republic of writers, architects, engineers, scholars and publishers rewards experimentation and continuous revision. Marginalia, in her annotated academic robes and crooked spectacles, presides over the Editorial Department. Its philosophy: **Nothing Is Ever Final.**

## Exact mechanics

| System | Effect |
| --- | --- |
| Nothing Is Ever Final | Each qualifying Building Class possessed by the empire earns **12 Culture and 20 Gold once per game**, on Standard speed. |
| Ink Mortar | Replaces the active CP Catapult; **+1 Movement**, **+1 Sight**, all other baseline properties and companion records preserved. Extra Sight is lost on upgrade. Uses the normal Catapult model. |
| Revision Workshop | Replaces the active CP Workshop; retains all its benefits and adds **+1 Culture**. Adds **min(3, floor(current qualifying city classes / 4)) Science**. |

The UA evaluates at `GameEvents.PlayerDoTurn`, after the native player turn's city processing. Rewards are **not paid by the construction notification**. A building must still be present at the evaluation. Multiple cities, extra copies and unique replacements never reward the same class twice. Production, Gold/Faith purchases, free/gifted buildings and captures can all establish possession.

The active `GameSpeeds.ConstructPercent` controls scaling: `floor(base * percent / 100 + 0.5)` for each class separately, then sum. Standard gives 12/20; Marathon with the fixture's 300% gives 36/60 per class. No named-speed multipliers are hardcoded.

Both mechanics share one lookup built from active `Buildings` and `BuildingClasses`. A building must belong to an unlimited non-wonder class, have a Production route (`Cost >= 0`) or positive Faith cost, and be visible ordinary content. Palace/capital buildings, all three kinds of limited wonder classes, `IsDummy`, hidden Civilopedia entries, negative `GreatWorkCount` control buildings, league projects and otherwise unconstructible specials are excluded. Faith-only buildings such as Pagodas qualify. Eligibility describes a building definition's possible construction/purchase route; it does not require that a particular city currently satisfies every prerequisite.

The Revision Workshop counts as `BUILDINGCLASS_WORKSHOP`, including toward its own Science. At 0–3/4–7/8–11/12+ current city classes its additional Science is 0/1/2/3. Its additional Culture is a normal static building yield. Its Science uses three hidden, nonconstructible, nonpurchasable, noncapturable +1 Science buildings set to exact binary targets. They never qualify for UA rewards or the UB count.

## Play

Build varied affordable institutions to gain early Culture and Gold, then develop research cities around Workshop thresholds. Repeated buildings still improve cities and count toward their local Workshop Science, even after the national reward for that class is exhausted. The Ink Mortar's movement and reconnaissance help position siege armies; normal setup, resources, attack restrictions and city damage apply.

## Requirements and registration

Requires Windows Civilization V **Brave New World + Community Patch v151**. Vox Populi is not required. This civilization has `Playable=1`, `AIPlayable=0`; its Lua effects only benefit living human Republic players. Multiplayer/hotseat support is unchanged from the collection and is not claimed.

This is part of **Cool Wacky Civs 2 (v 19)**, using its existing UUID and ModBuddy project. Install the collection normally through the Mods menu; do not install this directory as a separate mod. `tools/build_mod.py` appends this civilization after all released SQL to preserve their IDs. SQL loads in numeric order. One `InGameUIAddin` loads `Lua/RFD_FirstDrafts.xml`; the Lua script, diplomacy scene and DDS textures use VFS imports. SQL and the entry XML do not. There is no gameplay panel or shared CityView override.

## Saves and initialization

The permanent class ledger is a carefully delimited `[RFD1|...]` block in **player ScriptData**, which the CP DLL serializes into the save. It stores sorted **Building Class type names**, the last evaluated turn, and any unfinished payout journal. Other ScriptData bytes remain intact. Ordinary Lua globals are only controller ownership and cached definitions.

Classes remain exhausted after sale, removal, capture, razing, destruction, rebuilding and recapture. No city identity is used for permanent recognition. On a fresh context with no ledger, `Game.GetGameTurn() > Game.GetStartTurn()` identifies a progressed game: currently owned classes are seeded without rewards. At the actual start turn, including advanced-era starts, the ledger starts empty and first possessions can reward normally. A save still on its initial game turn is treated as a new game; the engine exposes no independent mod-install timestamp for distinguishing a late install on that same turn. Existing ledger blocks always take precedence and are never reseeded.

Each payout writes the updated class set and frozen before/after yield balances before changing yields. Culture and Gold are verified and acknowledged in separate stages. Retrying an interrupted write recognizes an already reached target and does not increment again. A corrupt ledger or ambiguous interrupted balance fails closed with `RFD:` diagnostics, retaining the saved journal instead of guessing or overwriting unrelated earnings. This exceptional state requires investigation of Lua.log/save data; ordinary save/load and repeated callbacks do not enter it.

The permanent UA history and the dynamic UB **never share a progression counter**. Building completion/purchase, sale, city dirty and capture notifications reconcile local Science. The owner-turn scan is authoritative for unannounced free building grants/removals. Capture handlers reacquire the current city from its plot and clear markers for foreign/AI owners. If an arbitrary external script removes a building without publishing an event, Science corrects at the next owner-turn boundary. Native yields already settled before that boundary cannot be retroactively changed. Captured dummies also have `NeverCapture=1` and `ConquestProb=0`.

## Art and verification

Includes six original generated paintings, 40 compiled DXT5 DDS textures with mip chains, circular burgundy/cream/gold atlases, monochrome parchment/quill civilization and unit flags, a 1024×768 Dawn chamber and map, and a static diplomacy portrait. There is no custom 3D leader animation, voice acting or custom siege model. [Art sources and exact prompts](../art-source/TheRepublicOfFirstDrafts/README.md).

Run from the repository root after the [validation prerequisites](../docs/ValidationSetup.md):

```powershell
.\.venv\Scripts\python.exe tools/build_mod.py --manifest-only --preserve-art
.\.venv\Scripts\python.exe tools/validate_rfd.py
.\.venv\Scripts\python.exe tools/validate_mod.py
```

[Implementation and source evidence](docs/Implementation.md) · [Testing and native acceptance checklist](docs/Testing.md) · [Executed results](docs/Validation.json) · [Changed files](docs/Files.md).

Tests execute real shipped SQL in an in-memory BNW snapshot with the installed v151 schema, and the actual Lua controller under Lua 5.1 with simulated native APIs. **Native gameplay, DDS rendering and engine save/load acceptance still require the checks in Testing.md.**
