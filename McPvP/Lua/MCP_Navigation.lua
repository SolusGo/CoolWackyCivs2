-- Read-only route queries and bounded land searches. Caches are advisory only;
-- objective authority and all rewards remain in the existing saved state.
local M=MapModData.MCPVP
M.navigation={};M.navStats={native=0,nodes=0,feasts=0}
local denominator=GameDefines.MOVE_DENOMINATOR or 60
local function push(heap,item)
 local i=#heap+1
 while i>1 do local parent=math.floor(i/2);local other=heap[parent]
  if other.cost<item.cost or (other.cost==item.cost and other.n<=item.n) then break end
  heap[i]=other;i=parent
 end
 heap[i]=item
end
local function pop(heap)
 local first=heap[1];local last=table.remove(heap);if #heap==0 then return first end
 local i=1
 while i*2<=#heap do local j=i*2
  if heap[j+1] and (heap[j+1].cost<heap[j].cost or (heap[j+1].cost==heap[j].cost and heap[j+1].n<heap[j].n)) then j=j+1 end
  local other=heap[j];if last.cost<other.cost or (last.cost==other.cost and last.n<=other.n) then break end
  heap[i]=other;i=j
 end
 heap[i]=last;return first
end
function M.NavContext(pid)
 local c=M.navigation[pid]
 if not c then c={units={},cursor=0};M.navigation[pid]=c end
 if c.turn~=M.Turn() then c.turn=M.Turn();c.budget={calls=6,nodes=640};c.planned=0 end
 return c
end
function M.NavDanger(pid,plot,options)
 if not options.safe then return 0 end
 options.danger=options.danger or {};local n=plot:GetPlotIndex()
 if options.danger[n]==nil then options.danger[n]=math.max(0,Players[pid]:GetPlotDanger(plot)) end
 return options.danger[n]
end
function M.NavEnter(pid,u,plot,options)
 options=options or {}
 if not plot or plot:IsWater() or plot:IsMountain() or plot:IsImpassable() or plot:IsFighting() then return false end
 local team=Players[pid]:GetTeam()
 if not plot:IsRevealed(team) then return false end
 local city=plot:GetPlotCity();if city and city:GetOwner()~=pid then return false end
 if u then
  if not u:CanMoveThrough(plot) then return false end
 else
  local owner=plot:GetOwner()
  if owner>=0 then local other=Players[owner]:GetTeam()
   if other~=team and not Teams[team]:IsAtWar(other) and not Teams[other]:IsAllowsOpenBordersToTeam(team) then return false end
  end
 end
 for i=0,plot:GetNumUnits()-1 do local v=plot:GetUnit(i)
  if v~=u and M.Alive(v) then
   if not options.ignoreUnits or (M.AtWar(pid,v:GetOwner()) and not v:IsInvisible(team,false)) then return false end
  end
 end
 if options.safe and u and M.NavDanger(pid,plot,options)>=u:GetMaxHitPoints()-u:GetDamage() then return false end
 return true
end
function M.NavCost(pid,u,from,plot,options)
 local cost
 if u then
  -- Verified native binding takes unit, FROM plot and remaining movement.
  cost=math.max(1,plot:MovementCost(u,from,math.max(denominator,u:MaxMoves())))/denominator
 else
  local terrain=GameInfo.Terrains[plot:GetTerrainType()];local feature=GameInfo.Features[plot:GetFeatureType()]
  cost=math.max(1,terrain and terrain.Movement or 1,feature and feature.Movement or 1,plot:IsHills() and 2 or 1)
 end
 return cost+math.min(12,M.NavDanger(pid,plot,options)/20)
end
-- Dijkstra expands a bounded region; no GetNumPlots/full-map traversal.
-- Returning a budget failure never means that an objective is unreachable.
function M.NavFlood(pid,u,origin,options,budget)
 options=options or {};budget=budget or {nodes=options.nodes or 192}
 local start=origin:GetPlotIndex();local records={[start]={plot=origin,cost=0,steps=0}}
 local heap={{n=start,cost=0}};local expanded=0;local maximum=math.min(options.nodes or 192,budget.nodes or 0)
 while #heap>0 and expanded<maximum do local entry=pop(heap);local r=records[entry.n]
  if not r.done and entry.cost==r.cost then
   r.done=true;expanded=expanded+1;M.navStats.nodes=M.navStats.nodes+1
   if options.goals and options.goals[entry.n] then budget.nodes=budget.nodes-expanded;return records,entry.n,'found' end
   if r.steps<(options.steps or 32) then
    for dir=0,5 do local plot=Map.PlotDirection(r.plot:GetX(),r.plot:GetY(),dir)
     if plot and (not options.radius or M.Distance(origin,plot)<=options.radius) and M.NavEnter(pid,u,plot,options) then
      local n=plot:GetPlotIndex();local cost=r.cost+M.NavCost(pid,u,r.plot,plot,options);local old=records[n]
      if cost<=(options.cost or 100) and (not old or cost<old.cost) then
       records[n]={plot=plot,cost=cost,steps=r.steps+1,previous=entry.n};push(heap,{n=n,cost=cost})
      end
     end
    end
   end
  end
 end
 budget.nodes=budget.nodes-expanded
 return records,nil,#heap>0 and 'budget' or 'unreachable'
end
local function makePlan(u,path,goal,options,engineTurns)
 if #path==0 or path[1]~=u:GetPlot() or path[#path]~=goal.plot then return end
 local weight,travel=0,0;local indices={}
 for i,plot in ipairs(path) do
  indices[i]=plot:GetPlotIndex()
  if i>1 then
   if M.Distance(path[i-1],plot)~=1 or not M.NavEnter(u:GetOwner(),u,plot,options) then return end
   weight=weight+M.NavCost(u:GetOwner(),u,path[i-1],plot,options)
   travel=travel+M.NavCost(u:GetOwner(),u,path[i-1],plot,{})
  end
 end
 local turns=math.max(engineTurns or 0,math.ceil(travel/math.max(1,u:MaxMoves()/denominator)))
 if turns>(options.turns or 12) then return end
 return {path=indices,goal=goal,weight=weight,turns=turns}
end
function M.NavPlan(u,goals,options,budget)
 options=options or {};budget=budget or {calls=2,nodes=192}
 if not M.Land(u) or #goals==0 then return nil,'unreachable' end
 local available,goalMap={},{}
 for _,goal in ipairs(goals) do if goal.plot==u:GetPlot() or M.NavEnter(u:GetOwner(),u,goal.plot,options) then
  available[#available+1]=goal;goalMap[goal.plot:GetPlotIndex()]=goal
 end end
 table.sort(available,function(a,b)
  local ad=M.Distance(u,a.plot)+M.NavDanger(u:GetOwner(),a.plot,options)/20
  local bd=M.Distance(u,b.plot)+M.NavDanger(u:GetOwner(),b.plot,options)/20
  if ad~=bd then return ad<bd end return a.key<b.key
 end)
 if #available==0 then return nil,'unreachable' end
 if goalMap[u:GetPlot():GetPlotIndex()] then return makePlan(u,{u:GetPlot()},goalMap[u:GetPlot():GetPlotIndex()],options) end
 local best
 for i=1,math.min(2,#available) do
  if options.native~=false and (budget.calls or 0)>0 then
   budget.calls=budget.calls-1;M.navStats.native=M.navStats.native+1
   -- CP returns a TABLE (empty = no path), never a reachability boolean.
   local raw=u:GeneratePath(available[i].plot,options.turns or 12)
   if type(raw)=='table' and #raw>0 and #raw<=33 then
    local path={};local first=Map.GetPlot(raw[1].X,raw[1].Y);local last=Map.GetPlot(raw[#raw].X,raw[#raw].Y)
    local reverse=last==u:GetPlot() or (first==available[i].plot and last~=available[i].plot)
    path[1]=u:GetPlot()
    for offset=1,#raw do local node=raw[reverse and #raw-offset+1 or offset];local plot=Map.GetPlot(node.X,node.Y)
     if plot~=path[#path] then path[#path+1]=plot end
    end
    local endNode=raw[reverse and 1 or #raw]
    local plan=makePlan(u,path,available[i],options,type(endNode.Turn)=='number' and endNode.Turn or 0)
    if plan and (not best or plan.weight<best.weight) then best=plan end
    if best and not options.safe then return best,'found' end
   end
  end
 end
 if best and best.weight==0 then return best,'found' end
 if (budget.nodes or 0)<=0 then return best,best and 'found' or 'budget' end
 local search={nodes=192,radius=20,steps=32,cost=(options.turns or 12)*math.max(1,u:MaxMoves()/denominator),goals=goalMap,safe=options.safe,danger=options.danger}
 local records,n,reason=M.NavFlood(u:GetOwner(),u,u:GetPlot(),search,budget)
 if n then
  local path={};local at=n
  while at do table.insert(path,1,records[at].plot);at=records[at].previous end
  local plan=makePlan(u,path,goalMap[n],options)
  if plan and (not best or plan.weight<best.weight) then best=plan end
 end
 return best,best and 'found' or reason
end
