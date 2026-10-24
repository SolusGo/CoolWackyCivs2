-- BNW / CP v151. One invisible InGameUIAddin owns both conditional buildings.
-- Native IsConnectedToCapital reads a cached network flag, not a fresh search.
-- See docs/Implementation.md for the exact event/settlement synchronization gap.
local previous = MapModData.CONICAL_Controller
-- This global is private to the owning Lua context, unlike MapModData. A fresh
-- Lua environment must register even if the engine reuses the ContextPtr value.
local localController = __CONICAL_CONTEXT_CONTROLLER
if localController and localController.active and localController.context == ContextPtr
    and previous == localController then return end
local types = GameInfoTypes or {}
local CIV = types.CIVILIZATION_CONICAL_UNION
local CONNECTION = types.BUILDING_CONICAL_CONNECTION_DUMMY
local GOLD = types.BUILDING_CONICAL_DETOUR_GOLD_DUMMY
local OFFICE = types.BUILDING_CONICAL_DETOUR_OFFICE
if not (CIV and CONNECTION and GOLD and OFFICE) then
  print('CONICAL: missing database identities; controller not registered')
  return
end
-- A shared boolean does not prove that a recreated UI context has callbacks.
-- Follow the collection's context identity pattern, and retire retained handlers.
local function Retire(state)
  if not state then return end
  state.active = false
  for _, registration in ipairs(state.handlers or {}) do
    pcall(function()
      if registration.event.Remove then registration.event.Remove(registration.callback) end
    end)
  end
  state.handlers = {}
end
Retire(previous)
if localController ~= previous then Retire(localController) end
local controller = {context = ContextPtr, active = true, handlers = {}}
MapModData.CONICAL_Controller = controller
__CONICAL_CONTEXT_CONTROLLER = controller
MapModData.CONICAL_ControllerLoaded = nil -- obsolete v1 boolean, not saved gameplay data
local busy, currentCity = false, nil
local warned, failed, pending, swept = {}, {}, {}, {}
local waiting, order = {}, {}
local maxPlayers = GameDefines and GameDefines.MAX_CIV_PLAYERS or 64

local function Try(key, fn)
  local ok, err = pcall(fn)
  if not ok then ok, err = pcall(fn) end -- only idempotent reconciliation is retried
  if ok then
    failed[key] = nil
  elseif not failed[key] then
    failed[key] = true
    print('CONICAL: ' .. key .. ' failed twice; next lifecycle/owner turn retries: ' .. tostring(err))
  end
  return ok
end

local function Warn(key, message)
  if not warned[key] then warned[key] = true; print('CONICAL: ' .. message) end
end

local function Set(city, building, count)
  if city:GetNumRealBuilding(building) ~= count then
    -- Suppress construction rewards; normal native yield recalculation remains.
    city:SetNumRealBuilding(building, count, true)
  end
end

local function ReconcileConicalCity(player, city)
  if not city then return end
  -- Always verify the ACTUAL owner: capture callbacks may refer to former owners.
  local owner = Players and Players[city:GetOwner()]
  local eligible = owner and owner == player and owner:IsAlive()
    and owner:GetCivilizationType() == CIV
  local connected = false
  if eligible then
    local capital = owner:GetCapitalCity()
    if capital and capital:GetID() ~= city:GetID() then
      if type(city.IsConnectedToCapital) == 'function' then
        local ok, result = pcall(city.IsConnectedToCapital, city)
        connected = ok and result == true
        if not ok then
          Warn('query', 'native connection query failed; conditional yields disabled until retry')
        end
      else
        Warn('api', 'City:IsConnectedToCapital unavailable; conditional yields disabled')
      end
    end
  end
  -- One shared binary calculation, no saved connection cache or accumulating grants.
  Set(city, CONNECTION, connected and 1 or 0)
  Set(city, GOLD, connected and city:GetNumRealBuilding(OFFICE) > 0 and 1 or 0)
end

local function IsConical(player)
  return player and player:GetCivilizationType() == CIV
end

local function CityKey(id, cityID) return 'city ' .. id .. ':' .. cityID end

local function ReconcileCity(player, city)
  if not city then return end
  local id, cityID = city:GetOwner(), city:GetID()
  local key = CityKey(id, cityID)
  currentCity = key
  local ok = Try(key, function() ReconcileConicalCity(player, city) end)
  currentCity = nil
  if ok then
    if pending[id] then
      pending[id][cityID] = nil
      if not next(pending[id]) then pending[id] = nil end
    end
  elseif not IsConical(player) then
    -- A foreign owner is not swept every turn. Retain only failed city IDs;
    -- never retain City userdata. Normal Conical turns already revisit all cities.
    pending[id] = pending[id] or {}
    pending[id][cityID] = true
  end
end

local function RetryForeign(id, player)
  local batch = pending[id]
  if not batch then return end
  pending[id] = nil
  for cityID in pairs(batch) do
    local ok = Try('lookup ' .. CityKey(id, cityID), function()
      local city = player and player:GetCityByID(cityID)
      if city then ReconcileCity(player, city) else failed[CityKey(id, cityID)] = nil end
    end)
    if not ok then pending[id] = pending[id] or {}; pending[id][cityID] = true end
  end
end

local function ReconcilePlayer(id, initialize)
  local player = Players and Players[id]
  if IsConical(player) or (initialize and player and not swept[id]) then
    Try('player ' .. id, function()
      for city in player:Cities() do ReconcileCity(player, city) end
      swept[id] = true
    end)
  else
    RetryForeign(id, player)
  end
end

local function ReconcileAll()
  -- One foreign city-list sweep per context repairs persisted capture residue.
  -- Later initialization notifications revisit only Conical lists/pending IDs.
  for id = 0, maxPlayers - 1 do ReconcilePlayer(id, true) end
end

local function Guard(key, fn)
  if not waiting[key] then order[#order + 1] = key end
  waiting[key] = fn
  if busy then return end
  busy = true
  -- Coalesce reentrant work for OTHER cities/ownership changes. Bound a hostile
  -- event storm; unfinished primitive-argument jobs resume on the next event.
  local count = 0
  while #order > 0 and count < 32 and controller.active do
    local job = table.remove(order, 1)
    local work = waiting[job]; waiting[job] = nil
    count = count + 1
    Try('event ' .. job, work)
  end
  busy = false
end

local function Hook(events, name, fn)
  local event = events and events[name]
  if event and event.Add then
    local callback = function(...)
      -- If native removal is unavailable or an old context survives, it is inert.
      if controller.active and MapModData.CONICAL_Controller == controller then fn(...) end
    end
    event.Add(callback)
    controller.handlers[#controller.handlers + 1] = {event = event, callback = callback}
  end
end

local function ReconcileID(id, cityID)
  local player = Players and Players[id]
  if not player then return end
  local city = player:GetCityByID(cityID)
  if not city then return end
  -- The targeted foreign path also clears markers if another script transfers a
  -- city and publishes its dirty event before/without CityCaptureComplete.
  -- Keep foreign marker reads INSIDE the per-city retry boundary too. Healthy
  -- foreign cities still do only the two count reads and never query a connection.
  ReconcileCity(player, city)
end

local function PlayerChanged(id) Guard('player ' .. id, function() ReconcilePlayer(id) end) end
Hook(GameEvents, 'PlayerDoTurn', PlayerChanged)
Hook(GameEvents, 'PlayerDoneTurn', PlayerChanged)
Hook(GameEvents, 'PlayerCityFounded', PlayerChanged)
Hook(GameEvents, 'CapitalChanged', PlayerChanged)
Hook(GameEvents, 'CityCaptureComplete', function(oldOwner, wasCapital, x, y, newOwner)
  Guard('capture ' .. x .. ':' .. y, function()
    -- Reacquire the reconstructed city; never keep old/deleted City userdata.
    local plot = Map and Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city then ReconcileCity(Players and Players[city:GetOwner()], city) end
    ReconcilePlayer(oldOwner)
    if newOwner ~= oldOwner then ReconcilePlayer(newOwner) end
  end)
end)
Hook(GameEvents, 'CityRazed', PlayerChanged)
local function BuildingChanged(id, cityID)
  local key = CityKey(id, cityID)
  if busy and currentCity == key then return end -- our setter's own dirty event
  Guard(key, function() ReconcileID(id, cityID) end)
end
Hook(GameEvents, 'CityConstructed', BuildingChanged)
Hook(GameEvents, 'CitySoldBuilding', BuildingChanged)
Hook(Events, 'SpecificCityInfoDirty', BuildingChanged)
local function Initialize() Guard('initialize', ReconcileAll) end
Hook(Events, 'SequenceGameInitComplete', Initialize)
Hook(Events, 'LoadScreenClose', Initialize)
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(controller)
    if MapModData.CONICAL_Controller == controller then MapModData.CONICAL_Controller = nil end
    if __CONICAL_CONTEXT_CONTROLLER == controller then __CONICAL_CONTEXT_CONTROLLER = nil end
  end)
end
-- Safe when the context is created after the init notification or on save reload.
Initialize()
