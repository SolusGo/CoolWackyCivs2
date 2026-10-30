-- Native-facing test double. Production controller is executed unchanged.
function Event()
  local handlers={}
  return {Add=function(f) handlers[#handlers+1]=f end,
    Remove=function(f) for i=#handlers,1,-1 do if handlers[i]==f then table.remove(handlers,i) end end end,
    Fire=function(...) local result=true;local snapshot={};for i,f in ipairs(handlers) do snapshot[i]=f end
      for _,f in ipairs(snapshot) do if f(...)==false then result=false end end;return result end,
    Count=function() return #handlers end}
end
GameEvents={};Events={}
for _,n in ipairs({'CityConstructed','UnitCreated','UnitConverted','UnitCaptured','UnitPrekill',
  'UnitPromoted','CityTrained','PlayerGoldenAge','PlayerDoTurn','PlayerDoneTurn','PlayerCanAdoptPolicy'}) do GameEvents[n]=Event() end
Events.SequenceGameInitComplete=Event();Events.LoadScreenClose=Event()
MapModData={};ContextPtr={}
GameInfoTypes={CIVILIZATION_LAUREATE_COMMONWEALTH=1,BUILDING_HALL_OF_LAURELS=10,
 PROMOTION_CROWNING_BLOW=20,PROMOTION_LAUREL_LEVEL_REWARDED=21,
 PROMOTION_LC_PERSON_RECOGNIZED=22,POLICY_LC_GOLDEN_EXCELLENCE=30}
GameInfo={GameSpeeds={[0]={GreatPeoplePercent=SPEED}},Units={},Buildings={},BuildingClasses={}}
local turn=10
Game={GetGameSpeedType=function() return 0 end,GetGameTurn=function() return turn end}
function NextTurn() turn=turn+1 end
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(k,a,b) return k..':'..tostring(a)..':'..tostring(b) end}
local function iterator(t)
 local keys={};for k in pairs(t) do keys[#keys+1]=k end;table.sort(keys)
 local i=0;return function() i=i+1;return t[keys[i]] end
end
Players={}
function Player(id,civ)
 local p={id=id,civ=civ,alive=true,human=true,era=0,data='OTHER_PLAYER_DATA',units={},cities={},
  meter=0,policies={},notices={},ga=false,anarchy=false,unitSweeps=0,citySweeps=0,
  gpModifier=0,xpModifier=0,policyWrites=0}
 function p:GetID() return self.id end
 function p:IsAlive() return self.alive end
 function p:IsHuman() return self.human end
 function p:GetCivilizationType() return self.civ end
 function p:GetCurrentEra() return self.era end
 function p:GetScriptData() return self.data end
 function p:SetScriptData(s) self.data=s end
 function p:GetUnitByID(id) return self.units[id] end
 function p:GetCityByID(id) return self.cities[id] end
 function p:Units() self.unitSweeps=self.unitSweeps+1;return iterator(self.units) end
 function p:Cities() self.citySweeps=self.citySweeps+1;return iterator(self.cities) end
 function p:IsAnarchy() return self.anarchy end
 function p:IsGoldenAge() return self.ga end
 function p:HasPolicy(id) return self.policies[id] or false end
 function p:SetHasPolicy(id,value)
  assert(self:HasPolicy(id)~=value,'duplicate policy mutation')
  self.policies[id]=value;self.policyWrites=self.policyWrites+1
  self.gpModifier=self.gpModifier+(value and POLICY_GP or -POLICY_GP)
  self.xpModifier=self.xpModifier+(value and POLICY_XP or -POLICY_XP)
 end
 function p:GetGoldenAgeProgressMeterTimes100() return self.meter end
 function p:ChangeGoldenAgeProgressMeter(n) if not self.noHappiness then self.meter=self.meter+100*n end end
 function p:AddNotification(kind,text,title,x,y) self.notices[#self.notices+1]=text end
 Players[id]=p;return p
end
function Unit(p,id,kind,gp,level)
 local u={id=id,kind=kind,owner=p.id,original=p.id,gp=gp or false,level=level or 1,
  promotions={},data='OTHER_UNIT_DATA',x=4,y=6,dead=false,delayed=false,scenario=0,born=Game.GetGameTurn()}
 GameInfo.Units[kind]=GameInfo.Units[kind] or {Class='CLASS_'..kind,Capture='CLASS_'..kind}
 function u:GetID() return self.id end
 function u:GetOwner() return self.owner end
 function u:GetGameTurnCreated() return self.born end
 function u:GetScenarioData() return self.scenario end
 function u:SetScenarioData(n) self.scenario=n end
 function u:GetUnitType() return self.kind end
 function u:GetOriginalOwner() return self.original end
 function u:GetX() return self.x end
 function u:GetY() return self.y end
 function u:GetName() return 'Unit '..self.id end
 function u:GetLevel() return self.level end
 function u:IsCombatUnit() return not self.gp and self.kind~=99 end
 function u:IsGreatPerson() return self.gp end
 function u:IsHasPromotion(id) return self.promotions[id] or false end
 function u:SetHasPromotion(id,v) self.promotions[id]=v end
 function u:IsDead() return self.dead end
 function u:IsDelayedDeath() return self.delayed end
 function u:GetScriptData() return self.data end
 function u:SetScriptData(s) self.data=s end
 p.units[id]=u;return u
end
function City(p,id,halls)
 local c={id=id,owner=p.id,halls=halls or 0,resistance=false,razing=false,buildings={}}
 function c:GetOwner() return self.owner end
 function c:GetX() return self.id end
 function c:GetY() return 1 end
 function c:IsResistance() return self.resistance end
 function c:IsRazing() return self.razing end
 function c:GetNumActiveBuilding(b) return self.halls end
 function c:GetNumBuilding(b) return self.buildings[b] or 0 end
 p.cities[id]=c;return c
end
P=Player(0,1);F=Player(1,2);Q=Player(2,1)
function GoldenStart(p)
 p.ga=true;GameEvents.PlayerGoldenAge.Fire(p.id,true,10)
end
function NativeGoldenStep(p,threshold)
 if not p.ga and p.meter>=threshold*100 then
  p.meter=p.meter-threshold*100;GoldenStart(p)
 end
end
function Spawn(p,id,kind,gp,level)
 local u=Unit(p,id,kind,gp,level);GameEvents.UnitCreated.Fire(p.id,id,kind,4,6);return u
end
function Convert(fromP,toP,oldID,newID,kind,upgrade,afterCopy)
 -- CP initializes at Level 1, emits UnitCreated, then convert copies level and
 -- promotions, emits UnitConverted and finally kills the source with delay.
 local a=fromP.units[oldID];local b=Spawn(toP,newID,kind,a.gp,1)
 for k,v in pairs(a.promotions) do b.promotions[k]=v end
 b.original=a.original;b.level=a.level
 if afterCopy then afterCopy(a,b) end
 GameEvents.UnitConverted.Fire(fromP.id,toP.id,oldID,newID,upgrade)
 GameEvents.UnitPrekill.Fire(fromP.id,oldID,a.kind,4,6,true,-1)
 fromP.units[oldID]=nil;return b
end
function Capture(fromP,toP,oldID,newID,between,afterCreate,combat)
 local a=fromP.units[oldID]
 if not combat then GameEvents.UnitCaptured.Fire(toP.id,999,fromP.id,oldID,false,0) end
 if between then between(a) end
 -- Movement snapshots before Prekill; combat kill snapshots AFTER Prekill.
 local snapshot=not combat and a.scenario or nil
 GameEvents.UnitPrekill.Fire(fromP.id,oldID,a.kind,4,6,false,toP.id)
 if combat then
  snapshot=a.scenario
  GameEvents.UnitCaptured.Fire(toP.id,a.kind,fromP.id,oldID,false,1)
 end
 fromP.units[oldID]=nil -- native deleteUnit precedes replacement init
 -- createCaptureUnit does NOT copy XP/level/promotions/ScriptData. Its native
 -- metadata assignment follows UnitCreated; this ordering is source-checked.
 local b=Spawn(toP,newID,a.kind,a.gp,1)
 if afterCreate then afterCreate(a,b) end
 b.original=a.original;b.scenario=snapshot
 return b
end
function Reload()
 ContextPtr={};LoadController();Events.LoadScreenClose.Fire()
end
function Check(n,msg) assert(P.meter==n*100,(msg or 'meter')..': '..P.meter..' expected '..n*100) end
