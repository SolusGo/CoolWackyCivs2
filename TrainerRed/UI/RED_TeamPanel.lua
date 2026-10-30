local uiRecovery -- UI state is transient; never part of a gameplay save.
include('IconSupport');include('InstanceManager');include('RED_Core')
local R=MapModData.RED_Legend
local rows=InstanceManager:new('REDPartnerRow','Root',Controls.PartyRows)
local opened,focused,candidate,destination=false,nil,nil,nil
local blocked,leader=false,false
local function text(key) return Locale.ConvertTextKey('TXT_KEY_RED_'..key) end
local function state() return R.States[Game.GetActivePlayer()] end
local function selected(s)
 local u=UI.GetHeadSelectedUnit()
 if u and u:GetOwner()==s.pid and R.Eligible(u) then return u end
 return focused and R.Unit(s,focused) or candidate and R.Unit(s,candidate)
end
local function candidates(s)
 local out={}
 for _,r in pairs(s.units) do local u=R.Unit(s,r.serial)
  if u and not r.slot and u:GetDomainType()~=DomainTypes.DOMAIN_AIR and R.Rank(r)>=3 then out[#out+1]=r.serial end
 end
 table.sort(out);return out
end
local function cities(s)
 local out={};for city in Players[s.pid]:Cities() do
  if city:GetNumBuilding(R.CENTER)>0 or city:GetNumBuilding(GameInfoTypes.BUILDING_AIRPORT)>0 then out[#out+1]=city:GetID() end
 end
 table.sort(out);return out
end
local function cycle(list,current)
 for i,n in ipairs(list) do if current==n then return list[i%#list+1] end end
 return list[1]
end
local function world()
 if uiRecovery then return uiRecovery:Available(),uiRecovery:Reason() end;
 if blocked or leader or UI.IsCityScreenUp() or UI.GetInterfaceMode()~=InterfaceModeTypes.INTERFACEMODE_SELECTION then return false end
 for _,name in ipairs({'CivilopediaScreen','TechTree','GenericPopup','SocialPolicyPopup','EconomicOverview','MilitaryOverview','DiploOverview','ProductionPopup','GameMenu','CultureOverview','ReligionOverview'}) do
  local control=ContextPtr:LookUpControl('/InGame/'..name);if control and not control:IsHidden() then return false end
 end
 return true
end
local refresh
local function command(kind,serial,slot)
 local pid=Game.GetActivePlayer();local s=R.States[pid];local p=Players[pid]
 if not s or not R.IsRed(pid) or not p:IsHuman() or not p:IsTurnActive() or not world() then return end
 local u=serial and R.Unit(s,serial) or selected(s)
 local ok=false
 if kind=='ASSIGN' then ok=u and R.Assign(s,u,slot)
 elseif kind=='RELEASE' then ok=serial and R.Release(s,serial)
 elseif kind=='ATTACH' then ok=u and R.Attach(s,u)
 elseif kind=='DETACH' then ok=u and R.Detach(s,u)
 elseif kind=='ITEM' then ok=u and R.Item(s,u)
 elseif kind=='AIRLIFT' then ok=u and destination and R.Airlift(s,u,p:GetCityByID(destination)) end
 Controls.Help:SetText(ok and text('PANEL_HELP') or 'Action unavailable: check movement, ownership, team eligibility, cooldown or destination.')
 refresh()
end
local function detail(s,u)
 if not u then return text('PANEL_HELP') end
 local serial=R.Serial(u);local r=serial and s.units[serial]
 if not r then return '' end
 local identity=r.identity and text(r.identity) or 'Identity awaits Mt. Silver'
 return u:GetName()..' — '..identity..'[NEWLINE]Battle Item ready on turn '..(r.itemReady or 0)..'; withdrawal ready on turn '..(r.withdrawReady or 0)..'. Training: '..r.training..'; Ribbons: '..r.ribbons..'.[NEWLINE]'..(r.identity and text(r.identity..'_HELP') or text('TRAINING_HELP'))
end
local rendering=false
refresh=function()
 if uiRecovery then uiRecovery:Sync() end
 if rendering then return end;rendering=true
 local ok,err=pcall(function()
  local pid=Game.GetActivePlayer();local p=Players[pid];local s=R.States[pid]
  local visible=R.IsRed(pid) and p:IsAlive() and p:IsHuman() and p:IsTurnActive() and world() and s~=nil
 visible=visible and (not uiRecovery or uiRecovery:Available())
 Controls.Launcher:SetHide(not visible)
  if not visible then opened=false end
  Controls.Panel:SetHide(not opened);if not opened then return end
  local team=R.Team(s);local silver=s.silver;local status=silver.phase
  if status=='ABSENT' then status='Mt. Silver: '..math.max(0,silver.due-Game.GetGameTurn())..' turns remaining'
  elseif status=='RETURNING' then status='Returning: waiting for legal friendly plots'
  elseif status=='READY' then status=R.SilverEligible(s) and 'Mt. Silver eligible' or 'Mt. Silver: requires Modern Era, 4 living partners, 1 Legendary' end
  local progress=''
  for city in p:Cities() do if city:GetProductionProject()==R.PROJECT then progress='  Production: '..city:GetProduction()..' / '..city:GetProductionNeeded();break end end
  Controls.Summary:SetText('Capacity: '..#team..' / '..R.Capacity(s)..' (maximum 6)[NEWLINE]'..status..progress)
  Controls.RosterMode:SetText(s.manual and 'Roster: Manual' or 'Roster: Automatic')
  local activeIdentities={};for _,r in ipairs(team) do if r.identity then activeIdentities[r.identity]=true end end
  local vacantIdentities={};for _,name in ipairs(R.Names) do if not activeIdentities[name] then vacantIdentities[#vacantIdentities+1]=name end end
  local vacantIndex=0
  rows:ResetInstances()
  for slot=1,6 do
   local c=rows:GetInstance();local serial=s.slots[slot];local r=serial and s.units[serial];local u=r and R.Unit(s,serial)
   if not r then vacantIndex=vacantIndex+1 end
   local fallback=vacantIdentities[vacantIndex] or R.Names[slot]
   c.IdentityIcon:SetHide(not r or not r.identity)
   if r and r.identity then
    for i,name in ipairs(R.Names) do if r.identity==name then IconHookup(i-1,32,'RED_IDENTITY_ATLAS',c.IdentityIcon) end end
   elseif silver.phase=='RETURNED' or silver.phase=='RETURNING' then
    c.IdentityIcon:SetHide(false);for i,name in ipairs(R.Names) do if name==fallback then IconHookup(i-1,32,'RED_IDENTITY_ATLAS',c.IdentityIcon) end end
   end
   if r then
    local snap=silver.snapshots[serial];local info=u and GameInfo.Units[u:GetUnitType()] or snap and GameInfo.Units[snap.unitType]
    if info then IconHookup(info.PortraitIndex,64,info.IconAtlas,c.Portrait) end
    local name=u and u:GetName() or snap and snap.name or 'Withdrawn partner'
    c.Name:SetText(slot..'. '..name..(r.identity and ' — '..text(r.identity) or ''))
    local hp=u and u:GetMaxHitPoints()-u:GetDamage() or snap and (snap.maxHP or snap.baseHP or 100)-(snap.damage or 0) or 0
    local maxhp=u and u:GetMaxHitPoints() or snap and (snap.maxHP or snap.baseHP) or 100
    c.Stats:SetText((info and Locale.ConvertTextKey(info.Description) or '')..'  Training '..r.training..' — '..text(R.Ranks[R.Rank(r)+1])..'[NEWLINE]HP '..hp..'/'..maxhp..'  XP '..(u and u:GetExperience() or snap and (snap.xp or 0)/100 or 0)..'  Level '..(u and u:GetLevel() or snap and snap.level or 1)..'[NEWLINE]Ribbons '..r.ribbons..'/5; Ace '..(r.ace and 'attached' or 'detached')..'; Summit-Trained '..(r.summit and 'yes' or 'no'))
    c.TrainingFill:SetSizeX(math.max(1,math.floor(math.min(1,r.training/100)*540)))
    c.Select:SetText(text('SELECT'));c.Select:SetDisabled(not u)
    c.Select:RegisterCallback(Mouse.eLClick,function() focused=serial;if u then UI.SelectUnit(u);UI.LookAt(u:GetPlot(),0) end;refresh() end)
    c.Release:SetDisabled(not u);c.Release:RegisterCallback(Mouse.eLClick,function() command('RELEASE',serial) end)
    c.Inspect:SetDisabled(false);c.Inspect:RegisterCallback(Mouse.eLClick,function() focused=serial;Controls.Details:SetText(u and detail(s,u) or 'Training safely stored during the Journey. Return due on turn '..tostring(silver.due)) end)
   else
    IconHookup(0,64,'RED_CIV_ATLAS',c.Portrait)
    c.Name:SetText(slot..'. '..(slot>R.Capacity(s) and 'Locked slot' or 'Vacant slot')..(silver.phase=='RETURNED' and ' — '..text(fallback) or ''))
    c.Stats:SetText(slot>R.Capacity(s) and 'Classical: 3. Medieval: 4. First national wonder: 6.' or 'Choose a Champion-rank non-air candidate below. Fallen partners are never recreated.')
    c.TrainingFill:SetSizeX(1);c.Select:SetText(text('ASSIGN'));c.Select:SetDisabled(not candidate or slot>R.Capacity(s))
    local targetSlot=slot;c.Select:RegisterCallback(Mouse.eLClick,function() command('ASSIGN',candidate,targetSlot) end)
    c.Inspect:SetDisabled(true)
    c.Release:SetDisabled(true)
   end
  end
  Controls.PartyRows:CalculateSize();Controls.PartyRows:ReprocessAnchoring();Controls.PartyScroll:CalculateInternalSize()
  local choices=candidates(s);if not candidate or not R.Unit(s,candidate) or s.units[candidate].slot then candidate=choices[1] end
  local cu=candidate and R.Unit(s,candidate);Controls.CandidateInfo:SetText(cu and cu:GetName()..' — Training '..s.units[candidate].training or 'No unassigned Champion-rank candidates')
  local u=selected(s);local r=u and R.Peek(u)
  Controls.Attach:SetDisabled(not u or not R.CanAttach(s,u));Controls.Detach:SetDisabled(not r or not r.ace or u:GetPlot():GetOwner()~=s.pid)
  Controls.Item:SetDisabled(not u or not R.CanItem(s,u))
  local dest=destination and p:GetCityByID(destination)
  Controls.Destination:SetText(dest and dest:GetName() or text('DESTINATION'))
  local airlift=s.pendingAirlifts and u and s.pendingAirlifts[R.Serial(u)]
  Controls.Airlift:SetDisabled(not u or not dest or airlift~=nil)
  Controls.Details:SetText(detail(s,u)..(airlift and '[NEWLINE]Airlift pending; the source allowance is consumed after arrival.' or ''))
 end)
 rendering=false;if not ok then print('[Red] Team panel: '..tostring(err));Controls.Panel:SetHide(true);opened=false end
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
Controls.Close:RegisterCallback(Mouse.eLClick,function() opened=false;refresh() end)
Controls.RosterMode:RegisterCallback(Mouse.eLClick,function()
 local s=state();if not s then return end
 s.manual=not s.manual;if not s.manual then R.AutoAssign(s) end;R.Changed(s);refresh()
end)
Controls.Candidate:RegisterCallback(Mouse.eLClick,function() local s=state();if s then candidate=cycle(candidates(s),candidate);refresh() end end)
Controls.Destination:RegisterCallback(Mouse.eLClick,function() local s=state();if s then destination=cycle(cities(s),destination);refresh() end end)
for _,pair in ipairs({{'Attach','ATTACH'},{'Detach','DETACH'},{'Item','ITEM'},{'Airlift','AIRLIFT'}}) do
 local kind=pair[2];Controls[pair[1]]:RegisterCallback(Mouse.eLClick,function() command(kind) end)
end
local function close() opened=false;refresh() end
R.Hook(LuaEvents,'RED_TeamChanged',function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
R.Hook(Events,'SerialEventUnitInfoDirty',function() if opened then refresh() end end)
R.Hook(Events,'SerialEventGameDataDirty',refresh)
R.Hook(Events,'SerialEventEnterCityScreen',close)
R.Hook(Events,'SerialEventExitCityScreen',function() blocked=false;close() end)
R.Hook(Events,'AILeaderMessage',function() leader=true;close() end)
R.Hook(Events,'LeavingLeaderViewMode',function() leader=false;close() end)
R.Hook(Events,'SerialEventGameMessagePopupShown',function() blocked=true;close() end)
R.Hook(Events,'SerialEventGameMessagePopupProcessed',function() blocked=false;close() end)
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','LoadScreenClose'}) do R.Hook(Events,name,function() blocked=false;leader=false;close() end) end
R.Hook(Events,'ActivePlayerTurnEnd',close);R.Hook(Events,'InterfaceModeChanged',close)
ContextPtr:SetInputHandler(function(msg,key)
 if uiRecovery and not uiRecovery:Available() then return false end
 if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then close();return true end return false end)
refresh()

-- Shared screen recovery: actual native visibility wins over stale event flags.
local helperLoaded=pcall(include,'CWC2_Screen')
if CWC2_Screen then
 uiRecovery=CWC2_Screen.New{name='TrainerRed',civ='CIVILIZATION_RED_INDIGO_CHAMPION',context=ContextPtr,
  roots={Controls.Launcher,Controls.Panel},panels={Controls.Panel},
  refresh=function() refresh() end,
  recover=function() blocked=false;leader=false end,repair=function() rendering=false end,
  close=function() opened=false end,manageContext=true}
 uiRecovery:Refresh(true)
end
