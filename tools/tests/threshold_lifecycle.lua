local T=Court();local p=Players[0]
-- Zero/one-house networks are not usable, even though the origin is valid.
destination.house=0;third.house=0
assert(not T.Validate(0,0,Snapshot(unit,origin)))
destination.house=1;assert(T.Validate(0,0,Snapshot(unit,origin)))
local renamed=T.CityToken(origin);origin.name='Renamed First Door';assert(renamed==T.CityToken(origin))
local old=T;local oldHandlers=#GameEvents.PlayerDoTurn.handlers
ContextPtr=NewContext();ReloadCore();T=Court()
assert(not old.active and #GameEvents.PlayerDoTurn.handlers==oldHandlers)
local charged=0
local originalChange=p.ChangeGold
p.ChangeGold=function(self,n)charged=charged+1;return originalChange(self,n)end
-- Fail final receipt deletion twice. Reload at confirmed destination reconstructs
-- the promotion and sees the already charged treasury without paying again.
local failed=0
p.onWrite=function(self,value)
 local body=value:match('%[THC_P1:([^%]]*)%]')
 if body and body:match('^101:100:0:') and failed<2 then failed=failed+1;error('final receipt deletion failure')end
end
assert(not T.Transfer(0,0,Snapshot(unit,origin),119,75))
assert(unit.x==119 and p.gold==900 and T.State(0)[3]==2 and charged==1)
p.onWrite=nil;ContextPtr=NewContext();ReloadCore();T=Court()
assert(p.gold==900 and charged==1 and T.State(0)[3]==0 and T.Locked(unit))
-- Conversion notification copies marker while old instance still exists.
local converted=Unit(Players[1],9,119,75);converted.promos[T.EXHAUSTED]=true
GameEvents.UnitConverted.Fire(0,1,0,9,false)
assert(T.Locked(converted) and converted.moves==0)
p.units[0]=nil;Place(unit,50,50);unit.dead=true
turn=101;Players[1].active=true;Players[0].active=false
GameEvents.PlayerDoTurn.Fire(1)
assert(T.Locked(converted),'recipient turn must not release before originating owner turn')
Players[0].active=true;NextTurn(101)
assert(not T.Locked(converted) and not converted:IsHasPromotion(T.EXHAUSTED))
assert(converted.moves==0,'cleanup must not grant foreign units free movement')
-- Main-menu/new-game context replacement cannot keep cached prior-save state.
p.raw='new-game-other-mod';origin:Plot().raw='new-map';destination:Plot().raw='new-map';third:Plot().raw='new-map'
converted.raw='new-foreign-unit';Place(converted,80,80)
unit.dead=false;p.units[0]=unit;Place(unit,3,4);unit.raw='new-unit';unit.promos={};unit.moves=180
ContextPtr=NewContext();ReloadCore();T=Court()
assert(T.State(0)[1]==0 and T.CityState(origin)[6]==0 and T.Validate(0,0,Snapshot(unit,origin)))
assert(GameEvents.CanMoveInto.Fire(1,9,8,8,false,false),'unmarked/non-Court unit must be unaffected')
print('PASS zero/one house, rename identity, context hook cleanup, native receipt reload without double payment, conversion, originating owner-turn cleanup and new-save isolation')
