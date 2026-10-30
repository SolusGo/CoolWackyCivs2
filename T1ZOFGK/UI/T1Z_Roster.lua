include('T1Z_Controller')
include('CWC2_Screen')
local panelOpen=false
local uiRecovery
local function Refresh()
  local pid=Game.GetActivePlayer()
  local available=T1Z and T1Z.IsPlayer(pid) and uiRecovery and uiRecovery:Available()
  Controls.Launcher:SetHide(not available)
  Controls.Panel:SetHide(not available or not panelOpen)
  if available then
    local summary=T1Z.Summary(pid)
    Controls.Open:SetToolTipString(summary)
    if panelOpen then
      Controls.Summary:SetText(summary)
      Controls.Scroll:CalculateInternalSize();Controls.Scroll:ReprocessAnchoring()
    end
  end
end
uiRecovery=CWC2_Screen.New{name='T1 ZOFGK',context=ContextPtr,civ='CIVILIZATION_T1Z_ZOFGK',
  roots={Controls.Launcher,Controls.Panel},panels={Controls.Panel},
  refresh=Refresh,close=function()panelOpen=false end}
Controls.Open:RegisterCallback(Mouse.eLClick,function() panelOpen=not panelOpen;Refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function()panelOpen=false;Refresh()end)
LuaEvents.T1Z_RosterChanged.Add(Refresh)
ContextPtr:SetInputHandler(function(message,key)
  if not uiRecovery:Available() then return false end
  if message==KeyEvents.KeyDown and key==Keys.VK_ESCAPE and panelOpen then
    panelOpen=false;Refresh();return true
  end
  return false
end)
uiRecovery:Sync();Refresh()
