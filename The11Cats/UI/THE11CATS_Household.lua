include('IconSupport')
include('InstanceManager')
include('THE11CATS_Manager')
local H=MapModData.THE11CATS
if H.uiContext==ContextPtr then return end
H.uiContext=ContextPtr
local opened,view,narrative,selected=false,'CATS',false,'AUSTIN'
local manager=InstanceManager:new('CatRow','Button',Controls.Roster)
local homesManager=InstanceManager:new('HomeCard','Home',Controls.HomesStack)
local bondsManager=InstanceManager:new('BondCard','Bond',Controls.BondsStack)
local rows,homeCards,bondCards={},{},{}
for _,id in ipairs(H.BondOrder) do bondCards[id]=bondsManager:GetInstance() end
-- Exactly eleven reusable instances, allocated once per context lifetime.
for _,id in ipairs(H.Order) do
 local instance=manager:GetInstance();rows[id]=instance
 IconHookup(H.Cats[id].portrait,64,'THE11CATS_CATS_ATLAS',instance.Portrait)
 instance.Name:SetText(H.Text(id..'_NAME')..' — '..H.Text(id..'_GENDER'))
 instance.Button:RegisterCallback(Mouse.eLClick,function() selected=id;H.Render() end)
end
H.interface={leader=false,hidden=false,blocked={},transition=false}
-- Native context names; queried only on event-triggered rendering and clicks.
local screens={'CivilopediaScreen','TechTree','GenericPopup','TextPopup','SocialPolicyPopup','DiploOverview','EconomicOverview','MilitaryOverview','CultureOverview','EspionageOverview','ReligionOverview','LeagueOverviewPopup','LeagueSplash','LeagueProjectPopup','DiploVotePopup','VoteResultsPopup','VictoryProgress','GameMenu','NotificationLogPopup','ChooseFreeItem','ChooseReligion','ChoosePantheon','NewEraPopup','ProductionPopup','DeclareWarPopup','CityStateDiploPopup','EndGameMenu','PlayerChange','TechAwardPopup','ChooseIdeology','GreatWorkSplash','ChooseFaithGreatPerson','SetUnitName','SetCityName','AdvisorModal','ChooseInternationalTradeRoute'}
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
 if c.status==1 then
  local unit=H.Unit(s,id);local plot=unit and unit:GetPlot();local location=plot and plot:GetPlotCity()
  if location then text=H.Text('LOCATION',location:GetName())
  elseif plot then text=H.Text('LOCATION_COORDS',plot:GetX(),plot:GetY()) end
 end
 local color=({[0]='COLOR_GREY',[1]='COLOR_CYAN',[2]='COLOR_POSITIVE_TEXT',[3]='COLOR_WARNING_TEXT'})[c.status]
 text='['..color..']'..text..'[ENDCOLOR]'
 if c.status==3 then text=text..'[NEWLINE]'..H.Text('RETURN',math.max(0,c.recovery-H.Turn())) end
 if c.cooldown>H.Turn() then text=text..'[NEWLINE]'..H.Text('COOLDOWN',c.cooldown-H.Turn()) end
 return text
end
local bondOrder={'FIRST_PAIR','BONNIE_FAMILY','SISTERS_BED','MOTHER_DAUGHTER'}
local function bondText(s,city,namesOnly)
 local bonds=city and H.Bonds(s,city) or {};local names={}
 for _,id in ipairs(bondOrder) do if bonds[id] then names[#names+1]=H.Text((namesOnly and 'BOND_NAME_' or 'BOND_')..id) end end
 return #names>0 and table.concat(names,'[NEWLINE]') or H.Text('NO_BONDS')
end
local function renderHomes(s)
 local live={}
 for city in Players[s.pid]:Cities() do
  local key=s.pid..':'..H.CityKey(city);live[key]=true
  local card=homeCards[key];if not card then card=homesManager:GetInstance();homeCards[key]=card end
  card.HomeName:SetText(city:GetName());local residents=H.Residents(s,city)
  card.Capacity:SetText(H.Text('CAPACITY',#residents)..(#residents==0 and ' — '..H.Text('NO_RESIDENTS') or ''))
  local capacityY=card.HomeName:GetSizeY()+18;card.Capacity:SetOffsetY(capacityY)
  local nextY=capacityY+card.Capacity:GetSizeY()+12
  for slot=1,3 do local id=residents[slot];card['Cat'..slot]:SetHide(not id)
   if id then
    IconHookup(H.Cats[id].portrait,48,'THE11CATS_CATS_ATLAS',card['Portrait'..slot])
    card['Name'..slot]:SetText(H.Text(id..'_NAME')..' — '..H.Text(id..'_TRAIT'))
    card['Effect'..slot]:SetText((H.Text(id..'_EFFECT_LINES'):gsub('%[NEWLINE%]','  ')))
    local effectY=card['Name'..slot]:GetSizeY()+8;card['Effect'..slot]:SetOffsetY(effectY)
    local height=math.max(64,effectY+card['Effect'..slot]:GetSizeY()+8)
    card['Cat'..slot]:SetOffsetY(nextY);card['Cat'..slot]:SetSizeY(height);nextY=nextY+height+6
    card['Cat'..slot]:RegisterCallback(Mouse.eLClick,function() selected=id;H.Render() end)
   end
  end
  card.HomeBonds:SetText(H.Text('BONDS_HEADING')..'[NEWLINE]'..bondText(s,city,true));card.HomeBonds:SetOffsetY(nextY+8)
  local treeY=nextY+card.HomeBonds:GetSizeY()+20;card.Tree:SetOffsetY(treeY)
  card.Tree:SetText(H.Text(city:GetNumBuilding(H.TREE)>0 and (#residents>0 and 'TREE_OCCUPIED' or 'TREE_BUILT') or 'TREE_NOT_BUILT'))
  card.Tree:SetToolTipString(H.Text('TREE_HELP'));card.Home:SetSizeY(treeY+card.Tree:GetSizeY()+16)
 end
 -- Release lost cities into the native instance pool; stable refreshes allocate nothing.
 for key,card in pairs(homeCards) do if not live[key] then homesManager:ReleaseInstance(card);homeCards[key]=nil end end
 Controls.HomesStack:CalculateSize();Controls.HomesStack:ReprocessAnchoring();Controls.HomesScroll:CalculateInternalSize()
end
local function render()
 local show=eligible();if not show then opened=false;narrative=false end
 Controls.Launcher:SetHide(not show);Controls.Panel:SetHide(not (show and opened));Controls.Narrative:SetHide(not (show and narrative))
 if not show or not opened then return end
 local pid=Game.GetActivePlayer();local s=H.State(pid)
 if not s then
  Controls.Feedback:SetText(H.Text('INVALID'));Controls.Action:SetDisabled(true);Controls.Locate:SetHide(true)
  Controls.Story:SetDisabled(true);Controls.Messages:SetDisabled(true)
  Controls.RosterScroll:SetHide(true);Controls.HomesScroll:SetHide(true);Controls.BondsScroll:SetHide(true)
  return
 end
 local count=1;for _,c in pairs(s.cats) do if c.status>0 then count=count+1 end end
 Controls.Title:SetText(count==11 and H.Text('COMPLETE') or H.Text('COUNT',count))
 Controls.RosterScroll:SetHide(view~='CATS');Controls.HomesScroll:SetHide(view~='HOMES');Controls.BondsScroll:SetHide(view~='BONDS')
 for _,id in ipairs(H.Order) do
  local row=rows[id];row.State:SetText(H.Status(s,id))
  local stateY=row.Name:GetSizeY()+16;row.State:SetOffsetY(stateY)
  row.Button:SetSizeY(math.max(80,stateY+row.State:GetSizeY()+12))
 end
 if view=='HOMES' then renderHomes(s) end
 if view=='BONDS' then
  for _,bond in ipairs(H.BondOrder) do local report=H.BondReport(s,bond);local card=bondCards[bond]
   card.BondName:SetText(report.name);card.Requirements:SetText(report.requirements)
   card.Bonus:SetText(report.effect);card.BondStatus:SetText(report.status)
   card.Target:SetText(H.Text('CURRENT_HOME',report.target and report.target:GetName() or H.Text('WAIT_HOME')))
   local requirementsY=card.BondName:GetSizeY()+24;card.Requirements:SetOffsetY(requirementsY)
   local bonusY=requirementsY+card.Requirements:GetSizeY()+14;card.Bonus:SetOffsetY(bonusY)
   local statusY=bonusY+card.Bonus:GetSizeY()+12;card.BondStatus:SetOffsetY(statusY)
   local targetY=statusY+card.BondStatus:GetSizeY()+12;card.Target:SetOffsetY(targetY)
   card.Bond:SetSizeY(targetY+card.Target:GetSizeY()+14)
  end
  Controls.BondsStack:CalculateSize();Controls.BondsStack:ReprocessAnchoring();Controls.BondsScroll:CalculateInternalSize()
 end
 local id=selected;local c=s.cats[id]
 IconHookup(H.Cats[id].portrait,128,'THE11CATS_CATS_ATLAS',Controls.DetailPortrait)
 Controls.DetailName:SetText(H.Text(id..'_NAME')..' — '..H.Text(id..'_GENDER'))
 Controls.DetailTrait:SetText(H.Text('PERSONALITY',H.Text(id..'_TRAIT')))
 Controls.DetailState:SetText(H.Text('CURRENT_HOME',H.Status(s,id)))
 Controls.DetailEffect:SetText(H.Text('EFFECT_HEADING')..'[NEWLINE]'..H.Text(id=='AUSTIN' and 'KING_HELP' or id..'_EFFECT_LINES'))
 Controls.DetailBio:SetText(H.Text('BIO_HEADING')..'[NEWLINE]'..H.Text(id..'_BIO'))
 Controls.DetailFamily:SetText(H.Text('FAMILY_HEADING')..'[NEWLINE]'..H.Text(id..'_FAMILY'))
 Controls.DetailBonds:SetText(H.Text('BONDS_HEADING')..'[NEWLINE]'..bondText(s,c and c.status==2 and H.City(c)))
 Controls.Action:SetHide(not c)
 Controls.Locate:SetHide(not c or c.status~=1)
 if c then
  local can,reason
  if c.status==2 then can,reason=H.CanRehome(pid,id) else can,reason=H.CanSettle(pid,id) end
  Controls.Action:SetText(H.Text(c.status==2 and 'REHOME' or 'SETTLE'))
  Controls.Action:SetDisabled(not can)
  Controls.Action:SetToolTipString(H.Text(can and c.status==2 and 'REHOME_PEDIA' or reason))
  Controls.Feedback:SetText(H.Text(reason))
 else Controls.Feedback:SetText(H.Text('KING_HELP')) end
 Controls.Story:SetDisabled(s.latest==0)
 Controls.Story:SetText(H.Text(s.latest==6 and 'STORY_COMPLETE' or 'STORY'))
 local notices=H.Notices(s)
 Controls.Messages:SetDisabled(not notices.valid)
 Controls.Messages:SetText(H.Text(notices.valid and notices.enabled and 'MESSAGES_ON' or 'MESSAGES_OFF'))
 Controls.Messages:SetToolTipString(H.Text('MESSAGES_HELP'))
 -- Read native screen size only during event-driven rendering; reserve room
 -- for footer feedback/actions in short windowed views.
 local height=650
 if UIManager and UIManager.GetScreenSizeVal then local _,screenY=UIManager:GetScreenSizeVal();height=math.min(650,math.max(430,screenY-36)) end
 local footer=math.max(70,Controls.Feedback:GetSizeY()+42)
 Controls.Panel:SetSizeY(height);Controls.Background:SetSizeY(height-16)
 for _,scroll in ipairs({Controls.RosterScroll,Controls.HomesScroll,Controls.BondsScroll}) do scroll:SetSizeY(math.max(100,height-100-footer)) end
 Controls.DetailsScroll:SetSizeY(math.max(70,height-240-footer-16))
 Controls.Roster:CalculateSize();Controls.Roster:ReprocessAnchoring();Controls.RosterScroll:CalculateInternalSize()
 Controls.DetailsStack:CalculateSize();Controls.DetailsStack:ReprocessAnchoring();Controls.DetailsScroll:CalculateInternalSize()
end
local rendering=false
function H.Render()
 if rendering then return end;rendering=true
 local ok,err=pcall(render);rendering=false
 if not ok then
  opened=false;narrative=false;Controls.Panel:SetHide(true);Controls.Narrative:SetHide(true)
  H.Log('Household display closed safely: '..tostring(err),true)
 end
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;if opened then H.Reconcile(Game.GetActivePlayer(),true) end;H.Render() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;narrative=false;H.Render() end)
Controls.Cats:RegisterCallback(Mouse.eLClick,function() view='CATS';H.Render() end)
Controls.Homes:RegisterCallback(Mouse.eLClick,function() view='HOMES';H.Render() end)
Controls.Bonds:RegisterCallback(Mouse.eLClick,function() view='BONDS';H.Render() end)
Controls.Messages:RegisterCallback(Mouse.eLClick,function()
 local s=eligible() and H.State(Game.GetActivePlayer());if s then H.ToggleFeedback(s) end
end)
Controls.Action:RegisterCallback(Mouse.eLClick,function()
 local pid=Game.GetActivePlayer();local s=H.State(pid);local c=s and s.cats[selected]
 if not c then return end
 local ok,reason=H.Command(pid,selected,c.status==2 and 'REHOME' or 'SETTLE');H.Render()
 if not ok then Controls.Feedback:SetText(H.Text(reason or 'INVALID')) end
end)
Controls.Locate:RegisterCallback(Mouse.eLClick,function()
 if not eligible() then return end
 local s=H.State(Game.GetActivePlayer());local u=s and H.Unit(s,selected)
 if u then UI.SelectUnit(u);UI.LookAt(u:GetPlot(),0) else Controls.Feedback:SetText(H.Text('MISSING_UNIT')) end
end)
Controls.Story:RegisterCallback(Mouse.eLClick,function()
 local s=H.State(Game.GetActivePlayer());if not s or s.latest<1 then return end
 Controls.StoryTitle:SetText(H.Text('CHAPTER_'..s.latest));Controls.StoryText:SetText(H.Text('STORY_'..s.latest))
 narrative=true;H.Render()
end)
Controls.StoryClose:RegisterCallback(Mouse.eLClick,function() narrative=false;H.Render() end)
local function close() opened=false;narrative=false;H.Render() end
local function closeTransition()
 opened=false;narrative=false;H.interface.transition=true;H.Render();H.Refresh()
end
-- Coalesce only transitions; gameplay dispatcher owns the sole one-shot update.
H.Hook(LuaEvents,'THE11CATS_Changed',function(pid) if pid==Game.GetActivePlayer() then H.Render() end end)
H.Hook(Events,'SerialEventUnitInfoDirty',function() if opened then H.Refresh() end end)
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
