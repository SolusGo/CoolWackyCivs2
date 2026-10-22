-- BNW / CP v151. Sole context. All authoritative state is native, saved buildings.
-- Economics precedes PlayerDoTurn: prepare the NEXT pass at PlayerDoneTurn.
local DEBUG = false
local civ = GameInfoTypes.CIVILIZATION_WCIRCUS
local crew = GameInfoTypes.UNIT_WCIRCUS_CARNIVAL_CREW
local office = GameInfoTypes.BUILDING_WCIRCUS_TICKET_OFFICE
local festival = GameInfoTypes.BUILDING_WCIRCUS_FESTIVAL_YIELDS
local production = GameInfoTypes.BUILDING_WCIRCUS_TICKET_PRODUCTION
local expiration = GameInfoTypes.BUILDING_WCIRCUS_EXPIRATION
local eligible = GameInfoTypes.BUILDING_WCIRCUS_NEXT_ELIGIBLE
local pending = GameInfoTypes.BUILDING_WCIRCUS_PENDING_START
local staged = GameInfoTypes.BUILDING_WCIRCUS_STAGED_TURN
if not (civ and crew and office and festival and production and expiration and eligible
 and pending and staged and GameEvents.PlayerDoneTurn) then
 print('[Wandering Circus] Required CP v151/database entries missing; check Database.log.')
 return
end
local buildings = {festival, production, expiration, eligible, pending, staged}
local maxPlayers = GameDefines.MAX_CIV_PLAYERS or 64
local circusPlayers = {}
for id = 0, maxPlayers - 1 do
 if Players[id] and Players[id]:GetCivilizationType() == civ then circusPlayers[#circusPlayers+1] = id end
end
local busy, armed = false, false
local context = ContextPtr
local function log(message) if DEBUG then print('[Wandering Circus] ' .. message) end end
local function retry(fn, label)
 local ok, err = pcall(fn)
 if not ok then ok, err = pcall(fn) end -- at most two attempts per city
 if not ok then
  print('[Wandering Circus] ' .. label .. ' failed on raw turn ' .. Game.GetGameTurn() .. ': ' .. tostring(err))
 end
end
local function guarded(fn, label)
 if busy then return end
 busy = true
 retry(fn, label)
 busy = false
end
local function set(city, building, count)
 if city:GetNumRealBuilding(building) ~= count then city:SetNumRealBuilding(building, count, true) end
end
local function clear(city)
 for _, building in ipairs(buildings) do set(city, building, 0) end
end
local function qualifies(city, id, excludedUnit)
 local plot = Map.GetPlot(city:GetX(), city:GetY())
 if not plot then return false end
 for i = 0, plot:GetNumUnits() - 1 do
  local unit = plot:GetUnit(i)
  -- CP may turn a captured foreign Worker into the captor's class replacement.
  -- OriginalOwner persists through capture; those foreign workers still do not qualify.
  if unit and unit:GetOwner() == id and unit:GetOriginalOwner() == id
   and unit:GetID() ~= excludedUnit and unit:GetUnitType() == crew
   and not unit:IsDead() and not unit:IsDelayedDeath() then return true end
 end
 return false
end
local function valid(player, city, id)
 return player and player:IsAlive() and player:GetCivilizationType() == civ and city:GetOwner() == id
end
local function target(city)
 local raw = Game.GetGameTurn()
 -- Encoded (ending raw turn + 1). The next economic turn is raw+1 until rollover.
 return city:GetNumRealBuilding(staged) == raw + 1 and raw + 1 or raw
end
local function refreshCity(player, city, id, excludedUnit)
 if not valid(player, city, id) then clear(city); return end
 local turn = target(city)
 local expires = city:GetNumRealBuilding(expiration) - 1
 local starts = city:GetNumRealBuilding(pending) - 1
 if starts >= 0 and starts == Game.GetGameTurn() and player:IsTurnActive() then
  -- setTurnActive(true) precedes all owner economics. This RESERVED show has
  -- begun: a Crew loss later in that pass must not split Production/Gold/Culture.
  -- Interturn unit events already cancel invalid reservations while inactive.
  -- No dirty/movement event can originate a reservation or move its boundaries.
  set(city, expiration, starts + 3 + 1)
  set(city, eligible, starts + 12 + 1)
  set(city, pending, 0)
  expires = starts + 3
  log('Activated city ' .. city:GetID() .. ' at owner-turn ' .. starts)
  starts = -1
 end
 -- Pending starts can only be created by the completed-owner-turn sample below.
 -- Losing the last Crew BEFORE activation cancels the reservation and its payout.
 if starts >= 0 and (starts ~= turn or not qualifies(city, id, excludedUnit)) then
  set(city, pending, 0); starts = -1
 end
 local active = (expires >= 0 and turn >= expires - 3 and turn < expires) or starts == turn
 set(city, festival, active and 1 or 0)
 set(city, production, active and city:GetNumBuilding(office) > 0 and 1 or 0)
end
local function refreshPlayer(id, excludedUnit)
 local player = Players[id]
 if not player then return end
 for city in player:Cities() do
  retry(function() refreshCity(player, city, id, excludedUnit) end, 'refresh city ' .. id .. ':' .. city:GetID())
 end
end
local function stagePlayer(id)
 local player = Players[id]
 if not player or player:GetCivilizationType() ~= civ then return end
 local raw = Game.GetGameTurn()
 local nextTurn = raw + 1
 for city in player:Cities() do
  retry(function()
   if valid(player, city, id) and city:GetNumRealBuilding(staged) ~= raw + 1 then
    local expires = city:GetNumRealBuilding(expiration) - 1
    local ready = city:GetNumRealBuilding(eligible) - 1
    if nextTurn >= ready and nextTurn >= expires and qualifies(city, id) then
     set(city, pending, nextTurn + 1)
     log('Prepared city ' .. city:GetID() .. ' for owner-turn ' .. nextTurn)
    end
    -- Write phase LAST: a retry completes an interrupted preparation safely.
    set(city, staged, raw + 1)
   end
   refreshCity(player, city, id)
  end, 'stage city ' .. id .. ':' .. city:GetID())
 end
end
local function startPlayer(id)
 local player = Players[id]
 if not player or player:GetCivilizationType() ~= civ then return end
 refreshPlayer(id)
end
local function refreshCircus()
 for _, id in ipairs(circusPlayers) do guarded(function() refreshPlayer(id) end, 'refresh player ' .. id) end
end
local function flush()
 context:ClearUpdate(); armed = false
 refreshCircus()
end
local function schedule()
 if busy or armed or #circusPlayers == 0 then return end
 armed = true; context:SetUpdate(flush)
end
local function hook(events, name, fn)
 if events[name] and events[name].Add then events[name].Add(fn) end
end
hook(GameEvents, 'PlayerDoneTurn', function(id) guarded(function() stagePlayer(id) end, 'stage turn') end)
hook(GameEvents, 'PlayerDoTurn', function(id) guarded(function() startPlayer(id) end, 'start turn') end)
hook(GameEvents, 'PlayerCityFounded', function(id) guarded(function() refreshPlayer(id) end, 'found city') end)
hook(GameEvents, 'CityCaptureComplete', function(_, _, x, y, newID)
 guarded(function()
  -- Reacquire by plot AFTER reconstruction; never retain old/deleted City userdata.
  local plot = Map.GetPlot(x, y)
  local city = plot and plot:GetPlotCity()
  if city and city:GetOwner() == newID then clear(city) end
 end, 'clear transferred city')
end)
local function buildingChanged(id, _, building)
 if building == office then guarded(function() refreshPlayer(id) end, 'Ticket Office change') end
end
hook(GameEvents, 'CityConstructed', buildingChanged)
hook(GameEvents, 'CitySoldBuilding', buildingChanged)
hook(Events, 'SpecificCityInfoDirty', function(id, cityID)
 local player = Players[id]
 if not player or player:GetCivilizationType() ~= civ then return end
 guarded(function()
  -- CP's real-building setter publishes this AFTER the count/effects change.
  local city = player:GetCityByID(cityID)
  if city then refreshCity(player, city, id) end
 end, 'specific city change')
end)
hook(GameEvents, 'UnitPrekill', function(id, unitID, unitType)
 if unitType == crew then guarded(function() refreshPlayer(id, unitID) end, 'Crew removal') end
end)
hook(GameEvents, 'UnitSetXY', function(id, unitID)
 local player = Players[id]
 local unit = player and player:GetUnitByID(unitID)
 if unit and unit:GetUnitType() == crew then
  guarded(function() refreshPlayer(id) end, 'Crew relocation')
 end
end)
-- Dirty events may reconcile effects, but NEVER create pending starts.
hook(Events, 'SerialEventGameDataDirty', schedule)
hook(Events, 'SerialEventCityInfoDirty', schedule)
hook(Events, 'LoadScreenClose', refreshCircus)
-- Clean foreign leftovers too; native NeverCapture additionally prevents transfers.
for id = 0, maxPlayers - 1 do guarded(function() refreshPlayer(id) end, 'load player ' .. id) end
