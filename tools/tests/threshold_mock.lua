-- Deliberately models only audited CP contracts; this is not a game runtime.
turn=100;activePlayer=0;MapModData={};DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
NotificationTypes={NOTIFICATION_GENERIC=1};Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
InterfaceModeTypes={INTERFACEMODE_SELECTION=0}
function Event()
 local e={handlers={}}
 function e.Add(f) e.handlers[#e.handlers+1]=f end
 function e.Remove(f) for i=#e.handlers,1,-1 do if e.handlers[i]==f then table.remove(e.handlers,i) end end end
 function e.Fire(...)
  local yes=true
  for _,f in ipairs(e.handlers) do if f(...)==false then yes=false end end
  return yes
 end
 return e
end
Events=setmetatable({},{__index=function(t,k)local e=Event();rawset(t,k,e);return e end})
GameEvents=setmetatable({},{__index=function(t,k)local e=Event();rawset(t,k,e);return e end})
Game={GetGameTurn=function()return turn end,GetActivePlayer=function()return activePlayer end}
Locale={ConvertTextKey=function(k,...)
 local value=Texts[k] or k;local args={...}
 return (value:gsub('{(%d+)_[^}]+}',function(i)return tostring(args[tonumber(i)])end))
end}
function Control()
 local c={hidden=false,disabled=false}
 function c:SetHide(v) self.hidden=v end
 function c:SetDisabled(v) self.disabled=v end
 function c:SetText(v) self.text=v end
 function c:SetToolTipString(v) self.tip=v end
 function c:RegisterCallback(_,f) self.click=f end
 function c:CalculateSize() end
 function c:ReprocessAnchoring() end
 function c:CalculateInternalSize() end
 return c
end
function NewContext()
 local c={}
 function c:SetUpdate(f) self.update=f end
 function c:ClearUpdate() self.update=nil end
 function c:SetInputHandler(f) self.input=f end
 function c:SetShowHideHandler(f) self.show=f end
 return c
end
ContextPtr=NewContext()
Controls=setmetatable({},{__index=function(t,k)local c=Control();rawset(t,k,c);return c end})
InstanceManager={}
function InstanceManager:new()
 local im={items={}}
 function im:ResetInstances() self.items={} end
 function im:GetInstance()
  local item={Row=Control(),Name=Control(),Status=Control()};self.items[#self.items+1]=item;return item
 end
 MockRows=im;return im
end
function TruncateString(c,_,s)c:SetText(s)end
UI={GetHeadSelectedUnit=function()return selected end,IsCityScreenUp=function()return false end,
 IsGameCoreBusy=function()return false end,GetInterfaceMode=function()return 0 end,
 SelectUnit=function(u)selected=u end}
local function Script(o)
 o.raw='foreign-data'
 function o:GetScriptData()return self.raw end
 function o:SetScriptData(v)
  if self.failWrites and self.failWrites>0 then self.failWrites=self.failWrites-1;error('injected write failure') end
  if self.onWrite then self:onWrite(v) end
  self.raw=v
 end
 return o
end
local plots={}
Map={GetPlot=function(x,y)return plots[x..':'..y]end}
function Plot(x,y)
 local p=Script({x=x,y=y,units={}});plots[x..':'..y]=p
 function p:GetPlotCity()return self.city end
 function p:GetNumUnits()return #self.units end
 function p:GetUnit(i)return self.units[i+1]end
 function p:IsCity()return self.city~=nil end
 return p
end
function City(p,id,x,y)
 local plot=Map.GetPlot(x,y) or Plot(x,y)
 local c={owner=p.id,id=id,x=x,y=y,born=1,founder=p.id,house=1,name='City '..id}
 function c:GetOwner()return self.owner end
 function c:GetID()return self.id end
 function c:GetX()return self.x end
 function c:GetY()return self.y end
 function c:GetGameTurnFounded()return self.born end
 function c:GetOriginalOwner()return self.founder end
 function c:GetNumBuilding()return self.house end
 function c:GetName()return self.name end
 function c:Plot()return plot end
 plot.city=c;p.cities[#p.cities+1]=c;return c
end
function Player(id,civ)
 local p=Script({id=id,civ=civ,human=true,alive=true,active=id==0,gold=1000,era=2,cities={},units={},notices={}})
 function p:IsAlive()return self.alive end
 function p:IsHuman()return self.human end
 function p:GetCivilizationType()return self.civ end
 function p:IsTurnActive()return self.active end
 function p:GetCurrentEra()return self.era end
 function p:GetGold()return self.gold end
 function p:ChangeGold(n)
  if self.goldFault=='before' then self.goldFault=nil;error('before charge') end
  self.gold=self.gold+n
  if self.goldFault=='after' then self.goldFault=nil;error('after charge') end
 end
 function p:GetTeam()return self.id end
 function p:GetUnitByID(id)return self.units[id]end
 function p:Cities()local i=0;return function()i=i+1;return self.cities[i]end end
 function p:Units()local k=nil;return function()local v;k,v=next(self.units,k);return v end end
 function p:AddNotification(_,text)self.notices[#self.notices+1]=text end
 return p
end
Players={[0]=Player(0,GameInfoTypes.CIVILIZATION_THRESHOLD_COURT),[1]=Player(1,-123)}
Teams={[0]={IsAtWar=function(_,id)return id~=0 end},[1]={IsAtWar=function(_,id)return id~=1 end}}
function Place(u,x,y)
 if u.x then
  local old=Map.GetPlot(u.x,u.y)
  for i=#old.units,1,-1 do if old.units[i]==u then table.remove(old.units,i) end end
 end
 u.x=x;u.y=y;local plot=Map.GetPlot(x,y) or Plot(x,y);plot.units[#plot.units+1]=u
end
function Unit(p,id,x,y)
 local u=Script({owner=p.id,id=id,kind=GameInfoTypes.UNIT_THRESHOLD_HINGEGUARD,born=7,moves=180,damage=37,xp=123,attacks=0,promos={},domain=0,combat=true,ranged=false})
 function u:IsDead()return self.dead or false end
 function u:IsDelayedDeath()return self.delayed or false end
 function u:GetOwner()return self.owner end
 function u:GetID()return self.id end
 function u:GetGameTurnCreated()return self.born end
 function u:GetUnitType()return self.kind end
 function u:GetDomainType()return self.domain end
 function u:IsCombatUnit()return self.combat end
 function u:IsRanged()return self.ranged end
 function u:IsEmbarked()return self.embarked or false end
 function u:IsOnlyDefensive()return self.defensive or self.promos[GameInfoTypes.PROMOTION_THRESHOLD_EXHAUSTED] or false end
 function u:IsCanAttackWithMove()return self.combat and not self.ranged and not self:IsOnlyDefensive() end
 function u:GetPlot()return Map.GetPlot(self.x,self.y)end
 function u:GetX()return self.x end
 function u:GetY()return self.y end
 function u:GetName()return 'Hingeguard '..self.id end
 function u:IsBusy()return self.busy or false end
 function u:MovesLeft()return self.moves end
 function u:FinishMoves()self.moves=0 end
 function u:SetMoves(n)self.moves=n end
 function u:SetMadeAttack(b)self.attacks=b and self.attacks+1 or 0 end
 function u:IsHasPromotion(id)return self.promos[id] or false end
 function u:SetHasPromotion(id,on)
  if self.promoFault then self.promoFault=nil;error('promotion restriction failure') end
  self.promos[id]=on
 end
 function u:CanMoveOrAttackInto(plot,unused,flag)
  assert(unused==0 and flag==1,'CP destination binding uses numeric fourth argument')
  if self.reject then return false end
  for _,other in ipairs(plot.units)do if other~=self and other:IsCombatUnit()then return false end end
  return GameEvents.CanMoveInto.Fire(self.owner,self.id,plot.x,plot.y,false,false)
 end
 function u:SetXY(x,y,a,b,c,d)
  assert(a==0 and b==1 and type(c)=='number' and d==0,'SetXY flags must be numeric')
  if self.moveFault=='before' then self.moveFault=nil;error('before relocation') end
  if self.moveFault=='noop' then self.moveFault=nil;return end
  if self.moveFault=='adjacent' then self.moveFault=nil;x=x+1 end
  Place(self,x,y);GameEvents.UnitSetXY.Fire(self.owner,self.id,x,y)
  if self.onMove then self:onMove() end
  if self.moveFault=='after' then self.moveFault=nil;error('after relocation') end
 end
 p.units[id]=u;Place(u,x,y);return u
end
origin=City(Players[0],0,3,4);destination=City(Players[0],1,119,75);third=City(Players[0],2,15,26)
unit=Unit(Players[0],0,3,4);selected=unit
function Court()return MapModData.ThresholdCourt end
function Snapshot(u,c)
 return {unit=Court().UnitToken(u),origin=Court().CityToken(c or Court().Origin(0,u))}
end
function NextTurn(n)
 turn=n or turn+1
 -- Model native turn replenishment before PlayerDoTurn/active-turn events.
 for _,u in pairs(Players[0].units)do u.moves=180;u.attacks=0 end
 GameEvents.PlayerDoTurn.Fire(0);Events.ActivePlayerTurnStart.Fire()
end
function Drain()local f=ContextPtr.update;if f then f()end end
