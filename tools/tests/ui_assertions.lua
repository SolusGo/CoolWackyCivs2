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
Controls={};for _,name in ipairs({'Rows','Launcher','Panel','Summary','Yields','Mode','Priority','Direction','Sort','Help','Page','Previous','Next','Scroll','Open','Close'}) do Controls[name]=control() end
InstanceManager={}
function InstanceManager:new()
 local manager={count=0}
 function manager:ResetInstances() self.count=0 end
 function manager:GetInstance() self.count=self.count+1;assert(self.count<=16,'UI rows must be paged');return {Text=control(),Assign=control(),Lock=control(),Locate=control()} end
 return manager
end
LoadWorkforceUI()
assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
Controls.Open.callback();assert(not Controls.Panel.hidden)
Events.AILeaderMessage.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.LeavingLeaderViewMode.Fire();assert(not Controls.Launcher.hidden)
Controls.Open.callback();Events.SerialEventEnterCityScreen.Fire();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.SerialEventExitCityScreen.Fire();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=9});assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown.Fire({Type=9});Events.SerialEventGameMessagePopupProcessed.Fire(9);assert(not Controls.Launcher.hidden)
Controls.Open.callback();assert(ContextPtr.input(1,27));assert(Controls.Panel.hidden)
assert(deferred==nil,'UI must not install a permanent frame handler')
print('PASS UI: launcher, paged rows, city/diplomacy/popup hiding and Escape with no idle polling')
