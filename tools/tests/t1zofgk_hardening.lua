-- Isolated production-controller regressions. Native ordering comes from the
-- pinned CP source; manual late copies/in-place transfers are defensive cases,
-- not assertions that direct CP capture copies promotions.
HardeningCases={}
local R=GameInfoTypes.UNIT_T1Z_RECRUIT
local function Setup()Reset();LoadController();return Army()end
local function Clean(u)
  Check(not RoleOf(u),'unauthorized legendary role')
  Check(not Has(u,'SYNERGY_10') and not Has(u,'SYNERGY_15'),'unauthorized formation')
end
HardeningCases.delayed_city_state_gift=function()
  local a=Setup();local u=Upgrade(a[1],11001,true)
  u.promos[900001]=true;u.data=u.data..'[OTHER_MOD=keep]'
  local gift=DistanceSend(u);turn=3
  local foreign=DistanceDeliver(gift,1,false,false)
  Clean(foreign)
  Check(Players[0].data:match('S1=V:'),'distance gift vacates original slot')
  Check(Has(foreign,'SCOUTED') and Has(foreign,'DEVELOPMENT_1'),'gift preserves non-role history')
  Check(foreign.promos[900001],'unrelated promotion preserved')
end
HardeningCases.returned_distance_gift=function()
  local a=Setup();local u=Upgrade(a[1],11001,true);local gift=DistanceSend(u)
  turn=2;local returned=DistanceDeliver(gift,0,true,true)
  Clean(returned)
  Check(Has(returned,'DEVELOPMENT_1') and Has(returned,'SCOUTED'),'return keeps history')
  GameEvents.PlayerDoTurn(0);Clean(returned)
  Reload(true);Clean(returned)
end
HardeningCases.roleless_gift_return_preserves_exclusion=function()
  Reset();LoadController();MakeCity(0,1,1)
  local foreignBorn=MakeUnit(0,R);GameEvents.MinorGiftUnit(1,0,R)
  Check(not RoleOf(foreignBorn),'city-state recruit begins excluded')
  local gift=DistanceSend(foreignBorn)
  local returned=DistanceDeliver(gift,0,true,true)
  GameEvents.PlayerDoTurn(0)
  Check(not RoleOf(returned),'same-turn return of a roleless gift cannot masquerade as a fresh initial Recruit')
  Check(Has(returned,'SCOUTED'),'acquisition exclusion does not destroy Recruit history')
end
HardeningCases.air_return_without_movement=function()
  local a=Setup();a[1].domain=2;local gift=DistanceSend(a[1]);turn=2
  local returned=DistanceDeliver(gift,0,true,false)
  -- No after-apply callback exists here. First native player boundary is the
  -- promised fallback; do not claim the copy can be intercepted earlier.
  GameEvents.PlayerDoTurn(1);Clean(returned)
end
HardeningCases.air_return_context_recreated_before_copy=function()
  Reset();LoadController();MakeCity(0,1,1)
  local original=Train(0,R,1);original.domain=2
  local gift=DistanceSend(original);turn=2
  local returned=DistanceDeliver(gift,0,true,false,function()Reload(true)end)
  GameEvents.PlayerDoTurn(1);Clean(returned)
  Check(not Players[0].data:match('S2=L:'),'partial delivery context must not consume another initial slot')
  Check(Has(returned,'SCOUTED'),'partial delivery retains native non-role history')
end
HardeningCases.foreign_formation_on_load=function()
  Setup();local foreign=MakeUnit(1,11002,20,20)
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_SYNERGY_15]=true
  foreign.promos[900001]=true;foreign.data='[OTHER_MOD=foreign]'
  Reload(true);Clean(foreign)
  Check(foreign.data:find('[OTHER_MOD=foreign]',1,true) and foreign.promos[900001],'cleanup preserves unrelated state')
end
HardeningCases.late_foreign_copy_at_boundary=function()
  Setup();local foreign=MakeUnit(1,11002,20,20)
  -- Explicit defensive injection after Created, not native direct capture.
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_ONER]=true
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_SYNERGY_15]=true
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_SUPPORT]=true
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_PRESSURE]=true
  GameEvents.PlayerDoTurn(1);Clean(foreign)
  Check(not Has(foreign,'SUPPORT') and not Has(foreign,'PRESSURE'),'late copied auras expire')
end
HardeningCases.late_foreign_copy_on_movement=function()
  Setup();local foreign=MakeUnit(1,11002,20,20)
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_ONER]=true
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_SUPPORT]=true
  foreign.promos[GameInfoTypes.PROMOTION_T1Z_PRESSURE]=true
  Move(foreign,25,20);Clean(foreign)
  Check(not Has(foreign,'SUPPORT') and not Has(foreign,'PRESSURE'),'movement reconciles copied auras even outside all source rings')
end
HardeningCases.in_place_owner_change=function()
  local a=Setup();local u=a[3];local oldID=u.id
  -- Defensive acquisition by another mod without native convert(). No CP
  -- SetOwner Lua API is claimed; the next known movement must reconcile it.
  Players[0].units[oldID]=nil;u.pid=1;u.id=999;Players[1].units[999]=u
  Move(u,8,0);Clean(u)
  Check(Players[0].data:match('S3=V:'),'lost owner receives vacancy')
end
HardeningCases.copied_token_cannot_steal_role_on_upgrade=function()
  local a=Setup();local clone=MakeUnit(0,R)
  clone.data=a[1].data;clone.promos[GameInfoTypes.PROMOTION_T1Z_ZEUS]=true
  clone=Upgrade(clone,11001,true)
  Check(RoleOf(a[1])==1 and not RoleOf(clone),'copied token does not authorize a different source object')
end
HardeningCases.copied_token_death_cannot_vacate_real_member=function()
  local a=Setup();local clone=MakeUnit(0,R)
  clone.data=a[1].data;clone.promos[GameInfoTypes.PROMOTION_T1Z_ZEUS]=true
  Die(clone)
  Check(RoleOf(a[1])==1 and not Players[0].data:match('S1=V:'),'unauthorized clone death cannot revoke a genuine member')
end
HardeningCases.lethal_hp_before_prekill=function()
  local a=Setup();a[1].dead=true
  GameEvents.UnitPrekill(0,a[1].id,R,0,0,true,1)
  Check(Players[0].data:match('S1=V:'),'lethal-HP unit still owns its death-time vacancy')
end
HardeningCases.health_transform_not_upgrade=function()
  local a=Setup();local u=Upgrade(a[1],11001,true)
  u=Convert(u,0,11002,true,true,{noUpgradeEvent=true})
  Check(Has(u,'DEVELOPMENT_1') and not Has(u,'DEVELOPMENT_2'),'CP health transform is not a genuine upgrade')
  Check(RoleOf(u)==1,'health transform keeps same-owner role')
end
HardeningCases.class_replacement_not_upgrade=function()
  local a=Setup();local u=Convert(a[1],0,11002,true,false,{noUpgradeEvent=true})
  Check(not Has(u,'DEVELOPMENT_1'),'replacement recreation is not a paid/goody upgrade')
  Check(RoleOf(u)==1,'same-owner replacement preserves role')
end
HardeningCases.militaristic_gift_not_local_birth=function()
  Setup();Reset();LoadController();MakeCity(0,1,1)
  local gift=MakeUnit(0,R)
  GameEvents.MinorGiftUnit(1,0,R);GameEvents.PlayerDoTurn(0)
  Check(not RoleOf(gift),'city-state supplied Recruit cannot enter initial roster')
  Check(Has(gift,'SCOUTED'),'gift retains native Recruit promotion')
end
HardeningCases.duplicate_creation_near_minor_gift=function()
  local a=Setup()
  GameEvents.UnitCreated(0,a[1].id,R,0,0)
  local gift=MakeUnit(0,R);GameEvents.MinorGiftUnit(1,0,R)
  Check(RoleOf(a[1])==1,'duplicate birth cannot let type-only gift callback revoke an existing member')
  Check(not RoleOf(gift),'actual incoming gift stays excluded')
end
HardeningCases.normal_capture_no_promotion_copy=function()
  local a=Setup();local u=Upgrade(a[1],11001,true)
  local foreign=DirectCapture(u,1,1)
  Clean(foreign)
  Check(not Has(foreign,'DEVELOPMENT_1'),'CP direct capture does not copy veteran promotion')
  Check(Players[0].data:match('S1=V:'),'capture vacates source')
  Reload(true);Clean(foreign)
end
HardeningCases.movement_capture_no_duplicate=function()
  local a=Setup();local foreign=DirectCapture(a[2],1,0)
  Move(foreign,8,0);Clean(foreign)
  Check(Players[0].data:match('S2=V:'),'movement capture leaves one vacancy')
end
HardeningCases.immediate_gift_and_return_history=function()
  local a=Setup();local u=Upgrade(a[1],11001,true);local token=u.data:match('%[T1Z1_ID=([^%]]+)%]')
  u.promos[900001]=true
  local gifted=Gift(u,1);Clean(gifted)
  local returned=Gift(gifted,0);Clean(returned)
  Check(Has(returned,'DEVELOPMENT_1') and Has(returned,'SCOUTED'),'immediate return keeps development')
  Check(returned.data:match('%[T1Z1_ID=([^%]]+)%]')==token,'normal conversions preserve token')
  Check(returned.promos[900001],'ordinary gifted promotion is retained')
  Reload(true);Clean(returned)
end
HardeningCases.goody_upgrade_exactly_once=function()
  local a=Setup()
  local u=Convert(a[1],0,11001,true,true,{goody=true,repeatUpgrade=true})
  Check(RoleOf(u)==1 and Has(u,'DEVELOPMENT_1') and not Has(u,'DEVELOPMENT_2'),'native goody upgrade counts exactly once')
end
HardeningCases.upgrade_context_checkpoints=function()
  local a=Setup();local u=a[1];u.data=u.data..'[OTHER_MOD=source]'
  u=Convert(u,0,11001,true,true,{
    repeatUpgrade=true,afterCreated=function()Reload(true)end,
    afterUpgrade=function()Reload(true)end,
    afterCopy=function(from,to)to.data=to.data..'[OTHER_MOD=destination]';Reload(true)end})
  Check(Has(u,'DEVELOPMENT_1') and RoleOf(u)==1,'one genuine upgrade across context checkpoints')
  Check(u.data:find('[OTHER_MOD=destination]',1,true),'destination ScriptData retained')
  Check(not Players[0].data:match('S1=V:'),'upgrade checkpoints never start cooldown')
end
HardeningCases.capture_near_upgrade_and_reused_id=function()
  local a=Setup();local old=a[2].id;DirectCapture(a[2],1,1)
  a[1]=Upgrade(a[1],11001,true);local replacement=Train(0,R,1,false,false,old)
  Check(not RoleOf(replacement),'new ID-reusing unit cannot fill cooling role')
  Check(RoleOf(a[1])==1 and Has(a[1],'DEVELOPMENT_1'),'nearby capture does not damage upgrade')
  Reload(true);Check(RoleOf(a[1])==1,'reload keeps surviving upgraded member')
end
HardeningCases.faker_and_keria_transfer_cleanup=function()
  local a=Setup();War(0,1,true);local enemy=MakeUnit(1,11002,1,0)
  local friend=Train(0,11002,1);Move(friend,1,0)
  Check(Has(enemy,'PRESSURE') and Has(friend,'SUPPORT'),'active role effects present')
  Convert(a[3],3,a[3].kind,false,true)
  Check(not Has(enemy,'PRESSURE'),'Faker transfer clears old pressure')
  Convert(a[5],1,a[5].kind,false,true)
  Check(not Has(friend,'SUPPORT'),'Keria transfer clears old support')
  Check(not Has(a[1],'SYNERGY_15'),'formation recalculates after ownership loss')
end
HardeningCases.cooldowns_and_simultaneous_losses=function()
  local a=Setup();Die(a[1]);Die(a[2]);local delay=math.max(1,math.floor(10*SPEED/100+.5))
  turn=delay-1;Reload(true);Check(not RoleOf(Train(0,11002,1)),'cooldown survives reload')
  turn=delay;local first=Train(0,11002,1);local second=Train(0,11002,1)
  Check(RoleOf(first)==1 and RoleOf(second)==2,'ready replacements preserve priority')
  Check(not Has(first,'SCOUTED'),'successor does not borrow origin')
end
HardeningCases.no_t1_isolation=function()
  Reset();Players[0].civ=-1;Players[3].civ=-1;LoadController()
  local u=MakeUnit(1,11002);u.promos[900001]=true;u.data='[OTHER_MOD=keep]'
  GameEvents.PlayerDoTurn(1);Move(u,5,0);Reload(true)
  Check(u.data=='[OTHER_MOD=keep]' and u.promos[900001] and not RoleOf(u),'unrelated units unchanged')
end
