local B=MapModData.BoundlessCity;local s=B.State(0)
Players[0].human=false;local near=Remote(24,5);local far=Remote(38,5,{10,10,10,10,10,10})
local busy=MakeUnit(10,400);local idle=MakeUnit(11,400)
function busy:MovesLeft() return 60 end;function idle:MovesLeft() return 60 end
function busy:IsBusy() return true end
s.aiTargets={[10]={x=far.x,y=far.y,build=0,birth=0},[999]={x=far.x,y=far.y,build=0,birth=0},[11]={x=near.x,y=near.y,build=999,birth=0}}
local nativeBuild=idle.CanBuild
function idle:CanBuild(p,b) assert(b~=999,'stale saved build ID reached the DLL');return nativeBuild(self,p,b) end
B.AIWorkers(s);assert(not s.aiTargets[999] and s.aiTargets[10] and not busy.lastMission)
assert(idle.lastMission and idle.lastMission[1]==MissionTypes.MISSION_BUILD,'local legal work should remain possible')
assert(s.aiTargets[11].x~=far.x,'busy Surveyor target must not be assigned twice')
idle.GetGameTurnCreated=function() return 7 end;idle.IsBusy=function() return true end
B.AIWorkers(s);assert(not s.aiTargets[11],'reused ID/creation identity must invalidate the old target')
busy.kind=700;B.AIWorkers(s);assert(not s.aiTargets[10],'upgraded non-Surveyor must lose stale target metadata')
-- A first failed saved path is not immediately tried again from the candidate list.
Players[0].units={};s.aiTargets={};B.Caches[0].aiFailures={};B.Caches[0].aiPathTurn=nil
local worker=MakeUnit(20,400);function worker:MovesLeft() return 60 end
function worker:GetX() return 0 end;function worker:GetY() return 0 end
local attempts={};function worker:CanBuild(p,b) return p.n==far.n and b==0 end
function worker:GeneratePath(p) attempts[p.n]=(attempts[p.n] or 0)+1;return {} end
s.aiTargets[20]={x=far.x,y=far.y,build=0,birth=0};B.Cache(s).aiDirty=true
B.AIWorkers(s);assert(attempts[far.n]==1 and not s.aiTargets[20])
now=now+1;B.AIWorkers(s);assert(attempts[far.n]==1,'unreachable plot must cool down')
now=now+3;B.AIWorkers(s);assert(attempts[far.n]==2,'failed routes must eventually retry')
-- Many units, unlimited distant candidates, bounded paths and fair starting units.
Players[0].units={};s.aiTargets={};B.Cache(s).aiFailures={};B.Cache(s).aiUnitCursor=0
for x=20,55 do Remote(x,10) end
local paths=0;local served={}
for id=30,49 do local u=MakeUnit(id,400)
 function u:MovesLeft() return 60 end
 function u:GetX() return 0 end;function u:GetY() return 0 end
 function u:GeneratePath(p) paths=paths+1;served[self.id]=true;return {} end
end
B.Cache(s).aiDirty=true
for _=1,20 do now=now+1;local before=paths;B.AIWorkers(s);assert(paths-before<=12)
 before=paths;B.AIWorkers(s);assert(paths==before,'repeated calls must share the turn budget')
end
local visited=0;for _ in pairs(served) do visited=visited+1 end;assert(visited>=10,'low-ID units must not monopolize all path attempts')
-- Targets waiting on budget remain saved; dead units and failed-path metadata are pruned.
local last=Players[0]:GetUnitByID(49);s.aiTargets[49]={x=far.x,y=far.y,build=0,birth=0}
B.Cache(s).aiFailures[49]=nil;B.Cache(s).aiUnitCursor=19
B.AIWorkers(s);assert(s.aiTargets[49],'budget deferral is not path failure')
last:Kill();B.AIWorkers(s);assert(not s.aiTargets[49] and not B.Cache(s).aiFailures[49])
print('PASS AI stale/dead/upgraded IDs, invalid build guard, busy targets, unreachable cooldown, shared turn budget, fair unit rotation and target deferral')
