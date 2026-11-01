-- Single simulation owner, in one InGameUIAddin. See docs/Implementation.md.
local previous = MapModData.TRI_Controller
if previous and previous.active and previous.context == ContextPtr then return end
local function Retire(controller)
  if not controller then return end
  controller.active = false
  for _, h in ipairs(controller.handlers) do h.event.Remove(h.callback) end
end
Retire(previous)
TRI = {}
include('TRI_State')
include('TRI_Bonuses')
local controller = {active=true, context=ContextPtr, handlers={}}
MapModData.TRI_Controller = controller
function TRI.Hook(events, name, callback)
  local event = assert(events[name], 'TRI: required event missing: '..name)
  local wrapped = function(...)
    if controller.active and MapModData.TRI_Controller == controller then return callback(...) end
  end
  event.Add(wrapped)
  controller.handlers[#controller.handlers+1] = {event=event, callback=wrapped}
end
local battle
local function MemberKey(player, unit) return player..':'..unit end
TRI.Hook(GameEvents, 'BattleStarted', function(kind, x, y)
  -- v151: melee=0, ranged=1, air=2, sweep=3, paradrop=4, nuclear=5.
  -- Only native, attributed lethal combat notifications can consume these records.
  battle = kind >= 0 and kind <= 5 and {members={}, pending={}} or nil
end)
TRI.Hook(GameEvents, 'BattleJoined', function(id, unitID, role, isCity)
  if not battle then return end
  if isCity then
    battle.members['CITY:'..id..':'..unitID] = {owner=id, city=true, role=role}
  else
    local unit = Players[id] and Players[id]:GetUnitByID(unitID)
    if unit then
      battle.members[MemberKey(id, unitID)] = {
        owner=id, id=unitID, kind=unit:GetUnitType(), born=unit:GetGameTurnCreated(),
        military=TRI.IsMilitary(unit), role=role}
    end
  end
end)
TRI.Hook(GameEvents, 'BattleFinished', function() battle = nil end)
TRI.Hook(GameEvents, 'UnitPrekill', function(victimID, unitID, kind, x, y, delayed, killerID)
  -- NEVER award from prekill. It also reports upgrades, gifts, disbands and deletion.
  if not battle or not TRI.IsImperium(Players[killerID]) or not TRI.IsMajor(Players[victimID])
      or not TRI.AreEnemies(Players[killerID], Players[victimID]) then return end
  local key = MemberKey(victimID, unitID)
  local member = battle.members[key]
  local unit = Players[victimID]:GetUnitByID(unitID)
  if not member or not member.military or member.kind ~= kind or not unit
      or member.born ~= unit:GetGameTurnCreated() or not unit:IsDead()
      or TRI.Get(unit, 'KILL') then return end
  local opponent = false
  for _, other in pairs(battle.members) do
    if other.owner == killerID and other.role ~= member.role then opponent = true; break end
  end
  if not opponent then return end
  -- The unit still exists during delayed-death notification. Keep its exact identity.
  battle.pending[key] = {owner=victimID, id=unitID, kind=kind, killer=killerID, unit=unit}
end)
TRI.Hook(GameEvents, 'UnitKilledInCombat', function(killerID, victimID, kind, killerUnitID)
  -- CvPlayer::DoUnitKilledCombat reports killer owner, victim owner, victim TYPE,
  -- killing unit ID (usually -1). Consume one matching lethal participant receipt.
  if not battle then return end
  for key, death in pairs(battle.pending) do
    if death.killer == killerID and death.owner == victimID and death.kind == kind then
      battle.pending[key] = nil
      if not TRI.Get(death.unit, 'KILL') then
        TRI.Put(death.unit, 'KILL', 1)
        TRI.Change(Players[killerID], 1, true)
      end
      return
    end
  end
end)
TRI.Hook(GameEvents, 'CityCaptureComplete', function(oldID, capital, x, y, newID, population, conquest)
  local plot = Map.GetPlot(x,y)
  local city = plot and plot:GetPlotCity()
  if not city or city:GetOwner() ~= newID then return end
  local receipt = table.concat({Game.GetGameTurn(), oldID, newID, TRI.CityIdentity(city)}, ':')
  if TRI.Get(plot, 'CAPTURE') == receipt then return end
  TRI.Put(plot, 'CAPTURE', receipt)
  TRI.Put(plot, 'HALL', nil) -- ownership-dependent eligibility never transfers
  local player = Players[newID]
  if conquest == true and oldID ~= newID and TRI.IsImperium(player)
      and TRI.IsMajor(Players[oldID]) then
    TRI.Put(plot, 'HALL', newID..':'..TRI.CityIdentity(city))
    local reward = 'REWARD_'..newID
    if not TRI.Get(plot, reward) then
      -- Site-wide lifetime receipt prevents gift/recapture and raze/refound farming.
      TRI.Put(plot, reward, 1)
      TRI.Change(player, 2, true)
    end
    -- A recapture is still a qualifying victory and renews Hall eligibility.
    TRI.Put(player, 'WIN', 1)
  end
  TRI.SyncCity(city) -- clears inherited dummies immediately for every new owner
end)
TRI.Hook(GameEvents, 'PlayerCityFounded', function(id, x, y)
  local plot = Map.GetPlot(x,y)
  local city = plot and plot:GetPlotCity()
  if city then
    TRI.Put(plot, 'HALL', nil); TRI.Put(plot, 'CAPTURE', nil)
    TRI.SyncCity(city)
  end
end)
TRI.Hook(GameEvents, 'TeamTechResearched', function(team, tech, change)
  if tech ~= GameInfoTypes.TECH_BRONZE_WORKING then return end
  for _, player in pairs(Players) do
    if TRI.IsImperium(player) and player:GetTeam() == team then
      for city in player:Cities() do TRI.SyncCity(city) end
    end
  end
end)
local function SyncUnit(id, unitID)
  local player = Players[id]
  TRI.SyncUnit(player and player:GetUnitByID(unitID))
end
TRI.Hook(GameEvents, 'UnitCreated', SyncUnit)
TRI.Hook(GameEvents, 'UnitConverted', function(oldID, newID, oldUnit, newUnit)
  -- Conversion finishes copying promotions BEFORE this hook.
  local source = Players[oldID] and Players[oldID]:GetUnitByID(oldUnit)
  local hadMarch = source and source:IsHasPromotion(TRI.march)
  SyncUnit(newID, newUnit)
  local unit = Players[newID] and Players[newID]:GetUnitByID(newUnit)
  -- Native conversion copies current moves even when LostOnGifting/Upgrade has
  -- already dropped March. The still-live source identifies that inherited excess.
  if hadMarch and unit and not unit:IsHasPromotion(TRI.march) and unit:MovesLeft() > unit:MaxMoves() then
    unit:SetMoves(unit:MaxMoves())
  end
end)
-- v151 UnitUpgraded is PRE-conversion; UnitConverted above owns the final result.
TRI.Hook(GameEvents, 'UnitUpgraded', function(id, oldUnit, newUnit) SyncUnit(id, newUnit) end)
TRI.Hook(GameEvents, 'CityTrained', function(id, city, unit) SyncUnit(id, unit) end)
TRI.Hook(GameEvents, 'UnitSetXY', SyncUnit) -- one unit only; catches unusual owner transfers
local function HallChanged(id, cityID, building)
  if building == TRI.hall then
    local city = Players[id] and Players[id]:GetCityByID(cityID)
    if city then TRI.SyncCity(city) end
  end
end
TRI.Hook(GameEvents, 'CityConstructed', HallChanged)
TRI.Hook(GameEvents, 'CitySoldBuilding', HallChanged)
TRI.Hook(GameEvents, 'CityCanConstruct', function(id, cityID, building)
  if building == TRI.hallActive then return false end
  for i=1,6 do if building == TRI.buildings[i] then return false end end
  return true
end)
TRI.Hook(GameEvents, 'PlayerDoTurn', function(id)
  local player = Players[id]
  if not TRI.IsImperium(player) then return end
  local turn = Game.GetGameTurn()
  local last = tonumber(TRI.Get(player, 'BOUNDARY'))
  if last and turn > last then
    -- Record boundary and clear the complete previous cycle BEFORE publishing changes.
    local won = TRI.Get(player, 'WIN') == '1'
    TRI.Put(player, 'BOUNDARY', turn); TRI.Put(player, 'WIN', 0)
    if not won then TRI.Change(player, -1, false) end
  elseif not last then
    TRI.Put(player, 'BOUNDARY', turn); TRI.Put(player, 'WIN', 0)
  end
  -- Once per owner turn, not per frame; also repairs unusual foreign script changes.
  TRI.RefreshEmpire(player)
  if TRI.RefreshUI then TRI.RefreshUI() end
end)
local function Initialize()
  for _, player in pairs(Players) do
    if player then
      if TRI.IsImperium(player) and not TRI.Get(player, 'BOUNDARY') then
        TRI.Put(player, 'BOUNDARY', Game.GetGameTurn())
        TRI.Put(player, 'M', 0); TRI.Put(player, 'WIN', 0)
      end
      -- Reconstruct, never replay rewards or advance a turn on load.
      TRI.RefreshEmpire(player)
    end
  end
end
Initialize()
TRI.Hook(Events, 'SequenceGameInitComplete', Initialize)
TRI.Hook(Events, 'LoadScreenClose', Initialize)
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(controller)
    if MapModData.TRI_Controller == controller then MapModData.TRI_Controller = nil end
  end)
end
