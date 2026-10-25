-- Behavioral native doubles fed with the actual SQL output by validate_jin.py.
now=0;active=0;nextUnit=1;messages={};MapModData={};errors={}
Game={GetGameTurn=function()return now end,GetActivePlayer=function()return active end,GetGameSpeedType=function()return speedID end}
GameDefines={MAX_CIV_PLAYERS=5,BARBARIAN_PLAYER=4}
DomainTypes={DOMAIN_LAND=GameInfoTypes.DOMAIN_LAND}
YieldTypes={YIELD_GOLD=GameInfoTypes.YIELD_GOLD}
OrderTypes={ORDER_CONSTRUCT=1};Mouse={eLClick=1}
ContextPtr={SetShutdown=function(self,fn)self.shutdown=fn end}
function Event()
 local e={handlers={}}
 function e.Add(fn)e.handlers[#e.handlers+1]=fn end
 function e.Remove(fn)for i=#e.handlers,1,-1 do if e.handlers[i]==fn then table.remove(e.handlers,i) end end end
 function e.Fire(...)local result=true;local copy={unpack(e.handlers)};for _,fn in ipairs(copy)do if fn(...)==false then result=false end end;return result end
 return e
end
GameEvents=setmetatable({},{__index=function(t,k)local e=Event();rawset(t,k,e);return e end})
Events=setmetatable({},{__index=function(t,k)local e=Event();rawset(t,k,e);return e end})
Teams={}
for i=0,4 do
 local team={tech={},war={}};Teams[i]=team
 function team:IsHasTech(tech)return self.tech[tech] or false end
 function team:IsAtWar(other)return self.war[other] or false end
end
function War(a,b,on)Teams[a].war[b]=on;Teams[b].war[a]=on end
for i=0,3 do War(i,4,true)end
plots={}
local function unitsAt(p)
 local out={};for pid=0,4 do for _,u in pairs(Players[pid].units)do if not u.dead and u.x==p.x and u.y==p.y then out[#out+1]=u end end end
 table.sort(out,function(a,b)if a.owner==b.owner then return a.id<b.id end return a.owner<b.owner end);return out
end
local function plot(x,y)
 if x<0 or y<0 or x>=24 or y>=24 then return nil end
 return plots[y*24+x]
end
Map={GetPlot=plot,GetPlotByIndex=function(i)return plots[i]end,
 PlotDistance=function(x,y,xx,yy)local dx,dy=xx-x,yy-y;return math.max(math.abs(dx),math.abs(dy),math.abs(dx+dy))end}
function Map.PlotXYWithRangeCheck(x,y,dx,dy,r)if Map.PlotDistance(x,y,x+dx,y+dy)<=r then return plot(x+dx,y+dy)end end
for y=0,23 do for x=0,23 do
 local p={x=x,y=y,index=y*24+x,owner=0,resource=-1,improvement=-1,feature=-1,water=false,mountain=false,pillaged=false,raw='',worked=true}
 plots[p.index]=p
 function p:GetX()return self.x end;function p:GetY()return self.y end;function p:GetPlotIndex()return self.index end
 function p:GetOwner()return self.owner end;function p:GetPlotCity()return self.city end;function p:IsCity()return self.city~=nil end
 function p:IsWater()return self.water end;function p:IsMountain()return self.mountain end;function p:IsImpassable()return self.mountain end
 function p:GetResourceType()return self.resource end;function p:GetImprovementType()return self.improvement end
 function p:GetFeatureType()return self.feature end;function p:GetTerrainType()return GameInfoTypes.TERRAIN_PLAINS end
 function p:IsImprovementPillaged()return self.pillaged end;function p:IsVisible()return self.visible~=false end
 function p:GetNumUnits()return #unitsAt(self)end;function p:GetUnit(i)return unitsAt(self)[i+1]end
 function p:SetResourceType(r,n)self.resource=r;self.quantity=n end
 function p:SetImprovementType(v,builder,gift)local old=self.improvement;self.improvement=v;self.builder=builder;GameEvents.TileImprovementChanged.Fire(self.x,self.y,self.owner,old,v,self.pillaged)end
 function p:SetOwner(v)local old=self.owner;self.owner=v;GameEvents.TileOwnershipChanged.Fire(self.x,self.y,v,old)end
end end
Players={}
function Iterate(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys);local i=0
 return function()i=i+1;return keys[i] and t[keys[i]] or nil end
end
for id=0,4 do
 local p={id=id,raw='',alive=true,human=id==0,civ=id==0 and GameInfoTypes.CIVILIZATION_JIN_DYNASTY or -1,units={},cities={},policies={},gold=20000,era=0,resources=10}
 Players[id]=p
 function p:IsAlive()return self.alive end;function p:IsHuman()return self.human end;function p:GetCivilizationType()return self.civ end
 function p:IsMinorCiv()return self.id==2 or self.id==3 end;function p:GetTeam()return self.id end
 function p:GetScriptData()return self.raw end;function p:SetScriptData(raw)self.raw=raw end
 function p:GetCapitalCity()return self.cities[1]end;function p:GetCityByID(i)for _,c in ipairs(self.cities)do if c.id==i then return c end end end
 function p:Cities()return Iterate(self.cities)end;function p:Units()return Iterate(self.units)end;function p:GetUnitByID(i)return self.units[i]end
 function p:GetCurrentEra()return self.era end;function p:IsTurnActive()return self.id==active end
 function p:HasPolicy(i)return self.policies[i] or false end;function p:SetHasPolicy(i,v)self.policies[i]=v end
 function p:GetGold()return self.gold end;function p:ChangeGold(n)self.gold=self.gold+n end
 function p:GetName()return 'Player '..self.id end
 function p:InitUnit(typ,x,y)
  if self.failSpawn then return nil end
  local data=GameInfo.Units[typ];assert(data,'unknown unit')
  local u={id=nextUnit,typ=typ,owner=self.id,x=x,y=y,promos={},damage=0,moves=120,born=now,raw=''};nextUnit=nextUnit+1;self.units[u.id]=u
  function u:GetID()return self.id end;function u:GetOwner()return self.owner end;function u:GetUnitType()return self.typ end
  function u:GetX()return self.x end;function u:GetY()return self.y end;function u:GetPlot()return Map.GetPlot(self.x,self.y)end
  function u:GetGameTurnCreated()return self.born end;function u:IsDead()return self.dead or false end;function u:IsDelayedDeath()return false end
  function u:IsCombatUnit()return (GameInfo.Units[self.typ].Combat or 0)>0 end;function u:IsRanged()return (GameInfo.Units[self.typ].RangedCombat or 0)>0 end
  function u:GetDomainType()return GameInfoTypes[GameInfo.Units[self.typ].Domain]end
  function u:IsEmbarked()return self.embarked or false end;function u:IsCanDefend()return self.defend~=false end
  function u:IsFighting()return self.fighting or false end;function u:IsInvisible()return self.invisible or false end;function u:IsGreatPerson()return self.great or false end
  function u:IsHasPromotion(i)return self.promos[i] or false end;function u:SetHasPromotion(i,v)assert(i,'nil promotion');self.promos[i]=v end
  function u:GetMaxHitPoints()
   local n=GameInfo.Units[self.typ].MaxHitPoints or 100
   for pr,on in pairs(self.promos)do if on then n=n+(GameInfo.UnitPromotions[pr].MaxHitPointsChange or 0)end end;return n
  end
  function u:GetDamage()return self.damage end;function u:SetDamage(n)assert(n>=0 and n<self:GetMaxHitPoints());self.damage=n end
  function u:ChangeDamage(n,by)self:SetDamage(self.damage+n);self.lastDamager=by end
  function u:MovesLeft()return self.moves end;function u:FinishMoves()self.moves=0 end;function u:SetMoves(n)self.moves=n end
  function u:GetScriptData()return self.raw end;function u:SetScriptData(s)self.raw=s end
  function u:Kill(delay,by)
   GameEvents.UnitPrekill.Fire(self.owner,self.id,self.typ,self.x,self.y,delay,by)
   self.dead=true;Players[self.owner].units[self.id]=nil
  end
  for r in GameInfo.Unit_FreePromotions{UnitType=data.Type}do u:SetHasPromotion(GameInfoTypes[r.PromotionType],true)end
  GameEvents.UnitCreated.Fire(self.id,u.id,typ,x,y)
  return u
 end
end
function City(owner,x,y)
 local p=Players[owner];local c={id=#p.cities+1,owner=owner,x=x,y=y,born=now,original=owner,buildings={},food=0,name='City '..owner..'-'..x}
 p.cities[#p.cities+1]=c;plot(x,y).city=c;plot(x,y).owner=owner
 function c:GetX()return self.x end;function c:GetY()return self.y end;function c:Plot()return plot(self.x,self.y)end
 function c:GetOwner()return self.owner end;function c:GetOriginalOwner()return self.original end;function c:GetID()return self.id end
 function c:GetGameTurnFounded()return self.born end;function c:GetName()return self.name end
 function c:GetNumBuilding(i)return self.buildings[i] or 0 end;function c:GetNumRealBuilding(i)return self:GetNumBuilding(i)end
 function c:SetNumRealBuilding(i,n)assert(i,'nil building');self.buildings[i]=n end
 function c:ChangeFood(n)self.food=self.food+n end
 function c:IsResistance()return self.resistance or false end;function c:IsRazing()return self.razing or false end
 function c:CanPlaceUnitHere()return not self.blocked end
 function c:GetUnitPurchaseCost(typ)return math.max(1,GameInfo.Units[typ].Cost*4)end
 function c:IsCanPurchase(testCost,testTrain,typ)
  assert(testTrain==true)
  local row=GameInfo.Units[typ]
  if row.Cost<0 or (row.PrereqTech and not Teams[self.owner]:IsHasTech(GameInfoTypes[row.PrereqTech])) then return false end
  if Players[self.owner].resources<=0 then
   for r in GameInfo.Unit_ResourceQuantityRequirements{UnitType=row.Type}do if r.Cost>0 then return false end end
  end
  local cls=GameInfo.UnitClasses[row.Class];local allowed=cls.DefaultUnit==row.Type
  for r in GameInfo.Civilization_UnitClassOverrides{CivilizationType=GameInfo.Civilizations[Players[self.owner].civ] and GameInfo.Civilizations[Players[self.owner].civ].Type or '',UnitClassType=row.Class}do allowed=r.UnitType==row.Type end
  return allowed and GameEvents.CityCanTrain.Fire(self.owner,self.id,typ)
 end
 function c:PushOrder(order,bid,data2,save,pop,append,force)
  assert(type(save)=='number' and type(pop)=='boolean' and type(append)=='boolean' and (force==nil or type(force)=='number'),'CP PushOrder integer/boolean ABI')
  assert(GameEvents.CityCanConstruct.Fire(self.owner,self.id,bid));self.order=bid
 end
 function c:GetNumCityPlots()return #MapModData.JIN.Near(self:Plot(),3)end
 function c:GetCityIndexPlot(i)return MapModData.JIN.Near(self:Plot(),3)[i+1]end
 function c:IsWorkingPlot(p)return p.worked and p.owner==self.owner end
 return c
end
cap=City(0,8,8);minor=City(2,16,8);minor2=City(3,16,12)
function NextTurn(n)
 for _=1,n or 1 do now=now+1;for _,u in pairs(Players[0].units)do u.moves=120 end;GameEvents.PlayerDoTurn.Fire(0)end
end
function Learn(key)Teams[0].tech[GameInfoTypes[key]]=true end
function Spawn(key,x,y,owner)return Players[owner or 0]:InitUnit(GameInfoTypes['UNIT_JIN_'..key] or GameInfoTypes[key],x or 8,y or 8)end
function Action(kind,a,b)
 local j=MapModData.JIN;return j.Action(0,j.State(0).serial,kind,a,b)
end
function Complete(key)
 local j=MapModData.JIN;local l;for _,v in ipairs(JINConfig.landmarks)do if v.key==key then l=v end end
 Players[0].era=l.era;assert(Action('LANDMARK',key));assert(cap.order==j.Building(key));cap:SetNumRealBuilding(j.Building(key),1);GameEvents.CityConstructed.Fire(0,cap.id,j.Building(key),false,false)
end
Locale={ConvertTextKey=function(k)return Text[k] or k end}
UI={LookAt=function(p)looked=p.index end}
function Control()
 local c={}
 function c:SetHide(v)self.hidden=v end;function c:SetText(v)self.text=v end;function c:SetDisabled(v)self.disabled=v end
 function c:SetToolTipString(v)self.tooltip=v end;function c:RegisterCallback(e,fn)self.callback=fn end
 function c:CalculateSize()end;function c:ReprocessAnchoring()end;function c:CalculateInternalSize()end
 return c
end
Controls=setmetatable({},{__index=function(t,k)local c=Control();rawset(t,k,c);return c end})
InstanceManager={new=function()local m={rows={}}
 function m:ResetInstances()self.rows={}end
 function m:GetInstance()local r={Root=Control(),Text=Control(),Action=Control()};self.rows[#self.rows+1]=r;return r end
 uiManager=m;return m end}
