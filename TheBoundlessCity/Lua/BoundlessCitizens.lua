-- CP v151 reservations: native forced labourers plus a conservative governor-proof surplus.
local B=MapModData.BoundlessCity
B.Watch={};B.UnitPositions={};B.DefaultBase={};B.SlotBuildings={}
for row in GameInfo.SpecialistYields{SpecialistType='SPECIALIST_CITIZEN'} do
 B.DefaultBase[B.ID(row.YieldType)]=row.Yield
end
for row in GameInfo.Buildings() do
 if (row.SpecialistCount or 0)>0 then B.SlotBuildings[#B.SlotBuildings+1]=row end
end
function B.LabourerYield(city,yield)
 local count=city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN'))
 -- GetSpecialistYield incorrectly mixes per-citizen and COUNT-multiplied extras.
 -- Use the database base and the verified native total for this type instead.
 local extra=city:GetExtraSpecialistYieldOfType(yield,B.ID('SPECIALIST_CITIZEN'))
 return (B.DefaultBase[yield] or 0)+(count>0 and extra/count or 0)
end
function B.Census(s,city)
 local a={population=city:GetPopulation(),specialists=city:GetTotalSpecialistCount(),
  defaults=city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN')),localCount=0,localLocked=0,
  localMaximum=0,slotMaximum=0,remote=0,remoteLocked=0,pending=0,locks=0}
 local words={a.population,a.specialists,a.defaults,city:GetAutomatons()}
 local locals=B.LocalPlots(city)
 for _,n in ipairs(B.Keys(locals)) do local r=locals[n]
  -- Count even temporarily blockaded/zero-yield/locked-water owned positions:
  -- peace, improvements or technology can make those native jobs available.
  if r.plot:GetOwner()==s.pid and not r.plot:IsCity() then a.localMaximum=a.localMaximum+1 end
  if city:IsWorkingPlot(r.plot) then
   a.localCount=a.localCount+1
   local forced=city:IsForcedWorkingPlot(r.plot)
   if forced and s.mode~='AUTO' then a.localLocked=a.localLocked+1 end
   words[#words+1]=n..':'..tostring(forced)
  end
 end
 for _,row in ipairs(B.SlotBuildings) do
  if city:GetNumBuilding(row.ID)>0 then
   a.slotMaximum=a.slotMaximum+math.min(row.SpecialistCount,GameDefines.MAX_SPECIALISTS_FROM_BUILDING or row.SpecialistCount)
  end
 end
 a.governorKey=table.concat(words,';')..';'..a.slotMaximum..';'..a.localMaximum
 a.automata=city:GetAutomatons()
 a.unassigned=math.max(0,a.population+a.automata-a.localCount-a.specialists-a.defaults)
 a.surplus=math.max(0,a.population-a.localMaximum-a.slotMaximum)
 a.realDefaults=math.min(a.defaults,math.max(0,a.population-a.localCount-a.specialists))
 -- Unknown external worker-automaton allocation cannot be attributed to ordinary people.
 if city:GetAutomatons()>0 then a.surplus=0;a.realDefaults=0 end
 local cache=B.Cache(s)
 local trusted=cache.governorKey==a.governorKey or cache.governorKey==nil
 local forced=trusted and (s.withdrawn or 0) or 0
 a.protected=math.min(a.realDefaults,math.max(forced,a.surplus))
 for n in pairs(s.assignments or {}) do a.remote=a.remote+1;if s.locks[n] then a.remoteLocked=a.remoteLocked+1 end end
 for n in pairs(s.locks or {}) do
  local p=Map.GetPlotByIndex(n)
  if p and p:GetOwner()==s.pid and not locals[n] then a.locks=a.locks+1 end
 end
 local intents=s.mode=='MANUAL' and s.selected or s.mode=='HYBRID' and s.locks or {}
 for n in pairs(intents or {}) do
  local p=Map.GetPlotByIndex(n)
  if p and p:GetOwner()==s.pid and not locals[n] and not s.assignments[n] then a.pending=a.pending+1 end
 end
 a.idle=math.max(0,a.defaults-a.remote)
 local movable=a.localCount-a.localLocked
 a.maximumRemote=math.min(math.max(0,a.population-a.specialists-a.localLocked),a.realDefaults+movable,math.max(a.surplus,forced+movable))
 if city:GetAutomatons()>0 then a.maximumRemote=0 end
 a.availableRemote=math.max(0,a.maximumRemote-a.remote)
 if cache.eligibleCount then a.availableRemote=math.min(a.availableRemote,math.max(0,cache.eligibleCount-a.remote)) end
 a.availableCitizens=math.max(0,a.population-a.specialists-a.localLocked-(s.mode~='AUTO' and a.remoteLocked or 0))
 if a.automata>0 then a.availableCitizens=0 end
 return a,locals
end
local function vector(text)
 local values={}
 for word in text:gmatch('[^,]+') do
  local n=tonumber(word);assert(n and n==n and math.abs(n)<1e12 and n==math.floor(n),'Invalid Boundless yield ledger')
  values[#values+1]=n
 end
 assert(#values==#B.Yields,'Invalid Boundless yield ledger length');return values
end
function B.Ledger(city)
 local data=Map.GetPlot(city:GetX(),city:GetY()):GetScriptData() or ''
 local misc,terrain=data:match('|BCY2:([^;|]*);([^|]*)|')
 if misc then return vector(misc),vector(terrain) end
 local old=data:match('|BCY1:([^|]*)|')
 if old then return vector(old),{} end
 assert(not data:find('|BCY[12]:'),'Malformed Boundless ledger marker')
 return {},{}
end
local function writeLedger(city,misc,terrain)
 local m,t={},{}
 for i=1,#B.Yields do m[i]=tostring(misc[i] or 0);t[i]=tostring(terrain[i] or 0) end
 local plot=Map.GetPlot(city:GetX(),city:GetY())
 local data=(plot:GetScriptData() or ''):gsub('|BCY1:[^|]*|',''):gsub('|BCY2:[^|]*|','')
 plot:SetScriptData(data..'|BCY2:'..table.concat(m,',')..';'..table.concat(t,',')..'|')
end
function B.ApplyLedger(city,gross,deduct)
 local misc,terrain=B.Ledger(city)
 local terrainChanged={}
 local function mutate(source,i,y,desired)
  local delta=desired-(source.values[i] or 0)
  if delta==0 then return end
  local before=city[source.get](city,y.id)
  local ok,err=pcall(city[source.change],city,y.id,delta)
  local after=city[source.get](city,y.id)
  -- Journal even if a callback raises after a completed native mutation.
  if ok or after==before+delta then source.values[i]=desired;writeLedger(city,misc,terrain) end
  assert(ok,err)
  assert(after==before+delta,'Unexpected native yield-source mutation')
 end
 for _,source in ipairs({{values=terrain,get='GetBaseYieldRateFromTerrain',change='ChangeBaseYieldRateFromTerrain'},
  {values=misc,get='GetBaseYieldRateFromMisc',change='ChangeBaseYieldRateFromMisc',negative=true}}) do
  for i,y in ipairs(B.Yields) do
   local desired=source.negative and -(deduct[i] or 0) or (gross[i] or 0)
   local delta=desired-(source.values[i] or 0)
   if not source.negative and delta~=0 then terrainChanged[i]=true end
   mutate(source,i,y,desired)
   if source.negative and delta==0 and terrainChanged[i] then
    -- Terrain's native setter does NOT update the cached city rate. The misc
    -- setter does, but ignores zero deltas: a journalled net-zero pulse refreshes
    -- that cache without leaving a bonus or changing any unrelated source.
    mutate(source,i,y,desired+1);mutate(source,i,y,desired)
   end
  end
 end
 writeLedger(city,misc,terrain)
end
function B.Index(s)
 local cache=B.Cache(s)
 for n in pairs(cache.watchKeys or {}) do if B.Watch[n] then B.Watch[n][s.pid]=nil;if not next(B.Watch[n]) then B.Watch[n]=nil end end end
 cache.watchKeys={}
 for _,t in ipairs({s.assignments or {},s.selected or {},s.locks or {},cache.blocked or {},cache.remoteFootprint or {}}) do
  for n in pairs(t) do cache.watchKeys[n]=true;B.Watch[n]=B.Watch[n] or {};B.Watch[n][s.pid]=true end
 end
end
function B.RefreshEligibility(s,touched,locals)
 local city=B.City(s);if not city then return false end
 local cache=B.Ownership(s);locals=locals or B.LocalPlots(city)
 local changed=false
 if not touched or not cache.remoteFootprint then
  cache.remoteFootprint={};cache.eligible={};cache.eligibleCount=0
  for n in pairs(cache.owned) do local p=Map.GetPlotByIndex(n)
   if p and p:GetOwner()==s.pid and not locals[n] and not p:IsCity() then
    cache.remoteFootprint[n]=true
    if B.Eligible(s,p) then cache.eligible[n]=true;cache.eligibleCount=cache.eligibleCount+1 end
   end
  end
  changed=true
 else
  for n in pairs(touched) do if cache.remoteFootprint[n] then
   local valid=B.Eligible(s,Map.GetPlotByIndex(n)) and true or nil
   if valid~=cache.eligible[n] then
    cache.eligible[n]=valid;cache.eligibleCount=cache.eligibleCount+(valid and 1 or -1);changed=true
   end
  end end
 end
 if changed then cache.viewRevision=(cache.viewRevision or 0)+1 end
 return changed
end
function B.Totals(s,city)
 local cache=B.Cache(s);local gross,deduct,perPlot={},{},{}
 for i=1,#B.Yields do gross[i]=0 end
 local count=0
 for _,n in ipairs(B.Keys(s.assignments)) do local p=Map.GetPlotByIndex(n)
  local r=s.assignments[n]
  assert(B.Eligible(s,p) and not city:IsWorkingPlot(p) and r.x==p:GetX() and r.y==p:GetY(),'Invalid remote assignment')
  count=count+1;perPlot[n]=B.PlotYields(p)
  for i=1,#B.Yields do gross[i]=gross[i]+perPlot[n][i] end
 end
 for i,y in ipairs(B.Yields) do deduct[i]=count*B.LabourerYield(city,y.id) end
 B.ApplyLedger(city,gross,deduct)
 cache.remoteYields=gross;cache.labourerYields=deduct;cache.perPlot=perPlot
 cache.viewRevision=(cache.viewRevision or 0)+1
 s.reserved=count;B.Index(s)
end
function B.Signature(s,city)
 local census=B.Census(s,city);local words={s.mode,s.priority,s.direction,census.governorKey,B.Ownership(s).count}
 for _,n in ipairs(B.Keys(s.assignments or {})) do local p=Map.GetPlotByIndex(n)
  words[#words+1]=n..':'..tostring(B.Eligible(s,p))
  if p then for _,y in ipairs(B.Yields) do words[#words+1]=p:GetYield(y.id) end end
 end
 for _,y in ipairs(B.Yields) do words[#words+1]=B.LabourerYield(city,y.id) end
 return table.concat(words,';')
end
function B.Trim(s,touched)
 local city=B.City(s);if not city or B.Busy[s.pid] then return end
 local cache=B.Cache(s)
 if s.incompatible then return end
 local scalar=cache.scalar
 if touched and scalar and cache.perPlot and city:GetPopulation()==scalar[1]
  and city:GetTotalSpecialistCount()==scalar[2] and city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN'))==scalar[3] then
  local gross={};for i=1,#B.Yields do gross[i]=cache.remoteYields[i] or 0 end
  local changed=false;local count=s.reserved or 0
  for n in pairs(touched) do if s.assignments[n] then local p=Map.GetPlotByIndex(n)
   local valid=B.Eligible(s,p) and not city:IsWorkingPlot(p)
   local old=cache.perPlot[n] or {};local current=valid and B.PlotYields(p) or {}
   for i=1,#B.Yields do local delta=(current[i] or 0)-(old[i] or 0);gross[i]=gross[i]+delta;if delta~=0 then changed=true end end
   if not valid then
    s.assignments[n]=nil;count=count-1;cache.blocked=cache.blocked or {};cache.blocked[n]=true;cache.perPlot[n]=nil;changed=true
   else cache.perPlot[n]=current end
  end end
  if not changed then return end
  local deduct={};for i,y in ipairs(B.Yields) do deduct[i]=count*B.LabourerYield(city,y.id) end
  B.Busy[s.pid]=true
  local ok,err=pcall(function() B.ApplyLedger(city,gross,deduct);s.reserved=count;cache.remoteYields=gross;cache.labourerYields=deduct;cache.viewRevision=(cache.viewRevision or 0)+1;B.Save(s) end)
  B.Busy[s.pid]=nil
  if not ok then print('[BoundlessCity] Indexed trim failed: '..tostring(err));B.Schedule(s.pid,true) end
  if LuaEvents.BoundlessChanged then LuaEvents.BoundlessChanged(s.pid) end
  return true
 end
 local census=B.Census(s,city)
 -- Full validation only for native census changes; movement checks use indexed plots.
 local keys=touched and cache.governorKey==census.governorKey and B.Keys(touched) or B.Keys(s.assignments)
 local changed=false;local count=census.remote
 for _,n in ipairs(keys) do
  if s.assignments[n] then local p=Map.GetPlotByIndex(n)
   if not B.Eligible(s,p) or city:IsWorkingPlot(p) then
    cache.blocked=cache.blocked or {};if p and p:GetOwner()==s.pid then cache.blocked[n]=true end
    s.assignments[n]=nil;count=count-1;changed=true
   elseif cache.perPlot and cache.perPlot[n] then
    for i,y in ipairs(B.Yields) do if cache.perPlot[n][i]~=p:GetYield(y.id) then changed=true;break end end
   end
  end
 end
 if count>census.protected then
  for _,n in ipairs(B.Keys(s.assignments)) do if count<=census.protected then break end
   s.assignments[n]=nil;count=count-1;changed=true
  end
 end
 if cache.governorKey~=census.governorKey then changed=true end
 for i,y in ipairs(B.Yields) do
  if cache.labourerYields and cache.labourerYields[i]~=count*B.LabourerYield(city,y.id) then changed=true end
 end
 if not changed then return end
 B.Busy[s.pid]=true
 local ok,err=pcall(function() B.Totals(s,city);B.Save(s) end)
 B.Busy[s.pid]=nil
 if not ok then print('[BoundlessCity] Trim failed: '..tostring(err));B.Schedule(s.pid,true) end
 if LuaEvents.BoundlessChanged then LuaEvents.BoundlessChanged(s.pid) end
 return true
end
function B.Reconcile(s)
 if B.Busy[s.pid] then return false end
 local city=B.City(s);if not city then return false end
 local cache=B.Cache(s)
 if s.incompatible then
  local ok,err=pcall(B.ApplyLedger,city,{},{})
  if not ok then print('[BoundlessCity] Cannot remove unverified ledger: '..tostring(err)) end
  return false
 end
 local signature=B.Signature(s,city)
 if not cache.force and cache.signature==signature then return true end
 cache.force=nil;B.Busy[s.pid]=true
 local ok,err=pcall(function()
  s.phase='RECONCILE';s.assignments={};s.reserved=0;B.Save(s)
  B.ApplyLedger(city,{},{})
  local release=math.min(s.withdrawn or 0,city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN')))
  for _=1,release do city:DoTask(TaskTypes.TASK_REMOVE_SLACKER,0,-1,0);s.withdrawn=math.max(0,s.withdrawn-1);B.Save(s) end
  s.withdrawn=0;cache.governorKey=nil
  local census,locals=B.Census(s,city);local candidates,selected,remote={},{},{}
  B.RefreshEligibility(s,nil,locals)
  for _,n in ipairs(B.Keys(B.Ownership(s).owned)) do local p=Map.GetPlotByIndex(n)
   if B.Eligible(s,p) and not s.excluded[n] then
    local r=locals[n];local locked=s.mode~='AUTO' and s.locks[n]==true and not r
    candidates[#candidates+1]={plot=p,n=n,score=B.Score(s,p),locked=locked and true or false,
     forced=(r and city:IsForcedWorkingPlot(p) and s.mode~='AUTO') and true or false,localPlot=r}
   end
   if p and p:GetOwner()~=s.pid then s.selected[n]=nil;s.locks[n]=nil;s.excluded[n]=nil end
  end
  table.sort(candidates,function(a,b)
   if a.forced~=b.forced then return a.forced end -- Native mandatory local roles consume capacity first.
   if a.locked~=b.locked then return a.locked end
   if a.score~=b.score then return a.score>b.score end;return a.n<b.n
  end)
  local capacity=math.max(0,census.population-census.specialists-census.localLocked)
  if s.mode=='MANUAL' then
   for _,r in ipairs(candidates) do if not r.localPlot and s.selected[r.n] and #remote<capacity then remote[#remote+1]=r end end
  else
   for i=1,math.min(census.population-census.specialists,#candidates) do local r=candidates[i];selected[r.n]=true
    if not r.localPlot then remote[#remote+1]=r end
   end
  end
  local target=math.min(#remote,census.maximumRemote)
  local worked={}
  for _,r in pairs(locals) do if city:IsWorkingPlot(r.plot) and (s.mode=='AUTO' or not city:IsForcedWorkingPlot(r.plot)) then worked[#worked+1]=r end end
  table.sort(worked,function(a,b)
   if selected[a.plot:GetPlotIndex()]~=selected[b.plot:GetPlotIndex()] then return not selected[a.plot:GetPlotIndex()] end
   local x,y=B.Score(s,a.plot),B.Score(s,b.plot);if x~=y then return x<y end;return a.index<b.index
  end)
  for _,r in ipairs(worked) do
   local current=B.Census(s,city)
   if current.protected>=target then break end
   local before=city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN'))
   city:AlterWorkingPlot(r.index)
   if not city:IsWorkingPlot(r.plot) and city:GetSpecialistCount(B.ID('SPECIALIST_CITIZEN'))==before+1 then s.withdrawn=s.withdrawn+1;B.Save(s) end
  end
  local actual=B.Census(s,city)
  for i=1,math.min(target,actual.protected) do local r=remote[i]
   s.assignments[r.n]={x=r.plot:GetX(),y=r.plot:GetY()}
  end
  B.Totals(s,city)
  local final=B.Census(s,city)
  assert(final.remote<=final.realDefaults and final.localCount+final.remote+final.specialists+final.idle+final.unassigned==final.population+final.automata,'Invalid native citizen census')
  s.phase='IDLE';s.failure=nil;B.Save(s);cache.governorKey=final.governorKey
  cache.signature=B.Signature(s,city);cache.viewRevision=(cache.viewRevision or 0)+1
  cache.scalar={final.population,final.specialists,final.defaults}
  cache.aiDirty=true
 end)
 B.Busy[s.pid]=nil
 if not ok then
  pcall(B.ApplyLedger,city,{},{})
  s.assignments={};s.reserved=0;s.phase='RECOVER';s.failure=tostring(err);B.Save(s);B.Index(s)
  cache.signature=nil
  print('[BoundlessCity] Reconciliation aborted safely: '..tostring(err))
 end
 if LuaEvents.BoundlessChanged then LuaEvents.BoundlessChanged(s.pid) end
 return ok,err
end
function B.Summary(s)
 local city=B.City(s);if not city then return end
 local a=B.Census(s,city);a.owned=B.Ownership(s).count
 a.progress=math.floor(s.progress or 0);a.cost=B.Cost(s)
 a.available=a.availableCitizens;return a
end
function B.RemoteRows(s,sort)
 local cache=B.Ownership(s);local revision=cache.viewRevision or 0
 if cache.rows and cache.rowsRevision==revision and cache.rowsSort==sort then return cache.rows end
 local city=B.City(s);local locals=B.LocalPlots(city);local rows={}
 for _,n in ipairs(B.Keys(cache.owned)) do local p=Map.GetPlotByIndex(n)
  if p:GetOwner()==s.pid and not locals[n] and not p:IsCity() then
   local resource=GameInfo.Resources[p:GetResourceType(Players[s.pid]:GetTeam())]
   local improvement=GameInfo.Improvements[p:GetImprovementType()]
   rows[#rows+1]={n=n,plot=p,distance=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY()),score=B.Score(s,p),
    resource=resource and Locale.ConvertTextKey(resource.Description) or '',improvement=improvement and Locale.ConvertTextKey(improvement.Description) or ''}
  end
 end
 table.sort(rows,function(a,b)
  local x,y
  if sort=='YIELD' then x,y=-a.score,-b.score elseif sort=='RESOURCE' then x,y=a.resource,b.resource
  elseif sort=='IMPROVEMENT' then x,y=a.improvement,b.improvement else x,y=a.distance,b.distance end
  if x~=y then return x<y end;return a.n<b.n
 end)
 cache.rows=rows;cache.rowsRevision=revision;cache.rowsSort=sort;return rows
end
function B.Action(pid,kind,value)
 if not B.IsBoundless(pid) or Game.GetActivePlayer()~=pid or not Players[pid]:IsHuman() or not Players[pid]:IsTurnActive() then return false end
 local s=B.State(pid);if s.incompatible or not B.City(s) then return false end
 if kind=='SIEGE' then return B.QueueSiege(s,value) end
 if kind=='MODE' and ({AUTO=true,MANUAL=true,HYBRID=true})[value] then s.mode=value
 elseif kind=='PRIORITY' and B.Weights[value] then s.priority=value
 elseif kind=='DIRECTION' and ({ANY=true,NORTH=true,EAST=true,SOUTH=true,WEST=true})[value] then s.direction=value
 elseif kind=='PLOT' or kind=='LOCK' then
  local p=type(value)=='number' and Map.GetPlotByIndex(value)
  if not p or p:GetOwner()~=pid or p:IsCity() or B.LocalPlots(B.City(s))[value] then return false end
  if kind=='LOCK' and s.locks[value] then s.locks[value]=nil
  elseif kind=='PLOT' and (s.assignments[value] or s.selected[value]) then s.selected[value]=nil;s.locks[value]=nil;s.excluded[value]=true
  else
   if not B.Eligible(s,p) then return false end
   s.selected[value]=true;s.excluded[value]=nil
   if kind=='LOCK' or s.mode~='MANUAL' then s.locks[value]=true end
   if s.mode=='AUTO' then s.mode='HYBRID' end
  end
 else return false end
 B.Cache(s).force=true;return B.Reconcile(s)
end
