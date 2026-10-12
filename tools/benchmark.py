"""Repeatable 16,000-plot Lua microbenchmark. This is not an in-game FPS benchmark."""
from pathlib import Path
import statistics,time,json
from lupa.lua51 import LuaRuntime
R=Path(__file__).resolve().parents[1];V=R/'TheBoundlessCity'
lua=LuaRuntime()
def include(name):lua.execute((V/'Lua'/f'{name}.lua').read_text(encoding='utf-8'))
lua.globals().include=include
lua.execute((R/'tools/tests/boundless_mock.lua').read_text())
lua.execute('''MakeMap(160,100,true)
capital=MakeCity(0,3,5,40,60);foreign=MakeCity(1,100,60,4,6)
Players[0].cities={capital};Players[1].cities={foreign}
for n,p in pairs(plots) do if not p.city then p.owner=0;p.yields={n%6,(n*3)%7,n%3,0,0,0} end end
''')
start=time.perf_counter();include('BoundlessCore');initial=time.perf_counter()-start
values=[]
for _ in range(20):
    start=time.perf_counter();lua.execute('local B=MapModData.BoundlessCity;B.Cache(B.State(0)).force=true;B.Reconcile(B.State(0));capital:Check()')
    values.append(time.perf_counter()-start)
result={'environment':'Python 3.11 + Lupa Lua 5.1; synthetic native calls, not Civ V',
 'plots':16000,'population':40,'iterations':20,'initialization_ms':round(initial*1000,2),
 'reconcile_median_ms':round(statistics.median(values)*1000,2),'reconcile_max_ms':round(max(values)*1000,2),
 'remote_workers':lua.eval('MapModData.BoundlessCity.State(0).reserved'),
 'idle_frame_polling':False,'in_game_huge_map_benchmark':'NOT RUN'}
print(json.dumps(result,indent=2))
(V/'docs/Benchmark.json').write_text(json.dumps(result,indent=2)+'\n')
