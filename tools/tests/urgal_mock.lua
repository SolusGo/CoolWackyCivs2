-- Exercises shipped Lua under Lua 5.1. This is not the Civ V engine.
now,activePlayer,speed=0,0,'GAMESPEED_STANDARD'
MapModData,Players,Teams,GameEvents,Events,plots={},{},{},{},{},{}
GameDefines={MAX_CIV_PLAYERS=5}
DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
GameInfoTypes={CIVILIZATION_URGAL=100,PROMOTION_URGAL_STRENGTH_II=101,PROMOTION_URGAL_POT_CHASER=102,PROMOTION_URGAL_POT_RECOVERY=103}
NotificationTypes={NOTIFICATION_GENERIC=0}
Game={GetGameTurn=function() return now end,GetGameSpeedType=function() return 0 end,GetActivePlayer=function() return activePlayer end}
GameInfo={GameSpeeds=setmetatable({},{__index=function() return {Type=speed,TrainPercent=speedPercent or 100} end}),Units={}}
for i,class in ipairs({'UNITCOMBAT_MELEE','UNITCOMBAT_MOUNTED','UNITCOMBAT_GUN','UNITCOMBAT_ARMOR','UNITCOMBAT_ARCHER','UNITCOMBAT_SIEGE','UNITCOMBAT_RECON','UNITCOMBAT_HELICOPTER','UNITCOMBAT_MODDED'}) do
 GameInfo.Units[i]={Combat=14,CombatClass=class,RangedCombat=(i==5 or i==6) and 10 or 0}
end
Locale={Length=string.len,Substring=string.sub,ConvertTextKey=function(key,...)
 local text=NativeText and NativeText[key]
 if not text then return key end
 local args={...}
 return (text:gsub('{(%d+)_[^}]+}',function(n) return tostring(args[tonumber(n)]) end))
end}
function Event()
 local e={handlers={}}
 e.Add=function(f) e.handlers[#e.handlers+1]=f end
 e.Remove=function(f) for i=#e.handlers,1,-1 do if e.handlers[i]==f then table.remove(e.handlers,i) end end end
 e.Fire=function(...) local copy={};for i,f in ipairs(e.handlers) do copy[i]=f end;for _,f in ipairs(copy) do f(...) end end
 return e
end
for _,n in ipairs({'PlayerDoTurn','TeamSetEra','UnitCreated','UnitConverted','UnitSetXY'}) do GameEvents[n]=Event() end
for _,n in ipairs({'SequenceGameInitComplete','LoadScreenClose','SerialEventGameDataDirty','UnitSelectionChanged','SerialEventEnterCityScreen','SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopupShown','SerialEventGameMessagePopupProcessed','ActivePlayerTurnEnd','ActivePlayerTurnStart','GameplaySetActivePlayer','InterfaceModeChanged'}) do Events[n]=Event() end
function NewPlayer(id,civ,human)
 local p={id=id,civ=civ or 0,human=human,era=0,raw='OTHER_MOD_DATA',units={},notices={}}
 function p:IsAlive() return true end
 function p:IsHuman() return self.human end
 function p:GetCivilizationType() return self.civ end
 function p:GetTeam() return self.team or self.id end
 function p:GetCurrentEra() return self.era end
 function p:GetScriptData() return self.raw end
 function p:SetScriptData(s) self.raw=s end
 function p:GetUnitByID(i) return self.units[i] end
 function p:IsTurnActive() return not self.inactive end
 function p:AddNotification(_,text) if self.failNotice then error('injected notification failure') end;self.notices[#self.notices+1]=text end
 function p:Units() local key;return function() key=next(self.units,key);return key and self.units[key] end end
 Players[id]=p;Teams[id]={wars={},IsAtWar=function(self,t) return self.wars[t]==true end}
 return p
end
for i=0,4 do NewPlayer(i,i==0 and 100 or 0,i==0) end
function NewUnit(id,owner,kind)
 local u={id=id,owner=owner,kind=kind or 1,promotions={},raw='UNIT_OTHER_DATA',domain=0,x=0,y=0,moves=120}
 function u:IsDead() return self.dead or false end
 function u:IsDelayedDeath() return self.delayed or false end
 function u:IsCombatUnit() return not self.civilian end
 function u:GetDomainType() return self.domain end
 function u:IsRanged() return GameInfo.Units[self.kind].RangedCombat>0 end
 function u:IsEmbarked() return self.embarked or false end
 function u:IsInvisible() return self.invisible or false end
 function u:GetUnitType() return self.kind end
 function u:GetID() return self.id end
 function u:GetOwner() return self.owner end
 function u:GetX() return self.x end
 function u:GetY() return self.y end
 function u:MovesLeft() return self.moves end
 function u:IsOutOfAttacks() return self.exhausted or false end
 function u:CanMoveOrAttackInto(plot) return not self.unreachable end
 function u:GetScriptData() return self.raw end
 function u:SetScriptData(s) self.raw=s end
 function u:IsHasPromotion(p) return self.promotions[p]==true end
 function u:SetHasPromotion(p,on) if self.failPromo then error('injected promotion failure') end;self.promotions[p]=on end
 Players[owner].units[id]=u;return u
end
function NewPlot(x,y,owner)
 local p={x=x,y=y,owner=owner or -1,units={},visible=true}
 function p:GetX() return self.x end
 function p:GetY() return self.y end
 function p:GetOwner() return self.owner end
 function p:IsVisible() return self.visible end
 function p:GetPlotCity() return self.city end
 function p:GetNumUnits() return #self.units end
 function p:GetUnit(n) return self.units[n+1] end
 plots[x..','..y]=p;return p
end
Map={PlotDistance=function(ax,ay,bx,by) return math.max(math.abs(ax-bx),math.abs(ay-by),math.abs((ax+ay)-(bx+by))) end,
 PlotXYWithRangeCheck=function(x,y,dx,dy,r) if Map.PlotDistance(x,y,x+dx,y+dy)>r then return nil end;return plots[(x+dx)..','..(y+dy)] end}
function NewContext()
 ContextPtr={SetShutdown=function(self,f) self.shutdown=f end,SetUpdate=function(self,f) self.update=f end,ClearUpdate=function(self) self.update=nil end,SetShowHideHandler=function(self,f) self.showhide=f end}
end
function Flush() if ContextPtr.update then ContextPtr.update() end end
function Check(u,on,recovery)
 assert(u:IsHasPromotion(101)==on,'Strength II expected '..tostring(on)..' for unit '..u.id)
 if recovery~=nil then assert(u:IsHasPromotion(103)==recovery,'recovery expected '..tostring(recovery)) end
end
function Convert(old,newOwner,newID,upgrade,kind)
 local u=NewUnit(newID,newOwner,kind or old.kind)
 -- CP creates first, then copies only non-lost promotions, then converts.
 GameEvents.UnitCreated.Fire(newOwner,newID)
 if old:IsHasPromotion(102) then u:SetHasPromotion(102,true) end
 GameEvents.UnitConverted.Fire(old.owner,newOwner,old.id,newID,upgrade)
 Players[old.owner].units[old.id]=nil;old.dead=true
 return u
end
function LoadUI()
 Controls={}
 for _,name in ipairs({'Inventory','Stockpile','Status','Drink'}) do
  Controls[name]={SetHide=function(self,v) self.hidden=v end,SetText=function(self,v) self.text=v end,GetText=function(self) return self.text or '' end,GetSizeX=function(self) return #(self.text or '')*8 end,SetDisabled=function(self,v) self.disabled=v end,SetToolTipString=function(self,v) self.tooltip=v end,RegisterCallback=function(self,_,fn) self.click=fn end}
 end
 UI={IsCityScreenUp=function() return false end,IsGameCoreBusy=function() return false end,GetInterfaceMode=function() return 0 end}
 InterfaceModeTypes={INTERFACEMODE_SELECTION=0};Mouse={eLClick=1}
 LoadUrgalUI()
end
NewContext()
