Players[4].civ=100;Players[4].human=true
local u=NewUnit(1,0);u.promotions[102]=true;u.promotions[777]=true
local c=NewCity(10,0,false);c.free[101]=1
LoadUnrung();PeaceTurns(15);CheckCity(c,3,3)
for turn=10,14 do
 now=turn;Players[4].active=true;GameEvents.PlayerDoTurn.Fire(4)
 Players[4].active=false;GameEvents.PlayerDoneTurn.Fire(4)
end
now=15;WarWith(1,true)
Teams[4].wars[1]=true;Teams[1].wars[4]=true;Events.WarStateChanged.Fire(4,1,true)
assert(Read(4).toll==1);CheckUnit(u,3)
-- Change BOTH owner and ID. A colliding old ID in the recipient's list must not
-- be mistaken for the converted unit; only the resulting unit is reconciled.
local collision=NewUnit(1,4);collision.promotions[888]=true
GameEvents.UnitCreated.Fire(4,1)
Players[0].units[1]=nil;u.id=77;u.owner=4;Players[4].units[77]=u
GameEvents.UnitConverted.Fire(0,4,1,77,false)
CheckUnit(u,1);CheckUnit(collision,1)
assert(u:IsHasPromotion(102) and u:IsHasPromotion(777) and collision:IsHasPromotion(888))
local upgraded=NewUnit(88,4);upgraded.promotions[102]=true;upgraded.promotions[133]=true
-- v151 UnitUpgraded is BEFORE convert, which overwrites promotion membership.
-- UnitConverted is the authoritative post-copy repair, not the pre-upgrade hook.
GameEvents.UnitUpgraded.Fire(4,77,88,false);CheckUnit(upgraded,1)
upgraded.promotions[131]=nil;upgraded.promotions[133]=nil -- LostWithUpgrade
GameEvents.UnitConverted.Fire(4,4,77,88,true)
CheckUnit(upgraded,1);assert(upgraded:IsHasPromotion(102))
-- Native free copies of Belfry count, while removing the last copy removes Science.
WarWith(1,false);CheckCity(c,0,0)
PeaceTurns(5);CheckCity(c,1,1)
c.buildings[101]=1;Events.SpecificCityInfoDirty.Fire(0,10);CheckCity(c,1,1)
c.buildings[101]=nil;GameEvents.CitySoldBuilding.Fire(0,10,101);CheckCity(c,1,1)
c.free[101]=nil;Events.SpecificCityInfoDirty.Fire(0,10);CheckCity(c,1,0)
-- Same-context include does not add callbacks or perform another load sweep.
local scans=counters.cityScans;LoadUnrung();assert(counters.cityScans==scans)
for _,event in pairs(GameEvents) do assert(#event.handlers==1) end
print('PASS owner+ID conversion, old-ID collision, different active Toll strengths, upgrade retention, free/real Belfry copies and same-context include')
