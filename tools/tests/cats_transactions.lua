local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local p=Players[0];local home=City(0,1,10,10);H.Reconcile(0,true);Flush();local s=H.State(0)
local save,init=p.SetScriptData,p.InitUnit
local luna=H.Unit(s,'LUNA');luna:MoveTo(home);local original=p.script
-- A setter which returns without storing must never commit/consume a traveller.
p.SetScriptData=function() end
assert(not H.Command(0,'LUNA','SETTLE'),'silently rejected save must not commit')
assert(s.cats.LUNA.status==1 and H.Unit(s,'LUNA')==luna and p.script==original)
p.SetScriptData=save;Flush();Settle('LUNA',home);Flush()
local cooldown=s.cats.LUNA.cooldown;original=p.script
-- Setup fails before the identity exists, AND native cleanup retains the birth.
local retained,kill
p.InitUnit=function(self,...)
 local u=init(self,...);retained=u;kill=u.Kill
 u.SetHasPromotion=function() error('identity setup rejected') end
 u.Kill=function() error('rollback cleanup retained') end
 return u
end
assert(not H.Command(0,'LUNA','REHOME'));p.InitUnit=init
assert(UnitCount(0)==1 and s.cats.LUNA.status==2 and s.cats.LUNA.cooldown==cooldown and p.script==original)
for i=1,5 do
 local ok,why=H.CanRehome(0,'LUNA');assert(not ok and why=='PENDING_REPAIR')
 assert(not H.Command(0,'LUNA','REHOME') and UnitCount(0)==1,'unidentified rollback birth must block another birth')
end
Flush();assert(not ContextPtr.callback and UnitCount(0)==1 and not H.busy and not H.syncing)
retained.Kill=kill;Events.SerialEventGameDataDirty();Flush();assert(UnitCount(0)==0)
-- An otherwise valid birth whose unsaved rollback cannot kill is equally safe.
p.InitUnit=function(self,...) local u=init(self,...);retained=u;kill=u.Kill;u.Kill=function() error('identified rollback retained') end;return u end
p.SetScriptData=function() error('before rehome save') end
assert(not H.Command(0,'LUNA','REHOME'));p.InitUnit=init;p.SetScriptData=save
assert(s.cats.LUNA.status==2 and s.cats.LUNA.cooldown==cooldown and p.script==original)
assert(home:GetNumRealBuilding(H.buildings.LUNA)==1 and UnitCount(0)==1)
assert(not H.Command(0,'LUNA','REHOME'));Flush();assert(not ContextPtr.callback)
retained.Kill=kill;Events.SerialEventGameDataDirty();Flush();assert(UnitCount(0)==0)
-- A setter may commit and then report failure: readback keeps the new cooldown.
p.SetScriptData=function(self,value) save(self,value);error('after rehome save') end
assert(H.Command(0,'LUNA','REHOME'));p.SetScriptData=save
assert(s.cats.LUNA.status==1 and s.cats.LUNA.cooldown==H.Turn()+10 and UnitCount(0)==1)
assert(home:GetNumRealBuilding(H.buildings.LUNA)==0)
Reload();H=MapModData.THE11CATS;s=H.State(0)
assert(s.cats.LUNA.status==1 and s.cats.LUNA.cooldown==10 and UnitCount(0)==1)
local effects=H.Effects;local passes=0
H.Effects=function(pid) passes=passes+1;return effects(pid) end
H.Schedule();H.Reconcile(0,false);Flush();assert(passes==1,'synchronous reconciliation must consume redundant queued work')
H.Effects=effects
print('PASS silent/throwing save setters, identified/unidentified retained rollback births, guarded retries and unchanged cooldown/load')
