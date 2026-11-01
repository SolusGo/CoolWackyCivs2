-- Additional scenarios run the shipped controller. API faults wrap the same
-- mock setters/getters, including explicit before- and after-mutation failures.
local function First(ai)
  LF_Turn,LF_StartTurn,LF_Loaded=0,0,false
  Players[0].active=true;Players[0].human=not ai
  LF_Guard();LF_Harbor.buildings[2]=1
end
local function FailBuilding(city,building,permanent,after)
  local original=city.SetNumRealBuilding
  local hits=0
  city.SetNumRealBuilding=function(self,id,n)
    if id==building and (permanent or hits==0) then
      hits=hits+1
      if after then original(self,id,n) end
      error('injected building '..id..(after and ' AFTER write' or ' BEFORE write'))
    end
    return original(self,id,n)
  end
  return function()city.SetNumRealBuilding=original end
end
local function OtherCity()
  local city=LF_City(0,true);city.units={LF_Unit()};city.buildings[2]=1
  Players[0].cities[#Players[0].cities+1]=city
  return city
end
local function Pending()return Players[0].data:find('|S|',1,true)~=nil end
local function NoPending()assert(not Pending(),'frozen plan should be committed')end
local function RestartContext()
  ContextPtr={SetShutdown=function(self,f)self.shutdown=f end};LF_Load()
end
function LF_Tests.first_legitimate_human_notification_not_consumed_by_init()
  First(false);LF_Load();LF_Counts(0,0);assert(not Players[0].data:find('[LANTERN1|0]',1,true))
  LF_Start(0,false);LF_Counts(1,1);NoPending()
end
function LF_Tests.first_legitimate_scenario_ai_notification_not_consumed_by_init()
  First(true);LF_Load();LF_Start(0,false);LF_Counts(1,1)
end
function LF_Tests.context_before_notification_and_recreated_before_first_boundary()
  First(false);LF_Load();RestartContext();LF_Counts(0,0);LF_Start(0,false);LF_Counts(1,1)
end
function LF_Tests.active_midturn_new_game_context_without_receipt_is_blocked()
  LF_Loaded=false;Players[0].active=true;LF_Guard();LF_Load()
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
  LF_Start();LF_Counts(1,0)
end
function LF_Tests.first_turn_saved_game_missing_receipt_does_not_qualify_on_reactivation()
  First(false);LF_Loaded=true;LF_Load();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
  LF_Start();LF_Counts(1,1)
end
function LF_Tests.legacy_current_receipt_and_counts_are_retained()
  First(false);Players[0].data='other[LANTERN1|0]suffix'
  LF_Harbor.buildings[3]=1;LF_Harbor.buildings[4]=1;LF_Harbor.units={}
  LF_Load();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(1,1);assert(Players[0].data=='other[LANTERN1|0]suffix')
end
function LF_Tests.malformed_receipt_quarantined_without_midturn_snapshot()
  Players[0].active=true;Players[0].data='prefix[LANTERN1|broken]suffix';LF_Guard()
  LF_Load();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
  assert(Players[0].data:find('prefix[LANTERN_QUARANTINE1|broken]suffix',1,true))
  LF_Start();LF_Counts(1,0)
end
function LF_Tests.duplicate_receipts_quarantined_and_next_turn_recovers()
  Players[0].active=true;Players[0].data='[LANTERN1|8][LANTERN1|9]';LF_Load();LF_Guard()
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0);LF_Start();LF_Counts(1,0)
end
function LF_Tests.truncated_receipt_quarantined_and_next_turn_recovers()
  Players[0].active=true;Players[0].data='unrelated[LANTERN1|not-closed';LF_Load();LF_Guard()
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0);LF_Start();LF_Counts(1,0)
end
function LF_Tests.future_save_version_preserved_and_disabled()
  Players[0].data='other[LANTERN10|future]';LF_Load();LF_Guard();LF_Start();LF_Counts(0,0)
  assert(Players[0].data=='other[LANTERN10|future]')
end
function LF_Tests.future_turn_receipt_is_not_a_permanent_lockout()
  Players[0].active=true;Players[0].data='[LANTERN1|9999]';LF_Load();LF_Guard()
  LF_Start();LF_Counts(1,0)
end
function LF_Tests.partial_snapshot_one_dummy_retries_without_requalifying()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;FailBuilding(LF_Harbor,4,false,false)
  LF_Start();LF_Counts(1,1);assert(LF_Qualifies==1);NoPending()
end
function LF_Tests.partial_snapshot_after_one_city_uses_frozen_targets()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local other=OtherCity()
  local release=FailBuilding(other,3,true,false)
  LF_Start();LF_Counts(1,1);assert(Pending() and not Players[0].data:find('[LANTERN1|11]',1,true))
  LF_Harbor.units={};other.units={};local reads=LF_Qualifies
  release();Events.AIProcessingStartedForPlayer.Fire(0)
  assert(other:GetNumRealBuilding(3)==1 and other:GetNumRealBuilding(4)==1)
  LF_Counts(1,1);assert(LF_Qualifies==reads);NoPending()
end
function LF_Tests.failed_second_dummy_and_ship_movement_do_not_change_target()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local release=FailBuilding(LF_Harbor,4,true,false)
  LF_Start();LF_Counts(1,0);assert(Pending());LF_Harbor.units={};local reads=LF_Qualifies
  release();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(1,1);assert(reads==LF_Qualifies)
end
function LF_Tests.failed_zero_target_does_not_admit_a_late_ship()
  LF_Harbor.buildings[3]=1;LF_Harbor.buildings[4]=1;LF_Harbor.buildings[2]=1
  LF_Load();local release=FailBuilding(LF_Harbor,3,true,false);LF_Start();assert(Pending())
  LF_Guard();release();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
end
function LF_Tests.setter_error_after_native_mutation_is_acknowledged_once()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;FailBuilding(LF_Harbor,3,false,true)
  LF_Start();LF_Counts(1,1);assert(LF_Writes==2);NoPending()
end
function LF_Tests.failed_scriptdata_write_after_mutation_does_not_lose_plan()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1
  local original=Players[0].SetScriptData;local once=true
  Players[0].SetScriptData=function(p,data)original(p,data);if once then once=false;error('injected AFTER ScriptData write')end end
  LF_Start();LF_Counts(1,1);NoPending()
end
function LF_Tests.unsaved_frozen_plan_never_applies_buildings_until_acknowledged()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1
  local original=Players[0].SetScriptData
  Players[0].SetScriptData=function(p,data)if data:find('|S|',1,true)then error('blocked frozen intent persistence')end;return original(p,data)end
  LF_Start();LF_Counts(0,0);assert(LF_Writes==0)
  LF_Harbor.units={};Players[0].SetScriptData=original
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(1,1)
end
function LF_Tests.completion_receipt_failure_keeps_saved_plan_and_recovers()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1
  local original=Players[0].SetScriptData
  Players[0].SetScriptData=function(p,data)if data:find('[LANTERN1|11]',1,true)then error('blocked completion')end;return original(p,data)end
  LF_Start();LF_Counts(1,1);assert(Pending());LF_Harbor.units={};local reads=LF_Qualifies
  Players[0].SetScriptData=original;Events.AIProcessingStartedForPlayer.Fire(0)
  LF_Counts(1,1);assert(LF_Qualifies==reads);NoPending()
end
function LF_Tests.save_reload_after_partial_update_uses_intent_not_current_ships()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local release=FailBuilding(LF_Harbor,4,true,false)
  LF_Start();LF_Counts(1,0);assert(Pending());LF_Harbor.units={};release()
  local reads=LF_Qualifies;RestartContext();LF_Counts(1,1);assert(reads==LF_Qualifies)
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(1,1);NoPending()
end
function LF_Tests.duplicate_notifications_after_recovery_do_not_write_or_scan()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;FailBuilding(LF_Harbor,4,false,false);LF_Start()
  local reads,writes=LF_Qualifies,LF_Writes
  for i=1,5 do Events.AIProcessingStartedForPlayer.Fire(0)end
  assert(reads==LF_Qualifies and writes==LF_Writes)
end
function LF_Tests.expired_plan_is_replaced_only_at_next_legitimate_boundary()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local release=FailBuilding(LF_Harbor,4,true,false)
  LF_Start();LF_Harbor.units={};release();LF_Start();LF_Counts(0,0);NoPending()
end
function LF_Tests.qualification_read_failure_never_rescans_after_movement()
  LF_Load();LF_Guard();local original=LF_Harbor.IsCoastal
  LF_Harbor.IsCoastal=function()error('injected city coastal read failure')end
  LF_Start();LF_Harbor.IsCoastal=original;LF_Harbor.units={}
  local reads=LF_Qualifies;Events.AIProcessingStartedForPlayer.Fire(0)
  assert(reads==LF_Qualifies and Players[0].data:find('|R|',1,true));LF_Counts(0,0)
  LF_Guard();LF_Start();LF_Counts(1,0)
end
function LF_Tests.status_after_observed_economy_is_rejected()
  LF_Load();LF_Guard();Players[0].active=true
  GameEvents.PlayerDoTurn.Fire(0);local reads=LF_Qualifies
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0);assert(reads==LF_Qualifies)
  LF_Start();LF_Counts(1,0)
end
function LF_Tests.phase_observer_never_reconciles_existing_snapshot()
  LF_Load();LF_Guard();LF_Start();LF_Harbor.units={};local reads,writes=LF_Qualifies,LF_Writes
  GameEvents.PlayerDoTurn.Fire(0);LF_Counts(1,0);assert(reads==LF_Qualifies and writes==LF_Writes)
end
function LF_Tests.missing_native_event_keeps_capture_cleanup_registered()
  Events.AIProcessingStartedForPlayer=nil;LF_Load();assert(MapModData.LANTERN_Controller.startHook==false)
  LF_Harbor.buildings[3]=1;LF_Harbor.buildings[4]=1
  GameEvents.CityCaptureComplete.Fire(0,false,LF_Harbor.x,LF_Harbor.y,0);LF_Counts(0,0)
end
function LF_Tests.unsupported_lifecycle_api_fails_closed_for_active_load()
  UI.IsLoadedGame=nil;Players[0].active=true;LF_Guard();LF_Load()
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0);LF_Start();LF_Counts(1,0)
end
function LF_Tests.capture_cancels_pending_targets_and_cannot_resurrect_on_recapture()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local release=FailBuilding(LF_Harbor,4,true,false);LF_Start();assert(Pending())
  release();LF_Harbor.owner=2;Players[0].cities={};Players[2].cities={LF_Harbor}
  GameEvents.CityCaptureComplete.Fire(0,false,LF_Harbor.x,LF_Harbor.y,2);LF_Counts(0,0)
  LF_Harbor.owner=0;Players[2].cities={};Players[0].cities={LF_Harbor}
  GameEvents.CityCaptureComplete.Fire(2,false,LF_Harbor.x,LF_Harbor.y,0)
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
  LF_Start();LF_Counts(1,1)
end
function LF_Tests.capture_during_snapshot_write_is_not_dropped()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1
  local original=LF_Harbor.SetNumRealBuilding;local once=true
  LF_Harbor.SetNumRealBuilding=function(city,b,n)
    original(city,b,n)
    if b==3 and n==1 and once then
      once=false;city.owner=2;Players[0].cities={};Players[2].cities={city}
      GameEvents.CityCaptureComplete.Fire(0,false,city.x,city.y,2)
    end
  end
  LF_Start();LF_Counts(0,0);assert(LF_Harbor.buildings[2]==1)
end
function LF_Tests.capture_one_setter_failure_still_clears_the_other_building()
  LF_Load();LF_Harbor.buildings[3]=1;LF_Harbor.buildings[4]=1;LF_Harbor.buildings[2]=1
  local release=FailBuilding(LF_Harbor,3,true,false)
  GameEvents.CityCaptureComplete.Fire(0,false,LF_Harbor.x,LF_Harbor.y,0)
  LF_Counts(1,0);assert(Players[0].data:find('[LANTERN_CLEAR2|',1,true))
  release();RestartContext();LF_Counts(0,0);assert(LF_Harbor.buildings[2]==1)
end
function LF_Tests.pending_identity_does_not_apply_to_replacement_city()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local release=FailBuilding(LF_Harbor,4,true,false);LF_Start()
  release();LF_Harbor.born=LF_Harbor.born+1;LF_Harbor.buildings[3]=0
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
end
function LF_Tests.shutdown_of_old_context_cannot_retire_new_context()
  LF_Load();local shutdown=ContextPtr.shutdown;RestartContext();shutdown();LF_Guard();LF_Start();LF_Counts(1,0)
  assert(MapModData.LANTERN_Controller.active)
end
function LF_Tests.all_cities_independent_and_only_one_ship_needed_each()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1
  local a,b=OtherCity(),OtherCity();a.units[2]=LF_Unit();b.coast=false
  LF_Start();LF_Counts(1,1)
  assert(a:GetNumRealBuilding(3)==1 and a:GetNumRealBuilding(4)==1)
  assert(b:GetNumRealBuilding(3)==0 and b:GetNumRealBuilding(4)==0)
end
function LF_Tests.numeric_progress_tag_does_not_consume_first_notification()
  First(false);LF_Load();Events.AIProcessingStartedForPlayer.Fire(0,0);LF_Counts(0,0)
  Events.AIProcessingStartedForPlayer.Fire(0,nil);LF_Counts(1,1)
end
function LF_Tests.empty_progress_tag_is_accepted_as_candidate_boundary()
  First(false);LF_Load();Events.AIProcessingStartedForPlayer.Fire(0,'');LF_Counts(1,1)
end
function LF_Tests.advanced_scenario_start_uses_native_start_turn()
  First(true);LF_Turn,LF_StartTurn=117,117;LF_Load();LF_Start(0,false);LF_Counts(1,1)
end
function LF_Tests.scriptdata_read_failure_cannot_cause_late_position_rescan()
  LF_Load();local original=Players[0].GetScriptData
  Players[0].GetScriptData=function()error('blocked native ScriptData read')end
  LF_Start();Players[0].GetScriptData=original;LF_Guard()
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0);LF_Start();LF_Counts(1,0)
end
function LF_Tests.reservation_write_failure_does_not_admit_later_ship()
  LF_Load();local original=Players[0].SetScriptData
  Players[0].SetScriptData=function()error('blocked reservation persistence')end
  LF_Start();Players[0].SetScriptData=original;LF_Guard()
  Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
  LF_Start();LF_Counts(1,0)
end
function LF_Tests.pending_recovery_survives_phase_observer_without_new_qualification()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local release=FailBuilding(LF_Harbor,4,true,false)
  LF_Start();GameEvents.PlayerDoTurn.Fire(0);LF_Harbor.units={};release()
  local reads=LF_Qualifies;Events.AIProcessingStartedForPlayer.Fire(0)
  LF_Counts(1,1);assert(LF_Qualifies==reads)
end
function LF_Tests.interleaved_owner_notifications_are_independent_simulation_only()
  LF_Load();LF_Guard();local other=LF_City(2,true);other.units={LF_Unit(2)};other.buildings[2]=1
  Players[2].cities={other};Players[0].active=true;Players[2].active=true
  Events.AIProcessingStartedForPlayer.Fire(0);GameEvents.PlayerDoTurn.Fire(0)
  Events.AIProcessingStartedForPlayer.Fire(2);LF_Counts(1,0)
  assert(other:GetNumRealBuilding(3)==1 and other:GetNumRealBuilding(4)==1)
end
function LF_Tests.malformed_pending_counts_are_quarantined_without_rescan()
  Players[0].active=true;Players[0].data='keep[LANTERN2|-1|10|S|0,0,1,0,1,2,0]'
  LF_Guard();LF_Load();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(0,0)
  assert(Players[0].data:find('[LANTERN_QUARANTINE2|',1,true))
  LF_Start();LF_Counts(1,0)
end
function LF_Tests.nested_capture_cannot_erase_an_unfinished_cleanup_intent()
  local other=OtherCity();other.buildings[3]=1;other.buildings[4]=1
  local release=FailBuilding(other,4,true,false)
  LF_Harbor.buildings[3]=1
  Players[0].data='keep[LANTERN_CLEAR2|0,0,1,0]'
  local original=LF_Harbor.SetNumRealBuilding;local once=true
  LF_Harbor.SetNumRealBuilding=function(city,b,n)
    original(city,b,n)
    if b==3 and n==0 and once then
      once=false;GameEvents.CityCaptureComplete.Fire(0,false,other.x,other.y,0)
    end
  end
  LF_Load();LF_Counts(0,0)
  assert(other:GetNumRealBuilding(4)==1 and Players[0].data:find('[LANTERN_CLEAR2|',1,true))
  release();RestartContext();assert(other:GetNumRealBuilding(4)==0)
end
function LF_Tests.pending_recovery_cannot_grant_to_a_changed_civilization()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;local release=FailBuilding(LF_Harbor,4,true,false)
  LF_Start();LF_Counts(1,0);Players[0].civ=9;release();RestartContext()
  LF_Counts(0,0);assert(LF_Harbor.buildings[2]==1);NoPending()
end
function LF_Tests.completed_snapshot_is_cleared_when_actual_civilization_changes()
  LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;LF_Start();LF_Counts(1,1)
  Players[0].civ=9;local reads=LF_Qualifies;LF_Start();LF_Counts(0,0)
  assert(reads==LF_Qualifies and LF_Harbor.buildings[2]==1)
end
function LF_Tests.old_controller_generation_is_retired_even_in_same_context()
  LF_Load();local old=MapModData.LANTERN_Controller;old.generation=1
  local shutdown=ContextPtr.shutdown;LF_Load();shutdown()
  assert(old~=MapModData.LANTERN_Controller and not old.active)
  assert(#Events.AIProcessingStartedForPlayer.handlers==1)
  LF_Guard();LF_Start();LF_Counts(1,0)
end
