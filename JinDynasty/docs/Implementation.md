# Jin implementation

## Files and authority

`Balance.json` is compiled by `tools/generate_jin.py` into five numerically ordered SQL files and `Lua/JIN_Config.lua`. SQL loads after all version-15 civilizations, preserving their database insertion order. `UI/JIN_Dynasty.xml` is the only simulation-owning addin; its matching Lua includes `JIN_Core`, `JIN_State` and `JIN_Military`. The other Lua modules are VFS imports, never independent simulation entry points.

All new gameplay identities use `JIN`: civilization/leader/unit/building/promotion/improvement/policy IDs, art filenames, atlases, player/unit script-data tags and the `MapModData.JIN` namespace. Existing built-in 3D art IDs are references, not newly defined art. The collection UUID remains `f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392`; collection version is 16 / 1.13.0 preview.

## Save model

The authoritative state is hex-encoded, bounded, length-prefixed data inside the native serialized Player ScriptData `JIN_P1` tag. It contains progression, committed choices, city identities, pending candidate indices, individual Horse inventories/progress, Tributary identities, upgrades, Karma/blessing deadlines, Garden position/deadline, defender parents/births/expiry, fort indices, defensive cooldowns, Groves, rebels and Emissary cooldowns. Unit ScriptData `JIN_D1` records defender owner/home/expiry for native movement validation and transfer cleanup. Foreign ScriptData is preserved.

The decoder never executes code. Duplicate, malformed, newer or unknown Jin records fail closed. City identity combines plot index and founding turn; unit identity combines native unit ID and creation turn. MapModData stores functions, active context and short-lived reentry locks, never the authoritative saved economy. Replacing the UI context detaches its predecessor's event listeners. Reloading an older save restores that save's native script data, including within one match at the same turn number. External Modding SaveData is unused.

Landmark choices commit when selected; native city construction completes their effects. Zero-maintenance Landmarks are unsellable under the audited native `IsBuildingSellable` rule. Completion records and one-time awards cannot be reset by selling, capturing a capital or moving a capital. Lost Landmark buildings stop their ongoing functions; completed progression and consumed opportunities remain committed. Pending Grassland offers can relocate to the surviving capital if their parent is lost.

## Economic order

Pinned CP v151 `CvPlayer::doTurnPostDiplomacy` processes city turns before `PlayerDoTurn`. Food and discounts therefore use persistent native building counts and native policies staged on actions, completion, city founding/capture, war and owner-turn/end-turn reconciliation. The +2 Food per active Tributary is a normal capital building yield; no guessed post-harvest Food or trade Gold is paid each turn. Rates are per economic turn and retain native city modifiers, resistance and growth behavior. A reward first established during a turn applies to future economic settlement.

The legacy yield-specific international-route policy table is inside `HH_MOD_API_TRADEROUTE_MODIFIERS`, absent from the pinned build definitions. Jin uses the working native `Policies.TradeRouteYieldModifier` instead. This is a single additive +15 percentage-point modifier to outgoing international income, including native non-Gold trade yields. It does not affect domestic Food/Production shipments. This engine adaptation is disclosed in the UI and fidelity guide.

Mountain Hall uses a native dummy policy for class-specific Monastery Production; dummy policies are excluded from ordinary policy counts. Pavilion discounts use local native unit-production-modifier buildings in every current/future city. Native +100% Production approximates half price; it adds to other production modifiers rather than literally replacing the displayed base cost.

## Spatial systems and transactions

Site lists are deterministic, nearest-first with plot-index ties, radius 5 around the completing city. Candidates require owned, passable, empty land with no resource, city, Natural Wonder or hostile/foreign occupant. Three real sites are offered when available; fewer are allowed. If all candidates become invalid, regenerate an offer locally. A pending offer persists if there is no legal site. Grassland improvements never overwrite resources or player infrastructure. Garden placement exposes eligible plots within five of owned cities. Grove generation searches radius 3 and caps attribution at five per city.

Each Grassland has its own elapsed owner-turn counter. `s.turn` guards repeated turn callbacks. Full sites do not bank further production; pillaged sites pause their elapsed timer and retained-HP contribution. Destruction/ownership changes remove their inventory. Recapturing the tile does not resurrect old Horses. Great Pasture uses a separate parent-city record and inventory.

All panel mutations validate the active human Jin turn and a saved serial number. Successful actions increment the serial; stale clicks are rejected. Reentry locks cover spawning and synchronous dirty events. Horse recruits check native `IsCanPurchase(false,true,...)`, explicit resistance/raze state, native `CanPlaceUnitHere`, technology, relevant custom gates, Horses and the discounted Gold price. A successful native spawn precedes committing the Horse/Gold cost. Recruits arrive without movement and use ordinary native resource accounting. They receive native innate promotions plus dynamic Jin effects; city training XP is not explicitly granted by the Lua recruit action.

Every active Horse supplies exact native `MaxHitPointsChange` through one generated promotion covering 1–40 HP. No base maximum is overwritten. On a health-cap transition current living HP is preserved and clamped to at least one; freshly created undamaged units start at full modified health. Cavalry eligibility uses native mounted flags/combat class and land combat status; armor-class tanks do not qualify merely through their class. Transfers and upgrades recalculate dynamic promotions and remove foreign benefits.

## Combat, diplomacy and defenses

CP `CombatEnded` has 15 arguments. Argument 3 is damage inflicted by the attacker; it is not damage received. Only the four applicable Jin signatures use it. A saved composite combat key suppresses duplicate callbacks, and a live recursion lock prevents secondary damage from triggering itself. Secondary damage is nonlethal, capped by remaining HP and three adjacent targets; civilians, invisible/neutral/friendly/invalid units are excluded. Bed Crossbow's second damage event targets its primary defender after normal combat, including native fighting state. No secondary XP/kill rewards are manufactured.

Tributaries are separate from ordinary influence. Their record matches a living independent City-State capital; war, conquest or elimination removes the relationship. Reestablishment requires another legal Emissary action. The +15% modifier is boolean, while Food and Villager capacity scale per valid relationship. Other major civilizations' influence is untouched.

Bribe requires nearby visible hostile land combatants; it protects Great People, civilians, limited/hero/project units, script-only or immobile units and custom classes without a conventional default. Enemy unique troops become their unit class's standard counterpart, preserving health fraction but not proprietary abilities, veteran XP or promotions. A living Barbarian replacement must exist before the original is removed, and Barbarian hostility to both sides is checked. Failed replacements are uncharged; partial successes charge only converted units. Rebels expire after six scaled game turns, checked on player turns even after Jin elimination/reload or when a Barbarian turn is absent. The Jin never control them.

Cities gain emplacements through Dragon Pavilion, Great Wall Bastion or the empire upgrade; Forts/Citadels require the upgrade and are indexed by tile events plus bounded city-neighborhood discovery at initialization. Each parent tracks capacity, next replenishment and last automatic shot. Defenders have parent/birth identity, a finite lifetime, NoCapture, no train/upgrade availability and a native CanMoveInto leash. Displaced units, expired units, ownership transfers and lost parents are cleaned up. Overlapping parents retain separate bounded capacities; repeated callbacks cannot replenish one parent twice inside its cooldown. Threat searches inspect only radius-3 neighborhoods. No frame callback or continuous global scan is installed.

Karma counts worked tiles within three of Mountain Hall/Jin Monasteries, plus nearby workers once per worker. Gain scales inversely with actual TrainPercent. Unit deaths are deduplicated; native conversions and controlled defender expiration are excluded. The four-turn blessing expires after four future native economic settlements. Groves add native worked Production and remove one movement point from nearby visible hostile combatants once per turn, never below zero.

## Engine and verification boundary

Native art uses existing mounted, siege and infantry models. The Mounted Villager is a real Worker definition with a borrowed mounted visual; its model does not have a custom construction animation. Eruptor and Grenadier explosives have mechanical scatter, not new particle/projectile animation. The static original Aguda painting supplies the leader scene and Dawn. No AoE4 proprietary artwork/audio or Korean DLC dependency is included.

SQL and Lua tests are executable checks, not proof of native rendering, engine event timing, real-save serialization or play balance. The outstanding native matrix is in Testing.md. This implementation remains a preview until that matrix is executed.
