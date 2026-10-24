local p=Player(0,true);p.capital=City(p,0,true,false)
local c=City(p,1,true,true)
LoadConical();Check(c,2,2,2)
c.IsConnectedToCapital=false;GameEvents.PlayerDoTurn.Fire(0);Check(c,0,1,0)
c.IsConnectedToCapital=function() error('native query unavailable') end
GameEvents.PlayerDoTurn.Fire(0);Check(c,0,1,0)
c.IsConnectedToCapital=function(self) return self.connected end
c.failBefore=true;GameEvents.PlayerDoTurn.Fire(0);Check(c,2,2,2)
c.connected=false;c.failAfter=true;GameEvents.PlayerDoTurn.Fire(0);Check(c,0,1,0)
-- No optional event is required for turn/load correctness.
ResetEvents(false);c.connected=true;LoadConical();Check(c,2,2,2)
c.connected=false;GameEvents.PlayerDoTurn.Fire(0);Check(c,0,1,0)
-- Foreign players can have many cities without any per-turn enumeration.
for id=1,62 do local f=Player(id,false);for n=1,20 do City(f,n,true,true) end end
local beforeScans,beforeWrites=scans,writes
for repeatIndex=1,100 do for id=1,63 do GameEvents.PlayerDoTurn.Fire(id) end end
assert(scans==beforeScans and writes==beforeWrites,'unrelated turns must do constant work')
for n=2,201 do City(p,n,true,n%2==0) end
GameEvents.PlayerDoTurn.Fire(0)
local stable=writes
for i=1,100 do GameEvents.PlayerDoTurn.Fire(0) end
assert(writes==stable,'large empire steady state must not write')
for _,city in ipairs(p.cities) do
  if city~=p.capital and city.connected then Check(city,2,1+(city.b[O] or 0),(city.b[O] or 0)*2) end
end
print('PASS Conical missing/failing API, retry before/after write, reentrant dirty events, optional hooks, 6,300 foreign turns without city iteration and 202-city idempotence')
