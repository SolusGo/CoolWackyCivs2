-- Direct commands must obey the same interface gate as the visible Prayer button.
local k=MapModData.CKPrayer;local p=Players[0];local s=k.states[0]
local function rejected(reason)
 local raw=p.script;local stage,ready,grace=s.stage,s.ready,s.grace
 local faith,food,production,gap=p.faith,p.cap.food,p.cap.production,p.gap
 assert(not k.CanPray(0),reason)
 assert(not k.Pray(0,stage,ready),reason..' (direct command)')
 LuaEvents.CKPrayer_Pray(0,stage,ready)
 assert(p.script==raw and s.stage==stage and s.ready==ready and s.grace==grace,'invalid request changed progression')
 assert(p.faith==faith and p.cap.food==food and p.cap.production==production and p.gap==gap,'invalid request granted rewards')
end
TEST.cityScreen=true;rejected('controller accepted City View');TEST.cityScreen=false
TEST.mode=2;rejected('controller accepted incompatible interface mode');TEST.mode=1
TEST.screens['/InGame/CultureOverview']={IsHidden=function()return false end}
rejected('controller accepted a modal without a Shown event');TEST.screens['/InGame/CultureOverview']=nil
TEST.screens['/LeaderHeadRoot']={IsHidden=function()return false end}
rejected('controller accepted leader view');TEST.screens['/LeaderHeadRoot']=nil
local nativeUI=UI;UI=nil;rejected('controller accepted missing UI APIs');UI=nativeUI
local modeAPI=UI.GetInterfaceMode;UI.GetInterfaceMode=nil;rejected('controller accepted unavailable mode API');UI.GetInterfaceMode=modeAPI
assert(k.CanPray(0))
TEST.LoadPanel()
Events.AILeaderMessage();rejected('controller accepted a pending leader transition')
-- A visible-root API can lag the message; the message guard must remain authoritative.
TEST.screens['/LeaderHeadRoot']={IsHidden=function()return true end};TEST.pump()
rejected('controller ignored a leader message while the root is still hidden')
Events.LeavingLeaderViewMode();TEST.screens['/LeaderHeadRoot']=nil;TEST.pump();assert(k.CanPray(0))
Events.SerialEventGameMessagePopupShown({Type=77});rejected('controller accepted a pending popup')
TEST.screens['/InGame/ReligionOverview']={IsHidden=function()return false end};TEST.pump()
rejected('controller accepted a visible popup')
Events.SerialEventGameMessagePopupProcessed(77);TEST.pump();rejected('controller accepted an early Processed event')
TEST.screens['/InGame/ReligionOverview']=nil;Events.SerialEventGameDataDirty();TEST.pump();assert(k.CanPray(0))
TEST.showhide(true);TEST.pump();rejected('controller accepted a hidden addin')
TEST.showhide(false);TEST.pump();assert(k.CanPray(0))
k.busy[0]=true;rejected('controller accepted a reentrant prayer');k.busy[0]=nil
k.syncing[0]=true;rejected('controller accepted a reentrant blessing reconciliation');k.syncing[0]=nil
local raw=p.script
assert(not k.Pray(0,s.stage+1,s.ready) and not k.Pray(0,s.stage,s.ready+1))
assert(not k.Pray(0,nil,nil) and not k.Pray(0,tostring(s.stage),s.ready) and p.script==raw,'stale/malformed requests')
local getCapital=p.GetCapitalCity;local cap=p.cap
p.cap=nil;assert(not k.CanPray(0));p.cap=cap
p.GetCapitalCity=function()return Players[2].cap end;assert(not k.CanPray(0),'foreign capital pointer');p.GetCapitalCity=getCapital
p.turnActive=false;rejected('inactive turn accepted');p.turnActive=true
TEST.active=2;rejected('inactive player accepted');TEST.active=0
local stage,ready=s.stage,s.ready;assert(k.Pray(0,stage,ready))
for i=1,25 do assert(not k.Pray(0,stage,ready) and not k.Pray(0,s.stage,s.ready)) end
TEST.advance();assert(k.CanPray(0) and not k.Pray(0,stage,ready),'cooldown expiry must not validate old request')
print('PASS Kingdom authoritative activation: native/transition/modal gates, stale/reentrant requests, no side effects and cooldown')
