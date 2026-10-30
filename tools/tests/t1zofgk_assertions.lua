ASSERTIONS=0
local R=GameInfoTypes.UNIT_T1Z_RECRUIT
local function Setup()Reset();LoadController()end
Setup()
-- Starting replacement exists before the simulation context is constructed.
Reset();local starting=MakeUnit(0,R);LoadController()
Check(RoleOf(starting)==1,'starting replacement must become Zeus')
MakeCity(0,1,1)
local a={starting}
for i=2,5 do a[i]=Train(0,R,1,i%2==0,false);Check(RoleOf(a[i])==i,'Z-O-F-G-K order including purchases')end
local sixth=Train(0,R,1)
Check(not RoleOf(sixth) and Has(sixth,'SCOUTED'),'sixth Recruit ordinary development origin')
GameEvents.CityTrained(0,1,sixth.id,false,false);GameEvents.UnitCreated(0,sixth.id,R,0,0)
Check(not RoleOf(sixth),'duplicate creation/training cannot create sixth role')
Check(Has(a[1],'SYNERGY_15') and not Has(a[1],'SYNERGY_10'),'all five tier exclusive')
Move(a[5],6,0)
Check(Has(a[1],'SYNERGY_10') and not Has(a[1],'SYNERGY_15'),'four distinct roles')
Move(a[4],6,0);Check(Has(a[1],'SYNERGY_10'),'three distinct roles')
Move(a[3],6,0);Check(not Has(a[1],'SYNERGY_10') and not Has(a[1],'SYNERGY_15'),'two distinct roles')
Move(sixth,1,0);Check(not Has(a[1],'SYNERGY_10'),'normal troops do not count')
Move(a[3],2,0);Check(Has(a[1],'SYNERGY_10'),'radius two inclusive')
a[3].embarked=true;GameEvents.UnitSetXY(0,a[3].id,2,0);Check(Has(a[1],'SYNERGY_10'),'embarked role uses map distance')
-- Duplicate/corrupted promotions cannot add a second distinct role or holder.
sixth.promos[GameInfoTypes.PROMOTION_T1Z_ZEUS]=true
sixth.promos[GameInfoTypes.PROMOTION_T1Z_KERIA]=true
GameEvents.PlayerDoTurn(0)
Check(not RoleOf(sixth),'unregistered duplicate roles stripped')
a[2].promos[GameInfoTypes.PROMOTION_T1Z_KERIA]=true;GameEvents.PlayerDoTurn(0)
Check(RoleOf(a[2])==2 and not Has(a[2],'KERIA'),'one unit cannot hold two roles')
-- Long upgrades, duplicated hook delivery, ID changes, soft and hard reloads.
local veteran=a[1];local token=veteran.data:match('%[T1Z1_ID=([^%]]+)%]')
for i=1,18 do
  veteran=Upgrade(veteran,10000+i,true)
  Check(Has(veteran,'DEVELOPMENT_'..i) and NativeModifier(veteran,'CombatPercent')>=4*i,'exact cumulative tier')
  Check(RoleOf(veteran)==1 and Has(veteran,'SCOUTED'),'upgrade preserves identity and origin')
  Check(veteran.data:match('%[T1Z1_ID=([^%]]+)%]')==token,'lifetime token survives new unit object')
  local tiers=0;for k=1,144 do if Has(veteran,'DEVELOPMENT_'..k)then tiers=tiers+1 end end
  Check(tiers==1,'no stacking development tiers')
  GameEvents.UnitPromoted(0,veteran.id,999);GameEvents.UnitUpgraded(0,veteran.id,veteran.id,false)
  Reload(i%2==0)
  Check(Has(veteran,'DEVELOPMENT_'..i) and RoleOf(veteran)==1,'reload and level-ups cannot add development')
  Check(not Players[0].data:match('S1=V:'),'upgrade is not a death')
end
local same=Upgrade(veteran,veteran.kind,true)
Check(Has(same,'DEVELOPMENT_18') and not Has(same,'DEVELOPMENT_19'),'same type conversion is not genuine upgrade')
local ordinary=Train(0,10044,1)
Check(not Has(ordinary,'SCOUTED') and NativeModifier(ordinary,'CombatPercent')==0,'new late-game unit has no inherited history')
local sixthUp=Upgrade(sixth,10045,true)
Check(Has(sixthUp,'DEVELOPMENT_1') and not RoleOf(sixthUp),'non-roster Recruit develops too')
-- Recruitment: persistent delay, production-only, real local HQ, own units.
local lostID=a[2].id;Die(a[2]);local delay=math.max(1,math.floor(10*SPEED/100+.5))
Check(Players[0].data:match('S2=V:'..delay),'vacancy gets scaled cooldown once')
local early=Train(0,R,1);Check(not RoleOf(early),'cannot recruit during cooldown')
turn=delay-1;Reload(true);local stillEarly=Train(0,10046,1)
Check(not RoleOf(stillEarly),'reload preserves cooldown')
turn=delay;GameEvents.PlayerDoTurn(0)
local count=#notifications;GameEvents.PlayerDoTurn(0);Reload(false)
Check(#notifications==count,'ready notice does not replay')
local bought=Train(0,10046,1,true,false);Check(not RoleOf(bought),'purchased successor excluded')
local faith=Train(0,10046,1,false,true);Check(not RoleOf(faith),'faith successor excluded')
MakeCity(0,2,0);local noHQ=Train(0,10046,2);Check(not RoleOf(noHQ),'free/dummy HQ is not real HQ')
MakeCity(0,3,1);Players[0].cities[3].pid=1
Check(not RoleOf(Train(0,10046,3)),'foreign city invalid')
local ranged=MakeUnit(0,10047);ranged.ranged=true;GameEvents.CityTrained(0,1,ranged.id,false,false)
Check(not RoleOf(ranged),'ranged successor excluded')
local civilian=MakeUnit(0,10047);civilian.military=false;GameEvents.CityTrained(0,1,civilian.id,false,false)
Check(not RoleOf(civilian),'civilian successor excluded')
local sea=MakeUnit(0,10047);sea.domain=1;GameEvents.CityTrained(0,1,sea.id,false,false)
Check(not RoleOf(sea),'naval successor excluded')
local defender=MakeUnit(0,10047);defender.onlyDefensive=true;GameEvents.CityTrained(0,1,defender.id,false,false)
Check(not RoleOf(defender),'defensive-only successor excluded')
local successor=Train(0,10046,1,false,false,lostID)
Check(RoleOf(successor)==2 and not Has(successor,'SCOUTED') and not Has(successor,'DEVELOPMENT_1'),'successor inherits only role, safely reuses old ID')
GameEvents.CityTrained(0,1,successor.id,false,false)
Check(RoleOf(successor)==2,'duplicate training consumes once')
-- Two simultaneous vacancies: priority, no free units, own history only.
Die(a[3]);Die(a[4]);local before=nextID
turn=turn+delay;GameEvents.PlayerDoTurn(0);Check(nextID==before,'cooldown never spawns units')
local f=Train(0,R,1);local g=Train(0,10046,1)
Check(RoleOf(f)==3 and RoleOf(g)==4,'simultaneous vacancies follow original priority')
Check(Has(f,'SCOUTED') and not Has(g,'SCOUTED'),'successor Recruit keeps only own origin')
-- Captures cannot recruit, even though native init precedes original-owner copy.
Die(f);turn=turn+delay
local capture=MakeUnit(0,R);capture.original=1
GameEvents.PlayerDoTurn(0);Reload(true)
Check(not RoleOf(capture),'captured replacement cannot join initial or successor roster')
local foreign=MakeUnit(1,R);local gift=Convert(foreign,0,R,false,true)
GameEvents.CityTrained(0,1,gift.id,false,false);GameEvents.PlayerDoTurn(0)
Check(not RoleOf(gift),'gift cannot masquerade as local training')
-- Direct capture of an originally local Recruit back to its original player
-- must also be rejected; OriginalOwner alone is not sufficient evidence.
local recapturedSource=MakeUnit(1,R,7,0);recapturedSource.original=0
GameEvents.UnitCaptured(0,0,1,recapturedSource.id,false,1)
Die(recapturedSource)
local recaptured=MakeUnit(0,R,7,0);recaptured.original=0
GameEvents.PlayerDoTurn(0);Reload(true)
Check(not RoleOf(recaptured),'recaptured original-owner Recruit cannot exploit initial roster')
-- Gift a living member away: vacates immediately, strips foreign role/aura.
local gifted=Convert(successor,1,10048,false,true)
Check(not RoleOf(gifted) and Players[0].data:match('S2=V:'),'ownership loss vacates once')
local returned=Convert(gifted,0,10048,false,true)
Check(not RoleOf(returned),'returning gift cannot duplicate role')
-- Auras: actual wars, all military domains, movement, death, peace and load.
Setup();a=Army();War(0,1,true);War(0,2,true)
local enemy=MakeUnit(1,10050,1,0)
Check(Has(enemy,'PRESSURE'),'enemy created next to Faker is debuffed')
enemy.domain=1;Move(enemy,1,0);Check(Has(enemy,'PRESSURE'),'naval military qualifies')
local barbarian=MakeUnit(2,10050,0,1);Check(Has(barbarian,'PRESSURE'),'barbarian hostile qualifies')
local neutral=MakeUnit(4,10050,1,0);Check(not Has(neutral,'PRESSURE'),'friendly team is not hostile')
enemy.military=false;Move(enemy,1,0);Check(not Has(enemy,'PRESSURE'),'civilian excluded')
enemy.military=true;Move(enemy,1,0);Check(Has(enemy,'PRESSURE'),'military gets aura')
Move(enemy,5,0);Check(not Has(enemy,'PRESSURE'),'leaving removes aura')
Move(enemy,1,0);Move(a[3],6,0)
Check(not Has(enemy,'PRESSURE') and not Has(barbarian,'PRESSURE'),'Faker movement removes old effects')
Move(a[3],0,0);War(0,1,false);Check(not Has(enemy,'PRESSURE'),'peace removes immediately')
Teams[1].wars[0]=true;Events.WarStateChanged(1,0,true)
Check(Has(enemy,'PRESSURE'),'one-sided native war event applies notified relationship')
Teams[1].wars[0]=false;Events.WarStateChanged(1,0,false)
Check(not Has(enemy,'PRESSURE'),'one-sided native peace event clears notified relationship')
War(0,1,true);local upgradedEnemy=Upgrade(enemy,10051,true)
Check(Has(upgradedEnemy,'PRESSURE'),'foreign upgrade refreshes aura after native overwrite')
Reload(true);Check(Has(upgradedEnemy,'PRESSURE'),'reload restores correct aura')
-- Another T1 player can have Faker, but the debuff is a single promotion.
MakeCity(3,1,1);for i=1,5 do Train(3,R,1)end;War(3,1,true)
Check(NativeModifier(upgradedEnemy,'CombatPercent')==-10,'multiple Faker sources do not stack')
Die(a[3]);Check(Has(upgradedEnemy,'PRESSURE'),'second hostile Faker maintains aura')
for _,u in pairs(Players[3].units)do if RoleOf(u)==3 then Die(u);break end end
Check(not Has(upgradedEnemy,'PRESSURE'),'last Faker death clears aura')
local friend=MakeUnit(0,10050,1,0);GameEvents.CityTrained(0,1,friend.id,false,false)
Check(Has(friend,'SUPPORT') and not Has(a[5],'SUPPORT'),'Keria supports adjacent friend, excludes self')
friend.damage=40;Check(NormalHeal(friend)==15,'normal healing adds exactly five')
friend.damage=3;Check(NormalHeal(friend)==3 and friend.damage==0,'healing respects maximum HP')
for _,flag in ipairs({'moved','attacked','blocked','embarked'})do
  friend.damage=40;friend[flag]=true;Check(NormalHeal(friend)==0,'support cannot bypass '..flag);friend[flag]=false
end
friend.military=false;Move(friend,1,0);Check(not Has(friend,'SUPPORT'),'civilian support excluded')
friend.military=true;friend.domain=1;Move(friend,1,0);Check(Has(friend,'SUPPORT'),'support covers naval military, native healing eligibility remains')
local ally=MakeUnit(4,10050,1,0);Check(Has(ally,'SUPPORT'),'same-team allied military supported')
Move(a[5],5,0);Check(not Has(friend,'SUPPORT') and not Has(ally,'SUPPORT'),'Keria movement clears support')
Move(a[5],0,0);Die(a[5]);Check(not Has(friend,'SUPPORT'),'Keria death clears support')
local scans=unitScans;for i=1,100 do Move(upgradedEnemy,20+i,20)end
Check(unitScans==scans,'ordinary movement never enumerates armies')
-- Defer native free births through conversion, but preserve creation order
-- before a subsequent CityTrained event (IDs are not creation serials).
Setup();MakeCity(0,1,1)
local first=MakeUnit(0,R,0,0,50);local second=MakeUnit(0,R,0,0,5)
GameEvents.UnitCreated(0,first.id,R,0,0);Reload(true)
local third=Train(0,R,1)
Check(RoleOf(first)==1 and RoleOf(second)==2 and RoleOf(third)==3,'pending births preserve creation order across duplicates and reload')
Setup();local free=MakeUnit(0,R);free=Upgrade(free,10091,true)
Check(RoleOf(free)==1 and Has(free,'DEVELOPMENT_1'),'free Recruit upgrading before turn boundary retains initial role')
Setup();MakeCity(0,1,1);local firstLegend=Train(0,R,1);Die(firstLegend)
turn=math.max(1,math.floor(10*SPEED/100+.5))
local secondLegend=Train(0,R,1)
Check(RoleOf(secondLegend)==2,'early death cannot displace original first-five role order')
local firstSuccessor=Train(0,10092,1)
Check(RoleOf(firstSuccessor)==1,'a valid non-Recruit can replace a ready role before the original five are complete')
-- No T1 present: callbacks preserve unrelated units and player save data.
Reset();Players[0].civ=-1;Players[3].civ=-1;LoadController()
local other=Train(0,10080,1);GameEvents.PlayerDoTurn(0);Reload(true)
Check(next(other.promos)==nil and other.data=='' and Players[0].data=='','other civilizations unaffected')
