-- A small native-contract model. These are simulations, not in-game tests.
GameInfoTypes=setmetatable({}, {__index=function(t,k) local n=0;for _ in pairs(t) do n=n+1 end;rawset(t,k,n+100);return n+100 end})
local function event()
 local handlers={}
 return setmetatable({Add=function(fn) handlers[#handlers+1]=fn end,Count=function() return #handlers end,Fire=function(...) local value=true;for _,fn in ipairs(handlers) do if fn(...)==false then value=false end end;return value end}, {__call=function(t,...) return t.Fire(...) end})
end
local function events() return setmetatable({}, {__index=function(t,k) local v=event();rawset(t,k,v);return v end}) end
GameEvents=events();Events=events();LuaEvents=events();MapModData={}
function ResetContextEvents()
 GameEvents=events();Events=events();LuaEvents=events();ContextPtr:ClearUpdate()
 local old=ContextPtr;ContextPtr={};for key,value in pairs(old) do if key~='callback' then ContextPtr[key]=value end end
end
GameDefines={MAX_MAJOR_CIVS=3,MAX_CIV_PLAYERS=4}
local turn=0
Game={GetGameTurn=function() return turn end,GetGameSpeedType=function() return 0 end,GetActivePlayer=function() return 0 end,IsNetworkMultiPlayer=function() return false end,IsHotSeat=function() return false end}
GameInfo={GameSpeeds={[0]={TrainPercent=100}}};UnitAITypes={NO_UNITAI=-1}
CommandTypes={COMMAND_DELETE=1,COMMAND_GIFT=2,COMMAND_UPGRADE=3};NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key,...) local args={...};for i,v in ipairs(args) do args[i]=tostring(v) end;return key..(#args>0 and ':'..table.concat(args,',') or '') end}
ContextPtr={callback=nil,SetUpdate=function(self,fn) self.callback=fn end,ClearUpdate=function(self) self.callback=nil end}
function Flush() local count=0;while ContextPtr.callback do count=count+1;assert(count<10,'permanent update loop');ContextPtr.callback() end end
local plots={};local function key(x,y) return x..':'..y end
Map={GetPlot=function(x,y)
 local k=key(x,y)
 if not plots[k] then
  local p={x=x,y=y,owner=-1,script='',units={}}
  function p:GetX() return self.x end;function p:GetY() return self.y end
  function p:GetOwner() return self.owner end;function p:IsWater() return self.water or false end
  function p:IsMountain() return self.mountain or false end;function p:IsImpassable() return self.blocked or false end
  function p:IsVisibleEnemyUnit() return self.enemy or false end
  function p:GetPlotCity() return self.city end
  function p:GetNumUnits() local n=0;for _,u in pairs(self.units) do if not u.dead then n=n+1 end end;return n end
  function p:GetUnit(index) local i=0;for _,u in pairs(self.units) do if not u.dead then if i==index then return u end;i=i+1 end end end
  function p:GetScriptData() return self.script end;function p:SetScriptData(s) self.script=s end
  plots[k]=p
 end
 return plots[k]
end}
local dx={1,1,0,-1,-1,0};local dy={0,-1,-1,0,1,1}
Map.PlotDirection=function(x,y,d) return Map.GetPlot(x+dx[d+1],y+dy[d+1]) end
function Advance(n) turn=turn+(n or 1) end
local function iterator(items) local list={};for _,v in pairs(items) do list[#list+1]=v end;local n=0;return function() n=n+1;return list[n] end end
Players={}
for pid=0,2 do
 local p={id=pid,human=pid==0,civ=pid==1 and -1 or GameInfoTypes.CIVILIZATION_THE11CATS,alive=true,active=true,script='foreign:kept',era=0,cities={},units={},notifications={},writes=0,nextUnit=1}
 function p:IsHuman() return self.human end;function p:GetCivilizationType() return self.civ end
 function p:IsAlive() return self.alive end;function p:IsTurnActive() return self.active end
 function p:GetCurrentEra() return self.era end;function p:GetTeam() return self.id end
 function p:GetScriptData() return self.script end;function p:SetScriptData(s) self.script=s;self.writes=self.writes+1 end
 function p:Cities() return iterator(self.cities) end;function p:Units() return iterator(self.units) end
 function p:GetCapitalCity() return self.capital end;function p:GetUnitByID(id) return self.units[id] end
 function p:AddNotification(_,message) self.notifications[#self.notifications+1]=message end
 function p:InitUnit(kind,x,y)
  if self.failSpawn then return end
  local u={id=self.nextUnit,owner=self.id,kind=kind,promos={},plot=Map.GetPlot(x,y)};self.nextUnit=self.nextUnit+1
  function u:GetID() return self.id end;function u:GetOwner() return self.owner end;function u:GetUnitType() return self.kind end
  function u:IsHasPromotion(id) return self.promos[id] or false end;function u:SetHasPromotion(id,value) self.promos[id]=value end
  function u:SetName(name) self.name=name end;function u:SetNoMaintenance(value) self.noMaintenance=value end
  function u:GetScriptData() return self.script or '' end;function u:SetScriptData(s) self.script=s end;function u:IsDead() return self.dead or false end
  function u:IsDelayedDeath() return self.delayed or false end;function u:IsCombatUnit() return false end
  function u:GetPlot() return self.plot end
  function u:Kill()
   GameEvents.UnitPrekill(self.owner,self.id,self.kind,self.plot.x,self.plot.y,false,-1)
   self.dead=true;self.plot.units[self.id..':'..self.owner]=nil;Players[self.owner].units[self.id]=nil
  end
  function u:MoveTo(city) self.plot.units[self.id..':'..self.owner]=nil;self.plot=city:Plot();self.plot.units[self.id..':'..self.owner]=self end
  self.units[u.id]=u;u.plot.units[u.id..':'..self.id]=u
  GameEvents.UnitCreated(self.id,u.id,kind,x,y);return u
 end
 Players[pid]=p
end
function City(pid,id,x,y)
 local c={owner=pid,id=id,x=x,y=y,founded=turn,original=pid,name='Home '..id,buildings={},choices={},wltkd=0,growth=0,applies=0}
 function c:GetID() return self.id end;function c:GetOwner() return self.owner end
 function c:GetX() return self.x end;function c:GetY() return self.y end
 function c:GetGameTurnFounded() return self.founded end;function c:GetOriginalOwner() return self.original end
 function c:GetName() return self.name end;function c:IsRazing() return self.razing or false end
 function c:IsResistance() return self.resistance or false end
 function c:Plot() return Map.GetPlot(self.x,self.y) end
 function c:GetNumRealBuilding(id) return self.buildings[id] or 0 end
 function c:GetNumBuilding(id) return self:GetNumRealBuilding(id) end
 function c:SetNumRealBuilding(id,n) self.buildings[id]=n end
 function c:IsCityEventChoiceActive(id) return self.choices[id] or false end
 function c:DoCityEventChoice(id) assert(not self.choices[id],'native choice would stack!');self.choices[id]=true;self.growth=self.growth+5;self.applies=self.applies+1 end
 function c:DoCancelCityEventChoice(id) if self.choices[id] then self.choices[id]=false;self.growth=self.growth-5 end end
 function c:GetWeLoveTheKingDayCounter() return self.wltkd end
 function c:SetWeLoveTheKingDayCounter(n) self.wltkd=n end
 Players[pid].cities[id]=c;if not Players[pid].capital then Players[pid].capital=c end
 c:Plot().city=c;c:Plot().owner=pid
 for d=0,5 do Map.PlotDirection(x,y,d).owner=pid end
 return c
end
function Transfer(city,new)
 local old=city.owner;Players[old].cities[city.id]=nil
 if Players[old].capital==city then Players[old].capital=nil;for c in Players[old]:Cities() do Players[old].capital=c;break end end
 city.owner=new;Players[new].cities[city.id]=city;city:Plot().owner=new
 GameEvents.CityCaptureComplete(old,false,city.x,city.y,new,5,true)
end
function Settle(id,city)
 local H=MapModData.THE11CATS;local s=H.State(0);local u=H.Unit(s,id);assert(u,'no travel unit for '..id)
 u:MoveTo(city);local ok,reason=H.Command(0,id,'SETTLE');assert(ok,tostring(reason)..' '..id)
end
function UnitCount(pid) local n=0;for _ in Players[pid]:Units() do n=n+1 end;return n end
