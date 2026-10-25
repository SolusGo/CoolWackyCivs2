include('URGAL_Core')
local U=MapModData.URGAL
local blocked,leader,city,hidden,ending={},false,false,false,false
local function Available()
 local id=Game.GetActivePlayer()
 return U.active and U.Civ(id) and Players[id]:IsHuman() and Players[id]:IsTurnActive() and not ending
  and not leader and not city and not hidden and not next(blocked) and not UI.IsCityScreenUp()
  and (not UI.IsGameCoreBusy or not UI.IsGameCoreBusy())
  and (not UI.GetInterfaceMode or UI.GetInterfaceMode()==InterfaceModeTypes.INTERFACEMODE_SELECTION)
end
function U.Refresh()
 local show=Available(); Controls.Inventory:SetHide(not show)
 if not show then return end
 local id=Game.GetActivePlayer(); local s=U.State(id)
 if not s then
  Controls.Stockpile:SetText(U.Text('UNAVAILABLE'));Controls.Status:SetText('');Controls.Drink:SetDisabled(true);return
 end
 local now=U.Turn(); local count=U.Count(id)
 Controls.Stockpile:SetText('[ICON_RES_WINE] '..U.Text('INVENTORY',s.potions))
 Controls.Status:SetText(now<s.finish and U.Text('ACTIVE_TURNS',s.finish-now) or now<s.ready and U.Text('AFTERTASTE',s.ready-now) or U.Text(count>0 and 'READY' or 'NO_ARMY'))
 Controls.Drink:SetText(U.Text(now<s.finish and 'ACTIVE' or s.potions==0 and 'EMPTY' or 'DRINK'))
 Controls.Drink:SetDisabled(not U.CanDrink(id))
 Controls.Drink:SetToolTipString(U.Text('TOOLTIP',U.Duration(),s.potions,count))
end
Controls.Drink:RegisterCallback(Mouse.eLClick,function()
 if Available() then U.Sync(Game.GetActivePlayer());U.Drink(Game.GetActivePlayer());U.Refresh() end
end)
-- One-shot refresh coalesces dirty notifications, then immediately detaches.
local queued=false
local function Queue()
 if queued then return end
 queued=true
 ContextPtr:SetUpdate(function() ContextPtr:ClearUpdate();queued=false;if U.active then U.Refresh() end end)
end
U.Hook(Events,'SerialEventGameDataDirty',Queue)
U.Hook(Events,'UnitSelectionChanged',Queue)
U.Hook(Events,'SerialEventEnterCityScreen',function() city=true;U.Refresh() end)
U.Hook(Events,'SerialEventExitCityScreen',function() city=false;Queue() end)
U.Hook(Events,'AILeaderMessage',function() leader=true;U.Refresh() end)
U.Hook(Events,'LeavingLeaderViewMode',function() leader=false;Queue() end)
U.Hook(Events,'SerialEventGameMessagePopupShown',function(info) if info and info.Type then blocked[info.Type]=true end;U.Refresh() end)
U.Hook(Events,'SerialEventGameMessagePopupProcessed',function(kind) blocked[kind]=nil;Queue() end)
U.Hook(Events,'ActivePlayerTurnEnd',function() ending=true;U.Refresh() end)
U.Hook(Events,'ActivePlayerTurnStart',function() ending=false;blocked={};city=false;leader=false;U.Sync(Game.GetActivePlayer());Queue() end)
U.Hook(Events,'GameplaySetActivePlayer',function() ending=false;blocked={};city=false;leader=false;Queue() end)
U.Hook(Events,'InterfaceModeChanged',Queue)
U.Hook(Events,'LoadScreenClose',function() ending=false;blocked={};city=false;leader=false;Queue() end)
ContextPtr:SetShowHideHandler(function(isHidden) hidden=isHidden;Queue() end)
U.Refresh()
