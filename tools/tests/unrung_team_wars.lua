-- Teams differ from player IDs; two Unrung owners share a team and an enemy team
-- has two living members. Ordinary supported single-player remains unchanged.
Players[0].team=4;Players[1].team=5;Players[5].team=5
Players[4].civ=100;Players[4].human=true
local a,b=NewUnit(1,0),NewUnit(1,4)
LoadUnrung()
for turn=0,14 do
 now=turn;Players[0].active=true;GameEvents.PlayerDoTurn.Fire(0)
 Players[0].active=false;GameEvents.PlayerDoneTurn.Fire(0)
 if turn>=10 then
  Players[4].active=true;GameEvents.PlayerDoTurn.Fire(4)
  Players[4].active=false;GameEvents.PlayerDoneTurn.Fire(4)
 end
end
now=15
assert(Read(0).peace==15 and Read(4).peace==5)
-- Enemy changes its flag first: both owners must snapshot before their team flag changes.
Teams[5].wars[4]=true;Events.WarStateChanged.Fire(5,4,true)
assert(Read(0).toll==3 and Read(4).toll==1);CheckUnit(a,3);CheckUnit(b,1)
local first=saves.UNRUNG_STATE_V1_0
Teams[4].wars[5]=true;Events.WarStateChanged.Fire(4,5,true)
assert(saves.UNRUNG_STATE_V1_0==first,'reverse notification refreshed Toll')
-- Nested/simultaneous declarations: the second relationship must prevent an
-- early peace transition while the first relationship is being cleared.
Teams[2].wars[4]=true;Events.WarStateChanged.Fire(2,4,true)
Teams[4].wars[2]=true;Events.WarStateChanged.Fire(4,2,true)
Teams[5].wars[4]=false;Events.WarStateChanged.Fire(5,4,false)
assert(Read().war==1 and Read().toll==3)
Teams[4].wars[5]=false;Events.WarStateChanged.Fire(4,5,false)
assert(Read().war==1)
Teams[2].wars[4]=false;Events.WarStateChanged.Fire(2,4,false)
assert(Read(0).war==0 and Read(4).war==0);CheckUnit(a,0);CheckUnit(b,0)
Teams[4].wars[2]=false;Events.WarStateChanged.Fire(4,2,false)
-- Barbarian team notifications cannot consume or interrupt a peaceful window.
Teams[3].wars[4]=true;Events.WarStateChanged.Fire(3,4,true)
assert(Read().war==0)
Players[0].active=true;GameEvents.PlayerDoTurn.Fire(0)
Teams[4].wars[5]=true;Events.WarStateChanged.Fire(4,5,true)
Teams[5].wars[4]=true;Events.WarStateChanged.Fire(5,4,true)
Teams[4].wars[5]=false;Events.WarStateChanged.Fire(4,5,false)
Teams[5].wars[4]=false;Events.WarStateChanged.Fire(5,4,false)
Players[0].active=false;GameEvents.PlayerDoneTurn.Fire(0)
assert(Read().peace==0,'same-window war/peace incorrectly earned Quietude')
print('PASS nonmatching player/team IDs, two owner records, multi-member teams, reverse/duplicate/cascaded notifications and same-window wars')
