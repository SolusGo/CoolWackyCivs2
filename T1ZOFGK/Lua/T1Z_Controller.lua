-- One event-driven simulation owner. BNW / CP v151 / Lua 5.1.
local previous=MapModData.T1Z_Controller
if previous and previous.active and previous.context==ContextPtr then return end
if previous then
  previous.active=false
  for _,h in ipairs(previous.handlers or {}) do h.event.Remove(h.callback) end
end
local T=GameInfoTypes
local CIV,RECRUIT,HQ=T.CIVILIZATION_T1Z_ZOFGK,T.UNIT_T1Z_RECRUIT,T.BUILDING_T1Z_HEADQUARTERS
if not (CIV and RECRUIT and HQ) then print('T1Z: database missing');return end
local C={active=true,context=ContextPtr,handlers={}}
MapModData.T1Z_Controller=C
T1Z=C
local names={'ZEUS','ONER','FAKER','GUMAYUSI','KERIA'}
local roles={};for i,name in ipairs(names) do roles[i]=assert(T['PROMOTION_T1Z_'..name]) end
local SCOUTED=T.PROMOTION_T1Z_SCOUTED
local TEN,FIFTEEN=T.PROMOTION_T1Z_SYNERGY_10,T.PROMOTION_T1Z_SYNERGY_15
local PRESSURE,SUPPORT=T.PROMOTION_T1Z_PRESSURE,T.PROMOTION_T1Z_SUPPORT
local tiers={};local n=1
while T['PROMOTION_T1Z_DEVELOPMENT_'..n] do tiers[n]=T['PROMOTION_T1Z_DEVELOPMENT_'..n];n=n+1 end
local speed=assert(GameInfo.GameSpeeds[Game.GetGameSpeedType()]).TrainPercent
local cooldown=math.max(1,math.floor(10*speed/100+0.5))
local rosters,affected,pending={},{},{}
local refreshing=false
local warOverride
local function Own(p) return p and p:IsHuman() and p:GetCivilizationType()==CIV end
local function Live(u) return u and not u:IsDead() and not u:IsDelayedDeath() end
local function Military(u) return Live(u) and u:IsCombatUnit() end
local function Melee(u) return Military(u) and u:GetDomainType()==DomainTypes.DOMAIN_LAND and not u:IsRanged() and not u:IsOnlyDefensive() end
local function Get(o,key) return (o:GetScriptData() or ''):match('%[T1Z1_'..key..'=([^%]]*)%]') end
local function Put(o,key,value)
  local data=o:GetScriptData() or ''
  local result=data:gsub('%[T1Z1_'..key..'=[^%]]*%]','')
  if value~=nil then result=result..'[T1Z1_'..key..'='..tostring(value)..']' end
  if result~=data then o:SetScriptData(result) end
end
local function Set(u,promotion,want)
  if u:IsHasPromotion(promotion)~=want then u:SetHasPromotion(promotion,want) end
end
local function Token(p,u)
  local token=Get(u,'ID')
  if not token then
    local seq=(tonumber(Get(p,'SEQ')) or 0)+1;Put(p,'SEQ',seq)
    token=p:GetID()..'.'..seq;Put(u,'ID',token)
  end
  return token
end
local function Count(u)
  for i=#tiers,1,-1 do if u:IsHasPromotion(tiers[i]) then return i end end
  return 0
end
local function Develop(u,count)
  assert(count<=#tiers,'T1Z: upgrade graph exceeds validated development tiers')
  for i,promotion in ipairs(tiers) do Set(u,promotion,i==count) end
end
local function Role(u)
  for i,promotion in ipairs(roles) do if u:IsHasPromotion(promotion) then return i end end
end
local function Strip(u)
  for _,promotion in ipairs(roles) do Set(u,promotion,false) end
  Set(u,TEN,false);Set(u,FIFTEEN,false)
end
local function Notice(p,key,a,b,u)
  if not Own(p) then return end
  p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
    Locale.ConvertTextKey('TXT_KEY_T1Z_NOTICE_'..key,a or '',b or ''),
    Locale.ConvertTextKey('TXT_KEY_T1Z_NOTICE_TITLE'),u and u:GetX() or -1,u and u:GetY() or -1)
end
local function RoleName(i) return Locale.ConvertTextKey('TXT_KEY_T1Z_'..names[i]) end
local function Slot(p,i) return Get(p,'S'..i) or 'N' end
local function Vacate(p,i,token,u)
  if not Own(p) or not token then return end
  if Slot(p,i)~='L:'..token then return end
  Put(p,'S'..i,'V:'..(Game.GetGameTurn()+cooldown));Put(p,'READY'..i,nil)
  if rosters[p:GetID()] then rosters[p:GetID()][i]=nil end
  Notice(p,'LOST',RoleName(i),cooldown,u)
end
local function SortedUnits(p)
  local result={};for u in p:Units() do result[#result+1]=u end
  table.sort(result,function(a,b)return a:GetID()<b:GetID() end)
  return result
end
-- Only T1 armies are enumerated on their own lifecycle/turn events. Slot
-- receipts, not object IDs, decide who owns a role; duplicates are stripped.
local function Rebuild(p)
  if not Own(p) then return end
  local roster={};rosters[p:GetID()]=roster
  for _,u in ipairs(SortedUnits(p)) do
    local token=Get(u,'ID');local keep
    if Live(u) and token then
      for i,promotion in ipairs(roles) do
        if u:IsHasPromotion(promotion) and Slot(p,i)=='L:'..token and not roster[i] and not keep then
          roster[i]=u;keep=i
        end
      end
    end
    for i,promotion in ipairs(roles) do Set(u,promotion,i==keep) end
    if not keep then Set(u,TEN,false);Set(u,FIFTEEN,false) end
  end
  for i=1,5 do
    local token=Slot(p,i):match('^L:(.+)$')
    if token and not roster[i] then Vacate(p,i,token) end
  end
end
local function Distance(a,b) return Map.PlotDistance(a:GetX(),a:GetY(),b:GetX(),b:GetY()) end
local function UnitKey(u) return u:GetOwner()..':'..u:GetID() end
local function Remember(u,list)
  list[UnitKey(u)]={owner=u:GetOwner(),id=u:GetID(),born=u:GetGameTurnCreated(),kind=u:GetUnitType()}
end
local function Resolve(record)
  local p=Players[record.owner];local u=p and p:GetUnitByID(record.id)
  if Live(u) and u:GetGameTurnCreated()==record.born and u:GetUnitType()==record.kind then return u end
end
local function Around(u,list)
  for dx=-1,1 do for dy=-1,1 do
    local plot=Map.PlotXYWithRangeCheck(u:GetX(),u:GetY(),dx,dy,1)
    if plot then for index=0,plot:GetNumUnits()-1 do
      local other=plot:GetUnit(index);if Live(other) then Remember(other,list) end
    end end
  end end
end
local function Aura(u)
  local pressure,support=false,false
  if Military(u) then
    local p=Players[u:GetOwner()]
    for pid,roster in pairs(rosters) do
      local source=Players[pid]
      if Own(source) and source:IsAlive() then
        local faker,keria=roster[3],roster[5]
        local first,second=source:GetTeam(),p:GetTeam()
        local hostile=Teams[first]:IsAtWar(second)
        if warOverride and ((first==warOverride[1] and second==warOverride[2]) or (first==warOverride[2] and second==warOverride[1])) then hostile=warOverride[3] end
        if Military(faker) and Distance(faker,u)<=1 and hostile then pressure=true end
        if Military(keria) and source:GetTeam()==p:GetTeam() and keria~=u and Distance(keria,u)==1 then support=true end
      end
    end
  end
  Set(u,PRESSURE,pressure);Set(u,SUPPORT,support)
  return pressure or support
end
local function Refresh()
  if refreshing then return end
  refreshing=true
  local candidates={};for key,record in pairs(affected) do candidates[key]=record end
  for _,roster in pairs(rosters) do
    for i,u in pairs(roster) do
      if Military(u) then
        local distinct=0
        for _,other in pairs(roster) do if Military(other) and Distance(u,other)<=2 then distinct=distinct+1 end end
        Set(u,TEN,distinct>=3 and distinct<=4);Set(u,FIFTEEN,distinct==5)
        if i==3 or i==5 then Around(u,candidates) end
      end
    end
  end
  local nextAffected={}
  for key,record in pairs(candidates) do
    local u=Resolve(record)
    if u and Aura(u) then nextAffected[key]=record end
  end
  affected=nextAffected;refreshing=false
  if LuaEvents.T1Z_RosterChanged then LuaEvents.T1Z_RosterChanged() end
end
local function Assign(p,u,canInitial,canSuccessor)
  if not Own(p) or not Military(u) or Role(u) then return end
  local chosen
  -- Initial recruits retain their original Z-O-F-G-K sequence even if an
  -- earlier member dies and its replacement cooldown expires very early.
  if canInitial then for i=1,5 do if Slot(p,i)=='N' then chosen=i;break end end end
  if not chosen and canSuccessor then
    for i=1,5 do
      local ready=tonumber(Slot(p,i):match('^V:(%d+)$'))
      if ready and Game.GetGameTurn()>=ready then chosen=i;break end
    end
  end
  if chosen then
    local token=Token(p,u);Put(p,'S'..chosen,'L:'..token);Put(p,'READY'..chosen,nil)
    Set(u,roles[chosen],true);rosters[p:GetID()]=rosters[p:GetID()] or {};rosters[p:GetID()][chosen]=u
    Notice(p,'JOIN',RoleName(chosen),nil,u)
  end
end
local function EligibleBirth(p,u)
  return Live(u) and u:GetOriginalOwner()==p:GetID() and Get(u,'FOREIGN')~='1' and Get(u,'ACQUIRED')~='1' and Get(u,'DONE')~='1'
end
local function Settle(p,u,city,produced)
  if not Own(p) or not EligibleBirth(p,u) then return end
  if u:GetUnitType()==RECRUIT then
    Set(u,SCOUTED,true);Token(p,u)
  end
  local initial=u:GetUnitType()==RECRUIT
  local successor=produced and city and city:GetOwner()==p:GetID() and city:GetNumRealBuilding(HQ)>0 and Melee(u)
  -- Consume before notifications/events can reenter CityTrained.
  Put(u,'DONE',1);Put(u,'BIRTH',nil);pending[UnitKey(u)]=nil
  Assign(p,u,initial,successor)
end
local function Created(pid,id)
  local p=Players[pid]
  local u=p and p:GetUnitByID(id);if not u then return end
  if not Own(p) then
    if next(rosters)~=nil and Aura(u) then Remember(u,affected) end
    return
  end
  -- initUnit is ALSO used for conversions/captures. Defer all awards until
  -- CityTrained or the next settled turn boundary, after original-owner copy.
  if Get(u,'DONE')~='1' and not Get(u,'BIRTH') then
    local seq=(tonumber(Get(p,'BIRTHSEQ')) or 0)+1;Put(p,'BIRTHSEQ',seq)
    Put(u,'BIRTH',seq);Remember(u,pending)
    local captures=Get(p,'CAPTURES') or ''
    for turn,x,y in captures:gmatch('(-?%d+),(-?%d+),(-?%d+);') do
      if tonumber(turn)==Game.GetGameTurn() and tonumber(x)==u:GetX() and tonumber(y)==u:GetY() then Put(u,'ACQUIRED',1) end
    end
  end
end
local function Flush(p,exclude,secondExclude)
  local waiting={}
  for _,u in ipairs(SortedUnits(p)) do
    if Get(u,'BIRTH') and u:GetID()~=exclude and u:GetID()~=secondExclude then waiting[#waiting+1]=u end
  end
  table.sort(waiting,function(a,b)return tonumber(Get(a,'BIRTH'))<tonumber(Get(b,'BIRTH')) end)
  for _,u in ipairs(waiting) do Settle(p,u,nil,false) end
end
local function Captured(byPID,byUnit,oldPID,oldID,willDie)
  local p=Players[byPID];if not Own(p) or willDie then return end
  local old=Players[oldPID];local u=old and old:GetUnitByID(oldID);if not u then return end
  -- CP's direct capture recreation has no destination-ID event. Quarantine
  -- unproven births at this exact capture site/turn; CityTrained is positive
  -- proof and clears this flag. Never borrow another mod's ScenarioData.
  local stamp=Game.GetGameTurn()..','..u:GetX()..','..u:GetY()..';'
  local captures=Get(p,'CAPTURES') or ''
  local current={}
  for turn,x,y in captures:gmatch('(-?%d+),(-?%d+),(-?%d+);') do
    if tonumber(turn)==Game.GetGameTurn() then current[#current+1]=turn..','..x..','..y..';' end
  end
  captures=table.concat(current)
  if not captures:find(stamp,1,true) then Put(p,'CAPTURES',captures..stamp) end
end
local function Converted(oldPID,newPID,oldID,newID,isUpgrade)
  local a,b=Players[oldPID],Players[newPID]
  local from=a and a:GetUnitByID(oldID);local to=b and b:GetUnitByID(newID)
  if not from or not to then return end
  if not (Own(a) or Own(b) or from:IsHasPromotion(SCOUTED) or Role(from)) then
    if next(rosters)~=nil then
      if Aura(to) then Remember(to,affected) end
    end
    return
  end
  if Own(a) and Get(from,'BIRTH') then
    -- A free Recruit may be upgraded/gifted before the next owner boundary.
    -- Settle that original birth, excluding the still-converting destination.
    Flush(a,oldID,oldPID==newPID and newID or nil);Settle(a,from,nil,false)
  end
  local token=Get(from,'ID') or (Own(a) and Token(a,from))
  local receipt=(token or oldPID)..':'..oldID..':'..from:GetGameTurnCreated()..':'..from:GetUnitType()..':'..to:GetUnitType()
  if Get(to,'CONVERT')==receipt then return end
  local role=Role(from);local count=Count(from)
  if from:IsHasPromotion(SCOUTED) then
    Set(to,SCOUTED,true)
    if isUpgrade and from:GetUnitType()~=to:GetUnitType() then count=count+1 end
    Develop(to,count)
  end
  if token then Put(to,'ID',token) end
  Put(to,'CONVERT',receipt);Put(to,'DONE',1);Put(to,'BIRTH',nil)
  Put(to,'FOREIGN',(oldPID~=newPID or Get(from,'FOREIGN')=='1') and 1 or nil)
  pending[UnitKey(to)]=nil
  -- Source is still alive here. Move the role before native prekill and before
  -- reconciling duplicates, so upgrades cannot start recruitment cooldowns.
  Strip(from);Strip(to)
  if role then
    if oldPID==newPID and Own(b) and Slot(b,role)=='L:'..token then
      Set(to,roles[role],true);rosters[newPID]=rosters[newPID] or {};rosters[newPID][role]=to
    else Vacate(a,role,token,from) end
  end
  Set(from,PRESSURE,false);Set(from,SUPPORT,false)
  Refresh()
end
local function Prekill(pid,id)
  local p=Players[pid];local u=p and p:GetUnitByID(id);if not u then return end
  local role=Role(u)
  if not role and not u:IsHasPromotion(PRESSURE) and not u:IsHasPromotion(SUPPORT) then return end
  if Own(p) and role then Vacate(p,role,Get(u,'ID'),u);Strip(u) end
  Set(u,PRESSURE,false);Set(u,SUPPORT,false);affected[UnitKey(u)]=nil;pending[UnitKey(u)]=nil
  if role then Refresh() end
end
local function Moved(pid,id)
  local p=Players[pid];local u=p and p:GetUnitByID(id)
  if not Live(u) then return end
  if Own(p) and Role(u) then Refresh();return end
  if next(rosters)==nil and not u:IsHasPromotion(PRESSURE) and not u:IsHasPromotion(SUPPORT) then return end
  -- Ordinary moves touch just this unit and at most ten aura sources.
  if Aura(u) then Remember(u,affected) else affected[UnitKey(u)]=nil end
end
local function Turn(pid)
  local p=Players[pid]
  if Own(p) then
    Flush(p);Rebuild(p)
    for i=1,5 do
      local ready=tonumber(Slot(p,i):match('^V:(%d+)$'))
      if ready and Game.GetGameTurn()>=ready and Get(p,'READY'..i)~='1' then
        Put(p,'READY'..i,1);Notice(p,'READY',RoleName(i))
      end
    end
    Refresh()
  end
end
local function Initialize()
  rosters,affected,pending={},{},{}
  local enabled=false;for _,p in pairs(Players) do if Own(p) then enabled=true;break end end
  if not enabled then return end
  -- One load-time scrub removes stale saved temporary effects and catches
  -- ownership changes made by other mods. No foreign army scans during play.
  for _,p in pairs(Players) do
    for u in p:Units() do
      Set(u,PRESSURE,false);Set(u,SUPPORT,false)
      if not Own(p) and Role(u) then Strip(u) end
    end
    if Own(p) then
      for _,u in ipairs(SortedUnits(p)) do
        if u:GetUnitType()==RECRUIT and not Get(u,'DONE') then Created(p:GetID(),u:GetID()) end
      end
      Flush(p);Rebuild(p)
    end
  end
  Refresh()
end
function C.Summary(pid)
  local p=Players[pid];if not Own(p) then return '' end
  local lines={};local roster=rosters[pid] or {}
  for i=1,5 do
    local u=roster[i];local state=Slot(p,i)
    if Live(u) then
      local formation=u:IsHasPromotion(FIFTEEN) and 15 or u:IsHasPromotion(TEN) and 10 or 0
      lines[i]=Locale.ConvertTextKey('TXT_KEY_T1Z_SLOT_ALIVE',RoleName(i),u:GetName(),Count(u)*4,formation)
    else
      local ready=tonumber(state:match('^V:(%d+)$'))
      if ready then
        local left=math.max(0,ready-Game.GetGameTurn())
        lines[i]=Locale.ConvertTextKey(left>0 and 'TXT_KEY_T1Z_SLOT_COOLDOWN' or 'TXT_KEY_T1Z_SLOT_READY',RoleName(i),left)
      else lines[i]=Locale.ConvertTextKey('TXT_KEY_T1Z_SLOT_INITIAL',RoleName(i)) end
    end
  end
  return table.concat(lines,'[NEWLINE][NEWLINE]')
end
function C.IsPlayer(pid) return Own(Players[pid]) end
local function Hook(group,name,callback)
  local event=group[name];if not event then return end
  local wrapped=function(...)if C.active then return callback(...) end end
  event.Add(wrapped);C.handlers[#C.handlers+1]={event=event,callback=wrapped}
end
Hook(GameEvents,'UnitCreated',Created)
Hook(GameEvents,'CityTrained',function(pid,cityID,id,gold,faith)
  local p=Players[pid];if not Own(p) then return end
  local u=p:GetUnitByID(id);if not u then return end
  Flush(p,id)
  if Get(u,'DONE')~='1' then Put(u,'ACQUIRED',nil) end
  Settle(p,u,p:GetCityByID(cityID),not gold and not faith);Refresh()
end)
Hook(GameEvents,'UnitConverted',Converted)
Hook(GameEvents,'UnitCaptured',Captured)
Hook(GameEvents,'UnitPrekill',Prekill)
Hook(GameEvents,'UnitSetXY',Moved)
Hook(GameEvents,'PlayerDoTurn',Turn)
Hook(GameEvents,'PlayerDoneTurn',Turn)
Hook(Events,'WarStateChanged',function(a,b,war)
  -- The native notification arrives after just one team's relation changes.
  warOverride={a,b,war};Refresh();warOverride=nil
end)
Hook(Events,'SequenceGameInitComplete',Initialize)
Hook(Events,'LoadScreenClose',Initialize)
Initialize()
