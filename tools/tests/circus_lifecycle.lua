local p,c,u=Setup();c.b[102]=0;EndTurn(p);BeginTurn(p);AssertYields(c,3,2,0)
c.b[102]=1;GameEvents.CityConstructed.Fire(0,1,102,false,false);AssertYields(c,4,2,2)
c.b[102]=0;GameEvents.CitySoldBuilding.Fire(0,1,102);AssertYields(c,3,2,0)
c.b[102]=1;Events.SerialEventGameDataDirty.Fire();Flush();AssertYields(c,4,2,2)
-- Scripted removal dirty fallback cannot initiate or extend a festival.
c.b[102]=0;Events.SerialEventCityInfoDirty.Fire();Flush();AssertYields(c,3,2,0)
assert(c.b[105]==rawTurn+4)
c.b[102]=1;Events.SpecificCityInfoDirty.Fire(0,1,1);AssertYields(c,4,2,2)
c.b[102]=0;Events.SpecificCityInfoDirty.Fire(0,1,1);AssertYields(c,3,2,0)
Events.SpecificCityInfoDirty.Fire(0,777,1)
for _,kind in ipairs({'capture','gift','liberation','scripted AcquireCity'}) do
 p,c,u=Setup();EndTurn(p);BeginTurn(p)
 local foreign=Players[1];Transfer(c,foreign,kind)
 for b=103,108 do assert(c.b[b]==0,'transferred state '..kind) end
 Transfer(c,p,'liberation');AssertYields(c,1,0,0)
 -- Returning the city is insufficient without a future ended turn.
 GameEvents.PlayerDoTurn.Fire(0);AssertYields(c,1,0,0)
 EndTurn(p);BeginTurn(p);AssertYields(c,4,2,2)
end
-- Razing/deletion frees the city's state; no cached City userdata is touched.
p,c,u=Setup();EndTurn(p);BeginTurn(p)
p.cities[c.id]=nil;PlotOf(c).city=nil;c.deleted=true
GameEvents.PlayerDoTurn.Fire(0);Events.SerialEventGameDataDirty.Fire();Flush()
EndTurn(p);BeginTurn(p)
-- Elimination, invalid IDs, missing cities and a no-Circus game.
p,c,u=Setup();EndTurn(p);BeginTurn(p);p.alive=false
GameEvents.PlayerDoTurn.Fire(0);for b=103,108 do assert(c.b[b]==0) end
for _,id in ipairs({-1,77}) do
 GameEvents.PlayerDoTurn.Fire(id);GameEvents.PlayerDoneTurn.Fire(id)
 GameEvents.CityConstructed.Fire(id,66,102);GameEvents.UnitSetXY.Fire(id,777)
end
GameEvents.CityCaptureComplete.Fire(0,false,999,999,1)
Players={};plots={};Player(0,false);Context();LoadCircus()
Events.SerialEventGameDataDirty.Fire();assert(not ContextPtr.callback)
-- A native setter mutates then throws: bounded retry completes before economics.
p,c,u=Setup();faults.setter=true;EndTurn(p);BeginTurn(p);AssertYields(c,4,2,2)
p,c,u=Setup();EndTurn(p);faults.setter=true;BeginTurn(p);AssertYields(c,4,2,2)
assert(c.b[105]==rawTurn+4 and c.b[106]==rawTurn+13)
print('PASS Circus lifecycle: Office construction/sale/script removal, all transfer paths, destruction, elimination, invalid references and mutation faults')
