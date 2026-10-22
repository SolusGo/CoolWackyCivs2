local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local s=H.State(0)
assert(s.cats.LUNA.status==3 and UnitCount(0)==0,'pre-capital arrival must be pending')
assert(not s.cats.AUSTIN and #H.Order==11)
local a=City(0,1,10,10);H.Reconcile(0,true)
assert(s.cats.LUNA.status==1 and UnitCount(0)==1)
local notices=#Players[0].notifications;local writes=Players[0].writes
H.Reconcile(0,true);assert(#Players[0].notifications==notices and Players[0].writes==writes)
Settle('LUNA',a);assert(a:GetNumRealBuilding(H.buildings.LUNA)==1 and a:GetNumRealBuilding(H.buildings.FIRST_PAIR)==1)
assert(not H.Unit(s,'LUNA') and UnitCount(0)==0)
Players[0].era=2;GameEvents.TeamSetEra(0,2,false)
assert(s.cats.BONNIE.status==1 and s.cats.APPA.status==1 and s.cats.LOKI.status==1 and s.cats.KURO.status==1)
assert(s.cats.OSCAR.status==0)
Settle('BONNIE',a);Settle('KURO',a)
assert(#H.Residents(s,a)==3 and a:GetNumRealBuilding(H.buildings.BONNIE_FAMILY)==1)
local appa=H.Unit(s,'APPA');appa:MoveTo(a);assert(not H.CanSettle(0,'APPA'))
a.buildings[H.TREE]=1;GameEvents.CityConstructed(0,1,H.TREE)
assert(a:GetNumRealBuilding(H.buildings.TREE_FOOD)==1)
H.Effects(0);assert(a:GetNumRealBuilding(H.buildings.TREE_FOOD)==1)
assert(H.Command(0,'LUNA','REHOME'));assert(s.cats.LUNA.cooldown==H.Turn()+10)
assert(a:GetNumRealBuilding(H.buildings.LUNA)==0 and a:GetNumRealBuilding(H.buildings.FIRST_PAIR)==0)
assert(not H.CanSettle(0,'LUNA'));local script=Players[0].script
Reload();H=MapModData.THE11CATS;H.InterfaceReady=function() return true end;s=H.State(0)
assert(s.cats.LUNA.cooldown==10 and Players[0].script:find('foreign:kept',1,true))
Advance(10);H.Reconcile(0,false);local b=City(0,2,20,20);Settle('LUNA',b)
assert(b:GetNumRealBuilding(H.buildings.FIRST_PAIR)==0)
Players[0].capital=b;GameEvents.CapitalChanged(0,2,1);assert(b:GetNumRealBuilding(H.buildings.FIRST_PAIR)==1)
-- Genuine capture: clear every dummy/choice under the new owner immediately.
Transfer(a,1)
assert(s.cats.BONNIE.status==3 and s.cats.KURO.status==3)
for _,building in pairs(H.buildings) do assert(a:GetNumRealBuilding(building)==0) end
Advance(2);H.Reconcile(0,false);assert(s.cats.BONNIE.status==3)
Advance(1);H.Reconcile(0,false);assert(s.cats.BONNIE.status==1 and s.cats.KURO.status==1)
local unit=H.Unit(s,'BONNIE');unit:Kill(false,1);assert(s.cats.BONNIE.status==3)
Advance(3);H.Reconcile(0,false);assert(s.cats.BONNIE.status==1)
local count=UnitCount(0);for i=1,8 do H.Reconcile(0,true) end;assert(UnitCount(0)==count)
-- A duplicate carrying a genuine identity must not become a second resident.
unit=Players[0]:InitUnit(H.UNIT,21,20,-1);unit:SetHasPromotion(GameInfoTypes.PROMOTION_THE11CATS_BONNIE,true)
H.Reconcile(0,false);assert(UnitCount(0)==count)
assert(not GameEvents.PlayerCanDisbandUnit(0,s.cats.BONNIE.unit))
assert(not GameEvents.CanDoCommand(0,s.cats.BONNIE.unit,CommandTypes.COMMAND_GIFT))
assert(not GameEvents.UnitCanHaveAnyUpgrade(0,s.cats.BONNIE.unit))
assert(GameEvents.PlayerCanDisbandUnit(1,999))
assert(not GameEvents.CityCanTrain(1,1,H.UNIT))
-- Missing units without a removal hook are detected using the registry.
unit=H.Unit(s,'APPA');unit.plot.units[unit.id..':0']=nil;Players[0].units[unit.id]=nil
H.Reconcile(0,false);assert(s.cats.APPA.status==3)
-- Elimination retains pending identities and does not repeatedly spawn.
Players[0].alive=false;Transfer(b,1);Advance(20);H.Reconcile(0,false)
assert(s.cats.LUNA.status==3);Players[0].alive=true
local c=City(0,3,30,30);H.Reconcile(0,false);assert(s.cats.LUNA.status==1)
print('PASS cats lifecycle: progression, capacity, bonds, capture, rehome, reload, death, missing unit, duplicate and elimination')
