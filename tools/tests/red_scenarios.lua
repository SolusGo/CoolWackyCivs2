local R=MapModData.RED_Legend
TEST.flush();local s=R.State(0)
assert(R.Capacity(s)==2)
Players[0].era=GameInfoTypes.ERA_CLASSICAL;assert(R.Capacity(s)==3)
Players[0].era=GameInfoTypes.ERA_MEDIEVAL;assert(R.Capacity(s)==4)
local a=TEST.new('UNIT_WARRIOR',4,4);TEST.flush();local ar=R.Record(a)
assert(ar.training==0 and R.Rank(ar)==0)
for _,n in ipairs({15,35,65,100}) do ar.training=n;R.Apply(a,ar);assert(R.Rank(ar)==({[15]=1,[35]=2,[65]=3,[100]=4})[n]);local count=0;for _,name in ipairs(R.Ranks) do if a:IsHasPromotion(R.Promo(name)) then count=count+1 end end;assert(count==1) end
ar.training=35;a.damage=50;R.Heal(a,10);assert(a.damage==35,'Proven extra healing must not loop')
ar.training=65;R.Apply(a,ar);R.AutoAssign(s);assert(ar.slot==1)
local b=TEST.new('UNIT_ARCHER',5,4);local c=TEST.new('UNIT_SPEARMAN',4,5);local d=TEST.new('UNIT_HORSEMAN',3,5);local e=TEST.new('UNIT_SWORDSMAN',3,4);local f=TEST.new('UNIT_CHARIOT_ARCHER',5,3)
TEST.flush()
for _,u in ipairs({b,c,d,e,f}) do R.AddTraining(u,65,false) end
assert(#R.Team(s)==4,'Medieval limit')
TEST.cap:SetNumRealBuilding(R.PLATEAU,1);GameEvents.CityConstructed(0,0,R.PLATEAU,false,false);assert(R.Capacity(s)==6 and #R.Team(s)==6)
for _,r in ipairs(R.Team(s)) do r.training=100;R.Apply(R.Unit(s,r.serial),r) end
R.Yields(s)
local yields=0;for bit=0,4 do yields=yields+TEST.cap:GetNumRealBuilding(GameInfoTypes['BUILDING_RED_RANK_'..bit])*2^bit end
assert(yields==24,'six Legendary members = 24 rank yields')
R.Save(s);local before=Players[0].script;s=TEST.reload();assert(Players[0].script==before and #R.Team(s)==6,'load must not accumulate yields')
ar=R.Peek(a);ar.training=90;local ace=TEST.new('UNIT_RED_POKEMON_ACE',4,4);TEST.flush()
assert(R.Attach(s,a));assert(ace.dead and ar.ace and R.Rank(ar)==4,'bond thresholds')
local aceToken=ar.ace.token
a.damage=70;TEST.turn=10;assert(R.Item(s,a));assert(a.damage==45 and ar.itemReady==18)
assert(not R.Item(s,a),'cooldown');ar.attackTurn=18;TEST.turn=18;assert(not R.Item(s,a),'no post-attack use');TEST.turn=19
R.AddTraining(a,10,true);assert(ar.training==105,'+50% combat Training')
TEST.cap:SetNumRealBuilding(R.CENTER,1);local gold=Players[0].gold;local serial=ar.serial
a=TEST.convert(a,'UNIT_SPEARMAN');ar=R.Peek(a);assert(ar.serial==serial and ar.training==105 and ar.ace.token==aceToken and ar.slot==1 and Players[0].gold==gold+50,'upgrade preserves bond/serial and refunds once')
s=TEST.reload();ar=R.Peek(a);assert(ar.ace.token==aceToken and ar.itemReady==18)
assert(R.Detach(s,a) and not ar.ace,'detach recreates the saved Ace')
local aces=0;for u in Players[0]:Units() do if u.typ==R.ACE then aces=aces+1 end end;assert(aces==1)
assert(not R.Detach(s,a),'no duplicate detachment')
-- Original capital, ribbons and Hall of Fame are separate persistent claims.
local capital=TEST.enemyCap;capital.pid=0;Players[1].cities={};Players[0].cities[#Players[0].cities+1]=capital;Map.GetPlot(9,7).owner=0
GameEvents.CityCaptureComplete(1,true,9,7,0,5,true)
local general=Players[0].general;assert(general==100 and s.hall==1)
for _,r in ipairs(R.Team(s)) do assert(r.ribbons==1) end
GameEvents.CityCaptureComplete(1,true,9,7,0,5,true);assert(s.hall==1 and Players[0].general==general,'capital cannot be farmed')
s=TEST.reload();GameEvents.CityCaptureComplete(1,true,9,7,0,5,true);assert(s.hall==1)
-- Repeated damage getters and duplicate completion cannot repeat kill rewards.
ar=R.Peek(a);local enemy=TEST.new('UNIT_WARRIOR',6,4,1);local train=ar.training;local culture=Players[0].culture
GameEvents.BattleStarted(0,6,4);GameEvents.BattleJoined(0,a.id,0,false);GameEvents.BattleJoined(1,enemy.id,1,false)
for i=1,5 do GameEvents.BattleDamageDelta(0,100) end
enemy:Kill(false,0);GameEvents.CombatEnded();GameEvents.CombatEnded()
assert(ar.training==train+15 and Players[0].culture==culture+math.floor(GameInfo.Units[enemy.typ].Cost*.5),'one kill + one Momentum')
enemy=TEST.new('UNIT_WARRIOR',6,4,1);train=ar.training
GameEvents.BattleStarted(0,6,4);GameEvents.BattleJoined(0,a.id,0,false);GameEvents.BattleJoined(1,enemy.id,1,false);enemy:Kill(false,0);GameEvents.CombatEnded();assert(ar.training==train+10,'Momentum type already claimed')
-- Mt. Silver is journalled before removal; a reloaded countdown returns exactly once.
Players[0].era=GameInfoTypes.ERA_MODERN
for _,r in ipairs(R.Team(s)) do r.training=100 end
assert(R.SilverEligible(s));local count=#R.Team(s);local saved={}
for _,r in ipairs(R.Team(s)) do saved[r.serial]=true end
local started=TEST.turn;assert(R.BeginSilver(s));assert(not R.BeginSilver(s))
for _,r in ipairs(R.Team(s)) do assert(r.withdrawn and not R.Unit(s,r.serial) and s.silver.snapshots[r.serial]) end
assert(TEST.cap:GetNumRealBuilding(GameInfoTypes.BUILDING_RED_ABSENCE_0)==1)
TEST.turn=started+4;s=TEST.reload();R.ResumeSilver(s);assert(s.silver.phase=='ABSENT')
TEST.turn=started+8;R.ResumeSilver(s);assert(s.silver.phase=='RETURNED')
local identities={};local returned=0
for _,r in ipairs(R.Team(s)) do local u=R.Unit(s,r.serial);assert(u and saved[r.serial] and r.summit and R.Rank(r)==4 and r.ribbons==1 and not identities[r.identity]);identities[r.identity]=true;returned=returned+1;assert(u:GetMaxHitPoints()==110) end
assert(returned==count and returned==6)
for _,name in ipairs(R.Names) do assert(identities[name]) end
assert(TEST.cap:GetNumRealBuilding(GameInfoTypes.BUILDING_RED_ABSENCE_0)==0)
local total=0;for u in Players[0]:Units() do if u:IsCombatUnit() then total=total+1 end end
s=TEST.reload();R.ResumeSilver(s);local again=0;for u in Players[0]:Units() do if u:IsCombatUnit() then again=again+1 end end;assert(total==again,'reload cannot generate another party')
-- Identity damage / movement / range effects use legal native classes.
local partners={};for _,r in ipairs(R.Team(s)) do partners[r.identity]=R.Unit(s,r.serial) end
local snorlax=partners.SNORLAX;assert(snorlax:MaxMoves()==60,'Snorlax maximum 1 Movement')
for _,name in ipairs({'CHARIZARD','LAPRAS'}) do local u=partners[name];if u:IsRanged() then assert(u:IsHasPromotion(R.Promo('RANGE'))) end end
local pikachu=partners.PIKACHU;local pr=R.Peek(pikachu);local foe=TEST.new('UNIT_WARRIOR',8,5,1);pikachu:SetXY(7,5);pikachu.damage=95
GameEvents.BattleStarted(0,7,5);GameEvents.BattleJoined(1,foe.id,0,false);GameEvents.BattleJoined(0,pikachu.id,1,false)
local delta=GameEvents.BattleDamageDelta(0,30);assert(delta==-30,'lethal melee withdrawal cancels incoming damage')
assert(pr.withdrawReady==0,'damage callback cannot consume cooldown')
GameEvents.CombatEnded();assert(pr.withdrawReady==TEST.turn+5 and not (pikachu.x==7 and pikachu.y==5),'legal withdrawal and cooldown')
local blastoise=partners.BLASTOISE
GameEvents.BattleStarted(1,blastoise.x,blastoise.y);GameEvents.BattleJoined(1,foe.id,0,false);GameEvents.BattleJoined(0,blastoise.id,1,false)
assert(GameEvents.BattleDamageDelta(0,40)==-10,'Blastoise ranged damage -25%');GameEvents.CombatEnded()
-- Explicit manual vacancy stays vacant; destroyed units cannot be restored by serial copies.
local victim=partners.CHARIZARD;local vr=R.Peek(victim);local oldSerial=vr.serial;local slot=vr.slot
victim:Kill(false,1);assert(not s.slots[slot] and vr.dead);s.manual=true;TEST.flush();assert(not s.slots[slot])
local impostor=TEST.new('UNIT_ARCHER',5,5);R.Tag(impostor,oldSerial);local fresh=R.Record(impostor);assert(fresh.serial~=oldSerial and fresh.training==0 and not fresh.summit)
-- Speed ratios preserve passive pacing and exact Standard baselines.
for _,n in ipairs({67,100,150,300}) do R.Percent=n;assert(R.Turns(8)==math.max(1,math.floor(8*n/100+.5))) end;R.Percent=100
print('PASS Red scenarios: ranks, capacity, healing, yields, saves, Ace, item, upgrades, capital claims, combat dedupe, Mt. Silver, identities, death and speed')
