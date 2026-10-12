local B=MapModData.BoundlessCity
MakeMap(100,30,false);capital=MakeCity(0,3,5,80,30);foreign=MakeCity(1,60,5,4,6)
Players[0].cities={capital};Players[1].cities={foreign};Players[0].script='third-party-player;'
local count=31
for n=0,Map.GetNumPlots()-1 do local p=plots[n]
 if count>=500 then break end
 if p.owner==-1 and Map.PlotDistance(3,5,p.x,p.y)>5 then p.owner=0;p.yields={7,11,5,3,2,4};count=count+1 end
end
B.States={};B.Caches={};B.Watch={};B.Initialize(0);local s=B.State(0)
capital.extra[1]=2;capital.extra[2]=1;capital.modifier=150
local misc,terrain={},{}
for y=0,5 do misc[y]=100+y;terrain[y]=70+y;capital.misc[y]=(capital.misc[y] or 0)+misc[y];capital.terrain[y]=(capital.terrain[y] or 0)+terrain[y] end
local locals=B.LocalPlots(capital);s.selected={};s.locks={};local requests=0
for _,n in ipairs(B.Keys(B.Ownership(s).owned)) do
 if not locals[n] and not plots[n]:IsCity() and requests<80 then s.selected[n]=true;requests=requests+1 end
end
local function verify()
 capital:Check();local a=B.Summary(s)
 assert(a.localCount+a.remote+a.specialists+a.idle+a.unassigned==capital.pop+capital:GetAutomatons())
 for y=0,5 do
  local gross=0;for n in pairs(s.assignments) do gross=gross+plots[n]:GetYield(y) end
  local per=(y==1 and 1 or 0)+(capital.extra[y] or 0)
  assert(capital.terrain[y]==terrain[y]+gross,'phantom terrain source')
  assert(capital.misc[y]==misc[y]-a.remote*per,'phantom labourer compensation')
  local native=0;for _,p in ipairs(capital.localPlots) do if capital.worked[p.n] then native=native+p:GetYield(y) end end
  assert(capital:NativeYield(y)==(misc[y]+terrain[y]+native+gross+(capital.defaults-a.remote)*per)*1.5)
 end
end
for _=1,12 do
 for _,mode in ipairs({'AUTO','MANUAL','HYBRID','AUTO'}) do assert(B.Action(0,'MODE',mode));verify() end
end
assert(s.reserved==50,'population 80 must retain the verified surplus beyond 30 jobs')
-- Golden Age plot additions and policy/religion-specific default extras change real sources.
local n=next(s.assignments);local p=plots[n];p.yields[3]=p.yields[3]+1
capital.extra[1]=3;GameEvents.PlayerAdoptPolicy.Fire(0);Pump();verify()
local nativeSnapshot={pop=capital.pop,defaults=capital.defaults,forcedDefault=capital.forcedDefault,
 specialists=capital.specialists,worked=capital.worked,forced=capital.forced,misc=capital.misc,terrain=capital.terrain,extra=capital.extra}
local nativeRaw=B.Encode(nativeSnapshot);local playerRaw=Players[0].script;local plotRaw=Map.GetPlot(3,5):GetScriptData()
s.progress=54321;s.rewards[p.n]=true;B.Save(s);playerRaw=Players[0].script
for _=1,10 do
 local restored=B.Decode(nativeRaw);for k,v in pairs(restored) do capital[k]=v end
 Players[0].script=playerRaw;Map.GetPlot(3,5):SetScriptData(plotRaw);B.States={};B.Caches={};B.Initialize(0);s=B.State(0)
 assert(s.progress==54321 and s.rewards[p.n] and s.version==2);verify()
end
-- Native rewind must restore ownership/progress as well as source accounting.
local lost=next(s.assignments);plots[lost]:SetOwner(1,foreign.id);Pump();assert(not s.assignments[lost]);verify()
plots[lost].owner=0;plots[lost].owningCity=capital.id
local function rewind()
 local restored=B.Decode(nativeRaw);for k,v in pairs(restored) do capital[k]=v end
 Players[0].script=playerRaw;Map.GetPlot(3,5):SetScriptData(plotRaw);B.States={};B.Caches={};B.Initialize(0);s=B.State(0)
 assert(s.progress==54321 and s.rewards[p.n]);verify()
end
rewind();assert(s.assignments[lost])
-- A living Boundless recipient with zero cities may recover only its recorded
-- original capital; it must never receive an unrelated replacement/second city.
Players[1].GetCivilizationType=function() return 100 end;B.Initialize(1)
Players[0]:AcquireCity(foreign);B.RecoverCities(s)
assert(foreign.owner==1 and Players[1]:GetNumCities()==1 and Players[0]:GetNumCities()==1)
assert(B.City(B.State(1))==foreign,'safe original-capital return must restore the same identity')
Players[1].GetCivilizationType=function() return 99 end
local ownedBefore={};for index in pairs(B.Ownership(s).owned) do ownedBefore[index]=true end
s.progress=B.Cost(s)-capital.culture;B.Busy[0]=true;B.Expand(s);B.Busy[0]=nil
local claimed;for index in pairs(B.Ownership(s).owned) do if not ownedBefore[index] then assert(not claimed);claimed=index end end
assert(claimed,'one frontier claim expected');verify();plots[claimed].owner=-1;plots[claimed].owningCity=-1;rewind()
-- Optional mirror failure must not erase successful native persistence or yields.
local mirrorSetter=SaveMirror.SetValue;SaveMirror.SetValue=function() error('unavailable optional mirror') end
s.progress=s.progress+1;assert(B.Save(s));B.Cache(s).force=true;assert(B.Reconcile(s));verify()
assert(B.Decode(Players[0].script:match('|BCSTATE1:%d+:(.*)|')).progress==54322)
SaveMirror.SetValue=mirrorSetter
local mirrorOpen=Modding.OpenSaveData;Modding.OpenSaveData=function() error('optional mirror open fault') end
include('BoundlessPersistence');assert(B.Save(s));verify()
Modding.OpenSaveData=mirrorOpen;include('BoundlessPersistence')
-- Indexed trim fails AFTER a native terrain mutation, then immediately clears all credits.
local oldSetter=capital.ChangeBaseYieldRateFromTerrain;local failed=false
capital.ChangeBaseYieldRateFromTerrain=function(self,y,d)
 oldSetter(self,y,d);if not failed then failed=true;error('indexed trim mutation fault') end
end
n=next(s.assignments);plots[n].yields[1]=plots[n].yields[1]+3;B.Trim(s,{[n]=true})
assert(s.reserved==0 and next(s.assignments)==nil and B.Cache(s).scalar==nil and s.phase=='RECOVER');verify()
capital.ChangeBaseYieldRateFromTerrain=oldSetter;Pump();assert(s.reserved==50);verify()
failed=false;capital.ChangeBaseYieldRateFromTerrain=function(self,y,d)
 oldSetter(self,y,d);if not failed then failed=true;error('full trim mutation fault') end
end
n=next(s.assignments);plots[n].yields[2]=plots[n].yields[2]+4;B.Trim(s)
assert(s.reserved==0 and s.phase=='RECOVER');verify();capital.ChangeBaseYieldRateFromTerrain=oldSetter;Pump();verify()
-- An unannounced source reset cannot be guessed away or sent to the native
-- terrain setter as a negative total. Preserve its journal and refuse new credits.
local physicalTerrain=B.Encode(capital.terrain);capital.terrain[0]=0
B.Cache(s).force=true;assert(not B.Reconcile(s))
assert(capital.terrain[0]==0 and s.phase=='RECOVER' and B.Summary(s).availableRemote==0)
capital.terrain=B.Decode(physicalTerrain);B.Cache(s).force=true;assert(B.Reconcile(s));verify()
-- External automaton adjustment with unchanged population/default/specialist scalars.
capital.automatons=1;capital.unassigned=1;capital:Check();n=next(s.assignments)
B.Trim(s,{[n]=true});assert(s.reserved==0 and B.Summary(s).availableRemote==0);verify()
capital.automatons=0;capital.unassigned=0;B.Cache(s).force=true;assert(B.Reconcile(s));verify()
-- Abrupt native starvation allocation from 80 to 6, followed by a population event.
capital.pop=6;capital.forcedDefault=0;GovernorWorst(capital);GameEvents.SetPopulation.Fire(3,5)
assert(s.reserved<=6);verify();Pump();verify()
-- Genuine unassigned people remain visible and do not receive fabricated defaults.
assert(B.Action(0,'MODE','MANUAL'));s.selected={};s.locks={};B.Cache(s).force=true;assert(B.Reconcile(s))
local localIndex=next(capital.worked);capital.worked[localIndex]=nil;capital.unassigned=1
B.Cache(s).force=true;assert(B.Reconcile(s));assert(B.Summary(s).unassigned==1 and s.reserved==0);verify()
-- Simultaneous protected transfers from eliminated owners survive native callbacks,
-- enter resistance only afterwards, and reload without granting their plot yields.
Players[1].IsAlive=function() return false end;Players[2].IsAlive=function() return false end;Players[2].minor=true
local a=MakeCity(0,50,20,3,2);a.original=1;a.previous=1;a.holy=true
local b=MakeCity(0,60,20,3,2);b.original=2;b.previous=2
Players[0].cities={capital,a,b}
insideCapture=true;GameEvents.CityCaptureComplete.Fire(1,false,50,20,0);GameEvents.CityCaptureComplete.Fire(2,false,60,20,0)
assert(a:GetResistanceTurns()==0 and b:GetResistanceTurns()==0 and #Players[0].cities==3);insideCapture=false;Pump()
assert(a:GetResistanceTurns()==2 and b:GetResistanceTurns()==2 and #Players[0].cities==3)
assert(not B.Eligible(s,Map.GetPlot(51,20)) and not B.Eligible(s,Map.GetPlot(61,20)))
assert(#Players[2].cities==0 and #Players[1].cities==1,'no arbitrary recipient/resurrection is allowed')
local savedProgress=s.progress;B.Save(s);B.States={};B.Caches={};B.Initialize(0);s=B.State(0);B.RecoverCities(s)
assert(s.progress==savedProgress and not B.Eligible(s,Map.GetPlot(51,20)));verify()
-- Created/gifted Settlers are removed after the native callback, even with the capital lost.
Players[0].cities={};Map.GetPlot(3,5).city=nil;Map.GetPlot(3,5).owner=1
local settler=MakeUnit(900,401);GameEvents.UnitCreated.Fire(0,900)
assert(not settler.dead,'unit creation callback must not delete its active native object');Pump();assert(settler.dead)
-- Before the original city exists, the initial Settler remains available.
Players[0].script='';B.States={};B.Caches={};local initial=MakeUnit(901,401)
GameEvents.UnitCreated.Fire(0,901);Pump();assert(not initial.dead)
print('PASS mode churn, six-source conservation, policy/Golden-Age simulation, ownership/frontier rewind, mirror/trim faults, automatons, abrupt loss, simultaneous dead-owner quarantine reload and deferred Settlers')
