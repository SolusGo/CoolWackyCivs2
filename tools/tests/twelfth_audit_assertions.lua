-- Source-shaped regression cases. These are NOT engine save/load tests.
local function setup(turn)
 Players={};saved={};faults={};rawTurn=startTurn+turn-1
 ResetContext()
 local p=NewPlayer(0,true);p.active=true
 NewCity(p,0,true);NewCity(p,1,false)
 return p
end
local function assertPlayer(chime,tower)
 AssertBonus(Players[0].cities[0],chime,tower)
 AssertBonus(Players[0].cities[1],chime,0)
end
local function played() return rawTurn-startTurn+1 end

-- Manual/quicksave/context reload: restore BOTH city state and the database.
setup(6);LoadTwelfth();GameEvents.PlayerDoTurn.Fire(0)
local activeChime=SaveSnapshot()
assert(Players[0].notices==1)
rawTurn=rawTurn+1;GameEvents.PlayerDoTurn.Fire(0);assertPlayer(0,0)
for i=1,3 do
 LoadSnapshot(activeChime);Events.LoadScreenClose.Fire()
 assertPlayer(1,1);assert(Players[0].notices==1,'duplicate after real snapshot rewind')
end

-- Independent games at exactly the same turn, and earlier saves of one game.
-- The provider swaps per-save databases; the module must not cache a ledger globally.
setup(6);LoadTwelfth()
local beforeNotice=SaveSnapshot()
GameEvents.PlayerDoTurn.Fire(0);local gameA=SaveSnapshot()
GameEvents.PlayerDoneTurn.Fire(0);local interturnA=SaveSnapshot()
setup(6);LoadTwelfth();local gameB=SaveSnapshot()
assert(saved['TWELFTH:v1:notified:0']==nil and saved['TWELFTH:v1:staged:0']==nil)
for i=1,3 do
 LoadSnapshot(interturnA);assertPlayer(0,0)
 LoadSnapshot(gameB);assertPlayer(1,1);GameEvents.PlayerDoTurn.Fire(0)
 assert(Players[0].notices==1,'game A suppressed game B notification')
 LoadSnapshot(gameA);assertPlayer(1,1);GameEvents.PlayerDoTurn.Fire(0)
 assert(Players[0].notices==1)
 LoadSnapshot(beforeNotice);GameEvents.PlayerDoTurn.Fire(0)
 assert(Players[0].notices==1,'future data contaminated an earlier save')
end

-- CP autosaves BEFORE m_bTurnActive changes and BEFORE PlayerDoneTurn.
-- Read() restores active/end/auto flags; processedAutoMoves is rebuilt by updateMoves.
local function deactivateWithAutosave()
 local p=Players[0]
 p.endTurn=true;p.autoMoves=true;p.processedAutoMoves=true
 local autosave=SaveSnapshot() -- exact relevant source point: dummies NOT staged yet
 p.active=false;GameEvents.PlayerDoneTurn.Fire(0)
 return autosave
end
local function resumeNativeEndModel()
 local p=Players[0]
 assert(p.active and p.endTurn and p.autoMoves and not p.processedAutoMoves)
 -- This models the ordinary completed-automove path, not native mission/cancel behavior.
 p.processedAutoMoves=true
 if p.active and p.endTurn and p.processedAutoMoves then
  p.active=false;GameEvents.PlayerDoneTurn.Fire(0)
 end
end
for _,turn in ipairs({5,6,11,12}) do
 setup(turn);LoadTwelfth();GameEvents.PlayerDoTurn.Fire(0)
 local oldNotices=Players[0].notices
 local autosave=deactivateWithAutosave()
 local nextChime=(turn+1)%6==0
 assertPlayer(nextChime and 1 or 0,nextChime and 1 or 0)
 -- Snapshot is earlier than staging, even though the live database has advanced.
 LoadSnapshot(autosave)
 assertPlayer(turn%6==0 and 1 or 0,turn%6==0 and 1 or 0)
 resumeNativeEndModel()
 assertPlayer(nextChime and 1 or 0,nextChime and 1 or 0)
 local between=SaveSnapshot();LoadSnapshot(between)
 assertPlayer(nextChime and 1 or 0,nextChime and 1 or 0)
 rawTurn=rawTurn+1;local p=Players[0];p.active=true;p.endTurn=false;p.autoMoves=false
 -- No UI callback is flushed before settlement: staging must already be synchronous.
 local production,science=Harvest(p.cities[0])
 assert(production==(nextChime and 38.5 or 20) and science==(nextChime and 45 or 30))
 GameEvents.PlayerDoTurn.Fire(0)
 assert(played()==turn+1 and p.notices==oldNotices+(nextChime and 1 or 0))
end

-- New/old saves with absent keys repair state without migrating or clearing other mods.
setup(6);saved.UNRELATED_MOD='keep';LoadTwelfth();assertPlayer(1,1)
assert(saved.UNRELATED_MOD=='keep' and saved['TWELFTH:v1:staged:0']==nil)
local c=Players[0].cities[0];c.buildings[101]=8;c.buildings[102]=7
Events.SerialEventGameDataDirty.Fire();Flush();assertPlayer(1,1)
Players[0].cities[1]=nil -- deleted/razed city references are not retained
Events.SerialEventGameDataDirty.Fire();Flush()
rawTurn=rawTurn+1;GameEvents.PlayerDoTurn.Fire(0);AssertBonus(c,0,0)

-- A single transient exception must recover synchronously, before harvest.
for _,fault in ipairs({'open','read','write','setter'}) do
 setup(5)
 if fault=='open' then faults.open=true end
 LoadTwelfth()
 if fault~='open' then faults[fault]=true end
 GameEvents.PlayerDoneTurn.Fire(0)
 assertPlayer(1,1)
 rawTurn=rawTurn+1
 local production,science=Harvest(Players[0].cities[0])
 assert(production==38.5 and science==45,'transient fault deferred the sixth-turn bonus')
 assert(ContextPtr.callback==nil,'retry must not create permanent polling')
end
-- A failed notification must not be recorded as delivered.
setup(6);LoadTwelfth();faults.notice=true;GameEvents.PlayerDoTurn.Fire(0)
assert(Players[0].notices==1 and saved['TWELFTH:v1:notified:0']==rawTurn)
-- A save write fault AFTER notification delivery must not send it twice on retry.
setup(6);LoadTwelfth();faults.write=true;GameEvents.PlayerDoTurn.Fire(0)
assert(Players[0].notices==1 and saved['TWELFTH:v1:notified:0']==rawTurn)

-- Persistent errors have a fixed retry bound and cannot starve another player on load.
setup(6)
local failing=Players[0].cities[0];local setter=failing.SetNumRealBuilding
local attempts=0
function failing:SetNumRealBuilding(...) attempts=attempts+1;error('persistent city fault') end
local other=NewPlayer(2,true);local otherCity=NewCity(other,0,true)
LoadTwelfth();assert(attempts==2);AssertBonus(otherCity,1,1)
assert(ContextPtr.callback==nil)
failing.SetNumRealBuilding=setter
GameEvents.PlayerDoTurn.Fire(0);assertPlayer(1,1)
Flush();assert(ContextPtr.callback==nil)
print('PASS Twelfth audit models: snapshot rewind, same-turn games, pre-staging autosaves, absent keys, corruption cleanup, deletion, synchronous faults and notification recovery')
