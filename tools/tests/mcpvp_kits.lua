TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
local v=TEST.new('UNIT_MCPVP_VETERAN',4,4);TEST.flush();local r=M.Peek(s,v)
assert(M.SelectKit(s,v,'KANGAROO'));assert(r.kit=='KANGAROO' and v:sum('MovesChange')==1 and v:sum('DefenseMod')==0) -- grace offsets Kangaroo
v.embarked=true;M.Apply(s,v,r);assert(v:sum('MovesChange')==0 and r.kit=='KANGAROO')
v.embarked=false;M.Apply(s,v,r);assert(v:sum('MovesChange')==1)
v.moves=120;assert(not M.SelectKit(s,v,'THOR'))
TEST.turnTo(15);assert(M.SelectKit(s,v,'THOR'));assert(v:sum('MovesChange')==0)
assert(r.ready==20 and r.changeReady==30)
-- Real cooldown cannot be bypassed by an upgrade.
local successor=TEST.mcpConvert(v,'UNIT_SPEARMAN');v=successor
assert(M.Peek(s,v)==r and r.veteran and r.kit=='THOR' and r.ready==20)
assert(v:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_VETERAN))
TEST.turnTo(20);v:SetXY(6,5);v.moves=120;TEST.flush()
local enemy=TEST.new('UNIT_WARRIOR',7,5,1);local ally=TEST.new('UNIT_WARRIOR',6,6);TEST.flush()
local targets=M.AbilityTargets(s,v);assert(#targets==1 and targets[1].id==enemy.id)
assert(M.Ability(s,v,targets[1]));assert(enemy.damage==15 and ally.damage==0 and r.ready==25 and v.moves==0)
v.moves=120;assert(#M.AbilityTargets(s,v)==0)
TEST.turnTo(25);enemy.invisible=true;assert(#M.AbilityTargets(s,v)==0);enemy.invisible=false
-- Hills and lower terrain are enforced; the damage may kill through native handling.
r.kit='STOMPER';r.ready=0;M.Apply(s,v,r)
assert(#M.AbilityTargets(s,v)==0);v:GetPlot().hill=true
enemy:GetPlot().hill=true;assert(#M.AbilityTargets(s,v)==0);enemy:GetPlot().hill=false
enemy:GetPlot().mountain=true;assert(#M.AbilityTargets(s,v)==0);enemy:GetPlot().mountain=false
enemy.damage=85;assert(M.Ability(s,v,M.AbilityTargets(s,v)[1]));assert(enemy.dead)
-- Endermage uses victim legality, never occupied terrain or cities.
r.kit='ENDERMAGE';r.ready=0;v.moves=120;M.Apply(s,v,r)
enemy=TEST.new('UNIT_WARRIOR',8,5,1);TEST.flush()
local original=enemy:GetPlot();local landing=M.PullPlot(v,enemy);assert(landing and landing:GetNumUnits()==0)
assert(M.Ability(s,v,M.AbilityTargets(s,v)[1]));assert(enemy:GetPlot()==landing and enemy:GetPlot()~=original and r.ready==32)
assert(not enemy:GetPlot():IsCity())
enemy:Kill(false,-1)
-- Poison is applied only after a successful direct hit, and refreshes without stacking.
r.kit='VIPER';r.ready=0;v.moves=120;M.Apply(s,v,r)
enemy=TEST.new('UNIT_WARRIOR',7,5,1);TEST.flush()
-- Actual CP ABI: argument 3 is incoming retaliation; argument 8 hits defender.
GameEvents.CombatResult(0,v.id,0,0,100,1,enemy.id,12,12,100,-1,-1,0,7,5)
assert(not enemy:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_POISON))
enemy:ChangeDamage(12,0)
GameEvents.CombatEnded(0,v.id,0,0,100,1,enemy.id,12,12,100,-1,-1,0,7,5);TEST.flush();assert(enemy:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_POISON))
M.PoisonTurn(1);assert(enemy.damage==17);M.PoisonTurn(1);assert(enemy.damage==17)
M.Poison(enemy,0);TEST.turn=26;M.PoisonTurn(1);assert(enemy.damage==22)
TEST.turn=27;M.PoisonTurn(1);assert(enemy.damage==27 and not enemy:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_POISON))
-- Dead attackers do not orphan poison; expired entries are removed from ScriptData.
M.Poison(enemy,0);v:Kill(false,-1);enemy.damage=96;TEST.turn=28;M.PoisonTurn(1);assert(enemy.dead)
-- Standard kill Legacy is capped and the bonus near an ACTIVE Feast is capped separately.
s.mode='HG';s.start=0;s.finish=100;s.killLegacy=0;s.nearLegacy=0;s.kills=0
s.feast={plot=Map.GetPlot(7,5):GetPlotIndex(),active=10,expires=50,status='ACTIVE'}
local before=s.current
for _=1,10 do M.KillReward(s,{pid=1,typ=GameInfoTypes.UNIT_WARRIOR},Map.GetPlot(7,5)) end
assert(s.current==before+25 and s.killLegacy==15 and s.nearLegacy==10)
M.KillReward(s,{pid=3,typ=GameInfoTypes.UNIT_WARRIOR},Map.GetPlot(7,5));assert(s.current==before+25)
print('PASS McPvP five distinct kits, exact-target damage, legal relocation, poison, cooldown continuity and combat caps')
