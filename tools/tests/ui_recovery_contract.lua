-- Executed against each collection's shipped presentation helper under Lua 5.1.
local listeners={}
Events=setmetatable({}, {__index=function(t,key)
 local event={Add=function(fn)listeners[key]=listeners[key] or {};table.insert(listeners[key],fn)end}
 rawset(t,key,event);return event
end})
local function fire(name,...)
 for _,fn in ipairs(listeners[name] or {}) do fn(...) end
end
local active,turn,alive,human=0,true,true,true
Game={GetActivePlayer=function()return active end,IsNetworkMultiPlayer=function()return false end}
GameInfoTypes={TEST_CIV=1}
Players={[0]={IsAlive=function()return alive end,IsHuman=function()return human end,
 IsTurnActive=function()return turn end,GetCivilizationType=function()return 1 end},
 [1]={IsAlive=function()return true end,IsHuman=function()return true end,
 IsTurnActive=function()return true end,GetCivilizationType=function()return 2 end}}
local city,mode,strategic=false,1,false
UI={IsCityScreenUp=function()return city end,GetInterfaceMode=function()return mode end,
 IsInStrategicView=function()return strategic end}
InterfaceModeTypes={INTERFACEMODE_SELECTION=1}
ButtonPopupTypes={BUTTONPOPUP_CHOOSEPOLICY=10,BUTTONPOPUP_CULTURE_OVERVIEW=11,BUTTONPOPUP_TECH_TREE=12}
SystemUpdateUIType={BulkHideUI=1,BulkShowUI=2}
local function control(hidden)
 return {hidden=hidden,IsHidden=function(s)return s.hidden end,SetHide=function(s,v)s.hidden=v end}
end
local contexts={['/InGame/TechTree']=control(true),['/InGame/CultureOverview']=control(true),
 ['/InGame/SocialPolicyPopup']=control(true),['/LeaderHeadRoot']=control(true)}
local updates=0
ContextPtr={hidden=false,IsHidden=function(s)return s.hidden end,
 LookUpControl=function(s,path)return contexts[path]end,
 SetUpdate=function()updates=updates+1 end,ClearUpdate=function()updates=updates+1 end,
 SetShowHideHandler=function(s,fn)s.showHide=fn end}
local launcher,panel=control(true),control(true)
local opened,legacy,latched,inject=false,false,false,false
local refreshes,repairs=0,0
local gate=UI_SCREEN.New{context=ContextPtr,civ='TEST_CIV',name='contract',
 roots={launcher,panel},panels={panel},manageContext=true,
 recover=function()legacy=false end,repair=function()latched=false;repairs=repairs+1 end,
 close=function()opened=false end,
 refresh=function()
  if latched then return end
  latched=true;refreshes=refreshes+1
  if inject then inject=false;error('injected row failure') end
  launcher:SetHide(legacy);panel:SetHide(not opened);latched=false
 end}
gate:Refresh(true);assert(not launcher.hidden and panel.hidden)
for i=1,100 do
 opened=true;turn=false;fire('ActivePlayerTurnEnd');assert(launcher.hidden and panel.hidden)
 fire('ActivePlayerTurnStart');assert(launcher.hidden,'early turn callback showed inactive human')
 turn=true;fire('SerialEventGameDataDirty');assert(not launcher.hidden and panel.hidden,'launcher stranded after AI turn')
end
city=true;fire('SerialEventEnterCityScreen');assert(launcher.hidden)
city=false;fire('UnitSelectionChanged');assert(not launcher.hidden,'missed city exit stranded launcher')
contexts['/LeaderHeadRoot'].hidden=false;fire('AILeaderMessage');assert(launcher.hidden)
contexts['/LeaderHeadRoot'].hidden=true;fire('SerialEventGameDataDirty');assert(not launcher.hidden,'native leader close not reconciled')
fire('AILeaderMessage');contexts['/LeaderHeadRoot']=nil;fire('UnitSelectionChanged');assert(not launcher.hidden,'unloaded leader root retained event latch')
-- Early Shown, nested types, and completion before native DequeuePopup.
fire('SerialEventGameMessagePopupShown',{Type=11});assert(launcher.hidden)
contexts['/InGame/CultureOverview'].hidden=false;fire('SerialEventGameDataDirty');assert(launcher.hidden)
contexts['/InGame/TechTree'].hidden=false;fire('SerialEventGameMessagePopupShown',{Type=12})
fire('SerialEventGameMessagePopupProcessed',11);assert(launcher.hidden,'completion cleared unrelated fullscreen blocker')
contexts['/InGame/CultureOverview'].hidden=true
fire('SerialEventGameMessagePopupProcessed',12);assert(not launcher.hidden,'completion-before-dequeue stranded launcher')
contexts['/InGame/TechTree'].hidden=true
-- A missed Processed can be recovered from the actual screen disappearing.
contexts['/InGame/SocialPolicyPopup'].hidden=false;fire('SerialEventGameMessagePopupShown',{Type=10})
contexts['/InGame/SocialPolicyPopup'].hidden=true;fire('SerialEventGameDataDirty');assert(not launcher.hidden)
fire('SerialEventGameMessagePopupShown',{Type=77});fire('SerialEventGameMessagePopupShown',{Type=77})
fire('SerialEventGameMessagePopupProcessed',77);assert(launcher.hidden,'nested popup count lost')
fire('SerialEventGameMessagePopupProcessed',77);assert(not launcher.hidden)
fire('SerialEventGameMessagePopupShown',{Type=88});fire('UnitSelectionChanged');assert(not launcher.hidden,'unknown stale popup failed map-return recovery')
-- Requested popups may be rejected or processed synchronously: no sticky flag.
fire('SerialEventGameMessagePopup',{Type=10});fire('SerialEventGameDataDirty');assert(not launcher.hidden)
mode=2;fire('InterfaceModeChanged');assert(launcher.hidden)
mode=1;fire('InterfaceModeChanged');assert(not launcher.hidden)
strategic=true;fire('SerialEventGameDataDirty');assert(launcher.hidden)
strategic=false;fire('SerialEventGameDataDirty');assert(not launcher.hidden)
fire('SystemUpdateUI',1);assert(launcher.hidden)
fire('SystemUpdateUI',2);assert(not launcher.hidden)
ContextPtr.hidden=true;ContextPtr.showHide(true,false);assert(launcher.hidden)
ContextPtr.hidden=false;ContextPtr.showHide(false,false);assert(not launcher.hidden)
legacy=true;fire('LoadScreenClose');assert(not launcher.hidden)
active=1;fire('GameplaySetActivePlayer');assert(launcher.hidden)
active=0;fire('GameplaySetActivePlayer');assert(not launcher.hidden)
inject=true;opened=true;gate:Refresh();assert(repairs==1 and panel.hidden)
gate:Refresh();assert(not launcher.hidden and not latched,'render error permanently latched renderer')
for i=1,1000 do fire('SerialEventGameDataDirty') end
local oldRefreshes=refreshes
local fresh=0
UI_SCREEN.New{name='contract',context=ContextPtr,civ='TEST_CIV',roots={},panels={},
 refresh=function()fresh=fresh+1 end}
fire('SerialEventGameDataDirty');gate:Refresh()
assert(fresh==1 and refreshes==oldRefreshes,'retired context touched its successor')
assert(updates==0,'presentation stole the gameplay context update dispatcher')
print('PASS UI recovery: 100 turn cycles, early flags, missing close events, nested popups, parent/bulk hiding, selection modes, reload, retired contexts, render faults and zero scheduler ownership')
