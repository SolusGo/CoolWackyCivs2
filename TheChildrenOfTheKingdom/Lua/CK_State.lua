-- Small, versioned numeric block in native saved player ScriptData. No executable deserialization.
local K=MapModData.CKPrayer
local fields={'stage','grace','ready','address','seek','repent','protection','clock','bread'}
local pattern='|CKPRAYER1:([^|]*)|'
local function integer(n) return type(n)=='number' and n==math.floor(n) and n>=0 and n<100000000 end
function K.Save(s)
 local out={};for _,key in ipairs(fields) do assert(integer(s[key]));out[#out+1]=tostring(s[key]) end
 local p=Players[s.pid];local raw=p:GetScriptData() or ''
 p:SetScriptData(raw:gsub(pattern,'')..'|CKPRAYER1:'..table.concat(out,',')..'|')
end
function K.State(pid)
 if K.states[pid] then return K.states[pid] end
 if K.failed[pid] then return end
 local p=Players[pid];if not p then return end
 local raw=p:GetScriptData() or '';local block=raw:match(pattern);local s={pid=pid}
 local ok=true
 if block then
  local values={};for n in (block..','):gmatch('(.-),') do values[#values+1]=tonumber(n) or false end
  ok=#values==#fields
  for i,key in ipairs(fields) do s[key]=values[i];ok=ok and integer(s[key]) end
  ok=ok and s.stage>=1 and s.stage<=7 and s.grace<=7
 elseif raw:find('|CKPRAYER',1,true) then ok=false
 else
  for _,key in ipairs(fields) do s[key]=0 end;s.stage=1;s.clock=K.Turn()
 end
 if not ok then
  K.failed[pid]=true;print('[Kingdom] Unsupported or corrupt prayer state for player '..pid..'; preserving ScriptData and disabling effects.');return
 end
 K.states[pid]=s;return s
end
function K.Active(s,key) return s and s[key]>s.clock end
