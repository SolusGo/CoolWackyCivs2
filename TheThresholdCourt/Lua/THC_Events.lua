local T=MapModData.ThresholdCourt
T.orphanSweeps={}
function T.Release(u)
 if u:IsHasPromotion(T.EXHAUSTED) then u:SetHasPromotion(T.EXHAUSTED,false) end
 assert(not u:IsHasPromotion(T.EXHAUSTED),'temporary promotion removal failed')
 assert(T.Write(u,'THC_U1',nil),'exhaustion record cleanup failed')
 assert(T.Write(u,'THC_O1',nil),'orphan record cleanup failed')
 -- Never set movement, attacks, damage, XP or any other promotion here.
end
local function EachUnit(fn)
 for _,p in pairs(Players) do
  if p:IsAlive() then for u in p:Units() do
   if T.Alive(u) then
    local ok,err=pcall(fn,u)
    if not ok then T.Warn('exhaustion cleanup '..u:GetOwner()..':'..u:GetID(),err) end
   end
  end end
 end
end
function T.Sync(pid,startTurn)
 if not T.Civ(pid) then return end
 local s=T.State(pid)
 if not s then
  -- Keep corrupt financial data untouched and portals disabled. A verified
  -- owner-turn still expires an independent, valid unit restriction.
  if startTurn then EachUnit(function(u)
   local stamp=T.ValidStamp(u)
   if stamp and stamp[1]==pid and stamp[2]<T.Turn() then T.Release(u) end
  end) end
  return
 end
 if startTurn and s[2]<T.Turn() then s[2]=T.Turn();if not T.Save(pid,s) then return end end
 -- Financial recovery must not defer a valid new owner-turn or re-exhaust it.
 local ok,err=pcall(T.Recover,pid)
 if not ok then T.Warn('receipt recovery '..pid,err) end
 for c in Players[pid]:Cities() do T.CityState(c) end
 -- Also release a unit gifted after crossing. No unmarked units are changed.
 EachUnit(function(u)
   local stamp=T.ValidStamp(u)
   if stamp and stamp[1]==pid then
    if stamp[2]<s[2] then
     T.Release(u)
     -- Native turn setup restores movement/attacks. Never grant moves here.
    else u:SetHasPromotion(T.EXHAUSTED,true);u:FinishMoves() end
   end
 end)
end
function T.CleanupEliminated()
 local dead,living={},false
 for pid,p in pairs(Players) do
  if p:GetCivilizationType()==T.CIV then
   if p:IsAlive() then living=true
   elseif T.orphanSweeps[pid]~=T.Turn() then dead[pid]=true;T.orphanSweeps[pid]=T.Turn() end
  end
 end
 if not next(dead) then return end
 -- Only a verified turn boundary calls this, at most once per dead owner per
 -- game turn. Never mutate a unit from an elimination/combat callback.
 EachUnit(function(u)
  local stamp=T.ValidStamp(u)
  if stamp then
   if dead[stamp[1]] and T.Turn()>stamp[2] then T.Release(u) end
  elseif u:IsHasPromotion(T.EXHAUSTED) then
   -- An unreadable origin must not release a living owner's unit early.
   -- If every possible Court origin is dead, persist one full quarantine turn
   -- before clearing only our temporary effect. Keep invalid raw data until
   -- that deliberate, logged cleanup; do not reset player/portal receipts.
   if living then T.Warn('orphan exhaustion','unknown origin; a Court owner is still alive');return end
   local seen,valid=T.Read(u,'THC_O1',1)
   if not valid then return end
   if not seen then T.Write(u,'THC_O1',{T.Turn()})
   elseif T.Turn()>seen[1] then
    T.Log('orphan exhaustion','clearing temporary effect after saved quarantine')
    T.Release(u)
   end
  end
 end)
end
T.Hook(GameEvents,'PlayerDoTurn',function(pid)
 T.Sync(pid,true);T.CleanupEliminated();if T.QueueRefresh then T.QueueRefresh() end
end)
T.Hook(GameEvents,'CanMoveInto',function(pid,uid,x,y,attack,declareWar)
 local p=Players[pid];local u=p and p:GetUnitByID(uid)
 if T.Restricted(u) then return x==u:GetX() and y==u:GetY() end
 return true
end,true)
T.Hook(GameEvents,'CanHaveUpgrade',function(pid,uid)
 local p=Players[pid];local u=p and p:GetUnitByID(uid)
 return not T.Restricted(u)
end,true)
T.Hook(GameEvents,'UnitSetXY',function(pid,uid)
 local p=Players[pid];local u=p and p:GetUnitByID(uid)
 if T.Restricted(u) then u:FinishMoves() end
 if T.QueueRefresh then T.QueueRefresh() end
end)
T.Hook(GameEvents,'UnitConverted',function(oldpid,newpid,oldid,newid)
 local old=Players[oldpid] and Players[oldpid]:GetUnitByID(oldid)
 local new=Players[newpid] and Players[newpid]:GetUnitByID(newid)
 if not old or not T.Alive(new) then return end
 local stamp=T.ValidStamp(old)
 if stamp then
  stamp[3]=new:GetGameTurnCreated();stamp[4]=new:GetUnitType()
  assert(T.Write(new,'THC_U1',stamp),'converted exhaustion record')
  if T.Restricted(new) then new:SetHasPromotion(T.EXHAUSTED,true);new:FinishMoves() end
 end
end)
local function ResetCity(x,y)
 local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
 if not plot or not city then return end
 local old,valid=T.Read(plot,'THC_C1',6)
 if T.Civ(city:GetOwner()) or (old and valid) then T.CityState(city,true) end
 if T.QueueRefresh then T.QueueRefresh() end
end
T.Hook(GameEvents,'PlayerCityFounded',function(pid,x,y) ResetCity(x,y) end)
T.Hook(GameEvents,'CityCaptureComplete',function(oldpid,capital,x,y) ResetCity(x,y) end)
T.Hook(Events,'ActivePlayerTurnStart',function() T.Sync(Game.GetActivePlayer(),true) end)
T.Hook(Events,'LoadScreenClose',function() T.Sync(Game.GetActivePlayer(),Players[Game.GetActivePlayer()] and Players[Game.GetActivePlayer()]:IsTurnActive()) end)
-- Bind current native objects after every context construction. No cached save
-- data or references survive a new add-in context; old hooks are detached.
for pid,p in pairs(Players) do if T.Civ(pid) then T.Sync(pid,p:IsTurnActive()) end end
