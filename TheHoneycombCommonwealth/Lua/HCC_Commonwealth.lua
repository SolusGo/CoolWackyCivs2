-- BNW / CP v151. One simulation owner; no load-time recalculation or frame polling.
-- PlayerDoTurn is AFTER economics. PlayerDoneTurn stages the NEXT payout.
-- Interturn assignment/pillage changes therefore wait one further snapshot.
local prior = MapModData.HCC_Controller
local existing = __HCC_CONTEXT_CONTROLLER
if existing and existing.active and existing.context == ContextPtr and prior == existing then return end
local types = GameInfoTypes or {}
local CIV, PLANTATION = types.CIVILIZATION_HCC_COMMONWEALTH, types.IMPROVEMENT_PLANTATION
local EXCHANGE = types.BUILDING_HCC_HONEY_EXCHANGE
local production = {types.BUILDING_HCC_PRODUCTION_1, types.BUILDING_HCC_PRODUCTION_2,
  types.BUILDING_HCC_PRODUCTION_3, types.BUILDING_HCC_PRODUCTION_4}
local culture = types.BUILDING_HCC_CULTURE
local gold = {types.BUILDING_HCC_GOLD_1, types.BUILDING_HCC_GOLD_2}
if not (CIV and PLANTATION and EXCHANGE and culture and production[1] and production[2]
    and production[3] and production[4] and gold[1] and gold[2]) then
  print('HCC: missing database identities; controller not registered')
  return
end
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
local controller = {context = ContextPtr, active = true, handlers = {}}
MapModData.HCC_Controller = controller
__HCC_CONTEXT_CONTROLLER = controller
local busy = false
local function IsCommonwealth(player)
  return player and player:IsAlive() and player:GetCivilizationType() == CIV
end
local function Set(city, building, count)
  if city:GetNumRealBuilding(building) ~= count then
    city:SetNumRealBuilding(building, count, true) -- suppress construction rewards
  end
end
local function ClearGold(city)
  for _, building in ipairs(gold) do Set(city, building, 0) end
end
local function ClearCommonwealthBonuses(city)
  if not city then return end
  for _, building in ipairs(production) do Set(city, building, 0) end
  Set(city, culture, 0)
  ClearGold(city)
end
local function CountWorkedPlantations(city, player)
  if not city or not player or city:GetOwner() ~= player:GetID() then return 0 end
  local count, seen = 0, {}
  -- CP GetNumCityPlots returns GetNumWorkablePlots; index lookup is the native
  -- citizen plot list. Explicit distance <= 3 excludes extended remote work.
  for index = 1, city:GetNumCityPlots() - 1 do
    local plot = city:GetCityIndexPlot(index)
    if plot and plot:GetOwner() == player:GetID()
        and plot:GetImprovementType() == PLANTATION and not plot:IsImprovementPillaged()
        and Map.PlotDistance(city:GetX(), city:GetY(), plot:GetX(), plot:GetY()) <= 3
        and city:IsWorkingPlot(plot) then
      local working = plot:GetWorkingCity() -- CP: effective owning city, including override
      local key = plot:GetPlotIndex()
      if working and working:GetOwner() == city:GetOwner() and working:GetID() == city:GetID()
          and not seen[key] then
        seen[key], count = true, count + 1
      end
    end
  end
  return count
end
local function ApplyCommonwealthBonuses(city, count)
  local p = math.min(4, count)
  local g = city:GetNumBuilding(EXCHANGE) > 0 and math.min(2, math.floor(count / 2)) or 0
  for i, building in ipairs(production) do Set(city, building, i <= p and 1 or 0) end
  Set(city, culture, count >= 2 and 1 or 0)
  for i, building in ipairs(gold) do Set(city, building, i <= g and 1 or 0) end
end
local function Cleanup(city)
  if not city then return end
  local player = Players[city:GetOwner()]
  if not IsCommonwealth(player) then ClearCommonwealthBonuses(city)
  elseif city:GetNumBuilding(EXCHANGE) == 0 then ClearGold(city) end
end
local function UpdateCommonwealthCities(id)
  local player = Players[id]
  if not IsCommonwealth(player) then return end
  local turn = Game.GetGameTurn()
  local data = player:GetScriptData() or ''
  if tonumber(data:match('%[HCC1:(%-?%d+)%]')) == turn then return end
  -- Snapshot EVERY city's count before any setter can trigger governor changes.
  -- Retain IDs/counts only; no city userdata survives an event boundary.
  local targets = {}
  for city in player:Cities() do
    if city and city:GetOwner() == id then
      targets[#targets + 1] = {id = city:GetID(), count = CountWorkedPlantations(city, player)}
    end
  end
  -- Bounded synchronous retry uses the SAME snapshot; failures never accumulate.
  for _, target in ipairs(targets) do
    local function Apply()
      local city = player:GetCityByID(target.id)
      if city and city:GetOwner() == id then ApplyCommonwealthBonuses(city, target.count) end
    end
    local ok, err = pcall(Apply)
    if not ok then ok, err = pcall(Apply) end
    if not ok then error('city ' .. target.id .. ' failed twice: ' .. tostring(err)) end
  end
  -- Only a duplicate-boundary receipt is saved. The dummies ARE the yield state.
  -- Re-read to preserve other controllers' ScriptData edits during setters.
  data = (player:GetScriptData() or ''):gsub('%[HCC1:%-?%d+%]', '')
  player:SetScriptData(data .. '[HCC1:' .. turn .. ']')
end
local function Guard(fn, ...)
  if not Game.IsFinalInitialized() then return end -- no partial-load city cleanup
  if busy then return end -- our own native dirty notifications are synchronous
  busy = true
  local ok, err = pcall(fn, ...)
  busy = false
  if not ok then print('HCC: callback failed: ' .. tostring(err)) end
end
local function Hook(events, name, fn)
  local event = events and events[name]
  if not event or not event.Add then return end
  local callback = function(...)
    if controller.active and MapModData.HCC_Controller == controller then Guard(fn, ...) end
  end
  event.Add(callback)
  controller.handlers[#controller.handlers + 1] = {event = event, callback = callback}
end
Hook(GameEvents, 'PlayerDoneTurn', UpdateCommonwealthCities)
Hook(GameEvents, 'PlayerDoTurn', function(id)
  local player = Players[id]
  if not player or not player:IsAlive() then return end
  -- Defensive cleanup of HCC markers only. NEVER refresh an existing snapshot.
  for city in player:Cities() do Cleanup(city) end
end)
Hook(GameEvents, 'CityCaptureComplete', function(oldOwner, wasCapital, x, y, newOwner)
  local plot = Map.GetPlot(x, y)
  local city = plot and plot:GetPlotCity()
  -- This hook follows native acquisition, including gifts/liberation; clear even
  -- for HCC -> HCC transfers. Newly acquired cities wait for their next snapshot.
  if city then ClearCommonwealthBonuses(city) end
end)
local function BuildingChanged(id, cityID)
  local player = Players[id]
  local city = player and player:GetCityByID(cityID)
  if city then Cleanup(city) end
end
Hook(GameEvents, 'CitySoldBuilding', BuildingChanged) -- verified AFTER native removal
Hook(GameEvents, 'CityConstructed', BuildingChanged) -- never activates fresh Exchange Gold
Hook(Events, 'SpecificCityInfoDirty', BuildingChanged) -- scripted removal; no recount
Hook(GameEvents, 'PlayerCityFounded', function(id, x, y)
  local plot = Map.GetPlot(x, y)
  local city = plot and plot:GetPlotCity()
  if city and city:GetOwner() == id then ClearCommonwealthBonuses(city) end
end)
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(controller)
    if MapModData.HCC_Controller == controller then MapModData.HCC_Controller = nil end
    if __HCC_CONTEXT_CONTROLLER == controller then __HCC_CONTEXT_CONTROLLER = nil end
  end)
end
-- Deliberately no Initialize / LoadScreenClose / SequenceGameInitComplete yield
-- pass: mid-turn reload preserves actual saved dummies despite new assignments.
