local B=MapModData.BoundlessCity
local function setup(pop,localCount)
 MakeMap(200,80,false);capital=MakeCity(0,3,5,pop,localCount);foreign=MakeCity(1,60,5,4,6)
 Players[0].cities={capital};Players[1].cities={foreign};Players[0].units={};Players[0].script='other-mod;'
 B.States={};B.Caches={};B.Watch={};now=now+1;B.Initialize(0)
 local s=B.State(0);s.priority='PRODUCTION';s.foodTarget=-1;return s
end
local function reconcile(s,touched)
 if touched then B.InvalidatePlan(s,touched) end
 B.Cache(s).force=true;assert(B.Reconcile(s));capital:Check()
 local a=B.Census(s,capital)
 assert(a.remote<=a.realDefaults and a.localCount+a.remote+a.specialists+a.idle+a.unassigned==capital.pop+capital:GetAutomatons())
end
-- The reported inferior-idle trade must disappear in Auto, but remain a valid
-- explicit Manual request. Worker accounting and compensation remain native.
local s=setup(13,12);local gold=Remote(36,5,{0,0,1,0,0,0})
local production=capital:NativeYield(1);reconcile(s)
assert(s.reserved==0 and capital:NativeYield(1)==production)
s.mode='MANUAL';s.selected[gold.n]=true;reconcile(s)
assert(s.reserved==1 and capital:NativeYield(1)==production-1)

-- Compare against the actual local job being displaced, not only an idle job.
s=setup(1,1);capital.localPlots[1].yields={1,10,0,0,0,0}
local weak=Remote(36,5,{1,1,0,0,0,0});reconcile(s);assert(s.reserved==0)
weak.yields[2]=20;GameEvents.TileImprovementChanged.Fire(weak.x,weak.y,0,-1,500,false);Pump()
assert(s.assignments[weak.n] and s.withdrawn==1)
weak.yields[2]=0;GameEvents.TileImprovementChanged.Fire(weak.x,weak.y,0,500,500,true);Pump()
assert(s.reserved==0 and capital:IsWorkingPlot(capital.localPlots[1]),'inferior job must return its local worker')

-- Surplus and forced counts overlap: crossing the surplus boundary can require
-- several local withdrawals for a single additional remote job.
s=setup(4,3);for _,p in ipairs(capital.localPlots) do p.yields={0,10,0,0,0,0} end
local r1=Remote(36,5,{0,20,0,0,0,0});local r2=Remote(37,5,{0,11,0,0,0,0})
reconcile(s);assert(s.reserved==1 and s.assignments[r1.n] and s.withdrawn==0)

-- A one-point improvement is inside the switching margin; a larger gain wins.
s=setup(1,1);local first=Remote(36,5,{0,3,0,0,0,0});local held=Remote(37,5,{0,3,0,0,0,0})
s.mode='MANUAL';s.selected[held.n]=true;reconcile(s);s.mode='AUTO';reconcile(s)
assert(s.assignments[held.n]);first.yields[3]=1;reconcile(s,{[first.n]=true})
assert(s.assignments[held.n],'small gain should not churn an existing assignment')
first.yields[3]=2;reconcile(s,{[first.n]=true});assert(s.assignments[first.n])
local before=mutations;local playerData=Players[0].script;local ledger=Map.GetPlot(3,5):GetScriptData()
reconcile(s,{});assert(mutations==before and Players[0].script==playerData and Map.GetPlot(3,5):GetScriptData()==ledger)
for i=1,1000 do Events.SerialEventCityInfoDirty.Fire() end
Pump();assert(mutations==before,'an unchanged dirty-event batch must not reset native reservations')
GameEvents.PlayerDoneTurn.Fire(0);capital:Check();assert(s.reserved<=capital.defaults and s.withdrawn==capital.forcedDefault)

-- Native Food feedback, including positive-only growth modifiers. There are
-- no Food storage/population setters involved in selecting a safe job.
s=setup(1,1);local factory=Remote(36,5,{0,10,0,0,0,0});local farm=Remote(37,5,{4,0,0,0,0,0})
capital.FoodDifferenceTimes100=function(self)
 local net=self:GetBaseYieldRateFromTerrain(0)+self:GetBaseYieldRateFromMisc(0)-self.pop*2
 return math.floor(net*100*(net>0 and 125 or 100)/100)
end
s.foodTarget=2;reconcile(s)
assert(s.assignments[farm.n] and B.FoodRate(capital)==2.5 and not B.Cache(s).foodLimited)
assert(B.Action(0,'FOOD_TARGET',-1));assert(s.assignments[factory.n] and B.FoodRate(capital)<0)
assert(B.Action(0,'FOOD_TARGET',2));assert(s.assignments[farm.n])
factory.yields[2]=10000;reconcile(s,{[factory.n]=true})
assert(s.assignments[farm.n] and not B.Cache(s).foodLimited,'final Food rescue pass must dominate unusually large economic yields')
s.mode='MANUAL';s.selected={[factory.n]=true};reconcile(s)
assert(s.assignments[factory.n] and not B.Cache(s).foodLimited,'Manual requests must remain authoritative')
s.mode='HYBRID';s.locks={[factory.n]=true};reconcile(s)
assert(s.assignments[factory.n] and B.Cache(s).foodLimited,'unreachable Food target must respect a Hybrid lock and report failure')
s.locks={};reconcile(s);assert(s.assignments[farm.n] and not B.Cache(s).foodLimited)
B.Save(s);local savedTarget=s.foodTarget;B.States={};B.Caches={};B.Initialize(0);s=B.State(0)
assert(s.foodTarget==savedTarget and s.version==3 and s.assignments[farm.n])
local corrupt=B.Decode(B.Encode(s));corrupt.foodTarget='bad';local raw=B.Encode(corrupt)
Players[0].script='|BCSTATE1:'..#raw..':'..raw..'|';B.States={}
assert(B.FoodTarget(B.State(0))==0,'invalid optional Food settings must normalize without losing the save')

-- Bounded candidate selection versus an independent exhaustive job oracle.
for _,priority in ipairs({'BALANCED','PRODUCTION','FOOD','GOLD'}) do
 s=setup(2,2);s.priority=priority
 capital.localPlots[1].yields={3,3,1,0,0,0};capital.localPlots[2].yields={2,4,1,0,0,0}
 local rs={}
 for i,v in ipairs({{5,1,0,0,0,0},{1,7,0,0,0,0},{1,1,8,0,0,0},{3,3,3,0,0,0}}) do rs[i]=Remote(35+i,5,v) end
 B.PlannerUpdate(s,capital);local plan=B.PlanJobs(s,capital,0)
 local localScores={B.Score(s,capital.localPlots[1]),B.Score(s,capital.localPlots[2])};table.sort(localScores)
 local best=0;local chosen=0
 for mask=0,15 do local count,score=0,0
  for i,r in ipairs(rs) do if math.floor(mask/2^(i-1))%2==1 then count=count+1;score=score+B.Score(s,r) end end
  if count<=2 then for i=1,count do score=score-localScores[i] end;if score>best then best=score;chosen=count end end
 end
 local gain=0;for n in pairs(plan.assignments) do gain=gain+B.Score(s,plots[n]) end
 for i=1,plan.count do gain=gain-localScores[i] end
 assert(gain==best and plan.count==chosen,'bounded selection differs from exhaustive job utility oracle')
end

-- Read-count evidence on 2,500 owned plots. Warm unchanged reconciliation and
-- a single unassigned improvement must not rescan every owned plot's yields.
s=setup(150,30)
local total=31
for n=0,Map.GetNumPlots()-1 do local p=plots[n]
 if total>=2500 then break end
 if p.owner==-1 then p.owner=0;p.yields={2,4,1,0,0,0};B.Cache(s).owned[n]=true;total=total+1 end
end
B.Cache(s).territoryDirty=true;reconcile(s)
local methods=getmetatable(plots[0]).__index;local get=methods.GetYield;local reads=0
methods.GetYield=function(self,y) reads=reads+1;return get(self,y) end
reconcile(s,{});local warm=reads;assert(warm<2500*6/2)
local improved
for n,row in pairs(B.Cache(s).candidates) do if row.eligible and not s.assignments[n] then improved=row.plot;break end end
assert(improved);improved.yields[2]=40;reads=0
GameEvents.TileImprovementChanged.Fire(improved.x,improved.y,0,-1,500,false);Pump()
assert(s.assignments[improved.n] and reads<2500*6/2,'single-plot update must consider a new winner without a full yield rescan')
methods.GetYield=get
print('PASS remote planner: idle/local opportunity cost, overlapping reservations, switching margin, no-op native updates, native Food feedback, Manual/Hybrid contracts, persistence, exhaustive oracle and 2,500-plot incremental reads ('..warm..' warm)')
