-- Save-serialized object data only. No Modding.OpenSaveData and no executable deserialization.
JINState = {}
local S=JINState
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
 local _,count=raw:gsub(pattern,'');if count>1 then return nil,'duplicate state' end
 local data=raw:match(pattern)
 if not data then return nil end
 return S.Decode(data),'invalid state'
end
function S.Write(object,tag,value)
 local raw=object:GetScriptData() or '';local nextData=raw:gsub('%['..tag..':[^%]]*%]','')
 if value then nextData=nextData..'['..tag..':'..S.Encode(value)..']' end
 if raw~=nextData then object:SetScriptData(nextData) end
end
function S.New()
 return {version=1,serial=0,turn=-1,started=false,choices={},landmarks={},pending={},grass={},
  trib={},upgrades={},defenders={},forts={},defense={},groves={},slowed={},deaths={},rebels={},
  emissaryCooldown={},karma=0,blessing=0,garden=-1,gardenReady=0,groveReady=0,freeEmissary=false}
end
function S.Player(p)
 local s,err=S.Read(p,'JIN_P1')
 if not s then
  if err or (p:GetScriptData() or ''):find('[JIN_P',1,true) then return nil end
  s=S.New();S.Write(p,'JIN_P1',s)
 end
 if s.version~=1 or type(s.serial)~='number' or type(s.karma)~='number' then return nil end
 for _,k in ipairs({'choices','landmarks','pending','grass','trib','upgrades','defenders','forts','defense','groves','slowed','deaths','rebels','emissaryCooldown'}) do if type(s[k])~='table' then return nil end end
 return s
end
