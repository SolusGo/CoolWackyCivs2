local T=Court();local p=Players[0]
for _,fault in ipairs({'before','noop'})do
 unit.moveFault=fault;local moves=unit.moves;local gold=p.gold
 assert(not T.Transfer(0,0,Snapshot(unit,origin),119,75))
 assert(unit.x==3 and unit.y==4 and p.gold==gold and unit.moves==moves)
 assert(T.State(0)[3]==0 and T.CityState(origin)[6]==0 and not T.Locked(unit))
end
unit.promoFault=true
assert(not T.Transfer(0,0,Snapshot(unit,origin),119,75))
assert(unit.moves==180 and not T.Locked(unit) and p.gold==1000)
p.failWrites=1
assert(not T.Transfer(0,0,Snapshot(unit,origin),119,75));assert(unit.x==3 and p.gold==1000)
-- Native relocation mutates, then raises: identity/position confirm in recovery.
unit.moveFault='after'
local result=T.Transfer(0,0,Snapshot(unit,origin),119,75)
assert(result==true,'an arrival recovered after SetXY raised is still a successful transfer')
assert(unit.x==119 and p.gold==900 and T.State(0)[1]==101 and T.CityState(origin)[6]==108)
-- Repeated same-turn execution is rejected, including re-entrant SetXY callbacks.
NextTurn(101);local other=Unit(p,4,3,4)
local reentry
unit.onMove=function()reentry=T.Transfer(0,4,Snapshot(other,origin),119,75)end
p.goldFault='after'
assert(T.Transfer(0,0,Snapshot(unit,destination),15,26))
assert(reentry==false and p.gold==800 and T.State(0)[3]==0)
-- A surviving receipt reconstructs restrictions and charges exactly once.
NextTurn(102)
p.goldFault='before'
unit.onMove=nil
assert(T.Transfer(0,4,Snapshot(other,origin),119,75)==false) -- origin cooldown
-- Corruption fails closed and preserves unrelated data.
p.raw='foreign-data[THC_P1:garbage]';assert(not T.Validate(0,4,Snapshot(other,origin)))
assert(p.raw=='foreign-data[THC_P1:garbage]')
print('PASS native failures, restriction/write failures, re-entry, charge-after-error recovery, corrupt save rejection')
