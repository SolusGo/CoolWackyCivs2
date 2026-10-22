local instances=0
local function control()
 local t={hidden=false,disabled=false,text='',callbacks={}}
 function t:SetHide(value) self.hidden=value end;function t:SetDisabled(value) self.disabled=value end
 function t:SetText(value) self.text=value end;function t:SetToolTipString(value) self.tooltip=value end
 function t:RegisterCallback(_,fn) self.click=fn end
 function t:CalculateSize() end;function t:ReprocessAnchoring() end;function t:CalculateInternalSize() end
 function t:IsHidden() return self.hidden end
 return t
end
Controls=setmetatable({}, {__index=function(t,k) local c=control();rawset(t,k,c);return c end})
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27};InterfaceModeTypes={INTERFACEMODE_SELECTION=1}
UI={IsCityScreenUp=function() return false end,GetInterfaceMode=function() return 1 end,SelectUnit=function(u) UI.selected=u end,LookAt=function() end}
function IconHookup(index,size,atlas,control) control.icon={index,size,atlas} end
InstanceManager={new=function() return {GetInstance=function() instances=instances+1;return {Button=control(),Portrait=control(),Name=control(),State=control()} end} end}
function ContextPtr:LookUpControl() return nil end
function ContextPtr:SetInputHandler(fn) self.input=fn end;function ContextPtr:SetShowHideHandler(fn) self.show=fn end
LoadUI()
local H=MapModData.THE11CATS
assert(instances==11 and not Controls.Launcher.hidden)
Controls.Open.click();assert(not Controls.Panel.hidden and Controls.Title.text:find(':2',1,true))
local a=City(0,1,10,10);H.Reconcile(0,true)
Events.UnitSelectionChanged(0,H.State(0).cats.LUNA.unit);H.Render()
Controls.Locate.click();assert(UI.selected)
UI.selected:MoveTo(a);H.Render();assert(not Controls.Action.disabled)
Controls.Action.click();assert(H.State(0).cats.LUNA.status==2)
Controls.Action.click();assert(H.State(0).cats.LUNA.status==1 and Controls.Action.disabled)
assert(Controls.DetailState.text:find('COOLDOWN',1,true))
Controls.Homes.click();assert(not Controls.HomesScroll.hidden and Controls.HomesText.text:find('Home 1',1,true))
for i=1,100 do H.Render() end;assert(instances==11)
Events.AILeaderMessage();assert(Controls.Launcher.hidden and Controls.Panel.hidden)
assert(not H.Command(0,'LUNA','SETTLE'))
Events.LeavingLeaderViewMode();Flush();assert(not Controls.Launcher.hidden)
UI.IsCityScreenUp=function() return true end;Events.SerialEventEnterCityScreen();assert(Controls.Launcher.hidden)
UI.IsCityScreenUp=function() return false end;Events.SerialEventExitCityScreen();Flush();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown({Type=7});assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed(7);Flush();assert(not Controls.Launcher.hidden)
Controls.Open.click();Controls.Story.click();assert(not Controls.Narrative.hidden)
Controls.StoryClose.click();assert(Controls.Narrative.hidden)
assert(ContextPtr.input(KeyEvents.KeyDown,Keys.VK_ESCAPE) and Controls.Panel.hidden)
print('PASS household UI: 11 reusable portraits, validated actions, cooldowns, homes, selected cat and modal visibility')
