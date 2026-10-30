-- Exercise shipped callbacks, native-persistent building state and separate owners.
local turn, writes, queries, initialized, dataWrites = 0, 0, 0, true, 0
local function Event()
  local e = {handlers = {}}
  function e.Add(fn) e.handlers[#e.handlers + 1] = fn end
  function e.Remove(fn) for i = #e.handlers, 1, -1 do if e.handlers[i] == fn then table.remove(e.handlers,i) end end end
  function e.Fire(...)
    local batch = {}; for i,fn in ipairs(e.handlers) do batch[i] = fn end
    for _,fn in ipairs(batch) do fn(...) end
  end
  return e
end
GameEvents, Events = {}, {}
for _,name in ipairs({'PlayerDoneTurn','PlayerDoTurn','CityCaptureComplete','CitySoldBuilding','CityConstructed','PlayerCityFounded'}) do GameEvents[name] = Event() end
for _,name in ipairs({'SpecificCityInfoDirty','LoadScreenClose','SequenceGameInitComplete'}) do Events[name] = Event() end
MapModData, ContextPtr = {}, {SetShutdown = function() end}
Game = {GetGameTurn = function() return turn end, GetActivePlayer = function() return 1 end,
  IsFinalInitialized = function() return initialized end,
  GetGameSpeedType = function() return HCC_TEST_SPEED=='GAMESPEED_MARATHON' and 3 or 1 end}
GameInfoTypes = {CIVILIZATION_HCC_COMMONWEALTH=10, IMPROVEMENT_PLANTATION=20, BUILDING_HCC_HONEY_EXCHANGE=30,
  BUILDING_HCC_PRODUCTION_1=41, BUILDING_HCC_PRODUCTION_2=42, BUILDING_HCC_PRODUCTION_3=43,
  BUILDING_HCC_PRODUCTION_4=44, BUILDING_HCC_CULTURE=45, BUILDING_HCC_GOLD_1=46, BUILDING_HCC_GOLD_2=47}
local EXCHANGE = 30
local cities, plots = {}, {}
Players = {}
for id=0,2 do
  local p = {id=id, civ=id==1 and 99 or 10, alive=true, cities={}, data='OTHER_SYSTEM:kept'}
  function p:GetID() return self.id end
  function p:GetCivilizationType() return self.civ end
  function p:IsAlive() return self.alive end
  function p:GetScriptData() return self.data end
  function p:SetScriptData(v)
    dataWrites=dataWrites+1
    if self.failReceipt and v:find('[HCC1:'..turn..']',1,true) then
      self.failReceipt=false; error('receipt write failed before mutation')
    end
    self.data = v
  end
  function p:GetCityByID(n) return self.cities[n] end
  function p:Cities() local k; return function() k=next(self.cities,k); return k and self.cities[k] end end
  Players[id] = p
end
Map = {
 PlotDistance = function(x,y,px,py) return math.max(math.abs(x-px),math.abs(y-py)) end,
 GetPlot = function(x,y) return {GetPlotCity=function() return cities[x] end} end,
}
local function City(id,owner)
  local c={id=id,owner=owner,x=id*10,y=0,buildings={},free={},plots={},worked={},fail=0}
  function c:GetID() return self.id end
  function c:GetOwner() return self.owner end
  function c:GetX() return self.x end
  function c:GetY() return self.y end
  function c:GetGameTurnFounded() return self.founded or 0 end
  function c:GetNumRealBuilding(b) return self.buildings[b] or 0 end
  function c:GetNumBuilding(b) return math.max(self:GetNumRealBuilding(b),self.free[b] or 0) end
  function c:SetNumRealBuilding(b,n,suppress)
    assert(suppress==true and (n==0 or n==1))
    if (self.failBefore or 0)>0 then self.failBefore=self.failBefore-1; error('native setter fault BEFORE mutation') end
    if (self.silent or 0)>0 then self.silent=self.silent-1; return end
    writes = writes+1; self.buildings[b]=n
    Events.SpecificCityInfoDirty.Fire(self.owner,self.id)
    if HCCOnSet then HCCOnSet(self,b,n) end
    if self.fail>0 then self.fail=self.fail-1; error('native setter fault AFTER mutation') end
  end
  function c:GetNumCityPlots() return 37 end
  function c:GetCityIndexPlot(i) queries=queries+1; return self.plots[i] end
  function c:IsWorkingPlot(p) return self.worked[p.index] or false end
  Players[owner].cities[id]=c; cities[c.x]=c
  return c
end
local seq=0
local function Plot(c,slot,attrs)
  seq=seq+1
  local p={index=seq,owner=c.owner,improvement=20,pillaged=false,x=c.x+1,y=0,working=c}
  for k,v in pairs(attrs or {}) do p[k]=v end
  function p:GetOwner() return self.owner end
  function p:GetImprovementType() return self.improvement end
  function p:IsImprovementPillaged() return self.pillaged end
  function p:GetPlotIndex() return self.index end
  function p:GetX() return self.x end
  function p:GetY() return self.y end
  function p:GetWorkingCity() return self.working end
  c.plots[slot]=p; c.worked[p.index]=true
  return p
end
local function Assign(c,n)
  c.plots={}; c.worked={}
  for i=1,n do Plot(c,i) end
end
local function Values(c)
  local p=0; for b=41,44 do p=p+c:GetNumRealBuilding(b) end
  return p,c:GetNumRealBuilding(45),c:GetNumBuilding(EXCHANGE)>0 and 1 or 0,c:GetNumRealBuilding(46)+c:GetNumRealBuilding(47)
end
local function Check(c,p,k,f,g)
  local a,b,d,e=Values(c)
  assert(a==p and b==k and d==f and e==g,table.concat({a,b,d,e},',')..' expected '..table.concat({p,k,f,g},','))
end
local function Boundary(id) turn=turn+1; GameEvents.PlayerDoneTurn.Fire(id or 0) end
local a=City(1,0)
LoadHCC()
Check(a,0,0,0,0)
-- A-D: all thresholds, arbitrary over-cap counts, normal Exchange ownership.
for _,has in ipairs({false,true}) do
  a.buildings[EXCHANGE]=has and 1 or 0
  for n=0,8 do
    Assign(a,n); Boundary()
    Check(a,math.min(4,n),n>=2 and 1 or 0,has and 1 or 0,has and math.min(2,math.floor(n/2)) or 0)
    local before=writes
    GameEvents.PlayerDoneTurn.Fire(0)
    assert(writes==before,'repeated processing changed state')
  end
end
-- E: owns four but works only one. F: pillaging.
Assign(a,4); for i=2,4 do a.worked[a.plots[i].index]=false end
Boundary(); Check(a,1,0,1,0)
Assign(a,4); a.plots[2].pillaged=true
Boundary(); Check(a,3,1,1,1)
-- Qualification: foreign land, unfinished improvement, wrong city, radius,
-- duplicate native index, nil plot, unworked tile, mismatched owner/city ID.
Assign(a,0)
local valid=Plot(a,1)
Plot(a,2,{owner=1}); Plot(a,3,{improvement=-1}); Plot(a,4,{pillaged=true})
Plot(a,5,{working={GetOwner=function() return 0 end,GetID=function() return 999 end}})
Plot(a,6,{x=a.x+4}); a.plots[7]=valid
local unworked=Plot(a,9); a.worked[unworked.index]=false
Plot(a,10,{working={GetOwner=function() return 1 end,GetID=function() return a.id end}})
Plot(a,11,{working=false})
Boundary(); Check(a,1,0,1,0)
-- G/H: mid-turn assignment and repeated boundary AFTER reload never recalculate.
Assign(a,4); Boundary(); Check(a,4,1,1,2)
Assign(a,1)
local savedWrites=writes; local savedQueries=queries
Events.SpecificCityInfoDirty.Fire(0,1); GameEvents.PlayerDoTurn.Fire(0)
LoadHCC(); assert(#GameEvents.PlayerDoneTurn.handlers==1,'duplicate same-context registration')
__HCC_CONTEXT_CONTROLLER=nil; ContextPtr={SetShutdown=function() end}; LoadHCC()
Events.LoadScreenClose.Fire(); Events.SequenceGameInitComplete.Fire()
initialized=false
local exchangeState=a.buildings[EXCHANGE]; a.buildings[EXCHANGE]=0
Events.SpecificCityInfoDirty.Fire(0,1) -- partial-load absence must not clear valid Gold
a.buildings[EXCHANGE]=exchangeState; initialized=true
GameEvents.PlayerDoneTurn.Fire(0)
Check(a,4,1,1,2); assert(writes==savedWrites and queries==savedQueries,'load/duplicate recounted')
Boundary(); Check(a,1,0,1,0)
assert(Players[0].data:find('OTHER_SYSTEM:kept',1,true))
-- Removal and rebuilding: clear Gold immediately, retain UA, no fresh Gold.
Assign(a,4); Boundary(); a.buildings[EXCHANGE]=0
GameEvents.CitySoldBuilding.Fire(0,1,EXCHANGE); Check(a,4,1,0,0)
a.buildings[EXCHANGE]=1; GameEvents.CityConstructed.Fire(0,1,EXCHANGE,false,false)
Check(a,4,1,1,0); Boundary(); Check(a,4,1,1,2)
a.buildings[EXCHANGE]=0; Events.SpecificCityInfoDirty.Fire(0,1); Check(a,4,1,0,0)
a.free[EXCHANGE]=1; Boundary(); Check(a,4,1,1,2)
a.free[EXCHANGE]=0; Events.SpecificCityInfoDirty.Fire(0,1); Check(a,4,1,0,0)
-- I/K: native reconstructed capture and transfers; foreign normal types untouched.
local function Transfer(c,newOwner)
  local old=c.owner; Players[old].cities[c.id]=nil; c.owner=newOwner; Players[newOwner].cities[c.id]=c
  GameEvents.CityCaptureComplete.Fire(old,false,c.x,0,newOwner,5,false,0,0)
end
a.buildings[999]=7; Transfer(a,1); Check(a,0,0,0,0); assert(a.buildings[999]==7)
Boundary(1); Check(a,0,0,0,0)
Transfer(a,2); Check(a,0,0,0,0)
Assign(a,4); a.buildings[EXCHANGE]=1; Boundary(2); Check(a,4,1,1,2)
Transfer(a,0); Check(a,0,0,1,0)
Assign(a,4); Boundary(); Check(a,4,1,1,2)
-- L: independent city/empire totals and M: idempotence next turn too.
local b,c,d=City(2,0),City(3,0),City(4,0)
b.buildings[EXCHANGE]=1; d.buildings[EXCHANGE]=1
Assign(b,2); Assign(c,1); Assign(d,0); Boundary()
Check(a,4,1,1,2); Check(b,2,1,1,1); Check(c,1,0,0,0); Check(d,0,0,1,0)
local totals={0,0,0,0}
for _,city in ipairs({a,b,c,d}) do local vals={Values(city)}; for i=1,4 do totals[i]=totals[i]+vals[i] end end
assert(table.concat(totals,',')=='7,2,3,3')
local previous=writes; Boundary(); assert(writes==previous,'unchanged snapshot invoked native setters')
-- Bounded synchronous retry repairs even a setter that mutates and then throws.
Assign(c,4); c.fail=1; Boundary(); Check(c,4,1,0,0)
-- Removed city, invalid player, dead Commonwealth and founding do not crash/grant.
Players[0].cities[c.id]=nil; cities[c.x]=nil
Events.SpecificCityInfoDirty.Fire(0,c.id); GameEvents.CityCaptureComplete.Fire(0,false,c.x,0,1)
GameEvents.PlayerDoneTurn.Fire(-1); GameEvents.PlayerDoTurn.Fire(-1)
local fresh=City(5,0); Assign(fresh,4); GameEvents.PlayerCityFounded.Fire(0,fresh.x,0); Check(fresh,0,0,0,0)
Players[0].alive=false; Boundary(); Check(fresh,0,0,0,0); Players[0].alive=true
Boundary(); Check(fresh,4,1,0,0)
-- N: simulated next payout sees STAGED state before any PlayerDoTurn callback.
Assign(fresh,2); Boundary(); local nativeProduction=select(1,Values(fresh))
assert(nativeProduction==2); GameEvents.PlayerDoTurn.Fire(0); Check(fresh,2,1,0,0)
-- Interturn pillage difference is explicit: staged state lasts until next boundary.
fresh.plots[1].pillaged=true; turn=turn+1; GameEvents.PlayerDoTurn.Fire(0)
Check(fresh,2,1,0,0); GameEvents.PlayerDoneTurn.Fire(0); Check(fresh,1,0,0,0)
print('PASS HCC shipped Lua A-I, K-N: qualification, caps, snapshots, reload, captures, multiple owners, sale/removal, idempotence, bounded retry (mock; native acceptance pending)')
HCC_Test={City=City,Plot=Plot,Assign=Assign,Check=Check,Boundary=Boundary,Values=Values,Transfer=Transfer,
  Writes=function() return writes end,Queries=function() return queries end,Turn=function() return turn end,
  DataWrites=function() return dataWrites end,SetTurn=function(n) turn=n end}
