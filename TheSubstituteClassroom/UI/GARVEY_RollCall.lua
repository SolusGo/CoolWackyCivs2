include('GARVEY_Core')
include('GARVEY_Interface')
local G=MapModData.Garvey
local opened,queued,rendering=false,false,false
local expected
local interface=G.interface
local function eligible()
 local pid=Game.GetActivePlayer()
 return G.Human(pid) and Players[pid]:IsTurnActive() and G.InterfaceReady()
end
local function render()
 local pid=Game.GetActivePlayer();local show=eligible();local s=G.Human(pid) and G.State(pid)
 if not show then opened=false end
 Controls.Launcher:SetHide(not show);Controls.Panel:SetHide(not (show and opened))
 if not show then return end
 if not s then
  Controls.LauncherStatus:SetText(G.Text('DISABLED'))
  for i=1,5 do Controls['Student'..i]:SetDisabled(true) end
  Controls.Cooldown:SetText(G.Text('DISABLED'));Controls.PatienceMeter:SetText('');return
 end
 local ready=s.clock>=s.ready;local detained=G.Active(s,'detEnd');local student=G.Student(s)
 local cooldown=ready and G.Text('AVAILABLE') or G.Text('WAIT',s.ready-s.clock)
 Controls.LauncherStatus:SetText(detained and '[COLOR_NEGATIVE_TEXT]DETENTION! '..(s.detEnd-s.clock)..'[ENDCOLOR]'
  or ready and '[COLOR_POSITIVE_TEXT]Attendance ready[ENDCOLOR]' or G.Text('WAIT',s.ready-s.clock))
 Controls.Open:SetToolTipString(cooldown)
 if not opened then return end
 expected=s.ready
 Controls.Cooldown:SetText(cooldown)
 Controls.Current:SetText(student>0 and G.Text('CURRENT',G.Text('STUDENT_'..student),s.bonusEnd-s.clock) or G.Text('NONE'))
 local names={'CALM','IRRITATED','FURIOUS'}
 local patience=G.Text('PATIENCE',s.insub,G.Text(names[s.insub+1]))
 if s.insub>0 then patience=(s.insub==2 and '[COLOR_NEGATIVE_TEXT]' or '[COLOR_WARNING_TEXT]')..patience..'[ENDCOLOR]' end
 Controls.Patience:SetText(detained and G.Text('DETENTION_STATUS',s.detEnd-s.clock) or patience)
 local level=detained and 3 or s.insub;local dots={}
 for i=1,3 do
  local color=i<=level and (level>=2 and 'COLOR_NEGATIVE_TEXT' or 'COLOR_WARNING_TEXT') or 'COLOR_GREY'
  dots[i]='['..color..'][ICON_BULLET][ENDCOLOR]'
 end
 Controls.PatienceMeter:SetText(table.concat(dots,'  '))
 Controls.PatienceMeter:SetToolTipString(detained and G.Text('DETENTION_STATUS',s.detEnd-s.clock) or patience)
 local office=detained and G.HasOffice(pid)
 Controls.Detention:SetText(detained and G.Text('DETENTION_DETAIL',G.config.DetentionUnhappiness-(office and G.config.OfficeRelief or 0)) or G.Text('NO_DETENTION'))
 for i=1,5 do Controls['Student'..i]:SetDisabled(not G.CanRoll(pid,expected)) end
 Controls.Sheet:CalculateSize();Controls.Sheet:ReprocessAnchoring();Controls.Scroll:CalculateInternalSize()
end
local function refresh()
 if rendering then return end;rendering=true
 local ok=G.Guard('Roll Call display',render);rendering=false
 if not ok then opened=false;Controls.Panel:SetHide(true) end
end
-- Shared one-shot dispatcher for dirty work and modal transitions. It detaches
-- before doing anything; no high-frequency or permanent frame polling.
function G.QueueRefresh()
 if queued then return end;queued=true
 ContextPtr:SetUpdate(function()
  ContextPtr:ClearUpdate();queued=false;interface.transition=false;G.Flush();refresh()
 end)
end
local function closeTransition()
 opened=false;interface.transition=true;refresh();G.QueueRefresh()
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;refresh() end)
for i=1,5 do
 local student=i
 Controls['Student'..i]:RegisterCallback(Mouse.eLClick,function()
  if opened and eligible() then G.Roll(Game.GetActivePlayer(),student,expected);refresh() end
 end)
end
G.Hook(LuaEvents,'GARVEY_Changed',function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
G.Hook(Events,'SerialEventGameDataDirty',G.QueueRefresh)
G.Hook(Events,'SerialEventCityInfoDirty',G.QueueRefresh)
G.Hook(Events,'SerialEventEnterCityScreen',closeTransition)
G.Hook(Events,'SerialEventExitCityScreen',function()
 if ButtonPopupTypes then interface.blocked[ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION]=nil end
 closeTransition()
end)
G.Hook(Events,'AILeaderMessage',function() interface.leader=true;closeTransition() end)
G.Hook(Events,'LeavingLeaderViewMode',function() interface.leader=false;closeTransition() end)
G.Hook(Events,'StrategicViewStateChanged',function(strategic) interface.strategic=strategic;closeTransition() end)
G.Hook(Events,'SerialEventGameMessagePopupShown',function(info)
 if info and info.Type then interface.blocked[info.Type]={capture=true} end
 closeTransition()
end)
G.Hook(Events,'SerialEventGameMessagePopupProcessed',function(kind) interface.blocked[kind]=nil;closeTransition() end)
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','LoadScreenClose'}) do
 G.Hook(Events,name,function() interface.blocked={};interface.leader=false;closeTransition() end)
end
G.Hook(Events,'ActivePlayerTurnEnd',closeTransition)
G.Hook(Events,'InterfaceModeChanged',closeTransition)
ContextPtr:SetShowHideHandler(function(hidden) interface.hidden=hidden;closeTransition() end)
ContextPtr:SetInputHandler(function(msg,key)
 if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then opened=false;refresh();return true end
 return false
end)
refresh()
