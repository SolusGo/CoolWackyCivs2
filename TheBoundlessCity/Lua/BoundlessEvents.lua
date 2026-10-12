local B=MapModData.BoundlessCity
local queued={};local updateContext=ContextPtr
-- A dirty event schedules ONE callback. The callback removes itself before running.
-- This is deferred dispatch after the native action, never an idle/frame polling loop.
function B.Schedule(pid,force)
 if not B.IsBoundless(pid) or B.Busy[pid] then return end
 if force then B.Cache(B.State(pid)).force=true end
 queued[pid]=true
 updateContext:SetUpdate(function()
  updateContext:SetUpdate(nil);local pending=queued;queued={}
  for _,id in ipairs(B.Keys(pending)) do
   B.RecoverCities(B.State(id));B.Registry(B.State(id));B.Reconcile(B.State(id))
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
 if not s.incompatible and not s.capital and city and city:GetOriginalOwner()==pid then
  s.capital={x=city:GetX(),y=city:GetY(),founded=city:GetGameTurnFounded()}
  city:SetName(B.Text('CAPITAL'),false);B.Save(s)
 end
 for unit in Players[pid]:Units() do B.NoCapture(pid,unit) end
 if not s.incompatible then B.Ownership(s);B.Registry(s) end
 B.Reconcile(s)
 if s.incompatible then B.Notify(s,'DISABLED') end
 return s
end
function B.RecoverCities(s)
 local player=Players[s.pid];local extras={}
 for city in player:Cities() do
  if not s.capital or city:GetX()~=s.capital.x or city:GetY()~=s.capital.y or city:GetGameTurnFounded()~=s.capital.founded then
   extras[#extras+1]={x=city:GetX(),y=city:GetY(),founded=city:GetGameTurnFounded(),previous=city:GetPreviousOwner(),original=city:GetOriginalOwner()}
  end
 end
 for _,r in ipairs(extras) do
  local plot=Map.GetPlot(r.x,r.y);local city=plot and plot:GetPlotCity()
  if city and city:GetOwner()==s.pid and city:GetGameTurnFounded()==r.founded then
   local recipient
   for _,id in ipairs({r.previous,r.original}) do
    local p=Players[id]
    if id~=s.pid and p and p:IsAlive() and not p:IsBarbarian() and not B.IsBoundless(id) then recipient=id;break end
   end
   if not recipient then
    for id=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[id]
     if id~=s.pid and p and p:IsAlive() and not p:IsBarbarian() and not B.IsBoundless(id) then recipient=id;break end
    end
   end
   if recipient then
    -- Outside acquireCity's capture hook: coordinate records are resolved fresh each time.
    Players[recipient]:AcquireCity(city,false,true)
    B.Notify(s,'RECOVERY');s.pending[plot:GetPlotIndex()]=nil
   else
    local n=plot:GetPlotIndex()
    if not s.pending[n] then B.Notify(s,'QUARANTINE') end
    s.pending[n]={x=r.x,y=r.y,founded=r.founded}
    print('[BoundlessCity] No legal living custodian for extra city '..r.x..','..r.y..'; blocked, never killed')
   end
  end
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
 B.Cache(s).force=true;B.Reconcile(s);B.AIWorkers(s);B.Save(s)
end
function B.AIWorkers(s)
 if Players[s.pid]:IsHuman() then return end
 -- Native builder AI can overlook distant land. Give idle Surveyors deterministic missions
 -- on the same land area, using real pathfinding and legal native build checks.
 local claimed={};local tasks={}
 for unit in Players[s.pid]:Units() do
  if unit:GetUnitType()==B.ID('UNIT_BC_SURVEYOR') and unit:MovesLeft()>0 and not unit:IsBusy() then
   local best,bestBuild,value
   for _,n in ipairs(B.Keys(B.Ownership(s).owned)) do local p=Map.GetPlotByIndex(n)
    if B.Eligible(s,p) and not p:IsWater() and p:GetArea()==unit:GetPlot():GetArea()
     and not claimed[n] and (p:GetImprovementType()<0 or p:IsImprovementPillaged()) then
     for build in GameInfo.Builds() do
      if (build.ImprovementType or build.Repair==true or build.Repair==1) and unit:CanBuild(p,build.ID,0,1) then
       local score=B.Score(s,p)+ (s.assignments[n] and 20 or 0)-Map.PlotDistance(unit:GetX(),unit:GetY(),p:GetX(),p:GetY())
       if not value or score>value or (score==value and n<best:GetPlotIndex()) then best=p;bestBuild=build.ID;value=score end
      end
     end
    end
   end
   if best then
    claimed[best:GetPlotIndex()]=true
    tasks[#tasks+1]={unit=unit,plot=best,build=bestBuild}
   end
  end
 end
 for _,r in ipairs(tasks) do
  if r.unit:GetX()==r.plot:GetX() and r.unit:GetY()==r.plot:GetY() then
   r.unit:PushMission(MissionTypes.MISSION_BUILD,r.build,-1,0,0,0)
  else r.unit:PushMission(MissionTypes.MISSION_MOVE_TO,r.plot:GetX(),r.plot:GetY(),0,0,0) end
 end
end
hook('PlayerDoTurn',B.Turn)
hook('PlayerDoneTurn',function(pid) if B.IsBoundless(pid) then B.Reconcile(B.State(pid));B.Save(B.State(pid)) end end)
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
hook('PlayerCanBuyOut',function(pid) return not B.IsBoundless(pid) end)
hook('PlayerCityFounded',function(pid) if B.IsBoundless(pid) then B.Initialize(pid);B.Schedule(pid) end end)
hook('UnitCreated',function(pid,id)
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
  if plot then plot:SetScriptData((plot:GetScriptData() or ''):gsub('|BCY1:[^|]*|','')) end
 end
 if B.IsBoundless(old) then
  local s=B.State(old);s.reserved=0;s.assignments={};B.Save(s);B.Schedule(old)
 end
 if B.IsBoundless(new) then B.Schedule(new) end
end)
hook('TileOwnershipChanged',function(x,y,new,old)
 local p=Map.GetPlot(x,y);if not p then return end
 for _,pid in ipairs({old,new}) do
  if B.IsBoundless(pid) then
   local s=B.State(pid);local c=B.Cache(s)
   c.owned[p:GetPlotIndex()]=new==pid and true or nil;c.territoryDirty=true;B.Trim(s);B.Schedule(pid,true)
  end
 end
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
hook('TileImprovementChanged',function(x,y,owner) B.Schedule(owner,true) end)
hook('TileFeatureChanged',function(x,y,owner) B.Schedule(owner,true) end)
hook('TileRouteChanged',function(x,y,owner) B.Schedule(owner,true) end)
hook('SetPopulation',function(x,y)
 local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
 if city and B.IsBoundless(city:GetOwner()) then B.Trim(B.State(city:GetOwner()));B.Schedule(city:GetOwner()) end
end)
hook('TeamTechResearched',function(team)
 for _,pid in ipairs(B.Players) do if Players[pid]:GetTeam()==team then B.Schedule(pid,true) end end
end)
hook('CityConstructed',function(pid) B.Schedule(pid,true) end)
hook('PlayerAdoptPolicy',function(pid) B.Schedule(pid,true) end)
if Events.SerialEventCityInfoDirty then Events.SerialEventCityInfoDirty.Add(function()
 for _,pid in ipairs(B.Players) do B.Trim(B.State(pid));B.Schedule(pid) end
end) end
hook('UnitSetXY',function(pid,uid,x,y)
 for _,id in ipairs(B.Players) do local s=B.State(id)
  for _,r in pairs(s.assignments or {}) do
   if Map.PlotDistance(r.x,r.y,x,y)<=1 then B.Trim(s);B.Schedule(id,true);break end
  end
 end
end)
if Events.LoadScreenClose then Events.LoadScreenClose.Add(function()
 for _,pid in ipairs(B.Players) do B.Initialize(pid);B.Schedule(pid) end
end) end
