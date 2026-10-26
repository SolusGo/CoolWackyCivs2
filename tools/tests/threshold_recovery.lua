local T=Court();local p=Players[0]
local failures=0
p.onWrite=function(self,raw)
 local block=raw:match('%[THC_P1:([^%]]*)%]')
 if block and block:match('^101:100:0:') and failures<2 then failures=failures+1;error('retain confirmed receipt')end
end
assert(not T.Transfer(0,0,Snapshot(unit,origin),119,75))
assert(p.gold==900 and T.State(0)[3]==2)
p.onWrite=nil
NextTurn(101)
assert(unit.moves==180 and unit.attacks==0,'late receipt recovery must not exhaust the next owner-turn')
assert(not T.Locked(unit) and p.gold==900 and T.State(0)[3]==0)
-- Recovery before arrival restores old moves only within that same owner-turn.
local prepared=T.State(0)
prepared[3]=1;prepared[4]=unit.id;prepared[5]=unit.born;prepared[6]=unit.x;prepared[7]=unit.y
prepared[8]=15;prepared[9]=26;prepared[10]=T.CityState(destination)[1];prepared[11]=101
prepared[12]=100;prepared[13]=900;prepared[14]=unit.kind;prepared[15]=20;prepared[16]=0
assert(T.Save(0,prepared));assert(T.Write(unit,'THC_U1',{0,101,unit.born,unit.kind}));unit:SetHasPromotion(T.EXHAUSTED,true)
NextTurn(102)
assert(unit.moves==180 and unit.attacks==0 and p.gold==900 and T.State(0)[3]==0)
-- A confirmed arrival is not charged twice when its old origin is captured
-- or the receiving House is later removed. Never stamp the new owner/city.
local count=0
p.onWrite=function(self,raw)
 if raw:match('%[THC_P1:103:102:0:') and count<2 then count=count+1;error('retain captured-origin receipt')end
end
assert(not T.Transfer(0,0,Snapshot(unit,destination),15,26));assert(p.gold==800)
p.onWrite=nil;destination.owner=1;GameEvents.CityCaptureComplete.Fire(0,false,119,75,1)
third.house=0;assert(T.Recover(0));assert(p.gold==800 and T.CityState(destination)[6]==0)
third.house=1;destination.owner=0;GameEvents.CityCaptureComplete.Fire(1,false,119,75,0)
NextTurn(103)
-- A disappeared unit or reused ID cannot be substituted into a saved receipt.
local pending=T.State(0);pending[3]=1;pending[4]=unit.id;pending[5]=unit.born
pending[6]=15;pending[7]=26;pending[8]=119;pending[9]=75;pending[10]=T.CityState(third)[1]
pending[11]=103;pending[12]=100;pending[13]=800;pending[14]=unit.kind;pending[15]=88;pending[16]=0
assert(T.Save(0,pending));local pendingRaw=p.raw;p.units[0]=nil
assert(not T.Recover(0) and p.raw==pendingRaw and p.gold==800)
local replacement=Unit(p,0,15,26);replacement.born=8
assert(not T.Recover(0) and p.raw==pendingRaw and replacement.moves==180 and p.gold==800)
Place(replacement,90,90);p.units[0]=unit;assert(T.Recover(0));assert(unit.moves==88)
-- An engine returning an unexpected location is quarantined, never paid or
-- accepted as an adjacent-tile fallback. Its next owner-turn is still normal.
unit.moveFault='adjacent';local oldLast=T.State(0)[1]
assert(not T.Transfer(0,0,Snapshot(unit,third),119,75))
assert(unit.x==120 and p.gold==800 and T.CityState(third)[6]==0 and T.State(0)[1]==oldLast and T.State(0)[3]==1)
NextTurn(104);assert(unit.moves==180 and unit.attacks==0 and not T.Locked(unit))
Place(unit,15,26);assert(T.Recover(0));assert(unit.moves==180 and p.gold==800)
-- Numeric but semantically impossible receipts must fail closed, untouched.
local invalid=T.State(0);invalid[1]=105;invalid[3]=2;invalid[4]=unit.id;invalid[5]=unit.born
invalid[6]=3;invalid[7]=4;invalid[8]=unit.x;invalid[9]=unit.y
invalid[10]=1;invalid[11]=104;invalid[12]=0;invalid[13]=800;invalid[14]=unit.kind
assert(T.Save(0,invalid));local raw=p.raw
assert(T.State(0)==nil,'zero-cost confirmed receipt is corrupt, not a free crossing')
assert(p.raw==raw and p.gold==800)
-- A corrupted financial ledger still blocks portals, but a verified owner
-- turn can expire an independent, valid unit stamp without resetting it.
assert(T.Write(unit,'THC_U1',{0,104,unit.born,unit.kind}));unit:SetHasPromotion(T.EXHAUSTED,true)
NextTurn(105)
assert(not T.Locked(unit) and unit.moves==180 and unit.attacks==0,'invalid player ledger must not make valid exhaustion permanent')
assert(p.raw==raw and p.gold==800 and T.State(0)==nil)
print('PASS delayed receipt recovery, captured/removed endpoints, disappearance/ID reuse, unexpected-location quarantine, once-only payment and semantic corruption')
