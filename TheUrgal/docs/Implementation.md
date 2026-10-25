# Urgal implementation

One `InGameUIAddin`, `UI/URGAL_Potions.xml`, owns simulation through its same-named Lua file and `URGAL_Core`. Urgal is human-only in SQL and runtime. `URGAL_AI.lua` is retained as dormant legacy source and is neither included nor called. Existing civilization identities and McPvP behavior are independent.

## Persistent state and deadlines

Player ScriptData retains `[URGAL_P1:potions:lastEra:finishTurn:readyTurn:serial]`; participants retain `[URGAL_U1:owner:serial:finishTurn]`. Other mods' data is preserved. No key, field order or collection UUID changes. Decimal integer encoding avoids scientific notation in large valid stockpiles. Duplicate, truncated, corrupt and unknown-version player records fail closed without granting a new opening bottle.

Bootstrap initializes one bottle and records the starting Era. `TeamSetEra` immediately awards the difference to matching human Urgal teammates; `PlayerDoTurn` is a scoped missed-event fallback. Duplicate/regressive events never repay an Era. Advanced starts do not retroactively award earlier Eras.

Strength duration remains 3/5/7/12; Aftertaste is 1/2/3/6. Custom speeds use TrainPercent: Strength floors `5*p/100`; Aftertaste rounds `2*p/100` to the nearest integer, both minimum one. Missing/nonpositive/nonfinite percentages default to 100. The saved expiration and reactivation deadlines are authoritative. Legacy v15 windows retain their already-recorded two-turn Aftertaste; all new drinks use corrected speed values. No timer is extended on reload or upgrade.

## Activation, combat and unit lifecycle

`U.Count` counts eligible unembarked land melee units. At least one is required to drink, while the full eligible snapshot still includes embarked participants. Feedback distinguishes immediate and embarked counts. Embarking suspends effects; disembarking restores a participant only before its original deadline. New units lack a participant marker and never join an existing window. Duplicate UnitCreated notifications preserve a legitimate existing marker.

An in-flight guard blocks reentrant spending. Inventory/deadlines commit before the full snapshot is marked, then native promotions are reconciled. Temporary `AttackMod=50` and `CityAttack=0` give the full additive +50% against units and enemy cities. No CombatPercent, defensive or city bombardment modifier is added. Only eligible melee units receive the promotion. Native city bombardment reads the city's strength cache and garrison base strengths, which this controller does not modify.

Pot Chaser remains a permanent upgrade-retained identity. A separate temporary `HPHealedIfDestroyEnemy=15` promotion is present only with both Pot Chaser and active Strength II. The audited native post-kill handler applies one capped heal, including barbarians unless another engine rule prohibits healing. No Lua damage or extra-movement/attack simulation is used.

CP v151 UnitConverted follows promotion copying and precedes old-unit destruction. Only a legitimate same-owner upgrade transfers a matching participant serial and deadline to an eligible replacement. Gifts, other conversions, expired markers and ownership mismatches clear temporary effects. Permanent Pot Chaser is preserved. Per-unit setter failures are isolated so the rest of the army can expire; failed units retry on later lifecycle/movement/turn events. Notification failures cannot interrupt era accounting or cleanup.

The Rusher fixes only requested scalar values (14 Strength, 2 Movement, 80 Production) and removes Iron, retaining other Swordsman companion effects and models. Brewing Stand fixes 75 cost/1 maintenance, inherits Barracks XP and companion benefits, and adds native per-unit `Unit_ProductionModifierBuildings=10` rows for eligible melee types. SQL/Lua predicates agree. Units loaded after this collection's SQL need compatible load ordering to gain those production rows. No potions or economic yields are created by the building.

## UI ownership and asset

Retirement removes event handlers, clears the owning context's queued update and makes stale callbacks inert. Closures retain `U.context`, so an old callback cannot clear a successor's update. Same-context UI reloads do not register duplicate handlers. Popup types are reference-counted, so closing one of two same-type popups cannot expose the panel. City screens, diplomacy, popups, interface modes, inactive turns and hidden contexts suppress it. Dirty events coalesce into a one-shot update that detaches before refresh; there is no permanent polling.

`URGAL_PotionUI32.dds` is a transparent 32x32 legacy RGBA DDS with six mip levels. The deterministic art compiler adapts the existing purple glass bottle, removes the medallion background and fits it into the 32px display. The manifest imports it. Icon, title, status and button occupy separate regions in the existing 290x112 panel. Native `SupportFunctions.TruncateString` measures title width within 226px; its tooltip keeps the full inventory value.

The tests execute shipped Lua, real-schema SQL and the installed native text helper with modeled font metrics. SQL-backed combat/healing models are checked against pinned native source contracts. Neither these models nor static viewport geometry establish native combat or rendering acceptance. See [Testing.md](Testing.md), [Validation.json](Validation.json) and [Audit.md](Audit.md).
