-- Extend the collection's engine double; gameplay under test is the shipped McPvP Lua.
local cap=TEST.cap
local City=getmetatable(cap)
function City:GetGameTurnFounded() return self.founded or 0 end
local Plot=getmetatable(cap:Plot())
function Plot:GetArea() return self.area or 0 end
function Plot:IsHills() return self.hill or false end
function Plot:IsMountain() return self.mountain or false end
function Plot:IsFighting() return self.fighting or false end
function Plot:IsRevealed() return not self.hidden end
function Plot:IsVisible() return not self.invisible end
function Plot:GetWorkingCity() return self.workingCity or (self.owner>=0 and Players[self.owner]:GetCapitalCity()) end
local unit=TEST.new('UNIT_WARRIOR',3,3)
local Unit=getmetatable(unit);unit:Kill(false,-1)
function Unit:IsInvisible() return self.invisible or false end
function Unit:SetMadeAttack(v) self.attacked=v end
function Unit:IsBusy() return self.busy or false end
function Unit:LastMissionPlot() return self.missionPlot end
function Unit:PopMission() self.missionPlot=nil end
function Unit:CanMoveThrough(plot)
 if not plot or plot:IsWater() or plot:IsMountain() or plot:IsImpassable() then return false end
 local owner=plot:GetOwner()
 if owner>=0 and owner~=self.pid and not Teams[self.pid]:IsAtWar(owner) and not Teams[owner]:IsAllowsOpenBordersToTeam(self.pid) then return false end
 if plot:IsCity() and plot:GetPlotCity():GetOwner()~=self.pid then return false end
 for _,v in ipairs(plot:list()) do if v.pid~=self.pid and Teams[self.pid]:IsAtWar(v.pid) then return false end end
 return true
end
function Plot:MovementCost(u,from,remaining)
 assert(u and from and type(remaining)=='number','CP movementCost takes unit, source and remaining movement')
 return (u:sum('IgnoreTerrainCost')>0 and 1 or self.moveCost or (self:IsHills() and 2 or 1))*60
end
function Unit:GeneratePath(goal,maxTurns)
 assert(type(maxTurns)=='number');TEST.pathCalls=(TEST.pathCalls or 0)+1
 if TEST.nativePath then return TEST.nativePath(self,goal,maxTurns) end
 if TEST.disableNative then return {} end
 -- Independent native-query double: unweighted BFS, with CP-shaped path rows.
 -- Production fallback is weighted Dijkstra and is tested with this query off.
 local queue={self:GetPlot()};local previous={[queue[1]:GetPlotIndex()]=false};local cursor=1
 while queue[cursor] do local at=queue[cursor];cursor=cursor+1
  if at==goal then local path={};local p=at
   while p do table.insert(path,1,{X=p:GetX(),Y=p:GetY(),RemainingMovement=0,Turn=0,Flags=0,Invisible=false,AdjInvisible=false});local n=previous[p:GetPlotIndex()];p=n and Map.GetPlotByIndex(n) end
   return path
  end
  for dir=0,5 do local p=Map.PlotDirection(at:GetX(),at:GetY(),dir)
   if p and previous[p:GetPlotIndex()]==nil and self:CanMoveThrough(p) then previous[p:GetPlotIndex()]=at:GetPlotIndex();queue[#queue+1]=p end
  end
 end
 return {}
end
function Unit:ChangeExperience(n) self.xp=self.xp+n*100 end
function Unit:ChangeDamage(n,killer)
 local previous=self.damage;self.damage=math.max(0,previous+n)
 if self.damage>=self:GetMaxHitPoints() then self:Kill(false,killer) end
end
local setxy=Unit.SetXY
function Unit:SetXY(x,y,group,update,show)
 for _,v in ipairs({group or 0,update or 1,show or 0}) do assert(type(v)=='number','CP SetXY flags must be integers') end
 setxy(self,x,y)
end
local Player=getmetatable(Players[0])
function Player:GetCivilizationShortDescription() return 'Civ '..self.pid end
function Player:ChangeGoldenAgeProgressMeter(n) self.ga=(self.ga or 0)+n end
function Player:GetPlotDanger(plot) return plot.danger or 0 end
for _,p in pairs(Players) do p.civ=GameInfoTypes.CIVILIZATION_AMERICA end
Players[0].civ=GameInfoTypes.CIVILIZATION_MCPVP
for _,team in pairs(Teams) do
 team.IsHasMet=function() return true end
 team.IsAtWar=function(self,other) if self.wars then return self.wars[other] or false end;return other~=self.id end
 team.IsAllowsOpenBordersToTeam=function(self,other) return self.borders and self.borders[other] or false end
end
for id,team in pairs(Teams) do team.id=id end
local pushMission=Unit.PushMission
function Unit:PushMission(kind,x,y,flags,append,manual)
 if kind==MissionTypes.MISSION_RANGE_ATTACK then TEST.attackOrders=(TEST.attackOrders or 0)+1 end
 if kind==MissionTypes.MISSION_MOVE_TO then
  local goal=Map.GetPlot(x,y);assert(goal and Map.PlotDistance(self.x,self.y,x,y)==1,'Objective missions must be adjacent native moves, not teleports')
  assert(type(append)=='number' and type(manual)=='number')
  TEST.moveAttempts=(TEST.moveAttempts or 0)+1
  if self.rejectMove then self.missionPlot=goal;return end
  assert(self:CanMoveThrough(goal),'Native move rejects illegal objective destination')
  self.missionPlot=nil
  local remaining=self.moves;local cost=goal:MovementCost(self,self:GetPlot(),remaining)
  self:SetXY(x,y);self:SetMoves(remaining-cost);return
 end
 return pushMission(self,kind,x,y)
end
Game.IsNetworkMultiPlayer=function() return TEST.multiplayer or false end
CommandTypes={COMMAND_UPGRADE=1,COMMAND_GIFT=2,COMMAND_DELETE=3}
for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);if not p:IsCity() then p.owner=-1 end end
function TEST.turnTo(n,pid)
 TEST.turn=n
 for u in Players[pid or 0]:Units() do u.moves=u:MaxMoves();u.attacked=false end
 GameEvents.PlayerDoTurn(pid or 0);TEST.flush()
end
function TEST.mcpReload()
 local M=MapModData.MCPVP
 M.states={};for pid=0,3 do if M.IsCiv(pid) then M.State(pid) end end
 M.Bootstrap();return M,M.State(0)
end
function TEST.mcpConvert(u,typ,owner,upgrade)
 local new=Players[owner or u.pid]:InitUnit(GameInfoTypes[typ],u.x,u.y)
 for id,on in pairs(u.promotions) do new.promotions[id]=on end
 new.xp=u.xp;new.damage=u.damage
 GameEvents.UnitConverted(u.pid,new.pid,u.id,new.id,upgrade~=false)
 u:Kill(false,-1);TEST.flush();return new
end
function TEST.loadUI()
 Controls=setmetatable({},{__index=function(t,k)
  local c={hidden=false,disabled=false}
  function c:SetHide(v) self.hidden=v end
  function c:SetDisabled(v) self.disabled=v end
  function c:SetText(v) self.text=v end
  function c:SetToolTipString(v) self.tooltip=v end
  function c:RegisterCallback(_,fn) self.click=fn end
  function c:CalculateSize() end
  function c:ReprocessAnchoring() end
  function c:CalculateInternalSize() end
  rawset(t,k,c);return c
 end})
 UI={GetHeadSelectedUnit=function() return TEST.selected end,IsCityScreenUp=function() return TEST.cityScreen or false end,LookAt=function() TEST.located=true end,
  GetInterfaceMode=function() return TEST.interfaceMode or 1 end}
 InterfaceModeTypes={INTERFACEMODE_SELECTION=1}
 function ContextPtr:LookUpControl(path)
  if TEST.screens and TEST.screens[path] then return {IsHidden=function() return false end} end
 end
 Mouse={eLClick=1};Keys={VK_ESCAPE=27};KeyEvents={KeyDown=1}
 function ContextPtr:SetInputHandler(fn) self.input=fn end
 TEST.LoadPanel()
end
-- Matches CP's complete ABI and resolution ordering; inputs are explicitly
-- damage TO each participant, and cumulative final damage, never remaining HP.
function TEST.combat(a,d,toDefender,toAttacker,options)
 options=options or {};local args={a.pid,a.id,toAttacker,a.damage+toAttacker,a:GetMaxHitPoints(),d.pid,d.id,toDefender,d.damage+toDefender,d:GetMaxHitPoints(),-1,-1,0,d.x,d.y}
 GameEvents.CombatResult(unpack(args))
 if options.duplicate then GameEvents.CombatResult(unpack(args)) end
 if options.unrelatedEnd then GameEvents.CombatEnded(2,999,0,0,100,1,998,0,0,100,-1,-1,0,0,0) end
 if not options.suppressDamage then
  d:ChangeDamage(toDefender,a.pid);a:ChangeDamage(toAttacker,d.pid)
  if options.healDefender then d:SetDamage(math.max(0,d.damage-options.healDefender)) end
 else args[8]=0 end -- resolution suppressed damage; cumulative forecast may remain positive
 GameEvents.CombatEnded(unpack(args))
 if options.duplicate then GameEvents.CombatEnded(unpack(args)) end
 TEST.flush();return args
end
