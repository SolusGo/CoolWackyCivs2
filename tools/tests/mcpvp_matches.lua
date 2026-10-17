TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
assert(s.mode=='HG' and s.finish-s.start==20)
local v=TEST.new('UNIT_MCPVP_VETERAN',4,4);TEST.flush()
local r=M.Peek(s,v);assert(r.veteran)
assert(M.Command(0,'QUEUE',nil,'CTF'));assert(s.mode=='HG' and s.queued=='CTF')
-- Grace expires and Final Battle starts even when a valid site cannot be found.
assert(v:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_GRACE))
TEST.turnTo(3);assert(not v:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_GRACE))
local plot=Map.GetPlot(6,5)
s.feast={plot=plot:GetPlotIndex(),active=10,expires=15,status='PREPARING'}
TEST.turnTo(7);assert(s.feast.announced and s.feast.status=='PREPARING')
local rival=TEST.new('UNIT_WARRIOR',6,5,1);TEST.flush()
TEST.turnTo(10);assert(s.feast.status=='CLAIMED' and s.feast.claimant==1)
assert(Players[1].gold==75 and rival:GetExperience()==20)
assert(not M.ClaimFeast(s,v));assert(s.current==0)
-- A separate Feast can be won; claims are committed before rewards.
s.feast={plot=plot:GetPlotIndex(),active=10,expires=15,status='ACTIVE'}
rival:Kill(false,-1);v:SetXY(6,5);v.damage=60;TEST.flush()
assert(s.feast.claimant==0 and s.current==15 and v.damage==35)
assert(not M.ClaimFeast(s,v) and s.current==15)
TEST.turnTo(20);assert(s.completed==1 and s.wins.HG==1 and s.mode=='CTF' and s.current==25)
assert(not v:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_FINAL) and not v:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_GRACE))
GameEvents.PlayerDoTurn(0);TEST.flush();assert(s.completed==1 and s.current==25,'Repeated turn callbacks cannot pay a completed match twice')
-- CTF acquisition, attack restrictions, return and once-per-city ledger.
v:SetXY(8,7);v.moves=120;TEST.flush()
local cities=M.ObjectiveTargets(s,v,'STEAL');assert(#cities==1)
assert(M.Objective(s,v,'STEAL',cities[1]));assert(r.flag and v.moves==0)
assert(GameEvents.MustAbortAttack(0,v.id)==true)
assert(GameEvents.CanDoCommand(0,v.id,CommandTypes.COMMAND_GIFT)==false)
assert(GameEvents.UnitCanHaveAnyUpgrade(0,v.id)==false)
v.moves=120;v:SetXY(4,4);TEST.flush();assert(M.Objective(s,v,'RETURN'))
assert(not r.flag and s.captures==1 and s.current==50 and Players[0].culture==40 and Players[0].ga==50)
v:SetXY(8,7);v.moves=120;TEST.flush();assert(#M.ObjectiveTargets(s,v,'STEAL')==0)
assert(not M.Objective(s,v,'RETURN'))
s.queued='SAB';TEST.turnTo(40);assert(s.wins.CTF==1 and s.mode=='SAB')
-- Defender gets a real response window; city yields expire without base-yield mutation.
v.moves=120;local targets=M.ObjectiveTargets(s,v,'INFILTRATE');assert(#targets==1)
assert(M.Objective(s,v,'INFILTRATE',targets[1]));local before=Players[1].notifications
TEST.turnTo(41);assert(r.mission and r.mission.warned and Players[1].notifications>before)
TEST.turnTo(42);assert(r.mission and s.missions==0)
TEST.turnTo(43);assert(not r.mission and s.missions==1 and s.current==80)
assert(TEST.enemyCap:GetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE)==1)
assert(#M.ObjectiveTargets(s,v,'INFILTRATE')==0)
TEST.turnTo(48);assert(TEST.enemyCap:GetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE)==0)
TEST.turnTo(60);assert(s.wins.SAB==1 and s.completed==3)
-- Interrupted infiltrations do not grant rewards; consumed city raids remain consumed.
s.queued='SAB';M.StartMatch(s);v.moves=120
assert(M.Objective(s,v,'INFILTRATE',M.ObjectiveTargets(s,v,'INFILTRATE')[1]))
v:SetXY(0,0);TEST.flush();assert(not r.mission)
-- Capital Culture follows capital relocation, and memory Culture continues increasing.
M.Legacy(s,910);Players[0].era=GameInfoTypes.ERA_FUTURE
M.Remember(s);M.Reconcile(s);local notifications=Players[0].notifications
M.Remember(s);assert(s.remembered and Players[0].notifications==notifications)
local culture=0;for bit=0,4 do culture=culture+TEST.cap:GetNumRealBuilding(GameInfoTypes['BUILDING_MCPVP_LEGACY_'..bit])*2^bit end
assert(culture==18 and v:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_MEMORY))
local city=TEST.city(0,2,2);Players[0].cities={city,TEST.cap};M.Yields(s)
for bit=0,4 do assert(TEST.cap:GetNumRealBuilding(GameInfoTypes['BUILDING_MCPVP_LEGACY_'..bit])==0) end
print('PASS McPvP match objectives, rewards, defender warning, expiry, match wins and permanent milestones')
