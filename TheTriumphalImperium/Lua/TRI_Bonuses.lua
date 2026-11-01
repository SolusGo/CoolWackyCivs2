-- Only one native promotion/production tier is ever active. No incremental stats.
local T = GameInfoTypes
TRI.promotions, TRI.buildings, TRI.barracks = {}, {}, {}
for i=1,6 do
  TRI.promotions[i] = assert(T['PROMOTION_TRI_MOMENTUM_'..i])
  TRI.buildings[i] = assert(T['BUILDING_TRI_MOBILISATION_'..i])
end
TRI.march = assert(T.PROMOTION_TRI_VICTORIOUS_MARCH)
TRI.advance = assert(T.PROMOTION_TRI_UNBROKEN_ADVANCE)
TRI.unbroken = assert(T.UNIT_TRI_UNBROKEN)
TRI.hall = assert(T.BUILDING_TRI_HALL_OF_TRIUMPHS)
TRI.hallActive = assert(T.BUILDING_TRI_MOBILISATION_HALL_ACTIVE)
for row in GameInfo.Buildings() do
  if row.BuildingClass == 'BUILDINGCLASS_BARRACKS' and row.ID ~= TRI.hall then
    TRI.barracks[#TRI.barracks+1] = row.ID
  end
end
local function Promotion(unit, id, wanted)
  if unit:IsHasPromotion(id) ~= wanted then unit:SetHasPromotion(id, wanted) end
end
local function Building(city, id, count)
  if city:GetNumRealBuilding(id) ~= count then city:SetNumRealBuilding(id, count) end
end
function TRI.SyncUnit(unit)
  if not unit or unit:IsDead() or unit:IsDelayedDeath() then return end
  local player = Players[unit:GetOwner()]
  local level = TRI.IsImperium(player) and TRI.IsMilitary(unit) and TRI.Momentum(player) or 0
  for i=1,6 do Promotion(unit, TRI.promotions[i], level == i) end
  if unit:GetUnitType() == TRI.unbroken then Promotion(unit, TRI.advance, true) end
  local march = level >= 4 and unit:GetUnitType() == TRI.unbroken
  local hadMarch = unit:IsHasPromotion(TRI.march)
  Promotion(unit, TRI.march, march)
  -- changeExtraMoves only changes the allowance; never refill current movement.
  if hadMarch and not march and unit:MovesLeft() > unit:MaxMoves() then
    unit:SetMoves(unit:MaxMoves())
  end
end
function TRI.TryHall(player, city)
  local plot = city:Plot()
  local pending = TRI.Get(plot, 'HALL')
  if not pending then return end
  if not TRI.IsImperium(player) or city:GetOwner() ~= player:GetID()
      or pending ~= player:GetID()..':'..TRI.CityIdentity(city) then
    TRI.Put(plot, 'HALL', nil); return
  end
  if not Teams[player:GetTeam()]:IsHasTech(T.TECH_BRONZE_WORKING) then return end
  -- Clear the receipt first: building setters can publish dirty UI events.
  TRI.Put(plot, 'HALL', nil)
  if city:GetNumBuilding(TRI.hall) == 0 then
    -- Replace only other members of the SAME Barracks class, never other buildings.
    for _, id in ipairs(TRI.barracks) do Building(city, id, 0) end
    Building(city, TRI.hall, 1)
  end
end
function TRI.SyncCity(city)
  local player = Players[city:GetOwner()]
  local level = TRI.IsImperium(player) and TRI.Momentum(player) or 0
  TRI.TryHall(player, city)
  for i=1,6 do Building(city, TRI.buildings[i], level == i and 1 or 0) end
  Building(city, TRI.hallActive,
    level >= 4 and city:GetNumBuilding(TRI.hall) > 0 and 1 or 0)
end
function TRI.RefreshEmpire(player)
  for unit in player:Units() do TRI.SyncUnit(unit) end
  for city in player:Cities() do TRI.SyncCity(city) end
end
function TRI.Change(player, amount, victory)
  local old = TRI.Momentum(player)
  local new = math.max(0, math.min(6, old + amount))
  if victory then TRI.Put(player, 'WIN', 1) end -- even at the cap, reset inactivity
  if new == old then return end
  TRI.Put(player, 'M', new)
  TRI.RefreshEmpire(player)
  if TRI.RefreshUI then TRI.RefreshUI() end
  -- At most one ordinary gain notice per global turn; maximum/decay remain visible.
  local turn = Game.GetGameTurn()
  if new == 6 and old < 6 then
    if tonumber(TRI.Get(player, 'MAXNOTICE')) ~= turn then
      TRI.Put(player, 'MAXNOTICE', turn); TRI.Notice(player, 'MAX', new)
    end
  elseif amount < 0 then
    TRI.Notice(player, 'DECAY', new)
  elseif tonumber(TRI.Get(player, 'GAINNOTICE')) ~= turn then
    TRI.Put(player, 'GAINNOTICE', turn); TRI.Notice(player, 'GAIN', new)
  end
end
