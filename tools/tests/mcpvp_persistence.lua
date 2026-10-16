TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
local v=TEST.new('UNIT_MCPVP_VETERAN',4,4);TEST.flush()
local r=M.Peek(s,v);r.kit='THOR';r.ready=17;r.changeReady=29
Players[0].script='foreign payload';M.Legacy(s,57);M.Save(s)
local snapshot=Players[0].script
M.Legacy(s,30);Players[0].script=snapshot
M,s=TEST.mcpReload();r=M.Peek(s,v)
assert(s.current==57 and s.lifetime==57 and r.ready==17 and r.changeReady==29)
assert(Players[0].script:sub(1,15)=='foreign payload')
-- Repeated training notifications cannot award Legacy twice; free units earn nothing.
TEST.cap.buildings[M.HUB]=1
local soldier=TEST.new('UNIT_WARRIOR',4,4);TEST.flush();local before=s.current
GameEvents.CityTrained(0,TEST.cap.id,soldier.id,false,false)
GameEvents.CityTrained(0,TEST.cap.id,soldier.id,false,false);TEST.flush()
assert(s.current==before+2 and M.Peek(s,soldier).eligible)
local free=TEST.new('UNIT_WARRIOR',3,4);TEST.flush();assert(not M.Peek(s,free).eligible and s.current==before+2)
-- Kit flags and cooldowns survive upgrade even though the native conversion drops ScriptData.
local nextUnit=TEST.mcpConvert(v,'UNIT_SPEARMAN');v=nextUnit;r=M.Peek(s,v)
assert(r and r.ready==17 and r.changeReady==29 and r.kit=='THOR' and r.veteran)
-- Stale unit IDs and copied tags cannot impersonate a living record.
local copy=TEST.new('UNIT_WARRIOR',3,3);copy.script=v.script;TEST.flush()
assert(M.Peek(s,copy).serial~=r.serial and not M.Peek(s,copy).kit)
local oldID=v.id;local oldScript=v.script;v:Kill(false,-1)
local reuse=TEST.new('UNIT_WARRIOR',2,3);TEST.units[reuse.id]=nil;reuse.id=oldID;reuse.born=1;TEST.units[oldID]=reuse;reuse.script=oldScript
M.Reconcile(s);assert(not M.Peek(s,reuse).kit and not M.Peek(s,reuse).veteran)
-- Gifting cannot clone kit privileges or carry a flag into a new owner.
local gifted=TEST.mcpConvert(soldier,'UNIT_WARRIOR',1,false)
assert(not gifted:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_THOR) and not M.Serial(gifted))
local trader=TEST.new('UNIT_MCPVP_VETERAN',4,4);TEST.flush();M.SelectKit(s,trader,'KANGAROO')
local away=TEST.mcpConvert(trader,'UNIT_MCPVP_VETERAN',1,false)
local returned=TEST.mcpConvert(away,'UNIT_MCPVP_VETERAN',0,false)
local transferred=M.Peek(s,returned);assert(transferred and not transferred.veteran and not transferred.kit and not M.CanKit(s,returned,'THOR'))
-- Invalid city ownership terminates flags and missions and removes debuffs.
s.queued='CTF';M.StartMatch(s);local carrier=TEST.new('UNIT_MCPVP_VETERAN',8,7);TEST.flush()
local cr=M.Peek(s,carrier);local target=M.ObjectiveTargets(s,carrier,'STEAL')[1]
assert(M.Objective(s,carrier,'STEAL',target));M,s=TEST.mcpReload();cr=M.Peek(s,carrier);assert(cr.flag and s.raids[target.key])
carrier.embarked=true;GameEvents.UnitSetXY(0,carrier.id,8,7);TEST.flush();assert(not cr.flag and not carrier:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_FLAG))
carrier.embarked=false;s.queued='SAB';M.StartMatch(s);carrier.moves=120
assert(M.Objective(s,carrier,'INFILTRATE',M.ObjectiveTargets(s,carrier,'INFILTRATE')[1]))
local ref=cr.mission.target;s.debuffs[ref.key]={target=ref,expires=100};M.Debuffs()
TEST.enemyCap.pid=2;M.UpdateMissions(s);M.Debuffs();assert(not cr.mission and not next(s.debuffs))
assert(TEST.enemyCap:GetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE)==0)
-- Corrupt/newer envelopes are rejected without overwriting the original save.
M.states[0]=nil;local original=Players[0].script;Players[0].script='|MCPSTATE9:0:|'
assert(not pcall(M.State,0));assert(Players[0].script=='|MCPSTATE9:0:|')
Players[0].script=original;s=M.State(0)
local damaged=M.Decode(M.Encode(s));damaged.current='invalid'
M.states[0]=nil;Players[0].script=M.Put(original,'MCPSTATE1',damaged)
local invalid=Players[0].script;assert(not pcall(M.State,0) and Players[0].script==invalid)
Players[0].script=original;M.State(0)
-- Speed comes from real GameSpeeds rows, including cooldown minimums.
for _,pair in ipairs({{'GAMESPEED_QUICK',13},{'GAMESPEED_STANDARD',20},{'GAMESPEED_EPIC',30},{'GAMESPEED_MARATHON',60}}) do
 M.speed=GameInfo.GameSpeeds[GameInfoTypes[pair[1]]];assert(M.Turns(20)==pair[2] and M.Turns(1)>=1)
end
print('PASS McPvP save rollback, envelope coexistence, upgrades, training idempotency, ownership/ID invalidation and four game speeds')
