local J=MapModData.JIN
Complete('GREAT_PASTURE');Complete('MOUNTAIN_HALL');Complete('PAGODA_FOREST')
local s=J.State(0);s.grass.pasture.horses=5;s.karma=500;J.Save(0,s)
local cavalry=Spawn('IRON_PAGODA',9,8);cavalry.damage=100
local writes,reads=0,0;local set=cavalry.SetHasPromotion;local has=cavalry.IsHasPromotion
cavalry.SetHasPromotion=function(self,...)writes=writes+1;return set(self,...)end
cavalry.IsHasPromotion=function(self,...)reads=reads+1;return has(self,...)end
for i=1,100 do J.SyncUnit(0,cavalry,J.State(0))end
assert(writes==0 and reads<2000,'unchanged HP rebuilt bank')
s=J.State(0);s.grass.pasture.horses=4;J.Save(0,s);J.SyncUnit(0,cavalry,s)
assert(writes==2 and cavalry:GetMaxHitPoints()==108 and cavalry.damage==98,'delta or absolute living HP incorrect')
-- Unsaved snapshots cannot mutate cached state; identical saves neither encode nor write.
local snap=J.State(0);snap.karma=12;assert(J.State(0).karma==500)
local encodes=0;local encode=J.S.Encode;J.S.Encode=function(...)encodes=encodes+1;return encode(...)end
for i=1,100 do J.Save(0,J.State(0))end;assert(encodes==0);J.S.Encode=encode
-- Distant actual enemy units reuse a derived coverage index, with no state decode/rebuild.
War(0,1,true);local enemy=Spawn('UNIT_WARRIOR',23,23,1);J.Spatial(0)
local builds=0;local placements=J.Emplacements;J.Emplacements=function(...)builds=builds+1;return placements(...)end
for i=1,1000 do J.Movement(1,enemy.id,23,23)end;assert(builds==0)
local fort=Map.GetPlot(20,20);fort:SetImprovementType(J.T.IMPROVEMENT_FORT);J.Spatial(0);assert(builds==1)
-- Native trade retirement is not a casualty; explicit plunder deducts exactly once.
local trader=Spawn('REINDEER_TRADER');trader:Kill(true,-1);assert(J.State(0).karma==500)
trader=Spawn('REINDEER_TRADER');trader:Kill(false,-1);assert(J.State(0).karma==500)
GameEvents.PlayerPlunderedTradeRoute.Fire(1,enemy.id,100,0,cap.id,2,minor.id,0,0)
assert(J.State(0).karma==500-J.C.karmaDeath)
GameEvents.PlayerPlunderedTradeRoute.Fire(1,enemy.id,100,0,cap.id,2,minor.id,0,0);assert(J.State(0).karma==500-J.C.karmaDeath)
-- Structurally invalid nested data preserves exact raw data and disables stale bonuses.
local valid=Players[0].raw
local temporary=Spawn('DEFENDER',9,9);J.S.Write(temporary,'JIN_D1',{owner=0,plot=cap:Plot().index,expires=now+4});temporary.fighting=true
s=J.State(0);s.grass.pasture.horses=6;J.S.Write(Players[0],'JIN_P1',s);local bad=Players[0].raw
assert(not J.State(0) and Players[0].raw==bad and cavalry:GetMaxHitPoints()==100)
assert(not temporary.dead);temporary.fighting=false;assert(not J.State(0) and temporary.dead and Players[0].raw==bad)
Players[0].raw=valid;LoadJin();J=MapModData.JIN;assert(J.State(0) and cavalry:GetMaxHitPoints()==108)
-- Closed UI never allocates rows; bursts coalesce; rendering errors always release guard.
LoadJinUI();local resets=0;local reset=uiManager.ResetInstances;uiManager.ResetInstances=function(self)resets=resets+1;return reset(self)end
for i=1,100 do Events.SerialEventGameDataDirty.Fire()end;Pump();assert(resets==0)
Controls.Open.callback();local before=resets
for i=1,100 do Events.SerialEventGameDataDirty.Fire()end;Pump();assert(resets==before)
Controls.EmissariesTab.callback();before=resets
for i=1,100 do GameEvents.UnitSetXY.Fire(1,enemy.id,23,23)end;Pump();assert(resets==before+1,'foreign Bribe targets did not coalesce/invalidate visible tab')
local get=uiManager.GetInstance;uiManager.GetInstance=function()error('injected UI failure')end
local originalPrint=print;local logged=false;print=function(msg)logged=tostring(msg):find('UI refresh',1,true)~=nil end
J.UIRefresh();print=originalPrint;assert(logged);uiManager.GetInstance=get;J.UIRefresh();assert(#uiManager.rows>0)
active=1;Events.GameplaySetActivePlayer.Fire();assert(Controls.Panel.hidden and Controls.Open.hidden)
-- Shutdown clears queued jobs and event ownership; the replacement context reconstructs state.
active=0;J.QueuePatrol(0);local handlers=#GameEvents.PlayerDoTurn.handlers;J.context.shutdown()
assert(not deferred and not MapModData.JIN);GameEvents.UnitSetXY.Fire(1,enemy.id,23,23)
LoadJin();J=MapModData.JIN;assert(#GameEvents.PlayerDoTurn.handlers==handlers and J.State(0))
print('PASS Jin hardening: HP deltas/health, immutable state snapshots/unchanged saves, cached distant movement/invalidation, trade Karma lifecycle, nested corruption, UI coalescing/error recovery/switch and shutdown')
