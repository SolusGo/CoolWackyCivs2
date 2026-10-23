local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local p=Players[0];p.era=5
local homes={};for i=1,6 do homes[i]=City(0,i,i*10,i*10) end
H.Reconcile(0,true)
Settle('LUNA',homes[1]);Settle('BONNIE',homes[2]);Settle('KURO',homes[2]);Settle('BOOMIE',homes[2])
Settle('APPA',homes[3]);Settle('LOKI',homes[3]);Settle('OSCAR',homes[3])
Settle('CHARLOTTE',homes[4]);Settle('SISI',homes[4]);Settle('MAX',homes[4]);Flush()
local writes=p.writes;local notices=#p.notifications
for turn=1,600 do Advance(1);GameEvents.PlayerDoTurn(0);Flush() end
assert(p.writes==writes and #p.notifications==notices and not ContextPtr.callback)
for move=1,12 do
 local s=H.State(0);assert(H.Command(0,'LUNA','REHOME'))
 for i=1,10 do Advance(1);GameEvents.PlayerDoTurn(0);Flush() end
 assert(UnitCount(0)==1)
 Settle('LUNA',homes[move%2==1 and 5 or 1]);Flush();assert(UnitCount(0)==0)
end
local raw=p.script;notices=#p.notifications
for i=1,50 do
 Reload();H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
 assert(p.script==raw and GameEvents.PlayerDoTurn.Count()==1 and not ContextPtr.callback)
end
assert(#p.notifications==notices)
local s=H.State(0);for _,c in pairs(s.cats) do assert(c.status==2) end
assert(H.Bonds(s,homes[1]).FIRST_PAIR and H.Bonds(s,homes[3]).SISTERS_BED)
print('PASS six-city / ten-cat fixture: 720 turn transitions, 12 rehomes and 50 reloads; stable handlers, no idle callbacks or redundant stable-turn saves')
