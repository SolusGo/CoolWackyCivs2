-- CP optimizes local citizens before doGrowth; PlayerDoTurn and our deferred
-- reconciliation run afterward. A UI dirty callback must not retire yields
-- from people who are still present in the native default labourer pool.
local B=MapModData.BoundlessCity
local s=B.State(0)
for _,p in ipairs(capital.localPlots) do p.yields={1,1,0,0,0,0} end
local farm=Remote(24,5,{10,0,0,0,0,0})
local pasture=Remote(34,5,{9,0,0,0,0,0})
s.mode=FoodTestMode or 'MANUAL';s.selected={[farm.n]=true,[pasture.n]=true};s.locks={};s.excluded={}

-- A separate Food model follows CP's positive surplus modifier and hundredths.
-- 21 native building Food + 6 local Food - 16 consumption + 19 remote Food,
-- with +25% growth, displays +37 and should store 37.50 per turn.
local ordinaryYield=capital.NativeYield
capital.NativeYield=function(self,y)
 if y~=0 then return ordinaryYield(self,y) end
 if self:GetResistanceTurns()>0 then return 0 end
 local surplus=self:GetBaseYieldRateFromTerrain(0)+self:GetBaseYieldRateFromMisc(0)-self.pop*2
 return math.floor(surplus*100*(surplus>0 and 125 or 100)/100)/100
end
-- Unlike the small shared mock, native working/slacker tasks refresh rates.
for _,name in ipairs({'AlterWorkingPlot','DoTask'}) do
 local nativeTask=capital[name]
 capital[name]=function(self,...)
  nativeTask(self,...);self.cached=self.cached or {};self.cached[0]=self:NativeYield(0)
 end
end
capital.misc[0]=21;B.Cache(s).force=true;assert(B.Reconcile(s))
assert(s.reserved==2 and capital.defaults==2 and capital.forcedDefault==2)
local function rate100() return math.floor(capital.cached[0]*100+0.5) end
assert(rate100()==3750)
local function verify()
 capital:Check();local a=B.Census(s,capital)
 assert(a.localCount+a.specialists+a.remote+a.idle+a.unassigned==a.population+a.automata)
 assert(a.remote<=a.realDefaults,'a local worker/specialist must never also work remotely')
 local remote=0;for n in pairs(s.assignments) do remote=remote+plots[n]:GetYield(0) end
 assert(capital.terrain[0]==remote,'remote Food must match actual assignments')
 assert(rate100()==math.floor(capital:NativeYield(0)*100+0.5),'stale native Food cache')
end
local function moveLocalWorker()
 local old,new
 for _,p in ipairs(capital.localPlots) do
  if capital.worked[p.n] and not old then old=p elseif not capital.worked[p.n] and not new then new=p end
 end
 assert(old and new)
 capital.worked[old.n]=nil;capital.worked[new.n]=true
 -- CP refreshes city rates while changing local jobs. Its forced labourers stay.
 capital.cached[0]=capital:NativeYield(0);capital:Check()
 Events.SerialEventCityInfoDirty.Fire()
end
local food100=20320
for turn=318,320 do
 now=turn;GameEvents.PlayerDoneTurn.Fire(0)
 local advertised=rate100();assert(advertised==3750)
 moveLocalWorker()
 -- Native growth harvests the cached rate before a deferred UI frame can run.
 local harvested=rate100();food100=food100+harvested
 assert(harvested==advertised,'remote Food disappeared before growth: expected '..advertised..', harvested '..harvested)
 assert(s.reserved==2 and capital.defaults==2);verify()
 GameEvents.PlayerDoTurn.Fire(0);Pump();verify()
 assert(rate100()==advertised and food100==20320+(turn-317)*3750)
end

-- A real worker reclaim drops only the now-unbacked assignment, synchronously.
local unworked
for i,p in ipairs(capital.localPlots) do if not capital.worked[p.n] then unworked=i;break end end
capital:AlterWorkingPlot(unworked);capital.cached[0]=capital:NativeYield(0)
Events.SerialEventCityInfoDirty.Fire()
assert(s.reserved==1 and capital.defaults==1);verify()
Pump();assert(s.reserved<=capital.defaults);verify()

-- A new native specialist consumes a person: no overlap, even before dispatch.
capital.defaults=capital.defaults-1;capital.forcedDefault=math.min(capital.forcedDefault,capital.defaults)
capital.specialists=capital.specialists+1;capital.cached[0]=capital:NativeYield(0)
Events.SerialEventCityInfoDirty.Fire()
assert(s.reserved<=capital.defaults);verify()
-- Unknown automata cannot back ordinary remote citizens.
Pump();capital.automatons=1;capital.unassigned=1
Events.SerialEventCityInfoDirty.Fire();assert(s.reserved==0);verify()

-- Idle defaults are not a request to create free/new remote assignments.
capital.automatons=0;capital.unassigned=0;s.mode='MANUAL';s.selected={};s.locks={}
B.Cache(s).force=true;assert(B.Reconcile(s));Events.SerialEventCityInfoDirty.Fire();Pump()
assert(s.reserved==0);verify()
print('PASS Food harvested before deferred dispatch matches displayed rate; real worker/specialist losses and automata remain exclusive')
