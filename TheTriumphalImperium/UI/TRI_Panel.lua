include('TRI_Gameplay')
include('CWC2_Screen')
if TRI.panelReady then return end
TRI.panelReady = true
local recovery
local function paint()
  local player = Players[Game.GetActivePlayer()]
  local visible = TRI.IsImperium(player) and recovery:Available()
  Controls.MomentumPanel:SetHide(not visible)
  if not visible then return end
  local m = TRI.Momentum(player)
  Controls.MomentumTitle:SetText(Locale.ConvertTextKey('TXT_KEY_TRI_UI_TITLE', m))
  Controls.MomentumEffects:SetText(Locale.ConvertTextKey('TXT_KEY_TRI_UI_EFFECTS', m*2, m*4))
  for i=1,6 do Controls['Laurel'..i]:SetAlpha(i <= m and 1 or 0.18) end
  local status = Locale.ConvertTextKey(m >= 4 and 'TXT_KEY_TRI_UI_ACTIVE' or 'TXT_KEY_TRI_UI_INACTIVE')
  Controls.MomentumPanel:SetToolTipString(Locale.ConvertTextKey('TXT_KEY_TRI_UI_TIP', m, m*2, m*4, status))
end
recovery = CWC2_Screen.New{
  name='Triumphal Imperium', context=ContextPtr, civ='CIVILIZATION_TRIUMPHAL_IMPERIUM',
  roots={Controls.MomentumPanel}, panels={Controls.MomentumPanel}, refresh=paint,
}
function TRI.RefreshUI()
  recovery:Refresh()
end
TRI.RefreshUI()
