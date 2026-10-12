local B=MapModData.BoundlessCity
B.AIBuilds={}
for row in GameInfo.Unit_Builds{UnitType='UNIT_BC_SURVEYOR'} do
 local build=GameInfo.Builds[B.ID(row.BuildType)]
 if build and (build.ImprovementType or build.Repair==true or build.Repair==1) then B.AIBuilds[#B.AIBuilds+1]=build.ID end
end
table.sort(B.AIBuilds)
B.Config.AICandidates=24;B.Config.AIPathsPerTurn=12
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
 local cache=B.Cache(s);local candidates=B.AICandidates(s);local claimed={};local budget=B.Config.AIPathsPerTurn
 s.aiTargets=s.aiTargets or {};cache.aiCursor=cache.aiCursor or 1
 cache.aiCursor=(cache.aiCursor-1)%math.max(1,#candidates)+1
 local units={};for unit in Players[s.pid]:Units() do if unit:GetUnitType()==B.ID('UNIT_BC_SURVEYOR') then units[#units+1]=unit end end
 table.sort(units,function(a,b) return a:GetID()<b:GetID() end)
 for _,unit in ipairs(units) do
  if unit:MovesLeft()>0 and not unit:IsBusy() then
   local target=s.aiTargets[unit:GetID()];local best,buildID
   if target and target.birth==unit:GetGameTurnCreated() then local p=Map.GetPlot(target.x,target.y)
    if B.Eligible(s,p) and not claimed[p:GetPlotIndex()] and unit:CanBuild(p,target.build,0,1) then
     local here=unit:GetX()==p:GetX() and unit:GetY()==p:GetY()
     if here then best=p;buildID=target.build
     elseif budget>0 then budget=budget-1;if #unit:GeneratePath(p,2147483647)>0 then best=p;buildID=target.build end end
    end
   end
   if not best then
    for _=1,math.min(#candidates,B.Config.AICandidates) do
     local r=candidates[cache.aiCursor];cache.aiCursor=cache.aiCursor%math.max(1,#candidates)+1
     local p=Map.GetPlotByIndex(r.n)
     if not claimed[r.n] and B.Eligible(s,p) then
      for _,id in ipairs(B.AIBuilds) do if unit:CanBuild(p,id,0,1) then
       local here=unit:GetX()==p:GetX() and unit:GetY()==p:GetY()
       if not here and budget<=0 then break end
       local path=here and {true} or unit:GeneratePath(p,2147483647)
       if not here then budget=budget-1 end
       if #path>0 then best=p;buildID=id end
       break
      end end
     end
     if best or budget<=0 then break end
    end
   end
   if best then
    claimed[best:GetPlotIndex()]=true
    s.aiTargets[unit:GetID()]={x=best:GetX(),y=best:GetY(),build=buildID,birth=unit:GetGameTurnCreated()}
    if unit:GetX()==best:GetX() and unit:GetY()==best:GetY() then unit:PushMission(MissionTypes.MISSION_BUILD,buildID,-1,0,0,0)
    else unit:PushMission(MissionTypes.MISSION_MOVE_TO,best:GetX(),best:GetY(),0,0,0) end
   else s.aiTargets[unit:GetID()]=nil end
  end
 end
end
