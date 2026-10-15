-- Reproduce the native UI context contract, rather than a self-clearing mock.
local B=MapModData.BoundlessCity;local s=B.State(0)
local frames=0
local callback=function() frames=frames+1 end
ContextPtr:SetUpdate(callback);Pump();Pump();assert(frames==2 and deferred==callback)
local ok=pcall(function() ContextPtr:SetUpdate(nil) end)
assert(not ok and deferred==callback,'nil must be rejected without detaching a native callback')
ContextPtr:ClearUpdate();Pump();assert(frames==2 and deferred==nil)

local calls=0;local reconcile=B.Reconcile;local set=ContextPtr.updatesSet;local cleared=ContextPtr.updatesCleared
B.Reconcile=function(state) calls=calls+1;return reconcile(state) end
for i=1,1000 do B.Schedule(0) end
assert(ContextPtr.updatesSet==set+1,'event storm must install one coalesced callback')
Pump();assert(calls==1 and deferred==nil and ContextPtr.updatesCleared==cleared+1)
local saved=Players[0].script;local before=mutations
for i=1,1000 do Pump() end
assert(calls==1 and mutations==before and Players[0].script==saved,'idle frames must not repeat work or saves')

-- Work scheduled during dispatch survives into the following frame; ClearUpdate
-- happens before any native mutation/event can arm that subsequent callback.
local once=true
B.Reconcile=function(state)
 calls=calls+1
 if once then once=false;B.Schedule(state.pid) end
 return reconcile(state)
end
B.Schedule(0);Pump();assert(calls==2 and deferred~=nil)
Pump();assert(calls==3 and deferred==nil)
Pump();assert(calls==3)

-- Clear before a failure as well: an unexpected exception cannot leave this
-- callback running and throwing repeatedly on later frames.
B.Reconcile=function() error('injected deferred reconciliation failure') end
B.Schedule(0);ok=pcall(Pump);assert(not ok and deferred==nil)
assert(pcall(Pump),'subsequent idle frame must not replay the failure')
B.Reconcile=reconcile;B.Schedule(0);Pump();assert(deferred==nil,'fresh events can schedule after a failed batch')

-- A second Boundless player shares the coalesced batch but gets its own state.
local originalCiv=Players[1].GetCivilizationType
Players[1].GetCivilizationType=function() return 100 end
B.Initialize(1)
calls=0;B.Reconcile=function(state) calls=calls+1;return reconcile(state) end
B.Schedule(0);B.Schedule(1);Pump();assert(calls==2 and deferred==nil)
Players[1].GetCivilizationType=originalCiv;B.Reconcile=reconcile

local movementCalls=0
B.Reconcile=function(state) movementCalls=movementCalls+1;return reconcile(state) end
local p=Remote(25,5,{4,3,2,1,1,1});s.mode='MANUAL';s.selected={[p.n]=true};B.Cache(s).force=true;reconcile(s)
for i=1,100 do
 p.enemy=i%2==1
 local c=B.RefreshEligibility(s,{[p.n]=true});local changed=B.Trim(s,{[p.n]=true})
 if c or changed then B.Schedule(0,true) end
end
assert(deferred~=nil);Pump();assert(movementCalls==1 and deferred==nil)
before=mutations;for i=1,500 do Pump() end
assert(movementCalls==1 and mutations==before,'movement batch must settle without a permanent update')
B.Reconcile=reconcile
-- UI-only work uses the same owner without overwriting a gameplay batch, and
-- work queued by a UI callback survives to the next frame as well.
local uiCalls=0
B.DeferUI(function() uiCalls=uiCalls+1;B.DeferUI(function() uiCalls=uiCalls+1 end) end)
Pump();assert(uiCalls==1 and deferred~=nil)
Pump();assert(uiCalls==2 and deferred==nil)
print('PASS native persistent-update contract, nil rejection, ClearUpdate, 1,000-event coalescing/idle frames, reentrancy, failure detach and two-player batch isolation')
