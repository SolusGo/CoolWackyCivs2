-- Native engine double. Tests execute the shipped Kingdom Lua, never a rewritten controller.
GameInfo,GameInfoTypes={},{}
for name,rows in pairs(CK_DATABASE) do
 local by={};for _,r in ipairs(rows) do if r.Type then by[r.Type]=r;GameInfoTypes[r.Type]=r.ID end;if r.ID then by[r.ID]=r end end
 setmetatable(by,{__call=function(_,filter)
  local i=0;return function() while true do i=i+1;local r=rows[i];if not r then return end
   local ok=true;for k,v in pairs(filter or {}) do if r[k]~=v then ok=false end end;if ok then return r end
  end end
 end});GameInfo[name]=by
end
local function event()
 local e={handlers={}};function e.Add(fn) e.handlers[#e.handlers+1]=fn end
 return setmetatable(e,{__call=function(_,...) local result;for _,fn in ipairs(e.handlers) do local r=fn(...);if r~=nil then result=r end end;return result end})
end
function ResetEvents()
 local function list() return setmetatable({},{__index=function(t,k)local e=event();rawset(t,k,e);return e end}) end
 GameEvents,Events,LuaEvents=list(),list(),list()
end
ResetEvents();MapModData={};GameDefines={MAX_CIV_PLAYERS=4};NotificationTypes={NOTIFICATION_GENERIC=1}
TEST={turn=0,active=0,speed=GameInfoTypes.GAMESPEED_STANDARD,controls={},screens={},cityScreen=false,mode=1}
Game={GetGameTurn=function() return TEST.turn end,GetGameSpeedType=function() return TEST.speed end,GetActivePlayer=function() return TEST.active end,IsNetworkMultiPlayer=function() return TEST.network or false end,IsHotSeat=function() return TEST.hotseat or false end}
Locale={ConvertTextKey=function(key,...)
 local text=CK_TEXT[key] or key;local args={...}
 return (text:gsub('{(%d+)_[^}]+}',function(n)return tostring(args[tonumber(n)]) end))
end}
local function iterator(t) local i=0;return function() i=i+1;return t[i] end end
local plotIndex={}
Map={GetPlot=function(x,y)return plotIndex[x..':'..y] end}
local Plot={};Plot.__index=Plot
function Plot:IsFriendlyTerritory(pid) return self.owner==pid or self.friendly==pid end
function Plot:GetPlotCity() return self.city end
function Plot:GetOwner() return self.owner end
function Plot:GetNumUnits() return #self.units end
function Plot:GetUnit(i) return self.units[i+1] end
function TEST.plot(x,y,owner)
 local key=x..':'..y
 if not plotIndex[key] then plotIndex[key]=setmetatable({x=x,y=y,owner=owner,units={}},Plot) end
 return plotIndex[key]
end
local City={};City.__index=City
function City:GetID() return self.id end
function City:GetNumRealBuilding(id) return self.buildings[id] or 0 end
function City:SetNumRealBuilding(id,n) self.buildings[id]=n end
function City:IsProductionUnit() return self.queue=='unit' end
function City:IsProductionBuilding() return self.queue=='building' end
function City:IsProductionProject() return self.queue=='project' end
function City:GetProduction() return self.production end
function City:GetProductionTimes100() return self.production*100+(self.fraction or 0) end
function City:GetProductionNeeded() return self.needed end
function City:SetProduction(n) assert(self.queue=='unit' or self.queue=='building' or self.queue=='project');assert(n<=self.needed,'unsafe overflow');self.production=n end
function City:ChangeProduction(n) assert(self.queue=='unit' or self.queue=='building' or self.queue=='project');assert(self:GetProductionTimes100()+n*100<=self.needed*100,'unsafe overflow');self.production=self.production+n end
function City:ChangeFood(n) self.food=self.food+n end
function City:bonus(yield)
 local total=0
 for r in GameInfo.Building_YieldChanges() do total=total+(self.buildings[GameInfoTypes[r.BuildingType]] or 0)*(r.YieldType==yield and r.Yield or 0) end
 return total
end
function City:culture()
 local percent=100;for id,n in pairs(self.buildings) do percent=percent+n*(GameInfo.Buildings[id].CultureRateModifier or 0) end
 return (self.baseCulture+self:bonus('YIELD_CULTURE'))*percent/100
end
local Player={};Player.__index=Player
function Player:IsHuman() return self.human end
function Player:IsAlive() return self.alive end
function Player:IsTurnActive() return self.turnActive end
function Player:GetCivilizationType() return self.civ end
function Player:GetCurrentEra() return self.era end
function Player:GetCapitalCity() return self.cap end
function Player:Cities() return iterator(self.cities) end
function Player:Units() return iterator(self.units) end
function Player:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
function Player:GetScriptData() return self.script end
function Player:SetScriptData(raw) self.script=raw end
function Player:HasPolicy(id) return self.policies[id]~=nil end
function Player:SetHasPolicy(id,on,free) self.policies[id]=on and {free=free} or nil end
function Player:ChangeFaith(n) self.faith=self.faith+n end
function Player:ChangeGoldenAgeProgressMeter(n) self.gap=self.gap+n end
function Player:AddNotification(kind,text,title) self.notifications[#self.notifications+1]={text=text,title=title} end
function Player:happiness() local n=0;for id in pairs(self.policies) do n=n+(GameInfo.Policies[id].ExtraHappiness or 0) end;return n end
function Player:strength() local n=0;for id in pairs(self.policies) do n=n+(GameInfo.Policies[id].CityStrengthMod or 0) end;return n end
function Player:paidPolicies() local n=0;for _,r in pairs(self.policies) do if not r.free then n=n+1 end end;return n end
local Unit={};Unit.__index=Unit
function Unit:GetOwner() return self.owner end
function Unit:GetID() return self.id end
function Unit:GetGameTurnCreated() return self.born end
function Unit:IsDead() return self.dead or false end
function Unit:IsDelayedDeath() return false end
function Unit:IsCombatUnit() return self.military end
function Unit:IsRanged() return self.ranged or false end
function Unit:IsHasPromotion(id) return self.promotions[id] or false end
function Unit:SetHasPromotion(id,on) self.promotions[id]=on end
function Unit:GetPlot() return self.plot end
function Unit:GetUnitType() return self.typ end
function TEST.unit(pid,typ,military,plot)
 local p=Players[pid];local u=setmetatable({id=#p.units+1,born=TEST.turn,owner=pid,typ=typ,military=military,promotions={},plot=plot or p.cap.plot},Unit)
 p.units[#p.units+1]=u;u.plot.units[#u.plot.units+1]=u;return u
end
function TEST.city(pid,id)
 local plot=TEST.plot(pid*10+id,1,pid)
 local city=setmetatable({id=id,buildings={},production=0,needed=40,queue='building',food=0,baseCulture=20,plot=plot},City)
 plot.city=city;Players[pid].cities[#Players[pid].cities+1]=city;return city
end
Players={}
for pid=0,3 do
 Players[pid]=setmetatable({civ=pid<2 and GameInfoTypes.CIVILIZATION_CK_KINGDOM or GameInfoTypes.CIVILIZATION_AMERICA,human=pid%2==0,alive=true,turnActive=true,era=0,cities={},units={},policies={},script='unrelated mod payload',faith=0,gap=0,notifications={}},Player)
 TEST.city(pid,1);TEST.city(pid,2);Players[pid].cap=Players[pid].cities[1]
 TEST.unit(pid,GameInfoTypes.UNIT_CK_KEEPER,true);TEST.unit(pid,GameInfoTypes.UNIT_WORKER,false)
end
function TEST.nextTurn(n)
 for i=1,n or 1 do
  TEST.turn=TEST.turn+1
  -- CP computes native city yields before PlayerDoTurn. Accumulate the actual
  -- SQL dummy yields first, then dispatch the real controller's expiration hook.
  for _,p in pairs(Players) do if p.alive then
   for _,c in ipairs(p.cities) do p.faith=p.faith+c:bonus('YIELD_FAITH');c.food=c.food+c:bonus('YIELD_FOOD') end
  end end
  for pid=0,3 do GameEvents.PlayerDoTurn(pid) end
 end
end
function TEST.pray()
 local k=MapModData.CKPrayer;local s=k.states[0];assert(k.Pray(0,s.stage,s.ready));return s
end
function TEST.advance() local s=MapModData.CKPrayer.states[0];TEST.nextTurn(math.max(0,s.ready-TEST.turn)) end
function TEST.move(u,plot)
 for i,v in ipairs(u.plot.units) do if v==u then table.remove(u.plot.units,i);break end end
 u.plot=plot;plot.units[#plot.units+1]=u;GameEvents.UnitSetXY(u.owner,u.id,plot.x,plot.y)
end
UI={IsCityScreenUp=function()return TEST.cityScreen end,GetInterfaceMode=function()return TEST.mode end}
InterfaceModeTypes={INTERFACEMODE_SELECTION=1};Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
ContextPtr={LookUpControl=function(_,path)return TEST.screens[path] end,SetInputHandler=function(_,fn) TEST.input=fn end,
 SetShowHideHandler=function(_,fn) TEST.showhide=fn end,
 SetUpdate=function(_,fn) assert(type(fn)=='function');TEST.updates=(TEST.updates or 0)+1;TEST.update=fn end,
 ClearUpdate=function() TEST.update=nil end}
function TEST.pump() if TEST.update then TEST.update() end end
Controls=setmetatable({},{__index=function(t,name)
 local c={hidden=false,disabled=false};function c:SetHide(v)self.hidden=v end;function c:IsHidden()return self.hidden end
 function c:SetText(v)self.text=v end;function c:SetDisabled(v)self.disabled=v end;function c:SetToolTipString(v)self.tip=v end
 function c:RegisterCallback(_,fn)self.click=fn end;function c:CalculateSize()end;function c:ReprocessAnchoring()end;function c:CalculateInternalSize()end
 rawset(t,name,c);return c
end})
