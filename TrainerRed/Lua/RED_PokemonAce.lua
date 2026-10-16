local R=MapModData.RED_Legend
function R.RescueAce(s,r)
 if r.ace then s.rescuedAces=s.rescuedAces or {};s.rescuedAces[r.ace.token]=r.ace;r.ace=nil end
end
local function aceToken(u)
 local pid,token=(u:GetScriptData() or ''):match('|REDACE:(%d+):(%d+)|')
 if tonumber(pid)==u:GetOwner() then return tonumber(token) end
end
local function tagAce(u,token)
 u:SetScriptData((u:GetScriptData() or ''):gsub('|REDACE:%d+:%d+|','')..'|REDACE:'..u:GetOwner()..':'..token..'|')
end
local function materializeAce(s,snap,x,y)
 local p=Players[s.pid];local j=snap.returning;local ace=j and p:GetUnitByID(j.id)
 if j and (not R.Alive(ace) or aceToken(ace)~=snap.token or ace:GetGameTurnCreated()~=j.born) then return true end
 local plot=not j and R.SpawnPlot(s.pid,R.ACE,x,y,nil,snap)
 if not j and not plot then return false end
 local ok=R.Internal(function()
  if not ace then
   ace=p:InitUnit(R.ACE,plot:GetX(),plot:GetY());if not ace then return end
   tagAce(ace,snap.token);snap.returning={id=ace:GetID(),born=ace:GetGameTurnCreated()};R.Save(s)
  end
  R.Restore(ace,snap);tagAce(ace,snap.token)
 end)
 return ok and ace~=nil
end
function R.RecoverAces(s)
 local p=Players[s.pid];local home=p:GetCapitalCity()
 if not p:IsAlive() or not home then return end
 -- Retire an original left alive by an interrupted attachment, never a journaled return.
 local attached={};for _,r in pairs(s.units) do if r.ace then attached[r.ace.token]=r.ace end end
 for token,snap in pairs(s.rescuedAces or {}) do attached[token]=snap end
 local retire={}
 for u in p:Units() do local token=aceToken(u);local snap=token and attached[token]
  if u:GetUnitType()==R.ACE and snap and not (snap.returning and snap.returning.id==u:GetID() and snap.returning.born==u:GetGameTurnCreated()) then retire[#retire+1]=u end
 end
 local ok=R.Internal(function() for _,u in ipairs(retire) do u:Kill(false,-1) end end)
 if not ok then return end
 for _,r in pairs(s.units) do
  if r.ace and r.ace.returning and materializeAce(s,r.ace,home:GetX(),home:GetY()) then
   r.ace=nil;local host=R.Unit(s,r.serial);if host then R.Apply(host,r) end;R.Save(s)
  end
 end
 local keys={};for token in pairs(s.rescuedAces or {}) do keys[#keys+1]=token end;table.sort(keys)
 for _,token in ipairs(keys) do
  if materializeAce(s,s.rescuedAces[token],home:GetX(),home:GetY()) then s.rescuedAces[token]=nil end
  R.Save(s)
 end
end
function R.CanAttach(s,u)
 local r=R.Peek(u);if not r or r.ace or u:IsBusy() or not R.Alive(u) then return end
 local best
 for ace in Players[s.pid]:Units() do
  if ace:GetUnitType()==R.ACE and not ace:IsBusy() and R.Distance(ace,u)<=1 and ace:MovesLeft()>0 and (not best or ace:GetID()<best:GetID()) then best=ace end
 end
 return best
end
function R.Attach(s,u)
 local ace=R.CanAttach(s,u);if not ace then return false end
 local r=R.Record(u);r.ace=R.Snapshot(ace);r.ace.token=s.nextSerial;s.nextSerial=s.nextSerial+1
 tagAce(ace,r.ace.token);R.Save(s);R.Internal(function() ace:Kill(false,-1) end)
 R.Apply(u,r);R.Changed(s);return true
end
function R.Detach(s,u)
 local r=R.Record(u)
 if not r or not r.ace or u:IsBusy() or u:GetPlot():GetOwner()~=s.pid then return false end
 local ok=materializeAce(s,r.ace,u:GetX(),u:GetY());if ok then r.ace=nil end
 R.Apply(u,r);R.Yields(s);R.Changed(s);return ok
end
function R.CanItem(s,u)
 local r=R.Peek(u)
 return r and r.ace and not u:IsBusy() and not R.Attacked(u) and Game.GetGameTurn()>=(r.itemReady or 0)
end
function R.Item(s,u)
 if not R.CanItem(s,u) then return false end
 local r=R.Record(u);r.itemReady=Game.GetGameTurn()+R.Turns(8)
 R.Save(s) -- commit the cooldown before effects or reentrant UI events
 R.Heal(u,25);R.Set(u,'BLOOM_STATUS',false)
 u:SetMoves(u:MaxMoves());R.Apply(u,r);R.Changed(s);return true
end
R.activeAirlifts={}
local function airliftCities(s,u,city)
 if not R.Alive(u) or not city or u:GetOwner()~=s.pid or u:GetDomainType()~=DomainTypes.DOMAIN_LAND or u:IsEmbarked() or u:HasMoved() or R.Attacked(u) or u:MovesLeft()<u:MaxMoves() then return end
 local from=u:GetPlot():GetPlotCity()
 if not from or from:GetOwner()~=s.pid or from:GetNumBuilding(R.CENTER)==0 or from:GetID()==city:GetID() or s.airlifts[from:GetID()]==Game.GetGameTurn() then return end
 if city:GetOwner()~=s.pid or (city:GetNumBuilding(R.CENTER)==0 and city:GetNumBuilding(GameInfoTypes.BUILDING_AIRPORT)==0) then return end
 return from
end
local function request(s,u,city)
 local from=airliftCities(s,u,city);if not from then return end
 if not R.Serial(u) then return end
 return {pid=s.pid,id=u:GetID(),serial=R.Serial(u),born=u:GetGameTurnCreated(),from=from:GetID(),to=city:GetID(),fx=from:GetX(),fy=from:GetY(),x=city:GetX(),y=city:GetY(),turn=Game.GetGameTurn()}
end
function R.AirliftPermission(pid,id,x,y,destination)
 if not R.IsRed(pid) then return false end
 local s=R.State(pid);local u=Players[pid]:GetUnitByID(id);local serial=u and R.Serial(u)
 local q=R.airliftQuery or (serial and R.activeAirlifts[pid..':'..serial] and s.pendingAirlifts[serial])
 if not q or q.pid~=pid or q.id~=id or q.serial~=serial or q.turn~=Game.GetGameTurn() or not R.Alive(u) or u:GetGameTurnCreated()~=q.born then return false end
 local city=Players[pid]:GetCityByID(q.to);local from=city and airliftCities(s,u,city)
 if not from or from:GetID()~=q.from or from:GetX()~=q.fx or from:GetY()~=q.fy or city:GetX()~=q.x or city:GetY()~=q.y then return false end
 return x==(destination and q.x or q.fx) and y==(destination and q.y or q.fy)
end
function R.CheckAirlift(s,u,city)
 if not u or u:IsBusy() then return false end
 local q=request(s,u,city);if not q then return false end
 for _,other in pairs(s.pendingAirlifts) do if other.from==q.from or other.id==q.id then return false end end
 R.airliftQuery=q
 -- Native canMoveInto(DESTINATION), water and adjacent-enemy checks still run.
 local ok,result=pcall(function() return u:CanAirliftAt(u:GetPlot(),city:GetX(),city:GetY()) end)
 R.airliftQuery=nil;return ok and result
end
local function finishAirlift(s,serial)
 local q=s.pendingAirlifts[serial];if not q then return false end
 local u=Players[s.pid]:GetUnitByID(q.id)
 local success=R.Alive(u) and R.Serial(u)==serial and u:GetGameTurnCreated()==q.born and
  u:GetX()==q.x and u:GetY()==q.y and u:MovesLeft()==0 and u:HasMoved()
 if success then s.airlifts[q.from]=q.turn end
 s.pendingAirlifts[serial]=nil;R.activeAirlifts[s.pid..':'..serial]=nil;R.Changed(s)
 return success
end
function R.ObserveAirlift(pid,id,x,y)
 if not R.IsRed(pid) then return end
 local s=R.State(pid);local u=Players[pid]:GetUnitByID(id);local serial=u and R.Serial(u);local q=serial and s.pendingAirlifts[serial]
 -- Native airlift finishes movement BEFORE UnitSetXY; no replay/resubmission.
 if q and q.id==id and (x~=q.fx or y~=q.fy) then finishAirlift(s,serial) end
end
function R.RecoverAirlifts(s)
 local todo={}
 for serial,q in pairs(s.pendingAirlifts) do
  if not R.activeAirlifts[s.pid..':'..serial] or q.turn~=Game.GetGameTurn() then todo[#todo+1]=serial end
 end
 -- After load permission is revoked. Only an already-arrived unit consumes a slot.
 for _,serial in ipairs(todo) do finishAirlift(s,serial) end
end
function R.Airlift(s,u,city)
 if not R.CheckAirlift(s,u,city) then return false end
 local q=request(s,u,city);local serial=q.serial;local key=s.pid..':'..serial
 s.pendingAirlifts[serial]=q;R.activeAirlifts[key]=true;R.Save(s)
 local ok=pcall(function() u:PushMission(MissionTypes.MISSION_AIRLIFT,q.x,q.y,0,0,1) end)
 if not ok then finishAirlift(s,serial);return false end
 if not s.pendingAirlifts[serial] then return s.airlifts[q.from]==q.turn end
 local tries,elapsed=0,0
 local function check(dt)
  if not s.pendingAirlifts[serial] then return end
  tries=tries+1;elapsed=elapsed+(dt or 0)
  local current=Players[s.pid]:GetUnitByID(q.id)
  if not R.Alive(current) or current:GetX()~=q.fx or current:GetY()~=q.fy or tries>=180 or elapsed>=3 or q.turn~=Game.GetGameTurn() then finishAirlift(s,serial)
  else R.AfterNative('airlift:'..key,check) end
 end
 R.AfterNative('airlift:'..key,check);R.Changed(s);return true -- accepted, possibly pending
end
