-- Presentation-only world-map gate. Never takes ownership of SetUpdate,
-- saves, turn processing or the native popup queue.
CWC2_Screen = {}
local screens = {
 'CivilopediaScreen','TechTree','TechPopup','GenericPopup','TextPopup','DeclareWarPopup',
 'SocialPolicyPopup','CultureOverview','NotificationLogPopup','WhosWinningPopup','NewEraPopup',
 'NaturalWonderPopup','GoodyHutPopup','BarbarianCampPopup','GoldenAgePopup','GreatPersonRewardPopup',
 'CityStateGreetingPopup','CityStateDiploPopup','DiploVotePopup','VoteResultsPopup','TechAwardPopup',
 'WonderPopup','AdvisorInfoPopup','AdvisorCounselPopup','AdvisorModal','EconomicOverview','DiploOverview',
 'MilitaryOverview','EndGameMenu','Demographics','VictoryProgress','ChooseFreeItem','ChoosePantheon',
 'ChooseReligion','EspionageOverview','ReligionOverview','ChooseMayaBonus','ChooseFaithGreatPerson',
 'SetUnitName','SetCityName','ProductionPopup','LeagueOverviewPopup','ChooseArchaeology','ChooseIdeology',
 'ChooseInternationalTradeRoute','ChooseTradeRouteNewHome','GreatWorkSplash','TradeRouteOverview',
 'LeagueProjectPopup','ChooseGoodyHutRewardPopup','ChooseAdmiralNewPort','LeagueSplash','GameMenu',
 'PlayerChange','ContentSwitch','LeaderHeadRoot','LeaderTrade','DiscussLeader'
}
local mapped = {
 BUTTONPOPUP_TECH_TREE='TechTree', BUTTONPOPUP_CHOOSETECH='TechPopup',
 BUTTONPOPUP_CHOOSE_TECH_TO_STEAL='TechPopup', BUTTONPOPUP_CHOOSEPOLICY='SocialPolicyPopup',
 BUTTONPOPUP_CULTURE_OVERVIEW='CultureOverview', BUTTONPOPUP_CHOOSEPRODUCTION='ProductionPopup'
}
local function hook(name, callback)
 if Events and Events[name] and Events[name].Add then Events[name].Add(callback) end
end
function CWC2_Screen.New(config)
 local self = {ending=false, leader=false, city=false, bulk=false, pending={}, completed={}, running=false}
 local ctx = config.context or ContextPtr
 MapModData=MapModData or {}
 MapModData.CWC2_ScreenHosts=MapModData.CWC2_ScreenHosts or {}
 local hosts=MapModData.CWC2_ScreenHosts
 local identity=config.name or tostring(ctx)
 hosts[identity]=self
 local function current()return hosts[identity]==self end
 local function subscribe(name,callback)
  hook(name,function(...)if current() then callback(...) end end)
 end
 local popupScreens = {}
 for key,name in pairs(mapped) do
  if ButtonPopupTypes and ButtonPopupTypes[key] then popupScreens[ButtonPopupTypes[key]]=name end
 end
 local function lookup(name)
  if not ctx or not ctx.LookUpControl then return nil end
  local control=ctx:LookUpControl('/InGame/'..name)
  if not control and name=='TechPopup' then control=ctx:LookUpControl('/InGame/WorldView/InfoCorner/TechPanel/TechPopup') end
  if not control and name=='LeaderHeadRoot' then control=ctx:LookUpControl('/LeaderHeadRoot') end
  return control
 end
 function self:Eligible()
  if not current() then return false end
  local id=Game.GetActivePlayer();local p=Players[id]
  return p and p:IsAlive() and (not p.IsHuman or p:IsHuman())
   and (not config.civ or p:GetCivilizationType()==GameInfoTypes[config.civ])
   and not (Game.IsNetworkMultiPlayer and Game.IsNetworkMultiPlayer())
 end
 function self:Reason(mapReturn)
  if not self:Eligible() then return 'inactive civilization' end
  local p=Players[Game.GetActivePlayer()]
  if self.ending or (p.IsTurnActive and not p:IsTurnActive()) then return 'inactive turn' end
  if ctx.IsHidden and ctx:IsHidden() then return 'hidden context' end
  local actual,first={},nil
  for _,name in ipairs(screens) do
   local c=lookup(name)
   if c then
    if c:IsHidden() then self.completed[name]=nil
    elseif not self.completed[name] then actual[name]=true;first=first or name end
   end
  end
  local bulk=lookup('BulkUI')
  if bulk and bulk.IsHidden then self.bulk=bulk:IsHidden() end
  if self.bulk then return 'world interface hidden' end
  if UI and UI.IsInStrategicView and UI.IsInStrategicView() then return 'strategic view' end
  local city=UI and UI.IsCityScreenUp and UI.IsCityScreenUp()
  if mapReturn and not city then self.city=false end
  if city or self.city then return 'city screen' end
  if UI and UI.GetInterfaceMode and InterfaceModeTypes
   and UI.GetInterfaceMode()~=InterfaceModeTypes.INTERFACEMODE_SELECTION then return 'targeting mode' end
  local leader=lookup('LeaderHeadRoot')
  if mapReturn and not first and not city and not (leader and not leader:IsHidden())
   and not (UI and UI.GetLeaderHeadRootUp and UI.GetLeaderHeadRootUp()) then
   self.leader=false;self.city=false;self.pending={}
  end
  if (leader and not leader:IsHidden()) or (not leader and self.leader)
   or (UI and UI.GetLeaderHeadRootUp and UI.GetLeaderHeadRootUp()) then return 'leader diplomacy' end
  for typ,record in pairs(self.pending) do
   local name=popupScreens[typ]
   if name and actual[name] then record.seen=true end
   if name and lookup(name) and not actual[name] and (record.seen or self.completed[name] or mapReturn) then self.pending[typ]=nil
   elseif record.screens then
    local active=false
    for screen in pairs(record.screens) do if actual[screen] then active=true;break end end
    if not active then self.pending[typ]=nil end
   elseif first then record.screens=actual end
  end
  if first then return 'popup '..first end
  -- A real map-return event repairs missing Processed notifications. Requests
  -- are never stored: native listeners can reject or synchronously process one.
  if mapReturn then self.pending={};self.leader=false;self.city=false end
  if next(self.pending) then return 'unprocessed popup' end
 end
 function self:Available(mapReturn) return self:Reason(mapReturn)==nil end
 function self:Sync(mapReturn)
  local available=self:Available(mapReturn)
  if available and config.recover then config.recover() end
  return available
 end
 function self:Enforce()
  if not current() then return end
  if not self:Available() then
   for _,control in ipairs(config.roots or {}) do control:SetHide(true) end
  end
 end
 function self:Refresh(mapReturn)
  if not current() or self.running then return end
  self.running=true
  self:Sync(mapReturn)
  local ok,err=pcall(config.refresh)
  if not ok then
   if config.repair then config.repair() end
   for _,control in ipairs(config.panels or {}) do control:SetHide(true) end
   if self.error~=tostring(err) then print('[Civilization UI] '..(config.name or '')..': '..tostring(err)) end
   self.error=tostring(err)
  else self.error=nil end
  self:Enforce();self.running=false
 end
 local function suspend()
  if config.close then config.close() end
  self:Refresh()
 end
 local function resume() self:Refresh(true) end
 subscribe('ActivePlayerTurnEnd',function()self.ending=true;suspend()end)
 local function reset()
  self.ending=false;self.leader=false;self.city=false;self.pending={};self.completed={};self.bulk=false
  if config.close then config.close() end
  resume()
 end
 subscribe('ActivePlayerTurnStart',reset);subscribe('GameplaySetActivePlayer',reset);subscribe('LoadScreenClose',reset)
 subscribe('SerialEventEnterCityScreen',function()self.city=true;suspend()end)
 subscribe('SerialEventExitCityScreen',function()self.city=false;resume()end)
 subscribe('AILeaderMessage',function()self.leader=true;suspend()end)
 subscribe('LeavingLeaderViewMode',function()self.leader=false;resume()end)
 subscribe('SerialEventGameMessagePopupShown',function(info)
  local typ=info and info.Type or 'unknown';local name=popupScreens[typ]
  if name then self.completed[name]=nil end
  local previous=self.pending[typ]
  self.pending[typ]={count=(previous and previous.count or 0)+1};suspend()
 end)
 subscribe('SerialEventGameMessagePopupProcessed',function(typ)
  typ=typ or 'unknown'
  local record=self.pending[typ]
  if record and (record.count or 1)>1 then record.count=record.count-1
  else self.pending[typ]=nil end
  -- Culture Overview sends Processed before DequeuePopup. Ignore only that
  -- completed screen, retaining every other visible/native blocker.
  if popupScreens[typ] and not self.pending[typ] then self.completed[popupScreens[typ]]=true end
  self:Refresh()
 end)
 subscribe('InterfaceModeChanged',resume)
 subscribe('UnitSelectionChanged',resume)
 subscribe('SerialEventGameDataDirty',function()
  -- Reuse the host's existing coalescer rather than rebuilding a large roster
  -- once for every native dirty notification in the same frame.
  if not self:Eligible() then self:Enforce();return end
  if config.request then config.request()
  else self:Refresh() end
 end)
 subscribe('SystemUpdateUI',function(kind)
  if SystemUpdateUIType and kind==SystemUpdateUIType.BulkHideUI then self.bulk=true;suspend()
  elseif SystemUpdateUIType and kind==SystemUpdateUIType.BulkShowUI then self.bulk=false;resume() end
 end)
 if config.manageContext and ctx.SetShowHideHandler then
  ctx:SetShowHideHandler(function(hidden,initial)
   if hidden then suspend() elseif not initial then resume() end
  end)
 end
 return self
end
