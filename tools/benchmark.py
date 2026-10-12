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
    lua.execute('''GameDefines.MAX_MAJOR_CIVS=22;GameDefines.MAX_CIV_PLAYERS=63
for pid=0,62 do
 if not Players[pid] then Players[pid]=setmetatable({pid=pid,cities={},units={},human=false},getmetatable(Players[1])) end
 Players[pid].IsBarbarian=function() return pid==62 end
 Players[pid].IsMinorCiv=function() return pid>=22 and pid<62 end
 if not Teams[pid] then Teams[pid]={IsAtWar=function(self,other) return other~=pid end,IsWaterWork=function() return true end} end
end''')
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
           'major_player_records': 22, 'minor_player_slots': 40, 'foreign_military_units': 200,
           'initialization_ms': round(initial, 3)}
    row['full_reconcile'] = measure(lua, 'B.Cache(s).force=true;assert(B.Reconcile(s));capital:Check()')
    row['assignment_change'] = measure(lua, "assert(B.Action(0,'PRIORITY',s.priority=='FOOD' and 'PRODUCTION' or 'FOOD'))")
    row['remote_workers'] = lua.eval('s.reserved')
    lua.execute('''military={}
for id=1,200 do local u=MakeUnit(id,600);Players[0].units[#Players[0].units]=nil
 local pid=1+(id-1)%21;u.x=150;u.y=70
 function u:GetX() return self.x end;function u:GetY() return self.y end
 Players[pid].units[#Players[pid].units+1]=u;military[id]={unit=u,pid=pid};GameEvents.UnitCreated.Fire(pid,id)
end''')
    row['movement_1000_unrelated'] = measure(lua, '''for i=1,1000 do local r=military[(i-1)%200+1]
r.unit.x=145+i%5;r.unit.y=68+i%4;B.Movement(r.pid,r.unit.id,r.unit.x,r.unit.y) end''')
    row['movement_1000_near_owned'] = measure(lua, '''local n=next(B.Cache(s).remoteFootprint);local p=plots[n]
for i=1,1000 do local r=military[(i-1)%200+1];r.unit.x=p.x;r.unit.y=p.y;B.Movement(r.pid,r.unit.id,p.x,p.y) end
assert(deferred==nil,'unchanged movement should not queue reconciliation')''', 5)
    row['hostile_entry_departure_coalesced_batch'] = measure(lua, '''local keys=B.Keys(B.Cache(s).remoteFootprint)
local count=math.min(200,#keys)
for i=1,count do local p=plots[keys[i]];local r=military[i];p.enemy=true;r.unit.x=p.x;r.unit.y=p.y
 B.Movement(r.pid,r.unit.id,p.x,p.y) end
for i=1,count do local p=plots[keys[i]];local r=military[i];p.enemy=false;r.unit.x=150;r.unit.y=70
 B.Movement(r.pid,r.unit.id,150,70) end
Pump();assert(deferred==nil);capital:Check()''', 5)
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
    row['ai_cached_plan'] = measure(lua, 'now=now+1;local before=pathCalls;B.AIWorkers(s);assert(pathCalls-before<=12)')
    row['ai_same_turn_reentry'] = measure(lua, 'local before=pathCalls;B.AIWorkers(s);assert(pathCalls==before)')
    row['ai_native_paths_per_turn_limit'] = 12
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
