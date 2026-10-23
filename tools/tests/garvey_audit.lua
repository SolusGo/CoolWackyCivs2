local G=Reload();Tick(turn+12)
local s=G.State(0);s.insub=2;G.Save(0,s);assert(G.Roll(0,4,s.ready));Flush()
local full=GameInfoTypes.POLICY_GARVEY_PENALTY_FULL
local relief=GameInfoTypes.POLICY_GARVEY_PENALTY_RELIEF
local science=GameInfoTypes.BUILDING_GARVEY_OFFICE_SCIENCE
local extra=NewCity(p,2,true);GameEvents.PlayerCityFounded(0,4,5);Flush()
assert(p:HasPolicy(relief) and city:GetNumBuilding(science)==0)
-- Both real and free scripted Office mutations have a native post-mutation
-- SpecificCityInfoDirty callback. Only the changed city's markers are visited.
local scans,units,lookups=metrics.cityScans,metrics.unitScans,metrics.cityLookups
city:SetNumRealBuilding(G.OFFICE,1,true)
for i=1,1000 do Events.SpecificCityInfoDirty(0,city.id,1) end
Flush()
assert(city:GetNumBuilding(science)==1 and p:HasPolicy(relief))
assert(metrics.cityScans==scans and metrics.unitScans==units and metrics.cityLookups==lookups+1)
city:SetNumRealBuilding(GameInfoTypes.BUILDING_GARVEY_DETENTION,0,true);Flush()
assert(city:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_DETENTION)==1,'scripted dummy removal was not repaired')
city:SetNumRealBuilding(G.OFFICE,0,true);Flush();assert(city:GetNumBuilding(science)==0)
extra:SetNumRealBuilding(G.OFFICE,0,true);Flush();assert(p:HasPolicy(full) and not p:HasPolicy(relief))
city:SetNumFreeBuilding(G.OFFICE,1);Flush();assert(city:GetNumBuilding(science)==1 and p:HasPolicy(relief))
city:SetNumFreeBuilding(G.OFFICE,0);Flush();assert(city:GetNumBuilding(science)==0 and p:HasPolicy(full))
-- Native CityRazed precedes city removal. The deferred policy pass must see the
-- final remaining empire even if no generic dirty callback is delivered.
extra:SetNumRealBuilding(G.OFFICE,1,true);Flush();assert(p:HasPolicy(relief))
plot.city=extra;GameEvents.CityRazed(0,4,5)
assert(p:HasPolicy(full) and not p:HasPolicy(relief),'dying Office must not soften the ongoing native economic pass')
p.cities={city};plot.city=nil;Flush()
assert(p:HasPolicy(full) and not p:HasPolicy(relief))
-- A city dirty request may become stale through capture before dispatch.
city:SetNumRealBuilding(G.OFFICE,1,true)
p.cities={};p.alive=false;foreign.cities={city};city.owner=2
GameEvents.CityCaptureComplete(0,true,4,5,2,10,true,0,0);Flush()
for _,name in ipairs(G.dummies) do assert(city:GetNumBuilding(GameInfoTypes['BUILDING_GARVEY_'..name])==0) end
assert(not p:HasPolicy(full) and not p:HasPolicy(relief))
-- Restore a capital and exercise the real large-empire event workload.
p.alive=true;p.cities={extra};extra.owner=0;G.Sync(0,true)
for i=10,209 do NewCity(p,i,i%2==0) end
for i=30,2029 do NewUnit(p,i,-6,20) end
G.Sync(0,true);Flush();Controls.Open.click()
local c0,u0,r0,ur0=metrics.cityScans,metrics.unitScans,metrics.cityReads,metrics.unitReads
for i=1,1000 do Events.SerialEventGameDataDirty();Events.SerialEventCityInfoDirty();Flush() end
assert(metrics.cityScans==c0 and metrics.unitScans==u0 and metrics.cityReads==r0 and metrics.unitReads==ur0,
 'generic/UI dirties must not touch any city or military unit')
assert(ContextPtr.update==nil)
-- The exact v1 serialized form, values and kill namespace remain readable.
local legacy=Store['GARVEY:v1:state:0'];assert(legacy:match('^1|'))
local fields=0;for _ in legacy:gmatch('[^|]+') do fields=fields+1 end;assert(fields==9)
G=Reload();assert(Store['GARVEY:v1:state:0']==legacy and G.State(0).insub==0)
-- Explicit event enablement must remain mandatory in the fixture, independently
-- of other civilizations and of CP's disabled-option fallback implementation.
Options.EVENTS_UNIT_PREKILL=0
local ok,err=pcall(function() GameEvents.UnitPrekill(1,target.id,target.typ,4,5,true,0) end)
assert(not ok and tostring(err):find('EVENTS_UNIT_PREKILL'))
Options.EVENTS_UNIT_PREKILL=1
