local a=NewUnit(1,0);a:SetHasPromotion(102,true)
local ranged=NewUnit(2,0,5);local siege=NewUnit(3,0,6);local recon=NewUnit(4,0,7)
local ship=NewUnit(5,0);ship.domain=1
local air=NewUnit(6,0);air.domain=2
local civ=NewUnit(7,0);civ.civilian=true
local custom=NewUnit(8,0,9)
local helicopter=NewUnit(9,0,8)
local embarked=NewUnit(10,0);embarked.embarked=true
LoadUrgal();local U=MapModData.URGAL
assert(U.State(0).potions==1 and U.State(1)==nil)
for era=1,4 do
 Players[0].era=era;GameEvents.TeamSetEra.Fire(0,era,false);GameEvents.TeamSetEra.Fire(0,era,false)
end
assert(U.State(0).potions==5,'Industrial hoard is five, not capped or duplicated')
Players[0].era=7;GameEvents.PlayerDoTurn.Fire(0);assert(U.State(0).potions==8,'skipped eras are awarded once')
GameEvents.TeamSetEra.Fire(0,6,false);assert(U.State(0).potions==8,'era regression cannot repay bottles')
assert(U.Count(0)==3)
assert(U.Drink(0));assert(U.State(0).potions==7);assert(not U.Drink(0),'no stacking')
Check(a,true,true);Check(custom,true,false)
for _,u in ipairs({ranged,siege,recon,ship,air,civ,helicopter,embarked}) do Check(u,false,false) end
embarked.embarked=false;GameEvents.UnitSetXY.Fire(0,10);Check(embarked,true,false)
local recruit=NewUnit(11,0);GameEvents.UnitCreated.Fire(0,11);Check(recruit,false,false)
for turn=0,4 do now=turn;GameEvents.PlayerDoTurn.Fire(0);Check(a,true,true);assert(not U.CanDrink(0)) end
now=5;GameEvents.PlayerDoTurn.Fire(0);Check(a,false,false);assert(not U.CanDrink(0))
now=6;GameEvents.PlayerDoTurn.Fire(0);assert(not U.Drink(0),'two Aftertaste turns')
now=7;GameEvents.PlayerDoTurn.Fire(0);assert(U.Drink(0));Check(recruit,true,false)
assert(a.raw:find('UNIT_OTHER_DATA',1,true) and Players[0].raw:find('OTHER_MOD_DATA',1,true))
for name,duration in pairs({GAMESPEED_QUICK=3,GAMESPEED_STANDARD=5,GAMESPEED_EPIC=7,GAMESPEED_MARATHON=12}) do speed=name;assert(U.Duration()==duration) end
print('PASS stockpile, immediate/duplicate/skipped era awards, no cap, snapshot eligibility, exact durations and two-turn Aftertaste')
