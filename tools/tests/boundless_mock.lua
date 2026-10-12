-- Independent native accounting model: local workers + labourers + specialists = population.
-- The task semantics follow CP's doTask, DoAlterWorkingPlot and ChangeNumDefaultSpecialists.
MapModData={};GameInfoTypes={CIVILIZATION_BOUNDLESS_CITY=100,BUILDING_BC_REGISTRY=200,
 SPECIALIST_CITIZEN=0,PROMOTION_BC_NO_CAPTURE=300,UNIT_BC_SURVEYOR=400,UNIT_SETTLER=401,
 YIELD_FOOD=0,YIELD_PRODUCTION=1,YIELD_GOLD=2,YIELD_SCIENCE=3,YIELD_CULTURE=4,YIELD_FAITH=5,IMPROVEMENT_FARM=500}
for n=1,10 do GameInfoTypes['BUILDING_BC_REGISTRY_'..n]=200+n end
GameDefines={MAX_MAJOR_CIVS=2,MAX_CIV_PLAYERS=3}
TaskTypes={TASK_REMOVE_SLACKER=1};MissionTypes={MISSION_BUILD=1,MISSION_MOVE_TO=2}
NotificationTypes={NOTIFICATION_GENERIC=1};Locale={ConvertTextKey=function(k,...) return k end}
now=1;speed=100;scans=0;mutations=0;cultureAward=0
Game={GetGameTurn=function() return now end,GetGameSpeedType=function() return 0 end,
 IsNetworkMultiPlayer=function() return false end,GetActivePlayer=function() return 0 end}
GameInfo={GameSpeeds=setmetatable({},{__index=function() return {CulturePercent=speed} end}),
 Units={[400]={Found=0},[401]={Found=1}},Builds={[0]={ID=0,ImprovementType='IMPROVEMENT_FARM'},[1]={ID=1,Repair=1}},Resources={},Improvements={}}
setmetatable(GameInfo.Builds,{__call=function(t) local i=-1;return function() i=i+1;return t[i] end end})
local function event() local a={};local fire=function(...) for _,fn in ipairs(a) do fn(...) end end
 return setmetatable({Add=function(fn) a[#a+1]=fn end,Fire=fire},{__call=function(_,...) return fire(...) end}) end
GameEvents={};for _,n in ipairs({'PlayerDoTurn','PlayerDoneTurn','PlayerCanFoundCity','PlayerCanTrain','CityCanTrain',
 'CityCanConstruct','PlayerCanBuyOut','PlayerCityFounded','UnitCreated','UnitConverted','CityCaptureComplete','TileOwnershipChanged',
 'PlayerBuilt','TileImprovementChanged','TileFeatureChanged','TileRouteChanged','SetPopulation','TeamTechResearched','CityConstructed','PlayerAdoptPolicy','UnitSetXY'}) do GameEvents[n]=event() end
Events={SerialEventCityInfoDirty=event(),LoadScreenClose=event()};LuaEvents={BoundlessChanged=event()}
ContextPtr={SetUpdate=function(self,fn) deferred=fn end}
function Pump() local fn=deferred;deferred=nil;if fn then fn() end end
local saved={};Modding={OpenSaveData=function() return {GetValue=function(k) return saved[k] end,SetValue=function(k,v) saved[k]=v end} end}
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
function plotMethods:GetYield(id) return self.yields[id+1] or 0 end
function plotMethods:GetResourceType() return -1 end
function plotMethods:GetImprovementType() return self.improvement or -1 end
function plotMethods:IsImprovementPillaged() return false end
function plotMethods:GetArea() return 1 end
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
function cityMethods:GetPopulation() return self.pop end
function cityMethods:SetName(name) self.name=name end
function cityMethods:GetNumCityPlots() return #self.localPlots+1 end
function cityMethods:GetCityIndexPlot(i) return self.localPlots[i] end
function cityMethods:IsWorkingPlot(p) return self.worked[p.n] or false end
function cityMethods:IsForcedWorkingPlot(p) return self.forced[p.n] or false end
function cityMethods:GetSpecialistCount(id) assert(id==0);return self.defaults end
function cityMethods:GetTotalSpecialistCount() return self.specialists end
function cityMethods:GetSpecialistYield(id,y) return y==1 and 1 or 0 end
function cityMethods:GetNumBuilding(id) return self.buildings[id] or 0 end
function cityMethods:GetNumRealBuilding(id) return self.buildings[id] or 0 end
function cityMethods:SetNumRealBuilding(id,n) self.buildings[id]=n;mutations=mutations+1 end
function cityMethods:ChangeBaseYieldRateFromMisc(y,d) self.misc[y]=(self.misc[y] or 0)+d;mutations=mutations+1 end
function cityMethods:GetJONSCulturePerTurn() return self.culture end
function cityMethods:FoodDifference() return 1 end
function cityMethods:Check()
 local count=0;for n,on in pairs(self.worked) do if on then count=count+1 end end
 assert(count+self.defaults+self.specialists==self.pop,'native census inconsistent')
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
function cityMethods:DoTask(task)
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
function MakeCity(pid,x,y,pop,localCount)
 local c=setmetatable({owner=pid,original=pid,previous=pid,id=pid+1,x=x,y=y,pop=pop,localPlots={},
 worked={},forced={},defaults=0,forcedDefault=0,specialists=0,buildings={},misc={},culture=8},{__index=cityMethods})
 local center=Map.GetPlot(x,y);center.city=c;center.owner=pid
 for i=1,localCount do local p=Map.GetPlot(x+i,y);p.owner=pid;c.localPlots[i]=p
  if i<=pop then c.worked[p.n]=true end
 end
 c.defaults=math.max(0,pop-localCount);return c
end
capital=MakeCity(0,3,5,8,12);foreign=MakeCity(1,60,5,4,6)
local playerMethods={}
function playerMethods:GetCivilizationType() return self.pid==0 and 100 or 99 end
function playerMethods:GetCapitalCity() return self.cities[1] end
function playerMethods:Cities() local i=0;return function() i=i+1;return self.cities[i] end end
function playerMethods:Units() local i=0;return function() i=i+1;return self.units[i] end end
function playerMethods:GetNumCities() return #self.cities end
function playerMethods:GetScriptData() return self.script or '' end
function playerMethods:SetScriptData(v) self.script=v end
function playerMethods:IsHuman() return self.human end
function playerMethods:IsAlive() return true end
function playerMethods:IsBarbarian() return self.pid==2 end
function playerMethods:IsTurnActive() return true end
function playerMethods:GetCurrentEra() return 0 end
function playerMethods:GetTeam() return self.pid end
function playerMethods:AddNotification() end
function playerMethods:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
function playerMethods:ChangeJONSCulture(n) cultureAward=cultureAward+n end
function playerMethods:GetNumMilitaryUnits() return 2 end
function playerMethods:AcquireCity(c)
 assert(not insideCapture,'unsafe recursive capture transfer')
 for _,p in pairs(Players) do for i=#p.cities,1,-1 do if p.cities[i]==c then table.remove(p.cities,i) end end end
 c.previous=c.owner;c.owner=self.pid;self.cities[#self.cities+1]=c
end
Players={}
for id=0,2 do Players[id]=setmetatable({pid=id,cities=id==0 and {capital} or id==1 and {foreign} or {},units={},human=id==0},{__index=playerMethods}) end
function MakeUnit(id,kind)
 local u={id=id,kind=kind,promotions={},dead=false}
 function u:GetUnitType() return self.kind end
 function u:SetHasPromotion(p,v) self.promotions[p]=v end
 function u:IsHasPromotion(p) return self.promotions[p] or false end
 function u:GetX() return 24 end;function u:GetY() return 5 end
 function u:Kill() self.dead=true end
 function u:MovesLeft() return 0 end
 Players[0].units[#Players[0].units+1]=u;return u
end
function Remote(x,y,values)
 local p=Map.GetPlot(x,y);p.owner=0;p.yields=values or {5,4,3,2,1,1}
 if MapModData.BoundlessCity then local c=MapModData.BoundlessCity.Cache(MapModData.BoundlessCity.State(0));c.owned[p.n]=true;c.territoryDirty=true;c.force=true end
 return p
end
