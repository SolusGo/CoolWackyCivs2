local instances=0
UIInstances={CatRow={},HomeCard={},BondCard={}}
local function control()
 local t={hidden=false,disabled=false,text='',callbacks={}}
 function t:SetHide(value) self.hidden=value end;function t:SetDisabled(value) self.disabled=value end
 function t:SetText(value) self.text=value end;function t:SetToolTipString(value) self.tooltip=value end
 function t:RegisterCallback(_,fn) self.click=fn end
 function t:CalculateSize() end;function t:ReprocessAnchoring() end;function t:CalculateInternalSize() end
 function t:GetSizeY() return self.height or 20*math.max(1,math.ceil(#self.text/40)) end
 function t:SetSizeY(value) self.height=value end;function t:SetOffsetY(value) self.y=value end
 function t:IsHidden() return self.hidden end
 return t
end
Controls=setmetatable({}, {__index=function(t,k) local c=control();rawset(t,k,c);return c end})
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27};InterfaceModeTypes={INTERFACEMODE_SELECTION=1}
UI={IsCityScreenUp=function() return false end,GetInterfaceMode=function() return 1 end,SelectUnit=function(u) UI.selected=u end,LookAt=function() end}
function IconHookup(index,size,atlas,control) control.icon={index,size,atlas} end
InstanceManager={new=function(_,kind,root)
 local pool={}
 return {GetInstance=function()
  if #pool>0 then local t=table.remove(pool);t[root]:SetHide(false);return t end
  instances=instances+1;local t=setmetatable({}, {__index=function(self,key) local c=control();rawset(self,key,c);return c end})
  UIInstances[kind][#UIInstances[kind]+1]=t;return t
 end,ReleaseInstance=function(_,t) t[root]:SetHide(true);pool[#pool+1]=t end}
end}
function ContextPtr:LookUpControl() return nil end
function ContextPtr:SetInputHandler(fn) self.input=fn end;function ContextPtr:SetShowHideHandler(fn) self.show=fn end
LoadUI()
local H=MapModData.THE11CATS
assert(#UIInstances.CatRow==11 and #UIInstances.BondCard==4 and not Controls.Launcher.hidden)
Controls.Open.click();assert(not Controls.Panel.hidden and Controls.Title.text:find(':2',1,true))
local a=City(0,1,10,10);H.Reconcile(0,true)
Events.UnitSelectionChanged(0,H.State(0).cats.LUNA.unit);H.Render()
Controls.Locate.click();assert(UI.selected)
UI.selected:MoveTo(a);H.Render();assert(not Controls.Action.disabled)
Controls.Action.click();assert(H.State(0).cats.LUNA.status==2)
Controls.Homes.click();local home=UIInstances.HomeCard[1]
assert(home.Capacity.text:find('CAPACITY:1',1,true) and home.Name1.text:find('LUNA',1,true))
assert(home.Portrait1.icon[1]==H.Cats.LUNA.portrait and home.Effect1.text:find('LUNA_EFFECT_LINES',1,true))
assert(home.HomeBonds.text:find('BOND_NAME_FIRST_PAIR',1,true) and home.Tree.text:find('TREE_NOT_BUILT',1,true))
a:SetNumRealBuilding(H.TREE,1);GameEvents.CityConstructed(0,a.id,H.TREE)
assert(home.Tree.text:find('TREE_OCCUPIED',1,true) and a:GetNumRealBuilding(H.buildings.TREE_FOOD)==1)
Controls.Action.click();assert(H.State(0).cats.LUNA.status==1 and Controls.Action.disabled)
assert(home.Cat1.hidden and home.Tree.text:find('TREE_BUILT',1,true) and a:GetNumRealBuilding(H.buildings.TREE_FOOD)==0)
assert(Controls.DetailState.text:find('COOLDOWN',1,true))
Controls.Homes.click();assert(not Controls.HomesScroll.hidden and UIInstances.HomeCard[1].HomeName.text=='Home 1')
local allocated=instances;for i=1,100 do H.Render() end;assert(instances==allocated)
Controls.Bonds.click();assert(not Controls.BondsScroll.hidden and UIInstances.BondCard[3].BondStatus.text:find('BOND_MISSING',1,true))
assert(UIInstances.BondCard[3].Requirements.text:find('OSCAR',1,true))
assert(Controls.DetailEffect.text:find('EFFECT_HEADING',1,true) and Controls.DetailBio.text:find('BIO_HEADING',1,true))
local flags=Players[0].script:match('|THE11CATS1:([^|]*)|')
Controls.Messages.click();assert(not H.Notices(H.State(0)).enabled and Players[0].script:match('|THE11CATS1:([^|]*)|')==flags)
LoadUI();assert(instances==allocated and MapModData.THE11CATS==H,'same-context reinclude must be inert')
Events.AILeaderMessage();assert(Controls.Launcher.hidden and Controls.Panel.hidden)
assert(not H.Command(0,'LUNA','SETTLE'))
Events.LeavingLeaderViewMode();Flush();assert(not Controls.Launcher.hidden)
UI.IsCityScreenUp=function() return true end;Events.SerialEventEnterCityScreen();assert(Controls.Launcher.hidden)
UI.IsCityScreenUp=function() return false end;Events.SerialEventExitCityScreen();Flush();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown({Type=7});assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed(7);Flush();assert(not Controls.Launcher.hidden)
Controls.Open.click();Controls.Story.click();assert(not Controls.Narrative.hidden)
Controls.StoryClose.click();assert(Controls.Narrative.hidden)
assert(ContextPtr.input(KeyEvents.KeyDown,Keys.VK_ESCAPE) and Controls.Panel.hidden)
-- Normal native roots may close before, after, or without a processed event.
local roots={};ContextPtr.LookUpControl=function(_,path) return roots[path] end
for _,name in ipairs({'CultureOverview','TechTree','SocialPolicyPopup','ReligionOverview','EspionageOverview','LeagueOverviewPopup'}) do
 local root=control();roots['/InGame/'..name]=root
 Events.SerialEventGameMessagePopupShown({Type=91});Flush();assert(Controls.Launcher.hidden)
 Events.SerialEventGameMessagePopupProcessed(91);Flush();assert(Controls.Launcher.hidden,'early processed event cannot show over a visible root')
 root.hidden=true;Events.SerialEventGameDataDirty();Flush();assert(not Controls.Launcher.hidden)
 root.hidden=false;Events.SerialEventGameMessagePopupShown({Type=92});Flush()
 root.hidden=true;Events.SerialEventGameDataDirty();Flush();assert(not Controls.Launcher.hidden,'missed processed event is repaired from native root visibility')
end
Controls.Open.click();Controls.Homes.click();local peak=instances
local b=City(0,2,30,30);H.Reconcile(0,false);assert(instances==peak+1)
Transfer(b,1);assert(UIInstances.HomeCard[2].Home.hidden)
local c=City(0,3,50,50);H.Reconcile(0,false)
assert(instances==peak+1 and UIInstances.HomeCard[2].HomeName.text=='Home 3','lost home cards must be reused')
peak=instances
for i=1,200 do Controls.Open.click();Controls.Open.click();H.Render() end
assert(instances==peak and #UIInstances.CatRow==11)
local coreBefore=Players[0].script
for i=1,1000 do Events.SerialEventUnitInfoDirty() end
Flush();assert(not ContextPtr.callback and Players[0].script==coreBefore and instances==peak)
local detailSet=Controls.DetailBio.SetText;Controls.DetailBio.SetText=function() error('injected renderer failure') end
H.Render();assert(Controls.Panel.hidden and not H.busy and not H.syncing)
Controls.DetailBio.SetText=detailSet;Controls.Open.click();assert(not Controls.Panel.hidden)
assert(GameEvents.PlayerDoTurn.Count()==1)
print('PASS household UI: 11 reusable portraits, validated actions, cooldowns, homes, selected cat and modal visibility')
