-- A single UI addin owns the simulation for every Boundless player, human or AI.
if __BOUNDLESS_CITY_LOADED then return end
__BOUNDLESS_CITY_LOADED=true
MapModData.BoundlessCity={States={},Caches={},Busy={},Players={}}
local B=MapModData.BoundlessCity
B.ID=function(name) return GameInfoTypes[name] end
B.Text=function(key,...) return Locale.ConvertTextKey('TXT_KEY_BC_'..key,...) end
B.Now=function() return Game.GetGameTurn() end
B.Keys=function(t) local a={};for k in pairs(t) do a[#a+1]=k end;table.sort(a);return a end
B.Config={BaseCost=20,TileCost=.20,RootCost=2.5,EraCost=.05,RegistryDiscount=.15,PageSize=16}
B.Weights={BALANCED={3,3,2,3,3,2},FOOD={8,2,1,2,2,1},PRODUCTION={3,8,1,2,2,1},GOLD={3,2,8,2,2,1}}
B.Yields={}
for _,name in ipairs({'FOOD','PRODUCTION','GOLD','SCIENCE','CULTURE','FAITH'}) do
 local id=B.ID('YIELD_'..name);if id then B.Yields[#B.Yields+1]={id=id,name=name} end
end
function B.IsBoundless(pid)
 local p=Players[pid]
 return p and p:GetCivilizationType()==B.ID('CIVILIZATION_BOUNDLESS_CITY')
  and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
end
function B.Cache(s)
 local c=B.Caches[s.pid]
 if not c then c={owned={},count=0,territoryDirty=true};B.Caches[s.pid]=c end
 return c
end
function B.City(s)
 if not s.capital then return end
 local p=Map.GetPlot(s.capital.x,s.capital.y);local c=p and p:GetPlotCity()
 if c and c:GetOwner()==s.pid and c:GetOriginalOwner()==s.pid and c:IsOriginalCapital()
  and c:GetGameTurnFounded()==s.capital.founded then return c end
end
function B.Notify(s,key)
 if Players[s.pid]:IsHuman() then Players[s.pid]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,B.Text(key),B.Text('WORKFORCE'),-1,-1) end
end
function B.Neighbors(p,fn)
 local seen={}
 for dir=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),dir)
  if q and not seen[q:GetPlotIndex()] then seen[q:GetPlotIndex()]=true;fn(q) end
 end
end
function B.Ownership(s)
 local cache=B.Cache(s)
 if not cache.initialized then
  for n=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(n)
   if p:GetOwner()==s.pid then cache.owned[n]=true end
  end
  cache.initialized=true;cache.territoryDirty=true
 end
 if not cache.territoryDirty then return cache end
 cache.count=0;for n in pairs(cache.owned) do local p=Map.GetPlotByIndex(n)
  if p and p:GetOwner()==s.pid then cache.count=cache.count+1 else cache.owned[n]=nil end
 end
 -- Only capital-connected territory can seed frontier expansion. Citadel islands cannot seed it.
 cache.frontier={};cache.connected={};local city=B.City(s)
 if city then
  local start=Map.GetPlot(city:GetX(),city:GetY());local queue={start};cache.connected[start:GetPlotIndex()]=true
  local head=1
  while head<=#queue do local p=queue[head];head=head+1
   B.Neighbors(p,function(q)
    local n=q:GetPlotIndex()
    if q:GetOwner()==s.pid and not cache.connected[n] then cache.connected[n]=true;queue[#queue+1]=q
    elseif q:GetOwner()==-1 and not q:IsCity() then cache.frontier[n]=true end
   end)
  end
 end
 cache.territoryDirty=false;return cache
end
function B.PlotYields(p)
 local result={};for i,y in ipairs(B.Yields) do result[i]=p:GetYield(y.id) end;return result
end
function B.Score(s,p)
 local score=0;local weights=B.Weights[s.priority] or B.Weights.BALANCED
 for i,y in ipairs(B.Yields) do score=score+p:GetYield(y.id)*weights[i] end
 return score
end
function B.Cost(s)
 local city=B.City(s);local n=B.Ownership(s).count
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
 local factor=(speed and speed.CulturePercent or 100)/100
 local value=(B.Config.BaseCost+B.Config.RootCost*math.sqrt(n)+B.Config.TileCost*n)
  *(1+B.Config.EraCost*Players[s.pid]:GetCurrentEra())*factor
 if city and city:GetNumBuilding(B.ID('BUILDING_BC_REGISTRY'))>0 then value=value*(1-B.Config.RegistryDiscount) end
 return math.max(1,math.floor(value+.5))
end
function B.FrontierScore(s,p)
 local city=B.City(s);local score=B.Score(s,p)
 local resource=p:GetResourceType(Players[s.pid]:GetTeam())
 if resource and resource>=0 then score=score+18 end
 local adjacent=0;B.Neighbors(p,function(q) if q:GetOwner()==s.pid then adjacent=adjacent+1 end end)
 score=score+adjacent*2 -- Compact borders and chokepoints with several owned approaches.
 local distance=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())
 score=score-distance*.12
 local w,h=Map.GetGridSize();local dx=p:GetX()-city:GetX();local dy=p:GetY()-city:GetY()
 if Map.IsWrapX() and math.abs(dx)>w/2 then dx=dx>0 and dx-w or dx+w end
 if Map.IsWrapY() and math.abs(dy)>h/2 then dy=dy>0 and dy-h or dy+h end
 local direction=s.direction
 if direction=='EAST' then score=score+dx/(distance+1)*8
 elseif direction=='WEST' then score=score-dx/(distance+1)*8
 elseif direction=='NORTH' then score=score+dy/(distance+1)*8
 elseif direction=='SOUTH' then score=score-dy/(distance+1)*8 end
 return score
end
function B.Registry(s)
 local city=B.City(s);if not city then return end
 local bonus=city:GetNumBuilding(B.ID('BUILDING_BC_REGISTRY'))>0 and math.min(10,math.floor(B.Ownership(s).count/10)) or 0
 for n=1,10 do local id=B.ID('BUILDING_BC_REGISTRY_'..n);local desired=n<=bonus and 1 or 0
  if city:GetNumRealBuilding(id)~=desired then city:SetNumRealBuilding(id,desired) end
 end
end
function B.Expand(s)
 local city=B.City(s);if not city then return end
 s.progress=s.progress+math.max(0,city:GetJONSCulturePerTurn())
 local cache=B.Ownership(s)
 while s.progress>=B.Cost(s) do
  local best,value
  for _,n in ipairs(B.Keys(cache.frontier)) do local p=Map.GetPlotByIndex(n)
   if p and p:GetOwner()==-1 and not p:IsCity() then
    local score=B.FrontierScore(s,p)
    if not value or score>value then best=p;value=score end
   end
  end
  if not best then break end -- Bank culture until a legal adjacent tile becomes available.
  local cost=B.Cost(s);best:SetOwner(s.pid,city:GetID(),true)
  if best:GetOwner()~=s.pid then break end
  s.progress=s.progress-cost;local n=best:GetPlotIndex()
  cache.owned[n]=true;cache.count=cache.count+1;cache.connected[n]=true;cache.frontier[n]=nil
  B.Neighbors(best,function(q) if q:GetOwner()==-1 and not q:IsCity() then cache.frontier[q:GetPlotIndex()]=true end end)
  cache.territoryDirty=false -- SetOwner's event marks it; this operation has updated the frontier itself.
 end
 B.Registry(s)
end
function B.Eligible(s,p)
 return p and p:GetOwner()==s.pid and not p:IsCity() and p:HasYield()
  and (not p:IsWater() or Teams[Players[s.pid]:GetTeam()]:IsWaterWork())
  and not p:IsVisibleEnemyUnit(s.pid) and not p:IsBlockaded(s.pid)
end
function B.LocalPlots(city)
 local result={}
 for i=1,city:GetNumCityPlots()-1 do local p=city:GetCityIndexPlot(i)
  if p then result[p:GetPlotIndex()]={plot=p,index=i} end
 end
 return result
end
include('BoundlessCitizens')
include('BoundlessPersistence')
include('BoundlessEvents')
for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do
 if B.IsBoundless(pid) then B.Players[#B.Players+1]=pid;B.Initialize(pid) end
end
if #B.Players>0 then
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local player=Players[pid]
  if player and player:IsAlive() then for unit in player:Units() do local plot=Map.GetPlot(unit:GetX(),unit:GetY())
   if plot then B.UnitPositions[pid..':'..unit:GetID()]=plot:GetPlotIndex() end
  end end
 end
end
print('[BoundlessCity] Runtime loaded for '..#B.Players..' player(s); native reservations only')
