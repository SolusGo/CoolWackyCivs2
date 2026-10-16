-- A new game begins before the Settler founds a capital. Preparation retries
-- must still produce the FIRST match's Feast, with full announcement lead time.
local firstCities=Players[0].cities;Players[0].cities={};TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
assert(not s.feast and s.feastPending);Players[0].cities=firstCities
TEST.turnTo(3);assert(s.feast and not s.feastPending and s.feast.active==10)
local v=TEST.new('UNIT_MCPVP_VETERAN',8,7);TEST.flush();local r=M.Peek(s,v)
TEST.selected=v;TEST.loadUI();Controls.Open.click()
assert(not Controls.Panel.hidden and Controls.Summary.text:find('Server Legacy'))
Controls.QueueCTF.click();assert(s.queued=='CTF' and s.mode=='HG')
Controls.Kangaroo.click();assert(r.kit=='KANGAROO')
Events.AILeaderMessage();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.LeavingLeaderViewMode();assert(not Controls.Launcher.hidden)
TEST.cityScreen=true;Events.SerialEventGameDataDirty();assert(Controls.Launcher.hidden)
TEST.cityScreen=false;Events.SerialEventExitCityScreen();assert(not Controls.Launcher.hidden)
TEST.multiplayer=true;Events.SerialEventGameDataDirty();assert(Controls.Launcher.hidden and not M.Command(0,'QUEUE',nil,'SAB'))
TEST.multiplayer=false;Events.SerialEventGameDataDirty()
-- Two McPvP states are isolated, and overlapping city debuffs never stack or expire early.
Players[2].civ=GameInfoTypes.CIVILIZATION_MCPVP;TEST.city(2,1,1);local other=M.State(2);M.StartMatch(other)
M.Legacy(other,31);assert(s.current==0 and other.current==31)
local ref=M.CityRef(TEST.enemyCap);s.debuffs[ref.key]={target=ref,expires=5};other.debuffs[ref.key]={target=ref,expires=10}
M.Debuffs();assert(TEST.enemyCap:GetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE)==1)
TEST.turn=5;M.Debuffs();assert(TEST.enemyCap:GetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE)==1)
TEST.turn=10;M.Debuffs();assert(TEST.enemyCap:GetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE)==0)
-- Conservative AI uses actual objectives and movement, with no free completions.
Players[0].human=false;s.queued='CTF';M.StartMatch(s);v.moves=120
M.AITurn(s);assert(r.flag and s.captures==0)
assert(M.AIStep(v,TEST.cap:Plot())==false) -- initial action consumed all movement
v:SetXY(4,4);v.moves=120;TEST.flush();M.AITurn(s);assert(not r.flag and s.captures==1)
s.queued='SAB';M.StartMatch(s);v:SetXY(8,7);v.moves=120;TEST.flush();M.AITurn(s);assert(r.mission)
TEST.turnTo(s.start+1);assert(r.mission and s.missions==0)
TEST.turnTo(s.start+3);assert(s.missions==1 and not r.mission)
local ai=TEST.new('UNIT_MCPVP_VETERAN',4,4);TEST.flush();ai.moves=120;M.AITurn(s);assert(M.Peek(s,ai).kit=='KANGAROO')
-- Feast fallback: no valid land location is safe and still gives a playable cycle.
for i=0,Map.GetNumPlots()-1 do Map.GetPlotByIndex(i).hidden=true end
s.queued='HG';M.StartMatch(s);assert(not s.feast);TEST.turnTo(s.start+10)
assert(ai:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_FINAL))
TEST.flush();assert(not ContextPtr.update)
print('PASS McPvP Browser callbacks/visibility, multiple players, overlapping debuffs, autonomous AI objectives and no-site fallback')
