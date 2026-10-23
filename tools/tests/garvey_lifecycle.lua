local G=Reload();local start=turn
assert(G.State(0).ready==start+12 and not G.CanRoll(0))
assert(not G.State(1) and not G.State(2))
for t=start+1,start+11 do Tick(t);assert(not G.CanRoll(0)) end
Tick(start+12);assert(G.CanRoll(0));Tick(start+15);assert(G.CanRoll(0),'pending Roll Call was discarded')
local ready=G.State(0).ready
assert(G.Roll(0,1,ready));assert(randomCalls==1 and G.State(0).insub==1)
assert(not G.Roll(0,1,ready) and randomCalls==1,'duplicate click rerolled')
local a=GameInfoTypes.BUILDING_GARVEY_AARON
assert(city:GetNumBuilding(a)==1)
local ticks=0
for t=start+16,start+23 do
 assert(city:GetNumBuilding(a)==1,'bonus removed before final native harvest');ticks=ticks+1
 Tick(t);G=Reload()
 assert(city:GetNumBuilding(a)==(t<start+23 and 1 or 0))
end
assert(ticks==8 and G.State(0).insub==1)
Tick(start+27);assert(G.Roll(0,2,G.State(0).ready));assert(G.State(0).insub==2)
Tick(start+39);assert(G.Roll(0,4,G.State(0).ready));assert(G.State(0).insub==0)
assert(G.Active(G.State(0),'detEnd'))
assert(hall:IsHasPromotion(G.promotions.BLAKE) and hall:IsHasPromotion(G.promotions.DETENTION) and hall:IsHasPromotion(G.promotions.HALL_DETENTION))
assert(not civilian:IsHasPromotion(G.promotions.DETENTION))
local full=GameInfoTypes.POLICY_GARVEY_PENALTY_FULL;local relief=GameInfoTypes.POLICY_GARVEY_PENALTY_RELIEF
assert(p:HasPolicy(full) and not p:HasPolicy(relief))
city.buildings[G.OFFICE]=1;GameEvents.CityConstructed(0,1,G.OFFICE)
assert(not p:HasPolicy(full) and p:HasPolicy(relief))
local officeScience=GameInfoTypes.BUILDING_GARVEY_OFFICE_SCIENCE
assert(city:GetNumBuilding(officeScience)==1)
local extra=NewCity(p,2,true);GameEvents.PlayerCityFounded(0,4,5)
assert(p:HasPolicy(relief) and not p:HasPolicy(full))
city.buildings[G.OFFICE]=0;GameEvents.CitySoldBuilding(0,1,G.OFFICE)
assert(city:GetNumBuilding(officeScience)==0 and p:HasPolicy(relief))
extra.buildings[G.OFFICE]=0;GameEvents.CitySoldBuilding(0,2,G.OFFICE)
assert(p:HasPolicy(full) and not p:HasPolicy(relief))
local purchased=NewUnit(p,20,-3);GameEvents.UnitCreated(0,20)
assert(purchased:IsHasPromotion(G.promotions.DETENTION))
local upgraded=NewUnit(p,21,-4);GameEvents.UnitConverted(0,0,hall.id,upgraded.id,true)
assert(upgraded:IsHasPromotion(G.promotions.DETENTION) and not upgraded:IsHasPromotion(G.promotions.HALL_DETENTION))
for t=start+40,start+44 do
 assert(city:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_DETENTION)==1)
 Tick(t);G=Reload()
end
assert(not G.Active(G.State(0),'detEnd') and not p:HasPolicy(full) and not p:HasPolicy(relief))
for _,u in ipairs(p.units) do assert(not u:IsHasPromotion(G.promotions.DETENTION) and not u:IsHasPromotion(G.promotions.HALL_DETENTION)) end
assert(hall:IsHasPromotion(G.promotions.BLAKE),'Roll Call expired with Detention')
Tick(start+47);assert(not hall:IsHasPromotion(G.promotions.BLAKE))
Tick(start+51);local before=randomCalls;assert(G.Roll(0,5,G.State(0).ready));assert(randomCalls==before and G.State(0).insub==0)
assert(city:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_TIMOTHY)==1)
G=Reload();assert(G.Student(G.State(0))==5)
-- Remove all classroom modifiers after a nonconquest foreign transfer.
p.cities={extra};foreign.cities={city};city.owner=2
GameEvents.CityCaptureComplete(0,true,4,5,2)
for _,n in ipairs(G.dummies) do assert(city:GetNumBuilding(GameInfoTypes['BUILDING_GARVEY_'..n])==0) end
-- Corrupted/newer states fail closed and strip modifiers, rather than rerolling.
Store['GARVEY:v1:state:0']='99|broken';G=Reload();assert(not G.State(0))
for _,n in ipairs(G.dummies) do assert(extra:GetNumBuilding(GameInfoTypes['BUILDING_GARVEY_'..n])==0) end
