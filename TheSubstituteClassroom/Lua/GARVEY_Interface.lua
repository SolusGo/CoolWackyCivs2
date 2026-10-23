-- Shared command/panel gate in the sole InGameUIAddin context. Transient flags
-- never enter saved progression; no cities, units, timers or polling are used.
local K=MapModData.Garvey
K.interface={leader=false,transition=false,hidden=false,blocked={}}
-- BNW InGame.xml context names, matching the collection's modal visibility fix.
local screens={
 'CivilopediaScreen','TechTree','GenericPopup','TextPopup','DeclareWarPopup','SocialPolicyPopup',
 'NotificationLogPopup','WhosWinningPopup','NewEraPopup','NaturalWonderPopup','GoodyHutPopup',
 'BarbarianCampPopup','GoldenAgePopup','GreatPersonRewardPopup','CityStateGreetingPopup','CityStateDiploPopup',
 'DiploVotePopup','VoteResultsPopup','TechAwardPopup','WonderPopup','AdvisorInfoPopup','AdvisorCounselPopup',
 'AdvisorModal','EconomicOverview','DiploOverview','MilitaryOverview','EndGameMenu','Demographics',
 'VictoryProgress','ChooseFreeItem','ChoosePantheon','ChooseReligion','EspionageOverview','ReligionOverview',
 'ChooseMayaBonus','ChooseFaithGreatPerson','SetUnitName','SetCityName','ProductionPopup','LeagueOverviewPopup',
 'ChooseArchaeology','ChooseIdeology','ChooseInternationalTradeRoute','CultureOverview','ChooseTradeRouteNewHome',
 'GreatWorkSplash','TradeRouteOverview','LeagueProjectPopup','ChooseGoodyHutRewardPopup','ChooseAdmiralNewPort',
 'LeagueSplash','GameMenu','PlayerChange','ContentSwitch'
}
function K.InterfaceReady()
 local state=K.interface
 -- Fail closed if this context lacks the verified native UI/control APIs.
 if not UI or not UI.IsCityScreenUp or not UI.GetInterfaceMode or not ContextPtr
  or not ContextPtr.LookUpControl or not InterfaceModeTypes then return false end
 if state.transition or state.hidden or state.leader or state.strategic or (UI.IsInStrategicView and UI.IsInStrategicView()) or UI.IsCityScreenUp() then return false end
 if UI.GetInterfaceMode()~=InterfaceModeTypes.INTERFACEMODE_SELECTION then return false end
 local leaderRoot=ContextPtr:LookUpControl('/LeaderHeadRoot')
 if (leaderRoot and not leaderRoot:IsHidden()) or (UI.GetLeaderHeadRootUp and UI.GetLeaderHeadRootUp()) then return false end
 local visible={}
 for _,name in ipairs(screens) do
  local control=ContextPtr:LookUpControl('/InGame/'..name)
  if control and not control:IsHidden() then visible[name]=true end
 end
 for kind,record in pairs(state.blocked) do
  if record.capture and next(visible) then record.capture=nil;record.screens=visible end
  if record.screens then
   local showing=false;for name in pairs(record.screens) do if visible[name] then showing=true end end
   if not showing then state.blocked[kind]=nil end
  end
 end
 return not next(visible) and not next(state.blocked)
end
