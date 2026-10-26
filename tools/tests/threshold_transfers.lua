local T=Court();local p=Players[0]
assert(T.Cost(0)==100)
for era=0,7 do p.era=era;assert(T.Cost(0)==50+25*era)end;p.era=2
local initial=Snapshot(unit,origin)
assert(T.Validate(0,0,initial))
p.gold=99;assert(not T.Transfer(0,0,initial,119,75));assert(p.gold==99 and unit.moves==180)
p.gold=100
local civilian=Unit(p,3,119,75);civilian.combat=false;civilian.kind=GameInfoTypes.UNIT_WORKER
assert(T.Transfer(0,0,initial,119,75))
assert(p.gold==0 and unit:GetX()==119 and unit:GetY()==75 and unit.moves==0)
assert(p.units[0]==unit and unit.xp==123 and unit.damage==37 and unit.born==7)
assert(unit.attacks>=1 and unit:IsHasPromotion(T.EXHAUSTED))
assert(unit.raw:find('foreign-data',1,true))
assert(T.CityState(origin)[6]==108 and T.CityState(destination)[6]==0)
assert(T.State(0)[1]==101 and not T.Transfer(0,0,initial,3,4))
-- Movement restoration and unlimited attacks do not restore mobility/offense.
unit.moves=10000;unit.blitz=true
assert(not GameEvents.CanMoveInto.Fire(0,0,15,26,false,false))
assert(not unit:IsCanAttackWithMove());assert(not GameEvents.CanHaveUpgrade.Fire(0,0,1,2))
-- Full Lua context replacement retains only native save-scoped ScriptData.
local old=T;ContextPtr=NewContext();ReloadCore();T=Court();assert(not old.active)
assert(T.State(0)[1]==101 and T.CityState(origin)[6]==108 and T.Locked(unit))
p.gold=1000;NextTurn(101)
assert(not T.Locked(unit) and not unit:IsHasPromotion(T.EXHAUSTED) and unit.moves==180)
-- Receiving did not start destination's cooldown: depart from it next turn.
assert(T.Transfer(0,0,Snapshot(unit,destination),15,26))
assert(T.CityState(destination)[6]==109 and T.CityState(third)[6]==0)
local home=Unit(p,4,3,4)
NextTurn(107);assert(not T.Validate(0,4,Snapshot(home,origin)))
NextTurn(108);assert(T.Validate(0,4,Snapshot(home,origin)))
assert(T.Transfer(0,4,Snapshot(home,origin),119,75))
print('PASS transfer costs, original identity/health/XP, civilian stacking, Huge distance, exhaustion, T+8, independent origins, reload')
