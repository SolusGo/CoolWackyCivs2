-- Minimal native boundary for the shipped controller. NOT Civ V engine tests.
local function Event()
  local e = {handlers = {}}
  function e.Add(f) e.handlers[#e.handlers + 1] = f end
  function e.Fire(...)
    for _, f in ipairs(e.handlers) do f(...) end
  end
  return e
end
function ResetContext()
  MapModData = {}
  Events = {SequenceGameInitComplete = Event()}
  GameEvents = {PlayerCityFounded = Event(), CityCaptureComplete = Event(),
                PlayerDoTurn = Event(), CityRazed = Event()}
end
ResetContext()
GameDefines = {MAX_CIV_PLAYERS = 64}
Players = {}
plots = {}
writes = 0
plotLookups = 0
for i = 0, 63 do
  local p = {id = i, civ = i == 0 and GameInfoTypes.CIVILIZATION_SABA or -1, cities = {}}
  function p:GetCivilizationType() return self.civ end
  function p:Cities()
    local index = 0
    return function() index = index + 1; return self.cities[index] end
  end
  Players[i] = p
end
Map = {}
function Map.GetPlot(x, y)
  plotLookups = plotLookups + 1
  return plots[x .. ':' .. y]
end
function MakeCity(owner, x, y, terrain, river, hills, feature)
  local c = {owner = owner, x = x, y = y, b = {}}
  local p = {terrain = terrain, river = river, hills = hills, feature = feature, city = c}
  function p:IsRiver() return self.river end
  function p:GetTerrainType() return self.terrain end
  function p:GetPlotCity() return self.city end
  function c:Check() assert(not self.dead, 'stale city object') end
  function c:GetOwner() self:Check(); return self.owner end
  function c:Plot() self:Check(); return p end
  function c:GetNumRealBuilding(b) self:Check(); return self.b[b] or 0 end
  function c:SetNumRealBuilding(b, n)
    self:Check(); assert(n == 0 or n == 1); self.b[b] = n; writes = writes + 1
  end
  plots[x .. ':' .. y] = p
  Players[owner].cities[#Players[owner].cities + 1] = c
  return c
end
function Transfer(c, owner, fire)
  local old = c.owner
  for i, peer in ipairs(Players[old].cities) do
    if peer == c then table.remove(Players[old].cities, i); break end
  end
  c.owner = owner
  Players[owner].cities[#Players[owner].cities + 1] = c
  if fire then GameEvents.CityCaptureComplete.Fire(old, false, c.x, c.y, owner, 5, false) end
end
function Raze(c)
  -- Simulate destruction before CityRazed: dereferencing c afterwards must fail.
  local owner, x, y = c.owner, c.x, c.y
  for i, peer in ipairs(Players[owner].cities) do
    if peer == c then table.remove(Players[owner].cities, i); break end
  end
  plots[x .. ':' .. y].city = nil
  c.dead = true
  GameEvents.CityRazed.Fire(owner, x, y)
end
function Counts(c, r, d)
  assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_SABA_RIVER) == r)
  assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_SABA_DESERT) == d)
end
