TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
local function reset(mode)
 local all={};for _,u in pairs(TEST.units) do all[#all+1]=u end;for _,u in ipairs(all) do u:Kill(false,-1) end
 for n=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(n)
  p.water=false;p.mountain=false;p.blocked=false;p.hidden=false;p.danger=0;p.owner=p.city and p.city.pid or -1
 end
 M.navigation={};Players[0].human=true;TEST.turn=0;s.queued=mode;M.StartMatch(s)
end
local function veteran(x,y,kit)
 local u=TEST.new('UNIT_MCPVP_VETERAN',x,y);TEST.flush()
 if kit then assert(M.SelectKit(s,u,kit));u.moves=u:MaxMoves() end
 return u,M.Peek(s,u)
end
local function aiTurn(turn,u)
 TEST.turn=turn;u.moves=u:MaxMoves();u.attacked=false;M.UpdateMissions(s);M.AITurn(s);TEST.flush()
end
-- Recon units can play BOTH CTF and Sabotage; route checks must not drop CTF.
reset('CTF');local scout=veteran(8,7,'KANGAROO');s.cycle=2;assert(M.AIMode(s)=='CTF')
s.cycle=3;assert(M.AIMode(s)=='SAB')
-- Hardcore: follow real movement around a wall, arriving during the active window.
reset('HG');local u,r=veteran(2,3,'KANGAROO');local legacyBeforeFeast=s.current
for y=0,6 do Map.GetPlot(3,y).mountain=true end
local feast=Map.GetPlot(7,3);s.feast={plot=feast:GetPlotIndex(),active=10,expires=15,status='PREPARING',announced=true}
Players[0].human=false
for turn=7,14 do TEST.turn=turn;M.UpdateFeast(s);aiTurn(turn,u);if s.feast.status=='CLAIMED' then break end end
assert(s.feast.claimant==0 and u:GetPlot()==feast and s.current==legacyBeforeFeast+15,'AI must claim through actual occupancy, never a free award')
-- The last active turn still contains a legal current-turn move and claim.
reset('HG');u,r=veteran(7,4,'KANGAROO');Players[0].human=false
s.feast={plot=Map.GetPlot(8,4):GetPlotIndex(),active=10,expires=15,status='ACTIVE',announced=true}
aiTurn(14,u);assert(s.feast.claimant==0,'Do not discard a feasible last-turn Feast claim')
-- CTF: steal, navigate a detour to safe friendly land, then perform Return Flag.
reset('CTF');u,r=veteran(8,7,'KANGAROO');Players[0].human=false;local legacyBeforeFlag=s.current
M.AITurn(s);assert(r.flag and s.captures==0)
local attacks=TEST.attackOrders or 0
for y=3,9 do Map.GetPlot(6,y).mountain=true end -- route home must go around the northern end
Map.GetPlot(5,3).owner=0;Map.GetPlot(5,3).danger=150 -- a lethal shortcut must be rejected
for turn=1,18 do aiTurn(turn,u);if s.captures>0 then break end end
-- SetMadeAttack(true) deliberately exhausts a carrier's attacks; count actual
-- attack ORDERS instead of confusing that native guard with an executed attack.
assert(s.captures==1 and not r.flag and s.current==legacyBeforeFlag+25 and (TEST.attackOrders or 0)==attacks,'Flag Carrier must return without issuing attacks')
-- A flag-bearing Veteran with no kit must return, rather than get stuck retrying kit selection.
reset('CTF');u,r=veteran(8,7);assert(M.Objective(s,u,'STEAL',M.ObjectiveTargets(s,u,'STEAL')[1]))
u:SetXY(4,4);u.moves=u:MaxMoves();TEST.flush();Players[0].human=false;M.AITurn(s)
assert(s.captures==1 and not r.flag and not r.kit)
-- Sabotage: approach a reachable operational tile, start a real mission, hold it.
reset('SAB');u,r=veteran(2,3,'KANGAROO');local legacyBeforeMission=s.current
for y=0,6 do Map.GetPlot(3,y).mountain=true end
Players[0].human=false
local startPlot
for turn=1,15 do aiTurn(turn,u);if r.mission then startPlot=u:GetPlot();break end end
assert(r.mission and M.Distance(u,TEST.enemyCap)<=2 and s.missions==0)
local finish=r.mission.finish
for turn=TEST.turn+1,finish-1 do aiTurn(turn,u);assert(r.mission and u:GetPlot()==startPlot and u.moves==0) end
aiTurn(finish,u);assert(s.missions==1 and not r.mission and s.current==legacyBeforeMission+20)
-- AI declines an infiltration which would be cancelled at the cycle boundary.
reset('SAB');u,r=veteran(8,7,'KANGAROO');Players[0].human=false
aiTurn(s.finish-M.Turns(3),u);assert(not r.mission)
-- Invalidated cities cancel only our queued step, with no rewards or stale path.
reset('CTF');u,r=veteran(2,3,'KANGAROO');u.rejectMove=true;Players[0].human=false
M.AITurn(s);assert(u:LastMissionPlot())
local before=s.current;TEST.enemyCap.pid=2;Players[1].cities={};Players[2].cities={TEST.enemyCap};TEST.enemyCap:Plot().owner=2
Teams[0].wars={[1]=true};TEST.turn=1;M.AITurn(s);assert(not u:LastMissionPlot() and s.current==before and not r.flag)
TEST.enemyCap.pid=1;Players[1].cities={TEST.enemyCap};Players[2].cities={};TEST.enemyCap:Plot().owner=1;Teams[0].wars=nil
-- Pathfinding budgets are shared across the army and repeated calls in one turn.
reset('HG');Players[0].human=false
s.feast={plot=Map.GetPlot(9,3):GetPlotIndex(),active=10,expires=15,status='PREPARING',announced=true}
TEST.turn=7;local beforeCalls=M.navStats.native;local beforeNodes=M.navStats.nodes
for i=1,12 do TEST.new('UNIT_WARRIOR',1,2) end;TEST.flush()
M.AITurn(s);TEST.flush();M.AITurn(s);TEST.flush()
assert(M.navStats.native-beforeCalls<=6 and M.navStats.nodes-beforeNodes<=640 and M.NavContext(0).planned<=4)
assert(not ContextPtr.update,'Event-driven movement must leave no idle update loop')
print('PASS McPvP AI objectives: real Feast/flag/infiltration actions, detours, carrier survival, no-kit carriers, mission holds, target invalidation and shared army budgets')
