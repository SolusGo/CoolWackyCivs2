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
GameEvents.UnitPromoted.Fire(0,300,5);Check(total,'level two')
soldier.level=3;GameEvents.UnitPromoted.Fire(0,300,6);total=total+Scale(14);Check(total,'level three')
soldier.level=6;GameEvents.UnitPromoted.Fire(0,300,7);Check(total,'further promotions')
soldier.promotions[crown]=true
soldier=Convert(P,P,300,301,3,true)
assert(soldier.promotions[crown] and soldier.promotions[vet]);Check(total,'upgrade marker persistence')
soldier=Capture(P,F,301,302);assert(soldier.promotions[vet],'capture to foreign owner retains marker')
soldier=Capture(F,P,302,303);GameEvents.UnitPromoted.Fire(0,303,8);Check(total,'capture return no farm')
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
assert(F.data=='OTHER_PLAYER_DATA','ordinary civilizations have no Laureate save fields')
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
