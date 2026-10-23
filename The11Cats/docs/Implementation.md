# Implementation and CP v151 contracts

## Integration

One entry point, `UI/THE11CATS_Household.xml`, owns `THE11CATS_Household.lua`. It includes `THE11CATS_Manager.lua`, which creates the unique `MapModData.THE11CATS` manager and includes generated `THE11CATS_Config.lua`, `THE11CATS_Safety.lua` and `THE11CATS_Presentation.lua`. All gameplay handlers and UI callbacks run in this same context. Lua events notify that context of changes; no assumption is made that an unrelated gameplay/UI state shares a Lua global. Mutations go through `H.Command` and revalidate player, active turn, interface, identity, ownership, capacity, cooldown and state. Same-context include guards prevent duplicate listener/instance registration; a new Lua context builds fresh handlers.

SQL follows the collection's core/inheritance/effects/art/text convention. All Cats content is appended after the seven released civilizations; earlier row insertion order is preserved. Version 10 keeps the collection UUID. SQL and entry-point XML are not imported into VFS; included Lua, art and the static leader scene are. VFS basenames are globally distinct. The builder updates the ModBuddy project and manifest, DDS finishing and hashes together.

## Authoritative state and invariants

The player ScriptData block `|THE11CATS1:...|` contains two chapter numbers and ten fixed eight-number cat records. No executable deserialization is used. Other mods' ScriptData is retained. A serialized-string comparison suppresses redundant native writes. Unsupported/corrupt blocks are preserved and disable effects instead of overwriting progress.

Austin is a config/leader identity only. Each companion has a canonical ID, numeric state (0 locked, 1 travelling, 2 resident, 3 recovering), city coordinates/founding turn/original owner, unit ID, cooldown end turn and recovery end turn. Private identity promotions independently identify surviving units. Unit ScriptData also records owner/identity while preserving other keys. City names and transient Lua pointers are never saved.

Reconciliation adopts one eligible surviving identified unit when recovering an absent registry, removes duplicates/orphans, detects missing units, verifies residence and capacity, processes chapters, attempts due returns, reconstructs all fifteen independent dummy buildings and both native growth choices, and saves changed records. The saved travelling unit ID wins over duplicates regardless of iteration order; otherwise the lowest valid ID wins. Consistent registry/backup metadata can restore missing or conflicting identity promotions. Impossible timers are clamped once to the full normal interval without resetting legitimate cooldowns. A loaded or foreign dummy is never authoritative. Units/bonuses are exclusive to a single state. Locked/recovering cats cannot supply resident bonuses.

The original 82-number gameplay record is unchanged. The optional `|THE11CATS_N1:...|` sidecar holds only the message preference and four first-bond bits per stable city identity. Existing v1 saves need no migration: active bonds are silently baselined on load. Unsupported presentation versions disable optional feedback while preserving valid gameplay. Unsupported/duplicate gameplay version blocks fail closed without overwriting them. Other mods' ScriptData remains intact.

`H.SaveSafe` verifies the serialized block if a native write reports an exception after mutation. Settle commits verified residence before consuming a unit; a failed write keeps it travelling. Rehome restores the original resident record, cooldown and effects and removes the tentative unit if saving fails. Narrative writes use the same readback principle; failed bond-message writes suppress that message and retain a dirty retry. Native calls are not assumed transactionally atomic.

## Exact bonuses

| Mechanic | Verified native implementation |
| --- | --- |
| Flat Food/Gold/Production/Culture | `Building_YieldChanges` |
| Bonnie's +5% Production | `Building_YieldModifiers`, `YIELD_PRODUCTION=5`; affects general city Production, not just building construction |
| Luna / Sister's Bed GP rate | `Buildings.GreatPeopleRateModifier=10` |
| +1 Happiness | `Buildings.UnmoddedHappiness=1`; one uncapped Happiness originating in that city, avoiding population-capped local Happiness under CP |
| Charlotte +5 Strength | `Buildings.Defense=500`; native building-defense strength is stored in hundredths |
| +5% Growth | Two private `CityEventChoices` with `GrowthMod=5`, `Expires=1`, `EventDuration=0`, no parent event, no audio |

CP v151 exposes `DoCityEventChoice`, `IsCityEventChoiceActive` and `DoCancelCityEventChoice`. A zero-duration choice stays active without automatic expiry; explicit cancellation reverses `GrowthMod`. Each choice is applied once while its saved household condition is valid. Native growth applies this additive percentage to positive surplus **after food consumption**, and respects normal starvation/settler/growth rules. This is neither extra gross Food nor food retained after growth. The ordinary event options need not be enabled, because the native choice is invoked directly. There is no new gameplay dependency or DLL change.

Other mods' growth choices are untouched. These choices have no parent random event and therefore cannot be offered as unrelated player rewards. If required CP bindings are missing, a clear `[The11Cats]` error records the exact growth blocker; the implementation does not silently substitute a Food modifier. The supported target includes those bindings.

Garden scalar/companion rows are copied at database activation. Cat Tree deliberately sets FreshWater=0 and GreatPeopleRateModifier=25, adds its requested +1 Culture, and receives a separate nonstacking Food dummy while residents are present. Costs, technology, upkeep and other active replacement rules are inherited.

## WLTKD

The audited trait schema/source has no suitable WLTKD-duration trait modifier. Native CP `CityBeginsWLTKD(owner,x,y,positiveAddedTurns)` and `CityExtendsWLTKD` run after `ChangeWeLoveTheKingDayCounter` has updated the remaining duration. Both invoke `H.WLTKD`, only for this human civilization. It adds one quarter of the event's duration using **SetWeLoveTheKingDayCounter**. That setter emits no new event or instant WLTKD yield, so there is no extension recursion and no second activation of another mod's instant rewards.

Whole turns are applied immediately; quarter-turn remainders persist in namespaced **plot** ScriptData keyed by owner/founding turn. CP v151 cities have no Lua ScriptData binding. No per-turn counter inference is used. Genuine positive refresh events get their own proportional extension. Loading does not replay events or guess an old celebration's original duration. A third-party script that directly sets the counter without raising a native event cannot be distinguished from arbitrary editing; such silent edits are not retroactively extended.

## Recovery and ownership

`UnitPrekill(player,unit,type,x,y,delay,byPlayer)` records recovery before removal. It is not treated as a cancelable death event. A second delayed-death callback finds the already recovering identity and cannot reset the timer. Intentional settle/duplicate cleanup removals are guarded. A NULL capture class prevents enemy Worker/cat rewards, including ordinary embarked removal. A no-capture promotion adds protection. Missing-unit reconciliation handles removals without a hook.

`CityCaptureComplete(oldOwner,wasCapital,x,y,newOwner,...)` runs after native reconstruction. The new city's Cats effects are cleared immediately; old-owner records are displaced, and both owners reconcile from stable identity. CapitalChanged, founding, construction/sale, city/unit destruction, dirty lifecycle signals and turn starts cover other transitions. Razing triggers displacement; a replacement city at the same coordinates fails the founding-identity check. Foreign effects are also cleared once on load. No map-wide scan is performed.

Recovery uses safe city-center/adjacent owned plots with no civilian/enemy occupant. At most seven nearby arrival spaces exist per isolated city; remaining cats stay pending. Rehoming validates the former home and creates a safe unit before committing the resident change; a failed native spawn leaves residence intact. Recovery preserves rehome cooldowns. Elimination preserves pending records without spawning into hostile ownership.

Protected spawn/removal calls always clear guards. If `InitUnit` creates a unit and then throws, one new House Cat at the requested plot can be adopted; ambiguous new births are cleaned up. Failed cleanup retains pending repair and blocks another recovery birth of that identity (or all births if the orphan cannot be identified). A resident with a lingering same-identity unit cannot rehome. Effect setters verify the city's owner/founding identity after mutation, stop if it changed and clean the currently owned city. A failing city does not prevent another city's effects from being reconciled.

## Performance and visibility

The UI allocates exactly eleven reusable cat rows and four bond cards once. Home cards are pooled by stable city identity and released when that city leaves the player's list. Wrapped text sets card offsets/heights when rendered. It redraws on opening, identity/status changes, relevant selection events, visible cooldown turn changes and screen transitions. One shared **one-shot** ContextPtr callback coalesces dirty/transition storms and detaches before work. There is no timer, idle update, full-map scan, global UI replacement or repeated instance recreation.

Safety wrappers clear `busy`/`syncing` even on failure. Events received during a command/reconciliation retain the affected player and any era-unlock request. Deferred work gets at most two gameplay attempts per external event wave; persistent errors retain pending work until a later lifecycle event, with no idle callback. UI-only refreshes cannot replenish that gameplay retry budget. Foreign cleanup never purges valid human-controlled companions. Notification/renderer faults are isolated from gameplay. A renderer fault closes the panel safely for a later explicit reopen.

Native modal roots are inspected only while rendering or validating an action. City/diplomacy/popup/interface transitions close the panel and defer one refresh after the native root has changed. Command validation shares these gates, so a stale UI callback cannot bypass a cooldown or capacity limit.

## Art and world-model investigation

All fifty existing DDS assets, their atlas indices and the supplied-image crops are retained. Metadata tests bind each name/gender/portrait slot to the canonical roster; Austin remains the white crowned long-haired leader and Sisi the dark tortoiseshell face. No reference photographs were available and none are claimed.

The installed game's exposed `.gr2`/`.fxsxml` file paths were searched for cat, kitten, lion, tiger, panther and leopard; none provided a verified suitable rig. Blender, AssetEditor and NexusBuddy were not available on PATH. This is not an assertion about every packed game archive. A safe cat-shaped model would require a verified mesh, rig, animations and exporter with native testing. Inventing paths or substituting an untested rig would add rendering risk, so the stable Worker world model remains; custom cat portraits/flag are unchanged.

## Source provenance and limits

Audited repository source: [Community Patch v151 pinned commit 44c1e14](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). Checks read the existing local `tools/reference` cache and installed CP schema. `validate_cats.py` verifies critical bindings, event signatures, reversible growth, native yield fields, loading and save invariants. These checks do not execute the actual DLL. Native rendering, saves/autosaves and gameplay must still pass the manual test matrix.
