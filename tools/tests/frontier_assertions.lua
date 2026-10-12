local B=MapModData.BoundlessCity;local s=B.State(0)
s.mode='MANUAL';s.locks={};capital.buildings[200]=1
local baseline=B.Cost(s);speed=200;assert(B.Cost(s)>=baseline*2-1);speed=100
local enemy=Map.GetPlot(20,5);enemy.owner=1
local sea=Map.GetPlot(25,5);sea.water=true
s.progress=10000000;B.Busy[0]=true;B.Expand(s);B.Busy[0]=nil
assert(enemy.owner==1,'frontier cannot steal enemy land')
assert(Map.GetPlot(70,8).owner==0 and sea.owner==0,'growth must exceed thirty hexes and cross water')
assert(s.progress>0 and B.Ownership(s).count>1000)
for n in pairs(B.Ownership(s).owned) do assert(B.Ownership(s).connected[n], 'all expansion claims remain capital-connected') end
for n=1,10 do assert(capital.buildings[200+n]==1,'Registry cap exactly ten nonstacking Culture bits') end
local scansBefore=scans;B.Ownership(s);B.Reconcile(s);B.Ownership(s);assert(scans==scansBefore,'steady cache must not scan whole map')
assert(s.reserved==0 and (capital.misc[0] or 0)==0,'owning an entire map does not grant unworked tile yields')
print('PASS frontier: >30 hexes, water continuity, enemy protection, game-speed cost and zero unworked yields')
