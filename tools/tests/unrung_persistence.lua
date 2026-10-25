-- Models the documented save-container contract, not native save-file loading.
local city=NewCity(10,0,true);local unit=NewUnit(1,0)
local gameA=saves
LoadUnrung();PeaceTurns(4)
local slot4=saves.UNRUNG_STATE_V1_0;Turn()
local slot5=saves.UNRUNG_STATE_V1_0;PeaceTurns(10)
local slot15=saves.UNRUNG_STATE_V1_0
CheckCity(city,3,3)
-- Same player ID in a new game must see an independent container. Deliberately
-- retain shared MapModData/event surfaces to stress context ownership retirement.
saves={};now=0;NewContext();LoadUnrung()
assert(Read().peace==0);CheckCity(city,0,0);CheckUnit(unit,0)
PeaceTurns(5);local gameB=saves;assert(Read().peace==5)
assert(gameA.UNRUNG_STATE_V1_0==slot15,'new game cannot write game A')
-- Distinct slots and rollback restore the selected snapshot, never newest state.
saves={UNRUNG_STATE_V1_0=slot4};now=4;NewContext();LoadUnrung()
assert(Read().peace==4);CheckCity(city,0,0);Turn();assert(Read().peace==5)
saves={UNRUNG_STATE_V1_0=slot5};now=5;NewContext();LoadUnrung()
assert(Read().peace==5);CheckCity(city,1,1)
saves=gameA;now=15;NewContext();LoadUnrung();assert(Read().peace==15)
WarWith(1,true);local partial=saves.UNRUNG_STATE_V1_0
Begin();Done();now=now+1;Begin();Done();now=now+1
local later=saves.UNRUNG_STATE_V1_0;assert(Read().windows==2)
-- Reload the earlier off-turn activation snapshot; reconcile saved promotions.
saves={UNRUNG_STATE_V1_0=partial};now=15;NewContext();LoadUnrung()
assert(Read().windows==0);CheckUnit(unit,3)
Begin();assert(Read().windows==1)
saves={UNRUNG_STATE_V1_0=later};now=16;NewContext();LoadUnrung()
assert(Read().windows==2);GameEvents.PlayerDoTurn.Fire(0);assert(Read().windows==2)
WarWith(1,false)
saves=gameB;now=5;NewContext();LoadUnrung();assert(Read().peace==5)
-- Preserve malformed/unknown data and fail closed, including non-finite parse
-- and double precision overflow in EVERY numeric position.
local valid={'1','15','0','0','0','14','14','-1','-1'}
local cases={'2|future','1|15|0|0|0|-1|-1|-1','1|15|0|0|0|-1|-1|-1|-1|extra'}
for position=2,9 do
 for _,bad in ipairs({string.rep('9',400),'9007199254740993'}) do
  local v={};for i,n in ipairs(valid) do v[i]=n end;v[position]=bad
  cases[#cases+1]=table.concat(v,'|')
 end
end
for _,raw in ipairs(cases) do
 saves={UNRUNG_STATE_V1_0=raw};NewContext();LoadUnrung()
 assert(saves.UNRUNG_STATE_V1_0==raw,'invalid record overwritten')
 CheckCity(city,0,0);CheckUnit(unit,0)
end
print('PASS independent games/slots, earlier/later save rollback, partial Toll restore, finite integer validation and unknown/corrupt preservation (modeled containers)')
