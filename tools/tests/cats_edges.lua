local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local a=City(0,1,10,10);H.Reconcile(0,true);local s=H.State(0)
-- CP changes the counter before dispatching; SetCounter emits no second hook.
a.wltkd=20;GameEvents.CityBeginsWLTKD(0,10,10,20);assert(a.wltkd==25)
for i=1,5 do a.wltkd=a.wltkd-1;H.Reconcile(0,false) end;assert(a.wltkd==20)
a.wltkd=a.wltkd+8;GameEvents.CityExtendsWLTKD(0,10,10,8);assert(a.wltkd==30)
a.wltkd=0;H.Reconcile(0,false);assert(a.wltkd==0)
for i=1,4 do a.wltkd=1;GameEvents.CityBeginsWLTKD(0,10,10,1);assert(a.wltkd==(i==4 and 2 or 1)) end
local foreign=City(1,1,60,60);foreign.wltkd=20;GameEvents.CityBeginsWLTKD(1,60,60,20);assert(foreign.wltkd==20)
local plot=a:Plot();plot.script='another-mod|'..plot.script;Reload();H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
assert(plot.script:find('another-mod|',1,true))
-- Resistance does not add an unspecified restriction to owned-city settling.
a.resistance=true;assert(H.CanSettle(0,'LUNA'));a.resistance=false
-- A completely occupied home delays recovery. No repeated spawn attempts succeed.
local u=H.Unit(H.State(0),'LUNA');u:Kill();Advance(3)
a:Plot().blocked=true;for d=0,5 do Map.PlotDirection(10,10,d).blocked=true end
H.Reconcile(0,false);assert(H.State(0).cats.LUNA.status==3 and UnitCount(0)==0)
a:Plot().blocked=false;H.Reconcile(0,false);assert(H.State(0).cats.LUNA.status==1)
-- Atomic rehome failure preserves residence and all benefits.
Settle('LUNA',a);Players[0].failSpawn=true
assert(not H.Command(0,'LUNA','REHOME'));assert(H.State(0).cats.LUNA.status==2 and a:GetNumRealBuilding(H.buildings.LUNA)==1)
Players[0].failSpawn=false
for _,entry in ipairs({{67,7,2},{100,10,3},{150,15,5},{300,30,9}}) do
 GameInfo.GameSpeeds[0].TrainPercent=entry[1];assert(H.Duration(10)==entry[2] and H.Duration(3)==entry[3])
end
GameInfo.GameSpeeds[0].TrainPercent=100
-- Razing displaces residents before their next yield harvest.
a.razing=true;H.Reconcile(0,false);assert(H.State(0).cats.LUNA.status==3 and a:GetNumRealBuilding(H.buildings.LUNA)==0)
Events.SerialEventGameDataDirty();Events.SerialEventGameDataDirty();Flush();assert(not ContextPtr.callback)
print('PASS WLTKD refresh/fractions, foreign isolation, blocked spawn, atomic rehome, speed scaling, razing and one-shot dispatcher')
