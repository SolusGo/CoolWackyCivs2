local M=MapModData.MCPVP
local function unitCache(u)
 local c=M.NavContext(u:GetOwner());local q=c.units[u:GetID()];local serial=M.Serial(u)
 if not q or q.born~=u:GetGameTurnCreated() or q.serial~=serial then
  q={born=u:GetGameTurnCreated(),serial=serial,failed={}};c.units[u:GetID()]=q
 end
 return q,c
end
local function cancelOwnOrder(u,q)
 local mission=u:LastMissionPlot()
 if q.pending and mission and mission:GetPlotIndex()==q.pending.to then u:PopMission() end
 q.pending=nil;q.plan=nil
end
local function cityGoals(s,u,kind,cities,upcoming)
 local goals={};local range=kind=='STEAL' and 1 or 2
 for i=1,math.min(4,#cities) do local city=cities[i];local ref=M.CityRef(city);local blocked=false
  if not upcoming then
   blocked=(kind=='STEAL' and s.raids[ref.key]) or (kind=='INFILTRATE' and s.sabotaged[ref.key])
   for _,r in pairs(s.units) do if r.mission and r.mission.target.key==ref.key then blocked=true end end
  end
  if not blocked then for dx=-range,range do for dy=-range,range do local plot=Map.GetPlot(ref.x+dx,ref.y+dy)
   if plot and not plot:IsCity() and M.Distance(city,plot)<=range and (plot==u:GetPlot() or M.NavEnter(s.pid,u,plot,{})) then
    goals[#goals+1]={plot=plot,key=kind..':'..ref.key..':'..plot:GetPlotIndex(),targetKey=kind..':'..ref.key,kind=kind,ref=ref}
   end
  end end end
 end
 return goals
end
local function nearby(s,u,range)
 local cities=M.EnemyCities(s,u,range)
 table.sort(cities,function(a,b) local ad,bd=M.Distance(u,a),M.Distance(u,b);if ad~=bd then return ad<bd end;return M.CityKey(a)<M.CityKey(b) end)
 return cities
end
function M.AIMode(s)
 local flags,military=false,0;local budget={calls=2,nodes=192}
 for u in Players[s.pid]:Units() do if M.Land(u) then
  military=military+1;local r=M.Record(s,u)
  if budget.calls>0 or budget.nodes>0 then
   local cities=nearby(s,u,12);local options={turns=math.min(12,M.Turns(20))}
   if M.Recon(u,r) and (s.cycle+s.pid)%3==0 and M.NavPlan(u,cityGoals(s,u,'INFILTRATE',cities,true),options,budget) then return 'SAB' end
   if M.NavPlan(u,cityGoals(s,u,'STEAL',cities,true),options,budget) then flags=true end
  end
 end end
 if flags and (s.cycle+s.pid)%2==0 then return 'CTF' end
 if military>0 then return 'HG' end
 return M.modes[(s.cycle+s.pid)%3+1]
end
function M.AITravel(s,u,goals,group,turns,safe)
 if not M.Land(u) or u:IsBusy() or u:MovesLeft()<=0 or turns<=0 then return false end
 local q,c=unitCache(u);local now=M.Turn();local here=u:GetPlot():GetPlotIndex()
 if q.moveTurn~=now then q.moveTurn=now;q.issued=0 end
 if q.issued>=8 then return false end -- real remaining movement accounts for roads and terrain
 if q.group~=group then cancelOwnOrder(u,q);q.group=group;q.failed={};q.stalls=0;q.retry=nil end
 q.cycle=s.cycle
 for key,untilTurn in pairs(q.failed) do if untilTurn<=now then q.failed[key]=nil end end
 local mission=u:LastMissionPlot()
 if mission and (not q.pending or mission:GetPlotIndex()~=q.pending.to) then return false end
 if q.pending then
  if here==q.pending.from then
   if now==q.pending.turn then return false end
   q.stalls=(q.stalls or 0)+1;q.plan=nil
   if q.stalls>=2 then q.failed[q.pending.target]=now+M.Turns(3);q.stalls=0 end
  else q.stalls=0 end
  local oldPlan=q.plan;cancelOwnOrder(u,q);q.plan=oldPlan
 end
 if q.retry and now<q.retry and q.retryFrom==here then return false end
 local available,map={},{}
 for _,g in ipairs(goals) do if not q.failed[g.targetKey or g.key] then available[#available+1]=g;map[g.key]=g end end
 if #available==0 then q.plan=nil;return false end
 local options={turns=math.min(12,turns),safe=safe}
 local nextPlot
 if q.plan and map[q.plan.goal.key] then
  for i,n in ipairs(q.plan.path) do if n==here and q.plan.path[i+1] then nextPlot=Map.GetPlotByIndex(q.plan.path[i+1]);break end end
  if nextPlot and not M.NavEnter(s.pid,u,nextPlot,options) then nextPlot=nil end
 end
 if not nextPlot then
  if c.planned>=4 then return false end;c.planned=c.planned+1
  local plan,reason=M.NavPlan(u,available,options,c.budget);q.plan=plan
  if not plan then
   if reason=='unreachable' then for _,g in ipairs(available) do q.failed[g.targetKey or g.key]=now+M.Turns(3) end
   else q.exhaustions=(q.exhaustions or 0)+1;if q.exhaustions>=2 then q.retry=now+M.Turns(2);q.retryFrom=here;q.exhaustions=0 end end
   return false
  end
  q.exhaustions=0;q.retry=nil
  nextPlot=plan.path[2] and Map.GetPlotByIndex(plan.path[2])
 end
 if not nextPlot or M.Distance(u,nextPlot)~=1 or not M.NavEnter(s.pid,u,nextPlot,options) then q.plan=nil;return false end
 q.pending={from=here,to=nextPlot:GetPlotIndex(),turn=now,target=q.plan.goal.targetKey or q.plan.goal.key}
 q.issued=q.issued+1
 -- One legal adjacent native order. No SetXY or combat mission; each turn
 -- revalidates the target and preserves unrelated native orders.
 u:PushMission(MissionTypes.MISSION_MOVE_TO,nextPlot:GetX(),nextPlot:GetY(),0,0,0)
 return true
end
function M.AIStep(u,goal)
 if not goal then return false end
 local key='STEP:'..goal:GetPlotIndex()
 return M.AITravel(M.State(u:GetOwner()),u,{{plot=goal,key=key,targetKey=key}},key,12,false)
end
local function returnGoals(s,u)
 local cities={};for city in Players[s.pid]:Cities() do cities[#cities+1]=city end
 table.sort(cities,function(a,b) return M.Distance(u,a)<M.Distance(u,b) end)
 local goals,seen={},{}
 for i=1,math.min(4,#cities) do local city=cities[i]
  for dx=-2,2 do for dy=-2,2 do local plot=Map.GetPlot(city:GetX()+dx,city:GetY()+dy)
   if plot and M.Distance(city,plot)<=2 and not seen[plot:GetPlotIndex()] and M.ReturnCity(s.pid,plot) then
    local key='RETURN:'..plot:GetPlotIndex();seen[plot:GetPlotIndex()]=true
    goals[#goals+1]={plot=plot,key=key,targetKey=key}
   end
  end end
 end
 return goals
end
local function pursue(s,u,r)
 if r.flag then
  if not M.FlagCity(r.flag) or not M.AtWar(s.pid,r.flag.owner) then M.DropFlag(s,r,u);return end
  if not M.Objective(s,u,'RETURN') then M.AITravel(s,u,returnGoals(s,u),'RETURN:'..s.cycle..':'..r.flag.key,s.finish-M.Turn(),true) end
 elseif s.mode=='CTF' or (s.mode=='SAB' and M.Recon(u,r)) then
  local kind=s.mode=='CTF' and 'STEAL' or 'INFILTRATE'
  if kind=='INFILTRATE' and M.Turn()+M.Turns(3)>=s.finish then return end
  local targets=M.ObjectiveTargets(s,u,kind)
  if #targets>0 then M.Objective(s,u,kind,targets[1])
  else M.AITravel(s,u,cityGoals(s,u,kind,nearby(s,u,12)),kind..':'..s.cycle,s.finish-M.Turn()-(kind=='INFILTRATE' and M.Turns(3) or 0),false) end
 elseif s.mode=='HG' and s.feast and s.feast.announced and (s.feast.status=='PREPARING' or s.feast.status=='ACTIVE') and M.Turn()<s.feast.expires then
  local plot=M.FeastPlot(s)
  if M.ValidFeast(plot) then local key='FEAST:'..s.cycle..':'..s.feast.plot
   M.AITravel(s,u,{{plot=plot,key=key,targetKey=key}},key,s.feast.expires-M.Turn(),false)
  end
 end
end
function M.AIContinue(s,u)
 if Players[s.pid]:IsHuman() or not Players[s.pid]:IsTurnActive() or not M.Land(u) or u:IsBusy() or u:MovesLeft()<=0 then return end
 local c=M.NavContext(s.pid);local q=c.units[u:GetID()];local r=M.Peek(s,u)
 if q and q.pending and q.pending.turn==M.Turn() and q.pending.to==u:GetPlot():GetPlotIndex() and r and not r.mission then pursue(s,u,r) end
end
function M.AITurn(s)
 if Players[s.pid]:IsHuman() then return end
 local c=M.NavContext(s.pid);local carriers,ordinary={},{}
 for id,q in pairs(c.units) do local u=Players[s.pid]:GetUnitByID(id)
  if not M.Alive(u) or u:GetGameTurnCreated()~=q.born or M.Serial(u)~=q.serial then c.units[id]=nil
  elseif q.cycle~=s.cycle or (q.plan and q.plan.goal.ref and not M.City(q.plan.goal.ref))
    or (q.group and q.group:sub(1,6)=='FEAST:' and (not s.feast or s.feast.status=='CLAIMED' or s.feast.status=='EXPIRED')) then
   cancelOwnOrder(u,q);c.units[id]=nil
  end
 end
 for u in Players[s.pid]:Units() do if M.Land(u) and not u:IsBusy() then local r=M.Record(s,u)
  if r.mission then u:SetMoves(0) -- retain the infiltrator inside its valid area
  elseif r.flag then carriers[#carriers+1]={u=u,r=r}
  elseif not u:LastMissionPlot() or (c.units[u:GetID()] and c.units[u:GetID()].pending) then
   if not r.kit and (r.eligible or r.veteran) and u:MovesLeft()>0 then
    local kit=M.Recon(u,r) and 'KANGAROO' or u:GetPlot():IsHills() and not u:IsRanged() and 'STOMPER' or u:IsRanged() and 'VIPER' or (r.serial+s.cycle)%4==0 and 'ENDERMAGE' or 'THOR'
    M.SelectKit(s,u,kit)
   else
    local targets=M.AbilityTargets(s,u)
    if #targets>0 then M.Ability(s,u,targets[1]) elseif u:MovesLeft()>0 then ordinary[#ordinary+1]={u=u,r=r} end
   end
  end
 end end
 local function visit(list,cursor)
  table.sort(list,function(a,b) return a.u:GetID()<b.u:GetID() end)
  if #list==0 then return end
  local start=(c[cursor] or 0)%#list
  for offset=1,#list do local entry=list[(start+offset-1)%#list+1];pursue(s,entry.u,entry.r) end
  c[cursor]=(start+1)%#list
 end
 visit(carriers,'flagCursor');visit(ordinary,'cursor')
end
