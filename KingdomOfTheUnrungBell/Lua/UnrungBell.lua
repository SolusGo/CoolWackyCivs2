-- One invisible simulation owner. BNW + CP v151, human-only.
-- Native FriendlyLandsModifier limitations are documented in docs/Implementation.md.
local localController = __UNRUNG_CONTROLLER
local previous = MapModData.UNRUNG_Controller
if localController and localController.active and previous == localController
  and localController.context == ContextPtr then return end
local T = GameInfoTypes
local CIV, BELFRY = T.CIVILIZATION_UNRUNG_BELL, T.BUILDING_UNRUNG_SILENT_BELFRY
if not (CIV and BELFRY) then print('UNRUNG: missing database identities'); return end
local PEACE_PER_STACK, MAX_STACKS, TOLL_WINDOWS = 5, 3, 5
local MAX_EXACT_INTEGER = 9007199254740991 -- Lua 5.1 doubles; reject corrupt overflow/rounding
local DEBUG = false
local tiers = {'I', 'II', 'III'}
local culture, science, toll = {}, {}, {}
for i, tier in ipairs(tiers) do
  culture[i] = T['BUILDING_UNRUNG_QUIETUDE_' .. tier]
  science[i] = T['BUILDING_UNRUNG_SCIENCE_' .. tier]
  toll[i] = T['PROMOTION_UNRUNG_GREAT_TOLL_' .. tier]
  if not (culture[i] and science[i] and toll[i]) then
    print('UNRUNG: missing effect identities'); return
  end
end
local function Retire(c)
  if not c then return end
  c.active = false
  for _, h in ipairs(c.handlers or {}) do
    pcall(function() if h.event.Remove then h.event.Remove(h.fn) end end)
  end
end
Retire(previous)
if localController ~= previous then Retire(localController) end
local controller = {active = true, context = ContextPtr, handlers = {}}
MapModData.UNRUNG_Controller, __UNRUNG_CONTROLLER = controller, controller
local maxPlayers = GameDefines.MAX_CIV_PLAYERS or 64
local owners, swept, writingCity, warnings = {}, {}, {}, {}
local store
local function Warn(key, err)
  if not warnings[key] then warnings[key] = true; print('UNRUNG: ' .. key .. ': ' .. tostring(err)) end
end
local function Try(key, fn)
  local ok, result = pcall(fn)
  if not ok then Warn(key, result) else warnings[key] = nil end
  return ok, result
end
local function Human(p)
  return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType() == CIV
end
for id = 0, maxPlayers - 1 do
  local p = Players[id]
  if p and p:GetCivilizationType() == CIV then owners[#owners + 1] = id end
end
local function War(p, a, b, value)
  local team = p:GetTeam()
  for id = 0, maxPlayers - 1 do
    local other = Players[id]
    if other and other:IsAlive() and not other:IsBarbarian() and other:GetTeam() ~= team then
      local enemy = other:GetTeam()
      local atWar = Teams[team]:IsAtWar(enemy)
      -- GameplayWarStateChanged fires after ONE side is changed. Override the
      -- notified pair so the second side cannot miss peace/war or clear early.
      if (team == a and enemy == b) or (team == b and enemy == a) then atWar = value end
      if atWar then return true end
    end
  end
  return false
end
local fields = {'peace','war','toll','windows','lastBegin','lastDone','blocked','skipBegin'}
local function Encode(s)
  local v = {'1'}
  for _, k in ipairs(fields) do v[#v + 1] = tostring(s[k]) end
  return table.concat(v, '|')
end
local function Decode(raw)
  if type(raw) ~= 'string' then return nil end
  local v = {}
  for n in string.gmatch(raw .. '|', '([^|]*)|') do
    if not string.match(n, '^%-?%d+$') then return nil end
    local number = tonumber(n)
    if not number or math.abs(number) > MAX_EXACT_INTEGER then return nil end
    v[#v + 1] = number
  end
  if #v ~= #fields + 1 or v[1] ~= 1 then return nil end
  local s = {}
  for i, k in ipairs(fields) do s[k] = v[i + 1] end
  if s.peace < 0 or (s.war ~= 0 and s.war ~= 1) or s.toll < 0 or s.toll > MAX_STACKS
    or s.windows < 0 or s.windows > TOLL_WINDOWS then return nil end
  for _, k in ipairs({'lastBegin','lastDone','blocked','skipBegin'}) do if s[k] < -1 then return nil end end
  if s.war == 1 and s.peace ~= 0 then return nil end
  if s.war == 0 and s.toll ~= 0 then return nil end
  if s.toll == 0 and s.windows ~= 0 then return nil end
  return s
end
local function Save(id, s)
  local raw = Encode(s)
  local ok = Try('save player ' .. id, function()
    store = store or Modding.OpenSaveData()
    -- Firaxis OpenSaveData methods use DOT notation. Single-row commit means
    -- consumption, war guard and duration cannot be saved independently.
    store.SetValue('UNRUNG_STATE_V1_' .. id, raw)
    assert(store.GetValue('UNRUNG_STATE_V1_' .. id) == raw, 'save readback failed')
  end)
  return ok
end
local function State(id)
  local p = Players[id]
  if not Human(p) then return nil end
  local ok, raw = Try('load player ' .. id, function()
    store = store or Modding.OpenSaveData()
    return store.GetValue('UNRUNG_STATE_V1_' .. id)
  end)
  if not ok then return nil end
  if raw ~= nil then
    local s = Decode(raw)
    if not s then Warn('invalid save ' .. id, 'unknown/corrupt version; effects disabled, record preserved') end
    return s
  end
  -- Never infer past peaceful turns when adding the mod or restoring no state.
  local s = {peace=0, war=War(p) and 1 or 0, toll=0, windows=0,
             lastBegin=-1, lastDone=-1, blocked=-1, skipBegin=-1}
  if Save(id, s) then return s end
end
local function Stacks(s)
  return s and s.war == 0 and math.min(MAX_STACKS, math.floor(s.peace / PEACE_PER_STACK)) or 0
end
local function Transition(id, s, atWar)
  local nextWar = atWar and 1 or 0
  if s.war == nextWar then return false end
  local p, now = Players[id], Game.GetGameTurn()
  if atWar then
    -- Snapshot BEFORE resetting progress, even during a multi-declaration cascade.
    s.toll, s.windows = Stacks(s), 0
    s.peace = 0
    s.skipBegin = p:IsTurnActive() and now or -1
  else
    s.toll, s.windows, s.skipBegin = 0, 0, -1
  end
  if p:IsTurnActive() then s.blocked = now end
  s.war = nextWar
  if DEBUG then print('UNRUNG transition', id, nextWar, s.toll) end
  return true
end
local function Set(city, building, count)
  if city:GetNumRealBuilding(building) ~= count then city:SetNumRealBuilding(building, count, true) end
end
local function City(city, state)
  if not city then return end
  local id = city:GetOwner()
  local key = id .. ':' .. city:GetID()
  if writingCity[key] then return end
  writingCity[key] = true
  Try('city ' .. key, function()
    local n = Human(Players[id]) and Stacks(state) or 0
    -- GetNumBuilding includes free copies, but ordinary Temples never qualify.
    local belfry = city:GetNumBuilding(BELFRY) > 0
    for i = 1, MAX_STACKS do
      Set(city, culture[i], n >= i and 1 or 0)
      Set(city, science[i], belfry and n >= i and 1 or 0)
    end
  end)
  writingCity[key] = nil
end
local function Cities(id, s)
  local p = Players[id]
  if p then for city in p:Cities() do City(city, s) end end
end
local function Unit(id, unit, s)
  if not unit then return end
  Try('unit ' .. id .. ':' .. unit:GetID(), function()
    local eligible = Human(Players[id]) and unit:GetOwner() == id
      and unit:GetDomainType() == DomainTypes.DOMAIN_LAND and unit:GetUnitCombatType() >= 0
      and (unit:GetBaseCombatStrength() > 0 or unit:GetBaseRangedCombatStrength() > 0)
    local strength = eligible and s and s.war == 1 and s.toll or 0
    for i = 1, MAX_STACKS do
      local wanted = strength == i
      if unit:IsHasPromotion(toll[i]) ~= wanted then unit:SetHasPromotion(toll[i], wanted) end
    end
    -- Never touch PROMOTION_UNRUNG_BELLWARDEN or any other permanent promotion.
  end)
end
local function Units(id, s)
  local p = Players[id]
  if p then for unit in p:Units() do Unit(id, unit, s) end end
end
local function Effects(id, s) Cities(id, s); Units(id, s) end
local function SyncWar(id, a, b, value)
  local p, s = Players[id], State(id)
  if not s then Effects(id, nil); return end
  if Transition(id, s, War(p, a, b, value)) then
    if not Save(id, s) then s = nil end
    Effects(id, s)
  end
end
local function Begin(id)
  if not Human(Players[id]) then return end
  local s, now = State(id), Game.GetGameTurn()
  if not s then Effects(id, nil); return end
  Transition(id, s, War(Players[id])) -- scoped fallback if a notification was missed
  if s.lastBegin ~= now then
    s.lastBegin = now
    if s.war == 1 then s.blocked = now end
    if s.toll > 0 and s.skipBegin ~= now then
      -- Window: [owner start, next owner start). Covers intervening enemy turns.
      -- Immediate partial activation window is extra; start #6 removes the Toll.
      if s.windows == TOLL_WINDOWS then s.toll, s.windows = 0, 0
      else s.windows = s.windows + 1 end
    end
    if not Save(id, s) then s = nil end
  else
    -- Transition might occur in a duplicated begin callback; persist its guard.
    if not Save(id, s) then s = nil end
  end
  Effects(id, s)
end
local function Done(id)
  if not Human(Players[id]) then return end
  local s, now = State(id), Game.GetGameTurn()
  if not s then Effects(id, nil); return end
  local changed = Transition(id, s, War(Players[id]))
  if s.lastDone ~= now then
    s.lastDone = now
    if s.war == 0 and s.blocked ~= now then s.peace = s.peace + 1 end
  end
  if not Save(id, s) then s = nil end
  Cities(id, s)
  -- A fallback peace/war transition must also repair units immediately.
  if changed or not s then Units(id, s) end
end
local function Hook(events, name, fn)
  local event = events and events[name]
  if not (event and event.Add) then Warn('missing hook ' .. name, 'native validation required'); return end
  local callback = function(...)
    if controller.active and MapModData.UNRUNG_Controller == controller then fn(...) end
  end
  event.Add(callback)
  controller.handlers[#controller.handlers + 1] = {event=event, fn=callback}
end
Hook(Events, 'WarStateChanged', function(a, b, value)
  for _, id in ipairs(owners) do
    local p = Players[id]
    if Human(p) and (p:GetTeam() == a or p:GetTeam() == b) then SyncWar(id, a, b, value) end
  end
end)
-- GameEvents.DeclareWar/MakePeace are PRE-change and have option-dependent
-- player/team ABIs. Deliberately do not consume Quietude from those hooks.
Hook(GameEvents, 'PlayerDoTurn', Begin)
Hook(GameEvents, 'PlayerDoneTurn', Done)
local function CityID(id, cityID)
  local p = Players[id]
  if p then City(p:GetCityByID(cityID), State(id)) end
end
Hook(Events, 'SpecificCityInfoDirty', CityID)
Hook(GameEvents, 'CityConstructed', CityID)
Hook(GameEvents, 'CitySoldBuilding', CityID)
local function PlotCity(x, y)
  local plot = Map.GetPlot(x, y)
  local city = plot and plot:GetPlotCity()
  if city then City(city, State(city:GetOwner())) end
end
Hook(GameEvents, 'PlayerCityFounded', function(id, x, y) PlotCity(x, y) end)
Hook(GameEvents, 'CityCaptureComplete', function(old, capital, x, y) PlotCity(x, y) end)
Hook(GameEvents, 'CityRazed', function(id, x, y) PlotCity(x, y) end)
local function UnitID(id, unitID)
  local p = Players[id]
  if p then Unit(id, p:GetUnitByID(unitID), State(id)) end
end
Hook(GameEvents, 'UnitCreated', UnitID)
Hook(GameEvents, 'CityTrained', function(id, city, unit) UnitID(id, unit) end)
-- CP v151 notifies UnitUpgraded BEFORE convert overwrites promotion membership.
-- UnitConverted below is the required post-copy repair for both normal/goody upgrades.
Hook(GameEvents, 'UnitUpgraded', function(id, old, new) UnitID(id, new) end)
Hook(GameEvents, 'UnitConverted', function(old, new, oldID, newID) UnitID(new, newID) end)
local function Initialize()
  for _, id in ipairs(owners) do SyncWar(id); Effects(id, State(id)) end
  -- One city/unit-list sanitation sweep per context, never a map scan or polling.
  for id = 0, maxPlayers - 1 do
    if not swept[id] and Players[id] and not Human(Players[id]) then
      Effects(id, nil); swept[id] = true
    end
  end
end
Hook(Events, 'SequenceGameInitComplete', Initialize)
Hook(Events, 'LoadScreenClose', Initialize)
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(controller)
    if MapModData.UNRUNG_Controller == controller then MapModData.UNRUNG_Controller = nil end
    if __UNRUNG_CONTROLLER == controller then __UNRUNG_CONTROLLER = nil end
  end)
end
Initialize() -- restore/reconcile only: never award a turn or advance a window
