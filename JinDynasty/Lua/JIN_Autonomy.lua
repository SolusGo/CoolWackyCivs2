-- Native local orders only from one deferred callback after native processing returns.
local J=MapModData.JIN
local C,S=J.C,J.S
J.executing={}
function J.CanStartMission(id,uid,mission)
 local p=Players[id];local u=p and p:GetUnitByID(uid)
 if not u or (u:GetUnitType()~=J.Unit(id,'DEFENDER') and u:GetUnitType()~=J.Unit(id,'GRENADIER')) then return true end
 local marker=u and S.Read(u,'JIN_D1')
 if not marker then return true end
 return type(marker)=='table' and marker.owner==id and J.executing[id..':'..uid]==true and (mission==MissionTypes.MISSION_MOVE_TO or mission==MissionTypes.MISSION_RANGE_ATTACK)
end
function J.ParentValid(id,s,r)
 local plot=J.Plot(r.plot);if not plot or plot:GetOwner()~=id then return false end
 if (r.parent or r.key):sub(1,1)=='f' then return s.upgrades.MENGAN_EMPLACEMENT and not plot:IsImprovementPillaged() and (plot:GetImprovementType()==J.T.IMPROVEMENT_FORT or plot:GetImprovementType()==J.T.IMPROVEMENT_CITADEL) end
 local city=J.City(id,r)
 return city and (s.upgrades.MENGAN_EMPLACEMENT or J.Has(id,s,'DRAGON_PAVILION') or city:GetNumBuilding(J.Building('GREAT_WALL_BASTION'))>0) or false
end
function J.QueuePatrol(id)
 if not J.IsJin(id) or Game.GetActivePlayer()~=id or not Players[id]:IsTurnActive() then return end
 J.Defer('patrol'..id,function()J.Patrol(id)end)
end
local function legalStep(id,u,home,p)
 if not p or p:IsCity() or p:IsWater() or p:IsMountain() or p:IsImpassable() or J.Distance(home,p)>C.defenderLeash then return false end
 if not p:IsVisible(Players[id]:GetTeam(),false) then return false end
 for i=0,p:GetNumUnits()-1 do local other=p:GetUnit(i);if other and (other:GetOwner()~=id or other:IsCombatUnit()) then return false end end
 return u:CanMoveOrAttackInto(p,0,1)
end
function J.Patrol(id)
 if not J.active or not J.IsJin(id) or J.busy[id] or J.patrolling or Game.GetActivePlayer()~=id or not Players[id]:IsTurnActive() then return end
 local pending=J.pendingCombat
 if pending then
  local a=Players[pending.ap] and Players[pending.ap]:GetUnitByID(pending.au)
  local d=Players[pending.dp] and Players[pending.dp]:GetUnitByID(pending.du)
  if (J.Alive(a) and (a:IsFighting() or a:IsBusy())) or (J.Alive(d) and (d:IsFighting() or d:IsBusy())) then return end
  J.pendingCombat=nil
 end
 local s=J.State(id);if not s then return end
 J.Defenders(id,s,false)
 local ids={};for uid in pairs(s.defenders) do ids[#ids+1]=uid end;table.sort(ids)
 J.patrolling=true
 local ok,err=pcall(function()
  for _,uid in ipairs(ids) do
   s=J.State(id);if not s then break end
   local r=s.defenders[uid];local u=Players[id]:GetUnitByID(uid)
   if r and J.Alive(u) and r.born==u:GetGameTurnCreated() and J.ParentValid(id,s,r) and r.acted~=J.Now() and not u:IsBusy() and not u:IsFighting() and not u:IsOutOfAttacks() and u:MovesLeft()>0 then
    local home=J.Plot(r.plot);local targets={}
    for _,p in ipairs(J.Near(home,C.defenderLeash)) do for i=0,p:GetNumUnits()-1 do local enemy=p:GetUnit(i)
     if not p:IsCity() and J.CombatTarget(id,enemy) then targets[#targets+1]={owner=enemy:GetOwner(),uid=enemy:GetID(),plot=J.Index(p),home=J.Distance(home,p),distance=J.Distance(u:GetPlot(),p)} end
    end end
    table.sort(targets,function(a,b)
     if a.home~=b.home then return a.home<b.home end
     if a.distance~=b.distance then return a.distance<b.distance end
     if a.owner~=b.owner then return a.owner<b.owner end;return a.uid<b.uid
    end)
    local target,attack
    if u:IsRanged() then
     for _,candidate in ipairs(targets) do local p=J.Plot(candidate.plot)
      if u:CanRangeStrikeAt(p:GetX(),p:GetY(),true,false) then target=candidate;attack='RANGED';break end
     end
    elseif targets[1] and targets[1].distance==1 then
     local p=J.Plot(targets[1].plot);J.executing[id..':'..uid]=true
     if u:CanMoveOrAttackInto(p,0,1) then target=targets[1];attack='MELEE' end
     J.executing[id..':'..uid]=nil
    end
    local destination
    if not attack then
     local goal=targets[1] and J.Plot(targets[1].plot) or home;local best=J.Distance(u:GetPlot(),goal)
     J.executing[id..':'..uid]=true
     for _,p in ipairs(J.Near(u:GetPlot(),1)) do
      local distance=J.Distance(p,goal)
      if distance<best and legalStep(id,u,home,p) then best=distance;destination=p end
     end
     J.executing[id..':'..uid]=nil
    end
    -- Persist the one-order budget before native calls can synchronously reenter Lua.
    r.acted=J.Now();r.mode=attack or (destination and (#targets>0 and 'APPROACH' or 'RETURN') or 'GUARD');J.Save(id,s)
    if attack or destination then
     J.executing[id..':'..uid]=true
     if attack then
      local p=J.Plot(target.plot);J.pendingCombat={ap=id,au=uid,dp=target.owner,du=target.uid}
      if attack=='RANGED' then u:RangeStrike(p:GetX(),p:GetY())
      else u:PushMission(MissionTypes.MISSION_MOVE_TO,p:GetX(),p:GetY(),0,0,0,-1,nil,nil) end
     else u:PushMission(MissionTypes.MISSION_MOVE_TO,destination:GetX(),destination:GetY(),0,0,0,-1,nil,nil) end
     J.executing[id..':'..uid]=nil
     if J.Alive(u) then u:FinishMoves() end
     if attack then break end -- finish this native combat before considering another defender
    else u:FinishMoves() end
   end
  end
 end)
 J.executing={};J.patrolling=false
 if not ok then print('JIN patrol: '..tostring(err)) end
 J.Refresh(true)
end
