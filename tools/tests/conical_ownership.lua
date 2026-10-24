local p=Player(0,true);local cap=City(p,0,true,true);p.capital=cap
local c=City(p,1,true,true)
local f=Player(1,false);f.capital=City(f,0,true,false)
local other=Player(2,true);other.capital=City(other,0,true,true)
LoadConical()
-- Native-shaped acquisition flags differ, but cleanup must read the actual owner.
for _,conquest in ipairs({true,false}) do
  Transfer(c,f);GameEvents.CityCaptureComplete.Fire(0,false,c.x,c.y,1,5,conquest,0,0)
  Check(c,0,1,0)
  Transfer(c,p);GameEvents.CityCaptureComplete.Fire(1,false,c.x,c.y,0,5,conquest,0,0)
  Check(c,2,2,2)
end
-- Liberation reconstructs the city through acquireCity; test both destinations.
Transfer(c,f);Transfer(c,other);Check(c,2,2,2)
Transfer(c,f);Check(c,0,1,0)
-- Capturing the original Capital makes the former normal city the new Capital.
local remaining=City(p,3,true,true)
Transfer(cap,f);p.capital=remaining;GameEvents.CapitalChanged.Fire(0,remaining.id,cap.id)
Check(cap,0,1,0);Check(remaining,0,1,0)
local newCapital=City(p,4,true,true)
p.capital=newCapital;GameEvents.CapitalChanged.Fire(0,newCapital.id,remaining.id)
Check(remaining,2,2,2);Check(newCapital,0,1,0)
-- Real Office presence, not free-building state, controls Gold eligibility.
remaining.b[O]=0;remaining.freeOffice=true
Events.SpecificCityInfoDirty.Fire(0,remaining.id);Check(remaining,2,1,0)
remaining.b[O]=1;GameEvents.CityConstructed.Fire(0,remaining.id,O,false,false);Check(remaining,2,2,2)
-- Native CityRazed is PRE-disband. Follow with removal and a no-Capital state.
GameEvents.CityRazed.Fire(0,newCapital.x,newCapital.y)
plots[newCapital.x..':'..newCapital.y]=nil
p.cities={};p.capital=nil;p.alive=false
GameEvents.CityRazed.Fire(0,newCapital.x,newCapital.y);GameEvents.PlayerDoTurn.Fire(0)
GameEvents.CityCaptureComplete.Fire(0,true,newCapital.x,newCapital.y,1,1,true)
-- Reconstituted native objects in a reload replace any prior references entirely.
local replacement=Player(0,true);replacement.capital=City(replacement,0,true,true)
local acquired=City(replacement,1,true,true)
RecreateConical(false,true,true);Check(acquired,2,2,2)
Check(replacement.capital,0,1,0)
-- Temporarily unavailable Players is safe and later init reconstructs state.
local available=Players;Players=nil;Events.SequenceGameInitComplete.Fire()
Players=available;Events.LoadScreenClose.Fire();Check(acquired,2,2,2)
print('PASS Conical conquest/gift/liberation-shaped transfers, Capital capture/relocation, real Office semantics, pre-disband/last-city loss and reload over replacement objects (synthetic)')
