-- Model the Civ V rules needed here: the first pipe-delimited form is the
-- default, and named positional tokens use a one-based argument index.
-- Do not mistake this small fixture for the native localization DLL.
Locale.ConvertTextKey=function(key,...)
 local text=SummaryText[key] or key;local args={...}
 text=text:match('^[^|]*')
 text=text:gsub('{(%d+)_[%w_]+}',function(index)
  assert(args[tonumber(index)]~=nil,'Missing localization argument for '..key)
  return tostring(args[tonumber(index)])
 end)
 assert(not text:find('{',1,true) and not text:find('}',1,true),'Unresolved token: '..text)
 return text
end
SummaryText.BROKEN='Population: {1_Num} | Owned plots: {2_Num}[NEWLINE]Local: {3_Num}'
assert(Locale.ConvertTextKey('BROKEN',8,25,6)=='Population: 8 ','old pipe separator must reproduce the reported missing fields')
SummaryText.BROKEN=nil
local B=MapModData.BoundlessCity;local s=B.State(0)
local function refresh()
 Events.SerialEventGameDataDirty.Fire();Pump()
 assert(not Controls.Panel.hidden,'summary refresh must keep the workforce panel functional')
end
local function fields(values)
 for name,key in pairs(SummaryFields) do
  local text=Controls[name].text
  assert(text~='' and not text:find('TXT_KEY_',1,true),name..' must be localized')
  assert(text:find(tostring(values[key]),1,true),name..' must contain its complete live value: '..text)
 end
 assert(Controls.SubjugationProgress.text:find('Original capitals subjugated:',1,true))
end
Controls.Open.callback();refresh();fields(B.Summary(s))
assert(Controls.OwnedPlots.text:find('Owned Plots:',1,true),'acceptance: owned plots must render')

local originalSummary,originalDomination=B.Summary,B.DominationProgress
for _,number in ipairs({0,2147483647}) do
 local values={automata=0};for _,key in pairs(SummaryFields) do values[key]=number end
 B.Summary=function() return values end
 B.DominationProgress=function() return number,number end
 refresh();fields(values)
 assert(Controls.SubjugationProgress.text:find(tostring(number)..' / '..tostring(number),1,true))
end
B.Summary=originalSummary;B.DominationProgress=originalDomination
-- A measured native stack may grow far beyond the viewport. The body must
-- follow that height; fixed action/list positions stay outside the scroll.
local localized=SummaryText.TXT_KEY_BC_SUMMARY_OWNED
SummaryText.TXT_KEY_BC_SUMMARY_OWNED=('A longer translated territory label '):rep(12)..'{1_Value}'
Controls.ManagementStack.height=2048;refresh()
assert(Controls.SummaryBody:GetSizeY()==2048,'summary body must follow the tallest wrapped column')
fields(B.Summary(s));assert(#Controls.OwnedPlots.text>300)
SummaryText.TXT_KEY_BC_SUMMARY_OWNED=localized;Controls.ManagementStack.height=1

-- Real mock-native accounting, ownership and existing gameplay events/actions,
-- rather than cached or hardcoded UI census data.
capital.pop=8;capital.forcedDefault=0;GovernorWorst(capital)
assert(B.Action(0,'MODE','MANUAL'));refresh()
assert(Controls.Population.text=='Population: 8');fields(B.Summary(s))
local plot=Remote(25,5,{5,4,3,2,1,1})
local owned=B.Ownership(s).count;refresh();assert(Controls.OwnedPlots.text=='Owned Plots: '..owned)
assert(B.Action(0,'PLOT',plot.n));refresh();assert(Controls.RemoteWorkers.text=='Remote Workers: 1')
assert(B.Action(0,'LOCK',plot.n));refresh();assert(Controls.LockedRequests.text=='Locked Requests: 1')
-- Exercise the real rendered row buttons as well as the global controls.
local function plotRow()
 for _,row in ipairs(UIRows) do if row.Text.text:find('(25,5)',1,true) then return row end end
 error('remote plot row disappeared')
end
plotRow().Lock.callback();refresh();assert(Controls.LockedRequests.text=='Locked Requests: 0')
plotRow().Assign.callback();refresh();assert(Controls.RemoteWorkers.text=='Remote Workers: 0')
Controls.Mode.callback();refresh();assert(Controls.Mode.text==B.Text(s.mode));fields(B.Summary(s))
Controls.Priority.callback();Controls.Direction.callback();Controls.Sort.callback();refresh();fields(B.Summary(s))

local cost=B.Cost(s);capital.buildings[200]=1;refresh()
assert(B.Cost(s)<cost and Controls.FrontierCost.text=='Next frontier claim: '..B.Cost(s)..' Culture')
capital.buildings[200]=nil;refresh();assert(Controls.FrontierCost.text=='Next frontier claim: '..cost..' Culture')
s.progress=18;refresh();assert(Controls.FrontierCulture.text=='Frontier Culture: 18')
plot.owner=1;GameEvents.TileOwnershipChanged.Fire(plot.x,plot.y,1,0);Pump();refresh();fields(B.Summary(s))
assert(Controls.OwnedPlots.text=='Owned Plots: '..(owned-1))
plot.owner=0;GameEvents.TileOwnershipChanged.Fire(plot.x,plot.y,0,1);Pump();refresh()
assert(Controls.OwnedPlots.text=='Owned Plots: '..owned)
s.progress=B.Cost(s);B.Busy[0]=true;B.Expand(s);B.Busy[0]=nil;Pump();refresh();fields(B.Summary(s))
assert(Controls.OwnedPlots.text=='Owned Plots: '..(owned+1),'frontier claim must update territory summary')
local claim=Players[0].notifications[#Players[0].notifications]
assert(claim.title=='Border expanded ('..claim.x..', '..claim.y..')' and claim.text:find('Click to go to the tile.',1,true))

-- Atlas uses live, already-credited remote yields and only moves the camera.
assert(B.Action(0,'MODE','MANUAL'));assert(B.Action(0,'PLOT',plot.n));refresh()
local snapshot=Players[0]:GetScriptData();local writes=mutations;local fullScans=scans
local atlasData=B.Atlas(s);local east=assert(atlasData.byName.EAST)
assert(east.workers==1 and east.yields[1]==5 and east.yields[2]==4)
Controls.Atlas.callback();refresh()
assert(not Controls.AtlasOverview.hidden and Controls.Scroll.hidden and Controls.Mode.hidden and Controls.AtlasTitle.text=='Living Atlas')
local eastRow
for _,row in ipairs(AtlasRows) do if row.AtlasRowText.text:find('East Causeway',1,true) then eastRow=row;break end end
assert(eastRow and not eastRow.AtlasRowInspect.hidden)
eastRow.AtlasRowInspect.callback();refresh()
assert(Controls.AtlasTitle.text=='East Causeway' and Controls.AtlasYields.tooltip:find('5 Food',1,true))
assert(not Controls.AtlasBack.hidden and AtlasRows[1].AtlasRowInspect.hidden and AtlasRows[1].AtlasRowText.text:find('Remote job',1,true))
AtlasRows[1].AtlasRowLocate.callback();assert(LocatedPlot==plot and Controls.Panel.hidden)
assert(Players[0]:GetScriptData()==snapshot and scans==fullScans and mutations==writes)
Controls.Open.callback();Controls.AtlasBack.callback();refresh();assert(Controls.AtlasTitle.text=='Living Atlas')
Controls.Atlas.callback();refresh();assert(Controls.AtlasScroll.hidden and not Controls.Scroll.hidden and not Controls.Mode.hidden)
B.Action(0,'PLOT',plot.n);refresh()

B.Save(s);local progress=math.floor(s.progress);B.States={};B.Caches={}
Events.LoadScreenClose.Fire();Pump();assert(Controls.Panel.hidden and not Controls.Launcher.hidden)
s=B.State(0);Controls.Open.callback();refresh();fields(B.Summary(s))
assert(Controls.FrontierCulture.text=='Frontier Culture: '..progress)
Events.SerialEventEnterCityScreen.Fire();Pump();assert(Controls.Panel.hidden)
Events.SerialEventExitCityScreen.Fire();Pump();Controls.Open.callback();refresh();fields(B.Summary(s))

capital.owner=1;Players[0].cities={};Players[1].cities[#Players[1].cities+1]=capital
LuaEvents.BoundlessChanged.Fire(0);refresh()
assert(not Controls.CapitalStatus.hidden and Controls.Mode.disabled)
assert(Controls.Population.text:find('Unavailable while the capital is occupied',1,true),'never show a stale capital census')
assert(Controls.OwnedPlots.text=='Owned Plots: '..B.Ownership(s).count)
assert(Controls.Siege.text==B.Text('WORKFORCE_VIEW'),'lost-capital military interface must remain available')
capital.owner=0;Players[0].cities={capital};Players[1].cities[#Players[1].cities]=nil
LuaEvents.BoundlessChanged.Fire(0);refresh();fields(B.Summary(s));assert(Controls.CapitalStatus.hidden and not Controls.Mode.disabled)
Controls.Siege.callback();refresh();fields(B.Summary(s))
local scansBefore=scans;local writesBefore=mutations
for i=1,50 do refresh() end
assert(scans==scansBefore and mutations==writesBefore,'summary-only refresh must not scan the map or mutate gameplay')
-- Visual marks follow actual assignments and pending requests, never stale rows.
assert(B.Action(0,'MODE','MANUAL'));assert(B.Action(0,'PLOT',plot.n));refresh()
assert(not plotRow().AssignedMark.hidden and plotRow().PendingMark.hidden)
assert(plotRow().Text.text:find('[ICON_FOOD]',1,true) and plotRow().Text.tooltip:find(B.Text('FOOD'),1,true))
assert(Controls.Yields.tooltip and not Controls.Yields.tooltip:find('[ICON_FOOD]',1,true),'full yield names remain available in tooltips')
capital.automatons=1;capital.unassigned=1;Events.SerialEventCityInfoDirty.Fire();Pump();refresh()
assert(plotRow().AssignedMark.hidden and not plotRow().PendingMark.hidden)
capital.automatons=0;capital.unassigned=0;B.Schedule(0,true);Pump();refresh()
assert(not plotRow().AssignedMark.hidden and plotRow().PendingMark.hidden)
Controls.Close.callback();Pump();for i=1,1000 do Pump() end
assert(deferred==nil,'summary fix must not add idle polling')
print('PASS summary: all fields, zero/large values, first-form/token rules, wrapped-height growth, real census/territory/Registry/actions, reload, capital loss/reclaim, transitions and no polling/map scans')
