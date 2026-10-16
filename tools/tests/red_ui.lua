local R=MapModData.RED_Legend;TEST.flush();local s=R.State(0)
local function controls()
 return setmetatable({},{__index=function(t,k)
  local c={hidden=false,disabled=false,text=''}
  function c:SetHide(v)self.hidden=v end
  function c:IsHidden()return self.hidden end
  function c:SetDisabled(v)self.disabled=v end
  function c:SetText(v)self.text=v end
  function c:SetSizeX(v)self.width=v end
  function c:CalculateSize()end
  function c:ReprocessAnchoring()end
  function c:CalculateInternalSize()end
  function c:RegisterCallback(_,fn)self.click=fn end
  rawset(t,k,c);return c
 end})
end
Controls=controls();Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27};InterfaceModeTypes={INTERFACEMODE_SELECTION=0}
UI={IsCityScreenUp=function()return TEST.cityScreen or false end,GetInterfaceMode=function()return 0 end,GetHeadSelectedUnit=function()return TEST.selected end,SelectUnit=function(u)TEST.selected=u end,LookAt=function()end}
function ContextPtr:LookUpControl()return nil end
function ContextPtr:SetInputHandler(fn)self.input=fn end
InstanceManager={new=function()return {ResetInstances=function(self)self.rows={}end,GetInstance=function(self)local c=controls();self.rows[#self.rows+1]=c;TEST.rows=self.rows;return c end}end}
function IconHookup()return true end
local nativeInclude=include
include=function(name)if name~='RED_Core' then nativeInclude(name) end end
TEST.LoadPanel()
R.Save(s);local before=Players[0].script
Controls.Open.click();assert(not Controls.Panel.hidden and #TEST.rows==6)
assert(Players[0].script==before,'panel opening is read-only')
for i=1,20 do LuaEvents.RED_TeamChanged(0) end;assert(Players[0].script==before,'refresh is read-only')
TEST.cityScreen=true;Events.SerialEventEnterCityScreen();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
TEST.cityScreen=false;Events.SerialEventExitCityScreen();assert(not Controls.Launcher.hidden)
Controls.Open.click();Events.AILeaderMessage();assert(Controls.Panel.hidden and Controls.Launcher.hidden)
Events.LeavingLeaderViewMode();assert(not Controls.Launcher.hidden)
Controls.Open.click();Events.SerialEventGameMessagePopupShown();assert(Controls.Panel.hidden)
Events.SerialEventGameMessagePopupProcessed();assert(not Controls.Launcher.hidden)
local u=TEST.new('UNIT_WARRIOR',4,4);TEST.flush();local r=R.Record(u);r.training=65;R.Apply(u,r);R.AutoAssign(s)
Controls.Open.click();assert(TEST.rows[1].Name.text:find('UNIT_WARRIOR',1,true))
TEST.rows[1].Release.click();assert(not r.slot and s.manual,'explicit release enables manual vacancies')
local snapshot=Players[0].script;LuaEvents.RED_TeamChanged(0);assert(Players[0].script==snapshot)
print('PASS Red panel: six rows, read-only open/refresh, explicit release, city/diplomacy/popup transitions')
