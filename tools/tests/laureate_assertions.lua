local function Scale(n) return math.floor(n*SPEED/100) end
local civ=GameInfoTypes
local vet,person,crown=civ.PROMOTION_LAUREL_LEVEL_REWARDED,civ.PROMOTION_LC_PERSON_RECOGNIZED,civ.PROMOTION_CROWNING_BLOW
local city=City(P,1,0)
GameInfo.BuildingClasses.WORLD={MaxGlobalInstances=1,MaxTeamInstances=-1,MaxPlayerInstances=-1}
GameInfo.BuildingClasses.NATIONAL={MaxGlobalInstances=-1,MaxTeamInstances=-1,MaxPlayerInstances=1}
GameInfo.BuildingClasses.TEAM={MaxGlobalInstances=-1,MaxTeamInstances=1,MaxPlayerInstances=-1}
for id,cls in ipairs({'WORLD','WORLD','NATIONAL','TEAM'}) do
 GameInfo.Buildings[id]={BuildingClass=cls,Description='Wonder '..id};city.buildings[id]=1
end
GameEvents.CityConstructed.Fire(0,1,1);Check(Scale(40),'Ancient wonder')
GameEvents.CityConstructed.Fire(0,1,1);Check(Scale(40),'duplicate completion')
P.era=2;GameEvents.CityConstructed.Fire(0,1,2);Check(Scale(40)+Scale(60),'Medieval wonder')
GameEvents.CityConstructed.Fire(0,1,3);GameEvents.CityConstructed.Fire(0,1,4)
GameEvents.CityConstructed.Fire(1,1,1);GameEvents.CityConstructed.Fire(0,999,2)
local total=Scale(40)+Scale(60);Check(total,'national/team/foreign/invalid reject')
Reload();GameEvents.CityConstructed.Fire(0,1,2);Check(total,'wonder reload')
-- All nine native GP classes, faith purchase, free creation, delayed and consumed birth.
for i=1,9 do
 local u=Spawn(P,100+i,1000+i,true)
 assert(P.meter==total*100,'creation must await conversion filtering')
 if i%2==0 then GameEvents.CityTrained.Fire(0,1,u.id,false,true)
 elseif i==9 then GameEvents.UnitPrekill.Fire(0,u.id,u.kind,4,6,true,-1);P.units[u.id]=nil
 else GameEvents.PlayerDoneTurn.Fire(0) end
 total=total+Scale(30);Check(total,'GP era reward '..i)
 GameEvents.PlayerDoneTurn.Fire(0);Check(total,'duplicate GP owner-end')
end
local fresh=Spawn(P,150,1001,true);P.era=5;Reload()
GameEvents.PlayerDoneTurn.Fire(0);total=total+Scale(30);Check(total,'birth-era reward survives reload/era change')
GameEvents.UnitCreated.Fire(0,150,1001,4,6);GameEvents.PlayerDoneTurn.Fire(0);Check(total,'duplicate created callback')
local f=Spawn(F,200,1001,true)
Capture(F,P,200,201);GameEvents.PlayerDoneTurn.Fire(0);Check(total,'captured GP rejected')
-- Original-owner check alone fails recapture. Exercise a full return to creator.
Capture(P,F,150,202);Capture(F,P,202,203);GameEvents.PlayerDoneTurn.Fire(0);Check(total,'recapture by original owner rejected')
local genuine=Spawn(P,210,1002,true)
local replacement=Convert(P,P,210,211,1002,true)
total=total+Scale(45);GameEvents.PlayerDoneTurn.Fire(0);Check(total,'upgrade settles birth exactly once')
replacement=Convert(P,F,211,212,1002,false)
replacement=Convert(F,P,212,213,1002,false)
GameEvents.PlayerDoneTurn.Fire(0);Check(total,'converted/gifted return rejected')
-- Loading an already-existing unrecognized GP does not invent a birth event.
Unit(P,220,1003,true);Reload();GameEvents.PlayerDoneTurn.Fire(0);Check(total,'existing GP not retroactively rewarded')
-- Recognition is once per lifetime, including upgrades, combat captures and gifts.
P.era=2
local soldier=Spawn(P,300,2,false,2)
GameEvents.CityTrained.Fire(0,1,300)
GameEvents.UnitPromoted.Fire(0,300,5);Check(total,'level two')
soldier.level=3;GameEvents.UnitPromoted.Fire(0,300,6);total=total+Scale(14);Check(total,'level three')
soldier.level=6;GameEvents.UnitPromoted.Fire(0,300,7);Check(total,'further promotions')
soldier.promotions[crown]=true
soldier=Convert(P,P,300,301,3,true)
assert(soldier.promotions[crown] and soldier.promotions[vet]);Check(total,'upgrade marker persistence')
soldier=Capture(P,F,301,302);GameEvents.PlayerDoneTurn.Fire(1)
assert(soldier.promotions[vet],'capture to foreign owner retains marker')
soldier=Capture(F,P,302,303);GameEvents.PlayerDoneTurn.Fire(0)
GameEvents.UnitPromoted.Fire(0,303,8);Check(total,'capture return no farm')
soldier=Convert(P,F,303,304,3,false);soldier=Convert(F,P,304,305,3,false);Check(total,'transfer no farm')
local navy=Spawn(P,310,4,false,3);GameEvents.CityTrained.Fire(0,1,310);total=total+Scale(14)
local civilian=Spawn(P,311,99,false,4);GameEvents.UnitPromoted.Fire(0,311,3);Check(total,'civilian excluded')
local direct=Spawn(P,312,2,false,1);direct.level=3
local dead=Spawn(P,313,2,false,3);dead.dead=true
GameEvents.PlayerDoTurn.Fire(0);total=total+Scale(14);Check(total,'direct SetLevel fallback, dead excluded')
Reload();GameEvents.PlayerDoTurn.Fire(0);Check(total,'reload markers prevent repeat')
-- Halls: native-active count, no duplicate turn processing or inappropriate states.
city.halls=1;City(P,2,1);City(P,3,1);NextTurn();GameEvents.PlayerDoTurn.Fire(0)
total=total+3;Check(total,'three halls')
Reload();GameEvents.PlayerDoTurn.Fire(0);GameEvents.PlayerDoTurn.Fire(0);Check(total,'same-turn reload')
P.cities[2].halls=0;P.cities[3].resistance=true;NextTurn();GameEvents.PlayerDoTurn.Fire(0)
total=total+1;Check(total,'destroyed/resistance')
city.razing=true;NextTurn();GameEvents.PlayerDoTurn.Fire(0);Check(total,'razing')
city.razing=false;P.anarchy=true;NextTurn();GameEvents.PlayerDoTurn.Fire(0);Check(total,'anarchy')
P.anarchy=false;P.cities[3].resistance=false
-- Golden Age toggles use real policy numeric values injected from executed SQL.
local notices=#P.notices;GoldenStart(P)
assert(P.gpModifier==15 and P.xpModifier==15 and F.gpModifier==0)
assert(#P.notices==notices+1)
local writes=P.policyWrites;GameEvents.PlayerGoldenAge.Fire(0,true,5)
assert(P.policyWrites==writes and #P.notices==notices+1,'extension must not stack or notify')
Reload();assert(P.gpModifier==15 and P.xpModifier==15 and #P.notices==notices+1,'load during GA')
NextTurn();GameEvents.PlayerDoTurn.Fire(0);total=total+2;Check(total,'Halls during Golden Age')
P.ga=false;GameEvents.PlayerGoldenAge.Fire(0,false,0)
assert(P.gpModifier==0 and P.xpModifier==0);Reload();assert(P.gpModifier==0,'outside GA reload')
assert(not GameEvents.PlayerCanAdoptPolicy.Fire(1,30),'ordinary civilizations cannot adopt dummy')
assert(GameEvents.PlayerCanAdoptPolicy.Fire(1,999),'ordinary policies unaffected')
assert(P.data:find('OTHER_PLAYER_DATA',1,true) and soldier.data:find('OTHER_UNIT_DATA',1,true),'foreign ScriptData preserved')
assert(not F.data:find('[LC1_GOLDEN=',1,true),'foreign capture receipts never grant Golden Age modifiers')
local count=GameEvents.PlayerDoTurn.Count();LoadController();assert(GameEvents.PlayerDoTurn.Count()==count,'duplicate init')
Reload();assert(GameEvents.PlayerDoTurn.Count()==count,'retire old context')
-- Several achievements can cross the native threshold without custom GA turns.
P.meter=0;P.era=0;P.cities[1].halls=0;P.cities[3].halls=0
local a=Spawn(P,400,1001,true);local b=Spawn(P,401,2,false,3)
GameEvents.UnitPromoted.Fire(0,401,1);GameEvents.PlayerDoneTurn.Fire(0)
Check(Scale(20)+Scale(10),'same-turn distinct achievements')
assert(not P.ga,'controller must leave threshold processing to native engine')
NativeGoldenStep(P,Scale(20)+Scale(10)-1);Check(1,'native overflow retained')
assert(P.ga and P.gpModifier==15 and P.xpModifier==15)
-- Work stays bounded: one unit sweep per player-turn event, owner-end only pending IDs.
local sweeps=P.unitSweeps;GameEvents.PlayerDoneTurn.Fire(0);assert(P.unitSweeps==sweeps)
print('PASS Laureate shipped Lua: speed '..SPEED..', achievements, conversions, captures, saves, Halls, GA lifecycle and isolation')

-- Isolated hardening cases execute the same loaded production controller. The
-- mock's movement and combat capture paths follow different native snapshots.
local cases=0
local function Case(name,fn)
 P=Player(0,1);F=Player(1,2);Q=Player(2,1);P.era=2
 Reload();fn();cases=cases+1
end
local function Done(pid) GameEvents.PlayerDoneTurn.Fire(pid or 0) end
local function Promote(u,level) u.level=level;GameEvents.UnitPromoted.Fire(u.owner,u.id,777) end
local function Trained(id,level)
 local u=Spawn(P,id,2,false,level);GameEvents.CityTrained.Fire(0,1,id);return u
end
local function MeterZero() Check(0) end
Case('1 foreign Level 4 military capture conversion',function()
 Unit(F,700,2,false,4);local u=Convert(F,P,700,701,2,false)
 MeterZero();GameEvents.PlayerDoTurn.Fire(0);Promote(u,5);Done();MeterZero()
end)
Case('2 foreign Level 3 gift',function()
 Unit(F,700,2,false,3);local u=Convert(F,P,700,701,2,false,function(a,b)
  GameEvents.UnitPromoted.Fire(0,b.id,777);MeterZero()
 end)
 MeterZero();Done();Promote(u,4);MeterZero()
end)
Case('3 acquired Level 2 can genuinely progress',function()
 Unit(F,700,2,false,2);local gift=Convert(F,P,700,701,2,false)
 Reload();Promote(gift,3);Check(Scale(14))
 Unit(F,702,2,false,2);local captured=Capture(F,P,702,703)
 Done();Promote(captured,2);Promote(captured,3);Check(2*Scale(14))
end)
Case('4 foreign veteran cannot farm after capture resets level',function()
 for i=0,1 do
  Unit(F,700+2*i,2,false,3+i)
  local u=Capture(F,P,700+2*i,701+2*i,nil,nil,i==1)
  assert(u.level==1,'native capture does not copy the old level')
  Done();Promote(u,3);Promote(u,4);MeterZero()
 end
end)
Case('5 legitimate native birth at Level 3, pending save and purchase',function()
 local u=Spawn(P,700,2,false,3);MeterZero();Reload();Done();Check(Scale(14))
 GameEvents.UnitCreated.Fire(0,700);Done();Check(Scale(14))
 Trained(701,3);Check(2*Scale(14));Done();Check(2*Scale(14))
end)
Case('6 normal Level 2 to 3',function()
 local u=Trained(700,2);Promote(u,3);Check(Scale(14))
end)
Case('7 subsequent Level 3 to 4',function()
 local u=Trained(700,3);P.meter=0;Promote(u,4);Done();MeterZero()
end)
Case('8 rewarded veteran capture and return',function()
 local u=Trained(700,3);P.meter=0
 for i=0,3 do
  u=Capture(P,F,u.id,710+i*2);Done(1);assert(u.promotions[vet])
  u=Capture(F,P,u.id,711+i*2);Done();assert(u.promotions[vet])
  Promote(u,3);Reload();Done();MeterZero()
 end
end)
Case('9 rewarded Champion upgrade including context replacement',function()
 local u=Trained(700,3);u.promotions[crown]=true;P.meter=0
 u=Convert(P,P,700,701,3,true,function() Reload();MeterZero() end)
 assert(u.promotions[crown] and u.promotions[vet]);Done();MeterZero()
end)
Case('10 acquired veteran save/reload remains closed',function()
 Unit(F,700,2,false,4);local u=Capture(F,P,700,701,nil,function() Reload();MeterZero() end,true)
 Reload();Done();Promote(u,3);Reload();GameEvents.PlayerDoTurn.Fire(0);MeterZero()
end)
Case('11 legitimate recognition remains paid across reload',function()
 local u=Trained(700,3);P.meter=0
 for i=1,3 do Reload();GameEvents.PlayerDoTurn.Fire(0);Promote(u,3+i);Done();MeterZero() end
end)
Case('12 duplicate conversion and capture callbacks',function()
 Unit(F,700,2,false,3)
 local u=Convert(F,P,700,701,2,false,function(a,b)
  GameEvents.UnitConverted.Fire(1,0,a.id,b.id,false)
  GameEvents.UnitConverted.Fire(1,0,a.id,b.id,false)
 end)
 GameEvents.UnitConverted.Fire(1,0,700,701,false);Done();MeterZero()
 Unit(F,702,2,false,4)
 u=Capture(F,P,702,703,function(a)
  GameEvents.UnitCaptured.Fire(0,999,1,a.id,false,0)
 end,function(a,b) GameEvents.UnitCreated.Fire(0,b.id);GameEvents.UnitCreated.Fire(0,b.id) end)
 Done();Promote(u,4);MeterZero()
end)
Case('13 same-class unrelated creation cannot consume capture identity',function()
 Unit(F,700,2,false,4)
 local own
 local acquired=Capture(F,P,700,701,function() own=Spawn(P,702,2,false,3) end,
  function() Spawn(P,703,2,false,3) end)
 MeterZero();Done();Check(2*Scale(14));assert(own.promotions[vet] and not acquired.promotions[vet])
 Promote(acquired,4);Check(2*Scale(14))
end)
Case('14 native unit ID reuse is a fresh lifetime',function()
 local old=Trained(700,2)
 GameEvents.UnitPrekill.Fire(0,700,2,4,6,false,-1);P.units[700]=nil
 local fresh=Trained(700,3);Check(Scale(14));assert(fresh.promotions[vet])
 GameEvents.UnitConverted.Fire(1,0,999,700,false);Done();Check(Scale(14))
end)
Case('legacy migration keeps old markers and rejects unprovable high levels',function()
 local native=Unit(P,700,2,false,4)
 local foreign=Unit(P,701,2,false,4);foreign.original=1
 local paid=Unit(P,702,2,false,3);paid.promotions[vet]=true
 local low=Unit(P,703,2,false,2)
 Reload();GameEvents.PlayerDoTurn.Fire(0);MeterZero()
 Promote(native,5);Promote(foreign,5);Promote(paid,4);MeterZero()
 Promote(low,3);Check(Scale(14))
end)
Case('eligible direct level change remains earned through a save',function()
 local u=Trained(700,2);u.level=3;Reload();MeterZero()
 GameEvents.PlayerDoTurn.Fire(0);Check(Scale(14));Reload();Done();Check(Scale(14))
end)
Case('foreign progression permanently closes inherited low-level eligibility',function()
 local u=Trained(700,2);u=Convert(P,F,700,701,2,false);Promote(u,3)
 u.level=2 -- even a subsequent scripted level decrease cannot reopen history
 u=Convert(F,P,701,702,2,false);Promote(u,3);Done();MeterZero()
end)
Case('capture identity restores nonzero ScenarioData and tolerates a failed capture',function()
 local u=Unit(F,700,2,false,4);u.scenario=731
 u=Capture(F,P,700,701);assert(u.scenario<0,'capture temporarily carries a native identity tag')
 Reload();Done();assert(u.scenario==731,'preexisting ScenarioData must be restored');MeterZero()
 local survivor=Unit(F,702,2,false,4);survivor.scenario=947
 GameEvents.UnitCaptured.Fire(0,999,1,702,false,0)
 assert(survivor.scenario<0);Done()
 assert(survivor.scenario==947 and not survivor.data:find('[LC1_BRIDGE=',1,true))
 assert(not F.data:match('%[LC1_C%d+='),'resolved/unused receipts are removed')
end)
Case('delayed death retains identity until the final capture snapshot',function()
 local a=Unit(F,700,2,false,4);a.scenario=852
 GameEvents.UnitPrekill.Fire(1,700,2,4,6,true,0);a.delayed=true
 Done();assert(a.scenario<0,'intermediate boundary must retain a delayed-death receipt')
 GameEvents.UnitPrekill.Fire(1,700,2,4,6,false,-1)
 local snapshot=a.scenario;GameEvents.UnitCaptured.Fire(0,2,1,700,false,1);F.units[700]=nil
 local b=Spawn(P,701,2,false,1);b.original=1;b.scenario=snapshot
 Done();assert(b.scenario==852);Promote(b,3);MeterZero()
end)
Case('Prophet capture and original-owner recapture leave genuine same-tile births eligible',function()
 local foreign=Unit(F,700,1009,true);foreign.original=0;foreign.scenario=963
 local captured=Capture(F,P,700,701,function() Spawn(P,702,1009,true) end,
  function() Spawn(P,703,1009,true);Reload() end,true)
 Done();Check(2*Scale(30));assert(captured.promotions[person] and captured.scenario==963)
 P.meter=0;captured=Capture(P,F,701,704);Done(1)
 captured=Capture(F,P,704,705);Done();MeterZero()
end)
Case('ordinary kill cannot suppress a new soldier sharing its tile and class',function()
 local a=Unit(F,700,2,false,4)
 GameEvents.UnitPrekill.Fire(1,700,2,4,6,false,0);F.units[700]=nil
 Spawn(P,701,2,false,3);Done();Check(Scale(14))
 assert(not F.data:match('%[LC1_C%d+='))
end)
Case('Great Person source categories, duplicates, immediate expenditure and native GA causes',function()
 for i=1,4 do
  local gp=Spawn(P,700+i,1000+i,true)
  if i==1 then GameEvents.CityTrained.Fire(0,1,gp.id,false,true)
  elseif i==2 then GameEvents.UnitPrekill.Fire(0,gp.id,gp.kind,4,6,true,-1);P.units[gp.id]=nil
  else Done() end -- policy and Wonder free units use the same native init path
 end
 Check(4*Scale(30));Reload();Done();Check(4*Scale(30))
 for i=1,4 do
  GoldenStart(P);Events.SequenceGameInitComplete.Fire();Events.LoadScreenClose.Fire()
  assert(P.gpModifier==15 and P.xpModifier==15)
  GameEvents.PlayerGoldenAge.Fire(0,true,5);assert(P.gpModifier==15 and P.xpModifier==15)
  P.ga=false;GameEvents.PlayerGoldenAge.Fire(0,false,0);Reload()
  assert(P.gpModifier==0 and P.xpModifier==0 and F.gpModifier==0)
 end
end)
Case('captured-city Hall ownership and normal suppression',function()
 local c=City(P,1,1);c.owner=1
 GameEvents.PlayerDoTurn.Fire(0);MeterZero()
 c.owner=0;c.resistance=true;NextTurn();GameEvents.PlayerDoTurn.Fire(0);MeterZero()
 c.resistance=false;NextTurn();GameEvents.PlayerDoTurn.Fire(0);Check(1)
 Reload();GameEvents.PlayerDoTurn.Fire(0);Check(1)
 c.halls=0;NextTurn();GameEvents.PlayerDoTurn.Fire(0);Check(1)
end)
Case('immediate post-capture upgrade cannot bypass deferred classification',function()
 Unit(F,700,2,false,4);local u=Capture(F,P,700,701)
 u=Convert(P,P,701,702,3,true,function() Reload();MeterZero() end)
 Promote(u,4);Done();MeterZero()
 local genuine=Spawn(P,703,2,false,3)
 genuine=Convert(P,P,703,704,3,true);Check(Scale(14))
 Reload();Done();assert(genuine.promotions[vet]);Check(Scale(14))
end)
Case('conversion level refunds stay closed and foreign idle events never scan armies',function()
 Unit(F,700,2,false,4)
 local u=Convert(F,P,700,701,3,false,function(a,b) b.level=2 end)
 Promote(u,3);Done();MeterZero()
 local a,b,c=P.unitSweeps,F.unitSweeps,Q.unitSweeps
 for i=1,1000 do
  GameEvents.PlayerDoTurn.Fire(1);GameEvents.PlayerDoneTurn.Fire(1)
  GameEvents.UnitCreated.Fire(1,9999)
 end
 assert(P.unitSweeps==a and F.unitSweeps==b and Q.unitSweeps==c)
end)
Case('a capture created while recognition is flushing retains its receipt',function()
 local notified=false;local acquired
 Unit(F,701,2,false,4)
 -- Retry a source whose earlier capture did not finish, so the operation may
 -- legitimately reuse a receipt that was already present when Flush began.
 GameEvents.UnitCaptured.Fire(0,999,1,701,false,0)
 local previous=P.AddNotification
 function P:AddNotification(...)
  if not notified then
   notified=true;acquired=Capture(F,P,701,702)
  end
  return previous(self,...)
 end
 Spawn(P,700,1001,true);Done();Check(Scale(30))
 Done();Promote(acquired,3);Check(Scale(30))
end)
LC_TEST_CASES=cases
print('PASS Laureate '..cases..' isolated hardening cases at speed '..SPEED..' (including all 14 required veteran regressions)')
