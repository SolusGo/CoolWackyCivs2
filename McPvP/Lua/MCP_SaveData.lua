-- Save-bound player/unit ScriptData, preserving other mods' contents.
local M=MapModData.MCPVP
function M.Encode(v)
 local t=type(v)
 if t=='nil' then return 'z' elseif t=='boolean' then return v and 't' or 'f'
 elseif t=='number' then return 'n'..v..';' elseif t=='string' then return 's'..#v..':'..v end
 assert(t=='table','Unsupported McPvP state')
 local keys={};for k in pairs(v) do keys[#keys+1]=k end
 table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end return type(a)<type(b) end)
 local out={'m',#keys,':'}
 for _,k in ipairs(keys) do out[#out+1]=M.Encode(k);out[#out+1]=M.Encode(v[k]) end
 return table.concat(out)
end
function M.Decode(raw)
 local pos=1
 local function read(depth)
  assert(depth<32 and pos<=#raw,'Invalid McPvP state')
  local t=raw:sub(pos,pos);pos=pos+1
  if t=='z' then return nil elseif t=='t' then return true elseif t=='f' then return false end
  assert(t=='n' or t=='s' or t=='m')
  local last=assert(raw:find(t=='n' and ';' or ':',pos,true));local n=assert(tonumber(raw:sub(pos,last-1)));pos=last+1
  assert(n==n and math.abs(n)<1e14)
  if t=='n' then return n end
  assert(n>=0 and n==math.floor(n) and n<=#raw)
  if t=='s' then assert(pos+n<=#raw+1);local v=raw:sub(pos,pos+n-1);pos=pos+n;return v end
  local out={};for _=1,n do local k=read(depth+1);assert(type(k)=='string' or type(k)=='number');out[k]=read(depth+1) end
  return out
 end
 local result=read(0);assert(pos==#raw+1 and type(result)=='table');return result
end
function M.Block(data,tag)
 local a,b=(data or ''):find('|'..tag..':%d+:')
 if not a then return end
 local n=tonumber(data:sub(a,b):match(':(%d+):'));assert(data:sub(b+n+1,b+n+1)=='|','Corrupt McPvP envelope')
 return M.Decode(data:sub(b+1,b+n)),a,b+n+1
end
function M.Put(data,tag,value)
 data=data or '';local _,a,b=M.Block(data,tag)
 if a then data=data:sub(1,a-1)..data:sub(b+1) end
 if value then local raw=M.Encode(value);data=data..'|'..tag..':'..#raw..':'..raw..'|' end
 return data
end
function M.Save(s) Players[s.pid]:SetScriptData(M.Put(Players[s.pid]:GetScriptData(),'MCPSTATE1',s)) end
local function integer(v) return type(v)=='number' and v>=0 and v<1e14 and v==math.floor(v) end
local function mode(v) return v=='HG' or v=='CTF' or v=='SAB' end
local function cityRef(v)
 return type(v)=='table' and integer(v.x) and integer(v.y) and integer(v.owner) and type(v.key)=='string'
end
local function valid(s,pid)
 if s.version~=1 or s.pid~=pid or not mode(s.queued) then return false end
 for _,field in ipairs({'units','raids','sabotaged','debuffs','wins'}) do if type(s[field])~='table' then return false end end
 for _,field in ipairs({'nextSerial','current','lifetime','completed','cycle'}) do if not integer(s[field]) then return false end end
 if s.nextSerial<1 or s.current>s.lifetime or type(s.lastTurn)~='number' then return false end
 for _,name in ipairs(M.modes) do if not integer(s.wins[name]) then return false end end
 if s.mode then
  if not mode(s.mode) then return false end
  for _,field in ipairs({'start','finish','kills','killLegacy','nearLegacy','captures','missions','earned'}) do if not integer(s[field]) then return false end end
  if s.finish<=s.start then return false end
 end
 for serial,r in pairs(s.units) do
  if not integer(serial) or type(r)~='table' or r.serial~=serial then return false end
  for _,field in ipairs({'id','born','ready','changeReady'}) do if not integer(r[field]) then return false end end
  if r.flag and not cityRef(r.flag) then return false end
  if r.mission and (type(r.mission)~='table' or not cityRef(r.mission.target) or not integer(r.mission.started) or not integer(r.mission.finish)) then return false end
 end
 for _,d in pairs(s.debuffs) do if type(d)~='table' or not cityRef(d.target) or not integer(d.expires) then return false end end
 if s.feast and (type(s.feast)~='table' or not integer(s.feast.plot) or not integer(s.feast.active) or not integer(s.feast.expires) or type(s.feast.status)~='string') then return false end
 return true
end
function M.State(pid)
 if M.states[pid] then return M.states[pid] end
 local data=Players[pid]:GetScriptData() or '';local s=M.Block(data,'MCPSTATE1')
 if s then
  assert(valid(s,pid),'Incompatible/corrupt McPvP state; refusing overwrite')
 else
  assert(not data:find('|MCPSTATE',1,true),'Unsupported McPvP save version')
  s={version=1,pid=pid,nextSerial=1,units={},raids={},sabotaged={},debuffs={},current=0,lifetime=0,completed=0,wins={HG=0,CTF=0,SAB=0},queued='HG',lastTurn=-1,cycle=0}
 end
 M.states[pid]=s;return s
end
function M.Serial(u)
 local owner,serial=(u:GetScriptData() or ''):match('|MCPSID:(%d+):(%d+)|')
 if tonumber(owner)==u:GetOwner() then return tonumber(serial) end
end
function M.Tag(u,n)
 u:SetScriptData((u:GetScriptData() or ''):gsub('|MCPSID:%d+:%d+|','')..'|MCPSID:'..u:GetOwner()..':'..n..'|')
end
function M.Record(s,u)
 local n=M.Serial(u);local r=n and s.units[n]
 if r and (r.id~=u:GetID() or r.born~=u:GetGameTurnCreated()) then r=nil end
 if not r then
  n=s.nextSerial;s.nextSerial=n+1
  local transferred=(u:GetScriptData() or ''):find('|MCPTRANSFER|',1,true)~=nil
  r={serial=n,id=u:GetID(),born=u:GetGameTurnCreated(),ready=0,changeReady=0,veteran=u:GetUnitType()==M.VETERAN and not transferred}
  s.units[n]=r;M.Tag(u,n)
 end
 return r
end
function M.Peek(s,u)
 local n=u and M.Serial(u);local r=n and s.units[n]
 if r and r.id==u:GetID() and r.born==u:GetGameTurnCreated() then return r end
end
function M.Unit(s,r)
 local u=Players[s.pid]:GetUnitByID(r.id)
 if M.Alive(u) and M.Serial(u)==r.serial and u:GetGameTurnCreated()==r.born then return u end
end
function M.CityKey(city) return city:GetX()..':'..city:GetY()..':'..city:GetOriginalOwner()..':'..city:GetGameTurnFounded() end
function M.City(ref)
 local plot=Map.GetPlot(ref.x,ref.y);local city=plot and plot:GetPlotCity()
 if city and city:GetOwner()==ref.owner and M.CityKey(city)==ref.key and not city:IsRazing() then return city end
end
function M.CityRef(city) return {x=city:GetX(),y=city:GetY(),owner=city:GetOwner(),key=M.CityKey(city)} end
