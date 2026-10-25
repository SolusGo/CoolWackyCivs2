local u=NewUnit(1,0);LoadUnrung();PeaceTurns(15)
Begin();WarWith(1,true);assert(Read().windows==0);CheckUnit(u,3)
local activated=saves.UNRUNG_STATE_V1_0;NewContext();LoadUnrung()
assert(saves.UNRUNG_STATE_V1_0==activated,'reload immediately after declaration cannot consume again')
GameEvents.PlayerDoTurn.Fire(0);Done();assert(Read().windows==0,'activation partial turn not counted')
now=now+1
for window=1,5 do
 Begin();assert(Read().windows==window);CheckUnit(u,3)
 local raw=saves.UNRUNG_STATE_V1_0
 local old=ContextPtr;NewContext();LoadUnrung();old.shutdown()
 assert(saves.UNRUNG_STATE_V1_0==raw,'load must not extend/shorten window')
 GameEvents.PlayerDoTurn.Fire(0);assert(saves.UNRUNG_STATE_V1_0==raw)
 if window==2 then WarWith(2,true);assert(Read().windows==2) end
 Done();CheckUnit(u,3)
 for i=1,5 do GameEvents.PlayerDoTurn.Fire(i);GameEvents.PlayerDoneTurn.Fire(i) end
 CheckUnit(u,3);now=now+1
end
Begin();assert(Read().toll==0 and Read().war==1);CheckUnit(u,0);Done();now=now+1
WarWith(2,false);WarWith(2,true);assert(Read().toll==0,'continuous war cannot reactivate')
WarWith(1,false);WarWith(2,false);PeaceTurns(5)
WarWith(2,true,true);assert(Read().toll==1 and Read().windows==0)
Begin();assert(Read().windows==1,'off-turn activation covers the next full owner window')
print('PASS five complete start-to-start windows, partial turn, interturn defense, expiration, additional wars, context/save reconstruction')
