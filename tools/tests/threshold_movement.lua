local T=Court();local p=Players[0]
local foreign=Unit(Players[1],20,20,20)
assert(GameEvents.CanMoveInto.Fire(1,20,21,21,false,false))
assert(T.Transfer(0,0,Snapshot(unit,origin),119,75))
unit.moves=10000;unit.blitz=true
for _,flags in ipairs({{false,false},{true,false},{true,true}})do
 assert(not GameEvents.CanMoveInto.Fire(0,0,118,75,flags[1],flags[2]))
end
assert(not GameEvents.CanMoveInto.Fire(0,0,118,75),'omitted unused trailing flags must be harmless')
assert(not unit:IsCanAttackWithMove() and not GameEvents.CanHaveUpgrade.Fire(0,0,1,2))
NextTurn(101);unit.kind=GameInfoTypes.UNIT_RIFLEMAN
assert(T.Eligible(unit),'normal late-game melee upgrades must remain eligible')
-- A stale/corrupt stamp on an unrelated unit must not become a global veto.
foreign.raw='other[THC_U1:0:100:999:999]'
assert(GameEvents.CanMoveInto.Fire(1,20,21,21,false,false))
foreign.raw='other[THC_U1:broken]'
assert(GameEvents.CanMoveInto.Fire(1,20,21,21,false,false))
foreign.raw='other';foreign.promos[T.EXHAUSTED]=true
assert(GameEvents.CanMoveInto.Fire(1,20,21,21,false,false),'promotion without a valid record must not veto unrelated movement')
foreign.promos[T.EXHAUSTED]=false
-- Execute the SHIPPED Jin veto, with modeled geometry/save adapters, on the
-- same TestAll event bus. Threshold's permissive return cannot undo its veto.
local home=Plot(20,20);local near=Plot(21,20);local far=Plot(30,20)
JinSave={Read=function(u) return u.jin end};JinConfig={defenderLeash=3}
JinFixture={IsJin=function(id)return id==1 end,Now=function()return turn end,
 Plot=function()return home end,Distance=function(a,b)return math.abs(a.x-b.x)+math.abs(a.y-b.y)end}
LoadJinVeto();GameEvents.CanMoveInto.Add(JinFixture.CanMoveInto)
foreign.jin={owner=1,expires=200,plot=1}
assert(GameEvents.CanMoveInto.Fire(1,20,21,20,false,false))
assert(not GameEvents.CanMoveInto.Fire(1,20,30,20,false,false),'Jin leash veto must still win')
near.city=origin;assert(not GameEvents.CanMoveInto.Fire(1,20,21,20,false,false));near.city=nil
foreign.jin=nil;assert(GameEvents.CanMoveInto.Fire(1,20,30,20,false,false))
-- Existing opt-ins on ineligible units are retained; those units are not
-- portal-eligible and remain subject only to their own controllers.
foreign.kind=GameInfoTypes.UNIT_WORKER;foreign.combat=false
assert(not T.Eligible(foreign) and GameEvents.CanMoveInto.Fire(1,20,21,20,false,false))
-- An external late-loaded type needs the same native opt-in. Never enable a
-- portal action whose movement exhaustion cannot be enforced.
local added={};for k,v in pairs(GameInfo.Units[GameInfoTypes.UNIT_RIFLEMAN])do added[k]=v end
GameInfo.Units[200000]=added;unit.kind=200000;added.SendCanMoveIntoEvent=0
assert(not T.Eligible(unit));added.SendCanMoveIntoEvent=1;assert(T.Eligible(unit))
print('PASS movement: foreign/civilian units, valid-only restrictions, Blitz/restored moves, late-game upgrades, six-argument CP ABI and composed shipped Jin veto')
