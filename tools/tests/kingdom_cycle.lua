local k=MapModData.CKPrayer;local p=Players[0];local cap=p.cap
local templeFaith=0;for r in GameInfo.Building_YieldChanges({BuildingType='BUILDING_CK_HOUSE',YieldType='YIELD_FAITH'}) do templeFaith=templeFaith+r.Yield end
assert(k.Duration()==5 and k.states[0].stage==1 and k.states[0].grace==0)
assert(not k.states[1] and not k.states[2] and not k.states[3])
local s=TEST.pray();local oldReady=s.ready
assert(s.stage==2 and s.ready==5 and cap:bonus('YIELD_FAITH')==2 and cap:bonus('YIELD_FOOD')==1)
assert(not k.Pray(0,1,0) and not k.Pray(0,2,5),'double click')
TEST.nextTurn(4);assert(k.Active(s,'address') and cap:bonus('YIELD_FAITH')==2)
TEST.nextTurn();assert(not k.Active(s,'address') and cap:bonus('YIELD_FAITH')==0)
assert(p.faith==10 and cap.food==5,'exactly five economic ticks')
p.era=2;TEST.pray();assert(p.faith==40,'Opening Glory era starts at 1')
TEST.advance();TEST.pray()
for city in p:Cities() do assert(city:culture()==23,'actual native culture multiplier') end
local founded=TEST.city(0,3);GameEvents.PlayerCityFounded(0,3,1);assert(founded:culture()==23)
TEST.advance();assert(cap:culture()==20);TEST.pray()
assert(cap.food==29 and cap.production==24 and s.bread==0,'ASK 8 per era')
TEST.advance();TEST.pray();assert(p:happiness()==2 and p:paidPolicies()==0)
k.Sync(0,false);assert(p:happiness()==2,'happiness once across all cities')
TEST.advance();assert(p:happiness()==0);TEST.pray();assert(p:strength()==20)
assert(p.units[1]:IsHasPromotion(k.SHIELD) and not p.units[2]:IsHasPromotion(k.SHIELD))
local fresh=TEST.unit(0,GameInfoTypes.UNIT_WARRIOR,true);GameEvents.UnitCreated(0,fresh.id);assert(fresh:IsHasPromotion(k.SHIELD))
local air=TEST.unit(0,GameInfoTypes.UNIT_BOMBER,false);air.ranged=true;GameEvents.UnitCreated(0,air.id);assert(air:IsHasPromotion(k.SHIELD),'ranged-only military unit')
TEST.advance();assert(p:strength()==0 and not fresh:IsHasPromotion(k.SHIELD) and not air:IsHasPromotion(k.SHIELD))
cap.buildings[k.HOUSE]=1;founded.buildings[k.HOUSE]=1
-- Another city is merely constructing a House and must not count.
p.cities[2].buildingUnderConstruction=k.HOUSE
local before=p.faith;TEST.pray()
assert(s.stage==1 and s.grace==1 and p.gap==60 and p.faith==before+20)
assert(cap:bonus('YIELD_FAITH')==templeFaith+2 and cap:bonus('YIELD_CULTURE')==2,'Grace + House')
for cycle=2,7 do for i=1,7 do TEST.advance();TEST.pray() end;assert(s.grace==cycle) end
assert(cap:bonus('YIELD_FAITH')==templeFaith+8 and cap:bonus('YIELD_CULTURE')==8)
local gap=p.gap
for i=1,7 do TEST.advance();TEST.pray() end
assert(s.grace==7 and p.gap==gap+135,'capped cycle 20 + 25 GAP per era')
for i=1,20 do k.Sync(0,true) end
assert(cap:bonus('YIELD_CULTURE')==8,'exact assignments never duplicate Grace')
for _,pair in ipairs({{'GAMESPEED_QUICK',3},{'GAMESPEED_STANDARD',5},{'GAMESPEED_EPIC',8},{'GAMESPEED_MARATHON',15}}) do
 TEST.speed=GameInfoTypes[pair[1]];assert(k.Duration()==pair[2])
 TEST.advance();local start=TEST.turn;TEST.pray();assert(s.ready==start+pair[2])
 TEST.nextTurn(pair[2]-1);assert(not k.Pray(0,s.stage,s.ready));TEST.nextTurn();assert(k.CanPray(0))
end
local speed=GameInfo.GameSpeeds[TEST.speed];local percent=speed.TrainPercent;speed.TrainPercent=1;assert(k.Duration()==1);speed.TrainPercent=percent
assert(Players[1].faith==0 and Players[2].faith==0,'no foreign/AI rewards')
print('PASS Kingdom cycle, exact duration ticks, all yields, eras, seven Grace, excess cycles, all speeds')
