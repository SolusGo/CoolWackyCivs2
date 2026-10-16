local p=NewPlayer(0,true);local ai=NewPlayer(1,true);local other=NewPlayer(2,false)
local a=NewCity(p,4);local b=NewCity(p,9);local enemy=NewCity(other,4);local ac=NewCity(ai,1)
a.buildings[104]=1
-- Context initialization scrubs saved, stale bonuses in unrelated owners too.
enemy.buildings[101]=9;enemy.buildings[102]=9;enemy.buildings[103]=1
local globals={};for key in pairs(_G) do globals[key]=true end
LoadPigeons();FlushPigeons();CheckCity(enemy,0,0,0);CheckCity(a,0,0,0)
for key in pairs(_G) do assert(globals[key],'addin polluted globals: '..key) end
for _,event in pairs(GameEvents) do assert(event.Count()==1,'duplicate or missing hook') end
assert(ContextPtr.callback==nil)
-- Medieval, same-city stacking, binary Roost and idempotence.
p.routes={Route(p,a)}
GameEvents.UnitPrekill.Fire(0,42,105,10,10,true,-1);FlushPigeons();CheckCity(a,2,2,1)
local writes=a.writes
GameEvents.PlayerDoTurn.Fire(0);GameEvents.PlayerDoTurn.Fire(0)
CheckCity(a,2,2,1);assert(a.writes==writes,'cumulative/duplicate writes')
p.routes={Route(p,a),Route(p,a),Route(p,a)}
GameEvents.PlayerDoTurn.Fire(0);CheckCity(a,6,6,1)
-- Internal food/production/gold and international routes all qualify.
p.routes={Route(p,a,2,0,1),Route(p,a,2,0,2),Route(p,a,2,2,0),Route(p,b,2,0,3)}
GameEvents.PlayerDoTurn.Fire(0);CheckCity(a,6,6,1);CheckCity(b,2,2,0)
-- Same city names and same IDs in another owner never qualify; malformed entries ignored.
p.routes[#p.routes+1]=Route(other,enemy)
p.routes[#p.routes+1]={FromID=0,FromCity=enemy,Domain=2}
p.routes[#p.routes+1]={FromID=0,Domain=2}
p.routes[#p.routes+1]=Route(p,a,0)
GameEvents.PlayerDoTurn.Fire(0);CheckCity(a,6,6,1);CheckCity(enemy,0,0,0)
-- Incoming route to b cannot activate its Roost or UA (not present in GetTradeRoutes).
other.routes={Route(other,enemy,2,0)};b.buildings[104]=1
GameEvents.PlayerDoTurn.Fire(2);CheckCity(enemy,0,0,0)
-- Renaissance for both teammates; no speed-based multipliers.
ai.team=0;ai.routes={Route(ai,ac),Route(ai,ac),Route(ai,ac)}
p.era=3;ai.era=3;GameEvents.TeamSetEra.Fire(0,3,true);FlushPigeons()
CheckCity(a,9,9,1);CheckCity(b,3,3,1);CheckCity(ac,9,9,0)
for era=0,7 do
 p.era=era;GameEvents.PlayerDoTurn.Fire(0)
 CheckCity(a,era>=3 and 9 or 6,era>=3 and 9 or 6,1)
end
-- Completion hook fires before the native route is cleared. Do not inspect early.
local reads=p.reads
GameEvents.PlayerTradeRouteCompleted.Fire(0,4,2,4,2,0)
assert(p.reads==reads,'read from inside completion hook')
p.routes={Route(p,b)};FlushPigeons();CheckCity(a,0,0,0);CheckCity(b,3,3,1)
-- Plunder hook uses the FOURTH argument for the route owner.
GameEvents.PlayerPlunderedTradeRoute.Fire(2,55,120,0,9,2,4,0,2)
p.routes={};FlushPigeons();CheckCity(b,0,0,0)
-- Land-to-sea switch, war cancellation and ordinary dirty creation.
p.routes={Route(p,a,0)};Events.SerialEventGameDataDirty.Fire();FlushPigeons();CheckCity(a,0,0,0)
p.routes={Route(p,a)};Events.SerialEventGameDataDirty.Fire();FlushPigeons();CheckCity(a,3,3,1)
Events.WarStateChanged.Fire(0,2,true);p.routes={};FlushPigeons();CheckCity(a,0,0,0)
-- Construction/removal only changes the binary Production, never UA counts.
p.routes={Route(p,b)};GameEvents.PlayerDoTurn.Fire(0);b.buildings[104]=0
GameEvents.CitySoldBuilding.Fire(0,9,104);FlushPigeons();CheckCity(b,3,3,0)
b.buildings[104]=1;GameEvents.CityConstructed.Fire(0,9,104,false,false);FlushPigeons();CheckCity(b,3,3,1)
b.buildings[104]=0;Events.SerialEventGameDataDirty.Fire();FlushPigeons();CheckCity(b,3,3,0)
-- Ownership transfer: simulate even a script carrying dummies into a foreign city.
p.routes={Route(p,a)};GameEvents.PlayerDoTurn.Fire(0)
GameEvents.CityCaptureComplete.Fire(0,false,10,10,2,5,true)
p.cities[4]=nil;other.cities[7]=a;a.owner=2;a.id=7;p.routes={}
FlushPigeons();CheckCity(a,0,0,0);CheckCity(b,0,0,0)
-- Captured destination cancels a different Pigeon player's route too.
ai.routes={};GameEvents.CityCaptureComplete.Fire(2,false,20,20,0,3,true);FlushPigeons();CheckCity(ac,0,0,0)
-- Deleted/razed city after scheduling: dispatcher keeps IDs, never stale city userdata.
p.routes={Route(p,b)};GameEvents.PlayerDoTurn.Fire(0)
Events.SerialEventGameDataDirty.Fire();p.routes={};p.cities[9]=nil;b.deleted=true
FlushPigeons()
-- Elimination clears any residual city; nil/missing player turn is safe.
ai.routes={Route(ai,ac)};GameEvents.PlayerDoTurn.Fire(1);ai.alive=false
GameEvents.PlayerDoTurn.Fire(1);CheckCity(ac,0,0,0)
GameEvents.PlayerDoTurn.Fire(7)
-- Dirty storms coalesce, and synchronous write dirties never arm another callback.
ai.alive=true;ai.routes={Route(ai,ac)}
local arms=ContextPtr.arms
for n=1,500 do Events.SerialEventGameDataDirty.Fire() end
assert(ContextPtr.arms==arms+1,'dirty events did not coalesce');FlushPigeons()
assert(ContextPtr.callback==nil,'permanent update callback');CheckCity(ac,3,3,0)
-- Save/load is a fresh Lua context over native city state; discard old handlers.
GameEvents={};Events={}
for _,name in ipairs({'PlayerDoTurn','PlayerTradeRouteCompleted','PlayerPlunderedTradeRoute','TeamSetEra','CityConstructed','CitySoldBuilding','CityCaptureComplete','UnitPrekill'}) do
 GameEvents[name]=NewTestEvent()
end
for _,name in ipairs({'SerialEventGameDataDirty','WarStateChanged','LoadScreenClose'}) do Events[name]=NewTestEvent() end
ac.buildings[101]=88;ac.buildings[102]=88;ac.buildings[103]=1
ai.era=2;ai.routes={Route(ai,ac),Route(ai,ac),Route(ai,ac)}
LoadPigeons();FlushPigeons();CheckCity(ac,6,6,0)
assert(#PigeonTestLogs==0,'unexpected Lua error log')
