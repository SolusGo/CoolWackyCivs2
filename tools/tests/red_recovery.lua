local R=MapModData.RED_Legend;TEST.flush();local s=R.State(0);local p=Players[0]
p.era=GameInfoTypes.ERA_MODERN;s.full=true;s.manual=true
local originals,saved={},{}
local retained=GameInfoTypes.PROMOTION_DRILL_1;assert(retained)
local invalid=GameInfoTypes.PROMOTION_RANGE;assert(invalid)
local lost
for promo in GameInfo.UnitPromotions() do if promo.LostWithUpgrade==1 and promo.ID~=retained and promo.ID~=invalid then lost=promo.ID;break end end
assert(lost)
for i=1,6 do
 local u=TEST.new('UNIT_WARRIOR',i+1,4);local r=R.Record(u)
 r.training=110+i;r.ribbons=(i-1)%5+1;r.itemReady=50;r.withdrawReady=60
 u.xp=2500+i;u.level=4;u.damage=20+i;u.name='Veteran '..i
 u:SetHasPromotion(retained,true);u:SetHasPromotion(invalid,true);u:SetHasPromotion(lost,true)
 assert(R.Assign(s,u,i));originals[i]=u;saved[r.serial]={training=r.training,ribbons=r.ribbons,xp=u.xp,damage=u.damage}
end
local ace=TEST.new('UNIT_RED_POKEMON_ACE',2,4);TEST.flush();assert(R.Attach(s,originals[1]))
local hostSerial=R.Serial(originals[1]);local token=s.units[hostSerial].ace.token
local oldKill=originals[1].Kill
originals[1].Kill=function(self,...)
 local data=p:GetScriptData();local a,b=data:find('|REDSTATE1:%d+:');local n=tonumber(data:sub(a,b):match(':(%d+):'))
 local committed=R.Decode(data:sub(b+1,b+n));local count=0
 for serial in pairs(committed.silver.snapshots) do count=count+1;assert(committed.units[serial].withdrawn) end
 assert(count==6 and committed.silver.phase=='ABSENT','all snapshots persisted before first kill')
 return oldKill(self,...)
end
local nativeKill=originals[3].Kill
originals[3].Kill=function() error('injected withdrawal interruption') end
assert(R.BeginSilver(s) and R.internal==0);originals[3].Kill=nativeKill
assert(s.silver.due==8);TEST.turn=3;R=TEST.reloadContext();s=R.State(0)
local function military()local n=0;for u in p:Units() do if u:IsCombatUnit() then n=n+1 end end;return n end
assert(s.silver.phase=='ABSENT' and s.silver.due==8 and military()==0,'third-turn reload retires surviving originals')
for i=0,Map.GetNumPlots()-1 do Map.GetPlotByIndex(i).blocked=true end
TEST.turn=8;R.ResumeSilver(s);assert(s.silver.phase=='RETURNING' and military()==0)
Map.GetPlot(4,4).blocked=false;Map.GetPlot(5,4).blocked=false
local nativeTrain=p.CanTrain;p.CanTrain=function(self,id) return GameInfo.Units[id].Type=='UNIT_SWORDSMAN' end
local nativeInit=p.InitUnit
p.InitUnit=function(self,...)
 local u=nativeInit(self,...);u.invalidPromotions={[invalid]=true};return u
end
local restore=R.Restore;local interrupted=false
R.Restore=function(u,snap)
 local result=restore(u,snap)
 if not interrupted then interrupted=true;error('injected return interruption after restore') end
 return result
end
R.ResumeSilver(s);assert(interrupted and R.internal==0 and military()==2)
local journal=s.units[hostSerial].returning;assert(journal and s.units[hostSerial].withdrawn)
local partialID=journal.id
R=TEST.reloadContext();s=R.State(0)
assert(military()==2 and s.units[hostSerial].id==partialID and not s.units[hostSerial].withdrawn,'reload adopts created returnee')
for i=0,Map.GetNumPlots()-1 do Map.GetPlotByIndex(i).blocked=false end
R.ResumeSilver(s);assert(s.silver.phase=='RETURNED' and military()==6)
local names={}
for serial,old in pairs(saved) do
 local r=s.units[serial];local u=R.Unit(s,serial)
 assert(u and r.training==old.training and r.ribbons==old.ribbons and r.summit and R.Rank(r)==4)
 assert(u:GetUnitType()==GameInfoTypes.UNIT_SWORDSMAN and u.xp==old.xp and u.level==4 and u.damage==old.damage,'type/XP/level/damage: '..R.Encode({u:GetUnitType(),u.xp,u.level,u.damage}))
 assert(u:IsHasPromotion(retained) and not u:IsHasPromotion(invalid) and not u:IsHasPromotion(lost),'eligible promotions only on upgraded type')
 assert(r.itemReady==50 and r.withdrawReady==60 and #r.lineage==1 and not names[r.identity]);names[r.identity]=true
 assert(not r.returning and not r.withdrawn)
end
assert(s.units[hostSerial].ace.token==token)
R=TEST.reloadContext();s=R.State(0);assert(military()==6 and not R.SilverEligible(s))
local sample=TEST.new('UNIT_WARRIOR',0,9);local shock=GameInfoTypes.PROMOTION_SHOCK_1
sample:SetHasPromotion(retained,true);sample:SetHasPromotion(shock,true)
local snap=R.Snapshot(sample);snap.promotionExpiry={PROMOTION_DRILL_1=8,PROMOTION_SHOCK_1=10}
local copy=TEST.new('UNIT_SWORDSMAN',0,8);local expiry=R.Restore(copy,snap)
assert(not copy:IsHasPromotion(retained) and copy:IsHasPromotion(shock) and expiry.PROMOTION_SHOCK_1==10,'expired effects excluded; live deadline retained')
local cr=R.Record(copy);cr.promotionExpiry=expiry;TEST.turn=10;R.Apply(copy,cr);assert(not copy:IsHasPromotion(shock))
TEST.turn=8;sample:Kill(false,1);copy:Kill(false,1);TEST.flush()

-- Failure after Ace creation is journaled, and recovery/detach adopt the same General.
restore=R.Restore;interrupted=false
R.Restore=function(u,snap)
 local result=restore(u,snap)
 if u:GetUnitType()==R.ACE and not interrupted then interrupted=true;error('injected Ace restoration interruption') end
 return result
end
R.Unit(s,hostSerial):Kill(false,1);TEST.flush()
local function aces()local n=0;for u in p:Units() do if u:GetUnitType()==R.ACE then n=n+1 end end;return n end
assert(interrupted and aces()==1 and s.rescuedAces[token].returning and R.internal==0)
R=TEST.reloadContext();s=R.State(0);assert(aces()==1 and not s.rescuedAces[token] and military()==5)
TEST.turn=9;for u in p:Units() do if u:GetUnitType()==R.ACE then u:SetMoves(u:MaxMoves()) end end
local host=R.Unit(s,s.slots[2]);host:SetXY(5,4);assert(R.Attach(s,host))
restore=R.Restore;R.Restore=function() error('injected detach interruption') end
assert(not R.Detach(s,host) and R.Peek(host).ace.returning and aces()==1 and R.internal==0)
R=TEST.reloadContext();s=R.State(0);assert(aces()==1 and not R.Peek(host).ace,'detachment resumes without a second Ace')
p.CanTrain=nativeTrain;p.InitUnit=nativeInit
print('PASS Red recovery: committed six-unit withdrawal, third-turn reload, partial-return fault/reload, eligible promotions, exact veteran ledger and Ace fault recovery')
