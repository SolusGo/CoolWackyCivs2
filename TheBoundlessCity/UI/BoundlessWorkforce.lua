include('InstanceManager')
include('BoundlessCore')
local B=MapModData.BoundlessCity
local instances=InstanceManager:new('BoundlessPlotRow','Root',Controls.Rows)
local opened,cityScreen,leaderScreen,refreshing=false,false,false,false
local blocked={};local page=1;local sort='DISTANCE';local message=''
local siege=false
local mode=UI.GetInterfaceMode()
local refresh
local function world()
 return not cityScreen and not leaderScreen and not next(blocked)
  and not UI.IsCityScreenUp() and mode==InterfaceModeTypes.INTERFACEMODE_SELECTION
end
local function yields(values)
 local words={};for i,y in ipairs(B.Yields) do words[#words+1]=(values[i] or 0)..' '..B.Text(y.name) end
 return table.concat(words,' / ')
end
refresh=function()
 if refreshing then return end;refreshing=true
 local pid=Game.GetActivePlayer();local p=Players[pid]
 local visible=B.IsBoundless(pid) and p:IsHuman() and p:IsAlive() and world()
 local s=visible and B.State(pid);local city=s and B.City(s)
 visible=visible and city~=nil and not s.incompatible
 Controls.Launcher:SetHide(not visible)
 if not visible then opened=false end
 Controls.Panel:SetHide(not opened)
 if not opened then refreshing=false;return end
 local info=B.Summary(s);local cache=B.Ownership(s);local locals=B.LocalPlots(city)
 local summary=B.Text('SUMMARY',info.population,info.owned,info.localCount,info.remote,info.specialists,info.idle,info.unassigned,info.availableCitizens,info.availableRemote,info.maximumRemote,info.pending,info.locks,info.progress,info.cost)
 if info.automata>0 then summary=summary..'[NEWLINE]'..B.Text('AUTOMATONS',info.automata) end
 Controls.Summary:SetText(summary)
 local net={};for i=1,#B.Yields do net[i]=(cache.remoteYields and cache.remoteYields[i] or 0)-(cache.labourerYields and cache.labourerYields[i] or 0) end
 Controls.Yields:SetText(B.Text('YIELDS',yields(cache.remoteYields or {}),yields(cache.labourerYields or {}),yields(net)))
 Controls.Mode:SetText(B.Text(s.mode));Controls.Priority:SetText(B.Text(s.priority))
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
   control.Text:SetText(row.name..'  ('..row.x..','..row.y..')[NEWLINE]'..B.Text(row.reason))
   control.Assign:SetText(B.Text('DEMOLISH'));control.Lock:SetHide(true)
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
 refreshing=false
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
Events.SerialEventCityInfoDirty.Add(function() if opened and siege then refresh() end end)
Events.GameplaySetActivePlayer.Add(function() opened=false;refresh() end)
Events.ActivePlayerTurnStart.Add(refresh)
Events.ActivePlayerTurnEnd.Add(function() opened=false;refresh() end)
Events.SerialEventEnterCityScreen.Add(function() cityScreen=true;opened=false;refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityScreen=false;B.Schedule(Game.GetActivePlayer(),true);if ButtonPopupTypes then blocked[ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION]=nil end;refresh() end)
Events.AILeaderMessage.Add(function() leaderScreen=true;opened=false;refresh() end)
Events.LeavingLeaderViewMode.Add(function() leaderScreen=false;refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function(info) if info and info.Type then blocked[info.Type]=true;opened=false;refresh() end end)
Events.SerialEventGameMessagePopupProcessed.Add(function(kind) blocked[kind]=nil;refresh() end)
Events.InterfaceModeChanged.Add(function(_,value) mode=value;if not world() then opened=false end;refresh() end)
Events.LoadScreenClose.Add(function() opened=false;blocked={};cityScreen=false;leaderScreen=false;mode=UI.GetInterfaceMode();refresh() end)
refresh()
