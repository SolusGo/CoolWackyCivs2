-- Player ScriptData travels with the native save, including when loading an older save.
-- OpenSaveData is a redundant mirror, never the authority for restoring native yield ledgers.
local B=MapModData.BoundlessCity
local mirrorOK,mirror=pcall(Modding.OpenSaveData)
local mirrorError=not mirrorOK and tostring(mirror) or 'no optional save store'
if not mirrorOK then mirror=nil end
local mirrorWarned=false
local function encode(v)
 local t=type(v)
 if t=='number' then return 'n'..tostring(v)..';'
 elseif t=='string' then return 's'..#v..':'..v
 elseif t=='boolean' then return v and 't' or 'f'
 elseif t=='nil' then return 'z' end
 assert(t=='table','Unsupported Boundless save value')
 local keys={};for k in pairs(v) do keys[#keys+1]=k end
 table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end;return type(a)<type(b) end)
 local out={'m',tostring(#keys),':'}
 for _,k in ipairs(keys) do out[#out+1]=encode(k);out[#out+1]=encode(v[k]) end
 return table.concat(out)
end
local function decode(raw)
 local pos=1
 local function read(depth)
  assert(depth<24 and pos<=#raw,'Invalid Boundless snapshot')
  local t=raw:sub(pos,pos);pos=pos+1
  if t=='z' then return nil elseif t=='t' then return true elseif t=='f' then return false end
  assert(t=='n' or t=='s' or t=='m')
  local finish=assert(raw:find(t=='n' and ';' or ':',pos,true))
  local n=assert(tonumber(raw:sub(pos,finish-1)));pos=finish+1
  assert(n==n and math.abs(n)<1e14)
  if t=='n' then return n end
  assert(n>=0 and n==math.floor(n) and n<=#raw)
  if t=='s' then assert(pos+n-1<=#raw);local s=raw:sub(pos,pos+n-1);pos=pos+n;return s end
  local out={};for _=1,n do local k=read(depth+1);assert(type(k)=='string' or type(k)=='number');out[k]=read(depth+1) end
  return out
 end
 local value=read(0);assert(pos==#raw+1 and type(value)=='table');return value
end
function B.Save(s)
 if s.incompatible then return false end -- Preserve newer/corrupt native payloads for recovery.
 local p=Players[s.pid];local data=p:GetScriptData() or ''
 local raw=encode(s)
 local first,last=data:find('|BCSTATE1:%d+:')
 if first then
  local length=tonumber(data:sub(first,last):match(':(%d+):'))
  data=data:sub(1,first-1)..data:sub(last+length+2)
 end
 p:SetScriptData(data..'|BCSTATE1:'..#raw..':'..raw..'|')
 local ok,err=false,mirrorError
 if mirror then ok,err=pcall(function() mirror.SetValue('BOUNDLESS_v1_P'..s.pid,raw) end) end
 if not ok and not mirrorWarned then
  mirrorWarned=true;print('[BoundlessCity] Optional save mirror unavailable; native ScriptData saved: '..tostring(err))
 end
 return true
end
function B.State(pid)
 if B.States[pid] then return B.States[pid] end
 local data=Players[pid]:GetScriptData() or ''
 local first,last=data:find('|BCSTATE1:%d+:');local s
 if first then
  local length=tonumber(data:sub(first,last):match(':(%d+):'))
  local ok,value=pcall(decode,data:sub(last+1,last+length))
  if ok then
   for _,name in ipairs({'locks','assignments','rewards','selected','excluded','pending','returned','history','sieges','aiTargets'}) do
    if value[name]~=nil and type(value[name])~='table' then ok=false end
   end
   for _,name in ipairs({'reserved','withdrawn','lastTurn'}) do
    if value[name]~=nil and (type(value[name])~='number' or value[name]~=math.floor(value[name])) then ok=false end
   end
   ok=ok and data:sub(last+length+1,last+length+1)=='|'
  end
  if ok and (value.version==1 or value.version==2) and value.pid==pid and type(value.assignments)=='table'
   and type(value.locks)=='table' and type(value.rewards)=='table' and type(value.progress)=='number' and value.progress>=0
   and (value.capital==nil or (type(value.capital)=='table' and type(value.capital.x)=='number'
    and type(value.capital.y)=='number' and type(value.capital.founded)=='number'
    and Map.GetPlot(value.capital.x,value.capital.y))) then s=value
  else s={pid=pid,incompatible=true,pending={},returned={},sieges={},assignments={}};print('[BoundlessCity] Invalid snapshot for '..pid) end
 elseif data:find('|BCSTATE',1,true) then
  s={pid=pid,incompatible=true,pending={},returned={},sieges={},assignments={}}
  print('[BoundlessCity] Malformed snapshot envelope for '..pid)
 else
  s={pid=pid,version=2,progress=0,mode='AUTO',priority='BALANCED',direction='ANY',
   assignments={},locks={},selected={},excluded={},rewards={},reserved=0,withdrawn=0,lastTurn=-1,pending={},history={},sieges={},phase='IDLE'}
 end
 if not s.incompatible then
  if s.version==1 then
   s.selected={};for n,v in pairs(s.locks) do if v then s.selected[n]=true end end
   s.withdrawn=s.reserved or 0;s.version=2;s.phase='RECOVER'
  end
  s.selected=s.selected or {};s.withdrawn=math.max(0,tonumber(s.withdrawn) or 0)
  s.sieges=s.sieges or {};s.returned=s.returned or {};s.aiTargets=s.aiTargets or {};s.history=s.history or {};s.phase=s.phase or 'RECOVER'
  s.lastTurn=s.lastTurn or -1
  s.excluded=s.excluded or {};s.pending=s.pending or {};s.reserved=math.max(0,tonumber(s.reserved) or 0)
  if not B.Weights[s.priority] then s.priority='BALANCED' end
  if s.mode~='AUTO' and s.mode~='HYBRID' and s.mode~='MANUAL' then s.mode='AUTO' end
  if not ({ANY=true,NORTH=true,EAST=true,SOUTH=true,WEST=true})[s.direction] then s.direction='ANY' end
  for _,tableName in ipairs({'locks','selected','excluded','assignments','rewards','sieges'}) do
   for n in pairs(s[tableName]) do
    if type(n)~='number' or n<0 or n>=Map.GetNumPlots() or n~=math.floor(n) then s[tableName][n]=nil end
   end
  end
  for _,name in ipairs({'locks','selected','excluded','rewards'}) do
   for n,v in pairs(s[name]) do if v~=true then s[name][n]=nil end end
  end
  for n,r in pairs(s.assignments) do local p=Map.GetPlotByIndex(n)
   if type(r)~='table' or not p or r.x~=p:GetX() or r.y~=p:GetY() then s.assignments[n]=nil end
  end
  for _,name in ipairs({'pending','returned','sieges','aiTargets'}) do
   for k,r in pairs(s[name]) do
    local valid=type(k)=='number' and k>=0 and k==math.floor(k) and type(r)=='table'
    if valid and name=='returned' then
     valid=type(r.founded)=='number' and type(r.recipient)=='number'
      and (r.turn==nil or (type(r.turn)=='number' and r.turn==math.floor(r.turn)))
    elseif valid then
     valid=type(r.x)=='number' and type(r.y)=='number' and Map.GetPlot(r.x,r.y)~=nil
     if name=='aiTargets' then valid=valid and type(r.birth)=='number' and type(r.build)=='number'
     else valid=valid and type(r.founded)=='number' end
     if name=='sieges' then valid=valid and type(r.owner)=='number'
      and (r.city==nil or (type(r.city)=='number' and r.city>=0 and r.city==math.floor(r.city))) end
    end
    if not valid then s[name][k]=nil end
   end
  end
 end
 B.States[pid]=s;return s
end
B.Encode,B.Decode=encode,decode
