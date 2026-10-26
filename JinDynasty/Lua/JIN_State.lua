-- Save-serialized object data only. No Modding.OpenSaveData and no executable deserialization.
JINState = {}
local S=JINState
local function weakKeys()return setmetatable({},{__mode='k'})end
local reads,writes=weakKeys(),weakKeys()
function S.ResetCache() reads=weakKeys();writes=weakKeys() end
function S.Copy(v)
 if type(v)~='table' then return v end
 local out={};for k,x in pairs(v) do out[k]=S.Copy(x) end;return out
end
local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local function encode(v)
 local t=type(v)
 if t=='number' then assert(v==math.floor(v) and math.abs(v)<9007199254740991);return 'n'..string.format('%.0f',v)..';' end
 if t=='boolean' then return v and 'b1' or 'b0' end
 if t=='string' then return 's'..#v..':'..v end
 assert(t=='table','unsupported Jin state type')
 local keys={};for k in pairs(v) do keys[#keys+1]=k end
 table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end return type(a)<type(b) end)
 local out={'t'..#keys..':'}
 for _,k in ipairs(keys) do out[#out+1]=encode(k);out[#out+1]=encode(v[k]) end
 return table.concat(out)
end
function S.Encode(v)
 return (encode(v):gsub('.',function(c)return string.format('%02x',string.byte(c)) end))
end
function S.Decode(hex)
 if type(hex)~='string' or #hex>400000 or #hex%2~=0 or hex:find('[^0-9a-f]') then return nil end
 local raw=hex:gsub('..',function(c)return string.char(tonumber(c,16))end);local at=1;local nodes=0
 local function number(delim)
  local stop=raw:find(delim,at,true);assert(stop)
  local word=raw:sub(at,stop-1);assert(word:match('^-?%d+$'))
  at=stop+1;local n=tonumber(word);assert(n and math.abs(n)<9007199254740991);return n
 end
 local read
 read=function(depth)
  nodes=nodes+1;assert(depth<16 and nodes<20000)
  local kind=raw:sub(at,at);at=at+1
  if kind=='n' then return number(';') end
  if kind=='b' then local b=raw:sub(at,at);at=at+1;assert(b=='0' or b=='1');return b=='1' end
  if kind=='s' then local n=number(':');assert(n>=0 and at+n-1<=#raw);local s=raw:sub(at,at+n-1);at=at+n;return s end
  assert(kind=='t');local count=number(':');assert(count>=0 and count<=5000)
  local v={}
  for _=1,count do local k=read(depth+1);assert(type(k)=='number' or type(k)=='string');assert(v[k]==nil);v[k]=read(depth+1) end
  return v
 end
 local ok,v=pcall(read,0)
 if ok and at==#raw+1 then return v end
end
function S.Read(object,tag)
 local raw=object:GetScriptData() or '';local pattern='%['..tag..':([^%]]*)%]'
 local cache=reads[object] and reads[object][tag]
 if cache and cache.raw==raw then return S.Copy(cache.value),cache.error end
 local _,count=raw:gsub(pattern,'');if count>1 then return nil,'duplicate state' end
 local data=raw:match(pattern)
 if not data then return nil end
 local value=S.Decode(data);local err=not value and 'invalid encoding' or nil
 reads[object]=reads[object] or {};reads[object][tag]={raw=raw,value=S.Copy(value),error=err}
 return value,err
end
function S.Write(object,tag,value)
 local raw=object:GetScriptData() or '';local cache=writes[object] and writes[object][tag]
 if cache and cache.raw==raw and equal(value,cache.value) then return false end
 local nextData=raw:gsub('%['..tag..':[^%]]*%]','')
 if value then nextData=nextData..'['..tag..':'..S.Encode(value)..']' end
 if raw~=nextData then object:SetScriptData(nextData) end
 assert(object:GetScriptData()==nextData,'Jin serialized write did not persist')
 writes[object]=writes[object] or {};writes[object][tag]={raw=nextData,value=S.Copy(value)}
 reads[object]=nil
 return raw~=nextData
end
function S.New()
 return {version=1,serial=0,turn=-1,started=false,choices={},landmarks={},pending={},grass={},
  trib={},upgrades={},defenders={},forts={},defense={},groves={},slowed={},deaths={},rebels={},
  emissaryCooldown={},karma=0,blessing=0,garden=-1,gardenReady=0,groveReady=0,freeEmissary=false}
end
local function integer(v,min,max) return type(v)=='number' and v==math.floor(v) and v>=min and v<=(max or 9007199254740990) end
local function city(r) return type(r)=='table' and integer(r.plot,0) and integer(r.founded,0) end
function S.Validate(s)
 if type(s)~='table' or s.version~=1 then return false,'unknown version or non-table record' end
 for _,k in ipairs({'choices','landmarks','pending','grass','trib','upgrades','defenders','forts','defense','groves','slowed','deaths','rebels','emissaryCooldown'}) do if type(s[k])~='table' then return false,'invalid '..k end end
 for _,k in ipairs({'serial','karma','blessing','gardenReady','groveReady'}) do if not integer(s[k],0) then return false,'invalid '..k end end
 if not integer(s.turn,-1) or not integer(s.garden,-1) or type(s.started)~='boolean' or type(s.freeEmissary)~='boolean' or s.karma>JINConfig.karmaMax then return false,'invalid counters' end
 local landmarks={};for _,l in ipairs(JINConfig.landmarks) do landmarks[l.key]=l.tier end
 for tier,key in pairs(s.choices) do if not integer(tier,1,3) or landmarks[key]~=tier then return false,'invalid choice' end end
 for key,r in pairs(s.landmarks) do if not landmarks[key] or not city(r) or s.choices[landmarks[key]]~=key then return false,'invalid landmark' end end
 for tier,r in pairs(s.pending) do
  if not integer(tier,1,3) or not city(r) or type(r.sites)~='table' or #r.sites>3 then return false,'invalid candidate offer' end
  for _,index in ipairs(r.sites) do if not integer(index,0) then return false,'invalid candidate plot' end end
 end
 for key,g in pairs(s.grass) do
  if (key~='pasture' and not integer(key,1,3)) or type(g)~='table' or not integer(g.plot,0) or not integer(g.horses,0,JINConfig.horseCapacity) or not integer(g.elapsed,0) or (key=='pasture' and not city(g)) then return false,'invalid Horse inventory' end
 end
 for id,r in pairs(s.trib) do if not integer(id,0) or not city(r) then return false,'invalid Tributary' end end
 for index,r in pairs(s.groves) do if not integer(index,0) or not city(r) then return false,'invalid Grove' end end
 for uid,r in pairs(s.defenders) do
  if not integer(uid,0) or type(r)~='table' or not integer(r.plot,0) or not integer(r.born,0) or not integer(r.expires,0) or type(r.parent)~='string' or (r.founded~=nil and not integer(r.founded,0)) or (r.acted~=nil and not integer(r.acted,-1)) then return false,'invalid defender' end
 end
 for uid,r in pairs(s.rebels) do if not integer(uid,0) or type(r)~='table' or not integer(r.born,0) or not integer(r.expires,0) then return false,'invalid rebel' end end
 for uid,r in pairs(s.emissaryCooldown) do if not integer(uid,0) or type(r)~='table' or not integer(r.born,0) or not integer(r.ready,0) then return false,'invalid Emissary cooldown' end end
 for key,r in pairs(s.defense) do if type(key)~='string' or type(r)~='table' or not integer(r.ready,0) or not integer(r.shot,-1) then return false,'invalid emplacement' end end
 for _,name in ipairs({'slowed','deaths','combats'}) do
  if s[name]~=nil and type(s[name])~='table' then return false,'invalid event ledger' end
  for key,v in pairs(s[name] or {}) do if type(key)~='string' or not integer(v,0) then return false,'invalid event ledger' end end
 end
 local upgrades={};for _,up in ipairs(JINConfig.upgrades) do upgrades[up.key]=true end
 for key,v in pairs(s.upgrades) do if not upgrades[key] or v~=true then return false,'invalid upgrade' end end
 for index,v in pairs(s.forts) do if not integer(index,0) or v~=true then return false,'invalid fort' end end
 local tx=s.transaction
 if tx~=nil then
  if type(tx)~='table' or not integer(tx.token,0) or not integer(tx.turn,0) or not integer(tx.paid,0) then return false,'invalid transaction' end
  if tx.intent and (type(tx.intent)~='table' or not integer(tx.intent.gold,-9007199254740990) or not integer(tx.intent.delta,-9007199254740990) or not integer(tx.intent.total,0)) then return false,'invalid payment intent' end
  if tx.kind=='recruit' then
   if not integer(tx.unitType,0) or not integer(tx.plot,0) or not integer(tx.sourcePlot,0) or not integer(tx.cost,1) or type(tx.before)~='table' or (tx.source~='pasture' and not integer(tx.source,1,3)) then return false,'invalid recruit receipt' end
   if (tx.unit~=nil and not integer(tx.unit,0)) or (tx.born~=nil and not integer(tx.born,0)) or (tx.horse~=nil and type(tx.horse)~='boolean') then return false,'invalid recruit identity' end
   for uid,v in pairs(tx.before)do if not integer(uid,0) or v~=true then return false,'invalid recruit snapshot' end end
  elseif tx.kind=='bribe' then
   if not integer(tx.emissary,0) or not integer(tx.emissaryBorn,0) or not integer(tx.ready,0) or type(tx.targets)~='table' or #tx.targets>JINConfig.bribeTargets then return false,'invalid Bribe receipt' end
   for _,r in ipairs(tx.targets) do
    if type(r)~='table' then return false,'invalid Bribe target' end
    for _,field in ipairs({'owner','uid','born','base','plot','cost'}) do if not integer(r[field],0) then return false,'invalid Bribe target '..field end end
    for _,field in ipairs({'clone','cloneBorn','spawn','expires'})do if r[field]~=nil and not integer(r[field],0)then return false,'invalid Bribe replacement '..field end end
    if r.converted~=nil and type(r.converted)~='boolean' then return false,'invalid conversion state' end
    if r.converted and not integer(r.expires,0) then return false,'invalid rebel expiry' end
   end
  else return false,'unknown transaction kind' end
 end
 return true
end
function S.Player(p)
 local s,err=S.Read(p,'JIN_P1')
 if not s then
  if err or (p:GetScriptData() or ''):find('[JIN_P',1,true) then return nil,err or 'unknown Jin tag' end
  s=S.New();S.Write(p,'JIN_P1',s)
 end
 local valid,reason=S.Validate(s);if not valid then return nil,reason end
 return s
end
