local function event() local callbacks={};local fire=function(...) for _,fn in ipairs(callbacks) do fn(...) end end
 return setmetatable({Add=function(fn) callbacks[#callbacks+1]=fn end,Fire=fire},{__call=function(_,...) fire(...) end}) end
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','ActivePlayerTurnEnd','SerialEventEnterCityScreen',
 'SerialEventExitCityScreen','AILeaderMessage','LeavingLeaderViewMode','SerialEventGameMessagePopupShown',
 'SerialEventGameMessagePopupProcessed','InterfaceModeChanged'}) do Events[name]=event() end
UI={GetInterfaceMode=function() return 0 end,IsCityScreenUp=function() return false end,LookAt=function() end}
InterfaceModeTypes={INTERFACEMODE_SELECTION=0};ButtonPopupTypes={BUTTONPOPUP_CHOOSEPRODUCTION=1}
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
function ContextPtr:SetInputHandler(fn) self.input=fn end
local function control()
 local c={hidden=false,text='',disabled=false}
 function c:SetHide(value) self.hidden=value end
 function c:SetText(value) self.text=value end
 function c:SetDisabled(value) self.disabled=value end
 function c:RegisterCallback(kind,fn) self.callback=fn end
 function c:CalculateSize() end;function c:ReprocessAnchoring() end;function c:CalculateInternalSize() end
 return c
end
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
Events.AILeaderMessage.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.LeavingLeaderViewMode.Fire();assert(not Controls.Launcher.hidden)
Controls.Open.callback();Events.SerialEventEnterCityScreen.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.SerialEventExitCityScreen.Fire();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=9});assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=9});Events.SerialEventGameMessagePopupProcessed.Fire(9);assert(not Controls.Launcher.hidden)
Controls.Open.callback();assert(ContextPtr.input(1,27));assert(Controls.Panel.hidden)
Pump();assert(deferred==nil,'UI must not install a permanent frame handler')
Controls.Open.callback();Controls.Siege.callback()
-- The benchmark reuses these controls on maps without a foreign city.
if Map.GetPlot(60,5):GetPlotCity()==foreign then
assert(#UIRows==1 and UIRows[1].Assign.disabled and UIRows[1].Text.text:find('SIEGE_PROTECTED'))
foreign.revealed=false;Events.SerialEventCityInfoDirty.Fire();assert(#UIRows==0,'undiscovered city must not leak through siege UI')
foreign.revealed=true;Map.GetPlot(60,5).visible=false;Events.SerialEventCityInfoDirty.Fire()
assert(UIRows[1].Assign.disabled and UIRows[1].Text.text:find('SIEGE_NOT_VISIBLE') and UIRows[1].Text.text:find('SIEGE_KNOWN_CITY'))
Map.GetPlot(60,5).visible=true
end
Controls.Siege.callback();Controls.Close.callback();Pump()
assert(deferred==nil,'siege refresh must remain event-driven')
print('PASS UI: launcher, paged rows, city/diplomacy/popup hiding and Escape with no idle polling')
