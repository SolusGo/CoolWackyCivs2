local k=MapModData.CKPrayer;local p=Players[0]
local s=TEST.pray();TEST.nextTurn(2);local saved=p.script;local faith=p.faith
TEST.reload();k=MapModData.CKPrayer;s=k.states[0]
assert(p.script:find('unrelated mod payload',1,true) and s.stage==2 and s.ready==5 and s.address==5 and s.clock==2)
assert(p.faith==faith and not k.Pray(0,1,0) and not k.Pray(0,s.stage,s.ready))
TEST.nextTurn(2);assert(k.Active(s,'address'));TEST.reload();k=MapModData.CKPrayer;s=k.states[0]
TEST.nextTurn();assert(not k.Active(s,'address') and p.cap:bonus('YIELD_FAITH')==0 and p.faith==10)
for i=2,7 do TEST.advance();TEST.pray() end
assert(s.grace==1);faith=p.faith;local gap=p.gap;local ready=s.ready
for i=1,3 do TEST.reload() end;k=MapModData.CKPrayer;s=k.states[0]
assert(s.grace==1 and s.ready==ready and p.faith==faith and p.gap==gap and p.cap:bonus('YIELD_CULTURE')==1)
assert(select(2,p.script:gsub('|CKPRAYER1:',''))==1)
-- ASK: empty/process/near-finished queues preserve all credit, no native overflow.
TEST.advance();TEST.pray();TEST.advance();TEST.pray();TEST.advance();TEST.pray();TEST.advance()
p.era=7;p.cap.queue=nil;TEST.pray();assert(s.bread==64 and p.cap.production==8,'earlier ASK progress preserved')
TEST.reload();k=MapModData.CKPrayer;s=k.states[0];assert(s.bread==64)
p.cap.queue='process';Events.SerialEventCityInfoDirty();assert(s.bread==64)
p.cap.queue='unit';p.cap.needed=10;p.cap.production=9;Events.SerialEventCityInfoDirty()
assert(s.bread==63 and p.cap.production==10)
for i=1,10 do Events.SerialEventCityInfoDirty() end;assert(s.bread==63 and p.cap.production==10)
p.cap.queue='project';p.cap.production=0;p.cap.needed=100;Events.SerialEventCityInfoDirty()
assert(s.bread==0 and p.cap.production==63)
-- Preserve native fractional production and never force a fractional overrun.
p.cap.fraction=75;p.cap.needed=64;s.bread=1;k.Save(s);Events.SerialEventCityInfoDirty()
assert(s.bread==1 and p.cap:GetProductionTimes100()==6375)
p.cap.needed=100;Events.SerialEventCityInfoDirty();assert(s.bread==0 and p.cap:GetProductionTimes100()==6475)
-- Do not remove the fifth economic tick when another event occurs before our turn.
TEST.advance();TEST.pray();TEST.advance();TEST.pray();TEST.advance();TEST.pray();TEST.advance();TEST.pray()
local untilTurn=s.address;TEST.turn=untilTurn
k.Sync(0,false);assert(p.cap:GetNumRealBuilding(GameInfoTypes.BUILDING_CK_ADDRESS)==1)
GameEvents.PlayerDoTurn(0);assert(p.cap:GetNumRealBuilding(GameInfoTypes.BUILDING_CK_ADDRESS)==0)
-- Corrupt/future state fails closed without replacing the original save payload.
p.script='foreign data|CKPRAYER9:1,2,3|';TEST.reload();k=MapModData.CKPrayer
assert(k.failed[0] and not k.states[0] and p.script=='foreign data|CKPRAYER9:1,2,3|')
assert(p.cap:bonus('YIELD_CULTURE')==0 and not k.CanPray(0))
p.script='foreign|CKPRAYER1:1,8,0,0,0,0,0,0,0|';TEST.reload();assert(MapModData.CKPrayer.failed[0])
print('PASS Kingdom save/reload, exact expiration, duplicate prevention, all ASK queue shapes and corrupt data')
