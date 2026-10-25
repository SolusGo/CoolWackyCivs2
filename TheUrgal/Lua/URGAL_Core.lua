-- Save-local authority. One simulation owner, included only by URGAL_Potions.xml.
local previous = MapModData.URGAL
if previous and previous.active and previous.context == ContextPtr then return end
if previous then
 previous.active = false
 if previous.context and previous.context.ClearUpdate then previous.context:ClearUpdate() end
 for _,h in ipairs(previous.handlers or {}) do if h.event.Remove then h.event.Remove(h.fn) end end
end
local U = {active=true, context=ContextPtr, handlers={}, drinking={}, warnings={}}
MapModData.URGAL = U
local T = GameInfoTypes
U.CIV, U.STRENGTH, U.CHASER, U.RECOVERY = T.CIVILIZATION_URGAL, T.PROMOTION_URGAL_STRENGTH_II, T.PROMOTION_URGAL_POT_CHASER, T.PROMOTION_URGAL_POT_RECOVERY
local MAX = 9007199254740991
local playerPattern, unitPattern = '%[URGAL_P1:([^%]]*)%]', '%[URGAL_U1:([^%]]*)%]'
local excluded = {UNITCOMBAT_RECON=true, UNITCOMBAT_ARCHER=true, UNITCOMBAT_SIEGE=true, UNITCOMBAT_HELICOPTER=true}
function U.Civ(id)
 local p=Players[id]
 return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType()==U.CIV
end
function U.Turn() return Game.GetGameTurn() end
function U.Text(key,...) return Locale.ConvertTextKey('TXT_KEY_URGAL_'..key,...) end
local function SpeedTurns(exact,base,rounding)
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()] or {}
 if exact[speed.Type] then return exact[speed.Type] end
 local percent=tonumber(speed.TrainPercent) or 100
 if percent<=0 or percent~=percent or percent==math.huge then percent=100 end
 return math.max(1,math.floor(base*percent/100+rounding))
end
function U.Duration() return SpeedTurns({GAMESPEED_QUICK=3,GAMESPEED_STANDARD=5,GAMESPEED_EPIC=7,GAMESPEED_MARATHON=12},5,0) end
function U.Aftertaste() return SpeedTurns({GAMESPEED_QUICK=1,GAMESPEED_STANDARD=2,GAMESPEED_EPIC=3,GAMESPEED_MARATHON=6},2,0.5) end
local function Warn(key,err)
 if not U.warnings[key] then U.warnings[key]=true;print('URGAL '..key..': '..tostring(err)) end
end
function U.Alive(u) return u and not u:IsDead() and not u:IsDelayedDeath() end
function U.Eligible(u)
 if not U.Alive(u) or not u:IsCombatUnit() or u:GetDomainType()~=DomainTypes.DOMAIN_LAND or u:IsRanged() then return false end
 local row=GameInfo.Units[u:GetUnitType()]
 return row and row.Combat and row.Combat>0 and row.CombatClass and not excluded[row.CombatClass] and (row.RangedCombat or 0)==0
end
local function Numbers(raw,count)
 if type(raw)~='string' then return nil end
 local out={}
 for part in string.gmatch(raw..':','([^:]*):') do
  if not string.match(part,'^%d+$') then return nil end
  local n=tonumber(part)
  if not n or n>MAX then return nil end
  out[#out+1]=n
 end
 if #out~=count then return nil end
 return out
end
local function Read(object,pattern) return string.match(object:GetScriptData() or '',pattern) end
local function Write(object,pattern,tag,value)
 local raw=object:GetScriptData() or ''
 local clean=string.gsub(raw,pattern,'')
 local nextData=clean..(value and ('['..tag..':'..value..']') or '')
 if raw~=nextData then object:SetScriptData(nextData) end
end
local function Encode(values)
 local out={}
 for i,n in ipairs(values) do out[i]=string.format('%.0f',n) end
 return table.concat(out,':') -- keep large valid stockpiles out of scientific notation
end
function U.Save(id,s)
 Write(Players[id],playerPattern,'URGAL_P1',Encode({s.potions,s.era,s.finish,s.ready,s.serial}))
end
function U.State(id)
 if not U.active or not U.Civ(id) then return nil end
 local p=Players[id]; local raw=Read(p,playerPattern)
 local _,records=string.gsub(p:GetScriptData() or '',playerPattern,'')
 if records>1 or (not raw and string.find(p:GetScriptData() or '','[URGAL_P',1,true)) then return nil end
 if raw then
  local v=Numbers(raw,5)
  -- Absolute saved deadlines are authoritative. This accepts legacy v15
  -- two-turn Aftertaste without rewriting an in-progress window on upgrade.
  if not v or (v[3]==0 and (v[4]~=0 or v[5]~=0)) or (v[3]>0 and (v[4]<=v[3] or v[5]==0)) then return nil end
  return {potions=v[1],era=v[2],finish=v[3],ready=v[4],serial=v[5]}
 end
 -- Advanced-era starts receive the one initial bottle, not retroactive eras.
 local s={potions=1,era=math.max(0,p:GetCurrentEra()),finish=0,ready=0,serial=0}
 U.Save(id,s); return s
end
function U.Mark(u,id,s)
 Write(u,unitPattern,'URGAL_U1',s and Encode({id,s.serial,s.finish}) or nil)
end
local function Promo(u,p,on) if u:IsHasPromotion(p)~=on then u:SetHasPromotion(p,on) end end
function U.Unit(id,u,s)
 if not U.Alive(u) then return end
 local v=Numbers(Read(u,unitPattern),3)
 local on=s and U.Civ(id) and v and v[1]==id and v[2]==s.serial and v[3]==s.finish and U.Turn()<s.finish and U.Eligible(u)
 -- Embarked snapshot units retain their record but cannot use either effect.
 local use=on and not u:IsEmbarked() or false
 Promo(u,U.STRENGTH,use)
 Promo(u,U.RECOVERY,use and u:IsHasPromotion(U.CHASER) or false)
 if not on and Read(u,unitPattern) then U.Mark(u,id,nil) end
end
function U.Units(id,s)
 local p=Players[id]
 if p then for u in p:Units() do
  local ok,err=pcall(U.Unit,id,u,s)
  if not ok then Warn('unit '..id..':'..u:GetID(),err) end
 end end
end
function U.Notify(id,key,...)
 local p=Players[id]
 if p and p:IsHuman() then
  local text=U.Text(key,...)
  local ok,err=pcall(function() p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,text,U.Text('TRAIT'),-1,-1) end)
  if not ok then Warn('notification',err) end
 end
end
function U.Sync(id,era)
 if not U.active then return nil end
 local s=U.State(id)
 if not s then U.Units(id,nil); return nil end
 local current=math.max(Players[id]:GetCurrentEra(),era or 0)
 if current>s.era then
  local gained=current-s.era
  s.potions=s.potions+gained; s.era=current; U.Save(id,s)
  U.Notify(id,'GAIN',gained,s.potions)
 end
 U.Units(id,s)
 return s
end
function U.Count(id)
 local n=0
 if U.Civ(id) then for u in Players[id]:Units() do if U.Eligible(u) and not u:IsEmbarked() then n=n+1 end end end
 return n
end
function U.CanDrink(id)
 local s=U.State(id)
 return U.active and not U.drinking[id] and s and s.potions>0 and U.Turn()>=s.ready and U.Count(id)>0
end
function U.Drink(id)
 if not U.active or not U.CanDrink(id) then return false end
 U.drinking[id]=true
 local ok,err=pcall(function()
  local s=U.State(id); local units={}; local immediate=0
  for u in Players[id]:Units() do if U.Eligible(u) then
   units[#units+1]=u;if not u:IsEmbarked() then immediate=immediate+1 end
  end end
  s.potions=s.potions-1; s.serial=s.serial+1; s.finish=U.Turn()+U.Duration(); s.ready=s.finish+U.Aftertaste()
  -- Commit expenditure first; duplicate/reentrant clicks cannot spend again.
  U.Save(id,s)
  -- Record the full snapshot before promotion setters can publish dirty events.
  for _,u in ipairs(units) do U.Mark(u,id,s) end
  U.Units(id,s)
  U.Notify(id,'DRANK',U.Duration(),immediate,#units-immediate)
 end)
 U.drinking[id]=nil
 if not ok then Warn('drink '..id,err);return false end
 if U.Refresh then U.Refresh() end
 return true
end
function U.Hook(events,name,fn)
 local event=events and events[name]
 if event and event.Add then
  local safe=function(...)
   if not U.active then return end
   local ok,err=pcall(fn,...)
   if not ok then print('URGAL '..name..': '..tostring(err)) end
  end
  event.Add(safe); U.handlers[#U.handlers+1]={event=event,fn=safe}
 end
end
-- Human-only. URGAL_AI.lua is retained as dormant legacy source, never loaded.
U.Hook(GameEvents,'PlayerDoTurn',function(id)
 if U.Civ(id) then
  local s=U.Sync(id)
  if s and U.Turn()==s.finish then U.Notify(id,'EXPIRED',math.max(0,s.ready-U.Turn())) end
 elseif Players[id] then
  -- Clean a transferred promotion even if a third-party transfer skipped conversion.
  for u in Players[id]:Units() do
   if u:IsHasPromotion(U.STRENGTH) or u:IsHasPromotion(U.RECOVERY) or Read(u,unitPattern) then U.Unit(id,u,nil) end
  end
 end
 if U.Refresh then U.Refresh() end
end)
U.Hook(GameEvents,'TeamSetEra',function(team,era)
 for id=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if U.Civ(id) and Players[id]:GetTeam()==team then U.Sync(id,era) end end
 if U.Refresh then U.Refresh() end
end)
U.Hook(GameEvents,'UnitCreated',function(id,unitID)
 local p=Players[id]; local u=p and p:GetUnitByID(unitID)
 -- Native new units have no snapshot marker. A duplicate creation notification
 -- for an existing participant must not erase its legitimate saved identity.
 if u then U.Unit(id,u,U.Civ(id) and Read(p,playerPattern) and U.State(id) or nil) end
 if U.Civ(id) and U.QueueRefresh then U.QueueRefresh() end
end)
U.Hook(GameEvents,'UnitConverted',function(oldOwner,newOwner,oldID,newID,isUpgrade)
 local old=Players[oldOwner] and Players[oldOwner]:GetUnitByID(oldID)
 local new=Players[newOwner] and Players[newOwner]:GetUnitByID(newID)
 if not new then return end
 local s=U.State(newOwner)
 -- The CP hook follows promotion copying and precedes old-unit destruction.
 local v=old and Numbers(Read(old,unitPattern),3)
 if isUpgrade and oldOwner==newOwner and s and v and v[1]==oldOwner and v[2]==s.serial and v[3]==s.finish and U.Turn()<s.finish and U.Eligible(new) then
  U.Mark(new,newOwner,s)
 else U.Mark(new,newOwner,nil) end
 U.Unit(newOwner,new,s)
 if (U.Civ(oldOwner) or U.Civ(newOwner)) and U.QueueRefresh then U.QueueRefresh() end
end)
U.Hook(GameEvents,'UnitSetXY',function(id,unitID)
 local u=Players[id] and Players[id]:GetUnitByID(unitID)
 if u and (U.Civ(id) or u:IsHasPromotion(U.STRENGTH) or u:IsHasPromotion(U.RECOVERY)) then
  U.Unit(id,u,U.State(id))
  if U.QueueRefresh then U.QueueRefresh() end
 end
end)
function U.Bootstrap()
 if not U.active then return end
 for id=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do
  if U.Civ(id) then U.Sync(id) elseif Players[id] then
   for u in Players[id]:Units() do
    if u:IsHasPromotion(U.STRENGTH) or u:IsHasPromotion(U.RECOVERY) or Read(u,unitPattern) then U.Unit(id,u,nil) end
   end
  end
 end
 if U.Refresh then U.Refresh() end
end
U.Hook(Events,'SequenceGameInitComplete',U.Bootstrap)
U.Hook(Events,'LoadScreenClose',U.Bootstrap)
if ContextPtr.SetShutdown then ContextPtr:SetShutdown(function()
 U.active=false
 if U.context.ClearUpdate then U.context:ClearUpdate() end
 for _,h in ipairs(U.handlers) do if h.event.Remove then h.event.Remove(h.fn) end end
 if MapModData.URGAL==U then MapModData.URGAL=nil end
end) end
U.Bootstrap()
