local p=Player(0,true)
local capital=City(p,0,true,false);p.capital=capital
local connected=City(p,1,true,true)
local disconnected=City(p,2,false,true)
local bare=City(p,3,true,false)
local empty=City(p,4,false,false)
local foreign=Player(1,false);local f=City(foreign,0,true,true);foreign.capital=f
LoadConical()
Check(capital,0,0,0);Check(connected,2,2,2);Check(disconnected,0,1,0)
Check(bare,2,1,0);Check(empty,0,0,0);Check(f,0,1,0)
capital.b[O]=1;Events.SpecificCityInfoDirty.Fire(0,0);Check(capital,0,1,0)
disconnected.connected=true;GameEvents.PlayerDoTurn.Fire(0);Check(disconnected,2,2,2)
connected.connected=false;GameEvents.PlayerDoTurn.Fire(0);Check(connected,0,1,0)
connected.connected=true;GameEvents.PlayerDoTurn.Fire(0);Check(connected,2,2,2)
local before=writes
for i=1,100 do GameEvents.PlayerDoTurn.Fire(0);GameEvents.PlayerDoneTurn.Fire(0) end
assert(writes==before,'idempotence: repeated turns must not write')
-- Native network may report true for road, railroad, Harbor, mixed or multiple paths.
for _, route in ipairs({'road','railroad','Harbor','mixed','road + Harbor + railroad'}) do
  bare.route=route;bare.connected=true;GameEvents.PlayerDoTurn.Fire(0);Check(bare,2,1,0)
end
-- Sale, normal construction, scripted removal and reconstruction share one controller.
connected.b[O]=0;GameEvents.CitySoldBuilding.Fire(0,1,O);Check(connected,2,1,0)
connected.b[O]=1;GameEvents.CityConstructed.Fire(0,1,O,false,false);Check(connected,2,2,2)
connected.b[O]=0;Events.SpecificCityInfoDirty.Fire(0,1);Check(connected,2,1,0)
connected.b[O]=1;Events.SpecificCityInfoDirty.Fire(0,1);Check(connected,2,2,2)
-- Capital relocation; the former capital is eligible only under the native flag.
p.capital=connected;GameEvents.CapitalChanged.Fire(0,1,0)
Check(connected,0,1,0);Check(capital,2,2,2)
p.capital=nil;GameEvents.CapitalChanged.Fire(0,-1,1)
for _,c in ipairs(p.cities) do Check(c,0,c.b[O] or 0,0) end
p.capital=capital;GameEvents.CapitalChanged.Fire(0,0,-1)
-- Cached flag synchronization: changing terrain has no fictional immediate callback.
connected.pendingConnection=false
Check(connected,2,2,2)
-- At the native refresh boundary the cached value changes; owner-turn fallback repairs it.
connected.connected=connected.pendingConnection;GameEvents.PlayerDoTurn.Fire(0)
Check(connected,0,1,0)
connected.connected=true;GameEvents.PlayerDoTurn.Fire(0);Check(connected,2,2,2)
assert(queries>0)
print('PASS Conical six-state matrix, connect/break/repair, native true/false route shapes, exact non-stacking yields, Office changes, capital relocation and cached refresh boundary')
