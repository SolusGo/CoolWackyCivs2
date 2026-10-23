-- Bounded, event-driven follow-up work. Never leave a native update attached.
local H=MapModData.THE11CATS
local pending,foreign={},{}
local queued,dispatching,attempts,renderNeeded=false,false,0,false
local arm,flush
function H.Request(pid,unlock)
 if not Players[pid] then return end
 pending[pid]=(pending[pid] or unlock) and true or false
 if not H.busy and not H.syncing and not dispatching then attempts=0;arm() end
end
function H.Foreign(pid) if Players[pid] then foreign[pid]=true;H.Request(pid,false) end end
function H.Schedule()
 for pid=0,GameDefines.MAX_MAJOR_CIVS-1 do if H.Human(pid) then pending[pid]=pending[pid] or false end end
 if not H.busy and not H.syncing and not dispatching then attempts=0;arm() end
end
function H.Refresh()
 renderNeeded=true
 if not H.busy and not H.syncing and not dispatching then arm() end
end
arm=function()
 if queued or H.busy or H.syncing or dispatching or (attempts>=2 and not renderNeeded) or (not next(pending) and not next(foreign) and not renderNeeded) then return end
 queued=true;ContextPtr:SetUpdate(flush)
end
local reconcile=H.Reconcile
function H.Reconcile(pid,unlock)
 if H.busy or H.syncing then H.Request(pid,unlock);return false end
 if not dispatching then attempts=0 end
 H.syncing=true
 local ok,err=pcall(reconcile,pid,unlock)
 H.syncing=false
 if not ok then
  H.Log('Reconciliation deferred for '..pid..': '..tostring(err),true)
  pending[pid]=(pending[pid] or unlock) and true or false
 end
 H.Changed(pid);arm();return ok
end
local command=H.Command
function H.Command(pid,id,action)
 if H.busy or H.syncing then return false,'BUSY' end
 attempts=0
 H.busy=true
 local ok,result,reason=pcall(command,pid,id,action)
 H.busy=false
 if not ok then
  H.Log('Command repair queued for '..tostring(id)..': '..tostring(result),true)
  pending[pid]=pending[pid] or false;result=false;reason='PENDING_REPAIR'
 end
 H.Changed(pid);arm();return result,reason
end
flush=function()
 ContextPtr:ClearUpdate();queued=false;dispatching=true
 if H.interface then H.interface.transition=false end
 local batch,cleanup={},{}
 if attempts<2 and (next(pending) or next(foreign)) then batch,cleanup=pending,foreign;pending={};foreign={};attempts=attempts+1 end
 local repaint=renderNeeded;renderNeeded=false
 local ok,err=pcall(function()
  for pid=0,GameDefines.MAX_CIV_PLAYERS-1 do
   if cleanup[pid] and not H.Human(pid) then
    local cleaned,fault=pcall(function() H.PurgeUnits(pid);H.Effects(pid) end)
    if not cleaned then foreign[pid]=true;H.Log('Foreign cleanup deferred: '..tostring(fault),true) end
   end
   if batch[pid]~=nil then H.Reconcile(pid,batch[pid]) end
  end
  if repaint and H.Render then H.Render() end
 end)
 dispatching=false;H.syncing=false;H.busy=false
 if not ok then
  H.Log('Deferred batch interrupted: '..tostring(err),true)
  for pid,unlock in pairs(batch) do pending[pid]=(pending[pid] or unlock) and true or false end
 end
 -- Two attempts per event wave. Persistent failures retain pending work but
 -- sleep until the next genuine lifecycle event; no idle retry loop.
 arm()
end
