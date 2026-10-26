-- Native player/plot/unit ScriptData is serialized inside each game save.
-- Numeric, versioned blocks; foreign script data is retained verbatim.
local T=MapModData.ThresholdCourt
local MAX=2147483647
function T.Log(key,detail) print('[ThresholdCourt] '..key..': '..tostring(detail or '')) end
function T.Warn(key,detail)
 if not T.warnings[key] then T.warnings[key]=true;T.Log(key,detail) end
end
local function Pattern(tag) return '%['..tag..':([^%]]*)%]' end
function T.Read(object,tag,count)
 local ok,raw=pcall(function() return object:GetScriptData() or '' end)
 if not ok then T.Warn('persistence read',raw);return nil,false end
 local pattern=Pattern(tag);local body=raw:match(pattern)
 local _,copies=raw:gsub(pattern,'')
 if copies>1 or (not body and raw:find('['..tag:sub(1,-2),1,true)) then
  T.Warn('persistence invalid',tag);return nil,false
 end
 if not body then return nil,true end
 local values={}
 for part in (body..':'):gmatch('([^:]*):') do
  local n=part:match('^%d+$') and tonumber(part)
  if not n or n>MAX then T.Warn('persistence invalid',tag);return nil,false end
  values[#values+1]=n
 end
 if #values~=count then T.Warn('persistence invalid',tag);return nil,false end
 return values,true
end
function T.Write(object,tag,values)
 local ok,err=pcall(function()
  local raw=object:GetScriptData() or '';local replacement=''
  if values then
   local out={}
   for i,n in ipairs(values) do
    assert(type(n)=='number' and n>=0 and n<=MAX and n==math.floor(n),'invalid saved integer')
    out[i]=string.format('%.0f',n)
   end
   replacement='['..tag..':'..table.concat(out,':')..']'
  end
  local nextData=raw:gsub(Pattern(tag),'')..replacement
  if raw~=nextData then object:SetScriptData(nextData) end
  assert(object:GetScriptData()==nextData,'ScriptData write did not persist')
 end)
 if not ok then T.Warn('persistence write '..tag,err) end
 return ok
end
-- last-success+1, last owner-turn start, and a recoverable relocation receipt.
-- phase, id, birth, origin XY, destination XY, origin epoch, transfer turn,
-- cost, treasury before charge, type, old moves, old origin ready deadline.
function T.State(pid)
 local p=Players[pid];if not p then return end
 local v,ok=T.Read(p,'THC_P1',16);if not ok then return end
 if not v then v={0,T.Turn(),0,0,0,0,0,0,0,0,0,0,0,0,0,0} end
 if v[3]>2 then T.Warn('persistence invalid','receipt phase');return end
 return v
end
function T.Save(pid,s) return T.Write(Players[pid],'THC_P1',s) end
function T.ClearReceipt(pid,s)
 for i=3,16 do s[i]=0 end
 return T.Save(pid,s)
end
local function CityFields(c)
 return {c:GetOwner(),c:GetID(),c:GetGameTurnFounded(),c:GetOriginalOwner()}
end
function T.CityState(c,reset)
 if not c then return end
 local plot=c:Plot();if not plot then return end
 local v,ok=T.Read(plot,'THC_C1',6);if not ok then return end
 local f=CityFields(c)
 local matches=v and v[2]==f[1] and v[3]==f[2] and v[4]==f[3] and v[5]==f[4]
 if not matches or reset then
  v={(v and v[1] or 0)+1,f[1],f[2],f[3],f[4],0}
  if not T.Write(plot,'THC_C1',v) then return end
 end
 return v
end
function T.CityToken(c)
 local v=T.CityState(c)
 if not v then return end
 return c:GetX()..':'..c:GetY()..':'..table.concat(v,':',1,5)
end
function T.UnitToken(u)
 if not T.Alive(u) then return end
 return u:GetOwner()..':'..u:GetID()..':'..u:GetGameTurnCreated()..':'..u:GetUnitType()
end
function T.Stamp(u)
 return T.Read(u,'THC_U1',4)
end
function T.Locked(u)
 local v,ok=T.Stamp(u)
 if not ok then return true end
 if not v then return u:IsHasPromotion(T.EXHAUSTED) end
 local s=T.State(v[1])
 -- The originating player's next owner-turn releases even gifted units.
 return not s or s[2]<=v[2]
end
