local B=MapModData.BoundlessCity;local s=B.State(0)
s.mode='MANUAL';s.locks={};capital.buildings[200]=1
local baseline=B.Cost(s);speed=200;assert(B.Cost(s)>=baseline*2-1);speed=100
local enemy=Map.GetPlot(20,5);enemy.owner=1
local sea=Map.GetPlot(25,5);sea.water=true
local ownedBefore=B.Ownership(s).count
Players[0].notifications={}
s.progress=10000000;B.Busy[0]=true;B.Expand(s);B.Busy[0]=nil
assert(enemy.owner==1,'frontier cannot steal enemy land')
assert(Map.GetPlot(70,8).owner==0 and sea.owner==0,'growth must exceed thirty hexes and cross water')
assert(s.progress>0 and B.Ownership(s).count>1000)
assert(#Players[0].notifications==B.Ownership(s).count-ownedBefore,'each successful frontier tile gets one notice')
local noticed={}
for _,notice in ipairs(Players[0].notifications) do
 local p=Map.GetPlot(notice.x,notice.y)
 assert(p:GetOwner()==0 and not noticed[p.n] and notice.kind==NotificationTypes.NOTIFICATION_GENERIC)
 noticed[p.n]=true
end
for n in pairs(B.Ownership(s).owned) do assert(B.Ownership(s).connected[n], 'all expansion claims remain capital-connected') end
for n=1,10 do assert(capital.buildings[200+n]==1,'Registry cap exactly ten nonstacking Culture bits') end
local scansBefore=scans;B.Ownership(s);B.Reconcile(s);B.Ownership(s);assert(scans==scansBefore,'steady cache must not scan whole map')
assert(s.reserved==0 and (capital.misc[0] or 0)==0,'owning an entire map does not grant unworked tile yields')
print('PASS frontier: >30 hexes, water continuity, enemy protection, game-speed cost and zero unworked yields')
-- Targeted wrapped-edge claim: high-yield water immediately across X=0.
MakeMap(80,20,true);capital=MakeCity(0,0,5,2,2);capital.originalCapital=true;Players[0].cities={capital};Players[0].script=''
B.States={};B.Caches={};B.Initialize(0);s=B.State(0)
local edge=Map.GetPlot(79,5);edge.water=true;edge.yields={100,100,0,0,0,0}
Players[0].notifications={}
s.progress=B.Cost(s)-capital.culture;B.Busy[0]=true;B.Expand(s);B.Busy[0]=nil
assert(edge.owner==0 and B.Ownership(s).connected[edge.n],'native adjacency must cross a wrapped coast')
local notice=assert(Players[0].notifications[1]);assert(notice.x==79 and notice.y==5 and #Players[0].notifications==1)
assert(B.Atlas(s).byName.CENTRAL,'across the seam is one hex from the capital')
assert(B.Atlas(s)==B.Atlas(s),'unchanged territory reuses the atlas view')
GameEvents.CityBoughtPlot.Fire(0,capital.id,79,5,false,true)
assert(#Players[0].notifications==1,'duplicate same-tile hooks must not add a second notice')
local native=Map.GetPlot(76,5);native:SetOwner(0,capital.id,true)
GameEvents.CityBoughtPlot.Fire(0,capital.id,76,5,true,false)
GameEvents.CityBoughtPlot.Fire(0,capital.id,76,5,false,false)
GameEvents.CityBoughtPlot.Fire(0,capital.id,77,5,false,true)
GameEvents.CityBoughtPlot.Fire(0,capital.id+1,76,5,false,true)
assert(#Players[0].notifications==1,'ignore gold purchases, failed claims and other cities')
GameEvents.CityBoughtPlot.Fire(0,capital.id,76,5,false,true)
assert(#Players[0].notifications==2 and Players[0].notifications[2].x==76)
assert(B.Atlas(s).byName.WEST.plots[1].n==native.n,'wrapped western ward follows ownership')
local original=Players[0].AddNotification
local bad=Map.GetPlot(1,5);bad.owner=-1;bad.yields={200,200,0,0,0,0};B.Cache(s).territoryDirty=true
Players[0].AddNotification=function() error('injected native notification failure') end
s.progress=B.Cost(s)-capital.culture;B.Busy[0]=true;B.Expand(s);B.Busy[0]=nil
Players[0].AddNotification=original
assert(bad.owner==0 and s.progress==0,'notification failure cannot interfere with successful expansion')
print('PASS targeted wrapped-edge adjacent water claim')
