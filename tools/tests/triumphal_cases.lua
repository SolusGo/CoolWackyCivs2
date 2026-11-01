local T=GameInfoTypes
local checks=0
local function Check(value,label)assert(value,label);checks=checks+1 end
local function Momentum(n)Check(TRI.Momentum(IMP)==n,'Momentum expected '..n..', got '..TRI.Momentum(IMP))end
local nextID=100
local function Enemy(player,kind)nextID=nextID+1;return Unit(player or RIVAL,nextID,kind or T.UNIT_SWORDSMAN)end
local function Kill(player,kind,style,city,dupes)Battle(city and HOME or U,Enemy(player,kind),style,city,dupes)end
local function Tiers(unit,level)
 for i=1,6 do Check(unit:IsHasPromotion(TRI.promotions[i])==(i==level),'obsolete promotion tier')end
end
local function Reload()
 ContextPtr={SetShutdown=function(self,f)self.shutdown=f end}
 LoadPanel()
end

-- Initial state; no unearned empire advantages, free building, or movement.
Momentum(0);Tiers(U,0);Tiers(WORKER,0);Tiers(PLANE,0)
Check(HOME:MilitaryProduction()==0,'initial industry');Check(U:MaxMoves()==120,'initial moves')
Check(U:IsHasPromotion(TRI.advance),'UU native advance')
GameEvents.PlayerDoTurn.Fire(0);Momentum(0)
Check(not Controls.MomentumPanel.hidden,'human Imperium panel missing')
Check(Controls.MomentumTitle.text=='VICTORY MOMENTUM: 0 / 6','UI title')

-- Three distinct normal combat deaths; duplicate callbacks do not create rewards.
Kill(nil,nil,0,false,true);Kill(nil,nil,1);Kill(nil,T.UNIT_FIGHTER,2)
Momentum(3);Tiers(U,3);Tiers(PLANE,3);Tiers(WORKER,0)
Check(HOME:MilitaryProduction()==12,'level 3 industry')
Check(U:MovesLeft()==120,'movement unexpectedly refilled')

-- Major conquest, duplicate capture, exact native Hall, local stacking.
Teams[0].bronze=true
local target=City(RIVAL,10,10,10)
Capture(target,IMP,true);Momentum(5)
Check(target:GetNumRealBuilding(TRI.hall)==1,'free Hall after Bronze')
Check(target:MilitaryProduction()==30,'20 empire + 10 Hall')
GameEvents.CityCaptureComplete.Fire(1,false,10,10,0,5,true);Momentum(5)
Check(U:MaxMoves()==180 and U:MovesLeft()==120,'march refilled moves')
Kill(nil,nil,1,true);Momentum(6);Check(target:MilitaryProduction()==34,'24 empire + 10 Hall')
for i=1,5 do Kill()end;Momentum(6)
Check(#IMP.notices<=2,'gain notification spam')
HOME.buildings[TRI.hall]=1;GameEvents.CityConstructed.Fire(0,1,TRI.hall,false,false)
Check(HOME:MilitaryProduction()==34,'newly constructed Hall did not activate')
HOME.buildings[TRI.hall]=0;GameEvents.CitySoldBuilding.Fire(0,1,TRI.hall)
Check(HOME:MilitaryProduction()==24,'sold Hall retained local industry')
Check(Controls.MomentumPanel.tip:find('Combat Strength: +12%',1,true)~=nil,'wrong tooltip strength')
Check(Controls.MomentumPanel.tip:find('ACTIVE')~=nil,'threshold status missing')

-- Ownership cleanup and recapture farming, including diplomatic transfers.
Capture(target,RIVAL,false)
Check(target:MilitaryProduction()==0,'foreign city retained mobilisation')
Capture(target,IMP,true);Momentum(6)
TRI.Change(IMP,-2,false);Momentum(4)
Capture(target,RIVAL,false);Capture(target,IMP,true);Momentum(4)
local gift=City(RIVAL,11,11,11);Capture(gift,IMP,false);Momentum(4)
Check(gift:GetNumRealBuilding(TRI.hall)==0,'diplomatic Hall')

-- No barbarian, minor, civilian, delete or unmatched prekill reward.
Kill(BARB);Kill(MINOR);Kill(RIVAL,T.UNIT_WORKER);Momentum(4)
local scripted=Enemy();GameEvents.UnitPrekill.Fire(1,scripted.id,scripted.kind,1,1,false,0)
GameEvents.UnitKilledInCombat.Fire(0,1,scripted.kind,-1);Momentum(4)
GameEvents.BattleStarted.Fire(0,1,1)
GameEvents.BattleJoined.Fire(0,U.id,0,false);GameEvents.BattleJoined.Fire(1,scripted.id,1,false)
GameEvents.UnitPrekill.Fire(1,scripted.id,scripted.kind,1,1,false,0) -- full-health script delete
GameEvents.UnitKilledInCombat.Fire(0,1,scripted.kind,-1);GameEvents.BattleFinished.Fire();Momentum(4)
Kill(nil,nil,5);Momentum(5) -- native attributed military nuclear combat death
TRI.Change(IMP,-1,false)
Kill(nil,T.UNIT_ATOMIC_BOMB,5);Momentum(5) -- nuclear payloads are military, not civilians
TRI.Change(IMP,-1,false)
Teams[0].peace[4]=true;Kill(OTHER,nil,5);Momentum(4) -- no friendly/neutral blast rewards

-- Persistence reconstruction and exactly one registered handler per native event.
local playerData=IMP.data;Reload();Momentum(4)
Check(IMP.data==playerData,'reload changed authoritative state')
Check(GameEvents.UnitKilledInCombat.Count()==1,'duplicate subscriptions')
Check(GameEvents.PlayerDoTurn.Count()==1,'duplicate turn subscriptions')
LoadPanel();Check(GameEvents.UnitKilledInCombat.Count()==1,'same-context reload resubscribed')
Events.LoadScreenClose.Fire();Momentum(4);Tiers(U,4)
Check(IMP.data:find('FOREIGN_PLAYER',1,true)==1,'foreign player metadata overwritten')
Check(target:Plot().data:find('FOREIGN_PLOT',1,true)==1,'foreign plot metadata overwritten')

-- Complete cycle, defence during opponents' turns, reload and duplicate turns.
SetTurn(1);GameEvents.PlayerDoTurn.Fire(0);Momentum(4) -- victory occurred during preceding cycle
SetTurn(2);GameEvents.PlayerDoTurn.Fire(0);Momentum(3)
Check(not U:IsHasPromotion(TRI.march),'march retained below threshold')
Check(target:MilitaryProduction()==12,'obsolete Hall or empire industry')
GameEvents.PlayerDoTurn.Fire(0);Momentum(3);Reload();Momentum(3)
-- Defender destroys attacking rival: roles reversed relative to ordinary helper.
local attacker=Enemy()
GameEvents.BattleStarted.Fire(0,1,1);GameEvents.BattleJoined.Fire(1,attacker.id,0,false)
GameEvents.BattleJoined.Fire(0,U.id,1,false);attacker.damage=100
GameEvents.UnitPrekill.Fire(1,attacker.id,attacker.kind,1,1,true,0)
GameEvents.UnitKilledInCombat.Fire(0,1,attacker.kind,-1);GameEvents.BattleFinished.Fire()
Momentum(4);SetTurn(3);GameEvents.PlayerDoTurn.Fire(0);Momentum(4)
for n=4,8 do SetTurn(n);GameEvents.PlayerDoTurn.Fire(0)end;Momentum(0)
Check(target:MilitaryProduction()==0,'decay did not clear all dummies')
Check(not U:IsHasPromotion(TRI.march),'movement permanent')

-- Pending Hall, late research, loss, liberation, razing and founded replacements.
Teams[0].bronze=false
local waiting=City(RIVAL,12,12,12);Capture(waiting,IMP,true);Momentum(2)
Check(waiting:GetNumRealBuilding(TRI.hall)==0,'pre-Bronze Hall')
Reload();Check(TRI.Get(waiting:Plot(),'HALL')~=nil,'pending Hall lost on load')
local lost=City(RIVAL,13,13,13);Capture(lost,IMP,true);Capture(lost,RIVAL,false)
Check(TRI.Get(lost:Plot(),'HALL')==nil,'lost pending Hall not cleared')
local razed=City(RIVAL,14,14,14);Capture(razed,IMP,true)
IMP.cities[razed.id]=nil;razed:Plot().city=nil
local replacement=City(IMP,15,14,14);GameEvents.PlayerCityFounded.Fire(0,14,14)
Teams[0].bronze=true;GameEvents.TeamTechResearched.Fire(0,T.TECH_BRONZE_WORKING,1)
Check(waiting:GetNumRealBuilding(TRI.hall)==1,'late Hall missing')
Check(lost:GetNumRealBuilding(TRI.hall)==0,'Hall granted abroad')
Check(replacement:GetNumRealBuilding(TRI.hall)==0,'razed city eligibility leaked')
Check(HOME:GetNumRealBuilding(TRI.hall)==0,'founded city free Hall')
GameEvents.TeamTechResearched.Fire(0,T.TECH_BRONZE_WORKING,1)
Check(waiting:GetNumRealBuilding(TRI.hall)==1,'duplicated free Hall')

-- New and upgraded units; permanent attack retained, original-type march removed.
TRI.Change(IMP,6,true)
local purchased=Unit(IMP,20,T.UNIT_TRI_UNBROKEN);purchased.moves=60
GameEvents.UnitCreated.Fire(0,20);Tiers(purchased,6)
Check(purchased:MovesLeft()==60,'new unit movement replenished')
local foreignGift=Unit(OTHER,24,T.UNIT_TRI_UNBROKEN);foreignGift.moves=180
GameEvents.UnitConverted.Fire(0,4,20,24,false)
Check(foreignGift:MovesLeft()==120,'native gift copied temporary excess moves')
Check(not foreignGift:IsHasPromotion(TRI.march),'foreign gift retains march')
Check(foreignGift:IsHasPromotion(TRI.advance),'foreign gift lacks unique attack')
local upgrade=Unit(IMP,21,T.UNIT_LONGSWORDSMAN)
upgrade.promotions[TRI.advance]=true;upgrade.promotions[TRI.march]=true
upgrade.promotions[TRI.promotions[5]]=true
GameEvents.UnitConverted.Fire(0,0,20,21,true);Tiers(upgrade,6)
Check(upgrade:IsHasPromotion(TRI.advance),'permanent advance lost')
Check(not upgrade:IsHasPromotion(TRI.march),'upgrade retains original type movement')
IMP.units[21]=nil;OTHER.units[21]=upgrade;upgrade.owner=4
GameEvents.UnitConverted.Fire(0,4,21,21,false);Tiers(upgrade,0)
Check(upgrade:IsHasPromotion(TRI.advance),'gift lost permanent unique ability')
OTHER.units[21]=nil;IMP.units[21]=upgrade;upgrade.owner=0
GameEvents.UnitSetXY.Fire(0,21,3,3);Tiers(upgrade,6)
-- Unrelated movement promotion is retained when march is removed.
U.promotions[T.PROMOTION_SCOUTING_3]=true
local independentMoves=U:MaxMoves()-60
TRI.Change(IMP,-3,false)
Check(U:IsHasPromotion(T.PROMOTION_SCOUTING_3),'unrelated move promotion removed')
Check(U:MaxMoves()==independentMoves,'unrelated movement altered')

-- Correct UI ownership and screen transitions, hidden dummy construction.
SetActive(4);Check(Controls.MomentumPanel.hidden,'foreign panel visible')
SetActive(5);Check(Controls.MomentumPanel.hidden,'AI panel visible')
SetActive(0);Check(not Controls.MomentumPanel.hidden,'Imperium panel missing')
Events.SerialEventEnterCityScreen.Fire();Check(Controls.MomentumPanel.hidden,'city screen overlap')
Events.SerialEventExitCityScreen.Fire();Check(not Controls.MomentumPanel.hidden,'city screen recovery')
Check(Controls.Laurel3.alpha==1 and Controls.Laurel4.alpha==0.18,'incorrect six segments')
Check(Controls.MomentumPanel.tip:find('INACTIVE',1,true)~=nil,'inactive status missing')
for i=1,6 do Check(GameEvents.CityCanConstruct.Fire(0,1,TRI.buildings[i])==false,'constructible dummy')end
Check(GameEvents.CityCanConstruct.Fire(0,1,TRI.hallActive)==false,'constructible Hall dummy')
Check(GameEvents.CityCanConstruct.Fire(0,1,TRI.hall)==true,'Hall hidden from production')
Check(TRI.Momentum(AIIMP)==0,'AI got Momentum')
-- Explicit save-at-five reconstruction, and free/native-start Hall presence.
TRI.Change(IMP,2,true);Momentum(5)
local snapshot=IMP.data;Reload();Momentum(5);Check(IMP.data==snapshot,'save-at-five mutated')
Tiers(U,5);Check(target:MilitaryProduction()==30,'save-at-five modifiers duplicated')
HOME.freeBuildings={[TRI.hall]=1};TRI.SyncCity(HOME)
Check(HOME:GetNumRealBuilding(TRI.hall)==0,'free Hall duplicated as real Hall')
Check(HOME:MilitaryProduction()==30,'native free Hall not detected')
-- A late-era initial turn never invents a completed inactivity cycle.
SetTurn(300);local late=Player(6,T.CIVILIZATION_TRIUMPHAL_IMPERIUM)
local lateCity=City(late,30,30,30);Teams[6].bronze=true
Reload();Check(TRI.Momentum(late)==0,'late start momentum');GameEvents.PlayerDoTurn.Fire(6)
Check(TRI.Momentum(late)==0,'late first-turn decay');Check(lateCity:MilitaryProduction()==0,'late unearned industry')
CHECK_COUNT=checks
