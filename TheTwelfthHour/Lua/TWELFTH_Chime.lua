-- BNW / Community Patch v151. See docs/Implementation.md for native call order.
-- PlayerDoTurn is AFTER Production AND research. Stage NEXT turn at PlayerDoneTurn.
local civ = GameInfoTypes.CIVILIZATION_TWELFTH_HOUR
local chime = GameInfoTypes.BUILDING_TWELFTH_GRAND_CHIME
local towerChime = GameInfoTypes.BUILDING_TWELFTH_CLOCKTOWER_CHIME
local tower = GameInfoTypes.BUILDING_TWELFTH_MUNICIPAL_CLOCKTOWER
if not (civ and chime and towerChime and tower and GameEvents.PlayerDoneTurn) then
 print('[Twelfth Hour] Required CP v151 event/database entries missing; check Database.log.')
 return
end

-- OpenSaveData is the savegame database, shared by mods within that save.
-- Its returned functions use DOT calls (see Firaxis's shipped scenarios).
-- Open lazily inside protected work so a transient open failure can recover.
local save
local context = ContextPtr
local maxPlayers = GameDefines.MAX_CIV_PLAYERS or 64
local busy, armed, pending = false, false, {}
local notifiedHere = {}
local function key(name, id) return 'TWELFTH:v1:' .. name .. ':' .. id end
local function savedValue(name, id)
 if not save then save = Modding.OpenSaveData() end
 return save.GetValue(key(name, id))
end
local function storeValue(name, id, value)
 if not save then save = Modding.OpenSaveData() end
 save.SetValue(key(name, id), value)
end
local function isChime(rawTurn)
 -- GetStartTurn is immutable saved game state, including advanced-era starts.
 local played = rawTurn - Game.GetStartTurn() + 1
 return played > 0 and played % 6 == 0
end

local function targetTurn(id)
 local raw = Game.GetGameTurn()
 -- This is a phase marker, NOT a countdown. Old markers expire on raw turn change.
 -- Persisting it lets an interturn load keep the pre-staged yield state intact.
 if tonumber(savedValue('staged', id)) == raw then return raw + 1 end
 return raw
end

local function setCount(city, building, count)
 if city:GetNumRealBuilding(building) ~= count then
  -- bNoBonus=true suppresses construction rewards, not native yield recalculation.
  city:SetNumRealBuilding(building, count, true)
 end
end

local function syncCity(city, active)
 setCount(city, chime, active and 1 or 0)
 setCount(city, towerChime, active and city:GetNumBuilding(tower) > 0 and 1 or 0)
end

local function syncPlayer(id)
 local player = Players[id]
 if not player then return end
 local active = player:IsAlive() and player:GetCivilizationType() == civ and isChime(targetTurn(id))
 for city in player:Cities() do syncCity(city, active) end
end

local function guarded(fn, label)
 if busy then return end
 busy = true
 local ok, err = pcall(fn)
 if not ok then
  -- Idempotent writes permit one SYNCHRONOUS retry, including after a setter
  -- mutates then throws. A deferred-only retry could miss the next harvest.
  local firstError = err
  ok, err = pcall(fn)
  if ok then print('[Twelfth Hour] Recovered ' .. (label or 'synchronization') .. ': ' .. tostring(firstError)) end
 end
 busy = false
 if not ok then
  print('[Twelfth Hour] ' .. (label or 'Synchronization') .. ' failed twice on raw turn '
   .. Game.GetGameTurn() .. '; next lifecycle/turn event will retry: ' .. tostring(err))
 end
 return ok
end

local function notify(id)
 local player = Players[id]
 local raw = Game.GetGameTurn()
 if not player or not player:IsAlive() or not player:IsHuman() or player:GetCivilizationType() ~= civ
    or targetTurn(id) ~= raw or not isChime(raw)
    or tonumber(savedValue('notified', id)) == raw then return end
 if notifiedHere[id] ~= raw then
  player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
   Locale.ConvertTextKey('TXT_KEY_TWELFTH_CHIME_HELP'), Locale.ConvertTextKey('TXT_KEY_TWELFTH_CHIME'))
  notifiedHere[id] = raw
 end
 -- Do not mark a failed AddNotification as delivered. If persistence fails
 -- AFTER delivery, the synchronous retry only retries persistence.
 storeValue('notified', id, raw)
end

local function flush()
 context:ClearUpdate()
 armed = false
 local batch = pending
 pending = {}
 for id = 0, maxPlayers - 1 do
  if batch[id] then guarded(function() syncPlayer(id) end, 'refresh player ' .. id) end
 end
end

local function schedule(id)
 if busy or not Players[id] then return end
 pending[id] = true
 if not armed then armed = true; context:SetUpdate(flush) end
end

local function scheduleClockPlayers()
 if busy then return end
 for id = 0, maxPlayers - 1 do
  local player = Players[id]
  if player and player:GetCivilizationType() == civ then schedule(id) end
 end
end

local function hook(events, name, fn)
 if events[name] and events[name].Add then events[name].Add(fn) end
end

hook(GameEvents, 'PlayerDoneTurn', function(id)
 local player = Players[id]
 if not player or player:GetCivilizationType() ~= civ then return end
 -- Synchronous: deferred UI callbacks cannot be trusted to precede the next harvest.
 guarded(function()
  storeValue('staged', id, Game.GetGameTurn())
  syncPlayer(id)
 end, 'stage player ' .. id)
end)

hook(GameEvents, 'PlayerDoTurn', function(id)
 local player = Players[id]
 if not player or player:GetCivilizationType() ~= civ then return end
 guarded(function() syncPlayer(id); notify(id) end, 'turn player ' .. id)
end)

hook(GameEvents, 'PlayerCityFounded', function(id)
 guarded(function() syncPlayer(id) end, 'founding player ' .. tostring(id))
end)
hook(GameEvents, 'CityCaptureComplete', function(oldID, _, _, _, newID)
 -- CityCaptureComplete is after native reconstruction. Remove foreign dummies now.
 guarded(function() syncPlayer(oldID); syncPlayer(newID) end,
  'capture ' .. tostring(oldID) .. ' to ' .. tostring(newID))
end)
hook(GameEvents, 'CityConstructed', function(id, _, building)
 if building == tower then guarded(function() syncPlayer(id) end, 'construction player ' .. tostring(id)) end
end)
hook(GameEvents, 'CitySoldBuilding', function(id, _, building)
 -- CP ResponseSellBuilding calls DoSellBuilding BEFORE this hook.
 if building == tower then guarded(function() syncPlayer(id) end, 'sale player ' .. id) end
end)
-- Covers scripted building removal. Coalesce dirty storms; never poll every frame.
hook(Events, 'SerialEventGameDataDirty', scheduleClockPlayers)
hook(Events, 'LoadScreenClose', function()
 for id = 0, maxPlayers - 1 do
  guarded(function()
   syncPlayer(id)
   if Players[id] and Players[id]:IsTurnActive() then notify(id) end
  end, 'load player ' .. id)
 end
end)

-- Explicit first-turn/load repair, including stale bonuses under foreign owners.
for id = 0, maxPlayers - 1 do guarded(function() syncPlayer(id) end, 'initialize player ' .. id) end
