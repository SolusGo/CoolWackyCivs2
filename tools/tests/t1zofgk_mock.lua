-- Native-order adapter for the shipped controller; not a Civ V engine test.
local function Event()
  local e={handlers={}}
  function e.Add(f)e.handlers[#e.handlers+1]=f end
  function e.Remove(f)for i=#e.handlers,1,-1 do if e.handlers[i]==f then table.remove(e.handlers,i) end end end
  function e.Fire(...)
    local copy={};for i,f in ipairs(e.handlers)do copy[i]=f end
    for _,f in ipairs(copy)do f(...) end
  end
  return setmetatable(e,{__call=function(_,...)e.Fire(...)end})
end
local function Group()return setmetatable({},{__index=function(t,k)local e=Event();rawset(t,k,e);return e end})end
local function EventsReset()GameEvents=Group();Events=Group();LuaEvents=Group()end
function Reset()
  EventsReset();MapModData={};ContextPtr={};turn=0;nextID=1;notifications={};unitScans=0
  DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2};NotificationTypes={NOTIFICATION_GENERIC=1}
  Game={GetGameTurn=function()return turn end,GetStartTurn=function()return 0 end,GetGameSpeedType=function()return 0 end,GetActivePlayer=function()return 0 end}
  GameInfo={GameSpeeds={[0]={TrainPercent=SPEED}}}
  Locale={ConvertTextKey=function(key,...)
    local text=Translations[key] or key;local args={...}
    return (text:gsub('{(%d+)_[^}]+}',function(i)return tostring(args[tonumber(i)] or '')end))
  end}
  Players={};Teams={}
  for pid=0,4 do
    local p={pid=pid,units={},cities={},data='',alive=true,human=pid==0 or pid==3,civ=(pid==0 or pid==3) and GameInfoTypes.CIVILIZATION_T1Z_ZOFGK or -1,team=pid}
    function p:GetID()return self.pid end
    function p:GetCivilizationType()return self.civ end
    function p:IsAlive()return self.alive end
    function p:IsHuman()return self.human end
    function p:GetTeam()return self.team end
    function p:GetScriptData()return self.data end
    function p:SetScriptData(s)self.data=s end
    function p:GetUnitByID(id)return self.units[id]end
    function p:GetCityByID(id)return self.cities[id]end
    function p:Units()
      unitScans=unitScans+1
      local ids={};for id in pairs(self.units)do ids[#ids+1]=id end;table.sort(ids)
      local n=0;return function()n=n+1;return self.units[ids[n]]end
    end
    function p:AddNotification(typ,text,title,x,y)notifications[#notifications+1]={pid=self.pid,text=text,title=title,x=x,y=y}end
    Players[pid]=p
    local team={wars={}}
    function team:IsAtWar(other)return self.wars[other] or false end
    Teams[pid]=team
  end
  Players[4].team=0
  function War(a,b,want)Teams[a].wars[b]=want;Teams[b].wars[a]=want;Events.WarStateChanged(a,b,want)end
  Map={}
  function Map.PlotDistance(ax,ay,bx,by)return math.max(math.abs(ax-bx),math.abs(ay-by),math.abs(ax-bx+ay-by))end
  function Map.PlotXYWithRangeCheck(x,y,dx,dy,radius)
    if Map.PlotDistance(x,y,x+dx,y+dy)>radius then return nil end
    local plot={x=x+dx,y=y+dy}
    function plot:List()
      local list={};for _,p in pairs(Players)do for _,u in pairs(p.units)do
        if not u.dead and not u.delayed and u.x==self.x and u.y==self.y then list[#list+1]=u end
      end end;return list
    end
    function plot:GetNumUnits()return #self:List()end
    function plot:GetUnit(i)return self:List()[i+1]end
    return plot
  end
end
function MakeCity(pid,id,real)
  local c={pid=pid,id=id,real=real or 0}
  function c:GetOwner()return self.pid end
  function c:GetNumRealBuilding(building)assert(building==GameInfoTypes.BUILDING_T1Z_HEADQUARTERS);return self.real end
  Players[pid].cities[id]=c;return c
end
function MakeUnit(pid,kind,x,y,id)
  local u={pid=pid,id=id or nextID,kind=kind,x=x or 0,y=y or 0,born=turn,data='',promos={},military=true,ranged=false,domain=0,original=pid,damage=0,maxHP=100,moved=false,attacked=false,blocked=false,embarked=false}
  nextID=math.max(nextID,u.id+1)
  function u:GetOwner()return self.pid end
  function u:GetID()return self.id end
  function u:GetUnitType()return self.kind end
  function u:GetX()return self.x end
  function u:GetY()return self.y end
  function u:GetGameTurnCreated()return self.born end
  function u:GetOriginalOwner()return self.original end
  function u:GetDomainType()return self.domain end
  function u:IsDead()return self.dead or false end
  function u:IsDelayedDeath()return self.delayed or false end
  function u:IsCombatUnit()return self.military end
  function u:IsRanged()return self.ranged end
  function u:IsOnlyDefensive()return self.onlyDefensive or false end
  function u:IsHasPromotion(id)return self.promos[id] or false end
  function u:SetHasPromotion(id,want)assert(id,'undefined promotion');self.promos[id]=want or nil end
  function u:GetScriptData()return self.data end
  function u:SetScriptData(data)self.data=data end
  function u:GetName()return 'Unit '..self.id end
  if kind==GameInfoTypes.UNIT_T1Z_RECRUIT then u.promos[GameInfoTypes.PROMOTION_T1Z_SCOUTED]=true end
  Players[pid].units[u.id]=u;GameEvents.UnitCreated(pid,u.id,kind,u.x,u.y)
  return u
end
function Train(pid,kind,city,gold,faith,id)
  local u=MakeUnit(pid,kind,0,0,id)
  GameEvents.CityTrained(pid,city,u.id,gold or false,faith or false);return u
end
function Move(u,x,y)u.x=x;u.y=y;u.moved=true;GameEvents.UnitSetXY(u.pid,u.id,x,y)end
function Die(u)
  GameEvents.UnitPrekill(u.pid,u.id,u.kind,u.x,u.y,true,-1)
  u.delayed=true
  GameEvents.UnitPrekill(u.pid,u.id,u.kind,u.x,u.y,false,-1)
  u.dead=true;Players[u.pid].units[u.id]=nil
end
function Convert(u,pid,kind,upgrade,repeatEvent,options)
  options=options or {}
  local to=MakeUnit(pid,kind,u.x,u.y)
  if options.afterCreated then options.afterCreated(u,to)end
  if upgrade and not options.noUpgradeEvent then
    GameEvents.UnitUpgraded(u.pid,u.id,to.id,options.goody or false)
    if options.repeatUpgrade then GameEvents.UnitUpgraded(u.pid,u.id,to.id,options.goody or false)end
  end
  if options.afterUpgrade then options.afterUpgrade(u,to)end
  -- CP overwrites destination promotions, copies original owner, then emits
  -- UnitConverted, while the source still exists. ScriptData is NOT copied.
  for _,promotion in pairs(GameInfoTypes)do
    local row=NativePromotions[promotion]
    if row then
      local retained=not options.gift or row.LostOnGifting==0
      to.promos[promotion]=retained and u.promos[promotion] or nil
    end
  end
  for promotion in pairs(u.promos)do if not NativePromotions[promotion] then to.promos[promotion]=true end end
  to.original=u.original
  to.born=u.born
  if options.afterCopy then options.afterCopy(u,to)end
  GameEvents.UnitConverted(u.pid,pid,u.id,to.id,upgrade or false)
  if repeatEvent then GameEvents.UnitConverted(u.pid,pid,u.id,to.id,upgrade or false)end
  Die(u);return to
end
function Upgrade(u,kind,duplicate)return Convert(u,u.pid,kind,true,duplicate)end
function Gift(u,pid)return Convert(u,pid,u.kind,false,true,{gift=true})end
-- Native direct capture recreates a unit WITHOUT copying promotions or
-- ScriptData. It must not be confused with delayed city-state gifts below.
function DirectCapture(u,pid,reason)
  local original,kind,x,y=u.original,u.kind,u.x,u.y
  if reason==0 then GameEvents.UnitCaptured(pid,0,u.pid,u.id,false,0)end
  GameEvents.UnitPrekill(u.pid,u.id,u.kind,u.x,u.y,true,pid);u.delayed=true
  GameEvents.UnitPrekill(u.pid,u.id,u.kind,u.x,u.y,false,pid)
  if reason~=0 then GameEvents.UnitCaptured(pid,kind,u.pid,u.id,false,1)end
  u.dead=true;Players[u.pid].units[u.id]=nil
  local to=MakeUnit(pid,kind,x,y);to.original=original
  return to
end
function DistanceSend(u)
  local gift={owner=u.pid,kind=u.kind,born=u.born,original=u.original,promos={},domain=u.domain}
  -- CvPlayer::AddIncomingUnit snapshots before UnitPrekill.
  for id in pairs(u.promos)do gift.promos[id]=true end
  Die(u);return gift
end
function DistanceDeliver(gift,pid,returning,jump,afterCreated)
  local to=MakeUnit(pid,gift.kind,8,0);to.domain=gift.domain
  if afterCreated then afterCreated(to) end
  to.original=gift.original;to.born=gift.born
  -- applyToUnit runs AFTER UnitCreated. Returns ignore LostOnGifting.
  for id in pairs(gift.promos)do
    local row=NativePromotions[id]
    if returning or not row or row.LostOnGifting==0 then to.promos[id]=true end
  end
  if not returning then GameEvents.PlayerGifted(gift.owner,pid,-1,gift.kind,-1,-1)end
  if jump and to.domain~=2 then Move(to,9,0)end
  return to
end
function Reload(hard)
  if hard then EventsReset();MapModData={}end
  ContextPtr={};LoadController();Events.LoadScreenClose();Events.SequenceGameInitComplete()
end
function NativeModifier(u,column)
  local sum=0;for id in pairs(u.promos)do local row=NativePromotions[id];sum=sum+(row and row[column] or 0)end;return sum
end
function NormalHeal(u)
  if not u.military or u.damage==0 or u.moved or u.attacked or u.blocked or u.embarked then return 0 end
  local before=u.damage
  u.damage=math.max(0,u.damage-10-NativeModifier(u,'FriendlyHealChange'))
  return before-u.damage
end
function Has(u,key)return u:IsHasPromotion(GameInfoTypes['PROMOTION_T1Z_'..key])end
function RoleOf(u)
  for i,key in ipairs({'ZEUS','ONER','FAKER','GUMAYUSI','KERIA'})do if Has(u,key)then return i end end
end
function Army()
  MakeCity(0,1,1);local a={}
  for i=1,5 do a[i]=Train(0,GameInfoTypes.UNIT_T1Z_RECRUIT,1)end
  return a
end
function Check(condition,message)assert(condition,message);ASSERTIONS=ASSERTIONS+1 end
Reset()
