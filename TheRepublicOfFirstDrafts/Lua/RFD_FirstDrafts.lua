-- BNW + Community Patch v151. Historical UA and current-city UB are independent.
local previous, localPrevious = MapModData.RFD_Controller, RFD_ContextController
if previous and previous.active and previous.context == ContextPtr then return end
local function Retire(state)
  if not state then return end
  state.active = false
  for _, h in ipairs(state.handlers or {}) do
    if h.event.Remove then pcall(h.event.Remove, h.callback) end
  end
end
Retire(previous)
if localPrevious ~= previous then Retire(localPrevious) end
local types = GameInfoTypes or {}
local CIV, WORKSHOP = types.CIVILIZATION_RFD_REPUBLIC, types.BUILDING_RFD_REVISION_WORKSHOP
local dummies = {types.BUILDING_RFD_SCIENCE_1, types.BUILDING_RFD_SCIENCE_2, types.BUILDING_RFD_SCIENCE_3}
if not (CIV and WORKSHOP and dummies[1] and dummies[2] and dummies[3]) then
  print('RFD: required database identities missing; controller disabled')
  return
end
local controller = {active=true, context=ContextPtr, handlers={}}
MapModData.RFD_Controller, RFD_ContextController = controller, controller
local busy = false
local function Flag(value) return value == true or value == 1 end
local function EligiblePlayer(player)
  return player and player:IsAlive() and player:IsHuman() and player:GetCivilizationType() == CIV
end

-- Resolve the ACTIVE database once. A possessed building must itself be eligible;
-- a hidden replacement cannot piggyback on an otherwise ordinary class.
local qualifying = {}
local function Qualifies(building)
  local class = GameInfo.BuildingClasses[building.BuildingClass]
  if not class or class.Type == 'BUILDINGCLASS_PALACE' or Flag(building.Capital)
      or Flag(building.IsDummy) or building.ShowInPedia == false or building.ShowInPedia == 0
      or (tonumber(building.GreatWorkCount) or 0) < 0 then return false end
  for _, limit in ipairs({'MaxGlobalInstances','MaxTeamInstances','MaxPlayerInstances'}) do
    if (tonumber(class[limit]) or -1) >= 0 then return false end
  end
  -- Faith-only religious buildings (Cost=-1) remain valid. League projects and
  -- unbuildable/free policy markers do not. Zero-cost constructible buildings do.
  if (tonumber(building.LeagueCost) or 0) > 0 then return false end
  return (tonumber(building.Cost) or -1) >= 0 or (tonumber(building.FaithCost) or 0) > 0
end
for building in GameInfo.Buildings() do
  if Qualifies(building) then qualifying[#qualifying+1] = {id=building.ID, class=building.BuildingClass} end
end
table.sort(qualifying, function(a,b) return a.id < b.id end)

local function CityClasses(city)
  local result, count = {}, 0
  for _, building in ipairs(qualifying) do
    if city:GetNumBuilding(building.id) > 0 and not result[building.class] then
      result[building.class], count = true, count+1
    end
  end
  return result, count
end
local function ReconcileCity(player, city, count)
  local target = 0
  if EligiblePlayer(player) and city:GetOwner() == player:GetID() and city:GetNumBuilding(WORKSHOP) > 0 then
    if not count then local unused; unused, count = CityClasses(city) end
    target = math.min(3, math.floor(count/4))
  end
  for i, id in ipairs(dummies) do
    local wanted = i <= target and 1 or 0
    if city:GetNumRealBuilding(id) ~= wanted then city:SetNumRealBuilding(id, wanted) end
  end
end
local function Scan(player, reconcile)
  local empire = {}
  for city in player:Cities() do
    local classes, count = CityClasses(city)
    for class in pairs(classes) do empire[class] = true end
    if reconcile then ReconcileCity(player, city, count) end
  end
  return empire
end
local function SortedKeys(set)
  local result = {}
  for key in pairs(set) do result[#result+1] = key end
  table.sort(result)
  return result
end

-- Save-scoped player ScriptData. Only replace our exact namespaced block.
-- [RFD1|lastEvaluationTurn|sorted class TYPES|phase,oldCulture100,newCulture100,oldGold100,newGold100]
-- The optional journal is written BEFORE any yield changes; phase 1=Culture,
-- phase 2=Gold. Exact before/after checks recover a completed but unacknowledged
-- write without incrementing again. Ambiguous external changes fail closed.
local function Read(player)
  local data = player:GetScriptData() or ''
  local payload = data:match('%[RFD1|([^%]]*)%]')
  if not payload then
    assert(not data:find('[RFD',1,true), 'unknown or damaged RFD save block')
    return nil
  end
  local _, copies = data:gsub('%[RFD1|','')
  assert(copies == 1, 'duplicate RFD ledger')
  local turn, classes, pending = payload:match('^(%-?%d+)|([^|]*)|(.*)$')
  assert(turn, 'invalid RFD ledger')
  local state = {turn=tonumber(turn), classes={}}
  assert(state.turn <= Game.GetGameTurn(), 'future RFD ledger')
  if classes ~= '' then
    for class in (classes..','):gmatch('(.-),') do
      assert(class:match('^BUILDINGCLASS_[A-Z0-9_]+$') and not state.classes[class], 'invalid RFD class')
      state.classes[class] = true -- retain exhausted classes even if a mod removes their definitions
    end
  end
  if pending ~= '' then
    local phase, cb, ct, gb, gt = pending:match('^([12]),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+)$')
    assert(phase, 'invalid RFD payout journal')
    state.pending = {phase=tonumber(phase),cb=tonumber(cb),ct=tonumber(ct),gb=tonumber(gb),gt=tonumber(gt)}
    assert(state.pending.ct >= state.pending.cb and state.pending.gt >= state.pending.gb,
      'negative RFD journal reward')
  end
  return state
end
local function Save(player, state)
  local pending = state.pending
  local journal = pending and table.concat({pending.phase,pending.cb,pending.ct,pending.gb,pending.gt},',') or ''
  local block = '[RFD1|'..state.turn..'|'..table.concat(SortedKeys(state.classes),',')..'|'..journal..']'
  local old = player:GetScriptData() or ''
  local value, count = old:gsub('%[RFD1|[^%]]*%]',function() return block end)
  if count == 0 then value = old..block end
  assert(count <= 1, 'duplicate RFD ledger on write')
  if value ~= old then player:SetScriptData(value) end
  assert(player:GetScriptData() == value, 'RFD ScriptData write not acknowledged')
end
local function Recover(player, state)
  local p = state.pending
  if not p then return end
  if p.phase == 1 then
    local actual = player:GetJONSCultureTimes100()
    assert(actual == p.cb or actual == p.ct, 'ambiguous interrupted Culture payout; ledger retained')
    if actual ~= p.ct then player:ChangeJONSCultureTimes100(p.ct-actual) end
    assert(player:GetJONSCultureTimes100() == p.ct, 'Culture payout not acknowledged')
    p.phase = 2
    Save(player, state)
  end
  local actual = player:GetGoldTimes100()
  assert(actual == p.gb or actual == p.gt, 'ambiguous interrupted Gold payout; ledger retained')
  if actual ~= p.gt then player:ChangeGold((p.gt-actual)/100) end
  assert(player:GetGoldTimes100() == p.gt, 'Gold payout not acknowledged')
  state.pending = nil
  Save(player, state)
end
local function InitializePlayer(player)
  local state = Read(player)
  if state then return state end
  -- Advanced era starts use the game's actual StartTurn. A late-added context on
  -- a progressed save seeds all CURRENT classes, with no retroactive payout.
  local progressed = Game.GetGameTurn() > Game.GetStartTurn()
  state = {turn=-1, classes=progressed and Scan(player,false) or {}}
  Save(player, state)
  return state
end
local function Evaluate(id)
  local player = Players[id]
  if not EligiblePlayer(player) then return end
  local current = Scan(player,true)
  local state = InitializePlayer(player)
  Recover(player,state)
  local turn = Game.GetGameTurn()
  if state.turn == turn then return end
  local count = 0
  for class in pairs(current) do
    if not state.classes[class] then state.classes[class], count = true, count+1 end
  end
  state.turn = turn
  if count > 0 then
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local percent = speed and tonumber(speed.ConstructPercent)
    assert(percent and percent > 0, 'active GameSpeeds.ConstructPercent unavailable')
    local culture = math.floor(12*percent/100+0.5)*count
    local gold = math.floor(20*percent/100+0.5)*count
    local cb, gb = player:GetJONSCultureTimes100(), player:GetGoldTimes100()
    state.pending = {phase=1,cb=cb,ct=cb+culture*100,gb=gb,gt=gb+gold*100}
  end
  Save(player,state)
  Recover(player,state)
end

local function Guard(label, work, ...)
  if busy then return end -- dummy writes can synchronously publish dirty events
  busy = true
  local ok, err = pcall(work, ...)
  busy = false
  if not ok then print('RFD: '..label..': '..tostring(err)) end
end
local function Hook(events, name, callback)
  local event = events and events[name]
  if not (event and event.Add) then return end
  local wrapped = function(...)
    if controller.active and MapModData.RFD_Controller == controller then callback(...) end
  end
  event.Add(wrapped)
  controller.handlers[#controller.handlers+1] = {event=event,callback=wrapped}
end
local function BuildingChanged(id, cityID, buildingID)
  if buildingID == dummies[1] or buildingID == dummies[2] or buildingID == dummies[3] then return end
  Guard('city reconciliation', function()
    local player = Players[id]
    local city = player and player:GetCityByID(cityID)
    if city then ReconcileCity(player,city) end
  end)
end
local function Initialize()
  for id, player in pairs(Players) do
    if EligiblePlayer(player) then
      Guard('initialize player '..id,function()
        Scan(player,true)
        local state = InitializePlayer(player)
        Recover(player,state)
      end)
    elseif player and player:IsAlive() then
      -- Cheap foreign cleanup, including saves made just after a city transfer.
      Guard('foreign cleanup '..id,function()
        for city in player:Cities() do ReconcileCity(player,city) end
      end)
    end
  end
end
Hook(GameEvents,'PlayerDoTurn',function(id)
  Guard('owner turn '..tostring(id),Evaluate,id)
end)
Hook(GameEvents,'CityConstructed',BuildingChanged)
Hook(GameEvents,'CitySoldBuilding',BuildingChanged)
Hook(Events,'SpecificCityInfoDirty',function(id,cityID) BuildingChanged(id,cityID) end)
Hook(GameEvents,'CityCaptureComplete',function(oldOwner,wasCapital,x,y,newOwner)
  Guard('city capture',function()
    local plot = Map.GetPlot(x,y)
    local city = plot and plot:GetPlotCity() -- reacquire; old City userdata is invalid
    if city then ReconcileCity(Players[city:GetOwner()],city) end
  end)
end)
Hook(Events,'SequenceGameInitComplete',Initialize)
Hook(Events,'LoadScreenClose',Initialize)
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(controller)
    if MapModData.RFD_Controller == controller then MapModData.RFD_Controller = nil end
    if RFD_ContextController == controller then RFD_ContextController = nil end
  end)
end
Initialize()
