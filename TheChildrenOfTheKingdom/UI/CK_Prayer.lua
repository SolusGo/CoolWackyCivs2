include('CK_Core')
local K=MapModData.CKPrayer
local opened,leader,rendering=false,false,false
local blocked={}
local transition,queued,contextHidden=false,false,false
local refresh
local expectedStage,expectedReady
-- BNW InGame.xml context names, matching the collection's modal visibility fix.
local screens={
 'CivilopediaScreen','TechTree','GenericPopup','TextPopup','DeclareWarPopup','SocialPolicyPopup',
 'NotificationLogPopup','WhosWinningPopup','NewEraPopup','NaturalWonderPopup','GoodyHutPopup',
 'BarbarianCampPopup','GoldenAgePopup','GreatPersonRewardPopup','CityStateGreetingPopup','CityStateDiploPopup',
 'DiploVotePopup','VoteResultsPopup','TechAwardPopup','WonderPopup','AdvisorInfoPopup','AdvisorCounselPopup',
 'AdvisorModal','EconomicOverview','DiploOverview','MilitaryOverview','EndGameMenu','Demographics',
 'VictoryProgress','ChooseFreeItem','ChoosePantheon','ChooseReligion','EspionageOverview','ReligionOverview',
 'ChooseMayaBonus','ChooseFaithGreatPerson','SetUnitName','SetCityName','ProductionPopup','LeagueOverviewPopup',
 'ChooseArchaeology','ChooseIdeology','ChooseInternationalTradeRoute','CultureOverview','ChooseTradeRouteNewHome',
 'GreatWorkSplash','TradeRouteOverview','LeagueProjectPopup','ChooseGoodyHutRewardPopup','ChooseAdmiralNewPort',
 'LeagueSplash','GameMenu','PlayerChange','ContentSwitch'
}
local function eligible()
 local pid=Game.GetActivePlayer();local p=Players[pid]
 if not K.Alive(pid) or not p:IsTurnActive() or transition or contextHidden or UI.IsCityScreenUp() then return false end
 if UI.GetInterfaceMode()~=InterfaceModeTypes.INTERFACEMODE_SELECTION then return false end
 local leaderRoot=ContextPtr:LookUpControl('/LeaderHeadRoot')
 if (leaderRoot and not leaderRoot:IsHidden()) or (not leaderRoot and leader)
  or (UI.GetLeaderHeadRootUp and UI.GetLeaderHeadRootUp()) then return false end
 local visible={}
 for _,name in ipairs(screens) do
  local control=ContextPtr:LookUpControl('/InGame/'..name)
  if control and not control:IsHidden() then visible[name]=true end
 end
 for kind,record in pairs(blocked) do
  if record.capture and next(visible) then record.capture=nil;record.screens=visible end
  if record.screens then
   local showing=false;for name in pairs(record.screens) do if visible[name] then showing=true end end
   if not showing then blocked[kind]=nil end
  end
 end
 return not next(visible) and not next(blocked)
end
local function render()
 local pid=Game.GetActivePlayer();local show=eligible();local s=K.states[pid]
 Controls.Launcher:SetHide(not show);Controls.Panel:SetHide(not (show and opened))
 if show and opened then
  if not s then
   Controls.Current:SetText(K.Text('DISABLED'));Controls.Quote:SetText('');Controls.Effect:SetText('')
   Controls.Permanent:SetText('');Controls.Blessings:SetText('');Controls.Reserve:SetText('');Controls.Cycle:SetText('')
   Controls.Progress:SetText('');Controls.Cooldown:SetText('');Controls.Pray:SetDisabled(true)
   Controls.Pray:SetToolTipString(K.Text('DISABLED'))
  else
   local era=math.max(1,Players[pid]:GetCurrentEra()+1);local duration=K.Duration()
   expectedStage,expectedReady=s.stage,s.ready
   Controls.Current:SetText(K.Text('CURRENT',K.Text('STAGE_'..s.stage)))
   Controls.Quote:SetText('"'..K.Text('QUOTE_'..s.stage)..'"')
   Controls.Effect:SetText(K.Text('BLESSING',K.Text('EFFECT_'..s.stage,duration,10*era,8*era,20*era,25*era)))
   Controls.Permanent:SetText(K.Text('PERMANENT',s.grace))
   Controls.Progress:SetText(K.Text('PROGRESS',s.grace,s.stage))
   local remaining=math.max(0,s.ready-K.Turn());local can,reason=K.CanPray(pid)
   Controls.Cooldown:SetText(remaining>0 and K.Text('WAIT',remaining) or K.Text('AVAILABLE'))
   Controls.Pray:SetDisabled(not can)
   Controls.Pray:SetToolTipString(can and K.Text('READY_HELP',duration) or reason=='WAIT_HELP' and K.Text('WAIT_HELP',remaining) or K.Text(reason or 'UNAVAILABLE'))
   local active={}
   for _,pair in ipairs({{'address',1},{'seek',3},{'repent',5},{'protection',6}}) do
    if K.Active(s,pair[1]) then active[#active+1]=K.Text('ACTIVE_LINE',K.Text('STAGE_'..pair[2]),math.max(0,s[pair[1]]-s.clock)) end
   end
   Controls.Blessings:SetText(K.Text('ACTIVE')..'[NEWLINE]'..(#active>0 and table.concat(active,'[NEWLINE]') or K.Text('NONE')))
   Controls.Reserve:SetText(K.Text('RESERVE',s.bread))
   local stages={}
   for i=1,7 do local label=i..'. '..K.Text('STAGE_'..i)
    if i==s.stage then label='[COLOR_POSITIVE_TEXT]'..label..'[ENDCOLOR]' end
    stages[#stages+1]=label
   end
   Controls.Cycle:SetText(table.concat(stages,'  >  '))
   Controls.Progress:SetToolTipString(K.Text('CYCLE_HELP'))
  end
  Controls.DetailsStack:CalculateSize();Controls.DetailsStack:ReprocessAnchoring();Controls.DetailsScroll:CalculateInternalSize()
 end
end
refresh=function()
 if rendering then return end;rendering=true
 local ok,err=pcall(render);rendering=false
 if not ok then opened=false;Controls.Panel:SetHide(true);print('[Kingdom] Prayer display: '..tostring(err)) end
end
-- One coalesced UI transition callback; detach BEFORE rendering. There is no
-- periodic refresh, idle callback, gameplay work, or polling in this dispatcher.
local function deferRefresh()
 if queued then return end;queued=true
 ContextPtr:SetUpdate(function()
  ContextPtr:ClearUpdate();queued=false;transition=false;refresh()
 end)
end
local function close() opened=false;refresh() end
local function closeTransition() opened=false;transition=true;refresh();deferRefresh() end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,close)
Controls.Pray:RegisterCallback(Mouse.eLClick,function()
 if opened and eligible() then LuaEvents.CKPrayer_Pray(Game.GetActivePlayer(),expectedStage,expectedReady);refresh() end
end)
K.Hook(LuaEvents,'CKPrayer_Changed',function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
K.Hook(Events,'SerialEventGameDataDirty',deferRefresh)
K.Hook(Events,'SerialEventCityInfoDirty',function() if opened then refresh() end end)
K.Hook(Events,'SerialEventEnterCityScreen',closeTransition)
K.Hook(Events,'SerialEventExitCityScreen',function()
 if ButtonPopupTypes then blocked[ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION]=nil end
 closeTransition()
end)
K.Hook(Events,'AILeaderMessage',function() leader=true;closeTransition() end)
K.Hook(Events,'LeavingLeaderViewMode',function() leader=false;closeTransition() end)
K.Hook(Events,'SerialEventGameMessagePopupShown',function(info)
 if info and info.Type then blocked[info.Type]={capture=true} end
 closeTransition()
end)
K.Hook(Events,'SerialEventGameMessagePopupProcessed',function(kind) blocked[kind]=nil;closeTransition() end)
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','LoadScreenClose'}) do
 K.Hook(Events,name,function() blocked={};leader=false;closeTransition() end)
end
K.Hook(Events,'ActivePlayerTurnEnd',closeTransition)
K.Hook(Events,'InterfaceModeChanged',closeTransition)
ContextPtr:SetShowHideHandler(function(hidden) contextHidden=hidden;closeTransition() end)
ContextPtr:SetInputHandler(function(msg,key)
 if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then close();return true end
 return false
end)
refresh()
