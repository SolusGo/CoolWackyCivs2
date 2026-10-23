-- Narrative-only sidecar. The 82-number THE11CATS1 gameplay format is unchanged.
local H=MapModData.THE11CATS
H.BondOrder={'FIRST_PAIR','BONNIE_FAMILY','SISTERS_BED','MOTHER_DAUGHTER'}
H.BondCats={FIRST_PAIR={'LUNA'},BONNIE_FAMILY={'BONNIE','APPA','LOKI','KURO','OSCAR','BOOMIE'},SISTERS_BED={'APPA','LOKI','OSCAR'},MOTHER_DAUGHTER={'CHARLOTTE','SISI'}}
function H.CityKey(city)
 return table.concat({city:GetX(),city:GetY(),city:GetGameTurnFounded(),city:GetOriginalOwner()},',')
end
local noticePattern='|THE11CATS_N1:([^|]*)|'
function H.Notices(s)
 if s.notices then return s.notices end
 local raw=Players[s.pid]:GetScriptData() or '';local block=raw:match(noticePattern)
 local n={enabled=true,seen={},valid=true,dirty=false};s.notices=n
 if block then
  local setting,entries=block:match('^([01]);(.*)$')
  if not setting then n.valid=false else
   n.enabled=setting=='1'
   for entry in entries:gmatch('[^;]+') do
    local x,y,turn,owner,bits=entry:match('^(%d+),(%d+),(%d+),(%d+),(%d+)$')
    if not bits or tonumber(bits)>15 then n.valid=false;break end
    n.seen[table.concat({x,y,turn,owner},',')]=tonumber(bits)
   end
  end
 elseif raw:find('|THE11CATS_N%d+:') then n.valid=false end
 if not n.valid then H.Log('Unsupported/invalid presentation sidecar preserved; narrative feedback disabled.',true) end
 return n
end
function H.SaveNotices(s)
 local n=H.Notices(s);if not n.valid then return end
 local keys={};for key in pairs(n.seen) do keys[#keys+1]=key end;table.sort(keys)
 local entries={};for _,key in ipairs(keys) do entries[#entries+1]=key..','..n.seen[key] end
 local block=(n.enabled and '1' or '0')..';'..table.concat(entries,';')
 local ok,err=pcall(function()
  local p=Players[s.pid];local raw=p:GetScriptData() or ''
  if raw:match(noticePattern)~=block then p:SetScriptData(raw:gsub(noticePattern,'')..'|THE11CATS_N1:'..block..'|') end
 end)
 if not ok then
  local verified,value=pcall(function() return (Players[s.pid]:GetScriptData() or ''):match(noticePattern)==block end)
  if verified and value then ok=true end
 end
 n.dirty=not ok
 if not ok then H.Log('Narrative state save deferred: '..tostring(err),true);H.Request(s.pid,false) end
 return ok
end
function H.Feedback(s,message)
 local n=H.Notices(s);if H.ready and n.valid and n.enabled then H.Notify(s.pid,message) end
end
function H.NoteBonds(s,city,expected)
 if not s then return end
 local n=H.Notices(s);if not n.valid then return end
 local key=H.CityKey(city);local bits=n.seen[key] or 0;local messages={}
 for i,id in ipairs(H.BondOrder) do local bit=2^(i-1)
  if expected[id] and math.floor(bits/bit)%2==0 then
   bits=bits+bit;messages[#messages+1]=H.Text('BOND_WELCOME',H.Text('BOND_NAME_'..id),city:GetName())
  end
 end
 if #messages>0 then
  n.seen[key]=bits;local saved=H.SaveNotices(s)
  -- Initial load silently baselines existing bonds, including pre-sidecar saves.
  if saved then for _,message in ipairs(messages) do H.Feedback(s,message) end end
 end
end
function H.ToggleFeedback(s)
 local n=H.Notices(s);if not n.valid then return false end
 n.enabled=not n.enabled;H.SaveNotices(s);H.Changed(s.pid);return n.enabled
end
function H.BondReport(s,id,preferred)
 local p=Players[s.pid];local hosts={};local target=preferred
 for city in p:Cities() do if H.Bonds(s,city)[id] then hosts[#hosts+1]=city:GetName();target=city end end
 if id=='FIRST_PAIR' then target=p:GetCapitalCity()
 elseif not target then
  local best=-1
  for city in p:Cities() do if not city:IsRazing() then
   local score=0
   for index,catID in ipairs(H.BondCats[id]) do
    local c=s.cats[catID]
    if c.status==2 and H.City(c)==city then score=score+(id=='BONNIE_FAMILY' and index==1 and 10 or 1) end
   end
   if score>best or (score==best and (city==p:GetCapitalCity() or (target~=p:GetCapitalCity() and city:GetID()<target:GetID()))) then target=city;best=score end
  end end
 end
 local lines,missing={},{};local kittenHere=false
 for index,catID in ipairs(H.BondCats[id]) do
  local c=s.cats[catID];local city=c.status==2 and H.City(c)
  local here=city and city==target and city:GetOwner()==s.pid and not city:IsRazing()
  local state
  if here then state=H.Text('SETTLED_HERE')
  elseif city and city:GetOwner()==s.pid then state=H.Text('OTHER_HOME',city:GetName())
  else state=H.Text(({[0]='NOT_JOINED',[1]='TRAVELLING',[2]='RESIDENT',[3]='RECOVERING'})[c.status]) end
  lines[#lines+1]=H.Text(catID..'_NAME')..': '..state
  if id=='BONNIE_FAMILY' and index>1 then kittenHere=kittenHere or here
  elseif not here then missing[#missing+1]=H.Text(catID..'_NAME') end
 end
 if id=='BONNIE_FAMILY' and not kittenHere then missing[#missing+1]=H.Text('ONE_KITTEN') end
 local active=#hosts>0
 return {active=active,hosts=hosts,target=target,requirements=table.concat(lines,'[NEWLINE]'),
  status=active and H.Text('BOND_ACTIVE',table.concat(hosts,', ')) or H.Text('BOND_MISSING',table.concat(missing,', ')),
  effect=H.Text('BOND_'..id),name=H.Text('BOND_NAME_'..id)}
end
