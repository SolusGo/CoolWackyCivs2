"""Measured Lua 5.1 simulation timings; native pathfinding/FPS are NOT measured."""
from pathlib import Path
import json, platform, statistics, time
from lupa.lua51 import LuaRuntime

R = Path(__file__).resolve().parents[1]
V = R / 'TheBoundlessCity'


def scenario(owned):
    lua = LuaRuntime()
    def include(name):
        if name != 'InstanceManager':
            lua.execute((V / 'Lua' / (name + '.lua')).read_text(encoding='utf-8'))
    lua.globals().include = include
    lua.execute((R / 'tools/tests/boundless_mock.lua').read_text())
    lua.execute('''MakeMap(200,80,true)
capital=MakeCity(0,3,5,150,30);Players[0].cities={capital};Players[1].cities={};Players[0].script=''
for _,p in pairs(plots) do p.owner=-1 end
Map.GetPlot(3,5).owner=0
for _,p in ipairs(capital.localPlots) do p.owner=0 end
''')
    lua.globals().desiredOwned = owned
    lua.execute('''local count=31
for n=0,Map.GetNumPlots()-1 do local p=plots[n]
 if count>=desiredOwned then break end
 if p.owner==-1 then p.owner=0;p.yields={3,8+n%3,2,1,1,1};count=count+1 end
end''')
    start = time.perf_counter()
    include('BoundlessCore')
    initialization = (time.perf_counter() - start) * 1000
    lua.execute('B=MapModData.BoundlessCity;s=B.State(0)')
    return lua, initialization


def measure(lua, code, iterations=9):
    samples = []
    for _ in range(iterations):
        start = time.perf_counter()
        lua.execute(code)
        samples.append((time.perf_counter() - start) * 1000)
    return {'iterations': iterations, 'median_ms': round(statistics.median(samples), 3),
            'max_ms': round(max(samples), 3)}


results = []
for owned in [100, 500, 1000, 2500, 10000]:
    lua, initial = scenario(owned)
    row = {'initial_owned': owned, 'world_plots': 16000, 'population': 150,
           'initialization_ms': round(initial, 3)}
    row['full_reconcile'] = measure(lua, 'B.Cache(s).force=true;assert(B.Reconcile(s));capital:Check()')
    row['assignment_change'] = measure(lua, "assert(B.Action(0,'PRIORITY',s.priority=='FOOD' and 'PRODUCTION' or 'FOOD'))")
    row['remote_workers'] = lua.eval('s.reserved')
    row['movement_1000_unrelated'] = measure(lua, 'for i=1,1000 do B.Movement(1,10,150,70) end')
    row['movement_1000_near_owned'] = measure(lua, '''local n=next(B.Cache(s).remoteFootprint);local p=plots[n]
for i=1,1000 do B.Movement(1,11,p.x,p.y) end
assert(deferred==nil,'unchanged movement should not queue reconciliation')''', 5)
    row['frontier_single_claim'] = measure(lua, '''s.progress=B.Cost(s)-capital.culture
local count=B.Ownership(s).count;B.Busy[0]=true;B.Expand(s);B.Busy[0]=nil
assert(B.Ownership(s).count==count+1);Pump()''')
    lua.execute('''Players[0].human=false;pathCalls=0;buildChecks=0
for i=1,20 do local u=MakeUnit(i,400)
 function u:MovesLeft() return 60 end
 function u:GeneratePath(p) pathCalls=pathCalls+1;return {{X=p.x,Y=p.y}} end
 local native=u.CanBuild
 function u:CanBuild(p,b) buildChecks=buildChecks+1;return native(self,p,b) end
end
B.Cache(s).aiDirty=true''')
    row['ai_cache_rebuild_and_plan'] = measure(lua, 'B.Cache(s).aiDirty=true;B.AIWorkers(s)', 1)
    row['ai_cached_plan'] = measure(lua, 'local before=pathCalls;B.AIWorkers(s);assert(pathCalls-before<=12)')
    row['ai_native_paths_per_pass_limit'] = 12
    row['ai_measured_path_calls_total'] = lua.eval('pathCalls')
    lua.execute('Players[0].human=true')
    lua.globals().LoadWorkforceUI = lambda: lua.execute((V / 'UI/BoundlessWorkforce.lua').read_text())
    lua.execute((R / 'tools/tests/ui_assertions.lua').read_text())
    lua.execute('Controls.Open.callback()')
    row['ui_first_rows_build'] = measure(lua, "B.Cache(s).rows=nil;LuaEvents.BoundlessChanged(0)", 3)
    row['ui_cached_open_refresh_100'] = measure(lua, 'for i=1,100 do LuaEvents.BoundlessChanged(0) end')
    lua.execute('Controls.Close.callback()')
    row['ui_closed_refresh_1000'] = measure(lua, 'for i=1,1000 do LuaEvents.BoundlessChanged(0) end')
    row['ui_remote_rows'] = lua.eval("#B.RemoteRows(s,'DISTANCE')")
    results.append(row)

result = {'date': '2026-10-12', 'environment': platform.platform(), 'python': platform.python_version(),
          'runtime': 'Lupa Lua 5.1; synthetic native calls', 'world_scan': 'once per player initialization',
          'idle_frame_polling': False, 'native_Civ_V': 'NOT RUN', 'native_pathfinding': 'NOT MEASURED',
          'native_FPS': 'NOT MEASURED', 'scenarios': results}
output = json.dumps(result, indent=2) + '\n'
print(output)
(V / 'docs/Benchmark.json').write_text(output, encoding='utf-8', newline='\n')
