local R=MapModData.RED_Legend;TEST.flush();local s=R.State(0);local p=Players[0]
s.full=true;s.manual=true
assert(not GameEvents.CityCanCreate(0,0,R.PROJECT),'Ancient era')
p.era=GameInfoTypes.ERA_MODERN;assert(not GameEvents.PlayerCanCreate(0,R.PROJECT),'empty team')
for i=1,4 do local u=TEST.new('UNIT_WARRIOR',3+i,4);local r=R.Record(u);r.training=65;assert(R.Assign(s,u,i)) end
assert(not R.SilverEligible(s),'no Legendary')
s.units[s.slots[1]].training=100
assert(GameEvents.PlayerCanCreate(0,R.PROJECT) and GameEvents.CityCanCreate(0,0,R.PROJECT))
assert(not GameEvents.PlayerCanCreate(1,R.PROJECT) and not GameEvents.CityCanCreate(1,0,R.PROJECT))
s=TEST.reload();assert(R.SilverEligible(s),'eligibility survives reload')
p.human=false
local function copies()
 local n=0;for c in p:Cities() do for i=0,c:GetOrderQueueLength()-1 do local kind,id=c:GetOrderFromQueue(i);if kind==OrderTypes.ORDER_CREATE and id==R.PROJECT then n=n+1 end end end;return n
end
for _,count in ipairs({1,5,20}) do
 p.cities={TEST.cap};TEST.cap.queue={};TEST.cap.project=nil;TEST.cap.production=5
 for i=2,count do local c=TEST.city(0,(i-2)%12,math.floor((i-2)/12));c.production=i*10 end
 local best=p.cities[#p.cities]
 best:PushOrder(OrderTypes.ORDER_CONSTRUCT,12345,-1,0,false,true)
 local oldProduction=best:GetProduction()
 for i=1,6 do R.AITurn(s) end
 assert(copies()==1 and best.queue[1][2]==12345 and best.queue[2][2]==R.PROJECT,'one appended order, strongest city')
 assert(best:GetProduction()==oldProduction,'production retained')
 s=TEST.reload();R.AITurn(s);assert(copies()==1,'reload and inactive queue prevent duplicates')
 table.remove(best.queue,1);best.project=R.PROJECT;R.AITurn(s);assert(copies()==1,'active project prevents duplicates')
 best:PushOrder(OrderTypes.ORDER_CONSTRUCT,54321,-1,0,false,false)
 R.AITurn(s);assert(copies()==1,'interruption retains queued project')
 if count>1 then
  table.remove(p.cities,#p.cities);best.pid=1
  R.AITurn(s);assert(copies()==1,'captured producer allows exactly one new project')
 end
end
s.silver.phase='RETURNED';for c in p:Cities() do c.queue={};c.project=nil end
R.AITurn(s);assert(copies()==0 and not GameEvents.PlayerCanCreate(0,R.PROJECT),'completion is permanent')
s=TEST.reload();assert(not GameEvents.CityCanCreate(0,0,R.PROJECT))

-- Independent airlift lifecycle: actual event ABI, asynchronous native completion.
p.human=true;p.cities={TEST.cap};local source=TEST.cap;source.pid=0;source:Plot().owner=0
source:SetNumRealBuilding(R.CENTER,1);local dest=TEST.city(0,1,8);dest:SetNumRealBuilding(R.CENTER,1)
TEST.turn=30
local air=TEST.new('UNIT_WARRIOR',source.x,source.y);local other=TEST.new('UNIT_WARRIOR',source.x,source.y)
TEST.flush();air.async=true
assert(R.Airlift(s,air,dest) and next(s.pendingAirlifts) and not s.airlifts[source.id])
assert(not R.Airlift(s,other,dest),'pending source reservation')
assert(not GameEvents.CanAirliftFrom(0,other.id,source.x,source.y),'no permission for another unit')
local mission=air.mission;air.async=false;air:PushMission(unpack(mission))
assert(air.x==dest.x and air.moves==0 and not next(s.pendingAirlifts) and s.airlifts[source.id]==30)
assert(not R.Airlift(s,other,dest));TEST.flush();s=TEST.reload();assert(s.airlifts[source.id]==30)
air:Kill(false,1);TEST.turn=31
local function rejected(change,undo)
 change();assert(not R.CheckAirlift(s,other,dest));undo()
end
rejected(function() other.moves=60 end,function() other.moves=other:MaxMoves() end)
rejected(function() other.attacked=true end,function() other.attacked=false end)
rejected(function() other.moved=true end,function() other.moved=false end)
rejected(function() dest:SetNumRealBuilding(R.CENTER,0) end,function() dest:SetNumRealBuilding(R.CENTER,1) end)
rejected(function() dest.pid=1 end,function() dest.pid=0 end)
local block=TEST.new('UNIT_WARRIOR',dest.x,dest.y);TEST.flush();assert(not R.CheckAirlift(s,other,dest));block:Kill(false,1)
local enemy=TEST.new('UNIT_WARRIOR',dest.x+1,dest.y,1);assert(not R.CheckAirlift(s,other,dest));enemy:Kill(false,0)
other.async=true;assert(R.Airlift(s,other,dest));other.mission=nil;TEST.flush()
assert(not next(s.pendingAirlifts) and s.airlifts[source.id]~=31,'canceled mission releases allowance')
assert(not other:CanAirliftAt(other:GetPlot(),dest.x,dest.y),'no permanent native Center grant')
assert(R.Airlift(s,other,dest));local queued=other.mission
R=TEST.reloadContext();s=R.State(0)
other.async=false;other:PushMission(unpack(queued))
assert(other.x==source.x and not next(s.pendingAirlifts) and s.airlifts[source.id]~=31,'reload revokes pending permission without replay')
dest:SetNumRealBuilding(R.CENTER,0);dest:SetNumRealBuilding(GameInfoTypes.BUILDING_AIRPORT,1)
assert(R.Airlift(s,other,dest) and other.x==dest.x and s.airlifts[source.id]==31,'Center-to-Airport')
TEST.flush()

-- Turn idempotence, immediate Range normalization, movement and safe anchoring.
local snorlax=R.Unit(s,s.slots[1]);local sr=R.Peek(snorlax);sr.identity='SNORLAX';sr.summit=true;R.Apply(snorlax,sr)
snorlax:SetXY(5,5);sr.stepTurn=nil;TEST.turn=32;snorlax.moves=60
snorlax:SetXY(6,5);assert(sr.stepTurn==32 and snorlax.moves==0)
local ace=TEST.new('UNIT_RED_POKEMON_ACE',6,5);TEST.flush();assert(R.Attach(s,snorlax))
assert(R.Item(s,snorlax) and snorlax.moves==0 and snorlax:MaxMoves()==60,'item cannot buy a second Snorlax tile')
s=TEST.reload();sr=s.units[sr.serial];assert(sr.stepTurn==32 and snorlax.moves==0)
local anchor={pid=0,anchor={x=5,y=5}}
assert(R.RestoreAnchor(snorlax,anchor) and snorlax.x==5 and R.internal==0)
local occupied=TEST.new('UNIT_WARRIOR',6,5);snorlax:SetXY(5,5)
assert(not R.RestoreAnchor(snorlax,{pid=0,anchor={x=6,y=5}}),'never stack on occupied anchor')
assert(not R.RestoreAnchor(snorlax,{pid=0,anchor={x=10,y=5}}),'never undo remote teleports')
occupied:Kill(false,1)
local attacker=TEST.new('UNIT_WARRIOR',5,4,1)
GameEvents.BattleStarted(0,5,5);GameEvents.BattleJoined(1,attacker.id,0,false);GameEvents.BattleJoined(0,snorlax.id,1,false)
snorlax:SetXY(6,5);assert(snorlax.x==6,'no reentrant correction during native placement')
TEST.flush();assert(snorlax.x==5 and snorlax.y==5,'bounded correction covers pre-combat withdrawal without CombatEnded')
snorlax:SetXY(6,5);TEST.flush();assert(snorlax.x==6,'consumed battle anchor cannot undo a later move')
snorlax:SetXY(5,5)
R.battle=nil;attacker:Kill(false,0)
local foe=TEST.new('UNIT_WARRIOR',4,5,1);foe.moves=120
GameEvents.UnitSetXY(1,foe.id,4,5);assert(foe.moves==120,'duplicate position is not ZOC movement')
foe:SetXY(4,6);foe:SetMoves(foe.moves-60);assert(foe.moves==0,'exceptional ZOC and native nonnegative movement')
local venusaur=R.Unit(s,s.slots[2]);local vr=R.Peek(venusaur);vr.identity='VENUSAUR';venusaur:SetXY(8,8)
local friend=TEST.new('UNIT_WARRIOR',8,7);TEST.flush();friend.damage=50
R.PartnerAura(0);assert(friend.damage==40);R.PartnerAura(0);assert(friend.damage==40)
s=TEST.reload();R.PartnerAura(0);assert(friend.damage==40,'Venusaur heal ledger survives reload')
TEST.turn=33;R.PartnerAura(0);assert(friend.damage==30)
local ranged=TEST.new('UNIT_ARCHER',3,8);local rr=R.Record(ranged);rr.identity='CHARIZARD';R.Apply(ranged,rr)
local range;for promo in GameInfo.UnitPromotions() do if promo.Type~='PROMOTION_RED_RANGE' and promo.RangeChange==1 then range=promo.ID;break end end
ranged:SetHasPromotion(range,true);GameEvents.UnitPromoted(0,ranged.id,range)
assert(not ranged:IsHasPromotion(R.Promo('RANGE')),'new native Range immediately removes private grant')
local ok=R.Internal(function() error('injected native failure') end);assert(not ok and R.internal==0)
local recycledID=ranged.id;ranged:Kill(false,1);local nextID=TEST.nextID;TEST.nextID=recycledID
local newborn=TEST.new('UNIT_ARCHER',0,0);TEST.nextID=nextID;TEST.flush()
assert(R.positions['0:'..newborn.id].x==0 and R.Peek(newborn).training==0,'reused native ID has no stale origin or pre-init mutation')
for i=0,Map.GetNumPlots()-1 do Map.GetPlotByIndex(i).blocked=true end
local ocean=Map.GetPlot(3,9);ocean.blocked=false;ocean.water=true;ocean.terrain=GameInfoTypes.TERRAIN_OCEAN
local navalSnapshot={unitType='UNIT_TRIREME',promotions={'PROMOTION_OCEAN_IMPASSABLE'}}
assert(not R.SpawnPlot(0,GameInfoTypes.UNIT_TRIREME,3,9,nil,navalSnapshot),'restored terrain prohibition excludes ocean')
local coast=Map.GetPlot(3,8);coast.blocked=false;coast.water=true;coast.terrain=GameInfoTypes.TERRAIN_COAST
assert(R.SpawnPlot(0,GameInfoTypes.UNIT_TRIREME,3,9,nil,navalSnapshot)==coast,'safe domain-compatible fallback')
navalSnapshot.unitType='UNIT_DESTROYER';navalSnapshot.promotionExpiry={PROMOTION_OCEAN_IMPASSABLE=TEST.turn}
assert(R.SpawnPlot(0,GameInfoTypes.UNIT_DESTROYER,3,9,nil,navalSnapshot)==ocean,'expired terrain prohibition cannot strand a returnee')
print('PASS Red stability: project gates, 1/5/20-city queues, asynchronous/canceled/reloaded airlift, Snorlax safety, aura and promotion idempotence')
