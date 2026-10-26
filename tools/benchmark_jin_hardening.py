"""Repeatable operation counts and Lua timings; native FPS/pathfinding are not measured."""
import argparse,json,statistics,subprocess,time
from pathlib import Path
from validate_jin import database,apply,make_runtime,R,V

SETUP="""
local j=MapModData.JIN
Complete('FLOWER_PAGODA');Complete('DRAGON_PAVILION');Complete('PAGODA_FOREST')
for i=1,14 do City(0,2+4*((i-1)%5),2+6*math.floor((i-1)/5)) end
local s=j.State(0)
for tier=1,3 do local p=Map.GetPlot(10+tier,18);p.resource=-1;p.improvement=GameInfoTypes.IMPROVEMENT_JIN_GRASSLAND;s.pending[tier]=nil;s.grass[tier]={plot=p.index,horses=5,elapsed=0} end
s.garden=Map.GetPlot(5,5).index;plots[s.garden].improvement=GameInfoTypes.IMPROVEMENT_JIN_GARDEN
for _,city in ipairs({Players[0].cities[2],Players[0].cities[13],Players[0].cities[15]})do
 local count=0;for _,p in ipairs(j.Near(city:Plot(),3))do
  if count<5 and j.SiteLegal(0,p)then p.improvement=GameInfoTypes.IMPROVEMENT_JIN_GROVE;s.groves[p.index]=j.CityRecord(city);count=count+1 end
 end;assert(count==5)
end
j.Save(0,s)
nearPlots={};local reserved={}
for _,p in ipairs(j.Near(cap:Plot(),3))do if #nearPlots<12 and not p:IsCity() and j.Distance(p,Map.GetPlot(5,5))>2 then nearPlots[#nearPlots+1]=p;reserved[p.index]=true end end
assert(#nearPlots==12)
army={};for index=0,23*24-1 do local p=plots[index]
 if #army<armySize and not p:IsCity() and p:GetNumUnits()==0 and j.Distance(p,Map.GetPlot(5,5))>2 and not reserved[index] then army[#army+1]=Spawn('IRON_PAGODA',p.x,p.y)end
end;assert(#army==armySize)
enemies={};for i=1,12 do enemies[i]=Spawn('UNIT_WARRIOR',11+i,23,1)end;War(0,1,true)
if j.InvalidateSpatial then j.InvalidateSpatial(0) end
-- Native plot occupancy is O(1); don't benchmark the test double's global unit search.
local buckets={};for n in pairs(plots)do buckets[n]={}end
local function RemoveBucket(u)
 local old=buckets[u:GetPlot().index];for i=#old,1,-1 do if old[i]==u then table.remove(old,i)end end
end
function Place(u,x,y)
 RemoveBucket(u)
 u.x=x;u.y=y;local bucket=buckets[u:GetPlot().index];bucket[#bucket+1]=u
end
for pid=0,4 do for u in Players[pid]:Units()do Place(u,u.x,u.y)end end
for n,p in pairs(plots) do
 local bucket=buckets[n]
 p.GetNumUnits=function(self)return #bucket end
 p.GetUnit=function(self,i)return bucket[i+1]end
end
metrics={}
local function wrap(t,key,name)
 local original=t[key];if not original then return end
 t[key]=function(...)metrics[name]=(metrics[name]or 0)+1;return original(...)end
end
wrap(j.S,'Encode','encodes');wrap(j.S,'Decode','decodes');wrap(j,'Emplacements','emplacements');wrap(j,'Near','neighborhoods')
wrap(j,'UIRefresh','ui_requests')
local function Track(u)
 wrap(u,'IsHasPromotion','promotion_reads');wrap(u,'SetHasPromotion','promotion_writes')
 local kill=u.Kill;u.Kill=function(self,...)RemoveBucket(self);return kill(self,...)end
end
for pid=0,4 do local p=Players[pid];wrap(p,'SetScriptData','player_writes');wrap(p,'GetScriptData','player_reads')
 for u in p:Units()do Track(u)end
 local init=p.InitUnit;p.InitUnit=function(self,...)local u=init(self,...);if u then Place(u,u.x,u.y);Track(u)end;return u end
end
if j.Runtime then j.Runtime={} end
function ResetMetrics()metrics={}end
"""

def run(ref=None):
 d=database();apply(d);results=[]
 for size in [100,300,500]:
  lua,printed=make_runtime(d)
  if ref:
   def include(name):
    if name!='InstanceManager':
     source=subprocess.check_output(['git','show',ref+':JinDynasty/Lua/'+name+'.lua'],cwd=R).decode('utf-8')
     lua.execute(source)
   lua.globals().include=include
   lua.execute('ContextPtr={SetShutdown=function(self,fn)self.shutdown=fn end}')
   include('JIN_Core')
  lua.globals().armySize=size;lua.execute(SETUP)
  for name,code in [
   ('unchanged_hp','local j=MapModData.JIN;local s=j.State(0);j.Units(0,s)'),
   ('changed_horses','local j=MapModData.JIN;local s=j.State(0);s.grass[1].horses=(s.grass[1].horses==5 and 4 or 5);j.Save(0,s);j.Units(0,s)'),
   ('distant_enemy_1000','for i=1,1000 do local u=enemies[1+(i%12)];MapModData.JIN.Movement(1,u.id,u.x,u.y)end'),
   ('garden_army','local j=MapModData.JIN;for _,u in ipairs(army)do local x,y=u.x,u.y;Place(u,5,5);j.Movement(0,u.id,5,5);Place(u,x,y);j.Movement(0,u.id,x,y)end'),
   ('near_enemy_100','for i,u in ipairs(enemies)do Place(u,nearPlots[i].x,nearPlots[i].y)end;for i=1,100 do local u=enemies[1+(i%12)];MapModData.JIN.Movement(1,u.id,u.x,u.y)end'),
   ('unchanged_saves_100','local j=MapModData.JIN;local s=j.State(0);for i=1,100 do j.Save(0,s)end')]:
   values=[];counts=None
   for _ in range(3):
    lua.execute('ResetMetrics()');start=time.perf_counter();lua.execute(code);values.append((time.perf_counter()-start)*1000)
    if counts is None:counts=dict(lua.globals().metrics)
   results.append({'units':size,'scenario':name,'median_ms':round(statistics.median(values),3),'first_pass_operations':counts})
  assert not [x for x in printed if x.startswith('JIN ')],printed
 return results

def main():
 p=argparse.ArgumentParser();p.add_argument('--baseline-only',action='store_true');args=p.parse_args()
 baseline=run('f252c63');report={'baseline_ref':'f252c63','runtime':'Lupa Lua 5.1 with native doubles','native_FPS':'NOT MEASURED','native_pathfinding':'NOT MEASURED','repeats':3,'fixture':'100/300/500 distinct military plots; 12 enemy movers on distinct reserved plots; 15 city emplacements; 3 stocked Grasslands; 15 Groves, 5 per valid nearby city; native-style constant-time plot occupancy; Garden enter/exit per unit; no deferred native orders pumped','baseline':baseline}
 if not args.baseline_only:report['hardened']=run()
 out=R/'dist/jin-hardening-baseline-expanded.json' if args.baseline_only else V/'docs/HardeningBenchmark.json'
 out.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n');print('Wrote',out)
if __name__=='__main__':main()
