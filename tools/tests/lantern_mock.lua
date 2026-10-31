-- Simulates API contracts only, never native DLL event ordering or payouts.
function LF_Event()
  local e = {handlers={}}
  function e.Add(f) e.handlers[#e.handlers+1]=f end
  function e.Remove(f) for i=#e.handlers,1,-1 do if e.handlers[i]==f then table.remove(e.handlers,i) end end end
  function e.Fire(...) local copy={unpack(e.handlers)}; for _,f in ipairs(copy) do f(...) end end
  return e
end
GameInfoTypes={CIVILIZATION_LANTERN_FLEET=1,BUILDING_LANTERN_SIGNAL_LIGHTHOUSE=2,
  BUILDING_LANTERN_GUARDED_HARBOR=3,BUILDING_LANTERN_SIGNAL_GOLD=4}
DomainTypes={DOMAIN_SEA=1,DOMAIN_LAND=0,DOMAIN_AIR=2}
MapModData={}
Events={AIProcessingStartedForPlayer=LF_Event(),LoadScreenClose=LF_Event(),
  SerialEventUnitMoveToHex=LF_Event(),ActivePlayerTurnStart=LF_Event(),SequenceGameInitComplete=LF_Event()}
GameEvents={CityCaptureComplete=LF_Event(),PlayerDoTurn=LF_Event(),CityConstructed=LF_Event(),UnitSetXY=LF_Event()}
LF_Turn,LF_Writes=10,0
Game={GetGameTurn=function() return LF_Turn end}
ContextPtr={SetShutdown=function(self,f) self.shutdown=f end}
function LF_Unit(owner,domain,combat,embarked)
  return {owner=owner or 0,domain=domain or 1,combat=combat~=false,embarked=embarked or false,
    GetOwner=function(s)return s.owner end,GetDomainType=function(s)return s.domain end,
    IsCombatUnit=function(s)return s.combat end,IsEmbarked=function(s)return s.embarked end,
    IsDead=function(s)return s.dead or false end,IsDelayedDeath=function(s)return s.delayed or false end}
end
function LF_City(owner,coast)
  local c={owner=owner or 0,coast=coast~=false,buildings={},units={}}
  c.GetOwner=function(s)return s.owner end
  c.IsCoastal=function(s,min)assert(min==-1);return s.coast end
  c.GetNumRealBuilding=function(s,b)return s.buildings[b] or 0 end
  c.GetNumBuilding=c.GetNumRealBuilding
  c.SetNumRealBuilding=function(s,b,n) assert(n==0 or n==1);s.buildings[b]=n;LF_Writes=LF_Writes+1 end
  local plot={GetNumUnits=function()return #c.units end,GetUnit=function(s,i)return c.units[i+1] end,
    GetPlotCity=function()return c end}
  c.Plot=function()return plot end
  return c
end
function LF_Player(id,civ)
  return {id=id,civ=civ or 1,data='unrelated-script-data',cities={},active=false,alive=true,human=true,
    GetCivilizationType=function(s)return s.civ end,IsAlive=function(s)return s.alive end,
    IsHuman=function(s)return s.human end,IsTurnActive=function(s)return s.active end,
    GetScriptData=function(s)return s.data end,SetScriptData=function(s,d)s.data=d end,
    Cities=function(s)local i=0;return function()i=i+1;return s.cities[i] end end}
end
Players={[0]=LF_Player(0),[1]=LF_Player(1,9),[2]=LF_Player(2)}
LF_Harbor=LF_City(0,true);Players[0].cities={LF_Harbor}
Map={GetPlot=function()return LF_Harbor:Plot() end}
function LF_Load() LF_LoadSource() end
function LF_Start(id,advance)
  if advance~=false then LF_Turn=LF_Turn+1 end
  for _,p in pairs(Players)do p.active=false end
  Players[id or 0].active=true
  Events.AIProcessingStartedForPlayer.Fire(id or 0,nil)
end
function LF_Counts(h,g)
  assert(LF_Harbor:GetNumRealBuilding(3)==h,'harbor count')
  assert(LF_Harbor:GetNumRealBuilding(4)==g,'gold count')
end
function LF_Guard() LF_Harbor.units={LF_Unit()} end
