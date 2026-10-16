-- BNW / CP v151. This context is the sole owner of these event subscriptions.
-- No persistent Lua ledger: every count is reconstructed from current routes.
local civ = GameInfoTypes.CIVILIZATION_PIGEON_REPUBLIC
local science = GameInfoTypes.BUILDING_PIGEON_ROUTE_SCIENCE
local culture = GameInfoTypes.BUILDING_PIGEON_ROUTE_CULTURE
local production = GameInfoTypes.BUILDING_PIGEON_ROOST_PRODUCTION
local roost = GameInfoTypes.BUILDING_PIGEON_ROOFTOP_ROOST
local renaissance = GameInfoTypes.ERA_RENAISSANCE
if not (civ and science and culture and production and roost and renaissance) then
 print('[Pigeons] Required database entries missing; check Database.log.')
 return
end

local context = ContextPtr
local queued, armed, busy = {}, false, false
local pigeonPlayers = {}
for id = 0, (GameDefines.MAX_CIV_PLAYERS or 64) - 1 do
 local player = Players[id]
 if player and player:GetCivilizationType() == civ then pigeonPlayers[#pigeonPlayers + 1] = id end
end

local function setCount(city, building, amount)
 if city:GetNumRealBuilding(building) ~= amount then
  -- The third parameter suppresses construction rewards; native yield updates still run.
  city:SetNumRealBuilding(building, amount, true)
 end
end

local function refreshPlayer(id)
 local player = Players[id]
 if not player then return end
 local eligible = player:IsAlive() and player:GetCivilizationType() == civ
 local routesByCity = {}
 if eligible then
  for _, route in ipairs(player:GetTradeRoutes() or {}) do
   -- CP v151 CvLuaPlayer::lGetTradeRoutes: FromID is a player ID,
   -- FromCity is a City object, and Domain is a DomainTypes integer.
   local origin = route.FromCity
   if route.Domain == DomainTypes.DOMAIN_LAND and route.FromID == id
      and origin and origin:GetOwner() == id then
    local cityID = origin:GetID()
    if player:GetCityByID(cityID) then
     routesByCity[cityID] = (routesByCity[cityID] or 0) + 1
    end
   end
  end
 end
 local perRoute = eligible and player:GetCurrentEra() >= renaissance and 3 or 2
 for city in player:Cities() do
  local routes = routesByCity[city:GetID()] or 0
  local bonus = routes * perRoute
  setCount(city, science, bonus)
  setCount(city, culture, bonus)
  setCount(city, production, eligible and routes > 0 and city:GetNumBuilding(roost) > 0 and 1 or 0)
 end
end

local function flush()
 -- Detach before writing: no permanent per-frame callback, including after an error.
 context:ClearUpdate()
 armed = false
 local pending = queued
 queued = {}
 busy = true
 local ok, err = pcall(function()
  -- Stable player order; retain no City userdata beyond this function call.
  for id = 0, (GameDefines.MAX_CIV_PLAYERS or 64) - 1 do
   if pending[id] then refreshPlayer(id) end
  end
 end)
 busy = false
 if not ok then print('[Pigeons] Trade refresh failed: ' .. tostring(err)) end
end

local function schedule(id)
 if busy or not Players[id] then return end
 queued[id] = true
 if not armed then
  armed = true
  context:SetUpdate(flush)
 end
end

local function schedulePigeons()
 for _, id in ipairs(pigeonPlayers) do schedule(id) end
end

local function hook(events, name, fn)
 if events[name] and events[name].Add then events[name].Add(fn) end
end

-- Required authoritative turn fallback for humans AND AI, even with no UI dirty event.
hook(GameEvents, 'PlayerDoTurn', function(id)
 if busy then return end
 busy = true
 local ok, err = pcall(refreshPlayer, id)
 busy = false
 if not ok then print('[Pigeons] Turn refresh failed: ' .. tostring(err)) end
end)
-- Completion fires BEFORE ClearTradeRoute in CP; always wait for native return.
hook(GameEvents, 'PlayerTradeRouteCompleted', function(fromID) schedule(fromID) end)
hook(GameEvents, 'PlayerPlunderedTradeRoute', function(_, _, _, fromID) schedule(fromID) end)
-- Establishing a route consumes its caravan AFTER CreateTradeRoute succeeds.
-- UnitPrekill is also useful when a trade unit is destroyed; no route arithmetic here.
hook(GameEvents, 'UnitPrekill', function(id, _, unitType)
 if unitType == GameInfoTypes.UNIT_CARAVAN or unitType == GameInfoTypes.UNIT_CARGO_SHIP then schedule(id) end
end)
hook(GameEvents, 'TeamSetEra', function(teamID)
 for _, id in ipairs(pigeonPlayers) do
  if Players[id]:GetTeam() == teamID then schedule(id) end
 end
end)
hook(GameEvents, 'CityConstructed', function(id, _, building)
 if building == roost then schedule(id) end
end)
hook(GameEvents, 'CitySoldBuilding', function(id, _, building)
 if building == roost then schedule(id) end
end)
hook(GameEvents, 'CityCaptureComplete', function(oldID, _, _, _, newID)
 -- Covers conquest, gifting and liberation; cleans non-Pigeon recipients too.
 schedule(oldID)
 schedule(newID)
 schedulePigeons() -- A captured destination also cancels other players' routes.
end)
hook(Events, 'WarStateChanged', schedulePigeons)
-- Existing BNW/CP data dirty event covers route establishment and scripted removal.
-- Requests coalesce into one callback; writes ignore their own synchronous dirties.
hook(Events, 'SerialEventGameDataDirty', schedulePigeons)
hook(Events, 'LoadScreenClose', schedulePigeons)

-- On context creation/load, scrub any old dummies in all owners' cities.
for id = 0, (GameDefines.MAX_CIV_PLAYERS or 64) - 1 do schedule(id) end
