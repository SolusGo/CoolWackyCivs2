# Implementation and verified contracts

## Database and isolation

SQL loads in this order: core rows, active companion inheritance, exact effects,
atlases, localization, then the repository's presentation-only player guide.
The collection appends the module after all released content, preserving earlier
insertion order. The standalone loads the same files, with the collection's
small optional-metadata compatibility table declarations first.

Runtime `CREATE TEMP TABLE ... AS SELECT *` cloning copies the active Swordsman
and Barracks. Schema-derived companion SQL copies requirements, promotions,
upgrades, flavors, experience and other base functionality. Only the specified
presentation fields and unique bonuses change. Rome supplies architecture and
starting entries; Aurelion has a new empty trait, without Rome's ability.
`Playable=1`, `AIPlayable=0`; every dynamic bonus requires a human Imperium owner.

## Persistence and turns

Namespaced `[TRI1_key=value]` fragments preserve unrelated native ScriptData.
Player keys: `M` is the sole authoritative Momentum value; `BOUNDARY` is the last
processed owner-start global turn; `WIN` records any victory since that boundary.
Two notification turn stamps bound feedback. Native CP serializers save player,
plot and unit ScriptData. No external file/database, cached second Momentum
value, random timer or game-speed multiplier is used.

At the next `GameEvents.PlayerDoTurn(playerID)`, a newer boundary consumes WIN
and decays by one only if no victory occurred. Duplicate events in the same
global turn do nothing. Initialization seeds a missing boundary to the current
turn without decay; loading reconstructs modifiers without consuming WIN or
replaying rewards. This includes late-era and nonzero starting turns.

CP v151 processes cities/economic yields before `PlayerDoTurn`, and unit turns
after it. The previous cycle therefore settles with its existing modifier;
decay then establishes the new-cycle value before unit movement resets. No
unverified executable UI notification is used as an economic turn hook.

`MapModData.TRI_Controller` is only an ephemeral subscription registry. A newly
created context retires the former owner and removes every callback. Loading the
same context twice returns without resubscribing. Shutdown retires the owner.

## Exact combat deaths

Verified CP v151 callbacks:

* `BattleStarted(kind, x, y)`: 0 melee, 1 ranged, 2 air, 3 sweep, 4 paradrop, 5 nuclear.
* `BattleJoined(playerID, unitOrCityID, role, isCity)`: native combat-info setters
  emit participant membership, including city bombardment and interceptors.
* `UnitPrekill(victimOwner, unitID, unitType, x, y, delayed, responsibleOwner)`:
  used only to prepare a lethal participant receipt, never to award Momentum.
* `UnitKilledInCombat(killerOwner, victimOwner, victimUnitType, killerUnitID)`:
  the fourth argument is usually **-1**, and the third is a **type**, not unit ID.
* `BattleFinished()`: clears the ephemeral participant and death ledger.

`CvUnit::setDamage` reaches lethal HP, calls delayed `kill(true, responsibleOwner)`
(prekill runs), then invokes `DoUnitKilledCombat`. The victim still exists during
that authoritative callback. The controller consumes exactly one matching
receipt, writes a unit death marker and awards one point. A receipt requires a
major enemy victim, military eligibility (melee, ranged or a nuclear payload), matching
owner/ID/type/birth turn, lethal HP, an opposing battle participant and a human
Imperium killer. Ordinary script `Kill`, gifts, upgrades, full-health immobile
units destroyed by city acquisition, civilians and unmatched notifications fail
these checks. No speculative reward comes from prekill or predicted damage.

Melee, ranged, naval, air, sweep, paradrop interception, city shots and nuclear
resolvers remain within the battle lifecycle. Attributed nuclear military damage
uses the same lethal and authoritative notifications; friendly/neutral victims
and unattributed scripted explosions do not qualify. Mods that directly
forge native events or force lethal damage during an active real battle cannot
be distinguished universally by the public Lua interface; ordinary script
deletions and out-of-battle damage never earn rewards.

## Conquests and Halls

`CityCaptureComplete(oldOwner, wasCapital, x, y, newOwner, population, conquest,
greatWorkCount, capturedGreatWorks)` is emitted after the new city exists.
The plot's actual city and owner are checked. Only `conquest == true` from a
major owner qualifies. The callback receipt prevents duplicate processing.

Plot key `REWARD_playerID` awards +2 only once per site/player for the lifetime
of the save. Plot key `HALL` holds recipient plus original owner/founding turn,
which survive ordinary acquisition. Every ownership transition clears old
eligibility before establishing a new genuine-conquest receipt. Founding clears
stale eligibility; a razed city cannot leak its pending Hall to a replacement.
Research, reconstruction and owner turns grant waiting Halls only to matching
currently owned cities after Bronze Working. An existing real or free Hall
fulfills eligibility. If necessary, only other real Barracks-class buildings are
replaced by the actual Hall, avoiding duplicate class effects.

Conquest synchronizes all custom production buildings on the new city, including
when it is lost to another civilization. It never deletes other building classes.
Annexation and puppet status do not affect eligibility. Subsequent recaptures
renew eligibility and WIN without farming more conquest Momentum.

## Native bonuses and movement

Six mutually exclusive hidden/nonselectable promotions provide CombatPercent
2/4/6/8/10/12 to current military units. Six mutually exclusive dummy buildings
provide MilitaryProductionModifier 4/8/12/16/20/24 in each city. A separate
10-point dummy is present only in Hall cities at Momentum 4+. Native city unit
production checks `IsMilitaryProduction()` before adding these modifiers, so
they enter ordinary additive production/overflow calculations and do not apply
to other production orders. The ordinary native resistance/puppet rules remain.

All dummy buildings have cost -1, IsDummy, NeverCapture and zero capture chance;
CityCanConstruct additionally rejects their types. Changes reconcile exact
counts rather than incrementing stats. Creation, purchase/training, completed
conversion/upgrade, city founding/capture/Hall construction or sale, load and one owner
turn sweep cover future objects. UnitSetXY reconciles only the moved unit for
unusual ownership transitions. No per-frame empire scan runs.

Unbroken Advance uses AttackMod=10, LostWithUpgrade=0 and LostOnGifting=0.
CP applies AttackMod to attacking melee/ranged calculations, not defense.
Victorious March uses MovesChange=1 and LostWithUpgrade/LostOnGifting=1;
post-conversion reconciliation ensures it belongs only to original-type
Unbroken controlled by the eligible owner. CP's `changeExtraMoves` does not
refill current moves. Removal clamps only remaining movement above the new max;
unrelated promotions are untouched. A mid-turn activation takes full effect on
the next normal movement refresh, without manufacturing movement immediately.

## Source pin

Contracts were read and hash-checked against the repository's official
Community Patch v151 source pin, commit
`44c1e14ff75d80c1dba5c8a71e8289439a53aafb`:

* [CvPlayer.cpp: combat kill, conquest, turn order, serialization](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvPlayer.cpp)
* [CvUnit.cpp: lethal damage, prekill, conversion, promotions, movement](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvUnit.cpp)
* [CvCity.cpp: native military production](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvCity.cpp)
* [CvUnitCombat.cpp: combat lifecycle](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvUnitCombat.cpp)
* [CvGameCoreStructs.cpp: participant membership](https://github.com/LoneGazebo/Community-Patch-DLL/blob/44c1e14ff75d80c1dba5c8a71e8289439a53aafb/CvGameCoreDLL_Expansion2/CvGameCoreStructs.cpp)

The installed v151 manifest/schema and installed BNW assets were inspected
read-only. No native game session was run; source and mocked acceptance are
reported separately in Testing.md.
