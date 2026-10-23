local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local p=Players[0];local a=City(0,1,10,10);local b=City(0,2,20,20)
p.era=5;H.Reconcile(0,true);local s=H.State(0)
Settle('APPA',a);Settle('LOKI',a);Settle('OSCAR',b)
local report=H.BondReport(s,'SISTERS_BED')
assert(not report.active and report.target==a and report.status:find('OSCAR',1,true))
assert(report.requirements:find('OTHER_HOME:Home 2',1,true))
local count=#p.notifications
assert(H.Command(0,'OSCAR','REHOME'));Advance(10);H.Reconcile(0,false);Settle('OSCAR',a)
assert(H.BondReport(s,'SISTERS_BED').active and #p.notifications==count+2,'one settle and one first bond message')
count=#p.notifications;local core=p.script:match('|THE11CATS1:([^|]*)|')
for i=1,50 do H.Effects(0);H.BondReport(s,'SISTERS_BED') end
assert(#p.notifications==count)
Reload();H=MapModData.THE11CATS;H.InterfaceReady=function() return true end;s=H.State(0)
assert(#p.notifications==count and p.script:match('|THE11CATS1:([^|]*)|')==core)
assert(H.Command(0,'OSCAR','REHOME'));Advance(10);H.Reconcile(0,false);Settle('OSCAR',a)
assert(#p.notifications==count+1,'same bond/city never repeats after reactivation')
-- A presentation preference must never change the primary gameplay block.
core=p.script:match('|THE11CATS1:([^|]*)|');H.ToggleFeedback(s)
assert(p.script:match('|THE11CATS1:([^|]*)|')==core and not H.Notices(s).enabled)
count=#p.notifications;Settle('MAX',b);assert(#p.notifications==count)
Reload();H=MapModData.THE11CATS;s=H.State(0);assert(not H.Notices(s).enabled)
-- A genuine v1 save without the new sidecar is accepted and silently baselined.
p.script=p.script:gsub('|THE11CATS_N1:[^|]*|','');count=#p.notifications;core=p.script:match('|THE11CATS1:([^|]*)|')
Reload();H=MapModData.THE11CATS;s=H.State(0)
assert(p.script:match('|THE11CATS1:([^|]*)|')==core and #p.notifications==count)
assert(H.BondReport(s,'SISTERS_BED').active)
-- Presentation-only save faults retain a dirty retry; no unsaved bond message.
local save=p.SetScriptData;H.Notices(s).seen[H.CityKey(a)]=0;count=#p.notifications
p.script=p.script:gsub('|THE11CATS_N1:[^|]*|','')
p.SetScriptData=function() error('before narrative save') end
H.NoteBonds(s,a,{SISTERS_BED=true});assert(H.Notices(s).dirty and #p.notifications==count)
p.SetScriptData=save;Flush();assert(not H.Notices(s).dirty)
H.Notices(s).seen[H.CityKey(a)]=0;p.script=p.script:gsub('|THE11CATS_N1:[^|]*|','')
p.SetScriptData=function(self,value) save(self,value);error('after narrative save') end
H.NoteBonds(s,a,{SISTERS_BED=true});assert(not H.Notices(s).dirty and #p.notifications==count+1)
p.SetScriptData=save
-- Unknown presentation versions do not disable or rewrite valid gameplay.
p.script=p.script:gsub('|THE11CATS_N1:[^|]*|','')..'|THE11CATS_N2:future|'
Reload();H=MapModData.THE11CATS;s=H.State(0)
assert(s and not H.failed[0] and not H.Notices(s).valid and p.script:find('|THE11CATS_N2:future|',1,true))
print('PASS bond diagnostics, one-time per-home feedback, optional messages and untouched v1/future-sidecar save compatibility')
