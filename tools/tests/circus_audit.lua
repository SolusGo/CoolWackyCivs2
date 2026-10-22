-- Independent source-shaped phase model. This is NOT a compiled/native DLL test.
-- Production is credited city-by-city, then treasury Gold, then player Culture;
-- PlayerDoTurn is later. Mutations can occur BETWEEN those separate harvests.
local function activate(p, afterProduction, beforeProduction)
 p.active=true;p.endTurn=false;p.autoMoves=false;p.processed=false
 if beforeProduction then beforeProduction() end
 local result={gold=0,culture=0,production=0}
 for c in p:Cities() do
  local _,_,production=Harvest(c)
  result.production=result.production+production
  c.progress=(c.progress or 0)+production
  if afterProduction then afterProduction(c) end
 end
 for c in p:Cities() do local _,gold=Harvest(c);result.gold=result.gold+gold end
 for c in p:Cities() do local culture=Harvest(c);result.culture=result.culture+culture end
 GameEvents.PlayerDoTurn.Fire(p.id)
 return result
end
local function nextRound(p) EndTurn(p);rawTurn=rawTurn+1;return activate(p) end

-- Regression: CP city doTurn can damage/kill units after doProduction (e.g.
-- doMeltdown). The festival began at owner-turn entry, BEFORE this Crew loss.
local p,c,u=Setup();EndTurn(p);rawTurn=rawTurn+1
local result=activate(p,function() Kill(u) end)
assert(result.production==2 and result.gold==2 and result.culture==4,
 'Crew loss after Production split the first festival payout')
assert(c.b[105]==rawTurn+4 and c.b[106]==rawTurn+13)
for delta=1,3 do
 local value=nextRound(p);local active=delta<3
 assert(value.gold==(active and 2 or 0),'lost/extra harvest after same-turn Crew death')
end
-- A same-turn scripted move after turn entry likewise cannot cancel a begun show.
p,c,u=Setup();EndTurn(p);rawTurn=rawTurn+1
result=activate(p,nil,function() Move(u,nil) end)
assert(result.production==2 and result.gold==2 and result.culture==4)
-- BEFORE entry, the owner is inactive, including raw rollover before a human
-- in a later player slot. Prekill/movement must still cancel the reservation.
for _,action in ipairs({'kill','move'}) do
 p,c,u=Setup();EndTurn(p);rawTurn=rawTurn+1
 if action=='kill' then Kill(u) else Move(u,nil) end
 result=activate(p)
 assert(result.production==0 and result.gold==0 and result.culture==1)
 assert(not c.b[105] and not c.b[106])
end

-- Error isolation: a persistently failing city must not starve healthy cities.
p,c,u=Setup();local c2=City(p,2,true);Unit(p,c2)
local setter=c.SetNumRealBuilding;local attempts=0
function c:SetNumRealBuilding(...) attempts=attempts+1;error('persistent city fault') end
EndTurn(p)
assert(attempts==2,'retry was not bounded per city')
rawTurn=rawTurn+1;result=activate(p)
AssertYields(c2,4,2,2)
assert(c2.b[105]==rawTurn+4 and c2.b[106]==rawTurn+13,'healthy city starved by failing peer')
c.SetNumRealBuilding=setter
-- Same failure during expiration must not leave a healthy peer's bonuses active.
p,c,u=Setup();c2=City(p,2,true);Unit(p,c2)
nextRound(p);nextRound(p);nextRound(p)
setter=c.SetNumRealBuilding;attempts=0
function c:SetNumRealBuilding(...) attempts=attempts+1;error('persistent expiry fault') end
EndTurn(p);assert(attempts==2)
rawTurn=rawTurn+1;activate(p);AssertYields(c2,1,0,0)
c.SetNumRealBuilding=setter

-- Every marker/yield write involved in staging and committing, before AND after
-- native mutation. One failed city write must recover without shifting T or T+12.
for _,phase in ipairs({'stage','commit','expire'}) do
 local targets=phase=='stage' and {107,108,103,104} or phase=='commit' and {105,106,107} or {108,103,104}
 for _,building in ipairs(targets) do
  for _,when in ipairs({'before','after'}) do
   p,c,u=Setup()
   if phase=='commit' then EndTurn(p) end
   if phase=='expire' then nextRound(p);nextRound(p);nextRound(p) end
   local native=c.SetNumRealBuilding;local fired=false
   function c:SetNumRealBuilding(b,n,noBonus)
    if b==building and not fired then
     fired=true
     if when=='after' then native(self,b,n,noBonus) end
     error('transient '..when..' mutation')
    end
    return native(self,b,n,noBonus)
   end
   if phase=='stage' or phase=='expire' then EndTurn(p) end
   rawTurn=rawTurn+1;result=activate(p)
   assert(fired,'fault target was never exercised')
   local active=phase~='expire'
   assert(result.gold==(active and 2 or 0) and result.production==(active and 2 or 0)
    and result.culture==(active and 4 or 1),'partial mutation changed economic boundaries')
   local expires,ready=c.b[105],c.b[106]
   for i=1,5 do GameEvents.PlayerDoTurn.Fire(p.id);Events.SpecificCityInfoDirty.Fire(p.id,c.id,1) end
   assert(c.b[105]==expires and c.b[106]==ready,'retry/duplicate callback reset a boundary')
  end
 end
end

-- Actual source-shaped autosave resumption, rather than an unconditional Done:
-- Read restores active/end/automove flags, processed=false. updateMoves rebuilds
-- processed; CheckPlayerTurnDeactivate requires all conditions before Done.
local function resumeDeactivate(p, mission)
 if not (p.alive and p.active and (p.endTurn or not p.human)) then return false end
 if p.autoMoves and not p.processed then
  if mission then mission() end
  if not p.busy then p.processed=true end
 end
 if not p.processed or p.busy then return false end
 EndTurn(p);return true
end
for _,delta in ipairs({-1,0,1,2,3,10,11,12}) do
 p,c,u=Setup();local initial=rawTurn
 if delta>=0 then
  nextRound(p)
  for i=1,delta do nextRound(p) end
 end
 -- This snapshot is BEFORE PlayerDoneTurn, as in the first player's autosave.
 p.endTurn=true;p.autoMoves=true;p.processed=true
 local snapshot=Save()
 EndTurn(p);rawTurn=rawTurn+1;local expected=activate(p)
 Restore(snapshot);p=Players[0];c=p.cities[1]
 assert(p.active and p.endTurn and p.autoMoves and not p.processed)
 p.busy=true;assert(not resumeDeactivate(p),'busy owner deactivated early')
 p.busy=false;assert(resumeDeactivate(p))
 assert(not resumeDeactivate(p),'inactive owner emitted another Done')
 rawTurn=rawTurn+1;local actual=activate(p)
 assert(actual.gold==expected.gold and actual.culture==expected.culture
  and actual.production==expected.production,'autosave replay altered payout at '..delta)
 assert(rawTurn==initial+delta+2)
end
-- Resumed automoves change the FINAL ended-turn position before sampling.
p,c,u=Setup();p.endTurn=true;p.autoMoves=true
local snapshot=Save();Restore(snapshot);p=Players[0];c=p.cities[1];u=p.units[1]
assert(resumeDeactivate(p,function() Move(u,nil) end))
rawTurn=rawTurn+1;result=activate(p);assert(result.gold==0)

-- Human Circus can occupy a later sequential slot; AI callbacks cannot change it.
Players={};plots={};Context();rawTurn=startTurn or 0
for id=0,2 do local ai=Player(id,false);ai.human=false;ai.active=false end
p=Player(3,true);c=City(p,1,true);u=Unit(p,c);LoadCircus()
EndTurn(p);local boundary=c.b[107]
for id=0,2 do
 GameEvents.PlayerDoTurn.Fire(id);GameEvents.PlayerDoneTurn.Fire(id)
end
assert(c.b[107]==boundary)
rawTurn=rawTurn+1
for id=0,2 do GameEvents.PlayerDoTurn.Fire(id);GameEvents.PlayerDoneTurn.Fire(id) end
assert(not p.active);result=activate(p);assert(result.gold==2 and result.production==2)

-- Pending city capture immediately before entry must not leak a first harvest.
p,c,u=Setup();EndTurn(p);Transfer(c,Players[1],'capture');Transfer(c,p,'liberation')
rawTurn=rawTurn+1;result=activate(p)
assert(result.gold==0 and result.production==0 and c.b[107]==0)
-- Gold/faith purchase hooks carry two native booleans, after building creation.
p,c,u=Setup();c.b[102]=0;nextRound(p)
for _,payment in ipairs({'gold','faith'}) do
 c.b[102]=1;GameEvents.CityConstructed.Fire(0,1,102,payment=='gold',payment=='faith')
 AssertYields(c,4,2,2)
 c.b[102]=0;Events.SpecificCityInfoDirty.Fire(0,1,1);AssertYields(c,3,2,0)
end
-- Completion/purchase/removal BEFORE Production is visible to that pass;
-- construction AFTER Production cannot retroactively increase already credited work.
p,c,u=Setup();c.b[102]=0;EndTurn(p);rawTurn=rawTurn+1
result=activate(p,nil,function()
 c.b[102]=1;GameEvents.CityConstructed.Fire(0,1,102,true,false)
end)
assert(result.production==2 and result.culture==4 and result.gold==2)
p,c,u=Setup();c.b[102]=0;EndTurn(p);rawTurn=rawTurn+1
result=activate(p,function()
 c.b[102]=1;GameEvents.CityConstructed.Fire(0,1,102,false,false)
end)
assert(result.production==0 and c.progress==0 and result.culture==4 and result.gold==2)
AssertYields(c,4,2,2)
p,c,u=Setup();EndTurn(p);rawTurn=rawTurn+1
result=activate(p,nil,function() c.b[102]=0;Events.SpecificCityInfoDirty.Fire(0,1,1) end)
assert(result.production==0 and result.culture==3 and result.gold==2)
-- Same unit ID under another owner must not exclude our remaining Crew.
p,c,u=Setup();local second=Unit(p,c);EndTurn(p)
GameEvents.UnitPrekill.Fire(1,second.id,101,0,0,true,0)
Kill(u);rawTurn=rawTurn+1;result=activate(p);assert(result.gold==2)

-- Delayed death is observable BEFORE sampling; recaptured own Crews retain
-- original identity, whereas native-converted foreign Workers never qualify.
p,c,u=Setup();u.delayed=true;EndTurn(p);rawTurn=rawTurn+1
result=activate(p);assert(result.gold==0)
p,c,u=Setup();u.original=1;EndTurn(p);rawTurn=rawTurn+1
result=activate(p);assert(result.gold==0)
u.original=0;nextRound(p);AssertYields(c,4,2,2)
-- Reload AFTER departure/death keeps an established festival, including its
-- exact old v9 marker format; no migration/reset or additional state is required.
for _,action in ipairs({'move','kill'}) do
 p,c,u=Setup();nextRound(p)
 local expires,ready=c.b[105],c.b[106]
 if action=='move' then Move(u,nil) else Kill(u) end
 local snapshot=Save();Restore(snapshot);p=Players[0];c=p.cities[1]
 assert(c.b[105]==expires and c.b[106]==ready);AssertYields(c,4,2,2)
 nextRound(p);AssertYields(c,4,2,2)
 nextRound(p);AssertYields(c,4,2,2)
 nextRound(p);AssertYields(c,1,0,0)
end
-- Old-format pending counts on owner entry can be committed on context load.
p,c,u=Setup();EndTurn(p);rawTurn=rawTurn+1;p.active=true
local legacy=Save();Restore(legacy);p=Players[0];c=p.cities[1]
assert(c.b[105]==rawTurn+4 and c.b[106]==rawTurn+13 and c.b[107]==0)
AssertYields(c,4,2,2)

-- No idle polling; 128 cities, simultaneous shows, per-city absolute boundaries,
-- and a 2,000-event storm. Only changed dummy counts may be written.
p,c,u=Setup()
for id=2,128 do local city=City(p,id,true);Unit(p,city) end
nextRound(p);local writes=0
for city in p:Cities() do writes=writes+city.writes end
for i=1,1000 do Events.SerialEventGameDataDirty.Fire();Events.SerialEventCityInfoDirty.Fire() end
Flush();local after=0
for city in p:Cities() do after=after+city.writes;AssertYields(city,4,2,2) end
assert(after==writes and not ContextPtr.callback)
assert(GameEvents.PlayerDoTurn.Count()==1 and Events.SpecificCityInfoDirty.Count()==1)
print('PASS Circus audit: split economic phases, owner entry vs interturn, isolated faults, gated autosave replay/automoves, later human slot, purchases/capture, unit identity and 128-city storms')
