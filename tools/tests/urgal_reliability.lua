local a=NewUnit(1,0);a.embarked=true
LoadUrgal();local U=MapModData.URGAL
assert(U.Count(0)==0 and not U.CanDrink(0) and not U.Drink(0))
assert(U.State(0).potions==1 and not a.raw:find('URGAL_U1',1,true))
local b=NewUnit(2,0);assert(U.Count(0)==1)
assert(U.Drink(0));local finish=U.State(0).finish
Check(a,false,false);Check(b,true,false)
assert(Players[0].notices[#Players[0].notices]:find('1 units benefit immediately; 1 existing embarked',1,true))
GameEvents.UnitCreated.Fire(0,2);Check(b,true,false)
now=2;a.embarked=false;GameEvents.UnitSetXY.Fire(0,1);Check(a,true,false)
assert(U.State(0).finish==finish)
b.failPromo=true;now=5;GameEvents.PlayerDoTurn.Fire(0);Check(a,false,false)
b.failPromo=false;GameEvents.PlayerDoTurn.Fire(0);Check(b,false,false)
Players[0].failNotice=true;Players[0].era=1;GameEvents.TeamSetEra.Fire(0,1,false)
assert(U.State(0).potions==1,'notification failures cannot block bookkeeping')
now=7
local native=Players[0].SetScriptData;local reentered
Players[0].SetScriptData=function(self,raw)
 if not reentered then reentered=true;assert(not U.Drink(0),'reentrant spend rejected before persistence') end
 native(self,raw)
end
assert(U.Drink(0) and U.State(0).potions==0 and U.State(0).finish==12)
Players[0].SetScriptData=native;Players[0].failNotice=false
Players[2].civ=100;Players[2].human=true;local other=NewUnit(1,2)
assert(U.State(2).potions==1 and U.Drink(2));Check(other,true,false)
local raw2=Players[2].raw
Players[0].era=2;GameEvents.TeamSetEra.Fire(0,2,false)
assert(U.State(0).potions==1 and Players[2].raw==raw2)
local huge=U.State(2);huge.potions=1234567890123456;U.Save(2,huge)
assert(U.State(2).potions==1234567890123456,'large valid inventories round-trip without scientific notation')
for _,raw in ipairs({'OTHER[URGAL_P1:0:2:','OTHER[URGAL_P2:0:2:0:0:0]','[URGAL_P1:0:0:0:0:0][URGAL_P1:8:0:0:0:0]'}) do
 Players[0].raw=raw;assert(U.State(0)==nil and not U.Drink(0));assert(Players[0].raw==raw)
end
print('PASS embarked-only rejection, mixed feedback, duplicate creation, setter retries, notification faults, reentrant clicks, independent players and corrupt/future records')
