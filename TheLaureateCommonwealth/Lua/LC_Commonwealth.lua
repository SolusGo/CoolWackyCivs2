-- BNW / Community Patch v151. Native events own gameplay; no frame polling.
local old=MapModData.LC_Controller
if old and old.active and old.context==ContextPtr then return end
if old then
  old.active=false
  for _,h in ipairs(old.handlers or {}) do h.event.Remove(h.callback) end
end
local T=GameInfoTypes or {}
local CIV,HALL,CROWN=T.CIVILIZATION_LAUREATE_COMMONWEALTH,T.BUILDING_HALL_OF_LAURELS,T.PROMOTION_CROWNING_BLOW
local VETERAN,PERSON,POLICY=T.PROMOTION_LAUREL_LEVEL_REWARDED,T.PROMOTION_LC_PERSON_RECOGNIZED,T.POLICY_LC_GOLDEN_EXCELLENCE
if not (CIV and HALL and CROWN and VETERAN and PERSON and POLICY) then
  print('LC: required database entries missing; controller not started'); return
end
local control={active=true,context=ContextPtr,handlers={}}
MapModData.LC_Controller=control
local pending,bridges={},{}
local speed=assert(GameInfo.GameSpeeds[Game.GetGameSpeedType()]).GreatPeoplePercent
local function Laureate(p)
  return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType()==CIV
end
local function Military(u) return u and u:IsCombatUnit() and not u:IsGreatPerson() end
local function Get(obj,key) return (obj:GetScriptData() or ''):match('%[LC1_'..key..'=([^%]]*)%]') end
local function Put(obj,key,value)
  local data=obj:GetScriptData() or ''
  local result=data:gsub('%[LC1_'..key..'=[^%]]*%]','')
  if value~=nil then result=result..'[LC1_'..key..'='..tostring(value)..']' end
  if result~=data then obj:SetScriptData(result) end
end
local function Notice(p,key,a,b,x,y)
  if p:IsHuman() then
    local tag='TXT_KEY_LC_NOTICE_'..key
    local message=a~=nil and b~=nil and Locale.ConvertTextKey(tag,a,b) or Locale.ConvertTextKey(tag)
    p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,message,
      Locale.ConvertTextKey('TXT_KEY_LC_NOTICE_TITLE'),x or -1,y or -1)
  end
end
local function Scaled(p,base,era) return math.floor((base+era*math.max(0,p:GetCurrentEra()))*speed/100) end
local function Award(p,amount,key,name,x,y)
  local before=p:GetGoldenAgeProgressMeterTimes100()
  p:ChangeGoldenAgeProgressMeter(amount)
  if key and p:GetGoldenAgeProgressMeterTimes100()>before then Notice(p,key,name,amount,x,y) end
end
local function Golden(p,feedback)
  if not p or (not Laureate(p) and not p:HasPolicy(POLICY)) then return end
  local want=Laureate(p) and p:IsGoldenAge() or false
  if p:HasPolicy(POLICY)~=want then p:SetHasPolicy(POLICY,want,true) end
  local prior=Get(p,'GOLDEN')=='1'
  Put(p,'GOLDEN',want and 1 or 0)
  if feedback and want and not prior then Notice(p,'GOLDEN') end
end
-- VET version 2: N=new native initialization (not classified yet), E=eligible,
-- B=threshold already reached abroad / unprovable legacy veteran, R=rewarded.
-- The existing native promotion remains the authoritative lifetime receipt.
local function WriteHistory(u,state)
  local value='2:'..u:GetOwner()..':'..state
  if Get(u,'VET')~=value then Put(u,'VET',value) end
  if state=='R' and not u:IsHasPromotion(VETERAN) then u:SetHasPromotion(VETERAN,true) end
  return state
end
local function History(u,settled)
  if not Military(u) then return nil end
  if u:IsHasPromotion(VETERAN) then return WriteHistory(u,'R') end
  local raw=Get(u,'VET')
  local owner,state
  if raw then owner,state=raw:match('^2:(%d+):([NEBR])$');owner=tonumber(owner) end
  if not state then
    -- Migration never invents an achievement for an already-high-level unit.
    return WriteHistory(u,u:GetLevel()<3 and not raw and 'E' or 'B')
  end
  if owner~=u:GetOwner() then
    state=state=='R' and 'R' or (state=='B' or u:GetLevel()>=3) and 'B' or 'E'
  elseif state=='N' and settled then
    state='E' -- only persisted UnitCreated candidates can take this path
  end
  return WriteHistory(u,state)
end
local function Veteran(p,u)
  if Laureate(p) and Military(u) and not u:IsDead() and not u:IsDelayedDeath()
      and u:GetLevel()>=3 and History(u,false)=='E' then
    WriteHistory(u,'R')
    Award(p,Scaled(p,10,2),'VETERAN',u:GetName(),u:GetX(),u:GetY())
  end
end
local function Track(u)
  local pid,id=u:GetOwner(),u:GetID()
  Put(u,'NEW',2)
  pending[pid]=pending[pid] or {}
  pending[pid][id]={kind=u:GetUnitType(),born=u:GetGameTurnCreated()}
end
local function Untrack(u)
  local list=pending[u:GetOwner()]
  if list then list[u:GetID()]=nil end
  Put(u,'NEW',nil)
end
local function Settle(p,u)
  if not u then return end
  local amount=tonumber(Get(u,'PERSON'))
  if not amount then return end
  Put(u,'PERSON',nil)
  if not u:IsHasPromotion(PERSON) then
    u:SetHasPromotion(PERSON,true)
    if Laureate(p) and u:IsGreatPerson() and u:GetOriginalOwner()==p:GetID() then
      Award(p,amount,'PERSON',u:GetName(),u:GetX(),u:GetY())
    end
  end
end
local function Reject(u)
  Put(u,'PERSON',nil)
  if not u:IsHasPromotion(PERSON) then u:SetHasPromotion(PERSON,true) end
end
-- createCaptureUnit copies ScenarioData, but NOT ScriptData, level or promotions.
-- UnitCaptured has no replacement ID. A brief, reversible native identity tag
-- crosses that gap. The source player's saved receipt preserves the prior value;
-- the replacement restores it before recognition. Tile/class guesses are unused.
local function SaveBridge(r)
  Put(Players[r.source],'C'..r.serial,table.concat({r.prior,r.original,r.state,r.target,
    r.confirmed,r.id,r.born},':'))
end
local function DropBridge(r)
  Put(Players[r.source],'C'..r.serial,nil);bridges[r.token]=nil
end
local function SourceOf(r,u)
  return u:GetOwner()==r.source and u:GetID()==r.id and u:GetGameTurnCreated()==r.born
      and tonumber(Get(u,'BRIDGE'))==r.token
end
local function Resolve(u,settled)
  local token=-u:GetScenarioData()
  local r=bridges[token]
  if r and Get(u,'NEW')=='2' and not SourceOf(r,u) and r.confirmed==1 and r.target==u:GetOwner()
      and r.original==u:GetOriginalOwner() then
    if u:IsGreatPerson() then Reject(u) end
    if Military(u) then WriteHistory(u,r.state) end
    u:SetScenarioData(r.prior)
    DropBridge(r)
    Untrack(u)
    return true
  end
  if settled then History(u,true) end
  return false
end
local function Prepare(u,target,confirmed)
  if not (Military(u) or u:IsGreatPerson()) then return end
  local token=tonumber(Get(u,'BRIDGE'))
  local r=token and bridges[token]
  if r and SourceOf(r,u) then
    if confirmed then r.target=target;r.confirmed=1;SaveBridge(r) end
    return r
  end
  local p=Players[u:GetOwner()]
  local serial=(tonumber(Get(p,'CSEQ')) or 0)+1
  -- Numeric radix is metadata encoding, not a gameplay cap/modifier. CP player
  -- slots fit in one byte; 8 million captures per source fit the native signed int.
  assert(p:GetID()<255 and serial<8388608,'LC: capture identity space exhausted')
  token=serial*256+p:GetID()+1
  local state=History(u,true) or 'B'
  if Military(u) and state~='R' and u:GetLevel()>=3 then state='B' end
  r={source=p:GetID(),serial=serial,token=token,prior=u:GetScenarioData(),
    original=u:GetOriginalOwner(),state=state,target=target,confirmed=confirmed and 1 or 0,
    id=u:GetID(),born=u:GetGameTurnCreated()}
  Put(p,'CSEQ',serial);SaveBridge(r);bridges[token]=r
  Put(u,'BRIDGE',token);u:SetScenarioData(-token)
  return r
end
local function Created(pid,id)
  local p=Players[pid]
  if not Laureate(p) and next(bridges)==nil then return end
  local u=p and p:GetUnitByID(id)
  if not u or not (Military(u) or u:IsGreatPerson()) then return end
  if Military(u) and not Get(u,'VET') then WriteHistory(u,'N') end
  if Laureate(p) and u:IsGreatPerson() and not u:IsHasPromotion(PERSON) and not Get(u,'PERSON') then
    Put(u,'PERSON',Scaled(p,20,5))
  end
  -- Never consume a capture receipt or pay a Level 3 award during native init.
  if Get(u,'NEW') or Get(u,'PERSON') or (Military(u) and Get(u,'VET')=='2:'..pid..':N')
      or next(bridges)~=nil then Track(u) end
end
local function Converted(oldPID,newPID,oldID,newID,isUpgrade)
  local a,b=Players[oldPID],Players[newPID]
  local from=a and a:GetUnitByID(oldID)
  local to=b and b:GetUnitByID(newID)
  if not from or not to then return end -- native source exists; ignore stale callbacks
  local identity=oldPID..':'..oldID..':'..from:GetGameTurnCreated()
  if Get(to,'CONVERT')==identity then return end
  if not (Laureate(a) or Laureate(b) or Get(from,'VET') or from:IsHasPromotion(VETERAN)
      or (Military(from) and from:GetLevel()>=3)) then return end
  Resolve(from,true);Veteran(a,from);Settle(a,from)
  local state=History(from,true)
  if state~='R' and Military(from) and oldPID~=newPID and from:GetLevel()>=3 then state='B' end
  if to:IsGreatPerson() then Reject(to) end
  if Military(to) then WriteHistory(to,state or 'B') end
  if from:IsHasPromotion(CROWN) and not to:IsHasPromotion(CROWN) then to:SetHasPromotion(CROWN,true) end
  Put(to,'CONVERT',identity);Untrack(to)
  -- Deliberately no Veteran(b,to): ownership history must settle first.
end
local function Captured(byPID,byUnit,oldPID,oldID,willDie,reason)
  local p=Players[oldPID]
  local u=p and p:GetUnitByID(oldID)
  if not u then return end
  Resolve(u,true);Veteran(p,u);Settle(p,u)
  if willDie then return end
  if reason==1 then
    -- kill() has ALREADY snapshotted ScenarioData. Prekill prepared its tag.
    local r=bridges[tonumber(Get(u,'BRIDGE'))]
    if r and SourceOf(r,u) then r.target=byPID;r.confirmed=1;SaveBridge(r) end
  elseif Laureate(Players[byPID]) or Get(u,'VET') or u:IsHasPromotion(VETERAN)
      or (Military(u) and u:GetLevel()>=3) then
    Prepare(u,byPID,true) -- movement hook precedes getCaptureDefinition()
  end
end
local function Prekill(pid,id,kind,x,y,delay,byPID)
  local p=Players[pid];local u=p and p:GetUnitByID(id)
  if not u then return end
  Resolve(u,true);Veteran(p,u);Settle(p,u)
  if byPID and byPID>=0 and (Laureate(Players[byPID]) or Get(u,'VET')
      or u:IsHasPromotion(VETERAN) or (Military(u) and u:GetLevel()>=3)) then
    Prepare(u,byPID,false) -- precedes kill()'s capture-definition snapshot
  end
end
local function Flush()
  -- Only clean receipts present on entry. Native notifications/mod callbacks can
  -- synchronously create another capture while an achievement is being paid.
  local tokens={};for token in pairs(bridges) do tokens[#tokens+1]=token end;table.sort(tokens)
  local owners={};for pid in pairs(pending) do owners[#owners+1]=pid end;table.sort(owners)
  for _,pid in ipairs(owners) do
    local ids={};for id in pairs(pending[pid]) do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids) do
      local item=pending[pid][id]
      local p=Players[pid];local u=p and p:GetUnitByID(id)
      if item and u and Get(u,'NEW')=='2' and u:GetUnitType()==item.kind and u:GetGameTurnCreated()==item.born then
        Resolve(u,true);Settle(p,u);Veteran(p,u);Untrack(u)
      else pending[pid][id]=nil end
    end
  end
  -- At a native turn boundary the synchronous capture call has completed. Drop
  -- receipts for ordinary kills/failed captures, restoring a surviving source.
  -- An existing receipt can also be reused by a reentrant retry. Preserve any
  -- identity still carried by a newly queued replacement, even if it predates us.
  local waiting={}
  for pid,list in pairs(pending) do
    for id in pairs(list) do
      local u=Players[pid]:GetUnitByID(id)
      if u and Get(u,'NEW')=='2' then waiting[-u:GetScenarioData()]=true end
    end
  end
  for _,token in ipairs(tokens) do
    local r=bridges[token]
    if r and not waiting[token] then
      local p=Players[r.source];local u=p and p:GetUnitByID(r.id)
      if not (u and SourceOf(r,u) and u:IsDelayedDeath()) then
        if u and SourceOf(r,u) then
          if u:GetScenarioData()==-token then u:SetScenarioData(r.prior) end
          Put(u,'BRIDGE',nil)
        end
        DropBridge(r)
      end
    end
  end
end
local function Constructed(pid,cityID,buildingID)
  local p=Players[pid];if not Laureate(p) then return end
  local city=p:GetCityByID(cityID);local building=GameInfo.Buildings[buildingID]
  local class=building and GameInfo.BuildingClasses[building.BuildingClass]
  if city and city:GetOwner()==pid and city:GetNumBuilding(buildingID)>0 and class
      and class.MaxGlobalInstances==1 and class.MaxTeamInstances==-1
      and class.MaxPlayerInstances==-1 and not Get(p,'W'..buildingID) then
    Put(p,'W'..buildingID,1)
    Award(p,Scaled(p,40,10),'WONDER',Locale.ConvertTextKey(building.Description),city:GetX(),city:GetY())
  end
end
local function Turn(pid)
  Flush()
  local p=Players[pid];if not Laureate(p) then return end
  Golden(p,true)
  -- setLevel and insta-heal have no reliable CP level event. One owner army pass.
  for u in p:Units() do Resolve(u,true);Settle(p,u);Veteran(p,u) end
  local turn=Game.GetGameTurn();if tonumber(Get(p,'HALLTURN'))==turn then return end
  local total=0
  if not p:IsAnarchy() then
    for city in p:Cities() do
      if city:GetOwner()==pid and not city:IsResistance() and not city:IsRazing() then
        total=total+city:GetNumActiveBuilding(HALL)
      end
    end
  end
  Put(p,'HALLTURN',turn)
  if total>0 then Award(p,total) end
end
local function Hook(events,name,fn)
  local event=events[name];assert(event,'LC: missing required CP event '..name)
  local callback=function(...) if control.active and MapModData.LC_Controller==control then return fn(...) end end
  event.Add(callback);control.handlers[#control.handlers+1]={event=event,callback=callback}
end
Hook(GameEvents,'CityConstructed',Constructed)
Hook(GameEvents,'UnitCreated',Created)
Hook(GameEvents,'UnitConverted',Converted)
Hook(GameEvents,'UnitCaptured',Captured)
Hook(GameEvents,'UnitPrekill',Prekill)
Hook(GameEvents,'UnitPromoted',function(pid,id)
  local p=Players[pid];local u=p and p:GetUnitByID(id)
  if not Military(u) then return end
  local state=History(u,false)
  if not Laureate(p) and u:GetLevel()>=3 and state~='R' then WriteHistory(u,'B')
  else Veteran(p,u) end
end)
Hook(GameEvents,'CityTrained',function(pid,cityID,id)
  local p=Players[pid];local u=p and p:GetUnitByID(id)
  if Laureate(p) and u then Resolve(u,true);Settle(p,u);Veteran(p,u);Untrack(u) end
end)
Hook(GameEvents,'PlayerGoldenAge',function(pid) Golden(Players[pid],true) end)
Hook(GameEvents,'PlayerDoTurn',Turn)
Hook(GameEvents,'PlayerDoneTurn',function(pid) Flush();Golden(Players[pid],true) end)
Hook(GameEvents,'PlayerCanAdoptPolicy',function(pid,policy) return policy~=POLICY end)
local function Initialize()
  pending,bridges={},{}
  -- Saved receipts are source-player scoped; source unit IDs are never lifetime IDs.
  for pid,p in pairs(Players) do
    for seq,data in (p:GetScriptData() or ''):gmatch('%[LC1_C(%d+)=([^%]]+)%]') do
      local prior,original,state,target,confirmed,id,born=data:match('^(-?%d+):(-?%d+):([EBR]):(-?%d+):([01]):(%d+):(-?%d+)$')
      if prior then
        local serial=tonumber(seq);local token=serial*256+pid+1
        bridges[token]={source=pid,serial=serial,token=token,prior=tonumber(prior),original=tonumber(original),
          state=state,target=tonumber(target),confirmed=tonumber(confirmed),id=tonumber(id),born=tonumber(born)}
      end
    end
  end
  for _,p in pairs(Players) do
    if p:IsAlive() then
      Golden(p,false)
      -- Foreign armies are inspected on load ONLY while native capture receipts
      -- are outstanding; normal foreign turns never enumerate their units.
      if Laureate(p) or next(bridges)~=nil then
        for u in p:Units() do
          if Get(u,'NEW')=='2' or Get(u,'PERSON') or bridges[-u:GetScenarioData()] and not Get(u,'BRIDGE') then Track(u)
          elseif Laureate(p) then History(u,false) end
        end
      end
    end
  end
end
Hook(Events,'SequenceGameInitComplete',Initialize)
Hook(Events,'LoadScreenClose',Initialize)
Initialize()
