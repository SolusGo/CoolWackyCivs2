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
 if c and c:GetOwner()==s.pid and c:GetGameTurnFounded()==s.capital.founded then return c end
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
 return p and p:GetOwner()==s.pid and not p:IsCity() and not p:IsMountain()
  and not p:IsVisibleEnemyUnit(s.pid) and not (p:IsWater() and p:IsBlockaded(s.pid))
end
function B.LocalPlots(city)
 local result={}
 for i=1,city:GetNumCityPlots()-1 do local p=city:GetCityIndexPlot(i)
  if p then result[p:GetPlotIndex()]={plot=p,index=i} end
 end
 return result
end
function B.Ledger(city)
 local plot=Map.GetPlot(city:GetX(),city:GetY())
 local data=plot:GetScriptData() or '';local encoded=data:match('|BCY1:([^|]*)|')
 local result={};local i=1
 if encoded then for n in encoded:gmatch('[^,]+') do result[i]=tonumber(n) or 0;i=i+1 end end
 return result
end
function B.ApplyLedger(city,desired)
 local old=B.Ledger(city);local words={}
 for i,y in ipairs(B.Yields) do
  local delta=(desired[i] or 0)-(old[i] or 0)
  if delta~=0 then city:ChangeBaseYieldRateFromMisc(y.id,delta) end
  words[i]=tostring(desired[i] or 0)
 end
 local plot=Map.GetPlot(city:GetX(),city:GetY())
 local data=(plot:GetScriptData() or ''):gsub('|BCY1:[^|]*|','')
 plot:SetScriptData(data..'|BCY1:'..table.concat(words,',')..'|')
end
function B.Signature(s,city)
 local words={s.mode or '',s.priority or '',s.direction or '',city:GetPopulation(),city:GetTotalSpecialistCount(),
  city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN')),B.Ownership(s).count}
 local locals=B.LocalPlots(city)
 for _,n in ipairs(B.Keys(locals)) do local r=locals[n]
  if city:IsWorkingPlot(r.plot) then words[#words+1]=n..':'..tostring(city:IsForcedWorkingPlot(r.plot)) end
 end
 for _,n in ipairs(B.Keys(s.assignments or {})) do local p=Map.GetPlotByIndex(n)
  words[#words+1]=n..':'..tostring(B.Eligible(s,p))
  if p then for _,y in ipairs(B.Yields) do words[#words+1]=p:GetYield(y.id) end end
 end
 for _,y in ipairs(B.Yields) do words[#words+1]=city:GetSpecialistYield(B.ID('SPECIALIST_CITIZEN'),y.id) end
 return table.concat(words,';')
end
function B.Trim(s)
 -- Remove invalid contributions synchronously without reallocating native citizens.
 -- Used when native population, tile ownership or local assignments change mid-action.
 local city=B.City(s);if not city or B.Busy[s.pid] then return end
 local cache=B.Cache(s);local signature=B.Signature(s,city)
 if cache.trimSignature==signature or cache.signature==signature then return end
 B.Busy[s.pid]=true
 local defaults=city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN'))
 local limit=math.min(s.reserved or 0,defaults,math.max(0,city:GetPopulation()-city:GetTotalSpecialistCount()))
 local total={};for i=1,#B.Yields do total[i]=0 end
 local keep={};local count=0
 for _,n in ipairs(B.Keys(s.assignments or {})) do local p=Map.GetPlotByIndex(n)
  if count<limit and B.Eligible(s,p) and not city:IsWorkingPlot(p) then
   count=count+1;keep[n]=s.assignments[n]
   for i,y in ipairs(B.Yields) do total[i]=total[i]+p:GetYield(y.id) end
  end
 end
 local net,deduct={},{ }
 for i,y in ipairs(B.Yields) do deduct[i]=count*city:GetSpecialistYield(B.ID('SPECIALIST_CITIZEN'),y.id);net[i]=total[i]-deduct[i] end
 B.ApplyLedger(city,net);s.assignments=keep
 -- Keep the number of native reservations until the deferred reallocation releases them.
 -- The credited list can shrink earlier; this never creates an extra citizen.
 cache.remoteYields=total;cache.labourerYields=deduct;cache.trimSignature=B.Signature(s,city);B.Save(s)
 B.Busy[s.pid]=nil
end
function B.Reconcile(s)
 if B.Busy[s.pid] then return end
 local city=B.City(s);if not city then return end
 local cache=B.Cache(s)
 local signature=B.Signature(s,city)
 if not cache.force and cache.signature==signature then return end
 cache.force=nil
 B.Busy[s.pid]=true
 local ok,err=pcall(function()
  B.ApplyLedger(city,{})
  if s.incompatible then return end
  local locals=B.LocalPlots(city);local default=B.ID('SPECIALIST_CITIZEN')
  -- Release only the reservations owned by this system, through the verified native task.
  local release=math.min(s.reserved or 0,city:GetSpecialistCount(default))
  for _=1,release do city:DoTask(TaskTypes.TASK_REMOVE_SLACKER,0,-1,false) end
  s.reserved=0
  local specialist=city:GetTotalSpecialistCount()
  local capacity=math.max(0,city:GetPopulation()-specialist)
  local candidates,selected,remote={},{},{}
  local cache=B.Ownership(s)
  for _,n in ipairs(B.Keys(cache.owned)) do local p=Map.GetPlotByIndex(n)
   if B.Eligible(s,p) and not s.excluded[n] then
    local localPlot=locals[n]
    local locked=s.locks[n] and not localPlot
    local forced=localPlot and city:IsForcedWorkingPlot(p) and s.mode~='AUTO'
    candidates[#candidates+1]={plot=p,n=n,score=B.Score(s,p),locked=locked,forced=forced,localPlot=localPlot}
   end
  end
  table.sort(candidates,function(a,b)
   if a.locked~=b.locked then return a.locked and true or false end
   if a.forced~=b.forced then return a.forced and true or false end
   if a.score~=b.score then return a.score>b.score end;return a.n<b.n
  end)
  if s.mode=='MANUAL' then
   for _,r in ipairs(candidates) do if r.locked and #remote<capacity then remote[#remote+1]=r end end
  else
   for i=1,math.min(capacity,#candidates) do local r=candidates[i];selected[r.n]=true
    if not r.localPlot then remote[#remote+1]=r end
   end
  end
  -- Each reservation is created by unworking a real native plot. No imaginary specialist slots,
  -- negative automatons or population edits. Stop when the native pool cannot be reserved.
  -- This exposes the precise DLL limitation documented in EngineLimitations.md.
  local worked={}
  for _,r in pairs(locals) do if city:IsWorkingPlot(r.plot) then worked[#worked+1]=r end end
  table.sort(worked,function(a,b)
   if selected[a.plot:GetPlotIndex()]~=selected[b.plot:GetPlotIndex()] then return not selected[a.plot:GetPlotIndex()] end
   local x,y=B.Score(s,a.plot),B.Score(s,b.plot);if x~=y then return x<y end;return a.index<b.index
  end)
  local actual={}
  for _,r in ipairs(worked) do
   if #actual>=#remote then break end
   if s.mode=='AUTO' or not city:IsForcedWorkingPlot(r.plot) then
    local before=city:GetSpecialistCount(default)
    city:AlterWorkingPlot(r.index)
    if not city:IsWorkingPlot(r.plot) and city:GetSpecialistCount(default)==before+1 then actual[#actual+1]=remote[#actual+1] end
   end
  end
  s.assignments={};s.reserved=#actual
  local total,deduct={},{ }
  for i,y in ipairs(B.Yields) do total[i]=0;deduct[i]=#actual*city:GetSpecialistYield(default,y.id) end
  for _,r in ipairs(actual) do
   if B.Eligible(s,r.plot) and not city:IsWorkingPlot(r.plot) then
    s.assignments[r.n]={x=r.plot:GetX(),y=r.plot:GetY()}
    for i,y in ipairs(B.Yields) do total[i]=total[i]+r.plot:GetYield(y.id) end
   end
  end
  local count=0;for _ in pairs(s.assignments) do count=count+1 end
  assert(count==s.reserved and city:GetSpecialistCount(default)>=count,'Remote workforce reservation mismatch')
  local net={};for i=1,#B.Yields do net[i]=total[i]-deduct[i] end
  B.ApplyLedger(city,net)
  cache.remoteYields=total;cache.labourerYields=deduct
  B.Save(s)
  cache.signature=B.Signature(s,city)
 end)
 B.Busy[s.pid]=nil
 if not ok then B.ApplyLedger(city,{});error(err,0) end
 if LuaEvents.BoundlessChanged then LuaEvents.BoundlessChanged(s.pid) end
end
function B.Summary(s)
 local city=B.City(s);if not city then return end
 local locals=B.LocalPlots(city);local localCount=0
 for _,r in pairs(locals) do if city:IsWorkingPlot(r.plot) then localCount=localCount+1 end end
 local idle=city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN'))-(s.reserved or 0)
 local credited=0;for _ in pairs(s.assignments or {}) do credited=credited+1 end
 return {population=city:GetPopulation(),owned=B.Ownership(s).count,localCount=localCount,
  remote=credited,specialists=city:GetTotalSpecialistCount(),idle=math.max(0,idle),
  available=localCount,progress=math.floor(s.progress or 0),cost=B.Cost(s)}
end
function B.Action(pid,kind,value)
 if not B.IsBoundless(pid) or Game.GetActivePlayer()~=pid or not Players[pid]:IsHuman()
  or not Players[pid]:IsTurnActive() then return false end
 local s=B.State(pid);if s.incompatible or not B.City(s) then return false end
 if kind=='MODE' and (value=='AUTO' or value=='MANUAL' or value=='HYBRID') then s.mode=value
 elseif kind=='PRIORITY' and B.Weights[value] then s.priority=value
 elseif kind=='DIRECTION' and ({ANY=true,NORTH=true,EAST=true,SOUTH=true,WEST=true})[value] then s.direction=value
 elseif kind=='PLOT' or kind=='LOCK' then
  local p=type(value)=='number' and Map.GetPlotByIndex(value)
  if not B.Eligible(s,p) or B.LocalPlots(B.City(s))[value] then return false end
  if kind=='LOCK' then
   s.locks[value]=not s.locks[value] or nil;s.excluded[value]=nil
   if s.mode=='AUTO' then s.mode='HYBRID' end
  elseif s.assignments[value] or s.locks[value] then
   s.locks[value]=nil;s.excluded[value]=true
  else
   s.excluded[value]=nil;s.locks[value]=true
   if s.mode=='AUTO' then s.mode='HYBRID' end
  end
 else return false end
 B.Cache(s).force=true;B.Reconcile(s);B.Save(s);return true
end
include('BoundlessPersistence')
include('BoundlessEvents')
for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do
 if B.IsBoundless(pid) then B.Players[#B.Players+1]=pid;B.Initialize(pid) end
end
print('[BoundlessCity] Runtime loaded for '..#B.Players..' player(s); native reservations only')
