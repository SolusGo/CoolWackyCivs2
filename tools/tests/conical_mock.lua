-- Synthetic native boundary. No route search or engine yield settlement is mocked as fact.
function Event()
  local e = {handlers = {}}
  function e.Add(fn) e.handlers[#e.handlers + 1] = fn end
  function e.Remove(fn)
    for i=#e.handlers,1,-1 do if e.handlers[i]==fn then table.remove(e.handlers,i) end end
  end
  function e.Fire(...)
    local snapshot={};for i,fn in ipairs(e.handlers) do snapshot[i]=fn end
    for _,fn in ipairs(snapshot) do fn(...) end
  end
  return e
end
function NewContext()
  ContextPtr={SetUpdate=function() error('frame handler forbidden') end}
  function ContextPtr:SetShutdown(fn) self.shutdown=fn end
end
function ResetEvents(optional, keepShared)
  if not keepShared then MapModData = {} end
  NewContext()
  GameEvents = {}
  Events = {}
  for _, name in ipairs({'PlayerDoTurn','PlayerDoneTurn','PlayerCityFounded','CapitalChanged',
      'CityCaptureComplete','CityRazed','CityConstructed','CitySoldBuilding'}) do
    if optional or name == 'PlayerDoTurn' or name == 'PlayerCityFounded' or name == 'CityCaptureComplete' then
      GameEvents[name] = Event()
    end
  end
  for _, name in ipairs({'SpecificCityInfoDirty','SequenceGameInitComplete','LoadScreenClose'}) do
    Events[name] = Event()
  end
end
function RecreateConical(keepEvents, keepShared, shutdown)
  local old=ContextPtr
  if shutdown and old.shutdown then old.shutdown() end
  if keepEvents then
    NewContext()
    if not keepShared then MapModData={} end
  else ResetEvents(true,keepShared) end
  LoadConical()
  return old
end
ResetEvents(true)
GameDefines = {MAX_CIV_PLAYERS = 64}
Map = {GetPlot = function(x, y)
  local c = plots[x .. ':' .. y]
  if c then return {GetPlotCity = function() return c end} end
end}
Players = {}
plots = {}
O = GameInfoTypes.BUILDING_CONICAL_DETOUR_OFFICE
U = GameInfoTypes.BUILDING_CONICAL_CONNECTION_DUMMY
G = GameInfoTypes.BUILDING_CONICAL_DETOUR_GOLD_DUMMY
writes, queries, scans, reads, lookups = 0, 0, 0, 0, 0
function Player(id, conical)
  local p = {id=id, civ=conical and GameInfoTypes.CIVILIZATION_CONICAL_UNION or -10, alive=true, cities={}}
  function p:GetCivilizationType() return self.civ end
  function p:IsAlive() return self.alive end
  function p:GetCapitalCity() return self.capital end
  function p:GetCityByID(id) lookups=lookups+1;for _, c in ipairs(self.cities) do if c.id == id then return c end end end
  function p:Cities()
    scans=scans+1
    local i=0
    return function() i=i+1;return self.cities[i] end
  end
  Players[id]=p
  return p
end
function City(p, id, connected, office)
  local c = {owner=p.id, id=id, connected=connected, b={[O]=office and 1 or 0}, x=p.id*1000+id, y=0}
  function c:GetOwner() return self.owner end
  function c:GetID() return self.id end
  function c:GetNumRealBuilding(b)
    reads=reads+1
    if self.blockRead==b then error('persistent building getter failure') end
    return self.b[b] or 0
  end
  function c:IsConnectedToCapital() queries=queries+1;return self.connected end
  function c:SetNumRealBuilding(b, n, noBonus)
    assert(noBonus == true, 'native construction rewards must be suppressed')
    writes=writes+1
    if self.blockBuilding==b then error('persistent building setter failure') end
    if self.failBefore then self.failBefore=false;error('transient before write') end
    self.b[b]=n
    Events.SpecificCityInfoDirty.Fire(self.owner, self.id, 0)
    if self.onWrite then self.onWrite(b,n) end
    if self.failAfter then self.failAfter=false;error('transient after write') end
  end
  p.cities[#p.cities+1]=c
  plots[c.x .. ':' .. c.y]=c
  return c
end
function Transfer(c, target)
  local old = Players[c.owner]
  for i, v in ipairs(old.cities) do if v == c then table.remove(old.cities, i);break end end
  if old.capital == c then old.capital = old.cities[1] end
  c.owner=target.id
  local newID=0
  for _,other in ipairs(target.cities) do newID=math.max(newID,other.id+1) end
  c.id=newID -- native acquisition allocates an ID in the receiving player's list
  target.cities[#target.cities+1]=c
  -- Deliberately KEEP the dummy rows: test Lua cleanup independently of NeverCapture.
  GameEvents.CityCaptureComplete.Fire(old.id, false, c.x, c.y, target.id, 5, true)
end
function Check(c, production, culture, gold)
  assert(c:GetNumRealBuilding(U) <= 1 and c:GetNumRealBuilding(G) <= 1)
  local p, k, g = Harvest(c)
  assert(p == production and k == culture and g == gold,
    'unexpected yields ' .. p .. ',' .. k .. ',' .. g)
end
