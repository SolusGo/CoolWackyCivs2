-- Dormant legacy source. The human-only controller does not include this file.
local U=MapModData.URGAL
function U.AITurn(id)
 if not U.active or not U.Civ(id) or Players[id]:IsHuman() then return false end
 if not U.CanDrink(id) then return end
 local p=Players[id]; local team=p:GetTeam(); local candidates={}
 for u in p:Units() do
  if U.Eligible(u) and not u:IsEmbarked() and u:MovesLeft()>0 and not u:IsOutOfAttacks() then
   candidates[#candidates+1]=u
  end
 end
 if #candidates<3 then return end
 -- At most 48 anchors, each with a bounded radius-three hex scan. The army
 -- must already have several units within striking distance of one engagement.
 for i=1,math.min(48,#candidates) do
  local anchor=candidates[i]; local enemies,city,invaded,attackNow=0,false,false,false
  for dx=-3,3 do for dy=-3,3 do
   local plot=Map.PlotXYWithRangeCheck(anchor:GetX(),anchor:GetY(),dx,dy,3)
   if plot and plot:IsVisible(team,false) then
    local c=plot:GetPlotCity()
    local adjacent=Map.PlotDistance(anchor:GetX(),anchor:GetY(),plot:GetX(),plot:GetY())==1
    if c and Teams[team]:IsAtWar(Players[c:GetOwner()]:GetTeam()) and adjacent and anchor:CanMoveOrAttackInto(plot,0,1) then city=true;attackNow=true end
    for n=0,plot:GetNumUnits()-1 do
     local enemy=plot:GetUnit(n)
     if U.Alive(enemy) and enemy:IsCombatUnit() and not enemy:IsInvisible(team,false) and Teams[team]:IsAtWar(Players[enemy:GetOwner()]:GetTeam()) then
      enemies=enemies+1
      if adjacent and anchor:CanMoveOrAttackInto(plot,0,1) then attackNow=true end
      if plot:GetOwner()==id then invaded=true end
     end
    end
   end
  end end
  if attackNow and (enemies>=2 or city or (invaded and enemies>=1)) then
   local close=0
   for _,u in ipairs(candidates) do
    if Map.PlotDistance(anchor:GetX(),anchor:GetY(),u:GetX(),u:GetY())<=2 then close=close+1 end
   end
   if close>=3 then U.Drink(id);return end
  end
 end
end
