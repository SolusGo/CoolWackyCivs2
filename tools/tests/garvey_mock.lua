-- Native-boundary fixture only: this is NOT Civ V or its save serializer.
Store=Store or {};turn=StartTurn or 0;randomValue=0;randomCalls=0;notifications={};alerts={};Faults={}
local function fault(name)
 if (Faults[name] or 0)>0 then Faults[name]=Faults[name]-1;error('injected '..name) end
end
metrics={cityScans=0,unitScans=0,cityReads=0,unitReads=0,cityLookups=0,officeQueries=0}
local function event(option)
 local e={handlers={}}
 function e.Add(fn) e.handlers[#e.handlers+1]=fn end
 return setmetatable(e,{__call=function(_,...)
  -- Enforce our explicit module option contract; native CP also has a legacy
  -- UnitPrekill fallback when disabled, which is audited separately.
  if option then assert(Options[option]==1,'missing explicit '..option) end
  for _,fn in ipairs(e.handlers) do fn(...) end
 end})
end
local names={'PlayerDoTurn','PlayerCityFounded','CityConstructed','CitySoldBuilding','CapitalChanged','CityCaptureComplete','CityRazed','UnitCreated','CityTrained','UnitConverted','UnitUpgraded','PlayerCanAdoptPolicy','CombatResult','CombatEnded','UnitPrekill'}
local enames={'SpecificCityInfoDirty','SerialEventGameDataDirty','SerialEventCityInfoDirty','GameplaySetActivePlayer','WarStateChanged','GameplayAlertMessage','SerialEventEnterCityScreen','SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','StrategicViewStateChanged','SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed','ActivePlayerTurnStart','ActivePlayerTurnEnd','LoadScreenClose','InterfaceModeChanged'}
function FreshContext()
 MapModData={};GameEvents={};Events={};LuaEvents={GARVEY_Changed=event()}
 for _,n in ipairs(names) do GameEvents[n]=event(n=='UnitPrekill' and 'EVENTS_UNIT_PREKILL' or nil) end
 for _,n in ipairs(enames) do Events[n]=event() end
 Events.GameplayAlertMessage.Add(function(v) alerts[#alerts+1]=v end)
 Controls={}
 local function control()
  local c={hidden=true,disabled=false,text=''}
  function c:SetHide(v) self.hidden=v end
  function c:SetText(v) self.text=v end
  function c:SetDisabled(v) self.disabled=v end
  function c:SetToolTipString(v) self.tip=v end
  function c:RegisterCallback(_,fn) self.click=fn end
  function c:CalculateSize() end;function c:ReprocessAnchoring() end;function c:CalculateInternalSize() end
  return c
 end
 for _,n in ipairs({'Launcher','Panel','LauncherStatus','Open','Close','Cooldown','Current','Patience','PatienceMeter','Detention','Sheet','Scroll','Student1','Student2','Student3','Student4','Student5'}) do Controls[n]=control() end
 ContextPtr={}
 function ContextPtr:SetUpdate(fn) self.update=fn end
 function ContextPtr:ClearUpdate() self.update=nil end
 function ContextPtr:LookUpControl(path) return Screens[path] end
 function ContextPtr:SetShowHideHandler(fn) self.showhide=fn end
 function ContextPtr:SetInputHandler(fn) self.input=fn end
end
Screens={};cityScreen=false;mode=0;activePlayer=0;strategic=false
UI={IsCityScreenUp=function() return cityScreen end,GetInterfaceMode=function() return mode end,IsInStrategicView=function() return strategic end}
InterfaceModeTypes={INTERFACEMODE_SELECTION=0};Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
ButtonPopupTypes={BUTTONPOPUP_CHOOSEPRODUCTION=3};NotificationTypes={NOTIFICATION_GENERIC=1};GameDefines={MAX_CIV_PLAYERS=4}
Locale={ConvertTextKey=function(key,...)
 local s=Text[key] or key
 for i,v in ipairs({...}) do s=s:gsub('{'..i..'_[^}]+}',function() return tostring(v) end) end
 return s
end}
Modding={OpenSaveData=function() fault('open');return {
 GetValue=function(k)
  assert(type(k)=='string','save uses dot calls');fault(k:find(':kill:') and 'killRead' or 'stateRead');return Store[k]
 end,
 SetValue=function(k,v)
  assert(type(k)=='string','save uses dot calls');local name=k:find(':kill:') and 'killWrite' or 'stateWrite'
  fault(name);if not RejectWrites then Store[k]=v end;fault(name..'After')
 end} end}
Game={GetGameTurn=function() return turn end,GetActivePlayer=function() return activePlayer end,
 Rand=function(max,label) assert(max==100 and label);randomCalls=randomCalls+1;return randomValue end}
GameInfo={GARVEY_Config=function()
 local keys={};for k in pairs(Config) do keys[#keys+1]=k end;table.sort(keys);local i=0
 return function() i=i+1;local k=keys[i];if k then return {Name=k,Value=Config[k]} end end
end}
Players={};Teams={}
local function iterator(t)
 local i=0;return function() i=i+1;return t[i] end
end
function NewPlayer(id,civ,human)
 local p={id=id,civ=civ,human=human,alive=true,active=true,cities={},units={},policies={},culture=0}
 function p:IsHuman() return self.human end;function p:IsAlive() return self.alive end
 function p:GetCivilizationType() return self.civ end;function p:IsTurnActive() return self.active end
 function p:GetTeam() return self.id end
 function p:GetCapitalCity() return self.cities[1] end
 function p:Cities() metrics.cityScans=metrics.cityScans+1;return iterator(self.cities) end
 function p:Units() metrics.unitScans=metrics.unitScans+1;return iterator(self.units) end
 function p:GetCityByID(id)
  metrics.cityLookups=metrics.cityLookups+1
  for _,c in ipairs(self.cities) do if c.id==id then return c end end
 end
 function p:CountNumBuildings(id)
  -- Models CP's maintained native building-count cache without calling Lua
  -- Cities()/GetNumBuilding(). This fixture does not measure native timings.
  metrics.officeQueries=metrics.officeQueries+1
  local n=0;for _,c in ipairs(self.cities) do n=n+(c.buildings[id] or 0)+(c.free[id] or 0) end;return n
 end
 function p:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
 function p:HasPolicy(id) return self.policies[id] or false end
 function p:SetHasPolicy(id,v,free) assert(free==true);self.policies[id]=v end
 function p:ChangeJONSCulture(n) self.culture=self.culture+n end
 function p:AddNotification(_,msg) notifications[#notifications+1]=msg end
 Players[id]=p;return p
end
for id=0,3 do Teams[id]={IsAtWar=function(self,other) return other~=id end} end
function NewCity(p,id,office)
 local c={owner=p.id,id=id,founded=turn,buildings={},free={},writes=0}
 function c:GetGameTurnFounded() return self.founded end;function c:GetOwner() return self.owner end
 function c:GetNumRealBuilding(id) metrics.cityReads=metrics.cityReads+1;return self.buildings[id] or 0 end
 function c:GetNumBuilding(id) metrics.cityReads=metrics.cityReads+1;return (self.buildings[id] or 0)+(self.free[id] or 0) end
 function c:SetNumRealBuilding(id,n,noBonus)
  assert(noBonus==true);self.buildings[id]=n;self.writes=self.writes+1
  Events.SpecificCityInfoDirty(self.owner,self.id,1)
 end
 function c:SetNumFreeBuilding(id,n)
  self.free[id]=n;Events.SpecificCityInfoDirty(self.owner,self.id,1)
 end
 if office then c.buildings[GameInfoTypes.BUILDING_GARVEY_PRINCIPALS_OFFICE]=1 end
 p.cities[#p.cities+1]=c;return c
end
function NewUnit(p,id,typ,strength,ranged)
 local u={id=id,typ=typ,strength=strength or 16,ranged=ranged or 0,promos={},born=turn,dead=false,owner=p.id}
 function u:GetID() return self.id end;function u:GetUnitType() return self.typ end
 function u:GetGameTurnCreated() return self.born end
 function u:IsCombatUnit() return self.strength>0 end;function u:IsRanged() return self.ranged>0 end
 function u:IsDead() return self.dead end;function u:IsDelayedDeath() return false end
 function u:IsHasPromotion(id) metrics.unitReads=metrics.unitReads+1;return self.promos[id] or false end
 function u:SetHasPromotion(id,v) self.promos[id]=v end
 function u:GetBaseCombatStrength() return self.strength end;function u:GetBaseRangedCombatStrength() return self.ranged end
 p.units[#p.units+1]=u;return u
end
plot={friendly=true};function plot:IsFriendlyTerritory(pid) return self.friendly end
function plot:GetPlotCity() return self.city end
Map={GetPlot=function(x,y) if x==4 and y==5 then return plot end end}
function Tick(t,pid) turn=t;GameEvents.PlayerDoTurn(pid or 0) end
function Flush() local n=0;while ContextPtr.update do n=n+1;assert(n<10,'permanent frame polling');ContextPtr.update() end end
function Reload() FreshContext();LoadUI();Flush();return MapModData.Garvey end
FreshContext()
p=NewPlayer(0,GameInfoTypes.CIVILIZATION_GARVEY_CLASSROOM,true)
enemy=NewPlayer(1,-1,false);foreign=NewPlayer(2,-2,true)
city=NewCity(p,1);hall=NewUnit(p,1,GameInfoTypes.UNIT_GARVEY_HALL_MONITOR)
soldier=NewUnit(p,2,-4,20);civilian=NewUnit(p,3,-5,0)
target=NewUnit(enemy,7,-6,18,23)
