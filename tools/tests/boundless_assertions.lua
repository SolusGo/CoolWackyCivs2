local B=MapModData.BoundlessCity;local s=B.State(0)
local function Net(y) return (capital.misc[y] or 0)+(capital.terrain[y] or 0) end
local mine=Remote(24,5,{1,8,0,0,0,0});local farm=Remote(34,5,{5,0,0,0,0,0})
s.mode='MANUAL';s.selected[mine.n]=true;s.selected[farm.n]=true;s.locks[mine.n]=true;s.locks[farm.n]=true;B.Cache(s).force=true;B.Reconcile(s)
assert(s.reserved==2 and capital.defaults==2);capital:Check()
assert(capital:GetPopulation()==8 and capital:GetTotalSpecialistCount()==0)
assert(Net(0)==6 and Net(1)==6,'correct remote food/production minus two native labourer yields')
assert(B.Cache(s).remoteYields[2]==8)
local old=mutations;B.Reconcile(s);assert(mutations==old,'unchanged reconcile must not mutate native citizens')
local script=Players[0]:GetScriptData();local misc=Net(1)
B.States={};B.Caches={};B.Initialize(0);s=B.State(0)
assert(s.reserved==2 and Net(1)==misc,'reload must preserve exact yield ledger')
assert(s.locks[mine.n] and s.locks[farm.n])
mine.yields[2]=3;B.Cache(s).force=true;B.Reconcile(s);assert(Net(1)==1,'pillaging must update net production')
farm.owner=1;GameEvents.TileOwnershipChanged.Fire(farm.x,farm.y,1,0);Pump()
assert(s.reserved==1 and not s.assignments[farm.n] and Net(0)==1,'lost territory stops yielding')
assert(B.Action(0,'PLOT',mine.n));assert(s.reserved==0 and Net(0)==0 and Net(1)==0,'release removes all remote yields')
local water=Remote(44,5,{4,0,2,0,0,0});water.water=true
s.selected[water.n]=true;s.locks[water.n]=true;B.Cache(s).force=true;B.Reconcile(s);assert(s.assignments[water.n])
water.blockaded=true;B.Cache(s).force=true;B.Reconcile(s);assert(not s.assignments[water.n])
water.blockaded=false;Teams[0].waterWork=false;B.Cache(s).force=true;B.Reconcile(s);assert(s.reserved==0)
Teams[0].waterWork=true;water.water=false;water.mountain=true;B.Cache(s).force=true;B.Reconcile(s);assert(s.assignments[water.n],'yielding mountain wonders are native-workable')
water.yields={0,0,0,0,0,0};B.Cache(s).force=true;B.Reconcile(s);assert(s.reserved==0)
-- Population-limited assignments and a genuine native reservation ceiling, never invented workers.
s.selected={};s.locks={};s.excluded={};s.mode='MANUAL'
for x=20,39 do local p=Remote(x,8);s.selected[p.n]=true;s.locks[p.n]=true end
B.Cache(s).force=true;B.Reconcile(s);assert(s.reserved<=capital.pop and s.reserved==8);capital:Check()
-- Independent native starvation model removes a labourer before issuing the population event.
capital.pop=7;capital.defaults=capital.defaults-1;capital.forcedDefault=capital.forcedDefault-1
GameEvents.SetPopulation.Fire(capital.x,capital.y);Pump();assert(s.reserved<=7);capital:Check()
capital.pop=8;capital.defaults=capital.defaults+1;B.Cache(s).force=true;B.Reconcile(s);assert(s.reserved<=8);capital:Check()
-- Foreign civilizations receive no founding/training vetoes.
assert(B.IsBoundless(0) and not B.IsBoundless(1))
local unit=MakeUnit(1,400);GameEvents.UnitCreated.Fire(0,1);assert(unit.promotions[300])
local settler=MakeUnit(2,401);now=2;B.Turn(0);assert(settler.dead,'script-created extra settlers removed')
-- Reward once, including across reloads, replacements and repairs.
local reward=Remote(24,5);reward.improvement=500
GameEvents.PlayerBuilt.Fire(0,1,24,5,0);GameEvents.PlayerBuilt.Fire(0,1,24,5,1);GameEvents.PlayerBuilt.Fire(0,1,24,5,0)
assert(cultureAward==5)
B.States={};B.Caches={};B.Initialize(0);s=B.State(0);GameEvents.PlayerBuilt.Fire(0,1,24,5,0);assert(cultureAward==5)
-- Native script preserves unrelated mod data and supports restoring older native snapshots.
local snapshot=Players[0]:GetScriptData();Players[0].script='unrelated-mod-data;'..snapshot
B.Save(s);assert(Players[0].script:sub(1,19)=='unrelated-mod-data;')
local _,markers=Players[0].script:gsub('|BCSTATE1:', '');assert(markers==1,'duplicate native save marker')
local older=Players[0].script;local oldProgress=s.progress;s.progress=98765;B.Save(s)
Players[0].script=older;B.States={};assert(B.State(0).progress==oldProgress,'older saves must rewind custom state')
s=B.State(0)
-- Safe capture callback ordering: recovery runs after the native stack unwinds.
local extra=MakeCity(0,54,10,2,2);extra.original=1;extra.previous=1
Players[0].cities[#Players[0].cities+1]=extra
insideCapture=true;GameEvents.CityCaptureComplete.Fire(1,true,54,10,0);assert(#Players[0].cities==2)
insideCapture=false;Pump();assert(#Players[0].cities==1 and extra.owner==1 and extra.original==1)
assert(capital.owner==0,'original capital must never be returned')
Events.SerialEventCityInfoDirty.Fire();Pump();assert(deferred==nil,'no persistent update loop')
-- Idle AI Surveyors use legal native move/build missions; no imaginary order APIs.
Players[0].human=false
function unit:MovesLeft() return 60 end
function unit:IsBusy() return false end
function unit:GetPlot() return Map.GetPlot(24,5) end
function unit:CanBuild(plot,build) return build==0 and plot.owner==0 and not plot.water end
function unit:PushMission(kind,a,b) self.lastMission={kind,a,b} end
B.AIWorkers(s);assert(unit.lastMission and (unit.lastMission[1]==MissionTypes.MISSION_BUILD or unit.lastMission[1]==MissionTypes.MISSION_MOVE_TO))
local mission=unit.lastMission;function unit:IsBusy() return true end
B.AIWorkers(s);assert(unit.lastMission==mission,'busy Surveyor mission must not be overwritten')
Players[0].human=true
-- No safe recipient is a documented quarantine, never a protected-city deletion.
Players[1].IsAlive=function() return false end
local orphan=MakeCity(0,51,12,2,2);orphan.original=1;orphan.previous=1;orphan.protected=true;Players[0].cities[#Players[0].cities+1]=orphan
B.RecoverCities(s);assert(orphan.owner==0 and s.pending[Map.GetPlot(51,12).n])
-- Malformed native payload disables rather than creating a fresh workforce/reward bank.
Players[0].script='|BCSTATE1:4:bad!|';B.States={};assert(B.State(0).incompatible)
print('PASS workforce: evaluated yields, native census, starvation, growth, loss, water, blockade, release, reload and rewards')
print('PASS ownership: no-capture, extra Settlers, safe deferred recovery and original-capital protection')
print('PASS AI legal idle missions, busy-order preservation, safe orphan quarantine and corrupt-save rejection')
