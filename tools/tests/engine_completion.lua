-- Tests mod decisions against modeled native boundaries, not a live game.
local B=MapModData.BoundlessCity;local s=B.State(0)
local function survives(units,trait,completeKills,maxElimination)
 return not (maxElimination or units==0 or (not completeKills and not trait))
end
assert(survives(3,true,false,false) and not survives(3,false,false,false))
assert(not survives(0,true,false,false) and not survives(3,true,false,true))
local unit=MakeUnit(40,600);unit.moves=60
function unit:GetX() return self.x or 59 end;function unit:GetY() return self.y or 5 end
function unit:MovesLeft() return self.moves end
local n=Map.GetPlot(60,5).n;foreign.damage=199
Players[2].everAlive=false -- one actual rival, rather than an unfounded test slot
local nativeAlive=Players[0].IsAlive
Players[0].IsAlive=function(self) return self.alive~=false end
-- All protection/military failures must retain ownership and NoCapture.
for _,flag in ipairs({'defensive','outOfAttacks','dead'}) do
 unit[flag]=true;assert(not B.MilitaryCheck(s,n),flag);unit[flag]=false
end
unit.domain=DomainTypes.DOMAIN_AIR;assert(not B.MilitaryCheck(s,n))
unit.domain=DomainTypes.DOMAIN_SEA;assert(not B.MilitaryCheck(s,n))
Map.GetPlot(60,5).coastal=true;assert(B.MilitaryCheck(s,n));unit.domain=0
local peace=Teams[0].IsAtWar;Teams[0].IsAtWar=function() return false end
assert(not B.QueueSiege(s,n));Teams[0].IsAtWar=peace
foreign.damage=198;assert(not B.QueueSiege(s,n));foreign.damage=199
Map.GetPlot(60,5).visible=false;assert(not B.QueueSiege(s,n));Map.GetPlot(60,5).visible=true
-- Saved queue survives reload; capital remains protected, no capture/rewards.
assert(B.QueueSiege(s,n));assert(s.sieges[n].action=='SUBJUGATE')
B.States={};B.Caches={};s=B.State(0);B.ProcessSieges(s)
assert(foreign.owner==1 and unit.moves==0 and s.subjugated[n].capital and cultureAward==0)
assert(winner==0 and winnerCalls==1 and victory==2,'native Domination setter used once for Boundless only')
unit.moves=60;assert(not B.QueueSiege(s,n));assert(not B.CheckDomination(s) and winnerCalls==1)
foreign.owner=2;local formerID=foreign.id;foreign.id=foreign.id+30
local done,total,valid=B.DominationProgress(s)
assert(done==1 and total==1 and valid and not B.QueueSiege(s,n),'native owner/city-ID transfer retains one-time original progress')
foreign.owner=1;foreign.id=formerID
Map.GetPlot(60,5).city=nil;local _,_,missingValid=B.DominationProgress(s);assert(not missingValid);Map.GetPlot(60,5).city=foreign
-- Disable flag and existing winner prevent overwrite. Missing/replaced capitals
-- and unfounded ever-alive rivals cannot be silently excluded.
winner=nil;victory=nil;dominationEnabled=false;assert(not B.CheckDomination(s))
Map.GetPlot(60,5).city=nil;assert(not B.CheckDomination(s));Map.GetPlot(60,5).city=foreign
dominationEnabled=true;B.Config.SubjugationDomination=false;assert(not B.CheckDomination(s));B.Config.SubjugationDomination=true
Players[2].everAlive=true;assert(not B.CheckDomination(s));Players[2].everAlive=false
foreign.founded=1;assert(not B.CheckDomination(s));foreign.founded=0
local oldOriginal=foreign.original;foreign.original=2;assert(not B.CheckDomination(s));foreign.original=oldOriginal
-- Ordinary own-founded cities can be acknowledged once, never raw-disbanded.
winner=1;victory=3
local town=MakeCity(1,16,5,3,2);town.original=1;town.damage=199
Players[1].cities[#Players[1].cities+1]=town;unit.x=15
assert(not B.SiegeCheck(s,Map.GetPlot(16,5).n));assert(B.QueueSiege(s,Map.GetPlot(16,5).n));Pump()
assert(town.owner==1 and s.subjugated[Map.GetPlot(16,5).n] and winner==1 and cultureAward==0)
unit.moves=60;assert(not B.QueueSiege(s,Map.GetPlot(16,5).n))
Players[1].minor=true;local ok,_,reason=B.MilitaryCheck(s,n);assert(not ok and reason=='SIEGE_CITY_STATE');Players[1].minor=false
town.original=3;assert(not B.MilitaryCheck(s,Map.GetPlot(16,5).n),'barbarian-founded settlement is not a major subjugation target');town.original=1
-- Current owner/ID/actor birth/peace changes invalidate a deferred action.
local replacement=MakeCity(1,18,5,3,2);replacement.original=1;replacement.damage=199
unit.x=17;local replacementN=Map.GetPlot(18,5).n
assert(B.QueueSiege(s,replacementN));unit.GetGameTurnCreated=function() return 2 end;Pump()
assert(not s.subjugated[replacementN] and unit.moves==60);unit.GetGameTurnCreated=function() return 0 end
-- Model native source rebuilding and the native capture hook, separately from
-- the simple transfer helper used by earlier suites.
local acquire=Players[0].AcquireCity
local function nativeTransfer(pid,city,conquest,gift)
 local old=city.owner;city.terrain={};city.misc={}
 acquire(Players[pid],city,conquest,gift)
 Map.GetPlot(city.x,city.y).owner=pid
 insideCapture=true;GameEvents.CityCaptureComplete.Fire(old,true,city.x,city.y,pid);insideCapture=false
end
local remote=Remote(25,5,{4,3,2,1,2,1});s.mode='MANUAL';s.selected={[remote.n]=true};s.progress=999;s.rewards[remote.n]=true
B.Cache(s).force=true;B.Reconcile(s);local gross=B.Cache(s).remoteYields[1]
nativeTransfer(1,capital,true,false);Pump()
assert(not B.City(s) and next(s.assignments)==nil and s.progress==999 and s.selected[remote.n])
unit.x=2;capital.damage=199
assert(B.MilitaryCheck(s,Map.GetPlot(3,5).n))
unit:SetHasPromotion(301,true);assert(not B.MilitaryCheck(s,Map.GetPlot(3,5).n),'other native NoCapture promotions still prohibit reclaim')
unit:SetHasPromotion(301,false)
assert(not B.MilitaryCheck(s,n),'foreign city cannot be reclaimed while capital lost')
capital.original=1;assert(not B.MilitaryCheck(s,Map.GetPlot(3,5).n));capital.original=0
capital.founded=3;assert(not B.MilitaryCheck(s,Map.GetPlot(3,5).n));capital.founded=0
capital.originalCapital=false;assert(not B.MilitaryCheck(s,Map.GetPlot(3,5).n));capital.originalCapital=nil
Players[0].alive=false;assert(not B.QueueSiege(s,Map.GetPlot(3,5).n),'eliminated player cannot reclaim');Players[0].alive=true
-- A second externally transferred city blocks reclaim until recovered.
Players[0].cities={replacement};assert(not B.MilitaryCheck(s,Map.GetPlot(3,5).n));Players[0].cities={}
Players[0].AcquireCity=function(self,c,conquest,gift) nativeTransfer(self.pid,c,conquest,gift) end
assert(B.Action(0,'SIEGE',Map.GetPlot(3,5).n));B.Save(s);B.States={};B.Caches={};s=B.State(0);Pump()
assert(B.City(s)==capital and Players[0]:GetNumCities()==1 and Players[0].lastAcquire.conquest and not Players[0].lastAcquire.gift)
assert(s.progress==999 and s.rewards[remote.n] and s.selected[remote.n] and unit.moves==0)
assert(B.Cache(s).remoteYields[1]==gross and capital.terrain[0]==gross,'one rebuilt remote ledger')
B.NoCapture(0,unit);assert(unit:IsHasPromotion(300));Players[0].AcquireCity=acquire
-- Refresh derived Tourism without adding another culture/tourism source.
capital.landmarkPercent=100;B.ApplyLedger(capital,{0,0,0,0,7,0},{})
assert(capital.tourism==capital:GetBaseYieldRateFromTerrain(4)*100)
local nativeCulture=capital:GetBaseYieldRateFromTerrain(4)-7
B.ApplyLedger(capital,{},{})
assert(capital.tourism==nativeCulture*100 and capital:GetBaseYieldRateFromTerrain(4)==nativeCulture)
local refresh=capital.RefreshTourism;local refreshFailed=false
capital.RefreshTourism=function(self)
 refresh(self);if not refreshFailed then refreshFailed=true;error('fault after native Tourism refresh') end
end
B.Cache(s).force=true;assert(not B.Reconcile(s) and s.phase=='RECOVER')
assert(capital.terrain[4]==0 and capital.tourism==capital:GetBaseYieldRateFromTerrain(4)*100,'failed derived refresh cleans known sources')
capital.RefreshTourism=refresh
-- Only assigned remotes develop, at most once per owner turn and across reload.
B.Cache(s).force=true;B.Reconcile(s);remote.improvement=500
GameInfo.Improvements[500]={ID=500,ImprovementUpgrade='IMPROVEMENT_UPGRADED'}
GameInfo.Improvements.IMPROVEMENT_UPGRADED={ID=501}
local idle=Remote(26,5);idle.improvement=500
now=4;B.DevelopRemotePlots(s);assert(remote:GetUpgradeProgress()==100 and idle:GetUpgradeProgress()==0)
B.States={};B.Caches={};B.Initialize(0);s=B.State(0);B.DevelopRemotePlots(s);assert(remote:GetUpgradeProgress()==100)
s.selected={};B.Cache(s).force=true;B.Reconcile(s);now=5;B.DevelopRemotePlots(s);assert(remote:GetUpgradeProgress()==100)
s.selected={[remote.n]=true};B.Cache(s).force=true;B.Reconcile(s);now=6;B.DevelopRemotePlots(s)
assert(remote.improvement==501 and remote:GetUpgradeProgress()==0 and idle.improvement==500)
remote.improvement=500;remote.upgradeProgress=0;capital.worked[remote.n]=true;now=7
B.DevelopRemotePlots(s);assert(remote:GetUpgradeProgress()==0,'native worked plot never receives an additional development step')
capital.worked[remote.n]=nil
-- Extra-city route/territory guards apply even before deferred quarantine.
local extra=MakeCity(0,50,12,2,2);extra.original=1;Players[0].cities[#Players[0].cities+1]=extra
assert(not GameEvents.CityCanAcquirePlot.Test(0,extra.id,51,12))
assert(GameEvents.CityCanAcquirePlot.Test(0,capital.id,4,5))
assert(not GameEvents.PlayerCanCreateTradeRoute.Test(0,extra.id,1,foreign.id,0,0))
assert(not GameEvents.PlayerCanCreateTradeRoute.Test(1,foreign.id,0,extra.id,0,0))
assert(GameEvents.PlayerCanCreateTradeRoute.Test(0,capital.id,1,foreign.id,0,0))
assert(GameEvents.PlayerCanCreateTradeRoute.Test(1,foreign.id,2,replacement.id,0,0),'unrelated civilizations pass through')
-- AI resolves a newly defeated adjacent city through the same deferred rules,
-- including after native movement, rather than polling every frame.
local aiCity=MakeCity(1,20,5,3,2);aiCity.original=1;aiCity.damage=199
Players[1].cities[#Players[1].cities+1]=aiCity;unit.x=19;unit.moves=60;Players[0].human=false
B.Movement(0,unit.id,19,5);Pump();Pump()
assert(s.subjugated[Map.GetPlot(20,5).n] and aiCity.owner==1 and unit.moves==0)
assert(deferred==nil and winner==1,'AI shares rules and leaves no idle polling/winner overwrite')
Players[0].IsAlive=nativeAlive
print('PASS military reclaim identity/dead-player/reload; protected subjugation/no rewards; scoped native victory; Tourism refresh; assigned-only development')
