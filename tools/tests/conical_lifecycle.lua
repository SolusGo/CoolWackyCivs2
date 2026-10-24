local p=Player(0,true);local cap=City(p,0,true,true);p.capital=cap
local c=City(p,1,true,true)
local foreign=Player(1,false);foreign.capital=City(foreign,0,true,false)
local other=Player(2,true);other.capital=City(other,0,true,false)
LoadConical();Check(c,2,2,2)
Transfer(c,foreign);Check(c,0,1,0)
Transfer(c,p);Check(c,2,2,2)
Transfer(c,other);Check(c,2,2,2)
Transfer(cap,foreign);Check(cap,0,1,0)
local founded=City(other,3,true,false);GameEvents.PlayerCityFounded.Fire(2,founded.x,0);Check(founded,2,1,0)
-- Simulate normal save/load by reconstructing the context; city data survives, Lua does not.
c.b[U]=9;c.b[G]=7;founded.connected=false
ResetEvents(true);LoadConical();Check(c,2,2,2);Check(founded,0,0,0)
local handlers=#GameEvents.PlayerDoTurn.handlers;LoadConical()
assert(#GameEvents.PlayerDoTurn.handlers==handlers,'duplicate registration')
Events.SequenceGameInitComplete.Fire();Events.LoadScreenClose.Fire();Check(c,2,2,2)
-- A city deleted before a callback is never retained or dereferenced by the controller.
plots[c.x .. ':' .. c.y]=nil
for i,v in ipairs(other.cities) do if v==c then table.remove(other.cities,i);break end end
GameEvents.CityCaptureComplete.Fire(2,false,c.x,c.y,1)
GameEvents.CityRazed.Fire(2,c.x,c.y)
GameEvents.PlayerDoTurn.Fire(63);GameEvents.PlayerDoTurn.Fire(-1)
other.alive=false;founded.b[U]=1;founded.b[G]=1
GameEvents.PlayerDoTurn.Fire(2);Check(founded,0,0,0)
-- Foreign city-dirty notifications explicitly clean even deliberately retained markers.
cap.b[U]=1;cap.b[G]=1;Events.SpecificCityInfoDirty.Fire(1,cap.id);Check(cap,0,1,0)
print('PASS Conical capture/gift/recapture/multiple Conical owners, founding, reload repair, duplicate guard, destroyed/missing/dead players and targeted foreign cleanup')
