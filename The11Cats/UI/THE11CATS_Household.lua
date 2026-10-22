include('IconSupport')
include('InstanceManager')
include('THE11CATS_Manager')
local H=MapModData.THE11CATS
local opened,homes,narrative,selected=false,false,false,'AUSTIN'
local manager=InstanceManager:new('CatRow','Button',Controls.Roster)
local rows={}
-- Exactly eleven reusable instances, allocated once per context lifetime.
for _,id in ipairs(H.Order) do
 local instance=manager:GetInstance();rows[id]=instance
 IconHookup(H.Cats[id].portrait,64,'THE11CATS_CATS_ATLAS',instance.Portrait)
 instance.Name:SetText(H.Text(id..'_NAME')..' — '..H.Text(id..'_GENDER'))
 instance.Button:RegisterCallback(Mouse.eLClick,function() selected=id;H.Render() end)
end
H.interface={leader=false,hidden=false,blocked={},transition=false}
-- Native context names; queried only on event-triggered rendering and clicks.
local screens={'CivilopediaScreen','TechTree','GenericPopup','TextPopup','SocialPolicyPopup','DiploOverview','EconomicOverview','MilitaryOverview','CultureOverview','EspionageOverview','ReligionOverview','LeagueOverviewPopup','VictoryProgress','GameMenu','NotificationLogPopup','ChooseFreeItem','ChooseReligion','ChoosePantheon','NewEraPopup','ProductionPopup','DeclareWarPopup','CityStateDiploPopup','EndGameMenu','PlayerChange'}
function H.InterfaceReady()
 local f=H.interface
 if f.hidden or f.leader or f.transition then return false end
 if not UI or not UI.IsCityScreenUp or not UI.GetInterfaceMode or UI.IsCityScreenUp() then return false end
 if UI.GetInterfaceMode()~=InterfaceModeTypes.INTERFACEMODE_SELECTION then return false end
 local leader=ContextPtr:LookUpControl('/LeaderHeadRoot');if leader and not leader:IsHidden() then return false end
 local visible={}
 for _,name in ipairs(screens) do local control=ContextPtr:LookUpControl('/InGame/'..name);if control and not control:IsHidden() then visible[name]=true end end
 for kind,record in pairs(f.blocked) do
  if record.capture and next(visible) then record.capture=nil;record.screens=visible end
  if record.screens then
   local showing=false;for name in pairs(record.screens) do if visible[name] then showing=true end end
   if not showing then f.blocked[kind]=nil end
  end
 end
 return not next(visible) and not next(f.blocked)
end
local function eligible()
 local pid=Game.GetActivePlayer();local p=Players[pid]
 return H.Human(pid) and p:IsAlive() and p:IsTurnActive() and H.InterfaceReady()
end
local statusKeys={[0]='NOT_JOINED',[1]='TRAVELLING',[2]='RESIDENT',[3]='RECOVERING'}
function H.Status(s,id)
 if id=='AUSTIN' then return H.Text('KING') end
 local c=s.cats[id];local text=H.Text(statusKeys[c.status]);local city=c.status==2 and H.City(c)
 if city then text=text..' — '..city:GetName() end
 if c.status==3 then text=text..'[NEWLINE]'..H.Text('RETURN',math.max(0,c.recovery-H.Turn())) end
 if c.cooldown>H.Turn() then text=text..'[NEWLINE]'..H.Text('COOLDOWN',c.cooldown-H.Turn()) end
 return text
end
local bondOrder={'FIRST_PAIR','BONNIE_FAMILY','SISTERS_BED','MOTHER_DAUGHTER'}
local function bondText(s,city)
 local bonds=city and H.Bonds(s,city) or {};local names={}
 for _,id in ipairs(bondOrder) do if bonds[id] then names[#names+1]=H.Text('BOND_'..id) end end
 return #names>0 and table.concat(names,'[NEWLINE]') or H.Text('NO_BONDS')
end
function H.Render()
 local show=eligible();if not show then opened=false;narrative=false end
 Controls.Launcher:SetHide(not show);Controls.Panel:SetHide(not (show and opened));Controls.Narrative:SetHide(not (show and narrative))
 if not show or not opened then return end
 local pid=Game.GetActivePlayer();local s=H.State(pid);if not s then Controls.Feedback:SetText(H.Text('INVALID'));return end
 local count=1;for _,c in pairs(s.cats) do if c.status>0 then count=count+1 end end
 Controls.Title:SetText(count==11 and H.Text('COMPLETE') or H.Text('COUNT',count))
 Controls.RosterScroll:SetHide(homes);Controls.HomesScroll:SetHide(not homes)
 for _,id in ipairs(H.Order) do rows[id].State:SetText(H.Status(s,id)) end
 if homes then
  local lines={}
  for city in Players[pid]:Cities() do
   local residents=H.Residents(s,city);lines[#lines+1]='[COLOR_POSITIVE_TEXT]'..city:GetName()..'[ENDCOLOR] — '..H.Text('CAPACITY',#residents)
   for _,id in ipairs(residents) do lines[#lines+1]=H.Text(id..'_NAME') end
   lines[#lines+1]=bondText(s,city);lines[#lines+1]=''
  end
  Controls.HomesText:SetText(table.concat(lines,'[NEWLINE]'))
  Controls.HomesStack:CalculateSize();Controls.HomesStack:ReprocessAnchoring();Controls.HomesScroll:CalculateInternalSize()
 end
 local id=selected;local c=s.cats[id]
 IconHookup(H.Cats[id].portrait,128,'THE11CATS_CATS_ATLAS',Controls.DetailPortrait)
 Controls.DetailName:SetText(H.Text(id..'_NAME')..' — '..H.Text(id..'_GENDER'))
 Controls.DetailTrait:SetText(H.Text(id..'_TRAIT'))
 Controls.DetailState:SetText(H.Status(s,id));Controls.DetailEffect:SetText(H.Text(id..'_EFFECT'))
 Controls.DetailBio:SetText(H.Text(id..'_BIO'));Controls.DetailFamily:SetText(H.Text(id..'_FAMILY'))
 Controls.DetailBonds:SetText(bondText(s,c and c.status==2 and H.City(c)))
 Controls.Action:SetHide(not c or c.status==0 or c.status==3)
 Controls.Locate:SetHide(not c or c.status~=1)
 if c then
  local can,reason=H.CanSettle(pid,id)
  Controls.Action:SetText(H.Text(c.status==2 and 'REHOME' or 'SETTLE'))
  Controls.Action:SetDisabled(c.status==2 and c.cooldown>H.Turn() or c.status~=2 and not can)
  Controls.Action:SetToolTipString(H.Text(c.status==2 and 'REHOME_PEDIA' or reason))
  Controls.Feedback:SetText(c.status==1 and H.Text(reason) or c.status==3 and H.Text('WAIT_HOME') or '')
 else Controls.Feedback:SetText(H.Text('KING_HELP')) end
 Controls.Story:SetDisabled(s.latest==0)
 Controls.Roster:CalculateSize();Controls.Roster:ReprocessAnchoring();Controls.RosterScroll:CalculateInternalSize()
 Controls.DetailsStack:CalculateSize();Controls.DetailsStack:ReprocessAnchoring();Controls.DetailsScroll:CalculateInternalSize()
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;if opened then H.Reconcile(Game.GetActivePlayer(),true) end;H.Render() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;narrative=false;H.Render() end)
Controls.Cats:RegisterCallback(Mouse.eLClick,function() homes=false;H.Render() end)
Controls.Homes:RegisterCallback(Mouse.eLClick,function() homes=true;H.Render() end)
Controls.Action:RegisterCallback(Mouse.eLClick,function()
 local pid=Game.GetActivePlayer();local s=H.State(pid);local c=s and s.cats[selected]
 if not c then return end
 local ok,reason=H.Command(pid,selected,c.status==2 and 'REHOME' or 'SETTLE');H.Render()
 if not ok then Controls.Feedback:SetText(H.Text(reason or 'INVALID')) end
end)
Controls.Locate:RegisterCallback(Mouse.eLClick,function()
 if not eligible() then return end
 local s=H.State(Game.GetActivePlayer());local u=s and H.Unit(s,selected)
 if u then UI.SelectUnit(u);UI.LookAt(u:GetPlot(),0) end
end)
Controls.Story:RegisterCallback(Mouse.eLClick,function()
 local s=H.State(Game.GetActivePlayer());if not s or s.latest<1 then return end
 Controls.StoryTitle:SetText(H.Text('CHAPTER_'..s.latest));Controls.StoryText:SetText(H.Text('STORY_'..s.latest))
 narrative=true;H.Render()
end)
Controls.StoryClose:RegisterCallback(Mouse.eLClick,function() narrative=false;H.Render() end)
local function close() opened=false;narrative=false;H.Render() end
local function closeTransition()
 opened=false;narrative=false;H.interface.transition=true;H.Render();H.Schedule()
end
-- Coalesce only transitions; gameplay dispatcher owns the sole one-shot update.
H.Hook(LuaEvents,'THE11CATS_Changed',function(pid) if pid==Game.GetActivePlayer() then H.Render() end end)
H.Hook(Events,'SerialEventUnitInfoDirty',function() if opened then H.Render() end end)
H.Hook(Events,'UnitSelectionChanged',function(pid,unitID)
 if pid~=Game.GetActivePlayer() then return end
 local u=Players[pid]:GetUnitByID(unitID);local id=H.Identity(u)
 if id then selected=id end;if opened then H.Render() end
end)
H.Hook(Events,'SerialEventEnterCityScreen',closeTransition)
H.Hook(Events,'SerialEventExitCityScreen',function() H.interface.blocked={};closeTransition() end)
H.Hook(Events,'AILeaderMessage',function() H.interface.leader=true;closeTransition() end)
H.Hook(Events,'LeavingLeaderViewMode',function() H.interface.leader=false;closeTransition() end)
H.Hook(Events,'SerialEventGameMessagePopupShown',function(info) if info and info.Type then H.interface.blocked[info.Type]={capture=true} end;closeTransition() end)
H.Hook(Events,'SerialEventGameMessagePopupProcessed',function(kind) H.interface.blocked[kind]=nil;closeTransition() end)
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','LoadScreenClose'}) do
 H.Hook(Events,name,function() H.interface.blocked={};H.interface.leader=false;closeTransition() end)
end
H.Hook(Events,'ActivePlayerTurnEnd',closeTransition)
H.Hook(Events,'InterfaceModeChanged',closeTransition)
ContextPtr:SetShowHideHandler(function(hidden) H.interface.hidden=hidden;closeTransition() end)
ContextPtr:SetInputHandler(function(msg,key) if (opened or narrative) and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then narrative=false;opened=false;H.Render();return true end;return false end)
H.Render()
