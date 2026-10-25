local a=NewUnit(1,0);a:SetHasPromotion(102,true)
LoadUrgal();local U=MapModData.URGAL;assert(U.Drink(0))
now=2
local before=Players[0].raw;local unitData=a.raw;local oldContext=ContextPtr
NewContext();LoadUrgal();U=MapModData.URGAL
assert(Players[0].raw==before and a.raw==unitData,'reload neither grants bottles nor extends duration')
oldContext.shutdown();assert(U.active,'retired context cannot shut down the new owner')
assert(#GameEvents.PlayerDoTurn.handlers==1,'one simulation owner')
Check(a,true,true)
a=Convert(a,0,2,true,3);Check(a,true,true);assert(a:IsHasPromotion(102),'permanent Pot Chaser copied by native upgrade')
local civilianUpgrade=Convert(a,0,3,true,5);Check(civilianUpgrade,false,false)
local b=NewUnit(4,0);b:SetHasPromotion(102,true)
-- A newly produced Rusher has Pot Chaser but cannot join the current window.
GameEvents.UnitCreated.Fire(0,4);Check(b,false,false)
now=7;Players[0].era=1;GameEvents.TeamSetEra.Fire(0,1,false);assert(U.Drink(0));Check(b,true,true)
b.embarked=true;GameEvents.UnitSetXY.Fire(0,4);Check(b,false,false)
b.embarked=false;GameEvents.UnitSetXY.Fire(0,4);Check(b,true,true)
local gifted=Convert(b,1,5,false);Check(gifted,false,false)
gifted=Convert(gifted,0,6,false);Check(gifted,false,false)
-- ID reuse cannot restore the marker from a dead snapshot participant.
local reused=NewUnit(4,0);GameEvents.UnitCreated.Fire(0,4);Check(reused,false,false)
now=20;NewContext();LoadUrgal();Check(reused,false,false);Check(gifted,false,false)
assert(MapModData.URGAL.State(0).potions==0)
Players[0].raw='OTHER_MOD_DATA[URGAL_P1:999999999999999999999999999:1:0:0:0]'
assert(MapModData.URGAL.State(0)==nil,'corrupt overflow must not mint a giant inventory')
assert(not MapModData.URGAL.Drink(0))
-- A second Urgal has an independent stockpile and advanced-start baseline.
Players[2].civ=100;Players[2].era=4;NewUnit(1,2)
assert(MapModData.URGAL.State(2).potions==1)
Players[2].era=5;GameEvents.TeamSetEra.Fire(2,5,false)
assert(MapModData.URGAL.State(2).potions==2)
print('PASS reload/context retirement, upgrades, excluded upgrades, new Rushers, embark/disembark, gifts, ID reuse, corrupt data and independent players')
