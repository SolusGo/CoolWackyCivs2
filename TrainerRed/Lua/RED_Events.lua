local R=MapModData.RED_Legend
local H=R.Hook
-- A global project needs global vetoes, including games with no Red player.
H(GameEvents,'CityCanCreate',function(pid,city,project)
 if project~=R.PROJECT then return true end
 return R.IsRed(pid) and R.SilverEligible(R.State(pid))
end)
H(GameEvents,'PlayerCanCreate',function(pid,project)
 if project~=R.PROJECT then return true end
 return R.IsRed(pid) and R.SilverEligible(R.State(pid))
end)
local participating=false
for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if R.IsRed(pid) then participating=true end end
if not participating then return end
local pending,callbacks,armed={},{},false
local function arm()
 if armed then return end;armed=true
 ContextPtr:SetUpdate(function(dt)
  ContextPtr:ClearUpdate();armed=false;local todo,work=pending,callbacks;pending={};callbacks={}
  for _,fn in pairs(work) do local ok,err=pcall(fn,dt);if not ok then print('[Red] Deferred action: '..tostring(err)) end end
  for id=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if todo[id] then
   local ok,err=pcall(function()
    local s=R.State(id);R.RecoverAirlifts(s);R.Reconcile(s);R.ResumeSilver(s);R.RecoverAces(s);R.AutoAssign(s);R.Changed(s)
   end)
   if not ok then print('[Red] Reconcile: '..tostring(err)) end
  end end
 end)
end
function R.AfterNative(key,fn) callbacks[key]=fn;arm() end
function R.Defer(pid)
 if not R.IsRed(pid) or R.internal>0 then return end
 pending[pid]=true;arm()
end
function R.Attacked(u)
 if not R.IsRed(u:GetOwner()) then return u:IsOutOfAttacks() end
 local r=R.Peek(u);return (r and r.attackTurn==Game.GetGameTurn()) or u:IsOutOfAttacks()
end
H(GameEvents,'BattleStarted',R.BattleStart)
H(GameEvents,'BattleJoined',R.BattleJoin)
H(GameEvents,'BattleDamageDelta',R.DamageDelta)
H(GameEvents,'CombatResult',function(...)
 R.CombatResult(...)
 local pid,id=...;if R.IsRed(pid) then local u=Players[pid]:GetUnitByID(id)
  if u then local r,s=R.Record(u);if r then r.attackTurn=Game.GetGameTurn();R.Save(s) end end
 end
end)
H(GameEvents,'CombatEnded',R.FinishCombat)
H(GameEvents,'UnitCreated',function(pid,id)
 local u=Players[pid] and Players[pid]:GetUnitByID(id)
 if u then R.positions[pid..':'..id]={x=u:GetX(),y=u:GetY()} end
 R.Defer(pid)
end)
H(GameEvents,'UnitPromoted',function(pid,id)
 if R.internal>0 or not R.IsRed(pid) then return end
 local u=Players[pid]:GetUnitByID(id);local r=R.Peek(u)
 if r then R.Apply(u,r);R.Changed(R.State(pid)) end
end)
H(GameEvents,'UnitPrekill',function(pid,id,typ,x,y,delay,killer)
 R.positions[pid..':'..id]=nil
 if R.internal>0 then return end
 if R.battle then R.battle.dead[pid..':'..id]=true end
 if not R.IsRed(pid) then return end
 local u=Players[pid]:GetUnitByID(id);local n=u and R.Serial(u);local s=R.State(pid);local r=n and s.units[n]
 -- Conversion has already rebound r.id to its successor; the old prekill is harmless.
 if r and r.id==id and not r.withdrawn and not r.dead then
  R.RescueAce(s,r);r.dead=true;r.id=nil
  if r.slot then s.slots[r.slot]=nil;r.slot=nil end
  R.Yields(s);R.Changed(s);R.Defer(pid)
 end
end)
H(GameEvents,'UnitUpgraded',function(pid,oldID,newID,goody)
 if R.internal>0 or not R.IsRed(pid) then return end
 local p=Players[pid];local old=p:GetUnitByID(oldID);local new=p:GetUnitByID(newID)
 if not old or not new then return end
 local r,s=R.Record(old);if not r then return end
 local key=Game.GetGameTurn()..':'..oldID..':'..newID
 s.refunds=s.refunds or {}
 local city=old:GetPlot():GetPlotCity()
 if not goody and city and city:GetOwner()==pid and city:GetNumBuilding(R.CENTER)>0 and not s.refunds[key] then
  s.refunds[key]=true;R.Save(s);p:ChangeGold(math.floor(old:UpgradePrice(new:GetUnitType())*0.25))
 end
end)
H(GameEvents,'UnitConverted',function(oldOwner,newOwner,oldID,newID,isUpgrade)
 if R.internal>0 then return end
 local old=Players[oldOwner]:GetUnitByID(oldID);local new=Players[newOwner]:GetUnitByID(newID)
 if oldOwner==newOwner and R.IsRed(oldOwner) and old and new and isUpgrade then
  local r,s=R.Record(old)
  if r then
   r.lineage[#r.lineage+1]=GameInfo.Units[old:GetUnitType()].Type
   r.id=newID;r.unitType=GameInfo.Units[new:GetUnitType()].Type;R.Tag(new,r.serial);R.Apply(new,r);R.Yields(s);R.Changed(s)
  end
 elseif new and not R.IsRed(newOwner) then
  for promotion in GameInfo.UnitPromotions() do if promotion.Type:find('PROMOTION_RED_',1,true)==1 then new:SetHasPromotion(promotion.ID,false) end end
 end
 R.Defer(oldOwner);R.Defer(newOwner)
end)
H(GameEvents,'CityTrained',function(pid,cityID,unitID)
 if R.internal>0 or not R.IsRed(pid) then return end
 local p=Players[pid];local city=p:GetCityByID(cityID);local u=p:GetUnitByID(unitID)
 if city and u and R.Eligible(u) then
  local r,s=R.Record(u)
  if not r.startGranted then r.startGranted=true
   if city:GetNumBuilding(R.CENTER)>0 then r.training=math.max(15,r.training);R.Apply(u,r) end
   R.Changed(s)
  end
 end
end)
H(GameEvents,'CityConstructed',function(pid,cityID,bld)
 if R.IsRed(pid) then local s=R.State(pid);local b=GameInfo.Buildings[bld];local cls=b and GameInfo.BuildingClasses[b.BuildingClass]
  if bld==R.PLATEAU or (cls and cls.MaxPlayerInstances==1 and cls.MaxTeamInstances==-1 and cls.MaxGlobalInstances==-1 and (not b.IsDummy or b.IsDummy==0)) then s.full=true end
  R.AutoAssign(s);R.Yields(s);R.Changed(s)
 end
end)
H(GameEvents,'CityProjectComplete',function(pid,city,project)
 if project==R.PROJECT and R.IsRed(pid) then R.BeginSilver(R.State(pid)) end
end)
H(GameEvents,'CityCanAirlift',function(pid,cityID)
 return false -- Center grants are unit-specific; ordinary Airports remain native.
end)
H(GameEvents,'CanAirliftFrom',function(pid,id,x,y) return R.AirliftPermission(pid,id,x,y,false) end)
H(GameEvents,'CanAirliftTo',function(pid,id,x,y) return R.AirliftPermission(pid,id,x,y,true) end)
H(GameEvents,'BarbariansCampCleared',function(x,y,pid)
 if not R.IsRed(pid) then return end
 local plot=Map.GetPlot(x,y);if not plot then return end
 for i=0,plot:GetNumUnits()-1 do local u=plot:GetUnit(i)
  if u:GetOwner()==pid and R.Eligible(u) then R.AddTraining(u,8,false);break end
 end
end)
H(GameEvents,'CityCaptureComplete',function(oldOwner,wasCapital,x,y,newOwner,pop,conquest)
 -- Scrub foreign-held city dummies immediately; no benefits survive ownership transfer.
 local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
 if city and not R.IsRed(newOwner) then
  for _,name in ipairs({'RANK','HALL','ABSENCE'}) do for i=0,(name=='RANK' and 4 or name=='HALL' and 2 or 0) do
   city:SetNumRealBuilding(GameInfoTypes['BUILDING_RED_'..name..'_'..i],0,true)
  end end
 end
 if R.IsRed(newOwner) and conquest and city then
  local s=R.State(newOwner);local captor
  -- CombatResult has the exact attacking serial; fallback is the occupying melee unit.
  local b=R.battle;local a=b and b.actors[0]
  if a and a.pid==newOwner then captor=Players[newOwner]:GetUnitByID(a.id) end
  if not captor then for i=0,plot:GetNumUnits()-1 do local u=plot:GetUnit(i);if u:GetOwner()==newOwner and R.Eligible(u) then captor=u;break end end end
  if captor then R.AddTraining(captor,15,false) end
  local original=city:GetOriginalOwner();local founder=Players[original]
  local originalPlot=founder and founder:GetOriginalCapitalPlot()
  local key=original..':'..x..':'..y
  if original~=newOwner and founder and not founder:IsMinorCiv() and not founder:IsBarbarian() and originalPlot and originalPlot:GetX()==x and originalPlot:GetY()==y and not s.capitals[key] then
   s.capitals[key]=true;s.hall=math.min(5,s.hall+1);R.Save(s)
   Players[newOwner]:ChangeCombatExperience(math.floor(100*(R.Speed.GreatPeoplePercent or 100)/100+0.5))
   for _,r in ipairs(R.Team(s)) do local u=R.Unit(s,r.serial)
    if u then R.Heal(u,u:GetMaxHitPoints());r.ribbons=math.min(5,r.ribbons+1);R.Apply(u,r) end
   end
  end
  R.Yields(s);R.Changed(s)
 end
 R.Defer(oldOwner);R.Defer(newOwner)
end)
H(GameEvents,'TeamSetEra',function(team)
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if R.IsRed(pid) and Players[pid]:GetTeam()==team then R.Defer(pid) end end
end)
H(GameEvents,'UnitSetXY',R.Moved)
H(Events,'SerialEventUnitSetDamage',R.NativeHeal)
H(GameEvents,'PlayerDoTurn',function(pid)
 if not Players[pid] or not Players[pid]:IsAlive() then return end
 R.PartnerAura(pid)
 if not R.IsRed(pid) then return end
 local s=R.State(pid);R.RecoverAirlifts(s);R.Reconcile(s);R.ResumeSilver(s);R.RecoverAces(s);R.HealingFallback(s)
 if s.lastTurn~=Game.GetGameTurn() then
  s.lastTurn=Game.GetGameTurn();R.Save(s);R.Passive(s,false);R.AutoAssign(s);R.AITurn(s)
 end
 R.Yields(s);R.Changed(s)
end)
H(GameEvents,'PlayerDoneTurn',function(pid)
 if not R.IsRed(pid) then return end
 local s=R.State(pid)
 if s.lastDone~=Game.GetGameTurn() then s.lastDone=Game.GetGameTurn();R.Save(s);R.Passive(s,true)
  for u in Players[pid]:Units() do local r=R.Peek(u);if r then r.lastDamage=u:GetDamage() end end
  R.Changed(s)
 end
end)
H(Events,'LoadScreenClose',function()
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if R.IsRed(pid) then R.Defer(pid) end end
end)
-- Initial load reconstructs serials and native promotions before opening the panel.
for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if R.IsRed(pid) then R.Defer(pid) end end
for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if Players[pid] then
 for u in Players[pid]:Units() do R.positions[pid..':'..u:GetID()]={x=u:GetX(),y=u:GetY()} end
end end
