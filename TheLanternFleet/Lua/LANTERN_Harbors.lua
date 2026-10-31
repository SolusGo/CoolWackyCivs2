-- BNW / CP151. Persistent building counts ARE the economic snapshot.
-- No movement, load-screen or building-completion reconciliation.
local previous = MapModData.LANTERN_Controller
if previous and previous.active and previous.context == ContextPtr then return end
local function Retire(state)
  if not state then return end
  state.active = false
  for _, h in ipairs(state.handlers or {}) do
    if h.event.Remove then h.event.Remove(h.callback) end
  end
end
Retire(previous)
local T = GameInfoTypes
local CIV, LIGHTHOUSE = T.CIVILIZATION_LANTERN_FLEET, T.BUILDING_LANTERN_SIGNAL_LIGHTHOUSE
local HARBOR, GOLD = T.BUILDING_LANTERN_GUARDED_HARBOR, T.BUILDING_LANTERN_SIGNAL_GOLD
if not (CIV and LIGHTHOUSE and HARBOR and GOLD) then
  print('LANTERN: missing database identities; controller disabled')
  return
end
local controller = {active=true, context=ContextPtr, handlers={}}
MapModData.LANTERN_Controller = controller
local busy = false
local function Set(city, id, count)
  if city:GetNumRealBuilding(id) ~= count then city:SetNumRealBuilding(id, count) end
end
local function LastTurn(player)
  local data = player:GetScriptData() or ''
  local value = data:match('%[LANTERN1|(%-?%d+)%]')
  local _, copies = data:gsub('%[LANTERN1|', '')
  assert(copies <= 1 and (copies == 0 or value), 'invalid Lantern turn receipt')
  return value and tonumber(value) or nil
end
local function Stamp(player, turn)
  local old = player:GetScriptData() or ''
  local block = '[LANTERN1|'..turn..']'
  local new, count = old:gsub('%[LANTERN1|%-?%d+%]', function() return block end)
  if count == 0 then new = old..block end
  player:SetScriptData(new)
  assert(player:GetScriptData() == new, 'Lantern turn receipt not saved')
end
local function Qualifies(city, owner)
  if city:GetOwner() ~= owner or not city:IsCoastal(-1) then return false end
  local plot = city:Plot()
  if not plot then return false end
  for index = 0, plot:GetNumUnits()-1 do
    local unit = plot:GetUnit(index)
    if unit and unit:GetOwner() == owner and not unit:IsDead() and not unit:IsDelayedDeath()
        and not unit:IsEmbarked() and unit:GetDomainType() == DomainTypes.DOMAIN_SEA
        and unit:IsCombatUnit() then return true end
  end
  return false
end
local function Snapshot(id)
  local player = Players[id]
  if not player or not player:IsAlive() or not player:IsTurnActive() then return end
  if player:GetCivilizationType() ~= CIV then return end
  local turn = Game.GetGameTurn()
  if LastTurn(player) == turn then return end
  local targets = {}
  -- Freeze every city before any setter can publish a dirty event.
  for city in player:Cities() do
    local guarded = Qualifies(city, id)
    targets[#targets+1] = {city=city, harbor=guarded and 1 or 0,
      gold=guarded and city:GetNumBuilding(LIGHTHOUSE) > 0 and 1 or 0}
  end
  -- Receipt suppresses reentrant/duplicate notifications and ordinary reloads.
  -- It is not an economic ledger; saved real-building counts hold the yields.
  Stamp(player, turn)
  for _, target in ipairs(targets) do
    Set(target.city, HARBOR, target.harbor)
    Set(target.city, GOLD, target.gold)
  end
end
local function Guard(label, work, ...)
  if busy then return end
  busy = true
  local ok, err = pcall(work, ...)
  busy = false
  if not ok then print('LANTERN: '..label..': '..tostring(err)) end
end
local function Hook(events, name, callback)
  local event = events and events[name]
  assert(event and event.Add, 'LANTERN required event missing: '..name)
  local wrapped = function(...)
    if controller.active and MapModData.LANTERN_Controller == controller then callback(...) end
  end
  event.Add(wrapped)
  controller.handlers[#controller.handlers+1] = {event=event, callback=wrapped}
end

-- CP151 CvPlayer::setTurnActive publishes TURN_START before doTurn(), city
-- processing, DoGold(), Culture and doResearch(). AIProcessingStartedForPlayer
-- is the candidate executable notification used by installed TurnProcessing.lua.
-- Its exact mapping/synchronous dispatch requires native acceptance: Testing.md.
-- PlayerDoTurn is too late and is deliberately NOT an economic fallback.
Hook(Events, 'AIProcessingStartedForPlayer', function(id, tag)
  -- Tagged status updates are progress notifications, not owner-turn boundaries.
  if tag ~= nil and tag ~= '' then return end
  Guard('turn start '..tostring(id), Snapshot, id)
end)
Hook(GameEvents, 'CityCaptureComplete', function(oldOwner, capital, x, y, newOwner)
  Guard('capture cleanup', function()
    local plot = Map.GetPlot(x,y)
    local city = plot and plot:GetPlotCity()
    if city then Set(city,HARBOR,0); Set(city,GOLD,0) end
  end)
end)

-- A context introduced/recreated mid-turn must not manufacture a snapshot.
-- Existing receipts and ALL building counts are left untouched on normal load.
for _, player in pairs(Players) do
  if player and player:IsAlive() and player:GetCivilizationType() == CIV
      and player:IsTurnActive() and LastTurn(player) == nil then
    Stamp(player, Game.GetGameTurn())
  end
end
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(controller)
    if MapModData.LANTERN_Controller == controller then MapModData.LANTERN_Controller = nil end
  end)
end
