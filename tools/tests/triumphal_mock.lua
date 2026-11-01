-- Native-facing fixture: shipped Lua is executed unchanged under Lua 5.1.
function Event()
  local handlers={}
  return {Add=function(f) handlers[#handlers+1]=f end,
    Remove=function(f) for i=#handlers,1,-1 do if handlers[i]==f then table.remove(handlers,i) end end end,
    Fire=function(...) local copy={}; for i,f in ipairs(handlers) do copy[i]=f end
      local result=true;for _,f in ipairs(copy) do if f(...)==false then result=false end end;return result end,
    Count=function() return #handlers end}
end
GameEvents,Events={},{}
for _,name in ipairs({'BattleStarted','BattleJoined','BattleFinished','UnitPrekill','UnitKilledInCombat',
 'CityCaptureComplete','PlayerCityFounded','TeamTechResearched','UnitCreated','UnitConverted','UnitUpgraded',
 'CityTrained','UnitSetXY','CityConstructed','CitySoldBuilding','CityCanConstruct','PlayerDoTurn'}) do GameEvents[name]=Event() end
for _,name in ipairs({'SequenceGameInitComplete','LoadScreenClose','GameplaySetActivePlayer',
 'ActivePlayerTurnStart','SerialEventEnterCityScreen','SerialEventExitCityScreen','AILeaderMessage',
 'LeavingLeaderViewMode'}) do Events[name]=Event() end
MapModData={};ContextPtr={SetShutdown=function(self,f) self.shutdown=f end}
local turn,active=0,0
Game={GetGameTurn=function() return turn end,GetActivePlayer=function() return active end}
function SetTurn(n) turn=n end
function SetActive(n) active=n;Events.GameplaySetActivePlayer.Fire() end
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key,...)
 local values={...};return (TEXT[key] or key):gsub('{(%d+)_[^}]+}',function(i)return tostring(values[tonumber(i)])end)
end}
function Iterator(rows)
 local keys={};for k in pairs(rows) do if type(k)=='number' then keys[#keys+1]=k end end;table.sort(keys)
 local i=0;return function() i=i+1;return rows[keys[i]] end
end
for _,rows in pairs(GameInfo) do setmetatable(rows,{__call=function(t)return Iterator(t)end}) end
Players,Teams={},{}
function Player(id,civ,minor,barbarian)
 local p={id=id,civ=civ,minor=minor,barbarian=barbarian,alive=true,human=true,
  data='FOREIGN_PLAYER',cities={},units={},notices={},unitScans=0,cityScans=0}
 function p:GetID()return self.id end
 function p:GetTeam()return self.id end
 function p:GetCivilizationType()return self.civ end
 function p:IsHuman()return self.human end
 function p:IsAlive()return self.alive end
 function p:IsMinorCiv()return self.minor end
 function p:IsBarbarian()return self.barbarian end
 function p:GetScriptData()return self.data end
 function p:SetScriptData(s)self.data=s end
 function p:GetUnitByID(id)return self.units[id] end
 function p:GetCityByID(id)return self.cities[id] end
 function p:Units()self.unitScans=self.unitScans+1;return Iterator(self.units) end
 function p:Cities()self.cityScans=self.cityScans+1;return Iterator(self.cities) end
 function p:AddNotification(_,message)self.notices[#self.notices+1]=message end
 Players[id]=p
 local t={id=id,bronze=false,peace={}};function t:IsHasTech(tech)return tech==GameInfoTypes.TECH_BRONZE_WORKING and self.bronze end
 function t:IsAtWar(other)return self.id~=other and not self.peace[other] end
 Teams[id]=t;return p
end
function Unit(p,id,kind)
 local row=GameInfo.Units[kind]
 local u={owner=p.id,id=id,kind=kind,born=turn,damage=0,delayed=false,data='FOREIGN_UNIT',promotions={},moves=row.Moves*60}
 function u:GetOwner()return self.owner end
 function u:GetID()return self.id end
 function u:GetUnitType()return self.kind end
 function u:GetGameTurnCreated()return self.born end
 function u:IsCombatUnit()return row.Combat>0 end
 function u:IsDead()return self.damage>=100 end
 function u:IsDelayedDeath()return self.delayed end
 function u:IsHasPromotion(id)return self.promotions[id] or false end
 function u:SetHasPromotion(id,on)self.promotions[id]=on end
 function u:MovesLeft()return self.moves end
 function u:MaxMoves()
  local moves=row.Moves;for id,on in pairs(self.promotions) do if on then moves=moves+GameInfo.UnitPromotions[id].MovesChange end end
  return moves*60
 end
 function u:SetMoves(n)assert(n<=self.moves,'movement refilled');self.moves=n end
 function u:GetScriptData()return self.data end
 function u:SetScriptData(s)self.data=s end
 p.units[id]=u;return u
end
local plots={}
Map={GetPlot=function(x,y)return plots[x..':'..y] end}
function City(p,id,x,y)
 local plot=plots[x..':'..y] or {data='FOREIGN_PLOT'};plots[x..':'..y]=plot
 function plot:GetScriptData()return self.data end
 function plot:SetScriptData(s)self.data=s end
 function plot:GetPlotCity()return self.city end
 local c={owner=p.id,id=id,original=p.id,founded=turn,x=x,y=y,buildings={}}
 function c:GetOwner()return self.owner end
 function c:GetID()return self.id end
 function c:GetOriginalOwner()return self.original end
 function c:GetGameTurnFounded()return self.founded end
 function c:GetX()return self.x end
 function c:GetY()return self.y end
 function c:Plot()return plot end
 function c:GetNumRealBuilding(b)return self.buildings[b] or 0 end
 function c:GetNumBuilding(b)return self:GetNumRealBuilding(b)+(self.freeBuildings and self.freeBuildings[b] or 0) end
 function c:SetNumRealBuilding(b,n)self.buildings[b]=n end
 function c:MilitaryProduction()
  local total=0;for b,n in pairs(self.buildings) do total=total+n*(GameInfo.Buildings[b].MilitaryProductionModifier or 0) end
  return total
 end
 plot.city=c;p.cities[id]=c;return c
end
function Capture(city,new,conquest)
 local old=city.owner;Players[old].cities[city.id]=nil;city.owner=new.id;new.cities[city.id]=city
 GameEvents.CityCaptureComplete.Fire(old,false,city.x,city.y,new.id,5,conquest,0,0)
end
function Battle(killer,victim,kind,cityKiller,duplicates)
 GameEvents.BattleStarted.Fire(kind or 0,10,10)
 if cityKiller then GameEvents.BattleJoined.Fire(killer.owner,killer.id,0,true)
 else GameEvents.BattleJoined.Fire(killer.owner,killer.id,0,false) end
 GameEvents.BattleJoined.Fire(victim.owner,victim.id,1,false)
 victim.damage=100
 GameEvents.UnitPrekill.Fire(victim.owner,victim.id,victim.kind,10,10,true,killer.owner)
 victim.delayed=true
 GameEvents.UnitKilledInCombat.Fire(killer.owner,victim.owner,victim.kind,-1)
 if duplicates then
  GameEvents.UnitPrekill.Fire(victim.owner,victim.id,victim.kind,10,10,true,killer.owner)
  GameEvents.UnitKilledInCombat.Fire(killer.owner,victim.owner,victim.kind,-1)
 end
 GameEvents.BattleFinished.Fire()
 GameEvents.UnitPrekill.Fire(victim.owner,victim.id,victim.kind,10,10,false,killer.owner)
end
Controls={}
for _,name in ipairs({'MomentumPanel','MomentumTitle','MomentumEffects','Laurel1','Laurel2','Laurel3','Laurel4','Laurel5','Laurel6'}) do
 local c={};function c:SetHide(v)self.hidden=v end;function c:SetText(v)self.text=v end
 function c:SetAlpha(v)self.alpha=v end;function c:SetToolTipString(v)self.tip=v end;Controls[name]=c
end
IMP=Player(0,GameInfoTypes.CIVILIZATION_TRIUMPHAL_IMPERIUM)
RIVAL=Player(1,-1);RIVAL.human=false
MINOR=Player(2,-2,true,false);BARB=Player(3,-3,false,true)
OTHER=Player(4,-4);AIIMP=Player(5,GameInfoTypes.CIVILIZATION_TRIUMPHAL_IMPERIUM);AIIMP.human=false
HOME=City(IMP,1,1,1)
U=Unit(IMP,1,GameInfoTypes.UNIT_TRI_UNBROKEN)
WORKER=Unit(IMP,2,GameInfoTypes.UNIT_WORKER)
PLANE=Unit(IMP,3,GameInfoTypes.UNIT_FIGHTER)
