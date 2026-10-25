local J=MapModData.JIN
Complete('GREAT_PASTURE');Complete('DRAGON_PAVILION');Complete('GREAT_WALL_BASTION')
assert(J.Tier(J.State(0))==3 and not Action('LANDMARK','PAGODA_FOREST'))
local opportunity=J.State(0).pending[3];assert(opportunity and #opportunity.sites==3)
local raw=Players[0].raw;LoadJin();J=MapModData.JIN;assert(J.State(0).pending[3].sites[1]==opportunity.sites[1])
-- Bootstrap replaces event owners, never accumulates handlers.
local handlers=#GameEvents.PlayerDoTurn.handlers;for i=1,10 do LoadJin()end;J=MapModData.JIN;assert(#GameEvents.PlayerDoTurn.handlers==handlers)
-- Native captures remove local Jin economic dummies; original completed choices persist.
local foreign=Players[1];Players[0].cities={};foreign.cities={cap};cap.owner=1;cap:Plot().owner=1
GameEvents.CityCaptureComplete.Fire(0,true,cap.x,cap.y,1,false)
assert(cap:GetNumBuilding(J.Building('TRIBUTE'))==0 and cap:GetNumBuilding(J.Building('PAVILION_DISCOUNT'))==0)
assert(J.State(0).landmarks.GREAT_PASTURE and J.State(0).choices[3]=='GREAT_WALL_BASTION')
Players[0].alive=false;assert(J.State(0)==nil)
-- A new match at this same turn starts with no Horses/choices; MapModData has no authoritative cache.
Players[0].alive=true;Players[0].raw='';local newcap=City(0,6,6);LoadJin();J=MapModData.JIN
assert(J.Tier(J.State(0))==0 and J.Horses(0,J.State(0))==0)
Players[0].raw='[JIN_P1:bad]';assert(J.State(0)==nil,'corrupt state silently reset')
-- Entirely absent Jin: event dispatch leaves unrelated units/yields and object data untouched.
Players[0].civ=-1;Players[0].raw='unrelated';LoadJin();J=MapModData.JIN
local other=Spawn('UNIT_WARRIOR',2,2,1);local before=other.raw
GameEvents.PlayerDoTurn.Fire(1);GameEvents.UnitSetXY.Fire(1,other.id,2,2)
assert(other.damage==0 and other.raw==before and Players[0].raw=='unrelated')
assert(GameEvents.CityCanTrain.Fire(1,1,GameInfoTypes.UNIT_WORKER))
print('PASS Jin lifecycle: all six paths across scenarios, pending offers, context ownership, capture/elimination, corrupt state and absent-civ isolation')
