local T=Court();local p=Players[0]
assert(T.Transfer(0,0,Snapshot(unit,origin),119,75))
local function ConvertTo(recipient,id,source)
 local u=Unit(recipient,id,30+id,30);u.promos[T.EXHAUSTED]=true;u.promos[99991]=true
 u.damage=43;u.xp=188;u.upgradeHistory='pike-lancer'
 GameEvents.UnitConverted.Fire(source.owner,recipient.id,source.id,id,false)
 return u
end
Players[2]=Player(2,-333);Players[2].human=false;Players[2].minor=true
local gift=ConvertTo(Players[1],10,unit)
local minor=ConvertTo(Players[2],11,unit)
local conversion=ConvertTo(Players[1],12,unit)
conversion.moves=800;conversion.attacks=3
local dead=ConvertTo(Players[1],13,unit);dead.dead=true
-- The same-turn death is not a mid-combat release trigger.
p.alive=false;p.active=false;GameEvents.PlayerDoTurn.Fire(1)
assert(T.Locked(gift) and gift:IsHasPromotion(T.EXHAUSTED))
-- Real serialized records, no process-state owner registry needed after load.
ContextPtr=NewContext();ReloadCore();T=Court()
turn=101;GameEvents.PlayerDoTurn.Fire(2)
assert(not T.Locked(gift),'gifted unit must recover after original owner elimination')
for _,u in ipairs({gift,minor,conversion})do
 assert(not u:IsHasPromotion(T.EXHAUSTED) and not T.Stamp(u))
 assert(u.promos[99991] and u.damage==43 and u.xp==188 and u.upgradeHistory=='pike-lancer')
 assert(u:GetID()>=10 and u.raw=='foreign-data')
end
assert(gift.moves==0 and minor.moves==0 and conversion.moves==800 and conversion.attacks==3,'cleanup must not alter movement or attack counters')
assert(dead:IsHasPromotion(T.EXHAUSTED),'dead userdata must not be modified')
-- Revival after cleanup must not resurrect a cleared restriction.
p.alive=true;p.active=true;NextTurn(102);assert(not T.Locked(gift))
-- Living origins, including revival before cleanup, still wait for their turn.
assert(T.Write(gift,'THC_U1',{0,102,gift.born,gift.kind}));gift:SetHasPromotion(T.EXHAUSTED,true)
p.alive=false;p.alive=true -- revived before the next safe cleanup boundary
turn=103;p.active=false;GameEvents.PlayerDoTurn.Fire(1);assert(T.Locked(gift))
p.active=true;GameEvents.PlayerDoTurn.Fire(0);assert(not T.Locked(gift))
-- Missing/corrupt records cannot guess an origin while any Court owner lives.
local missing=Unit(Players[1],14,44,30);missing:SetHasPromotion(T.EXHAUSTED,true)
local corrupt=Unit(Players[2],15,45,30);corrupt:SetHasPromotion(T.EXHAUSTED,true)
corrupt.raw='other[THC_U1:bad]';missing.moves=37;corrupt.moves=28;corrupt.attacks=2
GameEvents.PlayerDoTurn.Fire(1);assert(missing:IsHasPromotion(T.EXHAUSTED) and corrupt:IsHasPromotion(T.EXHAUSTED))
p.alive=false;p.active=false;turn=104;GameEvents.PlayerDoTurn.Fire(1)
assert(missing:IsHasPromotion(T.EXHAUSTED) and corrupt:IsHasPromotion(T.EXHAUSTED),'unknown origin needs one saved quarantine turn')
ContextPtr=NewContext();ReloadCore();T=Court();GameEvents.PlayerDoTurn.Fire(2)
assert(corrupt:IsHasPromotion(T.EXHAUSTED),'reload must not bypass quarantine')
turn=105;GameEvents.PlayerDoTurn.Fire(1)
assert(not missing:IsHasPromotion(T.EXHAUSTED) and not corrupt:IsHasPromotion(T.EXHAUSTED))
assert(missing.moves==37 and corrupt.moves==28 and corrupt.attacks==2 and corrupt.raw=='other')
-- Cleanup is independent of dead-player financial state. A fault on one unit
-- cannot prevent a different survivor recovering; retries are turn-bounded.
local faulty=Unit(Players[1],16,46,30);local healthy=Unit(Players[2],17,47,30)
for _,u in ipairs({faulty,healthy})do
 assert(T.Write(u,'THC_U1',{0,103,u.born,u.kind}));u:SetHasPromotion(T.EXHAUSTED,true)
end
p.raw='other[THC_P1:bad]';faulty.failWrites=1
turn=106;GameEvents.PlayerDoTurn.Fire(1)
assert(not T.Restricted(healthy) and not healthy:IsHasPromotion(T.EXHAUSTED))
assert(T.Restricted(faulty) and p.raw=='other[THC_P1:bad]')
turn=107;GameEvents.PlayerDoTurn.Fire(2);assert(not T.Restricted(faulty))
-- An elimination notification changes no new-game state or callbacks.
p.raw='new-game';p.alive=true;p.active=true
gift.raw='new-unit';ContextPtr=NewContext();ReloadCore();assert(not Court().Locked(gift))
print('PASS elimination: major/minor gifts, conversions, same-turn death, reload, death before cleanup, revival, corrupt/missing records and no movement/attack grants')
