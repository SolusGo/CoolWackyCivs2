local foreign=NewCity(900,1,true);foreign.buildings[111]=1;foreign.buildings[121]=1
local escaped=NewUnit(900,1);escaped.promotions[133]=true
local cities={};for i=1,202 do cities[i]=NewCity(i,0,i%2==0) end
local units={};for i=1,250 do units[i]=NewUnit(i,0) end
LoadUnrung();CheckCity(foreign,0,0);CheckUnit(escaped,0)
PeaceTurns(15)
for i,c in ipairs(cities) do CheckCity(c,3,i%2==0 and 3 or 0) end
local writes=counters.cityWrites
Events.LoadScreenClose.Fire();assert(counters.cityWrites==writes)
-- A failed city cannot prevent the remainder of a large empire from reconciling.
cities[1].fail=true;WarWith(1,true)
for i=2,#cities do CheckCity(cities[i],0,0) end
for _,u in ipairs(units) do CheckUnit(u,3) end
cities[1].fail=false;Events.SpecificCityInfoDirty.Fire(0,1);CheckCity(cities[1],0,0)
-- Retained native callbacks must be inert even when Remove is unavailable.
for _,e in pairs(GameEvents) do e.Remove=nil end
for _,e in pairs(Events) do e.Remove=nil end
NewContext();LoadUnrung()
local scans=counters.cityScans;Begin();assert(counters.cityScans==scans+1)
-- Simulate loading an end-turn autosave written BEFORE DoneTurn. Replayed
-- boundary increments once; this is an explicit model, not native replay proof.
WarWith(1,false);Done();now=now+1;Begin()
local snapshot=saves.UNRUNG_STATE_V1_0;local before=Read().peace
Done();assert(Read().peace==before+1)
saves.UNRUNG_STATE_V1_0=snapshot;NewContext();LoadUnrung()
assert(Read().peace==before);Done();Done();assert(Read().peace==before+1)
print('PASS 202-city/250-unit reconciliation, foreign load sanitation, isolated city fault/recovery, inert retained callbacks, modeled autosave rollback/replay')
