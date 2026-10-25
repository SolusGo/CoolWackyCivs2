local a,b=NewCity(10,0,true),NewCity(11,0,false)
LoadUnrung()
for turn=1,25 do
 Turn()
 local n=math.min(3,math.floor(turn/5))
 assert(Read().peace==turn);CheckCity(a,n,n);CheckCity(b,n,0)
end
local writes=counters.cityWrites
local raw=saves.UNRUNG_STATE_V1_0;NewContext();LoadUnrung()
assert(saves.UNRUNG_STATE_V1_0==raw,'maximum Quietude survives context reconstruction')
Events.LoadScreenClose.Fire();Events.SequenceGameInitComplete.Fire()
assert(counters.cityWrites==writes,'load reconciliation is idempotent')
local fresh=NewCity(12,0,true);GameEvents.PlayerCityFounded.Fire(0,12,0);CheckCity(fresh,3,3)
fresh.buildings[101]=nil;Events.SpecificCityInfoDirty.Fire(0,12);CheckCity(fresh,3,0)
fresh.buildings[101]=1;GameEvents.CityConstructed.Fire(0,12,101,false,false);CheckCity(fresh,3,3)
fresh.buildings[101]=nil;GameEvents.CitySoldBuilding.Fire(0,12,101);CheckCity(fresh,3,0)
-- A Temple alone has no Belfry type ID and no Science.
b.buildings[999]=1;Events.SpecificCityInfoDirty.Fire(0,11);CheckCity(b,3,0)
-- Duplicate callbacks never award another owner turn.
now=24;Begin();Done();assert(Read().peace==25)
-- Barbarian war notifications do not interrupt or consume.
WarWith(3,true);assert(Read().war==0 and Read().peace==25)
print('PASS Quietude 0/4/5/10/15/25, six binary yields, Belfry lifecycle, duplicate turns, barbarians')
