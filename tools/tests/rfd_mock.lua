-- Native API contract mock only. Never represents a launched Civ V session.
RFD_Turn, RFD_StartTurn, RFD_Speed = 0, 0, 2
RFD_Errors = {}
print = function(message) RFD_Errors[#RFD_Errors+1] = tostring(message) end
MapModData = {}
local function Event()
  local handlers = {}
  return {Add=function(fn) handlers[#handlers+1]=fn end,
    Remove=function(fn) for i=#handlers,1,-1 do if handlers[i]==fn then table.remove(handlers,i) end end end,
    Fire=function(...)
      local copy = {}; for i,fn in ipairs(handlers) do copy[i]=fn end
      for _,fn in ipairs(copy) do fn(...) end
    end,
    Count=function() return #handlers end}
end
GameEvents, Events = {}, {}
for _,name in ipairs({'PlayerDoTurn','CityConstructed','CitySoldBuilding','CityCaptureComplete'}) do GameEvents[name]=Event() end
for _,name in ipairs({'SpecificCityInfoDirty','SequenceGameInitComplete','LoadScreenClose'}) do Events[name]=Event() end
Game = {GetGameTurn=function() return RFD_Turn end,GetStartTurn=function() return RFD_StartTurn end,
  GetGameSpeedType=function() return RFD_Speed end}
local function Iterator(rows)
  return function() local i=0; return function() i=i+1; return rows[i] end end
end
local buildings, classes, speeds = {}, {}, {}
GameInfoTypes = {}
for _,row in ipairs(RFD_BuildingRows) do
  buildings[row.Type],buildings[row.ID] = row,row
  GameInfoTypes[row.Type]=row.ID
end
setmetatable(buildings,{__call=Iterator(RFD_BuildingRows)})
for _,row in ipairs(RFD_ClassRows) do classes[row.Type],classes[row.ID]=row,row end
for _,row in ipairs(RFD_SpeedRows) do speeds[row.ID]=row end
GameInfo = {Buildings=buildings, BuildingClasses=classes, GameSpeeds=speeds}
GameInfoTypes.CIVILIZATION_RFD_REPUBLIC = 987
local function Player(id, civ, human)
  local p = {id=id,civ=civ,human=human,alive=true,cities={},culture=0,gold=0,data='FOREIGN|preserve-this',writes=0}
  function p:IsAlive() return self.alive end
  function p:IsHuman() return self.human end
  function p:GetID() return self.id end
  function p:GetCivilizationType() return self.civ end
  function p:Cities() return Iterator(self.cities)() end
  function p:GetCityByID(id) for _,c in ipairs(self.cities) do if c.id==id then return c end end end
  function p:GetScriptData() return self.data end
  function p:SetScriptData(data)
    self.writes=self.writes+1
    if self.failSave==self.writes then error('injected ScriptData failure') end
    self.data=data
  end
  function p:GetJONSCultureTimes100() return self.culture end
  function p:GetGoldTimes100() return self.gold end
  function p:ChangeJONSCultureTimes100(value)
    if self.beforeCulture then self.beforeCulture=false; error('before Culture') end
    self.culture=self.culture+value
    if self.afterCulture then self.afterCulture=false; error('after Culture') end
  end
  function p:ChangeGold(value)
    if self.beforeGold then self.beforeGold=false; error('before Gold') end
    self.gold=self.gold+value*100
    if self.afterGold then self.afterGold=false; error('after Gold') end
  end
  return p
end
Players = {[0]=Player(0,987,true),[1]=Player(1,1,true),[2]=Player(2,987,false),[3]=Player(3,987,true)}
RFD_Plots = {}
Map = {GetPlot=function(x,y) return {GetPlotCity=function() return RFD_Plots[x..':'..y] end} end}
function RFD_City(owner,id)
  local c={owner=owner,id=id,buildings={},free={},writes=0,x=id*7,y=owner*11}
  function c:GetOwner() assert(not self.dead,'stale city'); return self.owner end
  function c:GetNumBuilding(id) assert(not self.dead,'stale city'); return (self.buildings[id] or 0)+(self.free[id] or 0) end
  function c:GetNumRealBuilding(id) assert(not self.dead,'stale city'); return self.buildings[id] or 0 end
  function c:SetNumRealBuilding(id,count)
    assert(not self.dead,'stale city'); self.buildings[id]=count; self.writes=self.writes+1
    Events.SpecificCityInfoDirty.Fire(self.owner,self.id)
    if self.failDummy then self.failDummy=false; error('injected dummy write failure') end
  end
  Players[owner].cities[#Players[owner].cities+1]=c
  RFD_Plots[c.x..':'..c.y]=c
  return c
end
function RFD_Add(city,name,count)
  city.buildings[assert(GameInfoTypes[name],name)]=count or 1
end
function RFD_Remove(city,name) city.buildings[assert(GameInfoTypes[name])]=nil; city.free[GameInfoTypes[name]]=nil end
function RFD_Next(id) RFD_Turn=RFD_Turn+1; GameEvents.PlayerDoTurn.Fire(id or 0) end
function RFD_Bonus(city)
  local result=0
  for i=1,3 do result=result+city:GetNumBuilding(GameInfoTypes['BUILDING_RFD_SCIENCE_'..i]) end
  return result
end
function RFD_Load()
  ContextPtr={SetShutdown=function(self,fn) self.shutdown=fn end}
  RFD_LoadSource()
end
function RFD_CheckYields(culture,gold,id)
  local p=Players[id or 0]
  assert(p.culture==culture*100,'Culture: '..p.culture..' expected '..culture*100)
  assert(p.gold==gold*100,'Gold: '..p.gold..' expected '..gold*100)
end
RFD_Ordinary={'BUILDING_MONUMENT','BUILDING_GRANARY','BUILDING_SHRINE','BUILDING_LIBRARY',
 'BUILDING_BARRACKS','BUILDING_MARKET','BUILDING_AMPHITHEATER','BUILDING_AQUEDUCT',
 'BUILDING_WATERMILL','BUILDING_STABLE','BUILDING_FORGE','BUILDING_UNIVERSITY',
 'BUILDING_GARDEN','BUILDING_CIRCUS','BUILDING_COLOSSEUM','BUILDING_HOSPITAL'}
function RFD_Diverse(city,count)
  RFD_Add(city,'BUILDING_RFD_REVISION_WORKSHOP')
  for i=1,count-1 do RFD_Add(city,RFD_Ordinary[i]) end
end
