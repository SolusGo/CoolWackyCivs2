local c=NewCity(10,0,true);local u=NewUnit(1,0)
LoadUnrung()
for stacks=0,3 do
 PeaceTurns(stacks*5)
 WarWith(stacks%2==0 and 1 or 2,true,stacks%2==0)
 local enemy=stacks%2==0 and 1 or 2
 assert(Read().toll==stacks and Read().war==1 and Read().peace==0)
 CheckCity(c,0,0);CheckUnit(u,stacks)
 local extra=enemy==1 and 2 or 1
 WarWith(extra,true);assert(Read().toll==stacks and Read().windows==0)
 WarWith(enemy,false);assert(Read().war==1)
 WarWith(extra,false,true);assert(Read().war==0 and Read().toll==0);CheckUnit(u,0)
end
-- Declaration and peace in the same owner turn cannot award a peaceful turn.
PeaceTurns(15);Begin();WarWith(1,true);WarWith(1,false);Done()
assert(Read().peace==0);CheckCity(c,0,0)
now=now+1;Turn();assert(Read().peace==1)
-- A short peace with zero Quietude does not manufacture a new Toll.
WarWith(2,true,true);assert(Read().toll==0);CheckUnit(u,0)
print('PASS strengths 0/1/2/3, both declaration directions, city-states, half-updated teams, cascades, immediate peace')
