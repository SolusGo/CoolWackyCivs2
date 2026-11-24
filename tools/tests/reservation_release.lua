-- The captured native crash is uncatchable in Lua. Reject any invocation of
-- its bulk governor entry, then exercise the real reconciliation end to end.
local B=MapModData.BoundlessCity;local s=B.State(0)
local originalTask=capital.DoTask;local bulkCalls=0
capital.DoTask=function(self,task,...)
 if task==TaskTypes.TASK_REMOVE_SLACKER then bulkCalls=bulkCalls+1;error('native bulk governor trap') end
 return originalTask(self,task,...)
end
local remote=Remote(24,5,{5,8,2,1,0,0})
s.mode='MANUAL';s.selected={[remote.n]=true};s.locks={}
B.Cache(s).force=true;assert(B.Reconcile(s));assert(s.reserved==1 and s.withdrawn==1)
local function check()
 capital:Check()
 local a=B.Census(s,capital)
 assert(a.remote<=a.realDefaults)
 for n in pairs(s.assignments) do assert(not capital:IsWorkingPlot(Map.GetPlotByIndex(n))) end
 assert(bulkCalls==0,'workforce invoked the captured fatal governor path')
end
-- Dropping a remote job returns the person, without duplicate credit or a
-- permanent Manual/Hybrid lock imposed by the mod's own native tile click.
s.selected={};B.Cache(s).force=true;assert(B.Reconcile(s));check()
assert(s.reserved==0 and capital.defaults==0 and s.releasePending==0)
local returned
for n in pairs(s.nativeReturns) do returned=n end
assert(returned and B.Census(s,capital).localLocked==0)
local nativeAlter=capital.AlterWorkingPlot
s.selected={[remote.n]=true};B.Cache(s).force=true
capital.AlterWorkingPlot=function(self,i)
 nativeAlter(self,i);error('after completed native withdrawal')
end
assert(not B.Reconcile(s));check()
assert(s.withdrawn==1 and s.reserved==0 and capital.defaults==1)
capital.AlterWorkingPlot=nativeAlter
s.selected={};B.Cache(s).force=true;assert(B.Reconcile(s));check()
assert(s.withdrawn==0 and s.releasePending==0 and capital.defaults==0)
s.selected={[remote.n]=true};B.Cache(s).force=true;assert(B.Reconcile(s));check()
assert(s.reserved==1,'returned native lock must remain movable by the planner')
-- End-turn renewal and reload do not need the bulk governor either.
for _=1,20 do GameEvents.PlayerDoneTurn.Fire(0);check();assert(s.reserved==1) end
B.States={};B.Caches={};B.Initialize(0);s=B.State(0);check();assert(s.reserved==1)
s.selected={};B.Cache(s).force=true;assert(B.Reconcile(s));check()
local savedReturns=B.Encode(s.nativeReturns)
B.Save(s);B.States={};B.Caches={};s=B.State(0)
assert(B.Encode(s.nativeReturns)==savedReturns,'return ownership must survive reload')
-- Already-worked rows are never toggled off. CanWork vetoes unavailable plots
-- instead of taking DoAlterWorkingPlot's bulk ownership-override branch.
s.selected={[remote.n]=true};B.Cache(s).force=true;assert(B.Reconcile(s));check()
s.selected={}
for _,p in ipairs(capital.localPlots) do if not capital:IsWorkingPlot(p) then p.blockaded=true end end
local alter=capital.AlterWorkingPlot;local attempts=0
capital.AlterWorkingPlot=function(self,i)
 local p=self.localPlots[i]
 assert(p and not self:IsWorkingPlot(p),'release toggled an already worked tile')
 assert(self:CanWork(p),'release attempted an ownership override')
 attempts=attempts+1;return alter(self,i)
end
B.Cache(s).force=true;assert(B.Reconcile(s));check()
assert(attempts==0 and s.releasePending==1 and s.reserved==0 and s.withdrawn==0)
B.Save(s);B.States={};B.Caches={};s=B.State(0)
assert(s.releasePending==1,'blocked return must survive reload')
for _,p in ipairs(capital.localPlots) do p.blockaded=false end
B.Cache(s).force=true;assert(B.Reconcile(s));check()
assert(attempts==1 and s.releasePending==0 and capital.defaults==0)
capital.AlterWorkingPlot=alter
-- A native no-op (e.g. resistance) cannot manufacture a successful release.
s.selected={[remote.n]=true};B.Cache(s).force=true;assert(B.Reconcile(s));s.selected={}
capital.AlterWorkingPlot=function() end
B.Cache(s).force=true;assert(B.Reconcile(s));check();assert(s.releasePending==1)
capital.AlterWorkingPlot=alter;assert(B.Reconcile(s));check();assert(s.releasePending==0)
-- A callback error after a completed native return is journalled before the
-- ordinary failure handler runs, so retry cannot consume another labourer.
s.selected={[remote.n]=true};B.Cache(s).force=true;assert(B.Reconcile(s));s.selected={}
capital.AlterWorkingPlot=function(self,i) alter(self,i);error('after completed native return') end
B.Cache(s).force=true;assert(not B.Reconcile(s));check()
assert(s.releasePending==0 and s.withdrawn==0 and capital.defaults==0)
capital.AlterWorkingPlot=alter;assert(B.Reconcile(s));check()
-- External automatons make ordinary-worker attribution ambiguous. Wait rather
-- than moving one, then complete the saved return after the automaton leaves.
s.selected={[remote.n]=true};B.Cache(s).force=true;assert(B.Reconcile(s));s.selected={}
capital.automatons=1;capital.defaults=capital.defaults+1
B.Cache(s).force=true;assert(B.Reconcile(s));check()
assert(s.reserved==0 and s.withdrawn==0 and s.releasePending==1)
capital.automatons=0;capital.defaults=capital.defaults-1
assert(B.Reconcile(s));check();assert(s.releasePending==0 and capital.defaults==0)
-- Population loss consumes the pending person: never reclaim someone else.
s.selected={[remote.n]=true};B.Cache(s).force=true;assert(B.Reconcile(s));s.selected={}
capital.AlterWorkingPlot=function() end
B.Cache(s).force=true;assert(B.Reconcile(s));assert(s.releasePending==1)
capital.defaults=capital.defaults-1;capital.forcedDefault=capital.forcedDefault-1;capital.pop=capital.pop-1
capital.AlterWorkingPlot=alter
assert(B.Reconcile(s));check();assert(s.releasePending==0 and capital.defaults==0)
-- A callback moves the next planned local worker after the first withdrawal.
-- Each later row must be rechecked, never clicked in the opposite direction.
capital.pop=capital.pop+1;capital.defaults=capital.defaults+1
capital:AlterWorkingPlot(12) -- fill one available job if any
local second=Remote(34,5,{6,9,3,2,0,0})
s.selected={[remote.n]=true,[second.n]=true}
local calls=0
capital.AlterWorkingPlot=function(self,i)
 local p=self.localPlots[i];assert(self:IsWorkingPlot(p),'stale withdrawal toggled an unworked plot')
 calls=calls+1;alter(self,i)
 if calls==1 then
  for _,q in ipairs(self.localPlots) do if self.worked[q.n] then
   self.worked[q.n]=nil;self.forced[q.n]=nil;self.defaults=self.defaults+1;self.forcedDefault=self.forcedDefault+1
   break
  end end
 end
end
B.Cache(s).force=true;assert(B.Reconcile(s));check()
capital.AlterWorkingPlot=alter
-- Legacy snapshots omit both optional fields; they acquire safe empty defaults.
local legacy=B.Decode(B.Encode(s));legacy.nativeReturns=nil;legacy.releasePending=nil
local raw=B.Encode(legacy);Players[0].script='|BCSTATE1:'..#raw..':'..raw..'|'
B.States={};B.Caches={};s=B.State(0)
assert(not s.incompatible and next(s.nativeReturns)==nil and s.releasePending==0)
print('PASS crash-path exclusion, returns, renewal/reload, blocked/no-op retries, population loss and stale withdrawal rows')
