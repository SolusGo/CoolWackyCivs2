TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
local v=TEST.new('UNIT_MCPVP_VETERAN',6,5);TEST.flush();assert(M.SelectKit(s,v,'VIPER'))
local function target(typ,pid)
 local d=TEST.new(typ or 'UNIT_WARRIOR',7,5,pid or 1);TEST.flush();return d
end
local function poisoned(d) return d:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_POISON) end
-- Melee: BOTH units damaged. Native final damage values include prior wounds.
local d=target();d.damage=9;v.damage=7
TEST.combat(v,d,13,6);assert(poisoned(d) and d.damage==22 and v.damage==13)
-- Ranged: attacker receives ZERO damage; argument 8 must trigger Viper.
v=TEST.mcpConvert(v,'UNIT_ARCHER');v.damage=0;local ranged=target()
local writes=0;local setScript=ranged.SetScriptData
function ranged:SetScriptData(raw) writes=writes+1;setScript(self,raw) end
TEST.combat(v,ranged,17,0,{duplicate=true,unrelatedEnd=true})
assert(poisoned(ranged) and ranged.damage==17 and writes==1,'One matching combat must apply exactly one poison block')
-- An unrelated Ended callback must not apply poison or consume the real hit.
local unrelated=target()
GameEvents.CombatResult(0,v.id,0,0,100,1,unrelated.id,8,8,100,-1,-1,0,7,5)
unrelated:ChangeDamage(8,0)
GameEvents.CombatEnded(1,900,0,0,100,2,901,0,0,100,-1,-1,0,0,0);TEST.flush();assert(not poisoned(unrelated))
GameEvents.CombatEnded(0,v.id,0,0,100,1,unrelated.id,8,8,100,-1,-1,0,7,5);TEST.flush();assert(poisoned(unrelated))
-- Prior wounds or incoming retaliation cannot masquerade as a successful hit.
local zero=target();zero.damage=15
TEST.combat(v,zero,0,0);assert(not poisoned(zero))
TEST.combat(v,zero,0,11);assert(not poisoned(zero) and zero.damage==15)
local cancelled=target();TEST.combat(v,cancelled,10,0,{suppressDamage=true});assert(not poisoned(cancelled))
-- Native post-combat healing does not undo the fact that a direct hit landed.
local healed=target();TEST.combat(v,healed,10,0,{healDefender=10});assert(healed.damage==0 and poisoned(healed))
-- No civilian, friendly, dead or invalid target receives poison.
local civilian=target('UNIT_WORKER');TEST.combat(v,civilian,10,0);assert(not poisoned(civilian))
local friend=target('UNIT_WARRIOR',0);TEST.combat(v,friend,10,0);assert(not poisoned(friend))
local dead=target();dead.damage=96;TEST.combat(v,dead,8,0);assert(dead.dead and not poisoned(dead))
GameEvents.CombatResult(0,v.id,0,0,100,1,99999,15,15,100,-1,-1,0,7,5)
GameEvents.CombatEnded(0,v.id,0,0,100,1,99999,15,15,100,-1,-1,0,7,5);TEST.flush()
-- Poison persists with exactly two ticks; duplicate owner-turn callbacks do not tick twice.
local persistent=target();TEST.turn=10;TEST.combat(v,persistent,12,0)
local savedScript,savedDamage=persistent.script,persistent.damage
M.PoisonTurn(1);assert(persistent.damage==17)
M.PoisonTurn(1);assert(persistent.damage==17)
persistent.script=savedScript;persistent.damage=savedDamage;M.poisonOwners={};M.navigation={}
M,s=TEST.mcpReload();assert(poisoned(persistent) and M.Block(persistent.script,'MCPPOISON1').left==2)
M.PoisonTurn(1);assert(persistent.damage==17 and M.Block(persistent.script,'MCPPOISON1').left==1)
TEST.turn=11;M.PoisonTurn(1);assert(persistent.damage==22 and not poisoned(persistent) and not M.Block(persistent.script,'MCPPOISON1'))
TEST.turn=12;M.PoisonTurn(1);assert(persistent.damage==22)
-- Refresh after a valid tick restores TWO future ticks; damage never stacks.
local refreshed=target();TEST.combat(v,refreshed,7,0);M.PoisonTurn(1);assert(refreshed.damage==12)
TEST.combat(v,refreshed,7,0);assert(M.Block(refreshed.script,'MCPPOISON1').left==2)
M.PoisonTurn(1);assert(refreshed.damage==19)
TEST.turn=13;M.PoisonTurn(1);assert(refreshed.damage==24)
TEST.turn=14;M.PoisonTurn(1);assert(refreshed.damage==29 and not poisoned(refreshed))
-- Applying attacker may die in the same melee resolution; surviving target still takes its poison ticks.
local survivor=target();v.damage=98;TEST.combat(v,survivor,9,5)
assert(v.dead and poisoned(survivor));TEST.turn=15;M.PoisonTurn(1);assert(survivor.damage==14)
TEST.turn=16;M.PoisonTurn(1);assert(survivor.damage==19 and not poisoned(survivor))
-- Several AI combats can resolve before the next UI frame. Deferred poison
-- must retain native order even when sequence numbers cross a digit boundary.
v=TEST.new('UNIT_MCPVP_VETERAN',6,5);TEST.flush();assert(M.SelectKit(s,v,'VIPER'))
local order,expected={},{};local originalPoison=M.Poison
M.Poison=function(unit,source) order[#order+1]=unit:GetID();return originalPoison(unit,source) end
for _=1,12 do
 local victim=TEST.new('UNIT_WARRIOR',7,5,1);expected[#expected+1]=victim.id
 local args={0,v.id,0,0,100,1,victim.id,1,1,100,-1,-1,0,7,5}
 GameEvents.CombatResult(unpack(args));victim:ChangeDamage(1,0);GameEvents.CombatEnded(unpack(args))
end
TEST.flush();M.Poison=originalPoison;assert(#order==#expected)
for i,id in ipairs(expected) do assert(order[i]==id,'Deferred poison must preserve combat chronology') end
print('PASS McPvP Viper: verified 15-argument CP ABI, melee/ranged, zero damage, actual survival, callback correlation/deduplication, refresh, rollback and exactly two ticks')
