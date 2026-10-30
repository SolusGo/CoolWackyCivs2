-- BNW / Community Patch v151. No interface action or frame polling owns gameplay.
local old = MapModData.LC_Controller
if old and old.active and old.context == ContextPtr then return end
if old then
  old.active = false
  for _, h in ipairs(old.handlers or {}) do h.event.Remove(h.callback) end
end
local T = GameInfoTypes or {}
local CIV, HALL, CROWN = T.CIVILIZATION_LAUREATE_COMMONWEALTH, T.BUILDING_HALL_OF_LAURELS, T.PROMOTION_CROWNING_BLOW
local VETERAN, PERSON, POLICY = T.PROMOTION_LAUREL_LEVEL_REWARDED, T.PROMOTION_LC_PERSON_RECOGNIZED, T.POLICY_LC_GOLDEN_EXCELLENCE
if not (CIV and HALL and CROWN and VETERAN and PERSON and POLICY) then
  print('LC: required database entries missing; controller not started')
  return
end
local control = {active=true,context=ContextPtr,handlers={}}
MapModData.LC_Controller = control
local captures = {} -- only spans synchronous native capture -> creation, never a turn scan
local pending = {}
local speed = assert(GameInfo.GameSpeeds[Game.GetGameSpeedType()]).GreatPeoplePercent
local function Laureate(p)
  return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType() == CIV
end
local function Get(obj, key)
  return (obj:GetScriptData() or ''):match('%[LC1_'..key..'=([^%]]*)%]')
end
local function Put(obj, key, value)
  local data = obj:GetScriptData() or ''
  local nextData = data:gsub('%[LC1_'..key..'=[^%]]*%]', '')
  if value ~= nil then nextData = nextData..'[LC1_'..key..'='..tostring(value)..']' end
  if nextData ~= data then obj:SetScriptData(nextData) end
end
local function Notice(p, key, a, b, x, y)
  if p:IsHuman() then
    local tag='TXT_KEY_LC_NOTICE_'..key
    local message=a~=nil and b~=nil and Locale.ConvertTextKey(tag,a,b) or Locale.ConvertTextKey(tag)
    p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
      message,
      Locale.ConvertTextKey('TXT_KEY_LC_NOTICE_TITLE'), x or -1, y or -1)
  end
end
local function Scaled(p, base, era)
  return math.floor((base + era * math.max(0,p:GetCurrentEra())) * speed / 100)
end
local function Award(p, amount, key, name, x, y)
  -- Native API respects NO_HAPPINESS and optional CP meter restrictions. Never
  -- set turns, alter thresholds, reset overflow or run a separate GA currency.
  local before = p:GetGoldenAgeProgressMeterTimes100()
  p:ChangeGoldenAgeProgressMeter(amount)
  if key and p:GetGoldenAgeProgressMeterTimes100() > before then
    Notice(p,key,name,amount,x,y)
  end
end
local function Golden(p, feedback)
  if not p then return end
  if not Laureate(p) and not p:HasPolicy(POLICY) then return end
  local want = Laureate(p) and p:IsGoldenAge() or false
  if p:HasPolicy(POLICY) ~= want then p:SetHasPolicy(POLICY,want,true) end
  local prior = Get(p,'GOLDEN') == '1'
  Put(p,'GOLDEN',want and 1 or 0)
  if feedback and want and not prior then Notice(p,'GOLDEN') end
end
local function Veteran(p, u)
  if Laureate(p) and u and u:IsCombatUnit() and not u:IsGreatPerson()
      and not u:IsDead() and not u:IsDelayedDeath() and u:GetLevel() >= 3
      and not u:IsHasPromotion(VETERAN) then
    u:SetHasPromotion(VETERAN,true) -- lifetime marker is committed before award
    Award(p,Scaled(p,10,2),'VETERAN',u:GetName(),u:GetX(),u:GetY())
  end
end
local function Settle(p, u)
  if not u then return end
  local amount = tonumber(Get(u,'PERSON'))
  if not amount then return end
  Put(u,'PERSON',nil)
  if p and pending[p:GetID()] then pending[p:GetID()][u:GetID()]=nil end
  if not u:IsHasPromotion(PERSON) then
    u:SetHasPromotion(PERSON,true)
    if Laureate(p) and u:IsGreatPerson() and u:GetOriginalOwner()==p:GetID() then
      Award(p,amount,'PERSON',u:GetName(),u:GetX(),u:GetY())
    end
  end
end
local function Reject(u)
  if u then Put(u,'PERSON',nil); u:SetHasPromotion(PERSON,true) end
end
local function CaptureKey(pid,id) return tostring(pid)..':'..tostring(id) end
local function Created(pid, id, kind, x, y)
  local p = Players[pid]
  if not Laureate(p) and next(captures)==nil then return end
  local u = p and p:GetUnitByID(id)
  if not u then return end
  local info = GameInfo.Units[kind or u:GetUnitType()]
  for key, r in pairs(captures) do
    if r.turn ~= Game.GetGameTurn() then captures[key]=nil
    elseif r.owner==pid and r.x==u:GetX() and r.y==u:GetY()
        and info and (r.class==info.Class or r.originalClass==info.Class or r.kind==u:GetUnitType()) then
      if r.veteran then u:SetHasPromotion(VETERAN,true) end
      if u:IsGreatPerson() then Reject(u) end
      captures[key]=nil
      return
    end
  end
  if not Laureate(p) then return end
  -- UnitCreated runs before capture ownership/conversion has settled. Persist a
  -- candidate rather than paying here. Load never reconstructs candidates from
  -- existing units, so old GPs cannot become fresh achievements after reload.
  if u:IsGreatPerson() and not u:IsHasPromotion(PERSON) and not Get(u,'PERSON') then
    Put(u,'PERSON',Scaled(p,20,5))
    pending[pid]=pending[pid] or {}; pending[pid][id]=true
  end
end
local function Converted(oldPID,newPID,oldID,newID,isUpgrade)
  local a,b=Players[oldPID],Players[newPID]
  local from=a and a:GetUnitByID(oldID)
  local to=b and b:GetUnitByID(newID)
  if not (Laureate(a) or Laureate(b) or (from and from:IsHasPromotion(VETERAN))) then return end
  -- Native convert emits this hook after copying promotions and level, before
  -- killing the source. A genuine birth belongs to its creator, never recipient.
  if from then Settle(a,from) end
  if to then
    if to:IsGreatPerson() then Reject(to) end
    if from and from:IsHasPromotion(VETERAN) then to:SetHasPromotion(VETERAN,true) end
    if from and from:IsHasPromotion(CROWN) then to:SetHasPromotion(CROWN,true) end
    Veteran(b,to)
  end
end
local function Captured(byPID,byUnit,oldPID,oldID,willDie,reason)
  local p=Players[oldPID]
  local u=p and p:GetUnitByID(oldID)
  if not u then return end
  Settle(p,u)
  if willDie or not (Laureate(Players[byPID]) or u:IsHasPromotion(VETERAN)) then return end
  local info=GameInfo.Units[u:GetUnitType()]
  local key=CaptureKey(oldPID,oldID)
  -- Movement and kill paths can announce the same capture. Replacing this keyed
  -- receipt prevents a stale second suppression, including recapture by creator.
  captures[key]={owner=byPID,kind=u:GetUnitType(),class=info and info.Capture,originalClass=info and info.Class,
    x=u:GetX(),y=u:GetY(),turn=Game.GetGameTurn(),veteran=u:IsHasPromotion(VETERAN)}
end
local function Constructed(pid,cityID,buildingID)
  local p=Players[pid]
  if not Laureate(p) then return end
  local city=p:GetCityByID(cityID)
  local building=GameInfo.Buildings[buildingID]
  local class=building and GameInfo.BuildingClasses[building.BuildingClass]
  if city and city:GetOwner()==pid and city:GetNumBuilding(buildingID)>0 and class
      and class.MaxGlobalInstances==1 and class.MaxTeamInstances==-1
      and class.MaxPlayerInstances==-1 and not Get(p,'W'..buildingID) then
    Put(p,'W'..buildingID,1)
    Award(p,Scaled(p,40,10),'WONDER',Locale.ConvertTextKey(building.Description),city:GetX(),city:GetY())
  end
end
local function Sweep(p)
  -- CP setLevel has no event. UnitPromoted handles normal promotion immediately;
  -- one owner-turn unit pass also catches direct legitimate level setters, free
  -- promotions, insta-heal and loaded pending GP candidates. Never scans the map.
  for u in p:Units() do Settle(p,u); Veteran(p,u) end
end
local function Turn(pid)
  local p=Players[pid]
  if not Laureate(p) then return end
  Golden(p,true)
  Sweep(p)
  local turn=Game.GetGameTurn()
  if tonumber(Get(p,'HALLTURN')) == turn then return end
  local total=0
  if not p:IsAnarchy() then
    for city in p:Cities() do
      if city:GetOwner()==pid and not city:IsResistance() and not city:IsRazing() then
        total=total+city:GetNumActiveBuilding(HALL)
      end
    end
  end
  Put(p,'HALLTURN',turn) -- before native meter mutation, durable across reload
  if total>0 then Award(p,total) end
end
local function Hook(events, name, fn)
  local event=events[name]
  assert(event,'LC: missing required CP event '..name)
  local callback=function(...)
    if control.active and MapModData.LC_Controller==control then return fn(...) end
  end
  event.Add(callback)
  control.handlers[#control.handlers+1]={event=event,callback=callback}
end
Hook(GameEvents,'CityConstructed',Constructed)
Hook(GameEvents,'UnitCreated',Created)
Hook(GameEvents,'UnitConverted',Converted)
Hook(GameEvents,'UnitCaptured',Captured)
Hook(GameEvents,'UnitPrekill',function(pid,id)
  local p=Players[pid]; if Laureate(p) then Settle(p,p:GetUnitByID(id)) end
end)
Hook(GameEvents,'UnitPromoted',function(pid,id)
  local p=Players[pid]; Veteran(p,p and p:GetUnitByID(id))
end)
Hook(GameEvents,'CityTrained',function(pid,cityID,id)
  local p=Players[pid]
  if Laureate(p) then local u=p:GetUnitByID(id); Settle(p,u); Veteran(p,u) end
end)
Hook(GameEvents,'PlayerGoldenAge',function(pid) Golden(Players[pid],true) end)
Hook(GameEvents,'PlayerDoTurn',Turn)
Hook(GameEvents,'PlayerDoneTurn',function(pid)
  local p=Players[pid]
  if Laureate(p) then
    local ids={}; for id in pairs(pending[pid] or {}) do ids[#ids+1]=id end
    table.sort(ids)
    for _,id in ipairs(ids) do Settle(p,p:GetUnitByID(id)) end
    pending[pid]={}
    Golden(p,true)
  end
  for key,r in pairs(captures) do if r.owner==pid then captures[key]=nil end end
end)
Hook(GameEvents,'PlayerCanAdoptPolicy',function(pid,policy) return policy~=POLICY end)
local function Initialize()
  for _,p in pairs(Players) do
    if p:IsAlive() then
      Golden(p,false) -- reconcile loaded policy, never replay activation feedback
      if Laureate(p) then
        pending[p:GetID()]={}
        for u in p:Units() do
          if Get(u,'PERSON') then pending[p:GetID()][u:GetID()]=true end
        end
      end
    end
  end
end
Hook(Events,'SequenceGameInitComplete',Initialize)
Hook(Events,'LoadScreenClose',Initialize)
Initialize()
