include('MCP_Core')
local M=MapModData.MCPVP
local opened,leader,blocked,rendering=false,false,false,false
local targetIndex,targetKey,selectedID=1,nil,nil
local targets={}
local function state() return M.states[Game.GetActivePlayer()] end
local function selected(s)
 local u=UI.GetHeadSelectedUnit()
 if u and u:GetOwner()==s.pid and M.Military(u) then return u end
end
local function eligible()
 local pid=Game.GetActivePlayer();local p=Players[pid]
 return p and M.IsCiv(pid) and p:IsHuman() and p:IsTurnActive() and not leader and not blocked and not UI.IsCityScreenUp() and not Game.IsNetworkMultiPlayer()
end
local function refresh()
 if rendering then return end;rendering=true
 local ok,err=pcall(function()
  local s=state();local show=eligible() and s and s.mode~=nil
  Controls.Launcher:SetHide(not show);Controls.Panel:SetHide(not (show and opened))
  if not show or not opened then return end
  Controls.Summary:SetText('Current: '..M.Text(s.mode)..'    Queued: '..M.Text(s.queued)..'    Turns remaining: '..math.max(0,s.finish-M.Turn())..'[NEWLINE]Server Legacy: '..s.current..'    Lifetime: '..s.lifetime..'    Completed matches: '..s.completed..'[NEWLINE]Victories - HG: '..s.wins.HG..'    CTF: '..s.wins.CTF..'    Sabotage: '..s.wins.SAB)
  local objective
  if s.mode=='HG' then
   local f=s.feast;local plot=f and M.FeastPlot(s)
   local phase=M.Turn()<s.start+M.Turns(3) and 'Grace Period' or M.Turn()<s.start+M.Turns(10) and 'Feast preparations' or 'Final Battle'
   objective=phase..'. Secure the contested Feast to win. Kills: '..s.kills..'; kill Legacy: '..s.killLegacy..'/15; near-Feast Legacy: '..s.nearLegacy..'/10.[NEWLINE]'
   objective=objective..(f and plot and (f.announced and 'Feast: ('..plot:GetX()..', '..plot:GetY()..') - '..f.status or 'Feast coordinates announced '..M.Turns(3)..' turns before activation.') or 'No accessible Feast site this match.')
  elseif s.mode=='CTF' then objective='Steal a flag adjacent to a visible enemy city at war. Return it to a land tile belonging to one of your cities. Each city may be raided once per match. Captures: '..s.captures..'.'
  else objective='A Veteran or recon unit can infiltrate a visible enemy city within two tiles. Stay nearby for '..M.Turns(3)..' turns; the defender is warned after the first turn. Successful missions: '..s.missions..'.' end
  Controls.Objective:SetText(objective..'[NEWLINE]Legacy earned this match: '..s.earned..(s.remembered and '[NEWLINE]Legacy Unforgotten: +10% military XP; memory Culture active.' or ''))
  Controls.LastMatch:SetText(s.summary or 'No completed match yet. The lobby is open.')
  Controls.StatusStack:CalculateSize();Controls.StatusStack:ReprocessAnchoring();Controls.StatusScroll:CalculateInternalSize()
  Controls.Locate:SetDisabled(not (s.feast and s.feast.announced and M.FeastPlot(s)))
  local u=selected(s);local r=u and M.Peek(s,u)
  if not u or selectedID~=u:GetID() then targetKey=nil;targetIndex=1 end
  selectedID=u and u:GetID()
  Controls.UnitInfo:SetText(u and u:GetName()..' - '..(r and r.kit and M.Text(r.kit) or 'No kit selected') or 'Select a military unit on the map')
  local details=r and r.kit and M.Text(r.kit..'_HELP') or 'Veterans and land military units trained in a Server Hub can select one kit.'
  if r then
   details=details..'[NEWLINE]'..M.AbilityReason(s,u)
   if r.veteran then details=details..' Veteran kit change: '..math.max(0,r.changeReady-M.Turn())..' turns.' end
   if r.flag then details=details..'[NEWLINE]FLAG CARRIER: return home. Attacks, ordinary upgrades, gifts and disbanding are blocked.' end
   if r.mission then details=details..'[NEWLINE]INFILTRATING: '..math.max(0,r.mission.finish-M.Turn())..' turns remaining. Stay within two tiles.' end
  end
  Controls.UnitDetails:SetText(details)
  for _,pair in ipairs({{'Kangaroo','KANGAROO'},{'Stomper','STOMPER'},{'Endermage','ENDERMAGE'},{'Thor','THOR'},{'Viper','VIPER'}}) do
   local can,why=false,'Select an eligible unit.';if u then can,why=M.CanKit(s,u,pair[2]) end
   Controls[pair[1]]:SetDisabled(not can);Controls[pair[1]]:SetToolTipString(M.Text(pair[2]..'_HELP')..'[NEWLINE]'..why)
  end
  targets={}
  if u then
   for _,ref in ipairs(M.AbilityTargets(s,u)) do targets[#targets+1]={kind='ABILITY',ref=ref} end
   for _,kind in ipairs({'STEAL','INFILTRATE'}) do for _,ref in ipairs(M.ObjectiveTargets(s,u,kind)) do targets[#targets+1]={kind=kind,ref=ref} end end
  end
  for i,t in ipairs(targets) do if t.kind..t.ref.key==targetKey then targetIndex=i end end
  if targetIndex>#targets then targetIndex=1 end
  local t=targets[targetIndex];targetKey=t and t.kind..t.ref.key
  Controls.Target:SetDisabled(#targets==0)
  local description='No valid targets. War, current visibility, movement and range are required.'
  if t then
   local ref=t.ref;local obj=t.kind=='ABILITY' and Players[ref.owner]:GetUnitByID(ref.id) or M.City(ref)
   description=t.kind..': '..(obj and obj:GetName() or 'Target')..' ('..ref.x..', '..ref.y..') ['..targetIndex..'/'..#targets..']'
  end
  Controls.TargetInfo:SetText(description)
  for _,pair in ipairs({{'Activate','ABILITY'},{'Steal','STEAL'},{'Infiltrate','INFILTRATE'}}) do
   Controls[pair[1]]:SetDisabled(not t or t.kind~=pair[2]);Controls[pair[1]]:SetToolTipString(description)
  end
  local canReturn=r and r.flag and M.Land(u) and u:MovesLeft()>0 and M.ReturnCity(s.pid,u:GetPlot()) and M.FlagCity(r.flag) and M.AtWar(s.pid,r.flag.owner)
  Controls.Return:SetDisabled(not canReturn);Controls.Return:SetToolTipString('Carry a valid enemy flag onto a land tile belonging to one of your cities, with movement remaining.')
 end)
 rendering=false
 if not ok then print('[McPvP] Browser: '..tostring(err));opened=false;Controls.Panel:SetHide(true) end
end
local function command(kind,kit)
 local s=state();if not s then return end;local u=selected(s);local t=targets[targetIndex]
 LuaEvents.MCPVP_Command(s.pid,kind,u and u:GetID(),t and t.ref,kit);refresh()
end
Controls.Open:RegisterCallback(Mouse.eLClick,function() opened=not opened;refresh() end)
local function close() opened=false;refresh() end
Controls.Close:RegisterCallback(Mouse.eLClick,close)
for _,pair in ipairs({{'QueueHG','HG'},{'QueueCTF','CTF'},{'QueueSAB','SAB'}}) do local mode=pair[2]
 Controls[pair[1]]:RegisterCallback(Mouse.eLClick,function() local s=state();if s then LuaEvents.MCPVP_Command(s.pid,'QUEUE',nil,mode);refresh() end end)
end
for _,pair in ipairs({{'Kangaroo','KANGAROO'},{'Stomper','STOMPER'},{'Endermage','ENDERMAGE'},{'Thor','THOR'},{'Viper','VIPER'}}) do local kit=pair[2]
 Controls[pair[1]]:RegisterCallback(Mouse.eLClick,function() command('KIT',kit) end)
end
for _,pair in ipairs({{'Activate','ABILITY'},{'Steal','STEAL'},{'Return','RETURN'},{'Infiltrate','INFILTRATE'}}) do local kind=pair[2];Controls[pair[1]]:RegisterCallback(Mouse.eLClick,function() command(kind) end) end
Controls.Target:RegisterCallback(Mouse.eLClick,function() if #targets>0 then targetIndex=targetIndex%#targets+1;targetKey=targets[targetIndex].kind..targets[targetIndex].ref.key;refresh() end end)
Controls.Locate:RegisterCallback(Mouse.eLClick,function() local s=state();local plot=s and M.FeastPlot(s);if plot and s.feast.announced then UI.LookAt(plot,0) end end)
M.Hook(LuaEvents,'MCPVP_Changed',function(pid) if pid==Game.GetActivePlayer() then refresh() end end)
M.Hook(Events,'SerialEventUnitInfoDirty',function() if opened then refresh() end end)
M.Hook(Events,'SerialEventUnitFlagSelected',function() if opened then refresh() end end)
M.Hook(Events,'SerialEventGameDataDirty',refresh)
M.Hook(Events,'SerialEventEnterCityScreen',close)
M.Hook(Events,'SerialEventExitCityScreen',function() blocked=false;close() end)
M.Hook(Events,'AILeaderMessage',function() leader=true;close() end)
M.Hook(Events,'LeavingLeaderViewMode',function() leader=false;close() end)
M.Hook(Events,'SerialEventGameMessagePopupShown',function() blocked=true;close() end)
M.Hook(Events,'SerialEventGameMessagePopupProcessed',function() blocked=false;close() end)
for _,name in ipairs({'GameplaySetActivePlayer','ActivePlayerTurnStart','LoadScreenClose'}) do M.Hook(Events,name,function() blocked=false;leader=false;close() end) end
M.Hook(Events,'ActivePlayerTurnEnd',close)
M.Hook(Events,'InterfaceModeChanged',close)
ContextPtr:SetInputHandler(function(msg,key) if opened and msg==KeyEvents.KeyDown and key==Keys.VK_ESCAPE then close();return true end return false end)
refresh()
