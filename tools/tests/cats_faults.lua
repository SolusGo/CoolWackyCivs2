local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local p=Players[0];local a=City(0,1,10,10);H.Reconcile(0,true);Flush();local s=H.State(0)
local unit=H.Unit(s,'LUNA');unit:MoveTo(a)
-- Save failure BEFORE mutation must not consume the travelling cat.
local save=p.SetScriptData;p.SetScriptData=function() error('before native save') end
local ok=H.Command(0,'LUNA','SETTLE');assert(not ok and s.cats.LUNA.status==1 and H.Unit(s,'LUNA')==unit)
assert(not H.busy and not H.syncing);Flush();assert(not ContextPtr.callback)
p.SetScriptData=save;Events.SerialEventGameDataDirty();Flush()
-- Save error AFTER mutation is verified, and settling is committed exactly once.
p.SetScriptData=function(self,value) save(self,value);error('after native save') end
assert(H.Command(0,'LUNA','SETTLE'));assert(s.cats.LUNA.status==2 and UnitCount(0)==0)
p.SetScriptData=save;Flush()
-- An interrupted constructor must never leave the global spawning guard set.
local init=p.InitUnit;p.InitUnit=function() error('before constructor') end
assert(not H.Command(0,'LUNA','REHOME'));assert(s.cats.LUNA.status==2 and s.cats.LUNA.cooldown==0)
assert(not H.spawning and not H.busy);p.InitUnit=init
-- Native birth followed by an exception: adopt that one birth, do not duplicate.
p.InitUnit=function(self,...) init(self,...);error('after constructor') end
assert(H.Command(0,'LUNA','REHOME'));p.InitUnit=init
assert(UnitCount(0)==1 and s.cats.LUNA.status==1 and s.cats.LUNA.cooldown==10)
local uid=s.cats.LUNA.unit;unit=H.Unit(s,'LUNA')
-- Removal by an enemy / embarked removal invokes the same noncancelable ABI.
GameEvents.UnitPrekill(0,uid,H.UNIT,10,10,true,1);local due=s.cats.LUNA.recovery
GameEvents.UnitPrekill(0,uid,H.UNIT,10,10,false,1);assert(s.cats.LUNA.recovery==due)
unit:Kill();Advance(3);H.Reconcile(0,false);assert(s.cats.LUNA.status==1 and s.cats.LUNA.cooldown==10)
unit=H.Unit(s,'LUNA');uid=unit:GetID()
-- Missing/ambiguous promotions can be repaired from consistent independent identity.
unit:SetHasPromotion(GameInfoTypes.PROMOTION_THE11CATS_LUNA,false);H.Reconcile(0,false)
assert(H.Unit(s,'LUNA'):GetID()==uid and s.cats.LUNA.recovery==-1)
unit:SetHasPromotion(GameInfoTypes.PROMOTION_THE11CATS_BONNIE,true);H.Reconcile(0,false)
assert(H.Identity(unit)=='LUNA' and H.Unit(s,'LUNA'):GetID()==uid)
-- Adversarial iteration order: prefer the SAVED unit, not the first duplicate.
local duplicate=p:InitUnit(H.UNIT,11,10,-1);duplicate:SetHasPromotion(GameInfoTypes.PROMOTION_THE11CATS_LUNA,true)
local iterator=p.Units;p.Units=function(self)
 local values={};for u in iterator(self) do values[#values+1]=u end
 table.sort(values,function(x,y) return x:GetID()>y:GetID() end)
 local i=0;return function() i=i+1;return values[i] end
end
H.Reconcile(0,false);p.Units=iterator;assert(s.cats.LUNA.unit==uid and duplicate:IsDead())
Advance(7);Settle('LUNA',a);Flush()
-- Unsaveable rehome rolls back residence, cooldown, effects AND the new unit.
p.SetScriptData=function() error('rehome cannot save') end
assert(not H.Command(0,'LUNA','REHOME'));p.SetScriptData=save
assert(s.cats.LUNA.status==2 and s.cats.LUNA.cooldown==10 and UnitCount(0)==0)
Flush()
-- An event arriving inside a mutation must be retained, including its unlock flag.
local b=City(0,2,20,20);local setter=a.SetNumRealBuilding;local fired=false
a.buildings[H.buildings.LUNA]=0
a.SetNumRealBuilding=function(self,id,n)
 setter(self,id,n)
 if not fired and id==H.buildings.LUNA and n==1 then
  fired=true;Transfer(a,1);p.era=2;GameEvents.TeamSetEra(0,2,false)
 end
end
H.Reconcile(0,false);Flush();a.SetNumRealBuilding=setter
assert(fired and s.cats.LUNA.status==3 and s.cats.BONNIE.status==1 and s.cats.APPA.status==1)
for _,building in pairs(H.buildings) do assert(a:GetNumRealBuilding(building)==0) end
-- Persistent native errors stop after a bounded event wave; later events retry.
local calls=0;local set=b.SetNumRealBuilding;b.SetNumRealBuilding=function() calls=calls+1;error('persistent setter failure') end
local bonnie=H.Unit(s,'BONNIE');bonnie:MoveTo(b);assert(H.Command(0,'BONNIE','SETTLE'))
Flush();assert(not ContextPtr.callback and not H.busy and not H.syncing)
local stopped=calls;H.Refresh();Flush();assert(calls==stopped,'UI-only refresh cannot restart exhausted gameplay retries')
b.SetNumRealBuilding=set;Events.SerialEventGameDataDirty();Flush()
assert(b:GetNumRealBuilding(H.buildings.BONNIE)==1)
-- Impossible timers repair once without discarding independent cooldowns/progress.
s.cats.LUNA.recovery=999999;s.cats.LUNA.cooldown=999999;H.Reconcile(0,false)
assert(s.cats.LUNA.recovery==H.Turn()+3 and s.cats.LUNA.cooldown==H.Turn()+10)
due=s.cats.LUNA.recovery;H.Reconcile(0,false);assert(s.cats.LUNA.recovery==due)
local appa=H.Unit(s,'APPA');appa:MoveTo(b);local kill=appa.Kill
appa.Kill=function() error('unit retained by native hook') end
assert(H.Command(0,'APPA','SETTLE'));Flush()
local can,reason=H.CanRehome(0,'APPA');assert(not can and reason=='PENDING_REPAIR')
assert(not next(H.removing) and not H.busy and not H.syncing)
appa.Kill=kill;Events.SerialEventGameDataDirty();Flush();assert(appa:IsDead())
-- A cleanup request whose owner is human must reconcile, never purge companions.
local remaining=UnitCount(0);H.Foreign(0);Flush();assert(UnitCount(0)==remaining)
print('PASS interrupted saves/constructors, identity repair, deterministic duplicates, reentrant capture+era, bounded failures and timer integrity')
