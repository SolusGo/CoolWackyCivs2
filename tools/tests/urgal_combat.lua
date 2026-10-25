-- SQL-backed model of audited native modifier/healing branches. Shipped Lua
-- selects recipients. This does not execute the Civ V DLL.
local function Modifier(u,column)
 local total=0
 for id,row in pairs(NativePromotions) do if u:IsHasPromotion(id) then total=total+(row[column] or 0) end end
 return total
end
local function Strength(u,mode,targetCity)
 local m=Modifier(u,'CombatPercent')
 if mode=='attack' then m=m+Modifier(u,'AttackMod')+(targetCity and Modifier(u,'CityAttack') or 0)
 elseif mode=='defense' then m=m+Modifier(u,'DefenseMod')
 elseif mode=='ranged' then m=m+Modifier(u,'AttackMod')+Modifier(u,'RangedAttackModifier') end
 return 34*(100+m)/100
end
local function Kill(u,damage,cannotHeal)
 local heal=cannotHeal and 0 or Modifier(u,'HPHealedIfDestroyEnemy')
 return damage-math.min(damage,heal)
end
local veteran=NewUnit(1,0);veteran:SetHasPromotion(102,true)
local ordinary=NewUnit(2,0)
local ranged=NewUnit(3,0,5);local siege=NewUnit(4,0,6)
local ship=NewUnit(5,0);ship.domain=1
local air=NewUnit(6,0);air.domain=2
LoadUrgal();local U=MapModData.URGAL
assert(Kill(veteran,40)==40,'Pot Chaser alone cannot heal')
assert(U.Drink(0))
for _,u in ipairs({veteran,ordinary}) do
 assert(Strength(u,'attack',false)==51,'+50% against units')
 assert(Strength(u,'attack',true)==51,'+50% against cities')
 assert(Strength(u,'defense',false)==34,'defense unchanged')
end
for _,u in ipairs({ranged,siege,ship,air}) do assert(Strength(u,'ranged',false)==34,'excluded attacks unchanged') end
-- Native city bombardment uses the city cache and garrison BASE strengths,
-- not garrison AttackMod. The controller never changes those base stats.
assert(GameInfo.Units[veteran.kind].Combat==14 and Modifier(veteran,'CombatPercent')==0)
assert(Kill(veteran,40)==25 and Kill(veteran,5)==0 and Kill(veteran,0)==0)
assert(Kill(veteran,40,true)==40,'native CannotHeal remains authoritative')
assert(Kill(ordinary,40)==40,'Strength II alone cannot heal')
veteran:SetHasPromotion(102,false);U.Sync(0);assert(Kill(veteran,40)==40,'requires Pot Chaser')
veteran:SetHasPromotion(102,true);U.Sync(0);assert(Kill(veteran,40)==25)
now=5;GameEvents.PlayerDoTurn.Fire(0)
assert(Strength(veteran,'attack',false)==34 and Strength(veteran,'attack',true)==34)
assert(Strength(veteran,'defense',false)==34 and Kill(veteran,40)==40,'Aftertaste has no combat penalty or residual healing')
assert(veteran.moves==120 and ordinary.moves==120,'no additional movement')
print('PASS shipped-recipient/SQL-backed unit/city attacks, defense/exclusions, capped conditional kill healing and expiry (native arithmetic model)')
