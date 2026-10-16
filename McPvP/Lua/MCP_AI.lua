local M=MapModData.MCPVP
function M.AIMode(s)
 local flags,sabotage,military=0,0,0
 for u in Players[s.pid]:Units() do if M.Land(u) then
  military=military+1;local r=M.Record(s,u)
  if #M.EnemyCities(s,u,6)>0 then flags=flags+1;if M.Recon(u,r) then sabotage=sabotage+1 end end
 end end
 if sabotage>0 and (s.cycle+s.pid)%3==0 then return 'SAB' end
 if flags>0 and (s.cycle+s.pid)%2==0 then return 'CTF' end
 if military>0 then return 'HG' end
 return M.modes[(s.cycle+s.pid)%3+1]
end
function M.AIStep(u,goal)
 if not goal or not M.Land(u) or u:IsBusy() or u:MovesLeft()<=0 then return false end
 local best,bestD;local start=M.Distance(u,goal)
 for dir=0,5 do local plot=Map.PlotDirection(u:GetX(),u:GetY(),dir)
  if plot and M.ValidFeast(plot) and plot:GetNumUnits()==0 and plot:IsRevealed(Players[u:GetOwner()]:GetTeam()) and u:CanMoveOrAttackInto(plot,0,1) then
   local d=M.Distance(plot,goal);if d<start and (not bestD or d<bestD) then best,bestD=plot,d end
  end
 end
 if best then u:PushMission(MissionTypes.MISSION_MOVE_TO,best:GetX(),best:GetY(),0,0,1);return true end
 return false
end
function M.AITurn(s)
 if Players[s.pid]:IsHuman() then return end
 for u in Players[s.pid]:Units() do if M.Land(u) and not u:IsBusy() then local r=M.Record(s,u)
  if not r.kit and (r.eligible or r.veteran) and u:MovesLeft()>0 then
   local info=GameInfo.Units[u:GetUnitType()];local kit
   if M.Recon(u,r) then kit='KANGAROO'
   elseif u:GetPlot():IsHills() and not u:IsRanged() then kit='STOMPER'
   elseif u:IsRanged() then kit='VIPER'
   else kit=(r.serial+s.cycle)%4==0 and 'ENDERMAGE' or 'THOR' end
   M.SelectKit(s,u,kit)
  elseif r.flag then
   if not M.Objective(s,u,'RETURN') then
    local best,dist;for city in Players[s.pid]:Cities() do local d=M.Distance(u,city);if not dist or d<dist then best,dist=city:Plot(),d end end
    M.AIStep(u,best)
   end
  elseif not r.mission then
   local targets=M.AbilityTargets(s,u)
   if #targets>0 then M.Ability(s,u,targets[1])
   elseif s.mode=='CTF' or s.mode=='SAB' then
    local kind=s.mode=='CTF' and 'STEAL' or 'INFILTRATE';local cities=M.ObjectiveTargets(s,u,kind)
    if #cities>0 then M.Objective(s,u,kind,cities[1])
    elseif s.mode=='CTF' or M.Recon(u,r) then
     local nearby=M.EnemyCities(s,u,6);local goal=nearby[1]
     if goal and not (s.mode=='CTF' and s.raids[M.CityKey(goal)]) and not (s.mode=='SAB' and s.sabotaged[M.CityKey(goal)]) then M.AIStep(u,goal:Plot()) end
    end
   elseif s.mode=='HG' and s.feast and s.feast.status~='CLAIMED' and s.feast.status~='EXPIRED' and M.Turn()>=s.feast.active-M.Turns(3) then
    local plot=M.FeastPlot(s);if plot and M.Distance(u,plot)<=6 then M.AIStep(u,plot) end
   end
  end
 end end
end
