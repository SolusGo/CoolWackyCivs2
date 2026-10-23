-- Sole simulation owner: included only by THE11CATS_Household.xml.
-- Gameplay and UI share this context; UI requests revalidate the authoritative registry.
if MapModData.THE11CATS and MapModData.THE11CATS.context==ContextPtr then return end
MapModData.THE11CATS={context=ContextPtr,states={},failed={},busy=false,spawning=false,removing={},DEBUG=false}
local H=MapModData.THE11CATS
H.CIV=GameInfoTypes.CIVILIZATION_THE11CATS
H.UNIT=GameInfoTypes.UNIT_THE11CATS_HOUSE_CAT
H.TREE=GameInfoTypes.BUILDING_THE11CATS_CAT_TREE
H.suffixes={'LUNA','BONNIE','APPA','LOKI','KURO','OSCAR','BOOMIE','CHARLOTTE','SISI','MAX','FIRST_PAIR','BONNIE_FAMILY','SISTERS_BED','MOTHER_DAUGHTER','TREE_FOOD'}
H.buildings={};for _,id in ipairs(H.suffixes) do H.buildings[id]=GameInfoTypes['BUILDING_THE11CATS_'..id] end
H.growth={SISI=GameInfoTypes.CITY_EVENT_CHOICE_THE11CATS_SISI,MOTHER_DAUGHTER=GameInfoTypes.CITY_EVENT_CHOICE_THE11CATS_MOTHER_DAUGHTER}
include('THE11CATS_Config')
function H.Log(message,always) if H.DEBUG or always then print('[The11Cats] '..message) end end
function H.Text(key,...) return Locale.ConvertTextKey('TXT_KEY_THE11CATS_'..key,...) end
function H.Turn() return Game.GetGameTurn() end
function H.Duration(n)
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
 return math.max(1,math.floor(n*(speed and speed.TrainPercent or 100)/100+0.5))
end
function H.Human(pid)
 local p=Players[pid]
 return p and p:IsHuman() and p:GetCivilizationType()==H.CIV and not Game.IsNetworkMultiPlayer() and not Game.IsHotSeat()
end
function H.Hook(events,name,fn) if events[name] and events[name].Add then events[name].Add(fn) end end
function H.Notify(pid,message)
 local p=Players[pid];if p and p:IsAlive() then
  local ok,err=pcall(p.AddNotification,p,NotificationTypes.NOTIFICATION_GENERIC,message,H.Text('TITLE'),-1,-1)
  if not ok then H.Log('Notification unavailable: '..tostring(err),true) end
 end
end
function H.Changed(pid)
 local ok,err=pcall(function() LuaEvents.THE11CATS_Changed(pid) end)
 if not ok then H.Log('Display refresh failed: '..tostring(err),true) end
end

-- Versioned, fixed-width numeric records, no loadstring, no user-settings storage.
-- Keep other mods' ScriptData verbatim. One native write per meaningful mutation.
local pattern='|THE11CATS1:([^|]*)|'
local fields={'status','x','y','founded','original','unit','cooldown','recovery'}
local function number(n) return type(n)=='number' and n==math.floor(n) and n>=-1 and n<2147483648 end
function H.Encode(s)
 local out={s.chapters,s.latest}
 for i=2,#H.Order do local c=s.cats[H.Order[i]];for _,key in ipairs(fields) do assert(number(c[key]));out[#out+1]=c[key] end end
 return table.concat(out,',')
end
function H.Save(s)
 local block=H.Encode(s);local p=Players[s.pid];local raw=p:GetScriptData() or ''
 if raw:match(pattern)==block then return true end
 p:SetScriptData(raw:gsub(pattern,'')..'|THE11CATS1:'..block..'|')
 return (p:GetScriptData() or ''):match(pattern)==block
end
function H.SaveSafe(s)
 local ok,err=pcall(H.Save,s)
 if ok and err then return true end
 -- A native setter may have mutated before reporting an error. Read back the
 -- whole authoritative block before deciding whether this transaction committed.
 local verified,value=pcall(function() return (Players[s.pid]:GetScriptData() or ''):match(pattern)==H.Encode(s) end)
 if verified and value then return true end
 H.Log('Save deferred for '..s.pid..': '..tostring(ok and 'native setter did not store the record' or err),true)
 if H.Request then H.Request(s.pid,false) end
 return false
end
function H.State(pid)
 if not H.Human(pid) or H.failed[pid] then return end
 if H.states[pid] then return H.states[pid] end
 local raw=Players[pid]:GetScriptData() or '';local block=raw:match(pattern)
 local s={pid=pid,chapters=0,latest=0,cats={}}
 local values={};if block then for n in (block..','):gmatch('(.-),') do values[#values+1]=tonumber(n) or false end end
 local valid=not block or #values==82
 local versions=0
 for version in raw:gmatch('|THE11CATS(%d+):') do versions=versions+1;if version~='1' then valid=false end end
 if versions>1 or (versions>0 and not block) then valid=false end
 if block then
  for _,n in ipairs(values) do if not number(n) then valid=false end end
  s.chapters=values[1];s.latest=values[2]
  valid=valid and s.chapters>=0 and s.chapters<=63 and s.latest>=0 and s.latest<=6
 end
 local index=3
 for i=2,#H.Order do
  local c={status=0,x=-1,y=-1,founded=-1,original=-1,unit=-1,cooldown=0,recovery=-1}
  if block then
   for _,key in ipairs(fields) do c[key]=values[index];index=index+1 end
   valid=valid and type(c.status)=='number' and c.status>=0 and c.status<=3 and c.cooldown>=0
  end
  s.cats[H.Order[i]]=c
 end
 if not valid then H.failed[pid]=true;H.Log('Invalid or unsupported state for '..pid..'; original ScriptData preserved, effects disabled.',true);return end
 H.states[pid]=s;return s
end
function H.City(c)
 if c.x<0 or c.y<0 then return end
 local plot=Map.GetPlot(c.x,c.y);local city=plot and plot:GetPlotCity()
 if city and city:GetGameTurnFounded()==c.founded and city:GetOriginalOwner()==c.original then return city end
end
function H.Identity(u)
 if not u or u:GetUnitType()~=H.UNIT then return end
 local found
 for i=2,#H.Order do local id=H.Order[i];if u:IsHasPromotion(GameInfoTypes['PROMOTION_THE11CATS_'..id]) then
  if found then return end;found=id
 end end
 return found
end
function H.Unit(s,id)
 local c=s.cats[id];local u=Players[s.pid]:GetUnitByID(c.unit)
 if u and u:GetOwner()==s.pid and not u:IsDead() and not u:IsDelayedDeath() and H.Identity(u)==id then return u end
end
function H.Remove(u)
 if not u then return end
 local owner,uid=u:GetOwner(),u:GetID();local key=owner..':'..uid;H.removing[key]=true
 local ok,err=pcall(u.Kill,u,false,-1);H.removing[key]=nil
 local present=Players[owner]:GetUnitByID(uid)
 if not present or present:IsDead() or present:IsDelayedDeath() then return true end
 H.Log('Unit cleanup deferred '..key..': '..(not ok and tostring(err) or 'engine retained unit'),true)
 if H.Request then if H.Human(owner) then H.Request(owner,false) else H.Foreign(owner) end end
 return false
end
function H.PurgeUnits(pid)
 local p=Players[pid];if not p then return end
 local remove={};for u in p:Units() do if u:GetUnitType()==H.UNIT then remove[#remove+1]=u end end
 for _,u in ipairs(remove) do H.Remove(u) end
end
function H.Residents(s,city)
 local result={}
 if not city or city:GetOwner()~=s.pid or city:IsRazing() then return result end
 for i=2,#H.Order do local id=H.Order[i];local c=s.cats[id]
  if c.status==2 and H.City(c)==city then result[#result+1]=id end
 end
 return result
end
function H.Bonds(s,city)
 local cats={};for _,id in ipairs(H.Residents(s,city)) do cats[id]=true end
 local result={}
 if cats.LUNA and Players[s.pid]:GetCapitalCity()==city then result.FIRST_PAIR=true end
 if cats.BONNIE and (cats.APPA or cats.LOKI or cats.KURO or cats.OSCAR or cats.BOOMIE) then result.BONNIE_FAMILY=true end
 if cats.APPA and cats.LOKI and cats.OSCAR then result.SISTERS_BED=true end
 if cats.CHARLOTTE and cats.SISI then result.MOTHER_DAUGHTER=true end
 return result
end
-- Reconcile every one of our dummies, including zeros; never trust existing buildings.
function H.ApplyCity(city,expected)
 local x,y,owner,founded,original=city:GetX(),city:GetY(),city:GetOwner(),city:GetGameTurnFounded(),city:GetOriginalOwner()
 local function stillCurrent()
  local plot=Map.GetPlot(x,y);local current=plot and plot:GetPlotCity()
  return current and current:GetOwner()==owner and current:GetGameTurnFounded()==founded and current:GetOriginalOwner()==original
 end
 for _,id in ipairs(H.suffixes) do
  local building=H.buildings[id];local count=expected[id] and 1 or 0
  if building and city:GetNumRealBuilding(building)~=count then
   city:SetNumRealBuilding(building,count)
   if not stillCurrent() then return false end
   H.Log('Effect '..id..'='..count..' in '..city:GetName())
  end
 end
 -- CP v151 native local GrowthMod, additive with other genuine growth modifiers.
 -- Separate reversible choices preserve independent Sisi / bond stacking.
 for id,choice in pairs(H.growth) do
  if city.IsCityEventChoiceActive and city.DoCityEventChoice and city.DoCancelCityEventChoice then
   local active=city:IsCityEventChoiceActive(choice)
   if expected[id] and not active then city:DoCityEventChoice(choice)
   elseif active and not expected[id] then city:DoCancelCityEventChoice(choice) end
   if not stillCurrent() then return false end
  elseif not H.growthMissing then H.growthMissing=true;H.Log('CP v151 city growth APIs unavailable; exact growth requires the target DLL.',true) end
 end
 return true
end
function H.Effects(pid)
 local p=Players[pid];if not p then return end
 local s=H.Human(pid) and H.State(pid)
 for city in p:Cities() do
  local expected={}
  if s and not city:IsRazing() then
   local residents=H.Residents(s,city)
   for _,id in ipairs(residents) do expected[id]=true end
   for id in pairs(H.Bonds(s,city)) do expected[id]=true end
   if #residents>0 and city:GetNumBuilding(H.TREE)>0 then expected.TREE_FOOD=true end
  end
  local x,y,name=city:GetX(),city:GetY(),city:GetName()
  local ok,err=pcall(H.ApplyCity,city,expected)
  if not ok then H.Log('Effect repair deferred in '..name..': '..tostring(err),true);H.Request(pid,false) end
  if err==false then H.Request(pid,false) end
  local plot=Map.GetPlot(x,y);local current=plot and plot:GetPlotCity()
  if current and current:GetOwner()~=pid then
   local cleaned,value=pcall(H.ApplyCity,current,{})
   if not cleaned or value==false then H.Foreign(current:GetOwner()) end
   H.Request(pid,false)
  elseif current and ok and err~=false and H.NoteBonds then H.NoteBonds(s,current,expected) end
 end
 if s and s.notices and s.notices.dirty then H.SaveNotices(s) end
end
function H.Recover(s,id,notify)
 local c=s.cats[id];if c.status==0 or c.status==3 then return end
 c.status=3;c.unit=-1;c.x=-1;c.y=-1;c.founded=-1;c.original=-1
 c.recovery=H.Turn()+H.Duration(3)
 H.Log(id..' recovering until '..c.recovery)
 if notify then H.Notify(s.pid,H.Text('FLED',H.Text(id..'_NAME'))) end
end
local function safe(plot,pid)
 if not plot or plot:GetOwner()~=pid or plot:IsWater() or plot:IsMountain() or plot:IsImpassable() or plot:IsVisibleEnemyUnit(pid) then return false end
 local city=plot:GetPlotCity();if city and (city:IsRazing() or city:IsResistance()) then return false end
 for n=0,plot:GetNumUnits()-1 do local u=plot:GetUnit(n);if u and (u:GetOwner()~=pid or not u:IsCombatUnit()) then return false end end
 return true
end
function H.SpawnPlot(pid,home)
 local p=Players[pid];local cities={}
 if home and home:GetOwner()==pid then cities[#cities+1]=home
 else
  local capital=p:GetCapitalCity();if capital then cities[#cities+1]=capital end
  for city in p:Cities() do if city~=capital then cities[#cities+1]=city end end
 end
 for _,city in ipairs(cities) do
  if not city:IsRazing() and not city:IsResistance() then
   local plot=city:Plot();if safe(plot,pid) then return plot end
   for d=0,5 do local q=Map.PlotDirection(city:GetX(),city:GetY(),d);if safe(q,pid) then return q end end
  end
 end
end
function H.PendingUnit(s,id)
 -- A failed configuration/rollback can leave a birth without any promotion.
 -- Treat unknown Cats conservatively until reconciliation can remove them.
 for u in Players[s.pid]:Units() do
  if u:GetUnitType()==H.UNIT and not u:IsDead() and not u:IsDelayedDeath() then
   local identity=H.Identity(u)
   local owner,backup=(u:GetScriptData() or ''):match('|THE11CATS:(%d+):([A-Z]+)|')
   if not identity and tonumber(owner)==s.pid and s.cats[backup] then identity=backup end
   if not identity or identity==id then return true end
  end
 end
 return false
end
function H.Spawn(s,id,home)
 if H.PendingUnit(s,id) then H.Request(s.pid,false);return false end
 local c=s.cats[id];local located,plot=pcall(H.SpawnPlot,s.pid,home)
 if not located then H.Log('Arrival lookup deferred for '..id..': '..tostring(plot),true);return false end
 if not plot then return false end
 local before={};for unit in Players[s.pid]:Units() do before[unit:GetID()]=true end
 H.spawning=true
 local ok,u=pcall(Players[s.pid].InitUnit,Players[s.pid],H.UNIT,plot:GetX(),plot:GetY(),UnitAITypes.NO_UNITAI)
 H.spawning=false
 if not ok then
  H.Log('Spawn interrupted for '..id..': '..tostring(u),true);u=nil
  local candidates={}
  for unit in Players[s.pid]:Units() do
   if not before[unit:GetID()] and unit:GetUnitType()==H.UNIT and unit:GetPlot()==plot then candidates[#candidates+1]=unit end
  end
  if #candidates==1 then u=candidates[1] else for _,unit in ipairs(candidates) do H.Remove(unit) end end
 end
 if not u or u:GetOwner()~=s.pid or u:IsDead() or u:IsDelayedDeath() then return false end
 local configured,err=pcall(function()
  u:SetHasPromotion(GameInfoTypes['PROMOTION_THE11CATS_'..id],true)
  u:SetHasPromotion(GameInfoTypes.PROMOTION_THE11CATS_HOME,true)
  u:SetName(H.Text(id..'_NAME'));u:SetNoMaintenance(true)
  local raw=u:GetScriptData() or ''
  u:SetScriptData(raw:gsub('|THE11CATS:%d+:[A-Z]+|','')..'|THE11CATS:'..s.pid..':'..id..'|')
 end)
 if not configured then H.Log('Spawn setup deferred for '..id..': '..tostring(err),true);H.Remove(u);return false end
 c.status=1;c.unit=u:GetID();c.x=-1;c.y=-1;c.founded=-1;c.original=-1;c.recovery=-1
 H.Log('Spawned '..id..' unit '..c.unit);return true
end
function H.Unlock(s)
 local era=Players[s.pid]:GetCurrentEra()
 for chapter=0,math.min(5,era) do
  local bit=2^chapter
  if math.floor(s.chapters/bit)%2==0 then
   -- Persist chapter before notifications; loading never replays the chapter.
   s.chapters=s.chapters+bit;s.latest=chapter+1
   for i=2,#H.Order do local id=H.Order[i];local c=s.cats[id]
    if H.Cats[id].era==chapter and c.status==0 then
     c.status=3;c.recovery=H.Turn() -- new arrivals wait safely, without a recovery penalty
     H.Log('Chapter '..(chapter+1)..' unlocks '..id)
    end
   end
   if H.SaveSafe(s) then H.Notify(s.pid,H.Text('CHAPTER_'..(chapter+1))..'[NEWLINE]'..H.Text('STORY_'..(chapter+1))) end
  end
 end
end
-- Bounded scan of this player's units, once per lifecycle mutation/turn/load.
-- Adopts one surviving canonical unit, removes duplicate/unknown House Cats.
function H.Reconcile(pid,unlock)
 local s=H.State(pid);if not s then H.Effects(pid);return end
 local p=Players[pid];local units={};local remove={};local present={};local references={}
 for id,c in pairs(s.cats) do if c.status==1 then
  if references[c.unit]~=nil then references[c.unit]=false else references[c.unit]=id end
 end end
 local candidates={}
 for u in p:Units() do
  if u:GetUnitType()==H.UNIT and not u:IsDead() and not u:IsDelayedDeath() then
   local id=H.Identity(u)
   local metaOwner,metaID=(u:GetScriptData() or ''):match('|THE11CATS:(%d+):([A-Z]+)|')
   local reference=references[u:GetID()]
   if reference and tonumber(metaOwner)==pid and metaID==reference then id=reference
   elseif not id and reference and not metaID then id=reference end
   if not id and tonumber(metaOwner)==pid and s.cats[metaID] and s.cats[metaID].status==1 then id=metaID end
   local c=id and s.cats[id]
   if c and u:GetOwner()==pid and (c.status==1 or (c.status==0 and H.Cats[id].era<=p:GetCurrentEra())) then
    candidates[id]=candidates[id] or {};candidates[id][#candidates[id]+1]=u
   else remove[#remove+1]=u end
  end
 end
 for _,id in ipairs(H.Order) do if candidates[id] then
  local c=s.cats[id];local list=candidates[id]
  table.sort(list,function(a,b)
   if (a:GetID()==c.unit)~=(b:GetID()==c.unit) then return a:GetID()==c.unit end
   return a:GetID()<b:GetID()
  end)
  local u=list[1];units[id]=u;c.status=1;c.unit=u:GetID()
  if H.Identity(u)~=id then
   H.Log('Repairing identity promotions for '..id,true)
   for i=2,#H.Order do u:SetHasPromotion(GameInfoTypes['PROMOTION_THE11CATS_'..H.Order[i]],H.Order[i]==id) end
  end
  local raw=u:GetScriptData() or '';local metaOwner,metaID=raw:match('|THE11CATS:(%d+):([A-Z]+)|')
  if tonumber(metaOwner)~=pid or metaID~=id then
   u:SetScriptData(raw:gsub('|THE11CATS:%d+:[A-Z]+|','')..'|THE11CATS:'..pid..':'..id..'|')
   H.Log('Repaired unit identity backup for '..id,true)
  end
  for i=2,#list do remove[#remove+1]=list[i] end
 end end
 for _,u in ipairs(remove) do
  H.Log('Removing duplicate or orphan House Cat',true)
  if not H.Remove(u) then
   local id=H.Identity(u);local owner,backup=(u:GetScriptData() or ''):match('|THE11CATS:(%d+):([A-Z]+)|')
   if not id and tonumber(owner)==pid and s.cats[backup] then id=backup end
   present[id or '__UNKNOWN']=true
  end
 end
 local capacity={}
 for i=2,#H.Order do local id=H.Order[i];local c=s.cats[id]
  if c.cooldown>H.Turn()+H.Duration(10) then c.cooldown=H.Turn()+H.Duration(10);H.Log('Repaired impossible cooldown for '..id,true) end
  if c.status==3 and (c.recovery<0 or c.recovery>H.Turn()+H.Duration(3)) then
   c.recovery=H.Turn()+H.Duration(3);H.Log('Repaired impossible recovery for '..id,true)
  end
  if c.status==0 and math.floor(s.chapters/2^H.Cats[id].era)%2==1 then
   c.status=3;c.recovery=H.Turn();H.Log('Restored unlocked identity '..id,true)
  end
  if c.status==2 then
   local city=H.City(c)
   if not city or city:GetOwner()~=pid or city:IsRazing() then H.Recover(s,id,true)
   else
    local key=city:GetID();capacity[key]=(capacity[key] or 0)+1
    if capacity[key]>3 then H.Log('Repairing overcapacity for '..id,true);H.Recover(s,id,false) end
   end
  elseif c.status==1 and not units[id] then H.Recover(s,id,true) end
  -- States are exclusive: invalidate all stale references outside their state.
  if c.status~=1 then c.unit=-1 end
  if c.status~=2 then c.x=-1;c.y=-1;c.founded=-1;c.original=-1 end
  if c.status~=3 then c.recovery=-1 end
 end
 if unlock then H.Unlock(s) end
 if p:IsAlive() then
  for i=2,#H.Order do local id=H.Order[i];local c=s.cats[id]
   if c.status==3 and not present[id] and not present.__UNKNOWN and H.Turn()>=c.recovery and H.Spawn(s,id) then H.Notify(pid,H.Text('RETURNED',H.Text(id..'_NAME'))) end
  end
 end
 H.SaveSafe(s);H.Effects(pid)
end
function H.CanSettle(pid,id)
 local s=H.State(pid);local c=s and s.cats[id]
 if not c then return false,'INVALID' end
 if c.status==0 then return false,'LOCKED' end
 if c.status==3 then return false,'RECOVERING_HELP' end
 if c.status~=1 then return false,'INVALID' end
 if c.cooldown>H.Turn() then return false,'WAIT_COOLDOWN' end
 local u=H.Unit(s,id);if not u then return false,'MISSING_UNIT' end
 local city=u:GetPlot() and u:GetPlot():GetPlotCity()
 if not city or city:GetOwner()~=pid or city:IsRazing() then return false,'NEED_CITY' end
 if #H.Residents(s,city)>=3 then return false,'FULL' end
 return true,'READY',city,u
end
function H.CanRehome(pid,id)
 local s=H.State(pid);local c=s and s.cats[id]
 if not c or c.status~=2 then return false,'INVALID' end
 if c.cooldown>H.Turn() then return false,'WAIT_COOLDOWN' end
 if H.PendingUnit(s,id) then return false,'PENDING_REPAIR' end
 local city=H.City(c)
 if not city or city:GetOwner()~=pid or city:IsRazing() then return false,'INVALID' end
 if not H.SpawnPlot(pid,city) then return false,'NO_SPAWN' end
 return true,'READY',city
end
function H.Command(pid,id,action)
 -- Never expose spawning/effects as a UI mutation. Reject stale or foreign requests.
 if pid~=Game.GetActivePlayer() or not H.Human(pid) or not Players[pid]:IsAlive() or not Players[pid]:IsTurnActive() or not H.InterfaceReady or not H.InterfaceReady() then return false,'NO_TURN' end
 local s=H.State(pid);local c=s and s.cats[id];if not c then return false,'INVALID' end
 if action=='SETTLE' then
  local ok,reason,city,u=H.CanSettle(pid,id);if not ok then return false,reason end
  local previous={};for _,key in ipairs(fields) do previous[key]=c[key] end
  c.status=2;c.unit=-1;c.x=city:GetX();c.y=city:GetY();c.founded=city:GetGameTurnFounded();c.original=city:GetOriginalOwner();c.recovery=-1
  if not H.SaveSafe(s) then for _,key in ipairs(fields) do c[key]=previous[key] end;return false,'PENDING_REPAIR' end
  H.Remove(u);H.Effects(pid);H.Log(id..' settled in '..city:GetName())
  if H.Feedback then H.Feedback(s,H.Text('SETTLED_'..id,city:GetName())) end
 elseif action=='REHOME' then
  local can,reason,city=H.CanRehome(pid,id);if not can then return false,reason end
  -- Spawn first; only commit the mutation when a safe unit actually exists.
  local previous={};for _,key in ipairs(fields) do previous[key]=c[key] end
  c.cooldown=H.Turn()+H.Duration(10)
  if not H.Spawn(s,id,city) then c.cooldown=previous.cooldown;return false,'NO_SPAWN' end
  if not H.SaveSafe(s) then
   H.Remove(H.Unit(s,id));for _,key in ipairs(fields) do c[key]=previous[key] end
   return false,'PENDING_REPAIR'
  end
  H.Effects(pid);H.Log(id..' rehoming until '..c.cooldown)
 else return false,'INVALID' end
 H.SaveSafe(s);return true
end

include('THE11CATS_Safety')
include('THE11CATS_Presentation')

-- Genuine CP events carry the actual added duration AFTER native mutation.
-- SetCounter is deliberately used: ChangeCounter would fire another event AND
-- grant other mods' instant WLTKD yields a second time. Fractional turns carry
-- within the city's save data so repeated short celebrations stay exactly +25%.
function H.WLTKD(pid,x,y,added)
 if not H.Human(pid) or not added or added<=0 then return end
 local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
 if not city or city:GetOwner()~=pid or city:GetWeLoveTheKingDayCounter()<=0 then return end
 -- Cities have no ScriptData binding in CP v151; plots do. Include owner and
 -- founding turn so a rebuilt or transferred city cannot inherit the remainder.
 local raw=plot:GetScriptData() or '';local owner,founded,remainder=raw:match('|THE11CATS_WLTKD:(%d+):(%d+):(%d)|')
 local carry=tonumber(owner)==pid and tonumber(founded)==city:GetGameTurnFounded() and tonumber(remainder) or 0
 if carry>3 then H.Log('Repaired invalid WLTKD fraction',true);carry=0 end
 local quarters=added+carry;local extra=math.floor(quarters/4);carry=quarters%4
 plot:SetScriptData(raw:gsub('|THE11CATS_WLTKD:%d+:%d+:%d|','')..'|THE11CATS_WLTKD:'..pid..':'..city:GetGameTurnFounded()..':'..carry..'|')
 if extra>0 then city:SetWeLoveTheKingDayCounter(city:GetWeLoveTheKingDayCounter()+extra) end
 H.Log('WLTKD '..city:GetName()..' +'..added..' extended +'..extra)
end
H.Hook(GameEvents,'CityBeginsWLTKD',H.WLTKD)
H.Hook(GameEvents,'CityExtendsWLTKD',H.WLTKD)
H.Hook(GameEvents,'PlayerDoTurn',function(pid)
 if H.Human(pid) then H.Reconcile(pid,true)
 elseif Players[pid] and Players[pid]:GetCivilizationType()==H.CIV then H.PurgeUnits(pid);H.Effects(pid) end
end)
H.Hook(GameEvents,'PlayerCityFounded',function(pid) if H.Human(pid) then H.Reconcile(pid,true) end end)
H.Hook(GameEvents,'TeamSetEra',function(team)
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if H.Human(pid) and Players[pid]:GetTeam()==team then H.Reconcile(pid,true) end end
end)
H.Hook(GameEvents,'CapitalChanged',function(pid) if H.Human(pid) then H.Reconcile(pid,false) end end)
H.Hook(GameEvents,'CityCaptureComplete',function(oldID,capital,x,y,newID)
 -- This event is AFTER city reconstruction. Never use the old owner city ID.
 local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
 if city then
  local ok,err=pcall(H.ApplyCity,city,{})
  if not ok or err==false then
   H.Log('Captured-city cleanup deferred: '..tostring(err),true)
   local current=plot:GetPlotCity();if current then H.Foreign(current:GetOwner()) end
  end
 end
 if H.Human(oldID) then H.Reconcile(oldID,false) end
 if H.Human(newID) then H.Reconcile(newID,true) end
end)
H.Hook(GameEvents,'CityConstructed',function(pid,cityID,building) if building==H.TREE and H.Human(pid) then H.Effects(pid);H.Changed(pid) end end)
H.Hook(GameEvents,'CitySoldBuilding',function(pid,cityID,building) if building==H.TREE and H.Human(pid) then H.Effects(pid);H.Changed(pid) end end)
H.Hook(GameEvents,'UnitPrekill',function(pid,unitID,unitType,x,y,delay,byPlayer)
 if unitType~=H.UNIT or H.removing[pid..':'..unitID] or not H.Human(pid) then return end
 local s=H.State(pid);if not s then return end
 for i=2,#H.Order do local id=H.Order[i];local c=s.cats[id]
  if c.status==1 and c.unit==unitID then H.Recover(s,id,true);H.SaveSafe(s);H.Changed(pid);H.Request(pid,false);break end
 end
end)
-- Capture class is NULL. Native capture can only destroy this civilian, never
-- reward a Worker or hand its identity to an enemy. Prekill records recovery.
H.Hook(GameEvents,'PlayerCanDisbandUnit',function(pid,unitID)
 local p=Players[pid];local u=p and p:GetUnitByID(unitID);return not (u and u:GetUnitType()==H.UNIT)
end)
H.Hook(GameEvents,'CanDoCommand',function(pid,unitID,command)
 local p=Players[pid];local u=p and p:GetUnitByID(unitID)
 if u and u:GetUnitType()==H.UNIT and (command==CommandTypes.COMMAND_DELETE or command==CommandTypes.COMMAND_GIFT or command==CommandTypes.COMMAND_UPGRADE) then return false end
 return true
end)
H.Hook(GameEvents,'CityCanTrain',function(pid,cityID,unitType) return unitType~=H.UNIT end)
H.Hook(GameEvents,'PlayerCanTrain',function(pid,unitType) return unitType~=H.UNIT end)
H.Hook(GameEvents,'CityCanConstruct',function(pid,cityID,building)
 return building~=H.TREE or H.Human(pid)
end)
H.Hook(GameEvents,'UnitCanHaveAnyUpgrade',function(pid,unitID)
 local p=Players[pid];local u=p and p:GetUnitByID(unitID);return not (u and u:GetUnitType()==H.UNIT)
end)

H.Hook(Events,'SerialEventGameDataDirty',H.Schedule)
H.Hook(Events,'SerialEventCityInfoDirty',H.Schedule)
H.Hook(Events,'SerialEventUnitDestroyed',H.Schedule)
H.Hook(Events,'SerialEventCityDestroyed',H.Schedule)
H.Hook(GameEvents,'UnitCreated',function(pid,unitID,unitType)
 if unitType==H.UNIT and not H.spawning then
  if not H.Human(pid) then H.Foreign(pid) end
  H.Schedule()
 end
end)
local function initialize()
 if not H.CIV or not H.UNIT or not H.TREE then H.Log('Missing database definitions; check Database.log.',true);return end
 H.ready=false
 for pid=0,GameDefines.MAX_CIV_PLAYERS-1 do
  local p=Players[pid]
  if p then
   if H.Human(pid) then H.Reconcile(pid,true)
   else
    -- One load-only cleanup of foreign/AI orphan units and our stale effects.
    local ok,err=pcall(function() H.PurgeUnits(pid);H.Effects(pid) end)
    if not ok then H.Log('Initial foreign cleanup deferred: '..tostring(err),true);H.Foreign(pid) end
   end
  end
 end
 H.ready=true
end
H.Hook(Events,'LoadScreenClose',initialize)
initialize()
