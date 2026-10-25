"""Measure shipped Jin Lua with synthetic native calls; no native FPS claims."""
import json,statistics,time
from validate_jin import database,apply,make_runtime,V
def main():
 d=database();apply(d);lua,printed=make_runtime(d)
 lua.execute("Complete('GREAT_PASTURE');Complete('DRAGON_PAVILION');Complete('PAGODA_FOREST');for i=1,100 do Spawn('IRON_PAGODA',7+i%4,7+math.floor(i/4)%4) end;War(0,1,true)")
 result={}
 for name,code,repeats in [
  ('100_unit_owner_turn','now=now+1;MapModData.JIN.Turn(0)',20),
  ('1000_unrelated_movements','for i=1,1000 do MapModData.JIN.Movement(1,-1,22,22) end',10),
  ('save_decode_encode','local j=MapModData.JIN;local s=j.State(0);j.Save(0,s)',100)]:
  values=[]
  for _ in range(repeats):
   start=time.perf_counter();lua.execute(code);values.append((time.perf_counter()-start)*1000)
  result[name]={'median_ms':round(statistics.median(values),3),'max_ms':round(max(values),3),'repeats':repeats}
 assert not [p for p in printed if p.startswith('JIN ')],printed
 report={'date':'2026-10-26','runtime':'Lupa Lua 5.1; synthetic native calls','native_FPS':'NOT MEASURED','native_pathfinding':'NOT MEASURED','continuous_frame_polling':False,'scenarios':result}
 (V/'docs/Benchmark.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
