-- Deliberately models only the verified CP route/City APIs used by PigeonTrade.
GameInfoTypes={CIVILIZATION_PIGEON_REPUBLIC=100,BUILDING_PIGEON_ROUTE_SCIENCE=101,
 BUILDING_PIGEON_ROUTE_CULTURE=102,BUILDING_PIGEON_ROOST_PRODUCTION=103,
 BUILDING_PIGEON_ROOFTOP_ROOST=104,ERA_RENAISSANCE=3,UNIT_CARAVAN=105,UNIT_CARGO_SHIP=106}
DomainTypes={DOMAIN_LAND=2,DOMAIN_SEA=0}
GameDefines={MAX_CIV_PLAYERS=8}
Players={}
GameEvents={}; Events={}
local function event()
 local handlers={}
 return {Add=function(fn) handlers[#handlers+1]=fn end,
 Fire=function(...) for _,fn in ipairs(handlers) do fn(...) end end,
 Count=function() return #handlers end}
end
NewTestEvent=event
for _,name in ipairs({'PlayerDoTurn','PlayerTradeRouteCompleted','PlayerPlunderedTradeRoute',
 'TeamSetEra','CityConstructed','CitySoldBuilding','CityCaptureComplete','UnitPrekill'}) do GameEvents[name]=event() end
for _,name in ipairs({'SerialEventGameDataDirty','WarStateChanged','LoadScreenClose'}) do Events[name]=event() end
ContextPtr={callback=nil,arms=0,clears=0}
function ContextPtr:SetUpdate(fn) self.callback=fn;self.arms=self.arms+1 end
function ContextPtr:ClearUpdate() self.callback=nil;self.clears=self.clears+1 end
function FlushPigeons()
 local loops=0
 while ContextPtr.callback do
  loops=loops+1;assert(loops<5,'dispatcher did not detach')
  ContextPtr.callback()
 end
end
function NewPlayer(id,isPigeon)
 local p={id=id,civ=isPigeon and 100 or 1,alive=true,era=2,team=id,cities={},routes={},reads=0}
 function p:GetCivilizationType() return self.civ end
 function p:IsAlive() return self.alive end
 function p:GetCurrentEra() return self.era end
 function p:GetTeam() return self.team end
 function p:GetCityByID(cityID) return self.cities[cityID] end
 function p:GetTradeRoutes() self.reads=self.reads+1;return self.routes end
 function p:Cities()
  local keys={};for k in pairs(self.cities) do keys[#keys+1]=k end;table.sort(keys)
  local n=0
  return function() n=n+1;return self.cities[keys[n]] end
 end
 Players[id]=p;return p
end
function NewCity(p,id)
 local c={id=id,owner=p.id,buildings={},writes=0,deleted=false}
 function c:GetOwner() assert(not self.deleted,'deleted City accessed');return self.owner end
 function c:GetID() assert(not self.deleted,'deleted City accessed');return self.id end
 function c:GetNumRealBuilding(b) assert(not self.deleted,'deleted City accessed');return self.buildings[b] or 0 end
 function c:GetNumBuilding(b) return self:GetNumRealBuilding(b) end
 function c:SetNumRealBuilding(b,n,noBonus)
  assert(not self.deleted,'deleted City written');assert(n>=0 and n==math.floor(n));assert(noBonus==true)
  self.buildings[b]=n;self.writes=self.writes+1
  Events.SerialEventGameDataDirty.Fire() -- reentrancy from native yield recalculation
 end
 p.cities[id]=c;return c
end
function Route(p,c,domain,toID,kind)
 return {FromID=p.id,FromCity=c,Domain=domain or DomainTypes.DOMAIN_LAND,
  FromCityName='Identical city name',ToCityName='Identical city name',ToID=toID or 2,
  TradeConnectionType=kind or 0}
end
function CheckCity(c,sci,cult,prod)
 assert(c:GetNumRealBuilding(101)==sci,'science mismatch')
 assert(c:GetNumRealBuilding(102)==cult,'culture mismatch')
 assert(c:GetNumRealBuilding(103)==prod,'production mismatch')
end
PigeonTestLogs={}
print=function(message) PigeonTestLogs[#PigeonTestLogs+1]=message end
