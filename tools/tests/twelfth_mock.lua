-- A CP-shaped fixture, NOT the Civ V engine. Harvest order is audited separately.
GameInfoTypes={CIVILIZATION_TWELFTH_HOUR=100,BUILDING_TWELFTH_GRAND_CHIME=101,
 BUILDING_TWELFTH_CLOCKTOWER_CHIME=102,BUILDING_TWELFTH_MUNICIPAL_CLOCKTOWER=103}
GameDefines={MAX_CIV_PLAYERS=8}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key) return key end}
rawTurn=0;startTurn=0
Game={GetGameTurn=function() return rawTurn end,GetStartTurn=function() return startTurn end}
Players={};GameEvents={};Events={};saved={};saveWrites=0
Modding={OpenSaveData=function() return {
 GetValue=function(_,k) return saved[k] end,
 SetValue=function(_,k,v) saved[k]=v;saveWrites=saveWrites+1 end} end}
function NewEvent()
 local list={}
 return {Add=function(fn) list[#list+1]=fn end,
 Fire=function(...) for _,fn in ipairs(list) do fn(...) end end,
 Count=function() return #list end}
end
function ResetContext()
 GameEvents={};Events={}
 for _,name in ipairs({'PlayerDoneTurn','PlayerDoTurn','PlayerCityFounded','CityCaptureComplete',
 'CityConstructed','CitySoldBuilding'}) do GameEvents[name]=NewEvent() end
 for _,name in ipairs({'SerialEventGameDataDirty','LoadScreenClose'}) do Events[name]=NewEvent() end
 ContextPtr={callback=nil,arms=0,clears=0}
 function ContextPtr:SetUpdate(fn) self.callback=fn;self.arms=self.arms+1 end
 function ContextPtr:ClearUpdate() self.callback=nil;self.clears=self.clears+1 end
end
function Flush()
 local loops=0
 while ContextPtr.callback do
  loops=loops+1;assert(loops<4,'permanent update loop')
  ContextPtr.callback()
 end
end
function NewPlayer(id,clock)
 local p={id=id,civ=clock and 100 or 1,alive=true,human=true,active=false,cities={},notices=0}
 function p:GetCivilizationType() return self.civ end
 function p:IsAlive() return self.alive end
 function p:IsHuman() return self.human end
 function p:IsTurnActive() return self.active end
 function p:Cities()
  local keys={};for k in pairs(self.cities) do keys[#keys+1]=k end;table.sort(keys)
  local i=0;return function() i=i+1;return self.cities[keys[i]] end
 end
 function p:AddNotification() self.notices=self.notices+1 end
 Players[id]=p;return p
end
function NewCity(p,id,hasTower)
 local c={id=id,owner=p.id,buildings={[101]=0,[102]=0,[103]=hasTower and 1 or 0},writes=0,
  baseProduction=20,baseScience=30,progress=0}
 function c:GetNumRealBuilding(b) return self.buildings[b] or 0 end
 function c:GetNumBuilding(b) return self.buildings[b] or 0 end
 function c:SetNumRealBuilding(b,n,noBonus)
  assert(noBonus==true and (n==0 or n==1),'stacking or construction rewards')
  self.buildings[b]=n;self.writes=self.writes+1
  Events.SerialEventGameDataDirty.Fire()
 end
 p.cities[id]=c;return c
end
function AssertBonus(c,chime,tower)
 assert(c.buildings[101]==chime,'wrong global modifier')
 assert(c.buildings[102]==tower,'wrong Clocktower flat yield')
end
ResetContext()
