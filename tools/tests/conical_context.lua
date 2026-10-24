local p=Player(0,true);p.capital=City(p,0,true,false)
local c=City(p,1,true,true)
local f=Player(1,false);local foreign=City(f,0,true,false);f.capital=foreign
LoadConical();Check(c,2,2,2)
-- Quick-load risk: shared data survives, old context/registrations do not.
c.connected=false
RecreateConical(false,true,false)
assert(#GameEvents.PlayerDoTurn.handlers==1,'shared marker suppressed a new context')
Check(c,0,1,0)
local scansBefore=scans;LoadConical();assert(scans==scansBefore,'same-context include must be inert')
-- A new Lua environment can reuse a native context pointer. Private globals are fresh.
local reused=ContextPtr
ResetEvents(true,true);ContextPtr=reused;__CONICAL_CONTEXT_CONTROLLER=nil
LoadConical();assert(#GameEvents.PlayerDoTurn.handlers==1,'reused pointer suppressed fresh Lua registrations')
-- If old callbacks remain in the event registry, replace/detach them explicitly.
for i=1,8 do
  RecreateConical(true,true,false)
  assert(#GameEvents.PlayerDoTurn.handlers==1,'retained callbacks accumulated')
  local q=queries;GameEvents.PlayerDoTurn.Fire(0)
  assert(queries-q==1,'more than one effective controller')
end
-- A late old-context shutdown must not unregister the new owner.
local old=RecreateConical(true,true,false)
if old.shutdown then old.shutdown() end
c.connected=true;GameEvents.PlayerDoTurn.Fire(0);Check(c,2,2,2)
-- Normal shutdown, new game from menu, and a fresh shared table all recover.
RecreateConical(true,true,true);Check(c,2,2,2)
RecreateConical(false,false,true);Check(c,2,2,2)
-- Event removal is a supported API but old/dead callbacks may be inaccessible.
for _,events in ipairs({GameEvents,Events}) do for _,e in pairs(events) do e.Remove=nil end end
RecreateConical(true,true,false)
local q=queries;GameEvents.PlayerDoTurn.Fire(0);assert(queries-q==1,'retired wrapper must be inert')
-- No City userdata is carried between contexts. Foreign saved residue is cleaned once.
foreign.b[U]=1;foreign.b[G]=1
RecreateConical(false,true,false);Check(foreign,0,0,0)
local s=scans;Events.SequenceGameInitComplete.Fire();Events.LoadScreenClose.Fire()
assert(scans-s==2,'foreign city lists must not be swept at every init notification')
print('PASS Conical shared-data quick-load/context recreation, retained/removed handlers, shutdown ownership, fresh games and one-time foreign load cleanup (synthetic)')
