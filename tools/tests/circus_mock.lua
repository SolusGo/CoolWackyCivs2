-- Source-shaped simulation only. Does not execute the Civ V DLL or serializer.
GameInfoTypes={CIVILIZATION_WCIRCUS=100, UNIT_WCIRCUS_CARNIVAL_CREW=101,
 BUILDING_WCIRCUS_TICKET_OFFICE=102, BUILDING_WCIRCUS_FESTIVAL_YIELDS=103,
 BUILDING_WCIRCUS_TICKET_PRODUCTION=104, BUILDING_WCIRCUS_EXPIRATION=105,
 BUILDING_WCIRCUS_NEXT_ELIGIBLE=106, BUILDING_WCIRCUS_PENDING_START=107,
 BUILDING_WCIRCUS_STAGED_TURN=108}
GameDefines={MAX_CIV_PLAYERS=8}
rawTurn=0; Players={}; plots={}; faults={}; nextUnit=0
Game={GetGameTurn=function() return rawTurn end}
Map={GetPlot=function(x,y) return plots[x..':'..y] end}
function Event()
 local handlers={}
 return {Add=function(fn) handlers[#handlers+1]=fn end,
 Fire=function(...) for _,fn in ipairs(handlers) do fn(...) end end,
 Count=function() return #handlers end}
end
function Context()
 GameEvents={};Events={}
 for _,name in ipairs({'PlayerDoneTurn','PlayerDoTurn','PlayerCityFounded','CityCaptureComplete',
  'CityConstructed','CitySoldBuilding','UnitPrekill','UnitSetXY'}) do GameEvents[name]=Event() end
 for _,name in ipairs({'SerialEventGameDataDirty','SerialEventCityInfoDirty','SpecificCityInfoDirty','LoadScreenClose'}) do Events[name]=Event() end
 ContextPtr={}
 function ContextPtr:SetUpdate(fn) assert(not self.callback,'double arm'); self.callback=fn end
 function ContextPtr:ClearUpdate() self.callback=nil end
end
function Flush()
 local n=0
 while ContextPtr.callback do n=n+1;assert(n<=1,'permanent polling');ContextPtr.callback() end
end
function Copy(v,seen)
 if type(v)~='table' then return v end
 seen=seen or {};if seen[v] then return seen[v] end
 local out={};seen[v]=out; for k,item in pairs(v) do out[k]=Copy(item,seen) end; return out
end
function Player(id,circus)
 local p={id=id,civ=circus and 100 or 1,alive=true,cities={},units={},human=true,
  active=true,endTurn=false,autoMoves=false,processed=false,busy=false}
 function p:GetCivilizationType() return self.civ end
 function p:IsAlive() return self.alive end
 function p:IsTurnActive() return self.active end
 function p:IsHuman() return self.human end
 function p:Cities()
  local keys={};for k in pairs(self.cities) do keys[#keys+1]=k end;table.sort(keys)
  local i=0;return function() i=i+1;return self.cities[keys[i]] end
 end
 function p:GetCityByID(id) return self.cities[id] end
 function p:GetUnitByID(id) return self.units[id] end
 Players[id]=p;return p
end
function City(p,id,hasOffice)
 local c={id=id,owner=p.id,x=id*10+p.id,y=1,b={[102]=hasOffice and 1 or 0},writes=0}
 function c:GetOwner() assert(not self.deleted,'deleted City accessed');return self.owner end
 function c:GetID() return self.id end
 function c:GetX() return self.x end
 function c:GetY() return self.y end
 function c:GetNumRealBuilding(b) assert(not self.deleted);return self.b[b] or 0 end
 function c:GetNumBuilding(b) return self:GetNumRealBuilding(b) end
 function c:SetNumRealBuilding(b,n,noBonus)
  assert(not self.deleted and noBonus==true and n>=0 and n==math.floor(n),'invalid setter')
  if b==103 or b==104 then assert(n<=1,'stacking yield dummy') end
  self.b[b]=n; self.writes=self.writes+1
  Events.SerialEventGameDataDirty.Fire()
  Events.SerialEventCityInfoDirty.Fire()
  Events.SpecificCityInfoDirty.Fire(self.owner,self.id,1)
  if faults.setter then faults.setter=false;error('setter failed after mutation') end
 end
 local plot={city=c,units={}}
 function plot:GetPlotCity() return self.city end
 function plot:GetNumUnits() return #self.units end
 function plot:GetUnit(i) return self.units[i+1] end
 plots[c.x..':'..c.y]=plot;p.cities[id]=c;return c
end
function PlotOf(c) return Map.GetPlot(c.x,c.y) end
function Unit(p,c,kind,original)
 nextUnit=nextUnit+1
 local u={id=nextUnit,owner=p.id,original=original or p.id,kind=kind or 101,plot=PlotOf(c)}
 function u:GetID() return self.id end
 function u:GetOwner() return self.owner end
 function u:GetOriginalOwner() return self.original end
 function u:GetUnitType() return self.kind end
 function u:IsDead() return self.dead end
 function u:IsDelayedDeath() return self.delayed end
 u.plot.units[#u.plot.units+1]=u;p.units[u.id]=u;return u
end
function Detach(u)
 if u.plot then for i,v in ipairs(u.plot.units) do if v==u then table.remove(u.plot.units,i);break end end end
 u.plot=nil
end
function Move(u,c)
 Detach(u)
 if c then u.plot=PlotOf(c);u.plot.units[#u.plot.units+1]=u end
 GameEvents.UnitSetXY.Fire(u.owner,u.id,c and c.x or -1,c and c.y or -1)
end
function Kill(u)
 -- Prekill sees the still-existing unit; Lua must exclude its ID explicitly.
 GameEvents.UnitPrekill.Fire(u.owner,u.id,u.kind,0,0,true,-1)
 u.delayed=true;Detach(u);Players[u.owner].units[u.id]=nil
end
function AssertYields(c,culture,gold,production)
 local a,b,d=Harvest(c)
 assert(a==culture and b==gold and d==production,
  'wrong bonuses at '..rawTurn..': '..a..','..b..','..d..' expected '..culture..','..gold..','..production)
end
function Setup(offset)
 rawTurn=offset or startTurn or 0;Players={};plots={};nextUnit=0;faults={};Context()
 local p=Player(0,true); local c=City(p,1,true);local u=Unit(p,c)
 local ai=Player(1,false);ai.active=false;ai.human=false;LoadCircus();return p,c,u
end
function EndTurn(p)
 p.active=false;p.endTurn=true;p.autoMoves=true;p.processed=true
 GameEvents.PlayerDoneTurn.Fire(p.id)
end
function BeginTurn(p)
 rawTurn=rawTurn+1
 p.active=true;p.endTurn=false;p.autoMoves=false;p.processed=false
 -- These values stand in for native economics, which runs BEFORE PlayerDoTurn.
 local result={};for c in p:Cities() do result[c.id]={Harvest(c)} end
 GameEvents.PlayerDoTurn.Fire(p.id);return result
end
function Save()
 return Copy({players=Players,plots=plots,turn=rawTurn,nextUnit=nextUnit})
end
function Restore(snapshot)
 -- Re-link pointers explicitly, as native deserialization would do.
 local s=Copy(snapshot);Players=s.players;plots=s.plots;rawTurn=s.turn;nextUnit=s.nextUnit
 for _,p in pairs(Players) do
  -- CP serializes active/end/automove flags, but rebuilds processed automoves.
  p.processed=false
  for _,c in pairs(p.cities) do
   local plot=PlotOf(c);plot.city=c;plot.units={}
  end
  for _,u in pairs(p.units) do
   if u.plot then local c=u.plot.city;u.plot=Map.GetPlot(c.x,c.y);u.plot.units[#u.plot.units+1]=u end
  end
 end
 Context();LoadCircus();Events.LoadScreenClose.Fire();Flush()
end
function Transfer(c,p,kind)
 local old=c.owner
 Players[old].cities[c.id]=nil;c.owner=p.id;p.cities[c.id]=c
 -- Deliberately retain all buildings to test explicit cleanup, independent of NeverCapture.
 GameEvents.CityCaptureComplete.Fire(old,false,c.x,c.y,p.id,4,kind=='capture')
end
Context()
