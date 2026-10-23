local G=Reload();Tick(turn+12)
-- A setter can mutate its native object before raising. Retrying the committed
-- selection must repair the remaining cities, without another RNG call.
local extra=NewCity(p,2);GameEvents.PlayerCityFounded(0,4,5)
local original=city.SetNumRealBuilding;local once=true
city.SetNumRealBuilding=function(self,...)
 original(self,...)
 if once then once=false;error('injected setter after mutation') end
end
local ready=G.State(0).ready;assert(G.Roll(0,1,ready))
assert(city:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_AARON)==1)
assert(extra:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_AARON)==1,'partial native effect application survived a transient fault')
assert(randomCalls==1 and G.State(0).insub==1)
city.SetNumRealBuilding=original
-- Save after-write errors must retry exactly the same candidate, never reroll.
Tick(turn+12);Faults.stateWriteAfter=1;ready=G.State(0).ready
assert(G.Roll(0,2,ready) and randomCalls==2 and G.State(0).insub==2)
assert(not G.Roll(0,2,ready) and randomCalls==2)
-- One transient load/open/read error must not disable a valid existing save.
local encoded=Store['GARVEY:v1:state:0'];Faults.open=1;G=Reload()
assert(G.State(0) and Store['GARVEY:v1:state:0']==encoded)
Faults.stateRead=1;G=Reload();assert(G.State(0) and G.State(0).insub==2)
Tick(turn+12);assert(G.Roll(0,4,G.State(0).ready))
-- A transient paid-marker read/write fault must not lose the reward or pay it
-- twice. Marking and native Culture delivery remain separate synchronous work.
local dead=NewUnit(enemy,77,-7,24);dead.dead=true
local before=p.culture;Faults.killWriteAfter=1
GameEvents.UnitPrekill(1,77,dead.typ,4,5,true,0);assert(p.culture==before+6)
GameEvents.UnitPrekill(1,77,dead.typ,4,5,false,0);assert(p.culture==before+6)
local another=NewUnit(enemy,78,-7,28);another.dead=true;Faults.killRead=1
GameEvents.UnitPrekill(1,78,another.typ,4,5,true,0);assert(p.culture==before+13)
G=Reload();GameEvents.UnitPrekill(1,78,another.typ,4,5,false,0);assert(p.culture==before+13)
-- Turn persistence retries preserve the final economic tick and expire before
-- the next actions, even when the first native write reports failure.
local endTurn=G.State(0).detEnd;Faults.stateWrite=1;Tick(endTurn)
assert(not G.Active(G.State(0),'detEnd'))
G=Reload();assert(not G.Active(G.State(0),'detEnd'))
