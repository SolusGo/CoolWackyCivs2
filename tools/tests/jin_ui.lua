local J=MapModData.JIN
LoadJinUI();assert(not Controls.Open.hidden and Controls.Panel.hidden)
Controls.Open.callback();assert(not Controls.Panel.hidden and #uiManager.rows>0)
Controls.LandmarksTab.callback();assert(#uiManager.rows==6 and uiManager.rows[1].Action.disabled)
Players[0].era=1;J.UIRefresh();assert(not uiManager.rows[1].Action.disabled)
uiManager.rows[1].Action.callback();assert(J.State(0).choices[1]=='FLOWER_PAGODA');assert(uiManager.rows[1].Action.disabled)
cap:SetNumRealBuilding(J.Building('FLOWER_PAGODA'),1);GameEvents.CityConstructed.Fire(0,1,J.Building('FLOWER_PAGODA'))
Controls.OverviewTab.callback();local selected
for _,r in ipairs(uiManager.rows)do if r.Text.text:find('candidate',1,true)then selected=r;break end end
assert(selected and not selected.Action.disabled);selected.Action.callback();assert(J.State(0).grass[1])
for _,tab in ipairs({'Recruit','Emissaries','Upgrades','Defense','Overview','Landmarks'})do Controls[tab..'Tab'].callback();assert(#uiManager.rows>0)end
Controls.Close.callback();assert(Controls.Panel.hidden)
active=1;Events.GameplaySetActivePlayer.Fire();assert(Controls.Open.hidden)
print('PASS Jin panel: visible entry, six tabs, era/choice disables, site action, refresh and non-Jin isolation')
