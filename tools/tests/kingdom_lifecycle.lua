local k=MapModData.CKPrayer;local p=Players[0];local s=TEST.pray()
-- Expiry must continue while a tracked human player is temporarily AI-controlled.
p.human=false;TEST.active=2;Events.GameplaySetActivePlayer()
assert(p.cap:bonus('YIELD_FAITH')==0 and not p.units[1]:IsHasPromotion(k.STAND))
local grace,stage,ready=s.grace,s.stage,s.ready
TEST.nextTurn(8)
assert(s.clock==TEST.turn,'tracked prayer clock stopped while control was nonhuman')
assert(s.grace==grace and s.stage==stage and s.ready==ready,'AI control must never progress prayers')
p.human=true;TEST.active=0;Events.GameplaySetActivePlayer()
assert(not k.Active(s,'address') and p.cap:bonus('YIELD_FAITH')==0,'expired blessing revived when human control returned')
TEST.reload();k=MapModData.CKPrayer;s=k.states[0];assert(not k.Active(s,'address'))
-- Existing ASK algorithm: full reserve follows legitimate capital changes, never a captor.
for i=2,3 do TEST.advance();TEST.pray() end;TEST.advance()
p.cap.queue='process';local food=p.cap.food;TEST.pray()
assert(p.cap.food==food+8 and s.bread==8)
local old=p.cap;local new=p.cities[2];new.production=39;new.needed=40;p.cap=new
GameEvents.CapitalChanged(0,new.id,old.id)
assert(s.bread==7 and new.production==40 and old.production==0,'reserve follows moved capital once')
table.remove(p.cities,2);Players[2].cities[#Players[2].cities+1]=new;new.plot.owner=2;p.cap=old;old.queue=nil
GameEvents.CityCaptureComplete(0,true,new.plot.x,new.plot.y,2)
local capturedProduction=new.production
assert(s.bread==7 and old.production==0)
TEST.reload();k=MapModData.CKPrayer;s=k.states[0];assert(s.bread==7)
old.queue='project';old.needed=100;Events.SerialEventCityInfoDirty()
assert(s.bread==0 and old.production==7 and new.production==capturedProduction,'reserve spent at captor or duplicated on reload')
local raw=p.script;assert(not k.Pray(0,4,0) and p.script==raw and old.food==food+8,'ASK request replay')
-- Grace and House effects remain exact after later capture/recapture and reload.
s.grace=7;k.Save(s);k.Sync(0,false);assert(old:bonus('YIELD_CULTURE')==7)
TEST.reload();k=MapModData.CKPrayer;s=k.states[0];assert(old:bonus('YIELD_CULTURE')==7)
p.alive=false;p.cap=nil;k.Sync(0,true);assert(not k.CanPray(0) and old:bonus('YIELD_CULTURE')==0)
print('PASS Kingdom nonhuman-control expiry, unchanged ASK capital/reserve/ownership/save rules, Grace and elimination')
