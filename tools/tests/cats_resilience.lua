local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local a=City(0,1,10,10);local b=City(0,2,20,20);local c=City(0,3,30,30);local d=City(0,4,40,40)
Players[0].era=5;H.Reconcile(0,true);local s=H.State(0)
Settle('LUNA',a);Settle('BONNIE',a);Settle('KURO',a)
Settle('APPA',b);Settle('LOKI',b);Settle('OSCAR',b)
Settle('CHARLOTTE',c);Settle('SISI',c);Settle('MAX',c);Settle('BOOMIE',d)
local writes=Players[0].writes;local notifications=#Players[0].notifications
local started=os.clock()
for i=1,1000 do H.Reconcile(0,true) end
assert(Players[0].writes==writes and #Players[0].notifications==notifications)
print(string.format('PASS 1,000 late-household reconciliations: %.4fs total in Lua model; zero redundant saves/notifications',os.clock()-started))
-- Names are presentation only; residence uses location + founding identity.
a.name='Renamed family home';H.Reconcile(0,false);assert(#H.Residents(s,a)==3)
-- Multiple ownership changes on one turn; save while every companion recovers.
Transfer(a,1);Transfer(b,1);Transfer(c,1);Transfer(d,1)
for _,cat in pairs(s.cats) do assert(cat.status==3) end
Reload();H=MapModData.THE11CATS;H.InterfaceReady=function() return true end;s=H.State(0)
Advance(3);H.Reconcile(0,false);assert(UnitCount(0)==0)
local e=City(0,5,50,50);H.Reconcile(0,false)
assert(UnitCount(0)==7,'one civilian per city/adjacent hex; blocked cats stay pending')
local f=City(0,6,70,70);H.Reconcile(0,false);assert(UnitCount(0)==10)
Settle('LUNA',e)
-- A replacement city at the exact same coordinates has a new founding identity.
Advance(1);Players[0].cities[e.id]=nil;e:Plot().city=nil
local replacement=City(0,8,50,50);H.Reconcile(0,false);assert(s.cats.LUNA.status==3)
-- Foreign and AI-created cat units are purged after initialization, not while
-- their native constructor is running. Unrelated units are left untouched.
local orphan=Players[2]:InitUnit(H.UNIT,80,80,-1);assert(orphan and not orphan:IsDead());Flush();assert(UnitCount(2)==0)
assert(not GameEvents.CityCanConstruct(2,1,H.TREE))
local good=Players[0].script
Players[0].script='foreign:kept|THE11CATS2:future|';Reload();H=MapModData.THE11CATS
assert(H.failed[0] and Players[0].script=='foreign:kept|THE11CATS2:future|')
for city in Players[0]:Cities() do for _,building in pairs(H.buildings) do assert(city:GetNumRealBuilding(building)==0) end end
Players[0].script='foreign:kept|THE11CATS1:1,2,bad|';Reload();H=MapModData.THE11CATS
assert(H.failed[0] and Players[0].script=='foreign:kept|THE11CATS1:1,2,bad|')
print('PASS city rename/refounding, simultaneous ten-cat recovery, 7-hex spawn limits, AI cleanup and preserved corrupt/future saves')
