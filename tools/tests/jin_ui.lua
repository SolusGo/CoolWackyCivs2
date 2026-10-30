local J=MapModData.JIN
LoadJinUI();assert(not Controls.Open.hidden and Controls.Panel.hidden)
Controls.Open.callback();assert(not Controls.Panel.hidden and #uiManager.rows>0)
assert(Controls.Open.hidden,'launcher overlaps the open council')
Controls.LandmarksTab.callback();assert(#uiManager.rows==6 and uiManager.rows[1].Action.disabled)
assert(not Controls.LandmarksActive.hidden and Controls.OverviewActive.hidden)
for _,r in ipairs(uiManager.rows)do assert(r.Art.icon.atlas=='JIN_BUILDING_ATLAS')end
Players[0].era=1;J.UIRefresh();assert(not uiManager.rows[1].Action.disabled)
uiManager.rows[1].Action.callback();assert(J.State(0).choices[1]=='FLOWER_PAGODA');assert(uiManager.rows[1].Action.disabled)
cap:SetNumRealBuilding(J.Building('FLOWER_PAGODA'),1);GameEvents.CityConstructed.Fire(0,1,J.Building('FLOWER_PAGODA'))
Controls.OverviewTab.callback();local selected
for _,r in ipairs(uiManager.rows)do if r.Text.text:find('candidate',1,true)then selected=r;break end end
assert(selected and not selected.Action.disabled);selected.Action.callback();assert(J.State(0).grass[1])
for _,tab in ipairs({'Recruit','Emissaries','Upgrades','Defense','Overview','Landmarks'})do Controls[tab..'Tab'].callback();assert(#uiManager.rows>0)end
Controls.UpgradesTab.callback();local icons={}
for _,r in ipairs(uiManager.rows)do assert(r.Art.icon.atlas=='JIN_UPGRADE_ATLAS');icons[r.Art.icon.index]=true end
local iconCount=0;for _ in pairs(icons)do iconCount=iconCount+1 end;assert(iconCount==13)
assert(Controls.HorseValue.text and Controls.KarmaValue.text and Controls.LandmarkValue.text)
Controls.Close.callback();assert(Controls.Panel.hidden)
-- Game.GetActivePlayer can remain Jin throughout AI turns. A hidden launcher
-- must recover even though closed-panel gameplay refreshes are suppressed.
Controls.Open.callback();assert(not Controls.Panel.hidden)
Players[0].turnActive=false;Events.ActivePlayerTurnEnd.Fire()
for i=1,20 do Events.SerialEventGameDataDirty.Fire()end;Pump()
assert(Controls.Open.hidden and Controls.Panel.hidden and not J.panelOpen)
Players[0].turnActive=true;Events.ActivePlayerTurnStart.Fire();Pump()
assert(not Controls.Open.hidden and Controls.Panel.hidden,'Jin launcher did not return next turn')
-- Early notifications arrive before the native turn-active flag settles.
for i=1,20 do
 Controls.Open.callback();assert(not Controls.Panel.hidden)
 Events.ActivePlayerTurnEnd.Fire();assert(Controls.Open.hidden and Controls.Panel.hidden)
 Players[0].turnActive=false;Events.ActivePlayerTurnStart.Fire();Pump();assert(Controls.Open.hidden)
 Players[0].turnActive=true;Events.SerialEventGameDataDirty.Fire();Pump()
 assert(not Controls.Open.hidden and Controls.Panel.hidden,'early turn notification stranded launcher')
 assert(deferred==nil,'visibility left an idle frame callback')
end
-- Loading in a transition and changing active players rechecks visibility.
Players[0].turnActive=false;Events.LoadScreenClose.Fire();Pump();assert(Controls.Open.hidden)
Players[0].turnActive=true;Events.LoadScreenClose.Fire();Pump();assert(not Controls.Open.hidden)
active=1;Events.GameplaySetActivePlayer.Fire();assert(Controls.Open.hidden)
active=0;Events.GameplaySetActivePlayer.Fire();Pump();assert(not Controls.Open.hidden)
print('PASS Jin panel: six tabs/actions, 20 turn cycles, early native flags, closed-launcher recovery, load/player switches and no idle polling')
