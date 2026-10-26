local T=MapModData.ThresholdCourt
function T.Sync(pid,startTurn)
 if not T.Civ(pid) then return end
 if not T.Recover(pid) then return end
 local s=T.State(pid);if not s then return end
 if startTurn and s[2]<T.Turn() then s[2]=T.Turn();if not T.Save(pid,s) then return end end
 for c in Players[pid]:Cities() do T.CityState(c) end
 -- Also release a unit gifted after crossing. No unmarked units are changed.
 for _,p in pairs(Players) do
  if p:IsAlive() then for u in p:Units() do
   local stamp,valid=T.Stamp(u)
   if valid and stamp and stamp[1]==pid then
    if stamp[2]<s[2] then
     u:SetHasPromotion(T.EXHAUSTED,false);T.Write(u,'THC_U1',nil)
     -- Native turn setup restores movement/attacks. Never grant moves here.
    else u:SetHasPromotion(T.EXHAUSTED,true);u:FinishMoves() end
   end
  end end
 end
end
T.Hook(GameEvents,'PlayerDoTurn',function(pid) T.Sync(pid,true);if T.QueueRefresh then T.QueueRefresh() end end)
T.Hook(GameEvents,'CanMoveInto',function(pid,uid,x,y)
 local p=Players[pid];local u=p and p:GetUnitByID(uid)
 if not T.Alive(u) then return true end
 -- Fast return for other civilizations. Gifted units retain our promotion.
 if not T.Civ(pid) and not u:IsHasPromotion(T.EXHAUSTED) then return true end
 if T.Locked(u) then return x==u:GetX() and y==u:GetY() end
 return true
end,true)
T.Hook(GameEvents,'CanHaveUpgrade',function(pid,uid)
 local p=Players[pid];local u=p and p:GetUnitByID(uid)
 if not T.Alive(u) or (not T.Civ(pid) and not u:IsHasPromotion(T.EXHAUSTED)) then return true end
 return not T.Locked(u)
end,true)
T.Hook(GameEvents,'UnitSetXY',function(pid,uid)
 local p=Players[pid];local u=p and p:GetUnitByID(uid)
 if T.Alive(u) and u:IsHasPromotion(T.EXHAUSTED) and T.Locked(u) then u:FinishMoves() end
 if T.QueueRefresh then T.QueueRefresh() end
end)
T.Hook(GameEvents,'UnitConverted',function(oldpid,newpid,oldid,newid)
 local old=Players[oldpid] and Players[oldpid]:GetUnitByID(oldid)
 local new=Players[newpid] and Players[newpid]:GetUnitByID(newid)
 if not old or not T.Alive(new) then return end
 local stamp,valid=T.Stamp(old)
 if valid and stamp then
  stamp[3]=new:GetGameTurnCreated();stamp[4]=new:GetUnitType()
  assert(T.Write(new,'THC_U1',stamp),'converted exhaustion record')
  if T.Locked(new) then new:SetHasPromotion(T.EXHAUSTED,true);new:FinishMoves() end
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
