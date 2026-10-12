local B=MapModData.BoundlessCity
B.AIBuilds={};B.AIBuildSet={}
for row in GameInfo.Unit_Builds{UnitType='UNIT_BC_SURVEYOR'} do
 local build=GameInfo.Builds[B.ID(row.BuildType)]
 if build and (build.ImprovementType or build.Repair==true or build.Repair==1) then B.AIBuilds[#B.AIBuilds+1]=build.ID;B.AIBuildSet[build.ID]=true end
end
table.sort(B.AIBuilds)
B.Config.AICandidates=24;B.Config.AIPathsPerTurn=12;B.Config.AIRetryTurns=3
function B.AICandidates(s)
 local cache=B.Ownership(s)
 if cache.aiCandidates and not cache.aiDirty and cache.aiPriority==s.priority then return cache.aiCandidates end
 local list={}
 for _,n in ipairs(B.Keys(cache.owned)) do local p=Map.GetPlotByIndex(n)
  if B.Eligible(s,p) and not p:IsWater() and (p:GetImprovementType()<0 or p:IsImprovementPillaged()) then
   local score=B.Score(s,p)+(s.assignments[n] and 30 or 0)
   if p:GetResourceType(Players[s.pid]:GetTeam())>=0 then score=score+20 end
   list[#list+1]={n=n,score=score}
  end
 end
 table.sort(list,function(a,b) if a.score~=b.score then return a.score>b.score end;return a.n<b.n end)
 cache.aiCandidates=list;cache.aiDirty=false;cache.aiPriority=s.priority;return list
end
function B.AIWorkers(s)
 if Players[s.pid]:IsHuman() or s.incompatible then return end
 local cache=B.Cache(s);local candidates=B.AICandidates(s);local claimed={}
 local turn=B.Now()
 if cache.aiPathTurn~=turn then cache.aiPathTurn=turn;cache.aiPathsUsed=0 end
 local budget=math.max(0,B.Config.AIPathsPerTurn-(cache.aiPathsUsed or 0))
 s.aiTargets=s.aiTargets or {};cache.aiCursor=cache.aiCursor or 1
 cache.aiCursor=(cache.aiCursor-1)%math.max(1,#candidates)+1
 local units,live={},{};for unit in Players[s.pid]:Units() do if unit:GetUnitType()==B.ID('UNIT_BC_SURVEYOR') then units[#units+1]=unit;live[unit:GetID()]=unit end end
 table.sort(units,function(a,b) return a:GetID()<b:GetID() end)
 cache.aiFailures=cache.aiFailures or {}
 for id,record in pairs(cache.aiFailures) do
  if not live[id] or record.birth~=live[id]:GetGameTurnCreated() then cache.aiFailures[id]=nil
  else for n,untilTurn in pairs(record.plots) do if untilTurn<=turn then record.plots[n]=nil end end end
 end
 for id,target in pairs(s.aiTargets) do local unit=live[id];local p=Map.GetPlot(target.x,target.y)
  if not unit or target.birth~=unit:GetGameTurnCreated() or not B.AIBuildSet[target.build] or not B.Eligible(s,p)
   or not unit:CanBuild(p,target.build,0,1) then s.aiTargets[id]=nil
  elseif unit:IsBusy() or unit:MovesLeft()<=0 then claimed[p:GetPlotIndex()]=true end
 end
 local function cooling(unit,n)
  local p=Map.GetPlotByIndex(n)
  if p and unit:GetX()==p:GetX() and unit:GetY()==p:GetY() then return false end
  local record=cache.aiFailures[unit:GetID()]
  return record and record.plots[n] and record.plots[n]>turn
 end
 local function reachable(unit,p)
  if unit:GetX()==p:GetX() and unit:GetY()==p:GetY() then return true end
  if budget<=0 then return nil end -- Deferred, not a failed path or lost target.
  budget=budget-1;cache.aiPathsUsed=(cache.aiPathsUsed or 0)+1
  if #unit:GeneratePath(p,2147483647)>0 then return true end
  local id=unit:GetID();local record=cache.aiFailures[id]
  if not record then record={birth=unit:GetGameTurnCreated(),plots={}};cache.aiFailures[id]=record end
  record.plots[p:GetPlotIndex()]=turn+B.Config.AIRetryTurns
  return false
 end
 local first=(cache.aiUnitCursor or 0)%math.max(1,#units)+1
 cache.aiUnitCursor=first
 for offset=0,#units-1 do local unit=units[(first+offset-1)%#units+1]
  if unit:MovesLeft()>0 and not unit:IsBusy() then
   local target=s.aiTargets[unit:GetID()];local best,buildID,deferred
   if target and target.birth==unit:GetGameTurnCreated() then local p=Map.GetPlot(target.x,target.y)
    if not claimed[p:GetPlotIndex()] and not cooling(unit,p:GetPlotIndex()) then
     local path=reachable(unit,p)
     if path then best=p;buildID=target.build elseif path==nil then deferred=true;claimed[p:GetPlotIndex()]=true end
    end
   end
   if not best and not deferred and budget>0 then
    for _=1,math.min(#candidates,B.Config.AICandidates) do
     local r=candidates[cache.aiCursor];cache.aiCursor=cache.aiCursor%math.max(1,#candidates)+1
     local p=Map.GetPlotByIndex(r.n)
     if not claimed[r.n] and not cooling(unit,r.n) and B.Eligible(s,p) then
      for _,id in ipairs(B.AIBuilds) do if unit:CanBuild(p,id,0,1) then
       if reachable(unit,p) then best=p;buildID=id end
       break
      end end
     end
     if best or budget<=0 then break end
    end
   end
   if not best and not deferred and budget<=0 then
    local p=unit:GetPlot()
    if B.Eligible(s,p) and not claimed[p:GetPlotIndex()] and (p:GetImprovementType()<0 or p:IsImprovementPillaged()) then
     for _,id in ipairs(B.AIBuilds) do if unit:CanBuild(p,id,0,1) then best=p;buildID=id;break end end
    end
   end
   if best then
    claimed[best:GetPlotIndex()]=true
    s.aiTargets[unit:GetID()]={x=best:GetX(),y=best:GetY(),build=buildID,birth=unit:GetGameTurnCreated()}
    if unit:GetX()==best:GetX() and unit:GetY()==best:GetY() then unit:PushMission(MissionTypes.MISSION_BUILD,buildID,-1,0,0,0)
    else unit:PushMission(MissionTypes.MISSION_MOVE_TO,best:GetX(),best:GetY(),0,0,0) end
   elseif not deferred then s.aiTargets[unit:GetID()]=nil end
  end
 end
end
