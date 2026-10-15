include('InstanceManager')
include('BoundlessCore')
local B=MapModData.BoundlessCity
local instances=InstanceManager:new('BoundlessPlotRow','Root',Controls.Rows)
local opened,leaderScreen,refreshing,transition=false,false,false,false
local blocked={};local page=1;local sort='DISTANCE';local message=''
local siege=false
local refresh;local lastVisibility,lastError;local contexts={};local transitionRevision=0
-- Context IDs from BNW InGame.xml. Query actual visibility: popup notifications
-- can be missed, or (DeclareWarPopup) report Processed while still displayed.
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
local function context(path)
 local c=contexts[path]
 if c==nil then c=ContextPtr:LookUpControl(path);contexts[path]=c or false end
 return c
end
local function worldReason()
 if transition then return 'screen transition' end
 local showing={};local popup
 for _,name in ipairs(screens) do local c=context('/InGame/'..name)
  if c and not c:IsHidden() then showing[name]=true;popup=popup or name end
 end
 for kind,record in pairs(blocked) do
  -- Bind Shown to the screens visible after that transition, never to a
  -- permanent flag. Unrecognized mod popups retain event/turn fallback.
  if record.capture then record.capture=nil;if popup then record.screens=showing end end
  if record.screens then
   local visible=false;for name in pairs(record.screens) do if showing[name] then visible=true;break end end
   if not visible then blocked[kind]=nil end
  end
 end
 if UI.IsCityScreenUp() then return 'city screen' end
 if UI.GetInterfaceMode()~=InterfaceModeTypes.INTERFACEMODE_SELECTION then return 'interface mode '..tostring(UI.GetInterfaceMode()) end
 local leader=context('/LeaderHeadRoot')
 if (leader and not leader:IsHidden()) or (not leader and leaderScreen)
  or (UI.GetLeaderHeadRootUp and UI.GetLeaderHeadRootUp()) then return 'leader diplomacy' end
 if popup then return 'popup '..popup end
 if next(blocked) then return 'popup event '..tostring(next(blocked)) end
end
local function deferRefresh()
 local revision=transitionRevision
 B.DeferUI(function() if revision==transitionRevision then transition=false end;refresh() end)
end
local function closeForTransition()
 opened=false;transition=true;transitionRevision=transitionRevision+1;refresh();deferRefresh()
end
local function resetVisibility()
 blocked={};contexts={};leaderScreen=false;closeForTransition()
end
local function yields(values)
 local words={};for i,y in ipairs(B.Yields) do words[#words+1]=(values[i] or 0)..' '..B.Text(y.name) end
 return table.concat(words,' / ')
end
local function render()
 local pid=Game.GetActivePlayer();local p=Players[pid]
 local reason
 if not B.IsBoundless(pid) or not p:IsHuman() or not p:IsAlive() then reason='inactive civilization'
 elseif not p:IsTurnActive() then reason='inactive turn'
 else reason=worldReason() end
 local visible=reason==nil
 local s=visible and B.State(pid);local city=s and B.City(s)
 if visible and (not s.capital or s.incompatible) then visible=false;reason=s.incompatible and 'incompatible state' or 'capital not founded' end
 local status=tostring(pid)..': '..(reason or 'visible')
 if status~=lastVisibility then print('[BoundlessCity] Workforce visibility: '..status);lastVisibility=status end
 Controls.Launcher:SetHide(not visible)
 if not visible then opened=false end
 Controls.Panel:SetHide(not opened)
 if not opened then return end
 if not city then siege=true end
 local info=city and B.Summary(s);local cache=B.Ownership(s)
 local summary=info and B.Text('SUMMARY',info.population,info.owned,info.localCount,info.remote,info.specialists,info.idle,info.unassigned,info.availableCitizens,info.availableRemote,info.maximumRemote,info.pending,info.locks,info.progress,info.cost) or B.Text('CAPITAL_LOST')
 if info and info.automata>0 then summary=summary..'[NEWLINE]'..B.Text('AUTOMATONS',info.automata) end
 local done,total=B.DominationProgress(s)
 summary=summary..'[NEWLINE]'..B.Text('SUBJUGATION_PROGRESS',done,total)
 Controls.Summary:SetText(summary)
 local net={};for i=1,#B.Yields do net[i]=(cache.remoteYields and cache.remoteYields[i] or 0)-(cache.labourerYields and cache.labourerYields[i] or 0) end
 Controls.Yields:SetText(B.Text('YIELDS',yields(cache.remoteYields or {}),yields(cache.labourerYields or {}),yields(net)))
 Controls.Mode:SetText(B.Text(s.mode));Controls.Priority:SetText(B.Text(s.priority))
 Controls.Mode:SetDisabled(not city);Controls.Priority:SetDisabled(not city);Controls.Direction:SetDisabled(not city)
 Controls.Direction:SetText(B.Text('DIRECTION')..': '..B.Text(s.direction));Controls.Sort:SetText(B.Text(sort))
 Controls.Help:SetText(message~='' and message or B.Text('CAPACITY'))
 if s.phase=='RECOVER' then Controls.Help:SetText(B.Text('RECOVERY_PENDING')) end
 Controls.Siege:SetText(B.Text(siege and 'WORKFORCE_VIEW' or 'SIEGE'))
 local rows=siege and B.SiegeRows(s) or B.RemoteRows(s,sort)
 if siege then Controls.Help:SetText(message~='' and message or B.Text('SIEGE_HELP')) end
 local pages=math.max(1,math.ceil(#rows/B.Config.PageSize));page=math.max(1,math.min(page,pages))
 instances:ResetInstances()
 for i=(page-1)*B.Config.PageSize+1,math.min(page*B.Config.PageSize,#rows) do
  local row=rows[i];local control=instances:GetInstance();row.plot=row.plot or Map.GetPlotByIndex(row.n)
  local assigned=s.assignments[row.n]~=nil
  local locked=s.mode~='AUTO' and s.locks[row.n]~=nil
  if siege then
   control.Text:SetText(row.name..'  ('..row.x..','..row.y..')[NEWLINE]'..(row.protection and B.Text(row.protection)..' ' or '')..B.Text(row.reason))
   control.Assign:SetText(B.Text(row.action or 'DEMOLISH'));control.Lock:SetHide(true)
   local n=row.n
   control.Assign:RegisterCallback(Mouse.eLClick,function()
    local ok,reason=B.Action(pid,'SIEGE',n);message=ok and '' or B.Text(reason or 'UNAVAILABLE');refresh()
   end)
  else
   control.Lock:SetHide(false)
   local pending=(s.mode=='MANUAL' and s.selected[row.n] or s.mode=='HYBRID' and s.locks[row.n]) and not assigned
   control.Text:SetText((assigned and '[COLOR_POSITIVE_TEXT]' or '')..'('..row.plot:GetX()..','..row.plot:GetY()..')  '
    ..B.Text('DISTANCE')..' '..row.distance..'  '..row.resource..'  '..row.improvement
    ..(locked and ' [ICON_LOCKED]' or '')..(pending and ' '..B.Text('PENDING') or '')
    ..(assigned and '[ENDCOLOR]' or '')..'[NEWLINE]'..yields(B.PlotYields(row.plot)))
   control.Assign:SetText(B.Text((assigned or s.selected[row.n]) and 'RELEASE' or 'ASSIGN'))
   control.Lock:SetText(B.Text(locked and 'UNLOCK' or 'LOCK'))
   control.Lock:SetDisabled(not p:IsTurnActive() or (not B.Eligible(s,row.plot) and not s.locks[row.n]))
   local n=row.n
   control.Assign:RegisterCallback(Mouse.eLClick,function() message=B.Action(pid,'PLOT',n) and '' or B.Text('UNAVAILABLE');refresh() end)
   control.Lock:RegisterCallback(Mouse.eLClick,function() B.Action(pid,'LOCK',n);refresh() end)
  end
  control.Assign:SetDisabled(not p:IsTurnActive() or (siege and not row.ready) or (not siege and not B.Eligible(s,row.plot) and not s.selected[row.n] and not assigned))
  local plot=row.plot
  control.Locate:RegisterCallback(Mouse.eLClick,function() UI.LookAt(plot,0) end)
 end
 Controls.Page:SetText(page..' / '..pages..'  ('..#rows..')')
 Controls.Previous:SetDisabled(page<=1);Controls.Next:SetDisabled(page>=pages)
 Controls.Rows:CalculateSize();Controls.Rows:ReprocessAnchoring();Controls.Scroll:CalculateInternalSize()
end
refresh=function()
 if refreshing then return end;refreshing=true
 local ok,err=pcall(render);refreshing=false
 if ok then lastError=nil else
  opened=false;Controls.Panel:SetHide(true)
  if err~=lastError then print('[BoundlessCity] Workforce refresh failed: '..tostring(err));lastError=err end
 end
end
local function cycle(list,current)
 for i,value in ipairs(list) do if value==current then return list[i%#list+1] end end
 return list[1]
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;page=1;message='';refresh() end)
Controls.Siege:RegisterCallback(Mouse.eLClick,function() siege=not siege;page=1;message='';refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;refresh() end)
Controls.Mode:RegisterCallback(Mouse.eLClick,function() local pid=Game.GetActivePlayer();B.Action(pid,'MODE',cycle({'AUTO','MANUAL','HYBRID'},B.State(pid).mode));refresh() end)
Controls.Priority:RegisterCallback(Mouse.eLClick,function() local pid=Game.GetActivePlayer();B.Action(pid,'PRIORITY',cycle({'BALANCED','FOOD','PRODUCTION','GOLD'},B.State(pid).priority));refresh() end)
Controls.Direction:RegisterCallback(Mouse.eLClick,function() local pid=Game.GetActivePlayer();B.Action(pid,'DIRECTION',cycle({'ANY','NORTH','EAST','SOUTH','WEST'},B.State(pid).direction));refresh() end)
Controls.Sort:RegisterCallback(Mouse.eLClick,function() sort=cycle({'DISTANCE','YIELD','RESOURCE','IMPROVEMENT'},sort);page=1;refresh() end)
Controls.Previous:RegisterCallback(Mouse.eLClick,function() page=page-1;refresh() end)
Controls.Next:RegisterCallback(Mouse.eLClick,function() page=page+1;refresh() end)
ContextPtr:SetInputHandler(function(msg,key)
 if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then opened=false;refresh();return true end
 return false
end)
LuaEvents.BoundlessChanged.Add(function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
Events.SerialEventCityInfoDirty.Add(function() if opened and siege then refresh() end;deferRefresh() end)
Events.SerialEventGameDataDirty.Add(deferRefresh)
Events.GameplaySetActivePlayer.Add(resetVisibility)
Events.ActivePlayerTurnStart.Add(resetVisibility)
Events.ActivePlayerTurnEnd.Add(closeForTransition)
Events.SerialEventEnterCityScreen.Add(closeForTransition)
Events.SerialEventExitCityScreen.Add(function()
 B.Schedule(Game.GetActivePlayer(),true)
 if ButtonPopupTypes then blocked[ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION]=nil end
 closeForTransition()
end)
Events.AILeaderMessage.Add(function() leaderScreen=true;closeForTransition() end)
Events.LeavingLeaderViewMode.Add(function() leaderScreen=false;closeForTransition() end)
Events.SerialEventGameMessagePopupShown.Add(function(info)
 if info and info.Type then blocked[info.Type]={capture=true};closeForTransition() end
end)
Events.SerialEventGameMessagePopupProcessed.Add(function(kind) blocked[kind]=nil;deferRefresh() end)
Events.InterfaceModeChanged.Add(closeForTransition)
Events.LoadScreenClose.Add(resetVisibility)
ContextPtr:SetShowHideHandler(function(hidden)
 if hidden then opened=false;Controls.Panel:SetHide(true) else resetVisibility() end
end)
refresh()
