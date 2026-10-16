-- Extend the collection's engine double; gameplay under test is the shipped McPvP Lua.
local cap=TEST.cap
local City=getmetatable(cap)
function City:GetGameTurnFounded() return self.founded or 0 end
local Plot=getmetatable(cap:Plot())
function Plot:GetArea() return self.area or 0 end
function Plot:IsHills() return self.hill or false end
function Plot:IsRevealed() return not self.hidden end
function Plot:IsVisible() return not self.invisible end
function Plot:GetWorkingCity() return self.workingCity or (self.owner>=0 and Players[self.owner]:GetCapitalCity()) end
local unit=TEST.new('UNIT_WARRIOR',3,3)
local Unit=getmetatable(unit);unit:Kill(false,-1)
function Unit:IsInvisible() return self.invisible or false end
function Unit:SetMadeAttack(v) self.attacked=v end
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
for _,p in pairs(Players) do p.civ=GameInfoTypes.CIVILIZATION_AMERICA end
Players[0].civ=GameInfoTypes.CIVILIZATION_MCPVP
for _,team in pairs(Teams) do team.IsHasMet=function() return true end end
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
 UI={GetHeadSelectedUnit=function() return TEST.selected end,IsCityScreenUp=function() return TEST.cityScreen or false end,LookAt=function() TEST.located=true end}
 Mouse={eLClick=1};Keys={VK_ESCAPE=27};KeyEvents={KeyDown=1}
 function ContextPtr:SetInputHandler(fn) self.input=fn end
 TEST.LoadPanel()
end
