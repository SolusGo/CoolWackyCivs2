-- BNW / CP v151. PlayerDoneTurn stages the NEXT payout; no per-frame polling.
-- Existing buildings remain the applied snapshot. HCCP2 is only an unfinished
-- write journal of seven binary targets, removed once HCC1 acknowledges them.
local prior, existing = MapModData.HCC_Controller, __HCC_CONTEXT_CONTROLLER
if existing and existing.active and existing.context == ContextPtr and prior == existing then return end
local function Retire(state)
  if not state then return end
  state.active = false
  for _, item in ipairs(state.handlers or {}) do
    if item.event.Remove then pcall(item.event.Remove, item.callback) end
  end
  state.handlers = {}
end
Retire(prior)
if existing ~= prior then Retire(existing) end
local types = GameInfoTypes or {}
local CIV, PLANTATION = types.CIVILIZATION_HCC_COMMONWEALTH, types.IMPROVEMENT_PLANTATION
local EXCHANGE = types.BUILDING_HCC_HONEY_EXCHANGE
local buildings = {types.BUILDING_HCC_PRODUCTION_1, types.BUILDING_HCC_PRODUCTION_2,
  types.BUILDING_HCC_PRODUCTION_3, types.BUILDING_HCC_PRODUCTION_4,
  types.BUILDING_HCC_CULTURE, types.BUILDING_HCC_GOLD_1, types.BUILDING_HCC_GOLD_2}
if not (CIV and PLANTATION and EXCHANGE and buildings[1] and buildings[2] and buildings[3]
    and buildings[4] and buildings[5] and buildings[6] and buildings[7]) then
  MapModData.HCC_Controller, __HCC_CONTEXT_CONTROLLER = nil, nil
  print('HCC: missing database identities; controller not registered')
  return
end
local controller = {context = ContextPtr, active = true, handlers = {}}
MapModData.HCC_Controller, __HCC_CONTEXT_CONTROLLER = controller, controller
local function OwnsContext()
  return controller.active and MapModData.HCC_Controller==controller
end
local busy, waiting, order, ready = false, {}, {}, false
local validMasks = {[0]=true,[1]=true,[19]=true,[23]=true,[31]=true,[51]=true,[55]=true,[127]=true}
local function IsCommonwealth(player)
  return player and player:IsAlive() and player:GetCivilizationType() == CIV
end
local function Identity(city)
  return {id=city:GetID(),x=city:GetX(),y=city:GetY(),founded=city:GetGameTurnFounded()}
end
local function Resolve(player, r)
  local city = player and player:GetCityByID(r.id)
  if city and city:GetOwner() == player:GetID() and city:GetX() == r.x and city:GetY() == r.y
      and city:GetGameTurnFounded() == r.founded then return city end
end
local function Set(city, building, count)
  if not OwnsContext() then return nil end
  if city:GetNumRealBuilding(building) ~= count then
    local player, identity = Players[city:GetOwner()], Identity(city)
    city:SetNumRealBuilding(building, count, true) -- suppress construction rewards
    if not OwnsContext() then return nil end
    local current = Resolve(player,identity)
    if current then assert(current:GetNumRealBuilding(building)==count, 'dummy write did not persist') end
    return current
  end
  return city
end
local function Try(label, fn)
  local ok, err = pcall(fn)
  if not ok then ok, err = pcall(fn) end
  if not ok then print('HCC: '..label..' failed twice: '..tostring(err)) end
  return ok
end
local function WriteData(player, transform)
  local old = player:GetScriptData() or ''
  local value = transform(old)
  if value ~= old then player:SetScriptData(value) end
  assert(player:GetScriptData() == value, 'ScriptData write did not persist')
end
local function Encode(journal)
  local records = {}
  for _, r in ipairs(journal.cities) do
    records[#records+1] = table.concat({r.id,r.x,r.y,r.founded,r.mask}, ',')
  end
  return '[HCCP2:'..journal.turn..'|'..table.concat(records,';')..']'
end
local function ReadPending(player)
  local data = player:GetScriptData() or ''
  local payload = data:match('%[HCCP2:([^%]]*)%]')
  if not payload then
    assert(not data:find('[HCCP2:',1,true), 'incomplete pending snapshot')
    return nil
  end
  local _, copies = data:gsub('%[HCCP2:', '')
  assert(copies == 1, 'duplicate pending snapshots')
  local turn, entries = payload:match('^(%d+)|(.*)$')
  assert(turn and tonumber(turn) <= Game.GetGameTurn(), 'invalid pending turn')
  local journal, seen = {turn=tonumber(turn),cities={}}, {}
  if entries == '' then return journal end
  for entry in (entries..';'):gmatch('(.-);') do
    local id,x,y,founded,mask = entry:match('^(%d+),(%d+),(%d+),(%d+),(%d+)$')
    id,x,y,founded,mask = tonumber(id),tonumber(x),tonumber(y),tonumber(founded),tonumber(mask)
    assert(id and id<=2147483647 and x<=2147483647 and y<=2147483647
      and founded<=journal.turn and validMasks[mask] and not seen[id], 'invalid pending city')
    seen[id] = true
    journal.cities[#journal.cities+1] = {id=id,x=x,y=y,founded=founded,mask=mask}
  end
  return journal
end
local function SavePending(player, journal)
  WriteData(player, function(data)
    return data:gsub('%[HCCP2:[^%]]*%]', '')..Encode(journal)
  end)
end
local function ClearGold(city)
  for i=6,7 do
    if not city then return end
    city = Set(city, buildings[i], 0)
  end
end
local function ClearCommonwealthBonuses(city)
  if not city then return end
  for _, building in ipairs(buildings) do
    if not city then return end
    city = Set(city, building, 0)
  end
end
local function CountWorkedPlantations(city, player)
  if not city or not player or city:GetOwner() ~= player:GetID() then return 0 end
  local count, seen = 0, {}
  for index=1,city:GetNumCityPlots()-1 do
    local plot = city:GetCityIndexPlot(index)
    if plot and plot:GetOwner() == player:GetID() and plot:GetImprovementType() == PLANTATION
        and not plot:IsImprovementPillaged()
        and Map.PlotDistance(city:GetX(),city:GetY(),plot:GetX(),plot:GetY()) <= 3
        and city:IsWorkingPlot(plot) then
      local working, key = plot:GetWorkingCity(), plot:GetPlotIndex()
      if working and working:GetOwner() == city:GetOwner() and working:GetID() == city:GetID()
          and not seen[key] then seen[key],count = true,count+1 end
    end
  end
  return count
end
local function RevokeGold(player, r, journal)
  local previous = r.mask
  r.mask = r.mask % 32
  local ok, err = pcall(SavePending,player,journal)
  if not ok then r.mask=previous; error(err) end
end
local function ApplyCommonwealthBonuses(player, r, journal)
  if not OwnsContext() then return end
  local city = Resolve(player,r)
  if not city then return end -- destroyed/transferred/reused IDs must not replay
  if city:GetNumBuilding(EXCHANGE) == 0 and r.mask >= 32 then
    RevokeGold(player,r,journal) -- a later rebuilt Exchange cannot revive old Gold
  end
  for i, building in ipairs(buildings) do
    if not city or not OwnsContext() then return end
    local target = math.floor(r.mask / 2^(i-1)) % 2
    if i >= 6 and city:GetNumBuilding(EXCHANGE) == 0 then target = 0 end
    city = Set(city,building,target) -- reacquires after every actual mutation
  end
  if OwnsContext() and city and city:GetNumBuilding(EXCHANGE) == 0 and r.mask >= 32 then
    RevokeGold(player,r,journal)
  end
end
local function Resume(player, journal)
  local complete = true
  for _, r in ipairs(journal.cities) do
    if not OwnsContext() then return end
    if not Try('snapshot city '..player:GetID()..':'..r.id, function()
      ApplyCommonwealthBonuses(player,r,journal)
    end) then complete = false end
  end
  if complete and OwnsContext() then
    -- Do not retry a whole snapshot on receipt failure; its saved targets remain.
    WriteData(player, function(data)
      return data:gsub('%[HCCP2:[^%]]*%]', ''):gsub('%[HCC1:%-?%d+%]', '')
        ..'[HCC1:'..journal.turn..']'
    end)
  end
end
local function Invalidate(player, x, y, goldOnly)
  if not player then return end
  local journal = ReadPending(player)
  if not journal then return end
  local changed = false
  for i=#journal.cities,1,-1 do
    local r = journal.cities[i]
    if r.x==x and r.y==y then
      if not goldOnly then table.remove(journal.cities,i); changed=true
      elseif r.mask>=32 then r.mask=r.mask%32; changed=true end
    end
  end
  if changed then SavePending(player,journal) end
end
local function Cleanup(city, lostExchange)
  if not city then return end
  local player = Players[city:GetOwner()]
  if not IsCommonwealth(player) then ClearCommonwealthBonuses(city)
  elseif lostExchange or city:GetNumBuilding(EXCHANGE)==0 then
    Invalidate(player,city:GetX(),city:GetY(),true)
    ClearGold(city)
  end
end
local function UpdateCommonwealthCities(id)
  local player = Players[id]
  if not IsCommonwealth(player) then return end
  local turn = Game.GetGameTurn()
  local journal = ReadPending(player)
  if journal and journal.turn==turn then Resume(player,journal); return end
  if tonumber((player:GetScriptData() or ''):match('%[HCC1:(%-?%d+)%]'))==turn then return end
  journal = {turn=turn,cities={}}
  for city in player:Cities() do
    if city and city:GetOwner()==id then
      local count = CountWorkedPlantations(city,player)
      local p, g = math.min(4,count), 0
      if city:GetNumBuilding(EXCHANGE)>0 then g=math.min(2,math.floor(count/2)) end
      journal.cities[#journal.cities+1] = {id=city:GetID(),x=city:GetX(),y=city:GetY(),
        founded=city:GetGameTurnFounded(),mask=2^p-1+(count>=2 and 16 or 0)+(g>=1 and 32 or 0)+(g>=2 and 64 or 0)}
    end
  end
  -- Freeze every count AND Exchange eligibility durably before the first setter.
  SavePending(player,journal)
  Resume(player,journal)
end
local function Guard(key, fn, ...)
  if not Game.IsFinalInitialized() then return end
  if not waiting[key] then order[#order+1] = key end
  waiting[key] = {fn=fn,args={...}}
  if busy then return end
  busy = true
  local jobs, budget = 0, 64
  while #order>0 and jobs<budget and OwnsContext() do
    local label = table.remove(order,1)
    local work = waiting[label]; waiting[label]=nil
    jobs = jobs+1
    local ok, err = pcall(work.fn,unpack(work.args))
    if not ok then print('HCC: '..label..' failed: '..tostring(err)) end
    -- A large ordinary snapshot can publish one coalesced dirty job per city.
    -- Drain that finite batch before returning to native economic processing.
    budget = math.min(4096,math.max(budget,jobs+#order*2))
  end
  busy = false -- excess primitive-argument jobs resume on the next native event
end
local function Hook(events, name, fn)
  local event = events and events[name]
  if not event or not event.Add then return end
  local callback = function(...)
    if controller.active and MapModData.HCC_Controller==controller and Game.IsFinalInitialized() then
      -- CP serializes IsFinalInitialized=true. It alone is not proof that every
      -- city building has been restored in a newly created Lua context.
      if events==GameEvents or name=='SequenceGameInitComplete' or name=='LoadScreenClose' then ready=true end
      if not ready then return end
      local ok, err = pcall(fn,...)
      if not ok then print('HCC: '..name..' failed: '..tostring(err)) end
    end
  end
  event.Add(callback)
  controller.handlers[#controller.handlers+1] = {event=event,callback=callback}
end
Hook(GameEvents,'PlayerDoneTurn',function(id) Guard('stage '..id,UpdateCommonwealthCities,id) end)
Hook(GameEvents,'PlayerDoTurn',function(id)
  Guard('turn '..id,function()
    local player = Players[id]
    if not player or not player:IsAlive() then return end
    if IsCommonwealth(player) then
      local journal = ReadPending(player)
      if journal then Resume(player,journal) end
    end
    for city in player:Cities() do
      Try('cleanup city '..id..':'..city:GetID(),function() Cleanup(city) end)
    end
  end)
end)
Hook(GameEvents,'CityCaptureComplete',function(oldOwner,wasCapital,x,y,newOwner)
  Guard('capture '..x..':'..y,function()
    Try('capture receipt',function()
      Invalidate(Players[oldOwner],x,y,false)
      if newOwner~=oldOwner then Invalidate(Players[newOwner],x,y,false) end
    end)
    local plot = Map.GetPlot(x,y)
    local city = plot and plot:GetPlotCity()
    if city then Try('capture cleanup',function() ClearCommonwealthBonuses(city) end) end
  end)
end)
local function BuildingChanged(id,cityID)
  local player = Players[id]
  local city = player and player:GetCityByID(cityID)
  if not city then return end
  -- Observe loss NOW, even when the mutation must wait behind another setter.
  -- OR-coalesce loss so a reentrant rebuild cannot overwrite the revocation.
  local key = 'building '..id..':'..cityID
  local lost = city:GetNumBuilding(EXCHANGE)==0
  local queued = waiting[key]
  lost = lost or (queued and queued.args[1]) or false
  Guard(key,function(force)
    local current = Players[id] and Players[id]:GetCityByID(cityID)
    if current then Try(key,function() Cleanup(current,force) end) end
  end,lost)
end
Hook(GameEvents,'CitySoldBuilding',BuildingChanged)
Hook(GameEvents,'CityConstructed',BuildingChanged)
Hook(Events,'SpecificCityInfoDirty',BuildingChanged)
Hook(GameEvents,'PlayerCityFounded',function(id,x,y)
  Guard('found '..x..':'..y,function()
    Try('found receipt',function() Invalidate(Players[id],x,y,false) end)
    local plot = Map.GetPlot(x,y)
    local city = plot and plot:GetPlotCity()
    if city and city:GetOwner()==id then Try('found cleanup',function() ClearCommonwealthBonuses(city) end) end
  end)
end)
local function RecoverPending()
  for id=0,(GameDefines and GameDefines.MAX_CIV_PLAYERS or 64)-1 do
    local player = Players[id]
    if IsCommonwealth(player) then
      Guard('recover '..id,function()
        local journal = ReadPending(player)
        if journal then Resume(player,journal) end
      end)
    end
  end
end
Hook(Events,'SequenceGameInitComplete',RecoverPending)
Hook(Events,'LoadScreenClose',RecoverPending)
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(controller)
    if MapModData.HCC_Controller==controller then MapModData.HCC_Controller=nil end
    if __HCC_CONTEXT_CONTROLLER==controller then __HCC_CONTEXT_CONTROLLER=nil end
  end)
end
-- No top-level/load-time counting. Recovery only replays an unfinished HCCP2
-- target; ordinary saves with only HCC1 retain their actual buildings untouched.
