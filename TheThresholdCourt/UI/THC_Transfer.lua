local uiRecovery -- UI state is transient; never part of a gameplay save.
include('InstanceManager')
include('SupportFunctions')
include('THC_Core')
local T=MapModData.ThresholdCourt
if T.uiContext==ContextPtr then T.Refresh();return end
T.uiContext=ContextPtr
local rows=InstanceManager:new('THC_Destination','Row',Controls.Destinations)
local snapshot,chosen,opened=nil,nil,false
local ending,city,leader,hidden=false,false,false,false
local popups={}
local function ScreenAvailable()
 local pid=Game.GetActivePlayer();local p=Players[pid]
 return T.active and T.Civ(pid) and p:IsTurnActive() and not ending and not city and not leader and not hidden
  and not next(popups) and not UI.IsCityScreenUp()
  and (not UI.IsGameCoreBusy or not UI.IsGameCoreBusy())
  and (not UI.GetInterfaceMode or UI.GetInterfaceMode()==InterfaceModeTypes.INTERFACEMODE_SELECTION)
end
local function Close()
 opened=false;snapshot=nil;chosen=nil;Controls.Panel:SetHide(true)
end
local function Selection()
 local u=UI.GetHeadSelectedUnit()
 if not T.Alive(u) or u:GetOwner()~=Game.GetActivePlayer() then return end
 return u
end
local function DisplayPanel(u)
 local pid=Game.GetActivePlayer();local o=T.Origin(pid,u)
 if not o or not snapshot or snapshot.unit~=T.UnitToken(u) or snapshot.origin~=T.CityToken(o) then Close();return end
 local base,reason=T.Validate(pid,u:GetID(),snapshot)
 Controls.Header:SetText(T.Text('HEADER',u:GetName(),o:GetName(),T.Cost(pid)))
 rows:ResetInstances()
 local selectedValid=false
 for c in Players[pid]:Cities() do
  if c:GetX()~=o:GetX() or c:GetY()~=o:GetY() then
   local item=rows:GetInstance();local x,y=c:GetX(),c:GetY()
   local token=T.CityToken(c)
   local available,why=T.Destination(pid,u,o,c)
   local selected=chosen and chosen.x==x and chosen.y==y and chosen.token==token
   local name=(selected and '[ICON_BULLET] ' or '')..c:GetName()
   TruncateString(item.Name,564,name);item.Name:SetToolTipString(name)
   item.Status:SetText(why..'  '..T.Cost(pid)..' [ICON_GOLD]')
   item.Row:SetToolTipString(base and why or reason)
   item.Row:SetDisabled(not base or not available)
   item.Row:RegisterCallback(Mouse.eLClick,function()
    if ScreenAvailable() and opened and snapshot and snapshot.unit==T.UnitToken(Selection()) then
     chosen={x=x,y=y,token=token};T.Refresh()
    end
   end)
   if selected and base and available then selectedValid=true end
  end
 end
 Controls.Destinations:CalculateSize();Controls.Destinations:ReprocessAnchoring();Controls.Scroll:CalculateInternalSize()
 if not selectedValid then chosen=nil end
 Controls.Confirm:SetDisabled(not selectedValid)
 local label=T.Text('CONFIRM')
 if chosen then
  local plot=Map.GetPlot(chosen.x,chosen.y);local dest=plot and plot:GetPlotCity()
  if dest then label=T.Text('CONFIRM_TO',dest:GetName()) end
 end
 Controls.Confirm:SetText(label);Controls.Confirm:SetToolTipString(label)
 Controls.Feedback:SetText(base and T.Text('CHOOSE') or reason)
 Controls.Panel:SetHide(false)
end
function T.Refresh()
 if uiRecovery then uiRecovery:Sync() end
 local show=ScreenAvailable();local u=show and Selection()
 local origin=u and T.Origin(Game.GetActivePlayer(),u)
 -- Keep an exhausted/ineligible military selection visible with a reason,
 -- but do not show a portal button for civilians, ranged units or other civs.
 local visible=origin and u:IsCombatUnit() and u:GetDomainType()==DomainTypes.DOMAIN_LAND and not u:IsRanged() and not u:IsEmbarked()
 visible=visible and (not uiRecovery or uiRecovery:Available())
 Controls.Launcher:SetHide(not visible)
 if not visible then Close();return end
 local valid,reason=T.Validate(Game.GetActivePlayer(),u:GetID())
 Controls.Open:SetDisabled(not valid);Controls.Open:SetToolTipString(reason);Controls.Reason:SetText(reason)
 if opened then DisplayPanel(u) end
end
local queued=false
function T.QueueRefresh()
 if not T.active or queued then return end
 queued=true
 ContextPtr:SetUpdate(function()
  ContextPtr:ClearUpdate();queued=false
  if T.active then T.Refresh() end
 end)
end
Controls.Open:RegisterCallback(Mouse.eLClick,function()
 if not ScreenAvailable() then return end
 local u=Selection();if not u then return end
 local valid,reason,ctx=T.Validate(Game.GetActivePlayer(),u:GetID())
 if not valid then T.Refresh();return end
 snapshot={unit=T.UnitToken(u),origin=T.CityToken(ctx.origin)};chosen=nil;opened=true;T.Refresh()
end)
Controls.Cancel:RegisterCallback(Mouse.eLClick,function() Close();T.Refresh() end)
Controls.Confirm:RegisterCallback(Mouse.eLClick,function()
 if not ScreenAvailable() or not opened or not snapshot or not chosen then Close();return end
 local u=Selection();if not u then Close();T.Refresh();return end
 local request={unit=snapshot.unit,origin=snapshot.origin,destination=chosen.token}
 local ok,reason=T.Transfer(Game.GetActivePlayer(),u:GetID(),request,chosen.x,chosen.y)
 if ok then
  Close()
  -- Keep the original selected instance; never select a replacement by type.
  if T.Alive(u) then UI.SelectUnit(u) end
 else
  T.Refresh();Controls.Feedback:SetText(reason)
 end
 T.QueueRefresh()
end)
ContextPtr:SetInputHandler(function(key,wparam)
 if uiRecovery and not uiRecovery:Available() then return false end
 if opened and key==KeyEvents.KeyDown and wparam==Keys.VK_ESCAPE then Close();return true end
 return false
end)
for _,name in ipairs({'UnitSelectionChanged','SerialEventUnitInfoDirty','SerialEventGameDataDirty','SerialEventCityInfoDirty','SerialEventCityDestroyed','SerialEventUnitDestroyed','InterfaceModeChanged'}) do T.Hook(Events,name,T.QueueRefresh) end
T.Hook(Events,'SerialEventEnterCityScreen',function() city=true;T.Refresh() end)
T.Hook(Events,'SerialEventExitCityScreen',function() city=false;T.QueueRefresh() end)
T.Hook(Events,'AILeaderMessage',function() leader=true;T.Refresh() end)
T.Hook(Events,'LeavingLeaderViewMode',function() leader=false;T.QueueRefresh() end)
T.Hook(Events,'SerialEventGameMessagePopupShown',function(info)
 if info and info.Type then popups[info.Type]=(popups[info.Type] or 0)+1 end
 T.Refresh()
end)
T.Hook(Events,'SerialEventGameMessagePopupProcessed',function(kind)
 local left=(popups[kind] or 0)-1;popups[kind]=left>0 and left or nil;T.QueueRefresh()
end)
T.Hook(Events,'ActivePlayerTurnEnd',function() ending=true;Close();T.Refresh() end)
local function ResetScreen()
 ending=false;city=false;leader=false;popups={};Close();T.QueueRefresh()
end
T.Hook(Events,'ActivePlayerTurnStart',ResetScreen)
T.Hook(Events,'GameplaySetActivePlayer',ResetScreen)
T.Hook(Events,'LoadScreenClose',ResetScreen)
ContextPtr:SetShowHideHandler(function(h) hidden=h;if h then Close() end;T.QueueRefresh() end)
T.Refresh()

-- Shared screen recovery: actual native visibility wins over stale event flags.
local helperLoaded=pcall(include,'CWC2_Screen')
if CWC2_Screen then
 uiRecovery=CWC2_Screen.New{name='TheThresholdCourt',civ='CIVILIZATION_THRESHOLD_COURT',context=ContextPtr,
  roots={Controls.Launcher,Controls.Panel},panels={Controls.Panel},
  request=function() T.QueueRefresh() end,
  refresh=function() T.Refresh() end,
  recover=function() ending=false;city=false;leader=false;hidden=false;popups={} end,repair=function()  end,
  close=function() opened=false;snapshot=nil;chosen=nil end,manageContext=false}
 uiRecovery:Refresh(true)
end
