TEST.LoadPanel();local k=MapModData.CKPrayer
assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
Controls.Open.click();assert(not Controls.Panel.hidden and not Controls.Pray.disabled)
assert(Controls.Progress.text:find('Grace: 0/7',1,true) and Controls.Current.text:find('ADDRESS',1,true))
assert(Controls.Effect.text:find('5 turns',1,true),'localized duration placeholders')
Controls.Pray.click();assert(Controls.Pray.disabled and k.states[0].stage==2 and Controls.Cooldown.text:find('5',1,true))
Controls.Pray.click();assert(k.states[0].stage==2,'UI double click')
assert(Controls.Blessings.text:find('ADDRESS: 5',1,true))
Events.AILeaderMessage();assert(Controls.Launcher.hidden and Controls.Panel.hidden)
Events.LeavingLeaderViewMode();TEST.pump();assert(not Controls.Launcher.hidden and Controls.Panel.hidden)
Controls.Open.click();TEST.cityScreen=true;Events.SerialEventEnterCityScreen();assert(Controls.Launcher.hidden)
TEST.cityScreen=false;Events.SerialEventExitCityScreen();TEST.pump();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown({Type=1});Events.SerialEventGameMessagePopupShown({Type=2});TEST.pump();assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed(1);TEST.pump();assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed(2);TEST.pump();assert(not Controls.Launcher.hidden)
for _,name in ipairs({'CultureOverview','TechTree','GameMenu','ReligionOverview','CivilopediaScreen'}) do
 TEST.screens['/InGame/'..name]={IsHidden=function()return false end};Events.SerialEventGameDataDirty();TEST.pump();assert(Controls.Launcher.hidden)
 TEST.screens['/InGame/'..name]=nil;Events.SerialEventGameDataDirty();TEST.pump();assert(not Controls.Launcher.hidden)
end
TEST.mode=2;Events.InterfaceModeChanged();assert(Controls.Launcher.hidden)
TEST.mode=1;Events.InterfaceModeChanged();TEST.pump();Controls.Open.click();assert(TEST.input(KeyEvents.KeyDown,Keys.VK_ESCAPE) and Controls.Panel.hidden)
TEST.active=2;Events.GameplaySetActivePlayer();assert(Controls.Launcher.hidden)
TEST.active=0;Events.GameplaySetActivePlayer();TEST.pump();assert(not Controls.Launcher.hidden)
Events.LoadScreenClose();TEST.pump();Controls.Open.click();assert(Controls.Current.text:find('OPENING GLORY',1,true))
-- Native Shown may precede visibility; Processed can precede actual closure.
Events.SerialEventGameMessagePopupShown({Type=10});TEST.screens['/InGame/DeclareWarPopup']={IsHidden=function()return false end};TEST.pump();assert(Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupProcessed(10);TEST.pump();assert(Controls.Launcher.hidden)
TEST.screens['/InGame/DeclareWarPopup']=nil;Events.SerialEventGameDataDirty();TEST.pump();assert(not Controls.Launcher.hidden)
Events.SerialEventGameMessagePopupShown({Type=11});TEST.screens['/InGame/CultureOverview']={IsHidden=function()return false end};TEST.pump()
TEST.screens['/InGame/CultureOverview']=nil;Events.SerialEventGameDataDirty();TEST.pump();assert(not Controls.Launcher.hidden,'missed Processed recovers from real visibility')
TEST.showhide(true);TEST.pump();assert(Controls.Launcher.hidden);TEST.showhide(false);TEST.pump();assert(not Controls.Launcher.hidden)
local setter=Controls.Current.SetText
Controls.Current.SetText=function()error('injected display fault')end
Controls.Open.click();assert(Controls.Panel.hidden,'display faults close only this panel')
Controls.Current.SetText=setter;Controls.Open.click();assert(not Controls.Panel.hidden,'display recovers after a fault')
local updates=TEST.updates or 0
for i=1,1000 do Events.SerialEventGameDataDirty() end
assert(TEST.updates==updates+1,'coalesce dirty events');TEST.pump();assert(not TEST.update)
local saved=Players[0].script
for i=1,1000 do TEST.pump() end
assert(not TEST.update and TEST.updates==updates+1 and saved==Players[0].script,'no idle polling or state changes')
print('PASS Kingdom UI controls, localization, modal/early/missed events, active/load/context recovery, coalescing and zero idle polling')
