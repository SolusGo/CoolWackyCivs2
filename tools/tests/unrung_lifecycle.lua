local c=NewCity(10,0,true)
local guard=NewUnit(1,0);guard.promotions[102]=true;guard.promotions[555]=true
local worker=NewUnit(2,0,0,0);local ship=NewUnit(3,0,1);local air=NewUnit(4,0,2)
local archer=NewUnit(5,0,0,0,12)
LoadUnrung();PeaceTurns(15)
-- City ownership changes in peace remove all conditional markers, and reacquisition restores them.
Players[0].cities[10]=nil;Players[1].cities[10]=c;c.owner=1
GameEvents.CityCaptureComplete.Fire(0,false,10,0,1);CheckCity(c,0,0)
Players[1].cities[10]=nil;Players[0].cities[10]=c;c.owner=0
GameEvents.CityCaptureComplete.Fire(1,false,10,0,0);CheckCity(c,3,3)
WarWith(1,true);CheckUnit(guard,3);CheckUnit(worker,0);CheckUnit(ship,0);CheckUnit(air,0);CheckUnit(archer,3)
for i=10,12 do
 local u=NewUnit(i,0);GameEvents.UnitCreated.Fire(0,i,999,0,0);CheckUnit(u,3)
 GameEvents.CityTrained.Fire(0,10,i,false,true);CheckUnit(u,3)
end
-- Simulate native permanent retention / temporary LostWithUpgrade clearing, then conversion.
local upgraded=NewUnit(20,0);upgraded.promotions[102]=true
GameEvents.UnitConverted.Fire(0,0,1,20,true);GameEvents.UnitUpgraded.Fire(0,1,20,false)
CheckUnit(upgraded,3);assert(upgraded:IsHasPromotion(102))
Players[0].units[20]=nil;Players[1].units[20]=upgraded;upgraded.owner=1
GameEvents.UnitConverted.Fire(0,1,20,20,false);CheckUnit(upgraded,0);assert(upgraded:IsHasPromotion(102))
local capture=NewCity(30,0,true);capture.buildings[111]=1
GameEvents.CityCaptureComplete.Fire(1,false,30,0,0);CheckCity(capture,0,0)
WarWith(1,false);assert(guard:IsHasPromotion(102) and guard:IsHasPromotion(555));CheckUnit(guard,0)
-- Razing destroys its native city; no stored userdata or effects are re-applied elsewhere.
GameEvents.CityRazed.Fire(0,30,0);Players[0].cities[30]=nil;plots[30]=nil
Turn()
print('PASS cities acquired/lost/liberated/razed, trained/purchased/ranged units, domain exclusions, conversion, upgrade, permanent promotion isolation')
