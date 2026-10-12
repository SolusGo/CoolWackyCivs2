local B=MapModData.BoundlessCity;local s=B.State(0)
capital.originalCapital=false;assert(not B.City(s),'coordinates/founding turn alone must not activate a replacement city')
capital.originalCapital=nil;assert(B.City(s)==capital)
local low=Remote(24,5,{0,0,0,0,0,0});local high=Remote(34,5,{6,8,3,2,4,1})
-- Mode separation: Automatic ignores old locks; Manual selection survives Unlock.
s.locks[low.n]=true;s.selected[low.n]=true;s.mode='AUTO';B.Cache(s).force=true;assert(B.Reconcile(s))
assert(s.assignments[high.n] and not s.assignments[low.n])
s.mode='MANUAL';s.selected={[high.n]=true};s.locks={[high.n]=true};B.Cache(s).force=true;assert(B.Reconcile(s))
assert(B.Action(0,'LOCK',high.n));assert(s.selected[high.n] and s.assignments[high.n] and not s.locks[high.n])
local a=B.Summary(s);assert(a.remote==1 and a.locks==0 and a.pending==0)
-- Signed deltas and CP's count-multiplied extras must not touch unrelated sources.
capital.extra[1]=2;capital.misc[1]=(capital.misc[1] or 0)+123;B.Cache(s).force=true;assert(B.Reconcile(s))
assert(capital.misc[1]==120 and capital.terrain[1]==8)
assert(capital.cached[0]==capital:NativeYield(0),'terrain-only Food needs a native cache refresh')
local oldSetter=capital.ChangeBaseYieldRateFromTerrain;local calls=0
capital.ChangeBaseYieldRateFromTerrain=function(self,y,d)
 calls=calls+1;oldSetter(self,y,d)
 if calls==2 then error('injected exception AFTER native mutation') end
end
local ok=B.Reconcile(s) -- unchanged state: no mutation, no injected fault.
assert(ok);B.Cache(s).force=true;assert(not B.Reconcile(s))
assert(capital.misc[1]==123 and (capital.terrain[1] or 0)==0,'partial journal removed an unrelated source')
assert(s.reserved==0 and s.phase=='RECOVER');capital:Check()
capital.ChangeBaseYieldRateFromTerrain=oldSetter;B.Cache(s).force=true;assert(B.Reconcile(s));assert(s.assignments[high.n])
local oldMiscSetter=capital.ChangeBaseYieldRateFromMisc;local injected=false
capital.ChangeBaseYieldRateFromMisc=function(self,y,d)
 oldMiscSetter(self,y,d)
 if y==0 and d==1 and not injected then injected=true;error('fault after cache pulse') end
end
B.Cache(s).force=true;assert(not B.Reconcile(s))
assert((capital.misc[0] or 0)==0 and capital.misc[1]==123,'cache pulse must also be journalled')
capital.ChangeBaseYieldRateFromMisc=oldMiscSetter;B.Cache(s).force=true;assert(B.Reconcile(s))
-- Explicit v1 state/ledger migration keeps progress, rewards, directions and selections.
local legacy=B.Decode(B.Encode(s));legacy.version=1;legacy.progress=4321;legacy.direction='EAST';legacy.rewards[low.n]=true
legacy.selected=nil;legacy.locks={[high.n]=true};legacy.reserved=s.withdrawn
local oldMisc={};for i,y in ipairs(B.Yields) do oldMisc[i]=(B.Cache(s).remoteYields[i] or 0)-(B.Cache(s).labourerYields[i] or 0) end
B.ApplyLedger(capital,{},{})
for i,y in ipairs(B.Yields) do capital:ChangeBaseYieldRateFromMisc(y.id,oldMisc[i]) end
local words={};for i=1,#B.Yields do words[i]=tostring(oldMisc[i]) end
Map.GetPlot(3,5):SetScriptData('unrelated-plot;|BCY1:'..table.concat(words,',')..'|')
local raw=B.Encode(legacy);Players[0].script='unrelated-player;|BCSTATE1:'..#raw..':'..raw..'|'
B.States={};B.Caches={};B.Initialize(0);s=B.State(0)
assert(s.version==3 and s.progress==4321 and s.direction=='EAST' and s.rewards[low.n] and s.selected[high.n])
assert(capital.misc[1]==120 and capital.terrain[1]==8)
assert(Map.GetPlot(3,5):GetScriptData():find('unrelated%-plot;') and Players[0].script:find('unrelated%-player;'))
-- Returning an EXTRA city must preserve the CAPITAL's citizen reservation records.
local remote=s.reserved;local withdrawn=s.withdrawn
local extra=MakeCity(0,52,10,2,2);extra.original=1;extra.previous=1;Players[0].cities[#Players[0].cities+1]=extra
insideCapture=true;GameEvents.CityCaptureComplete.Fire(1,false,52,10,0);insideCapture=false;Pump()
assert(extra.owner==1 and s.reserved==remote and s.withdrawn==withdrawn)
extra.protected=true;Players[0]:AcquireCity(extra);B.RecoverCities(s)
assert(extra.owner==0 and s.pending[Map.GetPlot(52,10).n],'return ping-pong must quarantine instead of looping')
assert(extra.automatedProduction==false and #extra.orders==0)
assert(extra:GetResistanceTurns()==2 and capital:GetResistanceTurns()==0)
assert(not B.Eligible(s,Map.GetPlot(53,10)),'quarantined city tiles must not supply remote work or Surveyor targets')
for y=0,5 do assert(extra:NativeYield(y)==0 and extra.cached[y]==0,'quarantined ordinary economic rates must be zero') end
extra:ChangeResistanceTurns(-1);assert(extra:GetResistanceTurns()==1)
B.RecoverCities(s);assert(extra:GetResistanceTurns()==2,'resistance must remain positive after the next native decrement')
now=now+1;B.RecoverCities(s)
assert(extra.owner==1,'a legitimate later-turn transfer must not be treated as an eternal return loop')
-- A legal orphan is removed with only its purchased tiles released.
local orphan=MakeCity(0,50,12,2,2);orphan.original=3;orphan.previous=3;Players[0].cities[#Players[0].cities+1]=orphan
local index=Map.GetPlot(51,12).n;B.Cache(s).territoryDirty=true;B.Cache(s).owned[index]=true
B.RecoverCities(s);assert(not Map.GetPlot(50,12):IsCity() and Map.GetPlot(51,12).owner==-1)
assert(capital.owner==0 and high.owner==0,'fallback must preserve capital territory')
-- Idle capacity is limited by the actual eligible remote inventory.
local cache=B.Cache(s);B.RefreshEligibility(s);local summary=B.Summary(s)
assert(summary.availableRemote<=cache.eligibleCount-summary.remote)
local hostile=MakeUnit(99,600);Players[0].units[#Players[0].units]=nil;Players[1].units[#Players[1].units+1]=hostile
high.enemy=true;GameEvents.UnitSetXY.Fire(1,99,high.x,high.y);assert(not s.assignments[high.n]);Pump()
high.enemy=false;GameEvents.UnitSetXY.Fire(1,99,0,0);Pump();assert(s.assignments[high.n],'departure should retry a pending selection')
-- A structurally invalid known-version payload is preserved and disabled.
local corrupt=B.Decode(B.Encode(s));corrupt.selected='wrong table shape';local badRaw=B.Encode(corrupt)
Players[0].script='|BCSTATE1:'..#badRaw..':'..badRaw..'|';B.States={};assert(B.State(0).incompatible)
B.Save(B.State(0));assert(Players[0].script:find(badRaw,1,true));B.States[0]=s
-- Future payloads remain intact; disabled state must not overwrite progress for another version.
local future=B.Decode(B.Encode(s));future.version=4;local rawFuture=B.Encode(future)
Players[0].script='|BCSTATE1:'..#rawFuture..':'..rawFuture..'|';B.States={};local blocked=B.State(0)
assert(blocked.incompatible);B.Save(blocked);assert(Players[0].script:find(rawFuture,1,true))
print('PASS mode isolation, CP specialist extras, partial native fault journal, v1 migration, extra-city workforce and future saves')
