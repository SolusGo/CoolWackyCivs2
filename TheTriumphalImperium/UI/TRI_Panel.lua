include('TRI_Gameplay')
if TRI.panelReady then return end
TRI.panelReady = true
local cityScreen, leaderScreen = false, false
function TRI.RefreshUI()
  local player = Players[Game.GetActivePlayer()]
  local visible = TRI.IsImperium(player) and not cityScreen and not leaderScreen
  Controls.MomentumPanel:SetHide(not visible)
  if not visible then return end
  local m = TRI.Momentum(player)
  Controls.MomentumTitle:SetText(Locale.ConvertTextKey('TXT_KEY_TRI_UI_TITLE', m))
  Controls.MomentumEffects:SetText(Locale.ConvertTextKey('TXT_KEY_TRI_UI_EFFECTS', m*2, m*4))
  for i=1,6 do Controls['Laurel'..i]:SetAlpha(i <= m and 1 or 0.18) end
  local status = Locale.ConvertTextKey(m >= 4 and 'TXT_KEY_TRI_UI_ACTIVE' or 'TXT_KEY_TRI_UI_INACTIVE')
  Controls.MomentumPanel:SetToolTipString(Locale.ConvertTextKey('TXT_KEY_TRI_UI_TIP', m, m*2, m*4, status))
end
TRI.Hook(Events, 'GameplaySetActivePlayer', TRI.RefreshUI)
TRI.Hook(Events, 'ActivePlayerTurnStart', TRI.RefreshUI)
TRI.Hook(Events, 'LoadScreenClose', function() cityScreen=false; leaderScreen=false; TRI.RefreshUI() end)
TRI.Hook(Events, 'SerialEventEnterCityScreen', function() cityScreen=true; TRI.RefreshUI() end)
TRI.Hook(Events, 'SerialEventExitCityScreen', function() cityScreen=false; TRI.RefreshUI() end)
TRI.Hook(Events, 'AILeaderMessage', function() leaderScreen=true; TRI.RefreshUI() end)
TRI.Hook(Events, 'LeavingLeaderViewMode', function() leaderScreen=false; TRI.RefreshUI() end)
TRI.RefreshUI()
