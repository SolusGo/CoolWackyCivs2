local messages={};local realPrint=print
print=function(message) messages[#messages+1]=message end
local p=Player(0,true);p.capital=City(p,0,true,false)
local bad=City(p,1,true,true);local good=City(p,2,true,true)
bad.blockBuilding=G
LoadConical()
Check(good,2,2,2) -- one broken city cannot starve the rest of the batch
local logged=#messages
for i=1,50 do GameEvents.PlayerDoTurn.Fire(0) end
assert(#messages==logged,'persistent failure spammed the log')
bad.blockBuilding=nil;GameEvents.PlayerDoTurn.Fire(0);Check(bad,2,2,2)
-- Failed foreign cleanup must be retried without enumerating foreign cities.
local f=Player(1,false);f.capital=City(f,0,false,false)
bad.blockBuilding=G;Transfer(bad,f)
assert(bad:GetNumRealBuilding(G)==1,'fault setup must retain the Gold marker')
local foreignLogged=#messages
for i=1,50 do GameEvents.PlayerDoTurn.Fire(1) end
assert(#messages==foreignLogged,'foreign retry reset failure diagnostics')
bad.blockBuilding=nil
local s=scans;GameEvents.PlayerDoTurn.Fire(1);assert(scans==s)
Check(bad,0,1,0)
local l=lookups;GameEvents.PlayerDoTurn.Fire(1);assert(lookups==l,'successful cleanup stayed queued')
-- Marker getters must be protected too, including the foreign eligibility read.
bad.b[G]=1;bad.blockRead=U
Events.SpecificCityInfoDirty.Fire(1,bad.id)
bad.blockRead=nil;GameEvents.PlayerDoTurn.Fire(1);Check(bad,0,1,0)
-- A different city changes during a setter: do not drop its only notification.
good.connected=false
good.onWrite=function()
  good.onWrite=nil
  bad.b[U]=1;bad.b[G]=1
  Events.SpecificCityInfoDirty.Fire(1,bad.id,0)
end
GameEvents.PlayerDoTurn.Fire(0);Check(good,0,1,0);Check(bad,0,1,0)
-- Save/load repairs deliberately persisted foreign residue, even after failed cleanup.
bad.b[U]=1;bad.b[G]=1
RecreateConical(false,false,true);Check(bad,0,1,0)
-- Destroyed queued city IDs are discarded rather than retaining dead userdata.
bad.b[U]=1;bad.blockBuilding=U;Events.SpecificCityInfoDirty.Fire(1,bad.id)
for i,v in ipairs(f.cities) do if v==bad then table.remove(f.cities,i);break end end
GameEvents.PlayerDoTurn.Fire(1)
local after=lookups;GameEvents.PlayerDoTurn.Fire(1);assert(lookups==after)
print=realPrint
print('PASS Conical per-city fault isolation, bounded diagnostics, partial-write recovery, targeted foreign retry, cross-city reentrancy and destroyed pending IDs')
