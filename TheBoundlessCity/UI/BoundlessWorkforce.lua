include('InstanceManager')
include('BoundlessCore')
local B=MapModData.BoundlessCity
local instances=InstanceManager:new('BoundlessPlotRow','Root',Controls.Rows)
local opened,cityScreen,leaderScreen,refreshing=false,false,false,false
local blocked={};local page=1;local sort='DISTANCE';local message=''
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
 Controls.Summary:SetText(B.Text('SUMMARY',info.population,info.owned,info.localCount,info.remote,info.specialists,info.idle,info.available,info.progress,info.cost))
 Controls.Yields:SetText(B.Text('YIELDS',yields(cache.remoteYields or {}),yields(cache.labourerYields or {})))
 Controls.Mode:SetText(B.Text(s.mode));Controls.Priority:SetText(B.Text(s.priority))
 Controls.Direction:SetText(B.Text('DIRECTION')..': '..B.Text(s.direction));Controls.Sort:SetText(B.Text(sort))
 Controls.Help:SetText(message~='' and message or B.Text('CAPACITY'))
 local rows={}
 for _,n in ipairs(B.Keys(cache.owned)) do local plot=Map.GetPlotByIndex(n)
  if not locals[n] and B.Eligible(s,plot) then
   local resource=GameInfo.Resources[plot:GetResourceType(p:GetTeam())]
   local improvement=GameInfo.Improvements[plot:GetImprovementType()]
   rows[#rows+1]={n=n,plot=plot,distance=Map.PlotDistance(city:GetX(),city:GetY(),plot:GetX(),plot:GetY()),
    score=B.Score(s,plot),resource=resource and Locale.ConvertTextKey(resource.Description) or '',
    improvement=improvement and Locale.ConvertTextKey(improvement.Description) or ''}
  end
 end
 table.sort(rows,function(a,b)
  local x,y
  if sort=='YIELD' then x,y=-a.score,-b.score
  elseif sort=='RESOURCE' then x,y=a.resource,b.resource
  elseif sort=='IMPROVEMENT' then x,y=a.improvement,b.improvement
  else x,y=a.distance,b.distance end
  if x~=y then return x<y end;return a.n<b.n
 end)
 local pages=math.max(1,math.ceil(#rows/B.Config.PageSize));page=math.max(1,math.min(page,pages))
 instances:ResetInstances()
 for i=(page-1)*B.Config.PageSize+1,math.min(page*B.Config.PageSize,#rows) do
  local row=rows[i];local control=instances:GetInstance();local assigned=s.assignments[row.n]~=nil
  local locked=s.locks[row.n]~=nil
  control.Text:SetText((assigned and '[COLOR_POSITIVE_TEXT]' or '')..'('..row.plot:GetX()..','..row.plot:GetY()..')  '
   ..B.Text('DISTANCE')..' '..row.distance..'  '..row.resource..'  '..row.improvement
   ..(locked and ' [ICON_LOCKED]' or '')..(assigned and '[ENDCOLOR]' or '')..'[NEWLINE]'..yields(B.PlotYields(row.plot)))
  control.Assign:SetText(B.Text((assigned or locked) and 'RELEASE' or 'ASSIGN'))
  control.Lock:SetText(B.Text(locked and 'UNLOCK' or 'LOCK'))
  control.Lock:SetDisabled(not p:IsTurnActive())
  control.Assign:SetDisabled(not p:IsTurnActive())
  local n=row.n;local plot=row.plot
  control.Assign:RegisterCallback(Mouse.eLClick,function()
   message=B.Action(pid,'PLOT',n) and '' or B.Text('UNAVAILABLE');refresh()
  end)
  control.Lock:RegisterCallback(Mouse.eLClick,function() B.Action(pid,'LOCK',n);refresh() end)
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
Events.GameplaySetActivePlayer.Add(function() opened=false;refresh() end)
Events.ActivePlayerTurnStart.Add(refresh)
Events.ActivePlayerTurnEnd.Add(function() opened=false;refresh() end)
Events.SerialEventEnterCityScreen.Add(function() cityScreen=true;opened=false;refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityScreen=false;if ButtonPopupTypes then blocked[ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION]=nil end;refresh() end)
Events.AILeaderMessage.Add(function() leaderScreen=true;opened=false;refresh() end)
Events.LeavingLeaderViewMode.Add(function() leaderScreen=false;refresh() end)
Events.SerialEventGameMessagePopupShown.Add(function(info) if info and info.Type then blocked[info.Type]=true;opened=false;refresh() end end)
Events.SerialEventGameMessagePopupProcessed.Add(function(kind) blocked[kind]=nil;refresh() end)
Events.InterfaceModeChanged.Add(function(_,value) mode=value;if not world() then opened=false end;refresh() end)
Events.LoadScreenClose.Add(function() opened=false;blocked={};cityScreen=false;leaderScreen=false;mode=UI.GetInterfaceMode();refresh() end)
refresh()
