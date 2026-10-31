RFD_Tests = {}
function RFD_Tests.first_and_repeated_classes()
  local c=RFD_City(0,1); RFD_Load()
  RFD_Add(c,'BUILDING_MONUMENT'); GameEvents.CityConstructed.Fire(0,1,GameInfoTypes.BUILDING_MONUMENT)
  RFD_CheckYields(0,0); RFD_Next(); RFD_CheckYields(12,20)
  local c2=RFD_City(0,2); RFD_Add(c2,'BUILDING_MONUMENT'); RFD_Next(); RFD_CheckYields(12,20)
  for _,name in ipairs({'BUILDING_GRANARY','BUILDING_SHRINE','BUILDING_LIBRARY','BUILDING_RFD_REVISION_WORKSHOP'}) do RFD_Add(c,name) end
  RFD_Next(); RFD_CheckYields(60,100)
  RFD_Add(c2,'BUILDING_WORKSHOP'); RFD_Next(); RFD_CheckYields(60,100)
  assert(Players[0].data:find('FOREIGN|preserve-this',1,true))
end
function RFD_Tests.sale_rebuild_and_context_reload()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_MONUMENT'); RFD_Next()
  local saved=Players[0].data
  RFD_Remove(c,'BUILDING_MONUMENT'); RFD_Next(); RFD_Load()
  RFD_Add(c,'BUILDING_MONUMENT'); RFD_Next(); RFD_CheckYields(12,20)
  assert(Players[0].data:find('BUILDINGCLASS_MONUMENT',1,true))
  assert(saved:find('BUILDINGCLASS_MONUMENT',1,true))
end
function RFD_Tests.no_transient_or_event_payout()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_GRANARY')
  GameEvents.CityConstructed.Fire(0,1,GameInfoTypes.BUILDING_GRANARY)
  RFD_Remove(c,'BUILDING_GRANARY'); RFD_Next(); RFD_CheckYields(0,0)
  RFD_Add(c,'BUILDING_GRANARY'); RFD_Next(); RFD_CheckYields(12,20)
end
function RFD_Tests.purchases_free_and_captured()
  local c=RFD_City(0,1); RFD_Load()
  RFD_Add(c,'BUILDING_GRANARY'); GameEvents.CityConstructed.Fire(0,1,GameInfoTypes.BUILDING_GRANARY,true,false)
  RFD_Add(c,'BUILDING_PAGODA'); GameEvents.CityConstructed.Fire(0,1,GameInfoTypes.BUILDING_PAGODA,false,true)
  c.free[GameInfoTypes.BUILDING_LIBRARY]=1
  local capture=RFD_City(0,7); RFD_Add(capture,'BUILDING_MARKET')
  GameEvents.CityCaptureComplete.Fire(1,false,capture.x,capture.y,0)
  RFD_CheckYields(0,0); RFD_Next(); RFD_CheckYields(48,80)
end
function RFD_Tests.wonders_palace_and_dummy_exclusions()
  local c=RFD_City(0,1); RFD_Load()
  for _,name in ipairs({'BUILDING_PALACE','BUILDING_PYRAMID','BUILDING_NATIONAL_COLLEGE',
    'BUILDING_RFD_TEST_TEAM','BUILDING_RFD_TEST_HIDDEN','BUILDING_RFD_TEST_UNBUILDABLE',
    'BUILDING_RFD_TEST_NODISPLAY','BUILDING_RFD_TEST_LEAGUE',
    'BUILDING_RFD_SCIENCE_1','BUILDING_RFD_SCIENCE_2','BUILDING_RFD_SCIENCE_3'}) do RFD_Add(c,name) end
  RFD_Next(); RFD_CheckYields(0,0); assert(RFD_Bonus(c)==0)
end
function RFD_Tests.faith_purchase_only_and_zero_cost()
  local c=RFD_City(0,1); RFD_Load()
  for _,name in ipairs({'BUILDING_PAGODA','BUILDING_RFD_TEST_PURCHASE','BUILDING_RFD_TEST_ZERO'}) do RFD_Add(c,name) end
  RFD_Next(); RFD_CheckYields(36,60)
end
function RFD_Tests.hidden_variant_cannot_borrow_class()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_RFD_TEST_FAKE_MONUMENT')
  RFD_Next(); RFD_CheckYields(0,0)
  RFD_Add(c,'BUILDING_MONUMENT'); RFD_Next(); RFD_CheckYields(12,20)
end
function RFD_Tests.thresholds_and_cap()
  local c=RFD_City(0,1); RFD_Load()
  for count=1,17 do
    RFD_Diverse(c,count); Events.SpecificCityInfoDirty.Fire(0,1)
    assert(RFD_Bonus(c)==math.min(3,math.floor(count/4)), 'threshold '..count)
    local writes=c.writes; Events.SpecificCityInfoDirty.Fire(0,1); assert(c.writes==writes,'duplicate dummy write')
  end
  RFD_CheckYields(0,0) -- UB events do not advance the permanent ledger
end
function RFD_Tests.class_dedup_and_city_independence()
  local a,b=RFD_City(0,1),RFD_City(0,2); RFD_Load()
  RFD_Diverse(a,9); RFD_Diverse(b,5); RFD_Add(a,'BUILDING_WORKSHOP')
  RFD_Add(a,'BUILDING_RFD_TEST_MONUMENT_VARIANT'); RFD_Add(a,'BUILDING_MONUMENT',3)
  RFD_Next(); assert(RFD_Bonus(a)==2 and RFD_Bonus(b)==1)
  RFD_CheckYields(108,180)
end
function RFD_Tests.dynamic_loss_and_workshop_removal()
  local c=RFD_City(0,1); RFD_Load(); RFD_Diverse(c,8); RFD_Next(); assert(RFD_Bonus(c)==2)
  RFD_Remove(c,RFD_Ordinary[7]); GameEvents.CitySoldBuilding.Fire(0,1,GameInfoTypes[RFD_Ordinary[7]])
  assert(RFD_Bonus(c)==1)
  RFD_Remove(c,RFD_Ordinary[6]); RFD_Next(); assert(RFD_Bonus(c)==1)
  RFD_Remove(c,'BUILDING_RFD_REVISION_WORKSHOP'); Events.SpecificCityInfoDirty.Fire(0,1)
  assert(RFD_Bonus(c)==0)
  RFD_Add(c,'BUILDING_RFD_REVISION_WORKSHOP'); RFD_Next(); assert(RFD_Bonus(c)==1)
  RFD_CheckYields(96,160)
end
function RFD_Tests.capture_recapture_and_reused_city_id()
  local old=RFD_City(0,1); RFD_Load(); RFD_Diverse(old,8); RFD_Next()
  local original=old.buildings
  Players[0].cities={}; old.dead=true
  local foreign=RFD_City(1,1); foreign.buildings=original
  GameEvents.CityCaptureComplete.Fire(0,false,foreign.x,foreign.y,1)
  assert(RFD_Bonus(foreign)==0)
  Players[1].cities={}; foreign.dead=true
  local recaptured=RFD_City(0,1); recaptured.buildings=original
  GameEvents.CityCaptureComplete.Fire(1,false,recaptured.x,recaptured.y,0)
  assert(RFD_Bonus(recaptured)==2); RFD_Next(); RFD_CheckYields(96,160)
  recaptured.dead=true; Players[0].cities={}; RFD_Next()
  local replacement=RFD_City(0,1); RFD_Add(replacement,'BUILDING_MONUMENT'); RFD_Next()
  RFD_CheckYields(96,160); assert(#RFD_Errors==0)
end
function RFD_Tests.existing_progressed_save_seeds()
  RFD_Turn=71
  local c=RFD_City(0,1); RFD_Diverse(c,8); RFD_Load()
  RFD_CheckYields(0,0); assert(RFD_Bonus(c)==2)
  RFD_Next(); RFD_CheckYields(0,0)
  RFD_Add(c,'BUILDING_HOSPITAL'); RFD_Next(); RFD_CheckYields(12,20)
end
function RFD_Tests.advanced_start_is_a_new_game()
  RFD_StartTurn=120; RFD_Turn=120
  local c=RFD_City(0,1); RFD_Add(c,'BUILDING_LIBRARY'); RFD_Load()
  GameEvents.PlayerDoTurn.Fire(0); RFD_CheckYields(12,20)
end
function RFD_Tests.human_guards_and_separate_ledgers()
  for id=0,3 do local c=RFD_City(id,1); RFD_Diverse(c,8) end
  RFD_Load()
  for id=0,3 do GameEvents.PlayerDoTurn.Fire(id) end
  RFD_CheckYields(96,160,0); RFD_CheckYields(0,0,1); RFD_CheckYields(0,0,2); RFD_CheckYields(96,160,3)
  assert(RFD_Bonus(Players[1].cities[1])==0 and RFD_Bonus(Players[2].cities[1])==0)
  Players[0].alive=false; RFD_Add(Players[0].cities[1],'BUILDING_HOSPITAL'); RFD_Next()
  RFD_CheckYields(96,160)
end
function RFD_Tests.duplicate_turn_and_context_handlers()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_MONUMENT'); RFD_Next()
  RFD_Add(c,'BUILDING_LIBRARY'); GameEvents.PlayerDoTurn.Fire(0); RFD_CheckYields(12,20)
  for i=1,10 do RFD_Load() end
  assert(GameEvents.PlayerDoTurn.Count()==1)
  Events.SequenceGameInitComplete.Fire(); Events.LoadScreenClose.Fire(); RFD_CheckYields(12,20)
  RFD_Next(); RFD_CheckYields(24,40)
end
function RFD_Tests.runtime_speed_and_individual_rounding()
  for _,speed in pairs(GameInfo.GameSpeeds) do speed.ConstructPercent=71 end
  local c=RFD_City(0,1); RFD_Load(); RFD_Diverse(c,3); RFD_Next()
  RFD_CheckYields(27,42) -- round(8.52)*3, round(14.2)*3
end
function RFD_Tests.marathon()
  RFD_Speed=0
  local c=RFD_City(0,1); RFD_Load(); RFD_Diverse(c,5); RFD_Next(); RFD_CheckYields(180,300)
end
function RFD_Tests.quick_and_epic()
  RFD_Speed=3
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_MONUMENT'); RFD_Next(); RFD_CheckYields(8,13)
  RFD_Speed=1; RFD_Add(c,'BUILDING_LIBRARY'); RFD_Next(); RFD_CheckYields(26,43)
end
function RFD_Tests.journal_before_and_after_yield_failures()
  local c=RFD_City(0,1); RFD_Load(); local p=Players[0]
  for i,flag in ipairs({'beforeCulture','afterCulture','beforeGold','afterGold'}) do
    RFD_Add(c,RFD_Ordinary[i]); p[flag]=true; RFD_Next()
    RFD_Load(); RFD_CheckYields(12*i,20*i)
    assert(not p.data:match('|[12],'))
  end
end
function RFD_Tests.failed_preparation_never_pays()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_MONUMENT')
  Players[0].failSave=Players[0].writes+1; RFD_Next(); RFD_CheckYields(0,0)
  Players[0].failSave=nil; GameEvents.PlayerDoTurn.Fire(0); RFD_CheckYields(12,20)
end
function RFD_Tests.failed_acknowledgement_never_duplicates()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_MONUMENT')
  Players[0].failSave=Players[0].writes+2; RFD_Next(); RFD_CheckYields(12,0)
  Players[0].failSave=nil; RFD_Load(); RFD_CheckYields(12,20)
  RFD_Next(); RFD_CheckYields(12,20)
end
function RFD_Tests.failed_final_commit_recovers_gold()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_MONUMENT')
  Players[0].failSave=Players[0].writes+3; RFD_Next(); RFD_CheckYields(12,20)
  Players[0].failSave=nil; RFD_Load(); RFD_Next(); RFD_CheckYields(12,20)
end
function RFD_Tests.ambiguous_recovery_preserves_external_earnings()
  local c=RFD_City(0,1); RFD_Load(); RFD_Add(c,'BUILDING_MONUMENT'); Players[0].afterGold=true; RFD_Next()
  Players[0].gold=Players[0].gold+700; RFD_Load()
  RFD_CheckYields(12,27); assert(Players[0].data:find('|2,',1,true))
  assert(RFD_Errors[#RFD_Errors]:find('ambiguous',1,true))
end
function RFD_Tests.dummy_failure_reconciles_exact_target()
  local c=RFD_City(0,1); RFD_Load(); RFD_Diverse(c,12); c.failDummy=true
  Events.SpecificCityInfoDirty.Fire(0,1); assert(RFD_Bonus(c)==1)
  RFD_Next(); assert(RFD_Bonus(c)==3)
  local writes=c.writes; RFD_Next(); assert(c.writes==writes); RFD_CheckYields(144,240)
end
function RFD_Tests.invalid_state_fails_closed()
  local c=RFD_City(0,1); RFD_Diverse(c,8); Players[0].data='foreign[RFD1|corrupt]'
  RFD_Load(); RFD_Next(); RFD_CheckYields(0,0); assert(Players[0].data=='foreign[RFD1|corrupt]')
  assert(RFD_Bonus(c)==2,'dynamic UB must remain independent of corrupt UA history')
end
