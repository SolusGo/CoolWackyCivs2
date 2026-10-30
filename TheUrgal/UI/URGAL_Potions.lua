local uiRecovery -- UI state is transient; never part of a gameplay save.
include('SupportFunctions') -- native TruncateString measures the actual game font
include('URGAL_Core')
local U=MapModData.URGAL
if U.uiContext==U.context then U.Refresh();return end
U.uiContext=U.context
local blocked,leader,city,hidden,ending={},false,false,false,false
local function Available()
 local id=Game.GetActivePlayer()
 return U.active and U.Civ(id) and Players[id]:IsHuman() and Players[id]:IsTurnActive() and not ending
  and not leader and not city and not hidden and not next(blocked) and not UI.IsCityScreenUp()
  and (not UI.IsGameCoreBusy or not UI.IsGameCoreBusy())
  and (not UI.GetInterfaceMode or UI.GetInterfaceMode()==InterfaceModeTypes.INTERFACEMODE_SELECTION)
end
function U.Refresh()
 if uiRecovery then uiRecovery:Sync() end
 local show=Available();
 show=show and (not uiRecovery or uiRecovery:Available())
 Controls.Inventory:SetHide(not show)
 if not show then return end
 local id=Game.GetActivePlayer(); local s=U.State(id)
 if not s then
  Controls.Stockpile:SetText(U.Text('UNAVAILABLE'));Controls.Status:SetText('');Controls.Drink:SetDisabled(true);return
 end
 local now=U.Turn(); local count=U.Count(id)
 Controls.PotionArmy:SetText("Affected army: "..count.." eligible melee units")
 local stockpile=U.Text('INVENTORY',s.potions)
 TruncateString(Controls.Stockpile,226,stockpile)
 Controls.Stockpile:SetToolTipString(stockpile)
 Controls.Status:SetText(now<s.finish and U.Text('ACTIVE_TURNS',s.finish-now) or now<s.ready and U.Text('AFTERTASTE',s.ready-now) or U.Text(count>0 and 'READY' or 'NO_ARMY',count))
 Controls.Drink:SetText(U.Text(now<s.finish and 'ACTIVE' or now<s.ready and 'DRINK' or s.potions==0 and 'EMPTY' or 'DRINK'))
 Controls.Drink:SetDisabled(not U.CanDrink(id))
 Controls.Drink:SetToolTipString(U.Text('TOOLTIP',U.Duration(),s.potions,count,U.Aftertaste()))
end
Controls.Drink:RegisterCallback(Mouse.eLClick,function()
 if Available() then U.Sync(Game.GetActivePlayer());U.Drink(Game.GetActivePlayer());U.Refresh() end
end)
-- One-shot refresh coalesces dirty notifications, then immediately detaches.
local queued=false
local function Queue()
 if not U.active or queued then return end
 queued=true
 U.context:SetUpdate(function()
  if not U.active then return end
  U.context:ClearUpdate();queued=false;U.Refresh()
 end)
end
U.QueueRefresh=Queue
U.Hook(Events,'SerialEventGameDataDirty',Queue)
U.Hook(Events,'UnitSelectionChanged',Queue)
U.Hook(Events,'SerialEventEnterCityScreen',function() city=true;U.Refresh() end)
U.Hook(Events,'SerialEventExitCityScreen',function() city=false;Queue() end)
U.Hook(Events,'AILeaderMessage',function() leader=true;U.Refresh() end)
U.Hook(Events,'LeavingLeaderViewMode',function() leader=false;Queue() end)
U.Hook(Events,'SerialEventGameMessagePopupShown',function(info)
 if info and info.Type then blocked[info.Type]=(blocked[info.Type] or 0)+1 end
 U.Refresh()
end)
U.Hook(Events,'SerialEventGameMessagePopupProcessed',function(kind)
 local remaining=(blocked[kind] or 0)-1
 blocked[kind]=remaining>0 and remaining or nil
 Queue()
end)
U.Hook(Events,'ActivePlayerTurnEnd',function() ending=true;U.Refresh() end)
U.Hook(Events,'ActivePlayerTurnStart',function() ending=false;blocked={};city=false;leader=false;U.Sync(Game.GetActivePlayer());Queue() end)
U.Hook(Events,'GameplaySetActivePlayer',function() ending=false;blocked={};city=false;leader=false;Queue() end)
U.Hook(Events,'InterfaceModeChanged',Queue)
U.Hook(Events,'LoadScreenClose',function() ending=false;blocked={};city=false;leader=false;Queue() end)
U.context:SetShowHideHandler(function(isHidden) if U.active then hidden=isHidden;Queue() end end)
U.Refresh()

-- Shared screen recovery: actual native visibility wins over stale event flags.
local helperLoaded=pcall(include,'CWC2_Screen')
if CWC2_Screen then
 uiRecovery=CWC2_Screen.New{name='TheUrgal',civ='CIVILIZATION_URGAL',context=ContextPtr,
  roots={Controls.Inventory},panels={},
  request=function() U.QueueRefresh() end,
  refresh=function() U.Refresh() end,
  recover=function() blocked={};leader=false;city=false;hidden=false;ending=false end,repair=function()  end,
  close=function()  end,manageContext=false}
 uiRecovery:Refresh(true)
end
