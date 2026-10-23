-- Sole simulation owner, included by GARVEY_RollCall.xml. Lua 5.1 / CP v151.
if MapModData.Garvey then return end
local G={states={},failed={},syncing={}}
MapModData.Garvey=G
G.CIV=GameInfoTypes.CIVILIZATION_GARVEY_CLASSROOM
G.UNIT=GameInfoTypes.UNIT_GARVEY_HALL_MONITOR
G.OFFICE=GameInfoTypes.BUILDING_GARVEY_PRINCIPALS_OFFICE
G.config={}
for row in GameInfo.GARVEY_Config() do G.config[row.Name]=row.Value end
G.students={'Aaron','Denise','Jacqueline','Blake','Timothy'}
G.dummies={'AARON','DENISE','JACQUELINE','TIMOTHY','DETENTION','OFFICE_SCIENCE'}
G.promotions={}
for _,name in ipairs({'HALL','BLAKE','DETENTION','HALL_DETENTION'}) do
 G.promotions[name]=GameInfoTypes['PROMOTION_GARVEY_'..name]
end
local store
local function db() if not store then store=Modding.OpenSaveData() end;return store end
function G.Hook(events,name,fn) if events[name] and events[name].Add then events[name].Add(fn) end end
function G.Text(key,...) return Locale.ConvertTextKey('TXT_KEY_GARVEY_'..key,...) end
function G.Human(pid)
 local p=Players[pid]
 return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType()==G.CIV
end
function G.Notify(pid,message)
 local p=Players[pid]
 if p and p:IsHuman() then p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,message,G.Text('TRAIT')) end
end
function G.Guard(label,fn)
 local ok,err=pcall(fn)
 if not ok then print('[Garvey] '..label..': '..tostring(err)) end
 return ok
end
local fields={'clock','founded','ready','student','bonusEnd','insub','detEnd','notified'}
local function key(pid) return 'GARVEY:v1:state:'..pid end
function G.Save(pid,s)
 local a={'1'}
 for _,name in ipairs(fields) do a[#a+1]=tostring(s[name]) end
 local encoded=table.concat(a,'|')
 db().SetValue(key(pid),encoded)
 assert(db().GetValue(key(pid))==encoded,'save did not retain classroom state')
 G.states[pid]=s
end
function G.MarkKill(pid,loser,effect)
 -- A native delayed death can call UnitPrekill twice, including after a load.
 -- Unit ID plus creation turn identifies that lifetime; keep the paid bit in
 -- the save database, not an ever-growing Lua scan/list.
 local k='GARVEY:v1:kill:'..pid..':'..effect..':'..loser.pid..':'..loser.id..':'..loser.born
 if db().GetValue(k)~=nil then return false end
 db().SetValue(k,1)
 assert(db().GetValue(k)==1,'kill ledger write did not persist')
 return true
end
function G.State(pid)
 if G.failed[pid] then return nil end
 if G.states[pid] then return G.states[pid] end
 local result
 local ok=G.Guard('load player '..pid,function()
  local raw=db().GetValue(key(pid));local s={}
  if raw==nil then
   if not G.Human(pid) then return end
   local cap=Players[pid]:GetCapitalCity();if not cap then return end
   local turn=Game.GetGameTurn();local founded=cap:GetGameTurnFounded()
   s={clock=turn,founded=founded,ready=founded+G.config.RollInterval,student=0,
      bonusEnd=-1,insub=0,detEnd=-1,notified=-1}
   G.Save(pid,s)
  else
   local parts={};for value in tostring(raw):gmatch('[^|]+') do parts[#parts+1]=tonumber(value) end
   assert(#parts==9 and parts[1]==1,'invalid or newer classroom save')
   for i,name in ipairs(fields) do
    local value=parts[i+1];assert(value and value==math.floor(value),'noninteger save field');s[name]=value
   end
   assert(s.student>=0 and s.student<=5 and s.insub>=0 and s.insub<G.config.CorrectionThreshold
     and s.founded>=0 and s.clock>=s.founded and s.ready>=s.founded,'invalid classroom state')
   G.states[pid]=s
  end
  result=s
 end)
 if not ok then G.failed[pid]=true end
 return result
end
function G.Active(s,name) return s and s[name]>s.clock or false end
function G.Student(s) return G.Active(s,'bonusEnd') and s.student or 0 end
function G.Promotion(u,id,value)
 if u:IsHasPromotion(id)~=value then u:SetHasPromotion(id,value) end
end
function G.Unit(pid,u)
 if not u or u:IsDead() or u:IsDelayedDeath() then return end
 local s=G.Human(pid) and G.State(pid) or nil
 local eligible=s and (u:IsCombatUnit() or u:IsRanged()) or false
 local detained=eligible and G.Active(s,'detEnd') or false
 G.Promotion(u,G.promotions.BLAKE,eligible and G.Student(s)==4 or false)
 G.Promotion(u,G.promotions.DETENTION,detained)
 G.Promotion(u,G.promotions.HALL_DETENTION,detained and u:GetUnitType()==G.UNIT or false)
end
local function set(city,id,n)
 if city:GetNumRealBuilding(id)~=n then city:SetNumRealBuilding(id,n,true) end
end
function G.Sync(pid,units)
 local p=Players[pid];if not p or G.syncing[pid] then return end
 G.syncing[pid]=true
 local ok=G.Guard('reconcile player '..pid,function()
  local s=G.Human(pid) and G.State(pid) or nil
  local selected=G.Student(s);local detained=G.Active(s,'detEnd');local office=false
  for city in p:Cities() do
   local hasOffice=city:GetNumBuilding(G.OFFICE)>0;office=office or hasOffice
   local active={AARON=selected==1,DENISE=selected==2,JACQUELINE=selected==3,
    TIMOTHY=selected==5,DETENTION=detained,OFFICE_SCIENCE=detained and hasOffice}
   for _,name in ipairs(G.dummies) do set(city,GameInfoTypes['BUILDING_GARVEY_'..name],active[name] and 1 or 0) end
  end
  for _,name in ipairs({'FULL','RELIEF'}) do
   local id=GameInfoTypes['POLICY_GARVEY_PENALTY_'..name]
   local want=detained and ((name=='RELIEF')==office) or false
   if p:HasPolicy(id)~=want then p:SetHasPolicy(id,want,true) end
  end
  if units then for u in p:Units() do G.Unit(pid,u) end end
 end)
 G.syncing[pid]=nil
 return ok
end
function G.CanRoll(pid,expected)
 if not G.Human(pid) or Game.GetActivePlayer()~=pid or not Players[pid]:IsTurnActive()
  or not Players[pid]:GetCapitalCity() or G.syncing[pid] then return false end
 local s=G.State(pid)
 return s and s.clock>=s.ready and (expected==nil or expected==s.ready) or false
end
function G.Roll(pid,student,expected)
 if not G.CanRoll(pid,expected) or not G.InterfaceReady() or not G.students[student] then return false end
 local old=G.State(pid);local s={};for k,v in pairs(old) do s[k]=v end
 -- One synchronized roll, including no roll at all for Timothy.
 local chance=G.config[G.students[student]..'Correction']
 local corrected=student~=5 and chance>0 and Game.Rand(100,'Garvey student correction')<chance
 s.student=student;s.bonusEnd=s.clock+G.config.BonusDuration;s.ready=s.clock+G.config.RollInterval
 s.insub=s.insub+(corrected and 1 or 0)
 local trigger=s.insub>=G.config.CorrectionThreshold
 if trigger then s.insub=0;s.detEnd=s.clock+G.config.DetentionDuration end
 -- Commit before native modifiers/notifications; repeated or stale UI clicks fail.
 if not G.Guard('save Roll Call',function() G.Save(pid,s) end) then G.failed[pid]=true;G.Sync(pid,true);return false end
 G.Sync(pid,true)
 G.Notify(pid,(corrected or student==5) and G.Text('CORRECTION_'..student)
  or G.Text('ACCEPTED',G.Text('STUDENT_'..student),G.config.BonusDuration))
 if trigger then G.Notify(pid,G.Text('DETENTION_START')) end
 LuaEvents.GARVEY_Changed(pid)
 return true
end
include('GARVEY_Events')
