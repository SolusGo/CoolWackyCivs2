local G=Reload();Tick(turn+12)
local s=G.State(0);s.insub=2;G.Save(0,s);assert(G.Roll(0,4,s.ready))
local lifetime=1000
local function fight(ap,ai,af,dp,di,df)
 lifetime=lifetime+1
 local a=Players[ap] and Players[ap]:GetUnitByID(ai)
 local d=Players[dp] and Players[dp]:GetUnitByID(di)
 if af>=100 and a then a.born=lifetime end
 if df>=100 and d then d.born=lifetime end
 GameEvents.CombatResult(ap,ai,10,af,100,dp,di,100,df,100,-1,-1,0,4,5)
 if af>=100 and a then a.dead=true;GameEvents.UnitPrekill(ap,ai,a.typ,4,5,true,dp);GameEvents.UnitPrekill(ap,ai,a.typ,4,5,false,dp) end
 if df>=100 and d then d.dead=true;GameEvents.UnitPrekill(dp,di,d.typ,4,5,true,ap);GameEvents.UnitPrekill(dp,di,d.typ,4,5,false,ap) end
 GameEvents.CombatEnded(ap,ai,10,af,100,dp,di,100,df,100,-1,-1,0,4,5)
 if a then a.dead=false end;if d then d.dead=false end
end
-- max(base melee 18, base ranged 23) * .25 rounds to 6 per effect.
fight(0,hall.id,10,1,target.id,100);assert(p.culture==12)
GameEvents.CombatEnded(0,hall.id,10,10,100,1,target.id,100,100,100);assert(p.culture==12)
GameEvents.CombatResult(0,hall.id,10,10,100,1,target.id,100,100,100,-1,-1,0,4,5)
GameEvents.CombatEnded(0,hall.id,10,10,100,1,target.id,100,100,100);assert(p.culture==12,'repeated result/completion pair paid the same lifetime twice')
plot.friendly=false;fight(0,hall.id,10,1,target.id,100);assert(p.culture==18)
plot.friendly=true;fight(0,soldier.id,10,1,target.id,100);assert(p.culture==24)
fight(0,soldier.id,10,1,target.id,90);assert(p.culture==24,'reward for surviving target')
-- Defensive victories, city bombardment, and civilians.
fight(1,target.id,100,0,hall.id,10);assert(p.culture==36)
fight(0,-1,0,1,target.id,100);assert(p.culture==42)
local civ=NewUnit(enemy,9,-9,0);fight(0,hall.id,0,1,civ.id,100);assert(p.culture==42)
local weak=NewUnit(enemy,10,-9,1);fight(0,hall.id,0,1,weak.id,100);assert(p.culture==44)
-- Nuclear/collateral deaths need no two-unit combat pair. Reload between delayed
-- and final callbacks must not pay a second Detention reward.
local collateral=NewUnit(enemy,19,-8,28);collateral.dead=true
GameEvents.UnitPrekill(1,19,collateral.typ,4,5,true,0);assert(p.culture==51)
G=Reload();GameEvents.UnitPrekill(1,19,collateral.typ,4,5,false,0);assert(p.culture==51)
local captured=NewUnit(enemy,20,-8,28);GameEvents.UnitPrekill(1,20,captured.typ,4,5,false,0);assert(p.culture==51)
-- Distinct ranged attacker, splash casualty, deletion/disband/conversion,
-- civilians and neutral/friendly-fire casualties use the same native ABI.
local ranged=NewUnit(p,30,-7,0,28);GameEvents.UnitCreated(0,ranged.id,ranged.typ,4,5)
assert(ranged:IsHasPromotion(G.promotions.DETENTION))
fight(0,ranged.id,0,1,target.id,100);assert(p.culture==57)
local splash=NewUnit(enemy,21,-8,40);splash.dead=true
GameEvents.UnitPrekill(1,21,splash.typ,4,5,true,0);assert(p.culture==67)
local removed=NewUnit(enemy,22,-8,28);removed.dead=true
GameEvents.UnitPrekill(1,22,removed.typ,4,5,false,-1);assert(p.culture==67)
removed.dead=false;GameEvents.UnitPrekill(1,22,removed.typ,4,5,true,-1);assert(p.culture==67)
local civilDeath=NewUnit(enemy,23,-9,0);civilDeath.dead=true
GameEvents.UnitPrekill(1,23,civilDeath.typ,4,5,true,0);assert(p.culture==67)
local neutral=NewUnit(foreign,24,-8,28);neutral.dead=true
local war=Teams[0].IsAtWar;Teams[0].IsAtWar=function() return false end
GameEvents.UnitPrekill(2,24,neutral.typ,4,5,true,0);assert(p.culture==67)
Teams[0].IsAtWar=war
Tick(turn+5);fight(0,hall.id,10,1,target.id,100);assert(p.culture==73,'Hall reward should survive Detention expiry')
plot.friendly=false;fight(0,hall.id,10,1,target.id,100);assert(p.culture==73)
-- Fresh/upgraded/gifted units cannot export civilization-wide promotions.
foreign.units={soldier};p.units={hall,civilian};soldier.owner=2
GameEvents.UnitConverted(0,2,soldier.id,soldier.id,false)
assert(not soldier:IsHasPromotion(G.promotions.BLAKE) and not soldier:IsHasPromotion(G.promotions.DETENTION))
