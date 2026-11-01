-- BNW / CP151. Native real-building counts remain the economic snapshot.
-- LANTERN1 is the compatible completed-turn receipt. LANTERN2 is phase/intent,
-- and LANTERN_CLEAR2 is capture cleanup. Neither pays yields directly.
local previous = MapModData.LANTERN_Controller
local generation = 2
if previous and previous.generation == generation and previous.active and previous.context == ContextPtr then return end
local function Retire(c)
  if not c then return end
  c.active = false
  for _, h in ipairs(c.handlers or {}) do
    if h.event.Remove then pcall(h.event.Remove, h.callback) end
  end
end
Retire(previous)
local T = GameInfoTypes or {}
local CIV, LIGHTHOUSE = T.CIVILIZATION_LANTERN_FLEET, T.BUILDING_LANTERN_SIGNAL_LIGHTHOUSE
local HARBOR, GOLD = T.BUILDING_LANTERN_GUARDED_HARBOR, T.BUILDING_LANTERN_SIGNAL_GOLD
if not (CIV and LIGHTHOUSE and HARBOR and GOLD) then
  print('LANTERN: missing database identities; controller disabled')
  return
end
local c = {active=true, generation=generation, context=ContextPtr, handlers={}, unsaved={}, busy={}, seen=previous and previous.seen or {}}
MapModData.LANTERN_Controller = c
local function Log(id, phase, message)
  print('LANTERN player='..tostring(id)..' turn='..tostring(Game.GetGameTurn())..
    ' phase='..phase..': '..tostring(message))
end
local function Rows(payload, full)
  local rows, seen = {}, {}
  if payload == '' then return rows end
  for text in (payload..';'):gmatch('(.-);') do
    local x,y,id,born,h,g,cancel
    if full then
      x,y,id,born,h,g,cancel = text:match('^(%d+),(%d+),(%d+),(%-?%d+),([01]),([01]),([01])$')
    else x,y,id,born = text:match('^(%d+),(%d+),(%d+),(%-?%d+)$') end
    assert(x, 'malformed city intent')
    local key = x..','..y
    assert(not seen[key], 'duplicate city intent '..key)
    seen[key] = true
    rows[#rows+1] = {x=tonumber(x),y=tonumber(y),id=tonumber(id),born=tonumber(born),
      h=tonumber(h) or 0,g=tonumber(g) or 0,cancel=tonumber(cancel) or 0}
    assert(rows[#rows].g <= rows[#rows].h, 'Gold intent without harbor')
  end
  return rows
end
local function Read(p)
  local raw = p:GetScriptData() or ''
  local s = {done=nil, settled=-1, turn=-1, mode='N', targets={}, clears={}}
  for version in raw:gmatch('%[LANTERN(%d+)|') do
    assert(version == '1' or version == '2', 'unsupported Lantern save version '..version)
  end
  for _, prefix in ipairs({'LANTERN1','LANTERN2','LANTERN_CLEAR2'}) do
    local _, count = raw:gsub('%['..prefix..'|', '')
    local payload = raw:match('%['..prefix..'|([^%]]*)%]')
    assert(count <= 1 and (count == 0 or payload), 'duplicate/truncated '..prefix)
    if payload then
      if prefix == 'LANTERN1' then
        assert(payload:match('^%-?%d+$'), 'malformed completed receipt')
        s.done = tonumber(payload)
      elseif prefix == 'LANTERN2' then
        local settled,turn,mode,targets = payload:match('^(%-?%d+)|(%-?%d+)|([NRS])|(.*)$')
        assert(settled, 'malformed phase receipt')
        s.settled,s.turn,s.mode = tonumber(settled),tonumber(turn),mode
        s.targets = Rows(targets,true)
        assert(mode == 'S' or #s.targets == 0, 'targets without frozen snapshot')
        assert((mode == 'N' and s.turn == -1) or (mode ~= 'N' and s.turn >= 0), 'invalid intent turn')
      else s.clears = Rows(payload,false) end
    end
  end
  local now = Game.GetGameTurn()
  assert((not s.done or s.done <= now) and s.settled <= now and s.turn <= now, 'future Lantern state')
  assert(s.mode == 'N' or not s.done or s.done < s.turn, 'pending intent already marked complete')
  return s
end
local function Encode(rows, full)
  local result = {}
  for _,r in ipairs(rows) do
    local fields = {r.x,r.y,r.id,r.born}
    if full then fields[5],fields[6],fields[7] = r.h,r.g,r.cancel end
    result[#result+1] = table.concat(fields, ',')
  end
  return table.concat(result, ';')
end
local function Save(p, id, s)
  -- Cache only unacknowledged intent, never authoritative yields. It lets the
  -- SAME context retry a failed ScriptData write without observing ships again.
  c.unsaved[id] = s
  local old = p:GetScriptData() or ''
  local new = old
  for _,prefix in ipairs({'LANTERN1','LANTERN2','LANTERN_CLEAR2'}) do
    new = new:gsub('%['..prefix..'|[^%]]*%]', '')
  end
  if s.done then new = new..'[LANTERN1|'..s.done..']' end
  if s.settled ~= -1 or s.mode ~= 'N' then
    new = new..'[LANTERN2|'..s.settled..'|'..s.turn..'|'..s.mode..'|'..Encode(s.targets,true)..']'
  end
  if #s.clears > 0 then new = new..'[LANTERN_CLEAR2|'..Encode(s.clears,false)..']' end
  local err
  for attempt=1,2 do
    if p:GetScriptData() == new then c.unsaved[id]=nil; return end
    local ok; ok,err = pcall(p.SetScriptData,p,new)
    if p:GetScriptData() == new then c.unsaved[id]=nil; return end
  end
  error('intent write not acknowledged: '..tostring(err))
end
local function State(p,id)
  return c.unsaved[id] or Read(p)
end
local function Identity(city,h,g)
  return {x=city:GetX(),y=city:GetY(),id=city:GetID(),born=city:GetGameTurnFounded(),h=h or 0,g=g or 0,cancel=0}
end
local function Resolve(id,r)
  local plot = Map.GetPlot(r.x,r.y)
  local city = plot and plot:GetPlotCity()
  if city and city:GetOwner() == id and city:GetID() == r.id and city:GetGameTurnFounded() == r.born then return city end
end
local function Set(city,b,n)
  assert(n == 0 or n == 1, 'non-binary dummy count')
  if city:GetNumRealBuilding(b) == n then return end
  local ok,err = pcall(city.SetNumRealBuilding,city,b,n)
  assert(city:GetNumRealBuilding(b) == n, 'city='..city:GetID()..' x='..city:GetX()..' y='..city:GetY()..
    ' building='..b..' target='..n..' write not acknowledged: '..tostring(err))
end
local function Qualifies(city,id)
  if city:GetOwner() ~= id or not city:IsCoastal(-1) then return false end
  local plot = city:Plot()
  if not plot then return false end
  for index=0,plot:GetNumUnits()-1 do
    local u = plot:GetUnit(index)
    if u and u:GetOwner() == id and not u:IsDead() and not u:IsDelayedDeath() and not u:IsEmbarked()
        and u:GetDomainType() == DomainTypes.DOMAIN_SEA and u:IsCombatUnit() then return true end
  end
  return false
end
local function RecoverClears(p,id)
  local s = State(p,id)
  if #s.clears == 0 then return end
  local complete = {}
  for _,r in ipairs(s.clears) do
    local city = Resolve(id,r)
    if city then Set(city,HARBOR,0) end
    city = Resolve(id,r)
    if city then Set(city,GOLD,0) end
    complete[table.concat({r.x,r.y,r.id,r.born},',')] = true
  end
  s = State(p,id)
  -- A nested capture may have appended another cleanup during a setter. Remove
  -- only identities actually processed, never erase an unacknowledged new intent.
  for i=#s.clears,1,-1 do
    local r=s.clears[i]
    if complete[table.concat({r.x,r.y,r.id,r.born},',')] then table.remove(s.clears,i) end
  end
  Save(p,id,s)
end
local function Recover(p,id)
  if c.unsaved[id] then Save(p,id,c.unsaved[id]) end
  local s = State(p,id)
  if p:GetCivilizationType() ~= CIV and (s.done or s.mode ~= 'N') then
    -- A scenario/debug civilization change must not revive a Lantern plan or
    -- retain its completed dummies. This is zero-only cleanup, not qualification.
    for city in p:Cities() do
      if city:GetNumRealBuilding(HARBOR)>0 or city:GetNumRealBuilding(GOLD)>0 then
        local r=Identity(city);local exists=false
        for _,old in ipairs(s.clears)do
          if old.x==r.x and old.y==r.y and old.id==r.id and old.born==r.born then exists=true end
        end
        if not exists then s.clears[#s.clears+1]=r end
      end
    end
    s.mode,s.turn,s.targets,s.settled='N',-1,{},Game.GetGameTurn()
    Save(p,id,s)
  end
  RecoverClears(p,id)
  s = State(p,id)
  if s.mode ~= 'S' then return end
  if s.turn ~= Game.GetGameTurn() then return end -- never restore an expired economy
  local turn, rows = s.turn, s.targets
  -- Re-read the saved cancellation bit before EACH setter: capture can publish
  -- synchronously from another listener. Never retain City userdata across it.
  for index=1,#rows do
    for _,b in ipairs({HARBOR,GOLD}) do
      s = State(p,id)
      assert(s.mode == 'S' and s.turn == turn, 'frozen intent changed during recovery')
      local r = s.targets[index]
      local city = Resolve(id,r)
      if city then Set(city,b,r.cancel == 1 and 0 or (b == HARBOR and r.h or r.g)) end
    end
  end
  s = State(p,id)
  for _,r in ipairs(s.targets) do
    local city = Resolve(id,r)
    if city then
      assert(city:GetNumRealBuilding(HARBOR) == (r.cancel == 1 and 0 or r.h) and
        city:GetNumRealBuilding(GOLD) == (r.cancel == 1 and 0 or r.g), 'frozen city verification failed')
    end
  end
  s.done,s.mode,s.turn,s.targets = turn,'N',-1,{}
  Save(p,id,s) -- commit only AFTER every applicable real count was acknowledged
end
local function Retry(id,label,work)
  for attempt=1,2 do
    local ok,err = pcall(work)
    if ok then return true end
    Log(id,label..' attempt='..attempt,err)
  end
  return false
end
local function Snapshot(id,allowCapture)
  local p = Players[id]
  if not p or not p:IsAlive() or not p:IsTurnActive() then return end
  local s = State(p,id)
  if c.unsaved[id] then Save(p,id,s) end
  RecoverClears(p,id)
  if p:GetCivilizationType() ~= CIV then Recover(p,id); return end
  local turn = Game.GetGameTurn()
  if s.mode == 'S' and s.turn == turn then Recover(p,id); return end
  if s.done == turn then return end
  if s.settled == turn then Log(id,'rejected start','native economy already observed; no late qualification'); return end
  if s.mode == 'R' and s.turn == turn then Log(id,'blocked start','boundary interrupted before a complete frozen plan; no position rescan'); return end
  if not allowCapture then Log(id,'blocked start','notification already attempted without a recoverable plan; no position rescan'); return end
  -- Reserve admission before any reads. If qualification itself fails, R is a
  -- truthful incomplete receipt, NEVER a completed turn or a license to rescan.
  s.mode,s.turn,s.targets = 'R',turn,{}
  Save(p,id,s)
  local targets = {}
  local ok,err = pcall(function()
    for city in p:Cities() do
      local guard = Qualifies(city,id)
      targets[#targets+1] = Identity(city,guard and 1 or 0,guard and city:GetNumBuilding(LIGHTHOUSE)>0 and 1 or 0)
    end
  end)
  assert(ok, 'qualification failed; reserved boundary retained: '..tostring(err))
  s.mode,s.targets = 'S',targets
  Save(p,id,s) -- all immutable targets durable BEFORE the first building setter
  Recover(p,id)
end
local function Hook(events,name,f)
  local e = events and events[name]
  if not (e and e.Add) then Log('-', 'registration', 'missing '..name); return false end
  local wrapped = function(...)
    if c.active and MapModData.LANTERN_Controller == c then f(...) end
  end
  e.Add(wrapped); c.handlers[#c.handlers+1] = {event=e,callback=wrapped}
  return true
end
-- The status notification is still a CANDIDATE. Publication in the DLL is not
-- proof of synchronous executable delivery for humans. No late payout fallback.
c.startHook = Hook(Events,'AIProcessingStartedForPlayer',function(id,tag)
  if tag ~= nil and tag ~= '' then return end
  if c.busy[id] then return end
  local p = Players[id]
  local eligible = p and p:IsAlive() and p:IsTurnActive() and p:GetCivilizationType() == CIV
  local turn = Game.GetGameTurn()
  local allowCapture = eligible and c.seen[id] ~= turn
  if eligible then c.seen[id] = turn end
  c.busy[id] = true
  Retry(id,'start/recover',function() Snapshot(id,allowCapture) end)
  c.busy[id] = nil
end)
-- SOURCE-VERIFIED late observer only: never scans ships or changes buildings.
-- Reject a status event arriving after this native economic boundary.
Hook(GameEvents,'PlayerDoTurn',function(id)
  local p = Players[id]
  if not p or p:GetCivilizationType() ~= CIV then return end
  Retry(id,'economy observer',function()
    local s = State(p,id); s.settled = Game.GetGameTurn(); Save(p,id,s)
    if s.done ~= s.settled then Log(id,'native acceptance','no completed early snapshot; timing/failure requires investigation') end
  end)
end)
Hook(GameEvents,'CityCaptureComplete',function(oldOwner,capital,x,y,newOwner)
  -- Capture is NOT dropped behind the snapshot's reentrancy guard.
  for _,id in ipairs(oldOwner == newOwner and {oldOwner} or {oldOwner,newOwner}) do
    local p = Players[id]
    if p then Retry(id,'capture invalidation x='..x..' y='..y,function()
      local s = State(p,id); local changed = false
      for _,r in ipairs(s.targets) do if r.x == x and r.y == y then r.cancel=1;changed=true end end
      if changed then Save(p,id,s) end
    end) end
  end
  local plot = Map.GetPlot(x,y)
  local city = plot and plot:GetPlotCity()
  if not city then return end
  local id = city:GetOwner(); local p = Players[id]
  -- Save a zero-only capture intent; it does NOT consume the recipient's turn.
  Retry(id,'capture intent',function()
    local s = State(p,id); local r = Identity(city)
    for i=#s.clears,1,-1 do if s.clears[i].x == x and s.clears[i].y == y then table.remove(s.clears,i) end end
    s.clears[#s.clears+1]=r; Save(p,id,s)
  end)
  -- Independently try BOTH clears even if intent persistence or one setter fails.
  for _,b in ipairs({HARBOR,GOLD}) do
    Retry(id,'capture clear building='..b,function()
      local current = Map.GetPlot(x,y):GetPlotCity()
      if current then Set(current,b,0) end
    end)
  end
  Retry(id,'capture cleanup receipt',function() RecoverClears(p,id) end)
end)

-- Firaxis LoadScreen.lua uses UI:IsLoadedGame() for Begin / Continue. The native
-- start-turn API distinguishes fresh initial/scenario starts from late installs.
-- Neither API proves the ordering of our candidate executable notification.
local fresh = false
if UI and UI.IsLoadedGame and Game.GetStartTurn then
  local ok,loaded = pcall(UI.IsLoadedGame,UI)
  fresh = ok and loaded == false and Game.GetGameTurn() == Game.GetStartTurn()
end
for id,p in pairs(Players) do
  if p and p:IsAlive() then
    local readable,raw = pcall(p.GetScriptData,p)
    if not readable then
      Log(id,'initialize read',raw)
      c.seen[id] = Game.GetGameTurn() -- no late rescan if the boundary cannot be identified
      raw = ''
    end
    raw = raw or ''
    if p:GetCivilizationType() == CIV or raw:find('[LANTERN',1,true) then
      Retry(id,'initialize/recover',function()
        local ok,s = pcall(Read,p)
        if not ok then
          -- Preserve damaged known blocks verbatim as quarantine. Future schema
          -- versions fail closed instead of being downgraded or overwritten.
          for version in raw:gmatch('%[LANTERN(%d+)|') do
            if version ~= '1' and version ~= '2' then error(s) end
          end
          Log(id,'quarantine',s)
          local repaired = raw:gsub('%[LANTERN([12])|','[LANTERN_QUARANTINE%1|')
            :gsub('%[LANTERN_CLEAR2|','[LANTERN_QUARANTINE_CLEAR2|')
          p:SetScriptData(repaired)
          s = Read(p)
          if p:IsTurnActive() then s.settled=Game.GetGameTurn() end
          Save(p,id,s)
        end
        if p:GetCivilizationType() == CIV and p:IsTurnActive() and (not fresh or not readable) and s.done ~= Game.GetGameTurn()
            and s.mode == 'N' then
          s.settled=Game.GetGameTurn(); Save(p,id,s)
        end
        Recover(p,id) -- saved targets ONLY; never calls Qualifies or awards stocks
      end)
    end
  end
end
if ContextPtr and ContextPtr.SetShutdown then
  ContextPtr:SetShutdown(function()
    Retire(c)
    if MapModData.LANTERN_Controller == c then MapModData.LANTERN_Controller=nil end
  end)
end
