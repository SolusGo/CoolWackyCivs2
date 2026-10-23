-- One invisible InGameUIAddin context owns this stateless controller.
-- No persistent Lua city objects, map scans, timers, UI or saved data.
if MapModData.SABA_CitiesLoaded then return end
local CIV = GameInfoTypes.CIVILIZATION_SABA
local RIVER = GameInfoTypes.BUILDING_SABA_RIVER
local DESERT = GameInfoTypes.BUILDING_SABA_DESERT
local TERRAIN_DESERT = GameInfoTypes.TERRAIN_DESERT
if not CIV or not RIVER or not DESERT or not TERRAIN_DESERT then
  print('SABA: missing database identities; city controller not registered')
  return
end
MapModData.SABA_CitiesLoaded = true

local function Set(city, building, count)
  if city:GetNumRealBuilding(building) ~= count then
    city:SetNumRealBuilding(building, count)
  end
end

local function ReconcileCity(city)
  if not city then return end
  local player = Players[city:GetOwner()]
  local plot = city:Plot()
  local saba = player and player:GetCivilizationType() == CIV and plot
  Set(city, RIVER, saba and plot:IsRiver() and 1 or 0)
  Set(city, DESERT, saba and plot:GetTerrainType() == TERRAIN_DESERT and 1 or 0)
end

local function ReconcilePlayer(playerID)
  local player = Players[playerID]
  if player then
    -- Also remove stray Saba markers from non-Saba owners. Never touch other buildings.
    for city in player:Cities() do ReconcileCity(city) end
  end
end

local function ReconcileAll()
  for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do ReconcilePlayer(playerID) end
end

local function ReconcilePlot(x, y)
  local plot = Map.GetPlot(x, y)
  if plot then ReconcileCity(plot:GetPlotCity()) end
end

GameEvents.PlayerCityFounded.Add(function(playerID, x, y) ReconcilePlot(x, y) end)
-- CP acquireCity emits this after reconstruction, for conquest AND nonconquest
-- transfers. Liberation also goes through acquireCity. Read the current owner.
GameEvents.CityCaptureComplete.Add(function(oldOwner, capital, x, y) ReconcilePlot(x, y) end)
GameEvents.PlayerDoTurn.Add(ReconcilePlayer)
-- A destroyed city has no retained Lua identity. This hook safely handles either
-- an already-empty plot or a city still present during a native razing callback.
if GameEvents.CityRazed then
  GameEvents.CityRazed.Add(function(playerID, x, y) ReconcilePlot(x, y) end)
end
Events.SequenceGameInitComplete.Add(ReconcileAll)
-- Covers both new-game and saved-game context creation, even after init fired.
ReconcileAll()
