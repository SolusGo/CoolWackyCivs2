"""Compare shipped Lua with its previous planner in the same native model.

These timings measure Lua simulation, not Civ V FPS, turn time or DLL latency.
"""
from pathlib import Path
import argparse
import json
import statistics
import subprocess
import time
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]


def scenario(owned,baseline=None):
    lua=LuaRuntime()
    def include(name):
        relative='TheBoundlessCity/Lua/'+name+'.lua'
        source=(subprocess.run(['git','show',baseline+':'+relative],cwd=ROOT,capture_output=True,check=True).stdout.decode()
                if baseline else (ROOT/relative).read_text(encoding='utf-8'))
        lua.execute(source)
    lua.globals().include=include
    lua.execute((ROOT/'tools/tests/boundless_mock.lua').read_text())
    lua.globals().ownedTarget=owned
    lua.execute('''
        MakeMap(200,80,true);capital=MakeCity(0,3,5,150,30);foreign=MakeCity(1,160,70,4,6)
        Players[0].cities={capital};Players[1].cities={foreign};Players[0].units={};Players[0].script=''
        local count=31
        for n=0,Map.GetNumPlots()-1 do local p=plots[n]
          if count>=ownedTarget then break end
          if p.owner==-1 then p.owner=0;p.yields={3,8+n%3,2,1,1,1};count=count+1 end
        end
    ''')
    include('BoundlessCore')
    lua.execute('''
        B=MapModData.BoundlessCity;s=B.State(0);s.priority='PRODUCTION';B.Cache(s).force=true;assert(B.Reconcile(s))
        reads=0;scriptWrites=0
        local methods=getmetatable(plots[0]).__index;local getter=methods.GetYield
        methods.GetYield=function(self,y) reads=reads+1;return getter(self,y) end
        local setter=Players[0].SetScriptData
        Players[0].SetScriptData=function(self,data)scriptWrites=scriptWrites+1;return setter(self,data)end
    ''')
    return lua


def measure(lua,code):
    samples=[];mutations=[];reads=[];writes=[]
    for _ in range(7):
        lua.execute('reads=0;scriptWrites=0;beforeMutations=mutations')
        started=time.perf_counter();lua.execute(code);samples.append((time.perf_counter()-started)*1000)
        mutations.append(lua.eval('mutations-beforeMutations'));reads.append(lua.eval('reads'));writes.append(lua.eval('scriptWrites'))
    return {'median_ms':round(statistics.median(samples),3),'native_model_mutations_max':max(mutations),
            'plot_yield_reads_max':max(reads),'player_script_writes_max':max(writes),'samples':len(samples)}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline',default='ad7840b')
    parser.add_argument('--output',type=Path,default=ROOT/'TheBoundlessCity/docs/RemotePlannerBenchmark.json')
    args=parser.parse_args();results=[]
    commit=subprocess.run(['git','rev-parse',args.baseline],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip()
    for owned in (250,2500,10000):
        row={'owned_plots':owned,'population':150}
        for label,ref in (('before',commit),('after',None)):
            lua=scenario(owned,ref)
            row[label]={
                'forced_full_validation':measure(lua,'B.Cache(s).force=true;assert(B.Reconcile(s));capital:Check()'),
                'known_unchanged_update':measure(lua,'if B.InvalidatePlan then B.InvalidatePlan(s,{}) end;B.Cache(s).force=true;assert(B.Reconcile(s));capital:Check()'),
            }
        results.append(row);print(json.dumps(row))
    report={'date':'2026-10-26','baseline_commit':commit,'measurement':'Lua 5.1 simulation; not native Civ V timings',
            'world_plots':16000,'results':results}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')


if __name__=='__main__':main()
