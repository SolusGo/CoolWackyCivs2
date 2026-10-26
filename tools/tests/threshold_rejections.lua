local T=Court();local p=Players[0];local snap=Snapshot(unit,origin)
local function reject()
 local gold=p.gold;local ready=T.CityState(origin)[6];local last=T.State(0)[1]
 assert(not T.Transfer(0,0,snap,119,75))
 assert(p.gold==gold and T.CityState(origin)[6]==ready and T.State(0)[1]==last)
end
for _,key in ipairs({'dead','delayed','ranged','embarked','defensive','busy'})do unit[key]=true;reject();unit[key]=false end
unit.combat=false;reject();unit.combat=true
for domain=1,2 do unit.domain=domain;reject()end;unit.domain=0
unit.kind=GameInfoTypes.UNIT_GREAT_GENERAL;reject();unit.kind=GameInfoTypes.UNIT_THRESHOLD_HINGEGUARD
unit.moves=0;reject();unit.moves=180
origin.house=0;reject();origin.house=1
destination.house=0;reject();destination.house=1
destination.owner=1;reject();destination.owner=0
local occupying=Unit(p,8,119,75);reject();p.units[8]=nil;Place(occupying,16,16)
unit.reject=true;reject();unit.reject=false
assert(not T.Transfer(0,0,snap,3,4));assert(not T.Transfer(0,0,snap,900,900))
p.active=false;reject();p.active=true
p.human=false;reject();p.human=true
p.civ=-999;reject();p.civ=T.CIV
local oldsnap=Snapshot(unit,origin)
unit.kind=GameInfoTypes.UNIT_PIKEMAN;assert(not T.Transfer(0,0,oldsnap,119,75));unit.kind=GameInfoTypes.UNIT_THRESHOLD_HINGEGUARD
-- Ownership round-trip clears a city's stale cooldown and invalidates snapshots.
local cs=T.CityState(origin);cs[6]=108;assert(T.Write(origin:Plot(),'THC_C1',cs))
local token=T.CityToken(origin)
origin.owner=1;GameEvents.CityCaptureComplete.Fire(0,false,3,4,1)
origin.owner=0;GameEvents.CityCaptureComplete.Fire(1,false,3,4,0)
assert(T.CityState(origin)[6]==0 and T.CityToken(origin)~=token)
assert(not T.Transfer(0,0,oldsnap,119,75))
-- Same coordinates, owner, ID, founding turn: founding notification changes epoch.
token=T.CityToken(origin);GameEvents.PlayerCityFounded.Fire(0,3,4);assert(token~=T.CityToken(origin))
-- Deleted city plot is rejected without retaining any city userdata.
destination:Plot().city=nil;reject();destination:Plot().city=destination
print('PASS illegal units, ownership, occupied/invalid endpoints, no slot fallback, no resource consumption, city epochs and stale snapshots')
