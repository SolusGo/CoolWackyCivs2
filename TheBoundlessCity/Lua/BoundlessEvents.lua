local B=MapModData.BoundlessCity
local queued={};local updateContext=ContextPtr
local armed=false
-- A dirty event schedules ONE callback. The callback removes itself before running.
-- This is deferred dispatch after the native action, never an idle/frame polling loop.
function B.Schedule(pid,force)
 if not B.IsBoundless(pid) or B.Busy[pid] then return end
 if force then B.Cache(B.State(pid)).force=true end
 queued[pid]=true
 if armed then return end
 armed=true
 updateContext:SetUpdate(function()
  updateContext:SetUpdate(nil);armed=false;local pending=queued;queued={}
  for _,id in ipairs(B.Keys(pending)) do
   local s=B.State(id);B.RecoverCities(s);B.ProcessSieges(s);B.Registry(s);B.Reconcile(s)
  end
 end)
end
local function hook(name,fn)
 if GameEvents[name] and GameEvents[name].Add then GameEvents[name].Add(fn)
 else print('[BoundlessCity] Missing CP hook: '..name) end
end
function B.NoCapture(pid,unit)
 if unit then local id=B.ID('PROMOTION_BC_NO_CAPTURE');local value=B.IsBoundless(pid)
  if unit:IsHasPromotion(id)~=value then unit:SetHasPromotion(id,value) end
 end
end
function B.Initialize(pid)
 local s=B.State(pid);local city=Players[pid]:GetCapitalCity()
 if not s.incompatible and not s.capital and city and city:GetOriginalOwner()==pid and city:IsOriginalCapital() then
  s.capital={x=city:GetX(),y=city:GetY(),founded=city:GetGameTurnFounded()}
  city:SetName(B.Text('CAPITAL'),false);B.Save(s)
 end
 for unit in Players[pid]:Units() do B.NoCapture(pid,unit) end
 if not s.incompatible then B.Ownership(s);B.Registry(s) end
 if s.incompatible then
  for owned in Players[pid]:Cities() do pcall(B.ApplyLedger,owned,{},{}) end
 else B.Reconcile(s) end
 if s.incompatible then B.Notify(s,'DISABLED') end
 return s
end
function B.RecoverCities(s)
 local player=Players[s.pid];local extras={}
 if player:GetNumCities()==0 or (player:GetNumCities()==1 and B.City(s)) then return end
 for city in player:Cities() do
  local nativeOriginal=s.incompatible and city:GetOriginalOwner()==s.pid and city:IsOriginalCapital()
  if not nativeOriginal and (not s.capital or city:GetX()~=s.capital.x or city:GetY()~=s.capital.y or city:GetGameTurnFounded()~=s.capital.founded) then
   extras[#extras+1]={x=city:GetX(),y=city:GetY(),founded=city:GetGameTurnFounded(),previous=city:GetPreviousOwner(),original=city:GetOriginalOwner()}
  end
 end
 for _,r in ipairs(extras) do
  local plot=Map.GetPlot(r.x,r.y);local city=plot and plot:GetPlotCity()
  if city and city:GetOwner()==s.pid and city:GetGameTurnFounded()==r.founded then
   local recipient
   local n=plot:GetPlotIndex();local prior=(s.returned or {})[n]
   local function legal(id)
    if type(id)~='number' or id<0 or id==s.pid or id>=(GameDefines.MAX_CIV_PLAYERS or 64) then return false end
    local p=Players[id]
    return p and p:IsAlive() and not p:IsBarbarian() and not B.IsBoundless(id)
     and not (prior and prior.founded==r.founded and prior.recipient==id)
   end
   for _,id in ipairs({r.previous,r.original}) do if legal(id) then recipient=id;break end end
   if not recipient then
    local native=player:GetPlayerToLiberate(city)
    if legal(native) and player:CanLiberatePlayer(native) then recipient=native end
   end
   if recipient then
    -- Outside acquireCity's capture hook: coordinate records are resolved fresh each time.
    s.returned=s.returned or {};s.returned[n]={founded=r.founded,recipient=recipient};B.Save(s)
    Players[recipient]:AcquireCity(city,false,true)
    B.Notify(s,'RECOVERY');s.pending[n]=nil
   else
    if B.NativeRazable(city) then
     local released={};local cityID=city:GetID()
     for _,index in ipairs(B.Keys(B.Ownership(s).owned)) do local tile=Map.GetPlotByIndex(index)
      if tile:GetOwner()==s.pid and tile:GetCityPurchaseID()==cityID then released[#released+1]=index end
     end
     player:Disband(city)
     for _,index in ipairs(released) do local tile=Map.GetPlotByIndex(index)
      if tile:GetOwner()==s.pid then tile:SetOwner(-1,-1,true) end
     end
     s.pending[n]=nil;B.Notify(s,'EXTRA_REMOVED')
    else
     if not s.pending[n] then B.Notify(s,'QUARANTINE');print('[BoundlessCity] Extra city quarantined: no historical legal recipient at '..r.x..','..r.y) end
     s.pending[n]={x=r.x,y=r.y,founded=r.founded}
     city:DoTask(TaskTypes.TASK_CLEAR_ORDERS,-1,-1,0)
     city:DoTask(TaskTypes.TASK_SET_AUTOMATED_PRODUCTION,-1,-1,0)
    end
   end
  end
 end
 for n in pairs(s.pending or {}) do local p=Map.GetPlotByIndex(n);local c=p and p:GetPlotCity()
  if not c or c:GetOwner()~=s.pid then s.pending[n]=nil end
 end
 B.Save(s)
end
function B.Turn(pid)
 if not B.IsBoundless(pid) then return end
 local s=B.Initialize(pid)
 B.RecoverCities(s)
 if s.incompatible or not B.City(s) or s.lastTurn==B.Now() then return end
 s.lastTurn=B.Now()
 local settlers={}
 for unit in Players[pid]:Units() do
  local row=GameInfo.Units[unit:GetUnitType()]
  if s.capital and row and (row.Found==true or row.Found==1 or row.FoundAbroad==true or row.FoundAbroad==1) then settlers[#settlers+1]=unit end
 end
 for _,unit in ipairs(settlers) do unit:Kill(false,-1) end
 if not Players[pid]:IsHuman() then
  s.mode='AUTO'
  local city=B.City(s)
  s.priority=city:FoodDifference()<=2 and 'FOOD' or Players[pid]:GetNumMilitaryUnits()<3 and 'PRODUCTION' or 'BALANCED'
 end
 B.Busy[pid]=true;B.Expand(s);B.Busy[pid]=nil
 B.Cache(s).force=true;B.Reconcile(s);B.AIWorkers(s)
 if not Players[pid]:IsHuman() then for _,r in ipairs(B.SiegeRows(s)) do B.QueueSiege(s,r.n) end end
 B.Save(s)
end
include('BoundlessSiege')
include('BoundlessAI')
hook('PlayerDoTurn',B.Turn)
hook('PlayerDoneTurn',function(pid) if B.IsBoundless(pid) then
 -- Refresh forced reservations even after an otherwise invisible native city reset.
 B.Cache(B.State(pid)).force=true;B.Reconcile(B.State(pid));B.Save(B.State(pid))
end end)
hook('PlayerCanFoundCity',function(pid)
 if not B.IsBoundless(pid) then return true end
 local s=B.State(pid);return not s.incompatible and not s.capital and Players[pid]:GetNumCities()==0
end)
hook('PlayerCanTrain',function(pid,kind)
 if not B.IsBoundless(pid) then return true end
 local row=GameInfo.Units[kind]
 return not (row and (row.Found==1 or row.Found==true or row.FoundAbroad==1 or row.FoundAbroad==true))
end)
hook('CityCanTrain',function(pid,id)
 if not B.IsBoundless(pid) then return true end
 local c=B.City(B.State(pid));return c and c:GetID()==id or false
end)
hook('CityCanConstruct',function(pid,id,building)
 local row=GameInfo.Buildings[building]
 if row and row.Type:match('^BUILDING_BC_REGISTRY_%d+$') then return false end
 if not B.IsBoundless(pid) then return true end
 local c=B.City(B.State(pid));return c and c:GetID()==id or false
end)
local function originalProduction(pid,id)
 if not B.IsBoundless(pid) then return true end
 local c=B.City(B.State(pid));return c and c:GetID()==id or false
end
hook('CityCanCreate',originalProduction)
hook('CityCanMaintain',originalProduction)
hook('PlayerCanBuyOut',function(pid) return not B.IsBoundless(pid) end)
hook('PlayerCityFounded',function(pid,x,y)
 local plot=Map.GetPlot(x,y)
 if plot then plot:SetScriptData((plot:GetScriptData() or ''):gsub('|BCY1:[^|]*|',''):gsub('|BCY2:[^|]*|','')) end
 if B.IsBoundless(pid) then B.Initialize(pid);B.Schedule(pid) end
end)
hook('UnitCreated',function(pid,id)
 local u=Players[pid] and Players[pid]:GetUnitByID(id)
 if u then B.UnitPositions[pid..':'..id]=Map.GetPlot(u:GetX(),u:GetY()):GetPlotIndex() end
 if B.IsBoundless(pid) then B.NoCapture(pid,Players[pid]:GetUnitByID(id)) end
end)
hook('UnitConverted',function(old,new,oldID,newID)
 local unit=Players[new] and Players[new]:GetUnitByID(newID)
 if B.IsBoundless(old) or B.IsBoundless(new) then B.NoCapture(new,unit) end
end)
hook('CityCaptureComplete',function(old,capital,x,y,new)
 -- DO NOT AcquireCity, Kill, raze or liberate from this callback. The DLL still
 -- dereferences the new city object after invoking it.
 if B.IsBoundless(old) or B.IsBoundless(new) then
  -- acquireCity rebuilds the city's native yield sources; it does not copy this
  -- Lua-added miscellaneous source. Plot ScriptData survives, so retire that
  -- old-object ledger without subtracting it from the freshly created city.
  local plot=Map.GetPlot(x,y)
  if plot then plot:SetScriptData((plot:GetScriptData() or ''):gsub('|BCY1:[^|]*|',''):gsub('|BCY2:[^|]*|','')) end
 end
 if B.IsBoundless(old) then
  local s=B.State(old)
  if s.capital and s.capital.x==x and s.capital.y==y then
   s.reserved=0;s.withdrawn=0;s.assignments={};B.Index(s)
  end
  B.Save(s);B.Schedule(old)
 end
 if B.IsBoundless(new) then B.Schedule(new) end
end)
hook('TileOwnershipChanged',function(x,y,new,old)
 local p=Map.GetPlot(x,y);if not p then return end
 for _,pid in ipairs({old,new}) do
  if B.IsBoundless(pid) then
   local s=B.State(pid);local c=B.Cache(s)
   c.owned[p:GetPlotIndex()]=new==pid and true or nil;c.territoryDirty=true;c.aiDirty=true
   if new~=pid then s.selected[p:GetPlotIndex()]=nil;s.locks[p:GetPlotIndex()]=nil;s.excluded[p:GetPlotIndex()]=nil;if c.blocked then c.blocked[p:GetPlotIndex()]=nil end end
   B.Trim(s);B.Schedule(pid,true)
  end
 end
 -- An enemy tile becoming unowned can open the frontier without changing our owned set.
 B.Neighbors(p,function(q)
  local pid=q:GetOwner()
  if B.IsBoundless(pid) then local cache=B.Cache(B.State(pid))
   if cache.connected and cache.connected[q:GetPlotIndex()] then cache.frontier[p:GetPlotIndex()]=new==-1 and not p:IsCity() and true or nil end
  end
 end)
end)
hook('PlayerBuilt',function(pid,uid,x,y,buildID)
 if not B.IsBoundless(pid) then return end
 local s=B.State(pid);local c=B.City(s);local p=Map.GetPlot(x,y)
 local unit=Players[pid]:GetUnitByID(uid);local build=GameInfo.Builds[buildID]
 if not s.incompatible and c and p and unit and unit:GetUnitType()==B.ID('UNIT_BC_SURVEYOR')
  and build and build.ImprovementType and not (build.Repair==true or build.Repair==1)
  and p:GetOwner()==pid and p:GetImprovementType()==B.ID(build.ImprovementType)
  and Map.PlotDistance(c:GetX(),c:GetY(),x,y)>5 and not s.rewards[p:GetPlotIndex()] then
  s.rewards[p:GetPlotIndex()]=true -- Persist before awarding; repairs/replacements/reloads cannot re-award.
  B.Save(s);Players[pid]:ChangeJONSCulture(5)
 end
 B.Schedule(pid,true)
end)
local function changedPlot(x,y,owner)
 if B.IsBoundless(owner) then local s=B.State(owner);B.Cache(s).aiDirty=true
  B.Trim(s,{[Map.GetPlot(x,y):GetPlotIndex()]=true});B.Schedule(owner,true)
 end
end
hook('TileImprovementChanged',changedPlot)
hook('TileFeatureChanged',changedPlot)
hook('TileRouteChanged',changedPlot)
hook('SetPopulation',function(x,y)
 local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
 if city and B.IsBoundless(city:GetOwner()) then B.Trim(B.State(city:GetOwner()));B.Schedule(city:GetOwner()) end
end)
hook('TeamTechResearched',function(team)
 for _,pid in ipairs(B.Players) do if Players[pid]:GetTeam()==team then B.Schedule(pid,true) end end
end)
hook('CityConstructed',function(pid) if B.IsBoundless(pid) then B.Trim(B.State(pid));B.Schedule(pid,true) end end)
hook('PlayerAdoptPolicy',function(pid) if B.IsBoundless(pid) then B.Trim(B.State(pid));B.Schedule(pid,true) end end)
if Events.SerialEventCityInfoDirty then Events.SerialEventCityInfoDirty.Add(function()
 for _,pid in ipairs(B.Players) do B.Trim(B.State(pid));B.Schedule(pid) end
end) end
function B.Movement(pid,uid,x,y)
 if #B.Players==0 then return end
 local unit=Players[pid] and Players[pid]:GetUnitByID(uid)
 if unit and (B.IsBoundless(pid) or unit:IsHasPromotion(B.ID('PROMOTION_BC_NO_CAPTURE'))) then B.NoCapture(pid,unit) end
 local key=pid..':'..uid;local p=Map.GetPlot(x,y);local old=B.UnitPositions[key]
 B.UnitPositions[key]=p and p:GetPlotIndex() or nil
 local affected={}
 local function watch(q)
  local n=q:GetPlotIndex()
  for id in pairs(B.Watch[n] or {}) do affected[id]=affected[id] or {};affected[id][n]=true end
 end
 if p then watch(p);B.Neighbors(p,watch) end
 local prior=old and Map.GetPlotByIndex(old)
 if prior then watch(prior);B.Neighbors(prior,watch) end
 for _,id in ipairs(B.Keys(affected)) do
  if Players[pid] and Teams[Players[id]:GetTeam()]:IsAtWar(Players[pid]:GetTeam()) then
   local s=B.State(id)
   local eligibilityChanged=B.RefreshEligibility(s,affected[id])
   local yieldsChanged=B.Trim(s,affected[id])
   if eligibilityChanged or yieldsChanged then B.Schedule(id,true) end
  end
 end
end
hook('UnitSetXY',B.Movement)
local function warChanged()
 -- CP dispatches player/team/bool or vanilla team/team under the same name.
 for _,pid in ipairs(B.Players) do B.Trim(B.State(pid));B.Schedule(pid,true) end
end
hook('DeclareWar',warChanged)
hook('MakePeace',warChanged)
if Events.LoadScreenClose then Events.LoadScreenClose.Add(function()
 for _,pid in ipairs(B.Players) do B.Initialize(pid);B.Schedule(pid) end
end) end
