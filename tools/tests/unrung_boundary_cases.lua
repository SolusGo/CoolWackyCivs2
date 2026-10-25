local u=NewUnit(1,0);LoadUnrung();PeaceTurns(15)
-- War during native turn setup, BEFORE the late PlayerDoTurn callback.
Players[0].active=true;WarWith(1,true)
assert(Read().skipBegin==now and Read().windows==0)
local raw=saves.UNRUNG_STATE_V1_0;NewContext();LoadUnrung()
assert(saves.UNRUNG_STATE_V1_0==raw)
Begin();Begin();Done();Done();assert(Read().windows==0)
now=now+1
for window=1,5 do
 Begin();Begin();assert(Read().windows==window);CheckUnit(u,3)
 if window==3 then
  WarWith(2,true);WarWith(1,false);WarWith(1,true)
  assert(Read().windows==3 and Read().toll==3)
 end
 Done();CheckUnit(u,3);now=now+1
end
-- Reload immediately before sixth start; init itself cannot expire or extend.
raw=saves.UNRUNG_STATE_V1_0;NewContext();LoadUnrung()
assert(saves.UNRUNG_STATE_V1_0==raw);CheckUnit(u,3)
Begin();CheckUnit(u,0);assert(Read().toll==0)
WarWith(1,false);WarWith(2,false);WarWith(1,true)
assert(Read().toll==0,'same-turn complete peace cannot restore consumed stacks')
print('PASS pre-DoTurn activation, duplicate begin/done, partial-turn reload, fifth interturn, sixth-start load boundary and same-window redeclaration')
