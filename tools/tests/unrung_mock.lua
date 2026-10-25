-- Runs the SHIPPED Lua in Lua 5.1. This is not the native game runtime.
now, saves, counters = 0, {}, {cityWrites=0, unitWrites=0, cityScans=0, unitScans=0}
MapModData, GameEvents, Events, Players, Teams, plots = {}, {}, {}, {}, {}, {}
Game = {GetGameTurn=function() return now end}
GameDefines = {MAX_CIV_PLAYERS=6}
DomainTypes = {DOMAIN_LAND=0, DOMAIN_SEA=1, DOMAIN_AIR=2}
GameInfoTypes = {CIVILIZATION_UNRUNG_BELL=100, BUILDING_UNRUNG_SILENT_BELFRY=101,
                PROMOTION_UNRUNG_BELLWARDEN=102}
for i,tier in ipairs({'I','II','III'}) do
  GameInfoTypes['BUILDING_UNRUNG_QUIETUDE_'..tier]=110+i
  GameInfoTypes['BUILDING_UNRUNG_SCIENCE_'..tier]=120+i
  GameInfoTypes['PROMOTION_UNRUNG_GREAT_TOLL_'..tier]=130+i
end
function Event()
  local e={handlers={}}
  e.Add=function(fn) e.handlers[#e.handlers+1]=fn end
  e.Remove=function(fn) for i=#e.handlers,1,-1 do if e.handlers[i]==fn then table.remove(e.handlers,i) end end end
  e.Fire=function(...)
    local copy={};for i,fn in ipairs(e.handlers) do copy[i]=fn end
    for _,fn in ipairs(copy) do fn(...) end
  end
  return e
end
for _,n in ipairs({'PlayerDoTurn','PlayerDoneTurn','CityConstructed','CitySoldBuilding',
  'PlayerCityFounded','CityCaptureComplete','CityRazed','UnitCreated','CityTrained','UnitConverted','UnitUpgraded'}) do GameEvents[n]=Event() end
for _,n in ipairs({'WarStateChanged','SpecificCityInfoDirty','SequenceGameInitComplete','LoadScreenClose'}) do Events[n]=Event() end
Modding={OpenSaveData=function() return {
 GetValue=function(key) return saves[key] end,
 SetValue=function(key,value) if failSave then error('injected save failure') end; saves[key]=value end
} end}
function NewPlayer(id,civ,human)
 local p={id=id,civ=civ or 0,human=human or false,alive=true,active=false,cities={},units={}}
 function p:GetCivilizationType() return self.civ end
 function p:GetTeam() return self.id end
 function p:IsAlive() return self.alive end
 function p:IsHuman() return self.human end
 function p:IsBarbarian() return self.id==3 end
 function p:IsTurnActive() return self.active end
 function p:GetCityByID(id) return self.cities[id] end
 function p:GetUnitByID(id) return self.units[id] end
 local function iterator(list) local key;return function() key=next(list,key);return key and list[key] end end
 function p:Cities() counters.cityScans=counters.cityScans+1;return iterator(self.cities) end
 function p:Units() counters.unitScans=counters.unitScans+1;return iterator(self.units) end
 Players[id]=p;Teams[id]={wars={},IsAtWar=function(self,other) return self.wars[other]==true end}
 return p
end
for i=0,5 do NewPlayer(i,i==0 and 100 or 0,i==0) end
function NewCity(id,owner,belfry)
 local c={id=id,owner=owner,buildings={}}
 if belfry then c.buildings[101]=1 end
 function c:GetID() return self.id end
 function c:GetOwner() return self.owner end
 function c:GetNumRealBuilding(b) return self.buildings[b] or 0 end
 function c:GetNumBuilding(b) return self:GetNumRealBuilding(b) end
 function c:SetNumRealBuilding(b,n,noBonus)
   assert(noBonus==true,'dummy construction rewards must be suppressed')
   if self.fail then error('injected city setter failure') end
   self.buildings[b]=n;counters.cityWrites=counters.cityWrites+1
   Events.SpecificCityInfoDirty.Fire(self.owner,self.id,0)
 end
 Players[owner].cities[id]=c;plots[id]={GetPlotCity=function() return c end}
 return c
end
Map={GetPlot=function(x,y) return plots[x] end}
function NewUnit(id,owner,domain,combat,ranged)
 local u={id=id,owner=owner,domain=domain or 0,combat=combat or 20,ranged=ranged or 0,promotions={}}
 function u:GetID() return self.id end
 function u:GetOwner() return self.owner end
 function u:GetDomainType() return self.domain end
 function u:GetUnitCombatType() return (self.combat>0 or self.ranged>0) and 1 or -1 end
 function u:GetBaseCombatStrength() return self.combat end
 function u:GetBaseRangedCombatStrength() return self.ranged end
 function u:IsHasPromotion(id) return self.promotions[id]==true end
 function u:SetHasPromotion(id,value) self.promotions[id]=value;counters.unitWrites=counters.unitWrites+1 end
 Players[owner].units[id]=u;return u
end
function NewContext()
 ContextPtr={SetShutdown=function(self,fn) self.shutdown=fn end}
 __UNRUNG_CONTROLLER=nil
end
function Read(id)
 local values={};for n in string.gmatch(saves['UNRUNG_STATE_V1_'..(id or 0)] or '', '[^|]+') do values[#values+1]=tonumber(n) end
 return {version=values[1],peace=values[2],war=values[3],toll=values[4],windows=values[5],lastBegin=values[6],lastDone=values[7],blocked=values[8],skipBegin=values[9]}
end
function Begin() Players[0].active=true;GameEvents.PlayerDoTurn.Fire(0) end
function Done() Players[0].active=false;GameEvents.PlayerDoneTurn.Fire(0) end
function Turn() Begin();Done();now=now+1 end
function PeaceTurns(n) for i=1,n do Turn() end end
function WarWith(id,value,reverse)
 local a,b=0,id;if reverse then a,b=b,a end
 Teams[a].wars[b]=value
 Events.WarStateChanged.Fire(a,b,value)
 -- Native second setAtWar publishes a duplicate from the reverse side.
 Teams[b].wars[a]=value
 Events.WarStateChanged.Fire(b,a,value)
end
function CheckCity(c,n,science)
 for i=1,3 do
   assert(c:GetNumRealBuilding(110+i)==(n>=i and 1 or 0),'city Culture tier '..i)
   assert(c:GetNumRealBuilding(120+i)==(science>=i and 1 or 0),'city Science tier '..i)
 end
end
function CheckUnit(u,strength)
 for i=1,3 do assert(u:IsHasPromotion(130+i)==(strength==i),'unit Toll tier '..i) end
end
NewContext()
