local p,c,u=Setup()
local base=rawTurn;AssertYields(c,1,0,0)
-- Mid-turn entry/dirty/turn refresh NEVER initiates a festival.
GameEvents.PlayerDoTurn.Fire(0);Events.SerialEventGameDataDirty.Fire();Flush();AssertYields(c,1,0,0)
EndTurn(p)
local first=base+1
assert(c.b[107]==first+1 and not c.b[105],'pending must not spend the cooldown')
local harvest=BeginTurn(p);assert(harvest[1][1]==4 and harvest[1][2]==2 and harvest[1][3]==2)
assert(c.b[105]==first+4 and c.b[106]==first+13 and c.b[107]==0)
-- Duplicate turn and refresh events cannot alter either absolute boundary.
local writes=c.writes
for i=1,25 do GameEvents.PlayerDoTurn.Fire(0);Events.SerialEventGameDataDirty.Fire() end
Flush();assert(c.writes==writes)
-- Three harvests at T,T+1,T+2; none T+3..T+11; T+12 exactly.
for delta=1,25 do
 EndTurn(p);EndTurn(p)
 local result=BeginTurn(p)[1]
 local active=delta%12<3
 assert(result[1]==(active and 4 or 1) and result[2]==(active and 2 or 0)
  and result[3]==(active and 2 or 0),'incorrect pre-PlayerDoTurn harvest '..delta)
 AssertYields(c,active and 4 or 1,active and 2 or 0,active and 2 or 0)
end
assert(GameEvents.PlayerDoneTurn.Count()==1 and GameEvents.UnitSetXY.Count()==1)
-- Multiple crews and departing crew: no stacking, no early termination.
p,c,u=Setup();Unit(p,c);EndTurn(p);BeginTurn(p);Move(u,nil)
AssertYields(c,4,2,2)
for unit in pairs(p.units) do Move(p.units[unit],nil) end
EndTurn(p);BeginTurn(p);AssertYields(c,4,2,2)
EndTurn(p);BeginTurn(p);AssertYields(c,4,2,2)
EndTurn(p);BeginTurn(p);AssertYields(c,1,0,0)
-- Visit a second city; local timers remain independent and capital is eligible.
p,c,u=Setup();local c2=City(p,2,false)
EndTurn(p);BeginTurn(p);Move(u,c2);EndTurn(p);BeginTurn(p)
AssertYields(c,4,2,2);AssertYields(c2,3,2,0);assert(c.b[106]+1==c2.b[106])
-- Passing through, ordinary Worker, foreign Worker converted by native capture.
p,c,u=Setup();Move(u,nil);local ordinary=Unit(p,c,1);local foreign=Unit(p,c,101,1)
EndTurn(p);BeginTurn(p);AssertYields(c,1,0,0)
Move(u,c);Move(u,nil);EndTurn(p);BeginTurn(p);AssertYields(c,1,0,0)
-- Never allow a staged Crew death/relocation to produce a first payout.
for _,action in ipairs({'death','move'}) do
 p,c,u=Setup();EndTurn(p)
 if action=='death' then Kill(u) else Move(u,nil) end
 assert(c.b[107]==0);AssertYields(c,1,0,0)
 BeginTurn(p);assert(not c.b[105] and not c.b[106]);AssertYields(c,1,0,0)
end
-- A second Crew keeps a pending festival valid when the first dies.
p,c,u=Setup();Unit(p,c);EndTurn(p);Kill(u);BeginTurn(p);AssertYields(c,4,2,2)
-- Capturing the Crew AFTER activation does not interrupt a committed festival.
p,c,u=Setup();EndTurn(p);BeginTurn(p);Kill(u);AssertYields(c,4,2,2)
-- All mandatory numerical examples, including six simultaneous festivals.
p,c,u=Setup();Move(u,nil);c.b[102]=0;AssertYields(c,0,0,0)
for id=1,6 do
 local city=p.cities[id] or City(p,id,true);city.b[102]=1;Unit(p,city)
end
EndTurn(p);BeginTurn(p)
local culture,gold,prod=0,0,0
for city in p:Cities() do local a,b,d=Harvest(city);culture=culture+a;gold=gold+b;prod=prod+d end
assert(culture==24 and gold==12 and prod==12)
-- Two Offices: +6 UA Culture, +2 Office Culture, +4 Gold, +4 Production.
local a,b,d=Harvest(p.cities[1]);local e,f,g=Harvest(p.cities[2])
assert(a+e==8 and b+f==4 and d+g==4)
-- A large city's dirty storm coalesces to one bounded refresh without writes.
for id=7,100 do City(p,id,false) end
local writes=c.writes
for i=1,1000 do Events.SerialEventGameDataDirty.Fire();Events.SerialEventCityInfoDirty.Fire() end
Flush();assert(c.writes==writes and not ContextPtr.callback)
print('PASS Circus timing: exact pre-harvest T..T+2 and T+12, no stacking, independent cities, crew travel/capture/origin, six-city totals')
