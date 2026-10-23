local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local p=Players[0];local home=City(0,1,10,10);local other=City(0,2,30,30);p.era=4;H.Reconcile(0,true);Flush()
local apply,cancel=home.DoCityEventChoice,home.DoCancelCityEventChoice
home.DoCityEventChoice=function() error('before growth activation') end
Settle('SISI',home);Flush();assert(home.growth==0 and not ContextPtr.callback)
home.DoCityEventChoice=apply;Events.SerialEventGameDataDirty();Flush();assert(home.growth==5 and home.applies==1)
-- Native effect can succeed and throw afterward: a retry must not stack it.
cancel(home,H.growth.SISI);home.DoCityEventChoice=function(self,id) apply(self,id);error('after growth activation') end
H.Effects(0);Flush();assert(home.growth==5 and home.applies==2)
home.DoCityEventChoice=apply;Settle('CHARLOTTE',home);Flush();assert(home.growth==10)
local count=home.applies;Reload();H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
assert(home.growth==10 and home.applies==count,'native active choices persist without reapplication')
H.Unit(H.State(0),'LUNA'):MoveTo(other) -- free a legal home arrival hex
home.DoCancelCityEventChoice=function(self,id) cancel(self,id);error('after growth cancellation') end
assert(H.Command(0,'CHARLOTTE','REHOME'));Flush();assert(home.growth==5 and not home:IsCityEventChoiceActive(H.growth.MOTHER_DAUGHTER))
home.DoCancelCityEventChoice=function() error('before growth cancellation') end
H.Unit(H.State(0),'BONNIE'):MoveTo({Plot=function() return Map.PlotDirection(30,30,0) end})
assert(H.Command(0,'SISI','REHOME'));Flush();assert(home.growth==5 and not ContextPtr.callback)
home.DoCancelCityEventChoice=cancel;Events.SerialEventGameDataDirty();Flush();assert(home.growth==0)
assert(H.State(0).cats.SISI.cooldown==10 and H.State(0).cats.CHARLOTTE.cooldown==10)
print('PASS before/after growth activation/cancellation faults, independent +5/+10 stacking, persisted choices and bounded repair')
