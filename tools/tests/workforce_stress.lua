local B=MapModData.BoundlessCity
local cases={{10,30,10},{40,150,30},{80,500,50},{150,1000,120}}
for _,case in ipairs(cases) do
 MakeMap(100,30,false);capital=MakeCity(0,3,5,case[1],30);foreign=MakeCity(1,60,5,4,6)
 Players[0].cities={capital};Players[1].cities={foreign};Players[0].units={};Players[0].script='other-mod;'
 if case[1]==10 then for i=11,30 do capital.localPlots[i].owner=-1 end end
 local count=0;for _,p in pairs(plots) do if p.owner==0 then count=count+1 end end
 for n=0,Map.GetNumPlots()-1 do local p=plots[n]
  if count>=case[2] then break end
  if p.owner==-1 and Map.PlotDistance(3,5,p.x,p.y)>5 then p.owner=0;p.yields={5,8,3,2,1,1};count=count+1 end
 end
 B.States={};B.Caches={};B.Watch={};B.Initialize(0)
 local s=B.State(0);s.mode='MANUAL';s.selected={};s.locks={};s.excluded={}
 local locals=B.LocalPlots(capital);local requests=0
 for _,n in ipairs(B.Keys(B.Ownership(s).owned)) do
  if not locals[n] and not plots[n]:IsCity() and requests<case[1] then s.selected[n]=true;s.locks[n]=true;requests=requests+1 end
 end
 capital.extra[1]=2;capital.extra[2]=1;capital.misc[1]=(capital.misc[1] or 0)+123;capital.misc[3]=(capital.misc[3] or 0)+77;capital.modifier=150
 B.Cache(s).force=true;assert(B.Reconcile(s));assert(s.reserved==case[3], 'conservative source-verified capacity changed')
 local function verify()
  capital:Check();local a=B.Summary(s)
  assert(a.localCount+a.remote+a.specialists+a.idle+a.unassigned==capital.pop)
  assert(a.remote<=capital.defaults and a.remote<=capital.pop-a.specialists)
  local per={0,3,1,0,0,0}
  for y=0,5 do
   local raw=(y==1 and 123 or y==3 and 77 or 0)+(capital.defaults-a.remote)*per[y+1]
   for _,p in ipairs(capital.localPlots) do if capital.worked[p.n] then raw=raw+p:GetYield(y) end end
   for n in pairs(s.assignments) do raw=raw+plots[n]:GetYield(y) end
   assert(capital:NativeYield(y)==raw*1.5,'source/city multiplier or labourer compensation applied twice')
  end
 end
 verify();local before=capital:NativeYield(1)
 GovernorWorst(capital);verify() -- Critical: safe BEFORE the delayed Lua reconciliation.
 GameEvents.PlayerDoneTurn.Fire(0);verify()
 local snapshot=Players[0].script;local ledger=Map.GetPlot(3,5):GetScriptData()
 local production=capital:NativeYield(1)
 B.States={};B.Caches={};B.Initialize(0);s=B.State(0);verify()
 assert(capital:NativeYield(1)==production and s.version==3,'native save reloaded twice after schema migration')
 local a=B.Summary(s);assert(a.pending==case[1]-case[3]);assert(a.availableRemote==0)
 print('PASS population '..case[1]..' / owned '..case[2]..' / safe remote '..a.remote..' / pending '..a.pending)
 -- Building capacity is accounted for BEFORE the governor can fill the new slots.
 capital.buildings[1000]=1;GameEvents.CityConstructed.Fire(0,capital.id,1000);GovernorWorst(capital);Pump();verify()
 -- Growth and starvation use actual native default citizens, never manufactured population.
 capital.pop=capital.pop+1;capital.defaults=capital.defaults+1;GameEvents.SetPopulation.Fire(3,5);Pump();verify()
 capital.pop=capital.pop-1;capital.defaults=capital.defaults-1;capital.forcedDefault=math.min(capital.forcedDefault,capital.defaults)
 GameEvents.SetPopulation.Fire(3,5);Pump();verify()
end
print('PASS adversarial governor, specialist slots, signed compensation, modifiers, reload, growth and starvation')
