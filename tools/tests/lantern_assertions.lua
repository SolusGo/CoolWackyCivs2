LF_Tests={}
function LF_Tests.one_owned_trireme() LF_Load();LF_Guard();LF_Start();LF_Counts(1,0) end
function LF_Tests.two_ships_do_not_stack() LF_Load();LF_Guard();LF_Harbor.units[2]=LF_Unit();LF_Start();LF_Counts(1,0) end
function LF_Tests.adjacent_ship_is_not_center() LF_Load();LF_Adjacent=LF_Unit();LF_Start();LF_Counts(0,0) end
function LF_Tests.cargo_ship_rejected() LF_Load();LF_Harbor.units={LF_Unit(0,1,false)};LF_Start();LF_Counts(0,0) end
function LF_Tests.embarked_land_rejected() LF_Load();LF_Harbor.units={LF_Unit(0,0,true,true)};LF_Start();LF_Counts(0,0) end
function LF_Tests.embarked_even_if_sea_domain_rejected() LF_Load();LF_Harbor.units={LF_Unit(0,1,true,true)};LF_Start();LF_Counts(0,0) end
function LF_Tests.foreign_teammate_allied_units_rejected()
  for _,owner in ipairs({1,2,22}) do LF_Load();LF_Harbor.units={LF_Unit(owner)};LF_Start();LF_Counts(0,0) end
end
function LF_Tests.inland_rejected() LF_Load();LF_Guard();LF_Harbor.coast=false;LF_Start();LF_Counts(0,0) end
function LF_Tests.lighthouse_without_guard() LF_Load();LF_Harbor.buildings[2]=1;LF_Start();LF_Counts(0,0);assert(LF_Harbor.buildings[2]==1) end
function LF_Tests.lighthouse_combined() LF_Load();LF_Harbor.buildings[2]=1;LF_Guard();LF_Start();LF_Counts(1,1) end
function LF_Tests.enter_after_snapshot_waits()
  LF_Load();LF_Start();LF_Guard();GameEvents.UnitSetXY.Fire(0,1,0,0);LF_Counts(0,0)
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0);LF_Start();LF_Counts(1,0)
end
function LF_Tests.depart_after_snapshot_and_remove_next()
  LF_Load();LF_Harbor.buildings[2]=1;LF_Guard();LF_Start();LF_Counts(1,1)
  LF_Harbor.units={};GameEvents.UnitSetXY.Fire(0,1,1,0);LF_Counts(1,1)
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(1,1);LF_Start();LF_Counts(0,0)
end
function LF_Tests.lighthouse_built_after_snapshot_waits()
  LF_Load();LF_Guard();LF_Start();LF_Harbor.buildings[2]=1;GameEvents.CityConstructed.Fire(0,1,2);LF_Counts(1,0)
  LF_Start();LF_Counts(1,1)
end
function LF_Tests.save_load_retains_counts_and_receipt()
  LF_Load();LF_Harbor.buildings[2]=1;LF_Guard();LF_Start();LF_Harbor.units={}
  local data,writes=Players[0].data,LF_Writes
  ContextPtr={SetShutdown=function(self,f)self.shutdown=f end};LF_Load()
  Events.LoadScreenClose.Fire();Events.SequenceGameInitComplete.Fire();Events.AIProcessingStartedForPlayer.Fire(0)
  LF_Counts(1,1);assert(data==Players[0].data and writes==LF_Writes)
  LF_Start();LF_Counts(0,0)
end
function LF_Tests.capture_to_foreign_clears_immediately()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;LF_Start();LF_Counts(1,1)
  LF_Harbor.owner=1;GameEvents.CityCaptureComplete.Fire(0,false,0,0,1);LF_Counts(0,0)
end
function LF_Tests.capture_to_lantern_waits_for_actual_new_owner()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;LF_Start();LF_Harbor.owner=2
  Players[0].cities={};Players[2].cities={LF_Harbor};LF_Harbor.units={LF_Unit(2)}
  GameEvents.CityCaptureComplete.Fire(0,false,0,0,2);LF_Counts(0,0)
  LF_Start(2,false);LF_Counts(1,1)
end
function LF_Tests.later_warship_accepted() LF_Load();LF_Harbor.units={LF_Unit()};LF_Harbor.units[1].type='UNIT_BATTLESHIP';LF_Start();LF_Counts(1,0) end
function LF_Tests.non_lantern_no_bonuses_or_scriptdata()
  Players[0].civ=9;LF_Load();LF_Guard();local data=Players[0].data;LF_Start();LF_Counts(0,0);assert(data==Players[0].data)
end
function LF_Tests.ai_lantern_works() Players[0].human=false;LF_Load();LF_Guard();LF_Start();LF_Counts(1,0) end
function LF_Tests.dead_delayed_units_rejected()
  LF_Load();LF_Guard();LF_Harbor.units[1].dead=true;LF_Start();LF_Counts(0,0)
  LF_Harbor.units[1].dead=false;LF_Harbor.units[1].delayed=true;LF_Start();LF_Counts(0,0)
end
function LF_Tests.only_one_registration_and_shutdown()
  LF_Load();LF_Load();assert(#Events.AIProcessingStartedForPlayer.handlers==1 and #GameEvents.CityCaptureComplete.handlers==1)
  ContextPtr={SetShutdown=function(self,f)self.shutdown=f end};LF_Load()
  assert(#Events.AIProcessingStartedForPlayer.handlers==1 and #GameEvents.CityCaptureComplete.handlers==1)
  ContextPtr.shutdown();assert(#Events.AIProcessingStartedForPlayer.handlers==0 and #GameEvents.CityCaptureComplete.handlers==0)
end
function LF_Tests.no_late_payout_fallback_or_load_movement_hooks()
  LF_Load();assert(#GameEvents.PlayerDoTurn.handlers==0 and #GameEvents.UnitSetXY.handlers==0
    and #Events.LoadScreenClose.handlers==0 and #Events.ActivePlayerTurnStart.handlers==0)
end
function LF_Tests.inactive_and_tagged_progress_do_not_snapshot()
  LF_Load();LF_Guard();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
  Players[0].active=true;Events.AIProcessingStartedForPlayer.Fire(0,'progress');LF_Counts(0,0)
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(1,0)
end
function LF_Tests.city_actual_owner_checked() LF_Load();LF_Guard();LF_Harbor.owner=2;LF_Start();LF_Counts(0,0) end
function LF_Tests.midturn_context_without_receipt_does_not_evaluate()
  Players[0].active=true;LF_Guard();LF_Load();LF_Counts(0,0)
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0);LF_Start();LF_Counts(1,0)
end
function LF_Tests.multiple_cities_independent()
  LF_Load();LF_Guard();local other=LF_City(0,true);other.buildings[2]=1;Players[0].cities[2]=other
  LF_Start();LF_Counts(1,0);assert(other:GetNumRealBuilding(3)==0 and other:GetNumRealBuilding(4)==0)
end
