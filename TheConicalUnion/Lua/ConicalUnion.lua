-- BNW / CP v151. One invisible InGameUIAddin owns both conditional buildings.
-- Native IsConnectedToCapital reads a cached network flag, not a fresh search.
-- See docs/Implementation.md for the exact event/settlement synchronization gap.
if MapModData.CONICAL_ControllerLoaded then return end
local CIV = GameInfoTypes.CIVILIZATION_CONICAL_UNION
local CONNECTION = GameInfoTypes.BUILDING_CONICAL_CONNECTION_DUMMY
local GOLD = GameInfoTypes.BUILDING_CONICAL_DETOUR_GOLD_DUMMY
local OFFICE = GameInfoTypes.BUILDING_CONICAL_DETOUR_OFFICE
if not (CIV and CONNECTION and GOLD and OFFICE) then
  print('CONICAL: missing database identities; controller not registered')
  return
end
MapModData.CONICAL_ControllerLoaded = true
local busy, warned = false, false

local function Set(city, building, count)
  if city:GetNumRealBuilding(building) ~= count then
    -- Suppress construction rewards; normal native yield recalculation remains.
    city:SetNumRealBuilding(building, count, true)
  end
end

local function ReconcileConicalCity(player, city)
  if not city then return end
  -- Always verify the ACTUAL owner: capture callbacks may refer to former owners.
  local owner = Players[city:GetOwner()]
  local eligible = owner and owner == player and owner:IsAlive()
    and owner:GetCivilizationType() == CIV
  local connected = false
  if eligible then
    local capital = owner:GetCapitalCity()
    if capital and capital:GetID() ~= city:GetID() then
      if type(city.IsConnectedToCapital) == 'function' then
        local ok, result = pcall(city.IsConnectedToCapital, city)
        connected = ok and result == true
        if not ok and not warned then
          print('CONICAL: native connection query failed; conditional yields disabled until retry')
          warned = true
        end
      elseif not warned then
        print('CONICAL: City:IsConnectedToCapital unavailable; conditional yields disabled')
        warned = true
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

local function ReconcilePlayer(id)
  local player = Players[id]
  if not IsConical(player) then return end
  for city in player:Cities() do ReconcileConicalCity(player, city) end
end

local function ReconcileAll()
  -- Only enumerate cities of relevant players. Never iterate map plots/foreign cities.
  for id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do ReconcilePlayer(id) end
end

local function Guard(fn)
  if busy then return end
  busy = true
  local ok, err = pcall(fn)
  if not ok then ok, err = pcall(fn) end -- idempotent synchronous recovery
  busy = false
  if not ok then print('CONICAL: reconciliation failed; next event retries: ' .. tostring(err)) end
end

local function Hook(events, name, fn)
  if events[name] and events[name].Add then events[name].Add(fn) end
end

local function ReconcileID(id, cityID)
  local player = Players[id]
  if not player then return end
  local city = player:GetCityByID(cityID)
  if not city then return end
  -- The targeted foreign path also clears markers if another script transfers a
  -- city and publishes its dirty event before/without CityCaptureComplete.
  if IsConical(player) or city:GetNumRealBuilding(CONNECTION) > 0
      or city:GetNumRealBuilding(GOLD) > 0 then
    ReconcileConicalCity(player, city)
  end
end

Hook(GameEvents, 'PlayerDoTurn', function(id) Guard(function() ReconcilePlayer(id) end) end)
Hook(GameEvents, 'PlayerDoneTurn', function(id) Guard(function() ReconcilePlayer(id) end) end)
Hook(GameEvents, 'PlayerCityFounded', function(id) Guard(function() ReconcilePlayer(id) end) end)
Hook(GameEvents, 'CapitalChanged', function(id) Guard(function() ReconcilePlayer(id) end) end)
Hook(GameEvents, 'CityCaptureComplete', function(oldOwner, wasCapital, x, y, newOwner)
  Guard(function()
    -- Reacquire the reconstructed city; never keep old/deleted City userdata.
    local plot = Map.GetPlot(x, y)
    local city = plot and plot:GetPlotCity()
    if city then ReconcileConicalCity(Players[city:GetOwner()], city) end
    ReconcilePlayer(oldOwner)
    if newOwner ~= oldOwner then ReconcilePlayer(newOwner) end
  end)
end)
Hook(GameEvents, 'CityRazed', function(id) Guard(function() ReconcilePlayer(id) end) end)
local function BuildingChanged(id, cityID)
  Guard(function() ReconcileID(id, cityID) end)
end
Hook(GameEvents, 'CityConstructed', BuildingChanged)
Hook(GameEvents, 'CitySoldBuilding', BuildingChanged)
Hook(Events, 'SpecificCityInfoDirty', BuildingChanged)
Hook(Events, 'SequenceGameInitComplete', function() Guard(ReconcileAll) end)
Hook(Events, 'LoadScreenClose', function() Guard(ReconcileAll) end)
-- Safe when the context is created after the init notification or on save reload.
Guard(ReconcileAll)
