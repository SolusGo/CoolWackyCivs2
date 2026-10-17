TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
local function reset()
 local all={};for _,u in pairs(TEST.units) do all[#all+1]=u end;for _,u in ipairs(all) do u:Kill(false,-1) end
 for n=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(n)
  p.water=false;p.mountain=false;p.blocked=false;p.hidden=false;p.hill=false;p.moveCost=nil;p.danger=0;p.owner=p.city and p.city.pid or -1
 end
 TEST.disableNative=false;TEST.nativePath=nil;M.navigation={};TEST.turn=TEST.turn+1
 s.mode='CTF';s.start=TEST.turn;s.finish=TEST.turn+100;s.cycle=s.cycle+1;s.feast=nil;s.feastPending=false
end
local function unit(x,y) local u=TEST.new('UNIT_WARRIOR',x,y);TEST.flush();return u end
local function walk(u,goal,limit)
 for _=1,limit or 25 do
  if u:GetPlot()==goal then return true end
  TEST.turn=TEST.turn+1;u.moves=u:MaxMoves();M.AIStep(u,goal);TEST.flush()
  assert(not u:GetPlot():IsWater() and not u:GetPlot():IsMountain(),'Route must stay on legal land')
 end
 return u:GetPlot()==goal
end
-- A wall forces a first move which does NOT reduce direct distance.
reset();for y=0,6 do Map.GetPlot(3,y).mountain=true end
local u=unit(2,3);local goal=Map.GetPlot(7,3)
local plan=M.NavPlan(u,{{plot=goal,key='mountain'}},{turns=20})
assert(plan and M.Distance(Map.GetPlotByIndex(plan.path[2]),goal)>=M.Distance(u,goal))
assert(walk(u,goal),'Native route must navigate around a mountain wall')
-- The independently tested bounded fallback must solve the same detour.
reset();TEST.disableNative=true;for y=0,6 do Map.GetPlot(3,y).mountain=true end
u=unit(2,3);assert(walk(u,goal),'Bounded fallback must solve a non-greedy detour')
-- Water barrier with one distant land crossing; no embarking or teleporting.
reset();for y=0,7 do Map.GetPlot(5,y).water=true end
u=unit(2,3);goal=Map.GetPlot(8,3);assert(walk(u,goal))
-- A native query returning a water route is rejected, then the land fallback is used.
reset();for y=0,7 do Map.GetPlot(5,y).water=true end
u=unit(2,3);goal=Map.GetPlot(8,3)
TEST.nativePath=function()
 local path={};for x=2,8 do path[#path+1]={X=x,Y=3,Turn=0,RemainingMovement=0} end;return path
end
plan=M.NavPlan(u,{{plot=goal,key='water-native'}},{turns=20});assert(plan)
for _,n in ipairs(plan.path) do assert(not Map.GetPlotByIndex(n):IsWater()) end
TEST.nativePath=nil
-- CP path rows may be reversed; normalize origin/destination explicitly.
reset();u=unit(2,2);goal=Map.GetPlot(4,2)
TEST.nativePath=function() return {{X=4,Y=2,Turn=1},{X=3,Y=2,Turn=0},{X=2,Y=2,Turn=0}} end
plan=M.NavPlan(u,{{plot=goal,key='reverse'}},{});assert(plan and plan.path[1]==u:GetPlot():GetPlotIndex() and plan.path[3]==goal:GetPlotIndex())
-- Movement costs can make a longer clear route preferable to a short rough route.
reset();TEST.disableNative=true;u=unit(2,5);goal=Map.GetPlot(8,5)
for x=3,7 do Map.GetPlot(x,5).moveCost=4 end
plan=M.NavPlan(u,{{plot=goal,key='cost'}},{turns=20});assert(plan and plan.weight<21)
local avoided=false;for _,n in ipairs(plan.path) do if Map.GetPlotByIndex(n):GetY()~=5 then avoided=true end end;assert(avoided)
-- An occupied choke point is unreachable now, not a repeatedly issued move.
reset();for y=0,9 do if y~=5 then Map.GetPlot(5,y).mountain=true end end
u=unit(2,4);goal=Map.GetPlot(8,4);local blocker=TEST.new('UNIT_WARRIOR',5,5);TEST.flush()
local before=TEST.moveAttempts or 0
assert(not M.AIStep(u,goal));assert((TEST.moveAttempts or 0)==before)
local queries=TEST.pathCalls or 0;TEST.turn=TEST.turn+1;assert(not M.AIStep(u,goal));assert((TEST.pathCalls or 0)==queries)
blocker:Kill(false,-1);TEST.turn=TEST.turn+M.Turns(3);assert(walk(u,goal))
-- Closed borders cannot be bypassed. Open borders make the same route legal.
reset();Teams[0].wars={[1]=true};for y=0,9 do Map.GetPlot(5,y).owner=2 end
u=unit(2,4);goal=Map.GetPlot(8,4)
plan=M.NavPlan(u,{{plot=goal,key='closed'}},{turns=20});assert(not plan)
Teams[2].borders={[0]=true};assert(walk(u,goal));Teams[0].wars=nil;Teams[2].borders=nil
-- Budget exhaustion is a deferral, distinct from proving no route exists.
reset();u=unit(2,2);goal=Map.GetPlot(8,2);local budget={calls=0,nodes=1};local reason
plan,reason=M.NavPlan(u,{{plot=goal,key='budget'}},{native=false,turns=20},budget)
assert(not plan and reason=='budget' and budget.nodes==0)
-- Preserve pre-existing native military orders; do not replace their target.
u.missionPlot=Map.GetPlot(1,1);before=TEST.moveAttempts or 0
assert(not M.AIStep(u,goal) and u.missionPlot==Map.GetPlot(1,1) and (TEST.moveAttempts or 0)==before)
u.missionPlot=nil
-- A native move that never executes is retried twice, then released/cools down.
reset();u=unit(2,2);goal=Map.GetPlot(8,2);u.rejectMove=true;before=TEST.moveAttempts or 0
assert(M.AIStep(u,goal));TEST.turn=TEST.turn+1;assert(M.AIStep(u,goal))
TEST.turn=TEST.turn+1;assert(not M.AIStep(u,goal) and not u:LastMissionPlot())
TEST.turn=TEST.turn+1;assert(not M.AIStep(u,goal) and (TEST.moveAttempts or 0)==before+2)
u.rejectMove=false;TEST.turn=TEST.turn+M.Turns(3);assert(walk(u,goal))
-- Replan a cached route when an occupied tile appears in its next step.
reset();u=unit(2,2);goal=Map.GetPlot(8,2);assert(M.AIStep(u,goal));TEST.flush()
local q=M.NavContext(0).units[u.id];local nextTile=Map.GetPlotByIndex(q.plan.path[3])
blocker=TEST.new('UNIT_WARRIOR',nextTile:GetX(),nextTile:GetY());TEST.flush()
TEST.turn=TEST.turn+1;u.moves=u:MaxMoves();assert(M.AIStep(u,goal));TEST.flush();assert(u:GetPlot()~=nextTile)
assert(walk(u,goal))
-- Navigation is advisory: selected-save data has no new schema or route fields.
reset();u=unit(2,2);goal=Map.GetPlot(4,2);local saved=M.Encode(s)
M.AIStep(u,goal);TEST.flush();assert(M.Encode(s)==saved and s.version==1)
M.navigation={};assert(walk(u,goal),'Clearing advisory caches must allow replanning after load')
print('PASS McPvP navigation: native table ABI, mountain/water detours, weighted fallback, occupied passages, access rights, budgets, failure cooldowns, replanning and save-independent caches')
