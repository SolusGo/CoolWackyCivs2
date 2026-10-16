-- Deliberately small native-engine double. All assertions run the shipped Lua.
GameInfo,GameInfoTypes={},{}
for name,data in pairs(RED_DATABASE) do
 local by={};for _,row in ipairs(data) do if row.Type then by[row.Type]=row;GameInfoTypes[row.Type]=row.ID end;if row.ID then by[row.ID]=row end end
 setmetatable(by,{__call=function(_,filter)
  local i=0;return function()
   while true do i=i+1;local row=data[i];if not row then return end
    local matches=true;for k,v in pairs(filter or {}) do if row[k]~=v then matches=false end end
    if matches then return row end
   end
  end
 end});GameInfo[name]=by
end
local function event()
 local e={handlers={}}
 function e.Add(fn)e.handlers[#e.handlers+1]=fn end
 return setmetatable(e,{__call=function(_,...) local result;for _,fn in ipairs(e.handlers) do local x=fn(...);if x~=nil then result=x end end;return result end})
end
local function eventList()return setmetatable({},{__index=function(t,k)local e=event();rawset(t,k,e);return e end})end
GameEvents,Events,LuaEvents=eventList(),eventList(),eventList()
MapModData={};NotificationTypes={NOTIFICATION_GENERIC=1};DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
MissionTypes={MISSION_AIRLIFT=1,MISSION_MOVE_TO=2,MISSION_HEAL=3,MISSION_RANGE_ATTACK=4}
OrderTypes={ORDER_CREATE=1,ORDER_CONSTRUCT=2};ActivityTypes={ACTIVITY_SLEEP=1};GameDefines={MAX_CIV_PLAYERS=4,MOVE_DENOMINATOR=60}
YieldTypes={YIELD_PRODUCTION=1}
Locale={ConvertTextKey=function(s)return s end}
TEST={turn=0,units={},nextID=0,speed=GameInfoTypes.GAMESPEED_STANDARD,techs={}}
Game={GetGameTurn=function()return TEST.turn end,GetGameSpeedType=function()return TEST.speed end,GetActivePlayer=function()return 0 end}
ContextPtr={SetUpdate=function(self,fn)self.update=fn end,ClearUpdate=function(self)self.update=nil end}
function TEST.flush()local n=0;while ContextPtr.update do n=n+1;assert(n<200,'infinite deferred dispatch');ContextPtr.update(0.1) end end
local plots={};local width,height=12,10
Map={}
function Map.PlotDistance(x,y,a,b)local dx,dy=x-a,y-b;return math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy))end
function Map.GetPlot(x,y)if x<0 or y<0 or x>=width or y>=height then return end;return plots[y*width+x]end
function Map.GetPlotByIndex(i)return plots[i]end
function Map.GetNumPlots()return width*height end
local dirs={{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
function Map.PlotDirection(x,y,d)return Map.GetPlot(x+dirs[d+1][1],y+dirs[d+1][2])end
local Plot={};Plot.__index=Plot
function Plot:GetX()return self.x end
function Plot:GetY()return self.y end
function Plot:GetOwner()return self.owner end
function Plot:GetPlotIndex()return self.y*width+self.x end
function Plot:GetPlotCity()return self.city end
function Plot:IsCity()return self.city~=nil end
function Plot:IsWater()return self.water or false end
function Plot:IsMountain()return false end
function Plot:IsImpassable()return self.blocked or false end
function Plot:IsVisible()return true end
function Plot:GetTerrainType()return self.terrain or (self.water and GameInfoTypes.TERRAIN_COAST or GameInfoTypes.TERRAIN_GRASS) end
function Plot:GetFeatureType()return -1 end
function Plot:list()
 local a={};for _,u in pairs(TEST.units) do if not u.dead and u.x==self.x and u.y==self.y then a[#a+1]=u end end;table.sort(a,function(x,y)return x.id<y.id end);return a
end
function Plot:GetNumUnits()return #self:list() end
function Plot:GetUnit(i)return self:list()[i+1] end
function Plot:IsVisibleEnemyUnit(pid)for _,u in ipairs(self:list()) do if u.pid~=pid and Players[pid]:GetTeam()~=Players[u.pid]:GetTeam() then return true end end return false end
for y=0,height-1 do for x=0,width-1 do plots[y*width+x]=setmetatable({x=x,y=y,owner=0},Plot) end end
local Unit={};Unit.__index=Unit
function Unit:GetOwner()return self.pid end
function Unit:GetID()return self.id end
function Unit:GetUnitType()return self.typ end
function Unit:GetX()return self.x end
function Unit:GetY()return self.y end
function Unit:GetPlot()return Map.GetPlot(self.x,self.y) end
function Unit:GetScriptData()return self.script end
function Unit:SetScriptData(v)self.script=v end
function Unit:IsDead()return self.dead or false end
function Unit:IsDelayedDeath()return self.dead or false end
function Unit:IsBusy()return false end
function Unit:HasMoved()return self.moved or false end
function Unit:GetGameTurnCreated()return self.born end
function Unit:IsPromotionValid(id)return not (self.invalidPromotions and self.invalidPromotions[id]) end
function Unit:IsCombatUnit()local i=GameInfo.Units[self.typ];return (i.Combat or 0)>0 or (i.RangedCombat or 0)>0 end
function Unit:GetDomainType()return DomainTypes[GameInfo.Units[self.typ].Domain] end
function Unit:GetBaseCombatStrength()return GameInfo.Units[self.typ].Combat or 0 end
function Unit:GetBaseRangedCombatStrength()return GameInfo.Units[self.typ].RangedCombat or 0 end
function Unit:IsRanged()return self:GetBaseRangedCombatStrength()>0 end
function Unit:IsHasPromotion(i)return self.promotions[i] or false end
function Unit:SetHasPromotion(i,on)assert(i~=nil and not self.initializing,'promotion mutation during native InitUnit');self.promotions[i]=on and true or nil end
function Unit:GetPromotionDuration()return 0 end
function Unit:GetTurnPromotionGained()return 0 end
function Unit:GetLeaderUnitType()return self.leader or -1 end
function Unit:SetLeaderUnitType(n)self.leader=n end
function Unit:GetReligion()return self.religion or -1 end
function Unit:SetReligion(n)self.religion=n end
function Unit:IsPromotionReady()return self.promotionReady or false end
function Unit:SetPromotionReady(n)self.promotionReady=n end
function Unit:sum(field)local n=0;for id in pairs(self.promotions) do n=n+(GameInfo.UnitPromotions[id][field] or 0) end;return n end
function Unit:GetMaxHitPointsBase()return self.baseHP end
function Unit:SetMaxHitPointsBase(n)self.baseHP=n end
function Unit:GetMaxHitPoints()return self.baseHP+self:sum('MaxHitPointsChange') end
function Unit:GetDamage()return self.damage end
function Unit:SetDamage(n)
 local old=self.damage;self.damage=n;Events.SerialEventUnitSetDamage(self.pid,self.id,n,old)
 if self.damage>=self:GetMaxHitPoints() then self:Kill(false,-1) end
end
function Unit:ChangeDamage(n,pid)self:SetDamage(self.damage+n)end
function Unit:MaxMoves()return math.max(0,((GameInfo.Units[self.typ].Moves or 2)+self:sum('MovesChange'))*60)end
function Unit:MovesLeft()return self.moves end
function Unit:SetMoves(n)self.moves=math.max(0,n) end
function Unit:FinishMoves()self.moves=0;self.moved=true end
function Unit:GetExperienceTimes100()return self.xp end
function Unit:SetExperienceTimes100(n)self.xp=n end
function Unit:GetExperience()return self.xp/100 end
function Unit:GetLevel()return self.level end
function Unit:SetLevel(n)self.level=n end
function Unit:GetNameNoDesc()return self.name end
function Unit:GetName()return self.name~='' and self.name or GameInfo.Units[self.typ].Type end
function Unit:SetName(n)self.name=n end
function Unit:GetOriginalOwner()return self.original end
function Unit:SetOriginalOwner(n)self.original=n end
function Unit:GetActivityType()return self.activity end
function Unit:SetActivityType(n)self.activity=n end
function Unit:GetFacingDirection()return 0 end
function Unit:GetUnitAIType()return 0 end
function Unit:IsEmbarked()return self.embarked or false end
function Unit:IsOutOfAttacks()return self.attacked or false end
function Unit:GetFortifyTurns()return self.fortified and 1 or 0 end
function Unit:CanFortify()return self:GetDomainType()==0 and not self:IsEmbarked() end
function Unit:CanMoveOrAttackInto(plot,declare,destination)
 if destination~=nil then assert(type(destination)=='number','CP luaL_optint destination flag requires integer') end
 return not plot:IsImpassable() and not plot:IsVisibleEnemyUnit(self.pid) and (self:GetDomainType()==1 and plot:IsWater() or self:GetDomainType()==0 and not plot:IsWater())
end
function Unit:GeneratePath()return true end
function Unit:CanMoveThrough(plot)return self:CanMoveOrAttackInto(plot) end
function Unit:Range()return (GameInfo.Units[self.typ].Range or 0)+self:sum('RangeChange')end
function Unit:CanRangeStrikeAt(x,y)return self:IsRanged() and Map.PlotDistance(self.x,self.y,x,y)<=self:Range()end
function Unit:SetXY(x,y)self.x=x;self.y=y;GameEvents.UnitSetXY(self.pid,self.id,x,y)end
function Unit:UpgradePrice()return 200 end
function Unit:CanAirliftAt(plot,x,y)
 local from=plot:GetPlotCity();local dest=Map.GetPlot(x,y):GetPlotCity()
 if not from or not dest or from.id==dest.id or not self:CanMoveOrAttackInto(dest:Plot()) then return false end
 for _,v in ipairs(dest:Plot():list()) do if v~=self and v:IsCombatUnit()==self:IsCombatUnit() then return false end end
 for d=0,5 do local p=Map.PlotDirection(x,y,d);if p and p:IsVisibleEnemyUnit(self.pid) then return false end end
 local start=GameEvents.CanAirliftFrom(self.pid,self.id,plot.x,plot.y) or (not self:HasMoved() and self:GetDomainType()==0 and from:GetNumBuilding(GameInfoTypes.BUILDING_AIRPORT)>0)
 local finish=GameEvents.CanAirliftTo(self.pid,self.id,x,y) or dest:GetNumBuilding(GameInfoTypes.BUILDING_AIRPORT)>0
 return start and finish
end
function Unit:PushMission(m,x,y)
 if m==MissionTypes.MISSION_AIRLIFT and self.async then self.mission={m,x,y}
 elseif m==MissionTypes.MISSION_AIRLIFT and self:CanAirliftAt(self:GetPlot(),x,y) then self:FinishMoves();self:SetXY(x,y)
 elseif m==MissionTypes.MISSION_MOVE_TO then self:SetXY(x,y);self:FinishMoves() end
end
function Unit:Kill(delay,killer)
 if self.dead then return end
 GameEvents.UnitPrekill(self.pid,self.id,self.typ,self.x,self.y,delay,killer)
 self.dead=true;TEST.units[self.id]=nil
end
local Player={};Player.__index=Player
function Player:GetCivilizationType()return self.civ end
function Player:GetTeam()return self.pid end
function Player:IsAlive()return not self.eliminated end
function Player:IsHuman()return self.human end
function Player:IsTurnActive()return true end
function Player:IsMinorCiv()return false end
function Player:IsBarbarian()return self.pid==3 end
function Player:GetScriptData()return self.script end
function Player:SetScriptData(s)self.script=s end
function Player:GetCurrentEra()return self.era end
function Player:GetUnitByID(id)local u=TEST.units[id];return u and u.pid==self.pid and u or nil end
function Player:Units()
 local a={};for _,u in pairs(TEST.units) do if u.pid==self.pid then a[#a+1]=u end end;table.sort(a,function(x,y)return x.id<y.id end)
 local i=0;return function()i=i+1;return a[i]end
end
function Player:Cities()local i=0;return function()i=i+1;return self.cities[i]end end
function Player:GetCityByID(id)for _,c in ipairs(self.cities) do if c.id==id then return c end end end
function Player:GetCapitalCity()return self.cities[1]end
function Player:GetOriginalCapitalPlot()return self.originalCapital end
function Player:CanTrain(id)local i=GameInfo.Units[id];return not i.PrereqTech or TEST.techs[i.PrereqTech] end
function Player:InitUnit(typ,x,y)
 local u=setmetatable({pid=self.pid,id=TEST.nextID,typ=typ,x=x,y=y,script='',promotions={},baseHP=100,damage=0,moves=120,xp=0,level=1,name='',original=self.pid,activity=0,born=TEST.turn},Unit)
 TEST.nextID=TEST.nextID+1;TEST.units[u.id]=u
 u.initializing=true;GameEvents.UnitSetXY(self.pid,u.id,x,y);u.initializing=nil;u.moves=u:MaxMoves()
 GameEvents.UnitCreated(self.pid,u.id,typ,x,y);return u
end
function Player:GetUnitProductionNeeded(typ)return math.max(0,GameInfo.Units[typ].Cost or 0)end
function Player:ChangeGold(n)self.gold=self.gold+n end
function Player:ChangeJONSCulture(n)self.culture=self.culture+n end
function Player:ChangeOverflowResearch(n)self.science=self.science+n end
function Player:ChangeCombatExperience(n)self.general=self.general+n end
function Player:GetWarWeariness(other)return self.ww[other] or 0 end
function Player:ChangeWarWeariness(other,n)self.ww[other]=(self.ww[other] or 0)+n end
function Player:AddNotification()self.notifications=self.notifications+1 end
Players,Teams={},{}
for id=0,3 do
 Players[id]=setmetatable({pid=id,civ=id==0 and GameInfoTypes.CIVILIZATION_RED_INDIGO_CHAMPION or GameInfoTypes.CIVILIZATION_AMERICA,script='',era=0,cities={},human=true,gold=0,culture=0,science=0,general=0,ww={},notifications=0},Player)
 Teams[id]={IsAtWar=function(_,other)return other~=id end,IsHasTech=function(_,tech)return TEST.techs[GameInfo.Technologies[tech] and GameInfo.Technologies[tech].Type or tech] or false end}
end
local City={};City.__index=City
function City:GetOwner()return self.pid end
function City:GetID()return self.id end
function City:GetX()return self.x end
function City:GetY()return self.y end
function City:Plot()return Map.GetPlot(self.x,self.y)end
function City:GetNumBuilding(id)return self.buildings[id] or 0 end
function City:GetNumRealBuilding(id)return self.buildings[id] or 0 end
function City:SetNumRealBuilding(id,n)assert(id~=nil);self.buildings[id]=n end
function City:GetOriginalOwner()return self.original end
function City:GetDamage()return 0 end
function City:GetMaxHitPoints()return 200 end
function City:GetName()return self.name end
function City:GetProductionProject()return self.project or -1 end
function City:GetProductionBuilding()return self.building or -1 end
function City:GetProduction()return 10 end
function City:GetProductionNeeded()return 100 end
function City:GetYieldRate()return self.production or 10 end
function City:IsRazing()return self.razing or false end
function City:IsResistance()return self.resistance or false end
function City:GetOrderQueueLength()return #(self.queue or {}) end
function City:GetOrderFromQueue(i)local o=(self.queue or {})[i+1];if o then return o[1],o[2],-1,false,false end;return -1,0,0,false,false end
function City:CanCreate()return true end
function City:CanConstruct()return true end
function City:PushOrder(kind,id,data,save,pop,append)
 assert(type(pop)=='boolean' and type(append)=='boolean','CP PushOrder booleans')
 self.queue=self.queue or {};if pop then table.remove(self.queue,1) end
 if append then self.queue[#self.queue+1]={kind,id} else table.insert(self.queue,1,{kind,id}) end
 local head=self.queue[1];self.project=head and head[1]==1 and head[2] or nil;self.building=head and head[1]==2 and head[2] or nil
end
function TEST.city(pid,x,y)
 local p=Players[pid];local c=setmetatable({pid=pid,id=#p.cities,x=x,y=y,buildings={},original=pid,name='City '..pid},City)
 p.cities[#p.cities+1]=c;Map.GetPlot(x,y).city=c;Map.GetPlot(x,y).owner=pid;p.originalCapital=p.originalCapital or c:Plot();return c
end
TEST.cap=TEST.city(0,4,4);TEST.enemyCap=TEST.city(1,9,7)
function TEST.new(typ,x,y,pid)return Players[pid or 0]:InitUnit(GameInfoTypes[typ],x or 4,y or 4)end
function TEST.reload()
 local R=MapModData.RED_Legend;R.Save(R.State(0));R.States={};R.Index={};local s=R.State(0);R.Reconcile(s);return s
end
function TEST.reloadContext()
 local old=MapModData.RED_Legend;for _,s in pairs(old.States) do old.Save(s) end
 ContextPtr.update=nil;GameEvents,Events,LuaEvents=eventList(),eventList(),eventList()
 include('RED_Core');TEST.flush();return MapModData.RED_Legend
end
function TEST.convert(u,typ)
 local R=MapModData.RED_Legend;local p=Players[u.pid];local new=p:InitUnit(GameInfoTypes[typ],u.x,u.y)
 GameEvents.UnitUpgraded(u.pid,u.id,new.id,false)
 -- Deliberately do not copy ScriptData: CP does not copy this field in convert.
 for id,on in pairs(u.promotions) do new.promotions[id]=on end
 new.xp=u.xp;new.name=u.name;new.damage=u.damage
 GameEvents.UnitConverted(u.pid,u.pid,u.id,new.id,true);u:Kill(false,-1);TEST.flush();return new
end
