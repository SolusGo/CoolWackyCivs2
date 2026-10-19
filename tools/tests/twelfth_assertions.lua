local p=NewPlayer(0,true);p.active=true
local a=NewCity(p,0,true);local b=NewCity(p,1,false)
local foreign=NewPlayer(1,false);local f=NewCity(foreign,0,true)
f.buildings[101]=1;f.buildings[102]=1
LoadTwelfth();AssertBonus(a,0,0);AssertBonus(b,0,0);AssertBonus(f,0,0)
local lastProduction=0
for played=1,24 do
 assert(rawTurn==startTurn+played-1)
 local chime=played%6==0
 -- Economics runs BEFORE PlayerDoTurn. This catches a naive late toggle.
 AssertBonus(a,chime and 1 or 0,chime and 1 or 0)
 AssertBonus(b,chime and 1 or 0,0)
 local production,science=Harvest(a)
 assert(production==(chime and 38.5 or 20),'wrong construction settlement')
 assert(science==(chime and 45 or 30),'wrong research settlement')
 a.progress=a.progress+production
 assert(a.progress-lastProduction==production);lastProduction=a.progress
 GameEvents.PlayerDoTurn.Fire(0)
 assert(p.notices==math.floor(played/6))
 -- A normal active-turn save/load retains the same effects and notice ledger.
 ResetContext();LoadTwelfth();Events.LoadScreenClose.Fire();Flush()
 AssertBonus(a,chime and 1 or 0,chime and 1 or 0)
 assert(p.notices==math.floor(played/6),'replayed notification after load')
 local writes=a.writes+b.writes
 for i=1,50 do Events.SerialEventGameDataDirty.Fire() end
 Flush();assert(a.writes+b.writes==writes,'redundant dirty writes')
 GameEvents.PlayerDoneTurn.Fire(0);p.active=false
 local nextChime=(played+1)%6==0
 AssertBonus(a,nextChime and 1 or 0,nextChime and 1 or 0)
 -- Reload while other civilizations act: keep next-turn preparation.
 ResetContext();LoadTwelfth();Events.LoadScreenClose.Fire();Flush()
 AssertBonus(a,nextChime and 1 or 0,nextChime and 1 or 0)
 assert(p.notices==math.floor(played/6),'interturn notification')
 rawTurn=rawTurn+1;p.active=true
end

-- Founding, conquest, gifting, liberation, same local ID under different owners.
rawTurn=startTurn+29 -- sixth Chime; existing stale phase marker must be ignored
GameEvents.PlayerDoTurn.Fire(0)
local founded=NewCity(p,2,false);GameEvents.PlayerCityFounded.Fire(0,4,4)
AssertBonus(founded,1,0)
founded.buildings[103]=1;GameEvents.CityConstructed.Fire(0,2,103)
AssertBonus(founded,1,1)
-- Sale notification BEFORE removal, then dirty fallback AFTER removal.
GameEvents.CitySoldBuilding.Fire(0,2,103);founded.buildings[103]=0;Flush()
AssertBonus(founded,1,0)
founded.buildings[103]=1;Events.SerialEventGameDataDirty.Fire();Flush();AssertBonus(founded,1,1)
p.cities[2]=nil;foreign.cities[2]=founded;founded.owner=1
GameEvents.CityCaptureComplete.Fire(0,true,4,4,1,4,false)
AssertBonus(founded,0,0)
foreign.cities[2]=nil;p.cities[2]=founded;founded.owner=0
GameEvents.CityCaptureComplete.Fire(1,false,4,4,0,4,true)
AssertBonus(founded,1,1)
local acquired=NewCity(foreign,3,false)
foreign.cities[3]=nil;p.cities[3]=acquired;acquired.owner=0
GameEvents.CityCaptureComplete.Fire(1,false,7,7,0,3,false);AssertBonus(acquired,1,0)
-- Scripted destruction of a Clocktower, dead players, zero cities, invalid IDs.
a.buildings[103]=0;Events.SerialEventGameDataDirty.Fire();Flush();AssertBonus(a,1,0)
p.alive=false;GameEvents.PlayerDoTurn.Fire(0);AssertBonus(a,0,0)
p.alive=true;GameEvents.PlayerDoTurn.Fire(0);AssertBonus(a,1,0)
GameEvents.PlayerDoTurn.Fire(-1);GameEvents.PlayerDoneTurn.Fire(99)
GameEvents.PlayerCityFounded.Fire(99);GameEvents.CityCaptureComplete.Fire(-1,false,0,0,99)
NewPlayer(2,true);GameEvents.PlayerDoneTurn.Fire(2)
local odd=NewPlayer(3,true);odd.human=false;local oddCity=NewCity(odd,0,true)
GameEvents.PlayerDoTurn.Fire(3);AssertBonus(oddCity,1,1);assert(odd.notices==0)
-- Capital/era changes have no input into this clock. Large jumps use saved turns.
rawTurn=startTurn+30;GameEvents.PlayerDoTurn.Fire(0);AssertBonus(a,0,0)
rawTurn=startTurn+101;GameEvents.PlayerDoTurn.Fire(0);AssertBonus(a,1,0)
rawTurn=startTurn+102;GameEvents.PlayerDoTurn.Fire(0);AssertBonus(a,0,0)
Flush();assert(ContextPtr.callback==nil)
print('PASS Twelfth mocked Lua: 24 pre-hook harvests, active/interturn loads, notifications, founding/capture, building lifecycle, dirty storms, invalid/dead/unusual players')
