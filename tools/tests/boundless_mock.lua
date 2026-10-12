-- Independent native accounting model: local workers + labourers + specialists = population.
-- The task semantics follow CP's doTask, DoAlterWorkingPlot and ChangeNumDefaultSpecialists.
MapModData={};GameInfoTypes={CIVILIZATION_BOUNDLESS_CITY=100,BUILDING_BC_REGISTRY=200,
 SPECIALIST_CITIZEN=0,PROMOTION_BC_NO_CAPTURE=300,UNIT_BC_SURVEYOR=400,UNIT_SETTLER=401,
 YIELD_FOOD=0,YIELD_PRODUCTION=1,YIELD_GOLD=2,YIELD_SCIENCE=3,YIELD_CULTURE=4,YIELD_FAITH=5,IMPROVEMENT_FARM=500}
GameInfoTypes.BUILD_FARM=0;GameInfoTypes.BUILD_REPAIR=1
for n=1,10 do GameInfoTypes['BUILDING_BC_REGISTRY_'..n]=200+n end
GameDefines={MAX_MAJOR_CIVS=2,MAX_CIV_PLAYERS=3}
GameDefines.MAX_MAJOR_CIVS=3;GameDefines.MAX_CIV_PLAYERS=4;GameDefines.MAX_SPECIALISTS_FROM_BUILDING=4
TaskTypes={TASK_REMOVE_SLACKER=1,TASK_CLEAR_ORDERS=2,TASK_SET_AUTOMATED_PRODUCTION=3};MissionTypes={MISSION_BUILD=1,MISSION_MOVE_TO=2}
NotificationTypes={NOTIFICATION_GENERIC=1};Locale={ConvertTextKey=function(k,...) return k end}
DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
now=1;speed=100;scans=0;mutations=0;cultureAward=0
Game={GetGameTurn=function() return now end,GetGameSpeedType=function() return 0 end,
 IsNetworkMultiPlayer=function() return false end,GetActivePlayer=function() return 0 end}
Game.GetWinner=function() return winner or -1 end;Game.GetVictory=function() return victory or -1 end
Game.IsVictoryValid=function() return dominationEnabled~=false end
Game.SetWinner=function(t,v) assert(not insideCapture);winner=t;victory=v;winnerCalls=(winnerCalls or 0)+1 end
Game.GetImprovementUpgradeTime=function() return 2 end
GameInfoTypes.VICTORY_DOMINATION=2
GameInfo={GameSpeeds=setmetatable({},{__index=function() return {CulturePercent=speed} end}),
 Units={[400]={Found=0},[401]={Found=1}},Builds={[0]={ID=0,ImprovementType='IMPROVEMENT_FARM'},[1]={ID=1,Repair=1}},Resources={},Improvements={}}
setmetatable(GameInfo.Builds,{__call=function(t) local i=-1;return function() i=i+1;return t[i] end end})
local function rows(values)
 return setmetatable(values,{__call=function(t,filter)
  local i=0;return function()
   while true do i=i+1;local r=t[i];if not r then return end
    local valid=true;for k,v in pairs(filter or {}) do if r[k]~=v then valid=false end end
    if valid then return r end
   end
  end
 end})
end
GameInfo.SpecialistYields=rows({{SpecialistType='SPECIALIST_CITIZEN',YieldType='YIELD_PRODUCTION',Yield=1}})
GameInfo.Unit_Builds=rows({{UnitType='UNIT_BC_SURVEYOR',BuildType='BUILD_FARM'},{UnitType='UNIT_BC_SURVEYOR',BuildType='BUILD_REPAIR'}})
GameInfo.Buildings=rows({{ID=1000,SpecialistCount=4}})
GameInfo.UnitPromotions=rows({{ID=300,NoCapture=1},{ID=301,NoCapture=1}})
Teams={};for i=0,3 do Teams[i]={IsAtWar=function(self,other) return other~=i end,IsWaterWork=function(self) return self.waterWork~=false end} end
local function event() local a={};local fire=function(...) for _,fn in ipairs(a) do fn(...) end end
 local test=function(...) for _,fn in ipairs(a) do if fn(...)==false then return false end end;return true end
 return setmetatable({Add=function(fn) a[#a+1]=fn end,Fire=fire,Test=test},{__call=function(_,...) return fire(...) end}) end
GameEvents={};for _,n in ipairs({'PlayerDoTurn','PlayerDoneTurn','PlayerCanFoundCity','PlayerCanTrain','CityCanTrain',
 'CityCanConstruct','CityCanCreate','CityCanMaintain','CityCanAcquirePlot','PlayerCanCreateTradeRoute','DeclareWar','MakePeace','PlayerCanBuyOut','PlayerCityFounded','UnitCreated','UnitConverted','CityCaptureComplete','TileOwnershipChanged',
 'PlayerBuilt','TileImprovementChanged','TileFeatureChanged','TileRouteChanged','SetPopulation','TeamTechResearched','CityConstructed','PlayerAdoptPolicy','UnitSetXY'}) do GameEvents[n]=event() end
Events={SerialEventCityInfoDirty=event(),LoadScreenClose=event()};LuaEvents={BoundlessChanged=event()}
ContextPtr={SetUpdate=function(self,fn) deferred=fn end}
function Pump() local fn=deferred;deferred=nil;if fn then fn() end end
local saved={};SaveMirror={GetValue=function(k) return saved[k] end,SetValue=function(k,v) saved[k]=v end}
Modding={OpenSaveData=function() return SaveMirror end}
plots={};local W,H=80,20
local plotMethods={}
function plotMethods:GetPlotIndex() return self.n end
function plotMethods:GetX() return self.x end
function plotMethods:GetY() return self.y end
function plotMethods:GetOwner() return self.owner end
function plotMethods:GetPlotCity() return self.city end
function plotMethods:IsCity() return self.city~=nil end
function plotMethods:IsMountain() return self.mountain or false end
function plotMethods:IsWater() return self.water or false end
function plotMethods:IsVisibleEnemyUnit() return self.enemy or false end
function plotMethods:IsBlockaded() return self.blockaded or false end
function plotMethods:HasYield() for _,v in ipairs(self.yields) do if v>0 then return true end end;return false end
function plotMethods:GetCityPurchaseID() return self.owningCity or -1 end
function plotMethods:GetYield(id) return self.yields[id+1] or 0 end
function plotMethods:GetResourceType() return -1 end
function plotMethods:GetImprovementType() return self.improvement or -1 end
function plotMethods:IsImprovementPillaged() return self.pillaged or false end
function plotMethods:IsBeingWorked() return self.city~=nil or (capital and capital.worked[self.n]) or false end
function plotMethods:IsCoastalLand() return self.coastal or false end
function plotMethods:GetUpgradeProgress() return self.upgradeProgress or 0 end
function plotMethods:ChangeUpgradeProgress(delta) self.upgradeProgress=(self.upgradeProgress or 0)+delta end
function plotMethods:GetPlayerThatBuiltImprovement() return self.builder or 0 end
function plotMethods:SetImprovementType(id,builder) self.improvement=id;self.builder=builder;self.upgradeProgress=0;GameEvents.TileImprovementChanged.Fire(self.x,self.y,id) end
function plotMethods:GetArea() return 1 end
function plotMethods:IsVisible() return self.visible~=false end
function plotMethods:GetScriptData() return self.script or '' end
function plotMethods:SetScriptData(value) self.script=value end
function plotMethods:SetOwner(pid,id)
 local old=self.owner;self.owner=pid;self.owningCity=id;GameEvents.TileOwnershipChanged.Fire(self.x,self.y,pid,old)
end
function MakeMap(w,h,wrap)
 W,H=w,h;plots={};wrapX=wrap
 for n=0,W*H-1 do plots[n]=setmetatable({n=n,x=n%W,y=math.floor(n/W),owner=-1,yields={1,1,0,0,0,0}},{__index=plotMethods}) end
end
MakeMap(80,20,false)
Map={GetNumPlots=function() scans=scans+1;return W*H end,GetGridSize=function() return W,H end,
 IsWrapX=function() return wrapX end,IsWrapY=function() return false end,
 GetPlotByIndex=function(n) return plots[n] end,
 GetPlot=function(x,y) if wrapX then x=x%W end;if x<0 or y<0 or x>=W or y>=H then return end;return plots[y*W+x] end}
function Map.PlotDirection(x,y,dir)
 local offsets={{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
 return Map.GetPlot(x+offsets[dir+1][1],y+offsets[dir+1][2])
end
function Map.PlotDistance(x,y,a,b)
 local dx=a-x;if wrapX and math.abs(dx)>W/2 then dx=dx>0 and dx-W or dx+W end
 local dy=b-y;return math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy))
end
local cityMethods={}
function cityMethods:GetOwner() return self.owner end
function cityMethods:GetX() return self.x end
function cityMethods:GetY() return self.y end
function cityMethods:GetID() return self.id end
function cityMethods:GetOriginalOwner() return self.original end
function cityMethods:GetPreviousOwner() return self.previous end
function cityMethods:GetGameTurnFounded() return 0 end
function cityMethods:GetGameTurnFounded() return self.founded or 0 end
function cityMethods:IsOriginalCapital()
 if self.originalCapital~=nil then return self.originalCapital end
 return (self.original==0 and self.x==3 and self.y==5) or (self.original==1 and self.x==60 and self.y==5)
end
function cityMethods:IsHolyCityAnyReligion() return self.holy or false end
function cityMethods:IsRevealed() return self.revealed~=false end
function cityMethods:GetResistanceTurns() return self.resistance or 0 end
function cityMethods:ChangeResistanceTurns(delta) self.resistance=(self.resistance or 0)+delta;assert(self.resistance>=0) end
function cityMethods:IsRazing() return self.razing or false end
function cityMethods:GetMaxHitPoints() return 200 end
function cityMethods:GetDamage() return self.damage or 0 end
function cityMethods:GetName() return self.name or 'Test settlement' end
function cityMethods:GetAutomatons() return self.automatons or 0 end
function cityMethods:GetPopulation() return self.pop end
function cityMethods:SetName(name) self.name=name end
function cityMethods:GetNumCityPlots() return #self.localPlots+1 end
function cityMethods:GetCityIndexPlot(i) return self.localPlots[i] end
function cityMethods:IsWorkingPlot(p) return self.worked[p.n] or false end
function cityMethods:IsForcedWorkingPlot(p) return self.forced[p.n] or false end
function cityMethods:GetSpecialistCount(id) assert(id==0);return self.defaults end
function cityMethods:GetTotalSpecialistCount() return self.specialists end
function cityMethods:GetSpecialistYield(id,y) return (y==1 and 1 or 0)+self.defaults*(self.extra[y] or 0) end
function cityMethods:GetExtraSpecialistYieldOfType(y,id) assert(id==0);return self.defaults*(self.extra[y] or 0) end
function cityMethods:GetNumBuilding(id) return self.buildings[id] or 0 end
function cityMethods:GetNumRealBuilding(id) return self.buildings[id] or 0 end
function cityMethods:SetNumRealBuilding(id,n) self.buildings[id]=n;mutations=mutations+1 end
function cityMethods:ChangeBaseYieldRateFromMisc(y,d)
 self.misc[y]=(self.misc[y] or 0)+d;mutations=mutations+1
 if d~=0 then self.cached=self.cached or {};self.cached[y]=self:NativeYield(y) end
end
function cityMethods:GetBaseYieldRateFromMisc(y) return self.misc[y] or 0 end
function cityMethods:GetBaseYieldRateFromTerrain(y)
 local total=self.terrain[y] or 0;for _,p in ipairs(self.localPlots) do if self.worked[p.n] then total=total+p:GetYield(y) end end
 return total
end
function cityMethods:ChangeBaseYieldRateFromTerrain(y,d) self.terrain[y]=(self.terrain[y] or 0)+d;mutations=mutations+1 end
function cityMethods:NativeYield(y)
 if self:GetResistanceTurns()>0 then return 0 end
 return (self:GetBaseYieldRateFromTerrain(y)+self:GetBaseYieldRateFromMisc(y)+self.defaults*((y==1 and 1 or 0)+(self.extra[y] or 0)))*(self.modifier or 100)/100
end
function cityMethods:GetJONSCulturePerTurn() return self.culture end
function cityMethods:RefreshTourism() self.tourism=self:GetBaseYieldRateFromTerrain(4)*(self.landmarkPercent or 0);self.tourismRefresh=(self.tourismRefresh or 0)+1 end
function cityMethods:FoodDifference() return 1 end
function cityMethods:Check()
 local count=0;for n,on in pairs(self.worked) do if on then count=count+1 end end
 assert(count+self.defaults+self.specialists+(self.unassigned or 0)==self.pop+self:GetAutomatons(),'native census inconsistent')
 assert(self.defaults>=0 and self.forcedDefault>=0 and self.forcedDefault<=self.defaults,'native labourer count inconsistent')
end
function cityMethods:AlterWorkingPlot(i)
 local p=self.localPlots[i];if not p or p.owner~=self.owner or p.enemy or p.mountain then return end
 if self.worked[p.n] then
  self.worked[p.n]=nil;self.forced[p.n]=nil;self.defaults=self.defaults+1;self.forcedDefault=self.forcedDefault+1
 elseif self.defaults>0 then
  self.defaults=self.defaults-1;self.forcedDefault=math.max(0,self.forcedDefault-1);self.worked[p.n]=true;self.forced[p.n]=true
 end
 mutations=mutations+1;self:Check()
end
function cityMethods:DoTask(task,data1,data2,option)
 assert(type(option)=='number','CP v151 DoTask uses luaL_optint, not a boolean')
 if task==TaskTypes.TASK_CLEAR_ORDERS then self.orders={};return end
 if task==TaskTypes.TASK_SET_AUTOMATED_PRODUCTION then self.automatedProduction=option~=0;return end
 assert(task==TaskTypes.TASK_REMOVE_SLACKER)
 if self.defaults<=0 then return end
 self.defaults=self.defaults-1;self.forcedDefault=math.max(0,self.forcedDefault-1)
 local best,score
 for _,p in ipairs(self.localPlots) do
  if not self.worked[p.n] and p.owner==self.owner and not p.enemy and not p.mountain then
   local value=p.yields[1]+p.yields[2]+p.yields[3]
   if not score or value>score then best=p;score=value end
  end
 end
 if best then self.worked[best.n]=true else self.defaults=self.defaults+1 end
 mutations=mutations+1;self:Check()
end
local nextCityID=0
function MakeCity(pid,x,y,pop,localCount)
 nextCityID=nextCityID+1
 local c=setmetatable({owner=pid,original=pid,previous=pid,id=nextCityID,x=x,y=y,pop=pop,localPlots={},
 worked={},forced={},defaults=0,forcedDefault=0,specialists=0,buildings={},misc={},terrain={},extra={},culture=8},{__index=cityMethods})
 local center=Map.GetPlot(x,y);center.city=c;center.owner=pid;center.owningCity=c.id
 for i=1,localCount do local p=Map.GetPlot(x+i,y);p.owner=pid;p.owningCity=c.id;c.localPlots[i]=p
  if i<=pop then c.worked[p.n]=true end
 end
 c.defaults=math.max(0,pop-localCount);return c
end
capital=MakeCity(0,3,5,8,12);foreign=MakeCity(1,60,5,4,6)
local playerMethods={}
function playerMethods:GetCivilizationType() return self.pid==0 and 100 or 99 end
function playerMethods:GetCapitalCity() return self.cities[1] end
function playerMethods:Cities() local i=0;return function() i=i+1;return self.cities[i] end end
function playerMethods:Units() local i=0;return function() repeat i=i+1 until not self.units[i] or not self.units[i].dead;return self.units[i] end end
function playerMethods:GetNumCities() return #self.cities end
function playerMethods:GetScriptData() return self.script or '' end
function playerMethods:SetScriptData(v) self.script=v end
function playerMethods:IsHuman() return self.human end
function playerMethods:IsAlive() return true end
function playerMethods:IsEverAlive() return self.everAlive~=false end
function playerMethods:GetOriginalCapitalPlot() return Map.GetPlot(self.originalX or (self.pid==0 and 3 or self.pid==1 and 60 or -1),self.originalY or 5) end
function playerMethods:GetImprovementUpgradeRate() return self.upgradeRate or 100 end
function playerMethods:IsBarbarian() return self.pid==3 end
function playerMethods:IsMinorCiv() return self.minor or false end
function playerMethods:GetPlayerToLiberate(city) return city.original~=self.pid and city.original or -1 end
function playerMethods:CanLiberatePlayer(pid) return Players[pid] and Players[pid]:IsAlive() end
function playerMethods:CanRaze(city)
 return city.owner==self.pid and city.original~=self.pid and not city:IsOriginalCapital() and not city.holy and not city.protected and not self.noRazing
end
function playerMethods:Disband(city)
 assert(not insideCapture,'cannot demolish in a native capture stack')
 assert(self:CanRaze(city),'native protected settlement destroyed')
 for i=#self.cities,1,-1 do if self.cities[i]==city then table.remove(self.cities,i) end end
 local p=Map.GetPlot(city.x,city.y);p.city=nil;local old=p.owner;p.owner=-1;GameEvents.TileOwnershipChanged.Fire(p.x,p.y,-1,old)
end
function playerMethods:IsTurnActive() return true end
function playerMethods:GetCurrentEra() return 0 end
function playerMethods:GetTeam() return self.pid end
function playerMethods:AddNotification() end
function playerMethods:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id and not u.dead then return u end end end
function playerMethods:ChangeJONSCulture(n) cultureAward=cultureAward+n end
function playerMethods:GetNumMilitaryUnits() return 2 end
function playerMethods:AcquireCity(c,conquest,gift)
 assert(not insideCapture,'unsafe recursive capture transfer')
 for _,p in pairs(Players) do for i=#p.cities,1,-1 do if p.cities[i]==c then table.remove(p.cities,i) end end end
 c.previous=c.owner;c.owner=self.pid;self.cities[#self.cities+1]=c
 self.lastAcquire={conquest=conquest,gift=gift}
end
Players={}
for id=0,3 do Players[id]=setmetatable({pid=id,cities=id==0 and {capital} or id==1 and {foreign} or {},units={},human=id==0},{__index=playerMethods}) end
function MakeUnit(id,kind)
 local u={id=id,kind=kind,promotions={},dead=false}
 function u:GetUnitType() return self.kind end
 function u:SetHasPromotion(p,v) self.promotions[p]=v end
 function u:IsHasPromotion(p) return self.promotions[p] or false end
 function u:GetDomainType() return self.domain or 0 end
 function u:IsDead() return self.dead end;function u:IsDelayedDeath() return false end
 function u:IsOnlyDefensive() return self.defensive or false end
 function u:IsOutOfAttacks() return self.outOfAttacks or false end
 function u:GetX() return 24 end;function u:GetY() return 5 end
 function u:Kill() self.dead=true end
 function u:MovesLeft() return 0 end
 function u:GetID() return self.id end
 function u:GetGameTurnCreated() return 0 end
 function u:IsBusy() return false end
 function u:IsCombatUnit() return self.kind==600 end
 function u:IsRanged() return false end
 function u:IsEmbarked() return false end
 function u:FinishMoves() self.moves=0 end
 function u:GeneratePath(plot) return {{X=plot.x,Y=plot.y}} end
 function u:CanBuild(plot,build) return build==0 and plot.owner==0 and not plot.water end
 function u:GetPlot() return Map.GetPlot(self:GetX(),self:GetY()) end
 function u:PushMission(kind,a,b) self.lastMission={kind,a,b} end
 Players[0].units[#Players[0].units+1]=u;return u
end
function GovernorWorst(city)
 -- Adversarial completed native allocation: keep only forced labourers,
 -- consume every legal local position and built specialist slot before defaults.
 city.worked={};city.forced={};city.specialists=0
 local remaining=city.pop-city.forcedDefault
 for _,p in ipairs(city.localPlots) do if remaining>0 and p.owner==city.owner and not p.mountain and not p.enemy then city.worked[p.n]=true;remaining=remaining-1 end end
 if city.buildings[1000] then city.specialists=math.min(4,remaining);remaining=remaining-city.specialists end
 city.defaults=city.forcedDefault+remaining;city:Check()
end
function Remote(x,y,values)
 local p=Map.GetPlot(x,y);p.owner=0;p.yields=values or {5,4,3,2,1,1}
 if MapModData.BoundlessCity then local c=MapModData.BoundlessCity.Cache(MapModData.BoundlessCity.State(0));c.owned[p.n]=true;c.territoryDirty=true;c.force=true end
 return p
end
