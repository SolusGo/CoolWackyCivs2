-- Derived indexes only; the native serialized state remains authoritative.
local J=MapModData.JIN
J.runtime={};J.hp={};J.jobs={};J.rejected={};J.invalidPending={}
function J.InvalidateSpatial(id) if id then J.runtime[id]=nil else J.runtime={} end end
function J.Spatial(id,s)
 local cached=J.runtime[id]
 if cached then return cached end
 s=s or J.State(id);if not s then return nil end
 local r={parents=J.Emplacements(id,s),threat={},grove={}};J.runtime[id]=r
 local keys={};for key in pairs(r.parents) do keys[#keys+1]=key end;table.sort(keys)
 for _,key in ipairs(keys) do for _,p in ipairs(J.Near(J.Plot(r.parents[key].plot),J.C.defenseRadius)) do
  local index=J.Index(p);r.threat[index]=r.threat[index]or {};r.threat[index][#r.threat[index]+1]=key
 end end
 for index in pairs(s.groves) do local p=J.Plot(index)
  if p and p:GetOwner()==id and p:GetImprovementType()==J.T.IMPROVEMENT_JIN_GROVE and not p:IsImprovementPillaged() then
   for _,near in ipairs(J.Near(p,J.C.groveSlowRadius)) do r.grove[J.Index(near)]=true end
  end
 end
 return r
end
-- One deferred callback removes itself BEFORE any native mission. No idle polling.
function J.Defer(key,fn)
 J.jobs[key]=fn
 if J.armed or not J.context.SetUpdate then return end
 J.armed=true
 J.context:SetUpdate(function()
  J.context:ClearUpdate();J.armed=false
  local pending=J.jobs;J.jobs={};local keys={};for k in pairs(pending) do keys[#keys+1]=k end;table.sort(keys)
  for _,k in ipairs(keys) do if J.active then local ok,err=pcall(pending[k]);if not ok then print('JIN deferred '..k..': '..tostring(err)) end end end
 end)
end
function J.ClearInvalid(id,reason)
 local p=Players[id];local raw=p:GetScriptData() or ''
 if J.rejected[id]==raw and not J.invalidPending[id] then return end
 if J.rejected[id]~=raw then print('JIN invalid saved state '..id..': '..tostring(reason)..'; original record preserved, derived effects disabled') end
 J.rejected[id]=raw;J.invalidPending[id]=false
 J.InvalidateSpatial(id);J.hp[id]=nil
 p:SetHasPolicy(J.T.POLICY_JIN_TRIBUTARY_TRADE,false);p:SetHasPolicy(J.T.POLICY_JIN_MONASTERY,false)
 for c in p:Cities() do
  for _,key in ipairs({'TRIBUTE','PAVILION_DISCOUNT','BLESSING'}) do J.SetBuilding(c,key,0) end
  for _,up in ipairs(J.C.upgrades) do J.SetBuilding(c,'UP_'..up.key,0) end
 end
 local remove={}
 for u in p:Units() do J.SyncUnit(id,u,nil)
  local marker=J.S.Read(u,'JIN_D1')
  if marker then
   if u:IsBusy() or u:IsFighting() then J.invalidPending[id]=true else remove[#remove+1]=u:GetID() end
  end
 end
 for _,uid in ipairs(remove) do local u=p:GetUnitByID(uid);if J.Alive(u) then u:Kill(false,-1) end end
end
