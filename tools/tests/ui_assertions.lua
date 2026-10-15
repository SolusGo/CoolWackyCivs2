local function event() local callbacks={};local fire=function(...) for _,fn in ipairs(callbacks) do fn(...) end end
 return setmetatable({Add=function(fn) callbacks[#callbacks+1]=fn end,Fire=fire},{__call=function(_,...) fire(...) end}) end
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','ActivePlayerTurnEnd','SerialEventEnterCityScreen',
 'SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopupShown',
 'SerialEventGameMessagePopupProcessed','InterfaceModeChanged','SerialEventGameDataDirty'}) do Events[name]=event() end
local native={mode=0,city=false,leader=false,turn=true}
UI={GetInterfaceMode=function() return native.mode end,IsCityScreenUp=function() return native.city end,
 GetLeaderHeadRootUp=function() return native.leader end,LookAt=function() end}
local turnActive=Players[0].IsTurnActive
Players[0].IsTurnActive=function() return native.turn end
InterfaceModeTypes={INTERFACEMODE_SELECTION=0};ButtonPopupTypes={BUTTONPOPUP_CHOOSEPRODUCTION=1}
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
function ContextPtr:SetInputHandler(fn) self.input=fn end
function ContextPtr:SetShowHideHandler(fn) self.showHide=fn end
local function control()
 local c={hidden=false,text='',disabled=false}
 function c:SetHide(value) self.hidden=value end
 function c:IsHidden() return self.hidden end
 function c:SetText(value) self.text=value end
 function c:SetDisabled(value) self.disabled=value end
 function c:RegisterCallback(kind,fn) self.callback=fn end
 function c:CalculateSize() end;function c:ReprocessAnchoring() end;function c:CalculateInternalSize() end
 return c
end
local nativeScreens={}
for _,path in ipairs({'/InGame/SocialPolicyPopup','/InGame/DeclareWarPopup','/InGame/ProductionPopup','/LeaderHeadRoot'}) do
 nativeScreens[path]=control();nativeScreens[path].hidden=true
end
function ContextPtr:LookUpControl(path) return nativeScreens[path] end
Controls={};for _,name in ipairs({'Rows','Launcher','Panel','Summary','Yields','Mode','Priority','Direction','Sort','Help','Page','Previous','Next','Scroll','Open','Close','Siege'}) do Controls[name]=control() end
InstanceManager={}
function InstanceManager:new()
 local manager={count=0}
 function manager:ResetInstances() self.count=0;UIRows={} end
 function manager:GetInstance() self.count=self.count+1;assert(self.count<=16,'UI rows must be paged');local row={Text=control(),Assign=control(),Lock=control(),Locate=control()};UIRows[#UIRows+1]=row;return row end
 return manager
end
LoadWorkforceUI()
assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
Controls.Open.callback();assert(not Controls.Panel.hidden)
capital.automatons=1;capital.unassigned=1;LuaEvents.BoundlessChanged.Fire(0);assert(Controls.Summary.text:find('AUTOMATONS'))
capital.automatons=0;capital.unassigned=0;LuaEvents.BoundlessChanged.Fire(0)
native.leader=true;nativeScreens['/LeaderHeadRoot'].hidden=false
Events.AILeaderMessage.Fire();Pump();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
native.leader=false;nativeScreens['/LeaderHeadRoot'].hidden=true
Events.LeavingLeaderViewMode.Fire();Pump();assert(not Controls.Launcher.hidden)
Controls.Open.callback();native.city=true
Events.SerialEventEnterCityScreen.Fire();Pump();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
native.city=false;Events.SerialEventExitCityScreen.Fire();Pump();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=9});Pump();assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=9});Events.SerialEventGameMessagePopupProcessed.Fire(9);Pump();assert(not Controls.Launcher.hidden)
Controls.Open.callback();assert(ContextPtr.input(1,27));assert(Controls.Panel.hidden)
Pump();assert(deferred==nil,'UI must not install a permanent frame handler')

-- Native screen state changes independently of notifications. A missed close
-- must recover even when the panel was closed, and a premature Processed must
-- not expose the launcher over a still-visible native popup.
local policy=nativeScreens['/InGame/SocialPolicyPopup']
policy.hidden=false;Events.SerialEventGameMessagePopupShown.Fire({Type=10});Pump()
assert(Controls.Launcher.hidden)
policy.hidden=true;Events.SerialEventGameDataDirty.Fire();Pump()
assert(not Controls.Launcher.hidden,'missed popup Processed must not latch launcher hidden')
local war=nativeScreens['/InGame/DeclareWarPopup']
war.hidden=false;Events.SerialEventGameMessagePopupShown.Fire({Type=11})
Events.SerialEventGameMessagePopupProcessed.Fire(11);Pump()
assert(Controls.Launcher.hidden,'early popup Processed must defer to actual visible screen')
war.hidden=true;Events.SerialEventCityInfoDirty.Fire();Pump();assert(not Controls.Launcher.hidden)
-- Multiple visible native screens remain conservative until both are closed.
policy.hidden=false;war.hidden=false;Events.SerialEventGameMessagePopupShown.Fire({Type=12});Pump()
policy.hidden=true;Events.SerialEventGameDataDirty.Fire();Pump();assert(Controls.Launcher.hidden)
war.hidden=true;Events.SerialEventGameDataDirty.Fire();Pump();assert(not Controls.Launcher.hidden)
native.city=true;Events.SerialEventEnterCityScreen.Fire();Pump();assert(Controls.Launcher.hidden)
native.city=false;Events.SerialEventGameDataDirty.Fire();Pump()
assert(not Controls.Launcher.hidden,'native city close recovers without ExitCityScreen')
native.mode=1;Events.InterfaceModeChanged.Fire(0,1);Pump();assert(Controls.Launcher.hidden)
native.mode=0;Events.SerialEventGameDataDirty.Fire();Pump()
assert(not Controls.Launcher.hidden,'mode queries must not retain stale event arguments')
nativeScreens['/LeaderHeadRoot'].hidden=false;Events.AILeaderMessage.Fire();Pump()
assert(Controls.Launcher.hidden,'diplomacy subdialogs stay hidden even with root-up flag false')
nativeScreens['/LeaderHeadRoot'].hidden=true;Events.SerialEventGameDataDirty.Fire();Pump()
assert(not Controls.Launcher.hidden,'native leader close recovers without LeavingLeaderViewMode')
-- Close notifications may arrive before the native context actually hides.
native.city=true;Events.SerialEventEnterCityScreen.Fire();Pump()
Events.SerialEventExitCityScreen.Fire();native.city=false;Pump();assert(not Controls.Launcher.hidden)
for _,name in ipairs({'ActivePlayerTurnStart','LoadScreenClose','GameplaySetActivePlayer'}) do
 Events.SerialEventGameMessagePopupShown.Fire({Type=999});Pump();assert(Controls.Launcher.hidden)
 policy.hidden=false;Events[name].Fire();Pump();assert(Controls.Launcher.hidden,'lifecycle reset cannot bypass native popup')
 policy.hidden=true;Events.SerialEventGameDataDirty.Fire();Pump();assert(not Controls.Launcher.hidden)
end
-- Unknown third-party contexts retain event blocking, with a turn fallback.
Events.SerialEventGameMessagePopupShown.Fire({Type=999});Pump();Events.SerialEventGameDataDirty.Fire();Pump()
assert(Controls.Launcher.hidden);Events.ActivePlayerTurnStart.Fire();Pump();assert(not Controls.Launcher.hidden)
native.turn=false;Events.ActivePlayerTurnEnd.Fire();Pump();assert(Controls.Launcher.hidden)
native.turn=true;Events.ActivePlayerTurnStart.Fire();Pump();assert(not Controls.Launcher.hidden)
Controls.Open.callback();ContextPtr.showHide(true);assert(Controls.Panel.hidden)
ContextPtr.showHide(false);Pump();assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
-- A rendering exception cannot leave the reentrancy guard set forever.
local summary=MapModData.BoundlessCity.Summary
MapModData.BoundlessCity.Summary=function() error('injected UI rendering failure') end
Controls.Open.callback();assert(Controls.Panel.hidden)
MapModData.BoundlessCity.Summary=summary;Controls.Open.callback();assert(not Controls.Panel.hidden)
Controls.Close.callback()
-- UI-only refresh storms neither reconcile gameplay nor leave an idle update.
local B=MapModData.BoundlessCity;local reconcile=B.Reconcile;local calls=0
B.Reconcile=function(s) calls=calls+1;return reconcile(s) end
local sets=ContextPtr.updatesSet
for i=1,1000 do Events.SerialEventGameDataDirty.Fire() end
assert(ContextPtr.updatesSet==sets+1);Pump();assert(calls==0 and deferred==nil)
Events.SerialEventGameDataDirty.Fire();B.Schedule(0);Pump()
assert(calls==1 and deferred==nil,'UI refresh must share, never replace, gameplay dispatch')
-- A new transition during gameplay dispatch belongs to the following frame;
-- the older captured UI refresh must not clear it or bind to the old screen.
B.Reconcile=function(s)
 Events.SerialEventGameMessagePopupShown.Fire({Type=13})
 return reconcile(s)
end
Events.SerialEventGameDataDirty.Fire();B.Schedule(0);Pump()
assert(Controls.Launcher.hidden and deferred~=nil)
policy.hidden=false;Pump();assert(Controls.Launcher.hidden and deferred==nil)
policy.hidden=true;Events.SerialEventGameDataDirty.Fire();Pump();assert(not Controls.Launcher.hidden)
B.Reconcile=reconcile
local writes=mutations;for i=1,1000 do Pump() end;assert(mutations==writes and deferred==nil)
Controls.Open.callback();Controls.Siege.callback()
-- The benchmark reuses these controls on maps without a foreign city.
if Map.GetPlot(60,5):GetPlotCity()==foreign then
assert(#UIRows==1 and UIRows[1].Assign.disabled and UIRows[1].Text.text:find('SIEGE_CAPITAL'))
foreign.revealed=false;Events.SerialEventCityInfoDirty.Fire();assert(#UIRows==0,'undiscovered city must not leak through siege UI')
foreign.revealed=true;Map.GetPlot(60,5).visible=false;Events.SerialEventCityInfoDirty.Fire()
assert(UIRows[1].Assign.disabled and UIRows[1].Text.text:find('SIEGE_NOT_VISIBLE') and UIRows[1].Text.text:find('SIEGE_KNOWN_CITY'))
Map.GetPlot(60,5).visible=true
local s=MapModData.BoundlessCity.State(0)
local unit=MakeUnit(99,600);function unit:GetX() return 2 end;function unit:GetY() return 5 end
function unit:MovesLeft() return 60 end
capital.owner=1;capital.damage=199;Players[0].cities={};Players[1].cities[#Players[1].cities+1]=capital
LuaEvents.BoundlessChanged.Fire(0);assert(not Controls.Launcher.hidden and Controls.Summary.text:find('CAPITAL_LOST'))
local reclaim=false;for _,r in ipairs(UIRows) do if r.Assign.text:find('RECLAIM') then reclaim=not r.Assign.disabled end end
assert(reclaim,'lost-capital panel must offer the eligible reclaim action')
assert(Controls.Mode.disabled and Controls.Priority.disabled)
capital.owner=0;Players[0].cities={capital};Players[1].cities[#Players[1].cities]=nil
LuaEvents.BoundlessChanged.Fire(0);assert(not Controls.Mode.disabled)
end
Controls.Siege.callback();Controls.Close.callback();Pump()
assert(deferred==nil,'siege refresh must remain event-driven')
Players[0].IsTurnActive=turnActive
print('PASS UI: missed/early popup, city/mode/leader close, turn/load/context recovery, render failure, 1,000 refreshes, shared dispatch, paged siege and no idle polling')
