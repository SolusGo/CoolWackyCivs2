local R=MapModData.RED_Legend
function R.RangeBonus(u,r)
 local eligible=(r.identity=='CHARIZARD' or r.identity=='LAPRAS') and u:IsRanged()
 if eligible then
  for promotion in GameInfo.UnitPromotions() do
   if (promotion.RangeChange or 0)>0 and promotion.ID~=R.Promo('RANGE') and u:IsHasPromotion(promotion.ID) then eligible=false;break end
  end
 end
 R.Set(u,'RANGE',eligible)
 if r.identity=='SNORLAX' then
  for i=1,32 do R.Set(u,'SNORLAX_LIMIT_'..i,false) end
  local extra=math.max(0,math.floor(u:MaxMoves()/(GameDefines.MOVE_DENOMINATOR or 60))-1)
  if extra>0 then R.Set(u,'SNORLAX_LIMIT_'..math.min(32,extra),true) end
 else
  for i=1,32 do R.Set(u,'SNORLAX_LIMIT_'..i,false) end
 end
end
function R.Adjacent(u,fn,radius)
 local origin=Map.GetPlot(u:GetX(),u:GetY());if not origin then return end
 -- Native neighbors respect map wrapping; coordinate rectangles need not.
 local queue={{plot=origin,d=0}};local seen={[origin:GetPlotIndex()]=true};local i=1
 while queue[i] do local node=queue[i];i=i+1;local p=node.plot
  for j=0,p:GetNumUnits()-1 do fn(p:GetUnit(j)) end
  if node.d<(radius or 1) then
   for direction=0,5 do local nextPlot=Map.PlotDirection(p:GetX(),p:GetY(),direction)
    if nextPlot and not seen[nextPlot:GetPlotIndex()] then seen[nextPlot:GetPlotIndex()]=true;queue[#queue+1]={plot=nextPlot,d=node.d+1} end
   end
  end
 end
end
function R.PartnerAura(pid)
 local p=Players[pid]
 local healed={}
 for u in p:Units() do
  R.positions[pid..':'..u:GetID()]={x=u:GetX(),y=u:GetY()}
  -- These belong solely to this mod. Other mods' negative statuses are untouched.
  R.Set(u,'BLOOM_STATUS',false);R.Set(u,'HORIZON',false)
 end
 for redID=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if R.IsRed(redID) and Players[redID]:IsAlive() then
  local s=R.State(redID)
  for _,r in ipairs(R.Team(s)) do local u=R.Unit(s,r.serial)
   if u and r.identity=='VENUSAUR' then
    R.Adjacent(u,function(v)
     if v:GetID()~=u:GetID() or v:GetOwner()~=u:GetOwner() then
      local key=v:GetOwner()..':'..v:GetID()
      if pid==redID and Players[v:GetOwner()]:GetTeam()==Players[redID]:GetTeam() and not healed[key] then healed[key]=true;R.Heal(v,10)
      elseif v:GetOwner()==pid and R.AtWar(pid,redID) then R.Set(v,'BLOOM_STATUS',true) end
     end
    end)
   elseif u and r.identity=='LAPRAS' then
    R.Adjacent(u,function(v) if v:GetOwner()==pid and Players[pid]:GetTeam()==Players[redID]:GetTeam() and v:IsEmbarked() then R.Set(v,'HORIZON',true) end end,2)
   end
  end
 end end
end
function R.LaprasAuraFor(u)
 local on=false
 if u:IsEmbarked() then
  for pid,s in pairs(R.States) do if Players[pid]:GetTeam()==Players[u:GetOwner()]:GetTeam() then
   for _,r in ipairs(R.Team(s)) do local lapras=R.Unit(s,r.serial)
    if lapras and r.identity=='LAPRAS' and R.Distance(u,lapras)<=2 then on=true end
   end
  end end
 end
 R.Set(u,'HORIZON',on)
end
function R.Splash(attacker,x,y)
 local target=Map.GetPlot(x,y);if not target then return end
 local victims={}
 for direction=0,5 do local p=Map.PlotDirection(x,y,direction)
  if p then for j=0,p:GetNumUnits()-1 do local v=p:GetUnit(j)
   if R.AtWar(attacker:GetOwner(),v:GetOwner()) and R.Alive(v) then victims[#victims+1]={pid=v:GetOwner(),id=v:GetID()} end
  end end
 end
 for _,key in ipairs(victims) do local v=Players[key.pid]:GetUnitByID(key.id)
  if R.Alive(v) then v:ChangeDamage(5,attacker:GetOwner()) end
 end
end
function R.EscapePlot(u,enemy)
 local plots={}
 for direction=0,5 do local p=Map.PlotDirection(u:GetX(),u:GetY(),direction)
  if p and not p:IsVisibleEnemyUnit(u:GetOwner()) and u:CanMoveOrAttackInto(p,0,1)
   and not p:IsCity() and (not p:IsWater() or u:GetDomainType()==DomainTypes.DOMAIN_SEA or u:IsEmbarked()) then
   local occupied=false;for i=0,p:GetNumUnits()-1 do if p:GetUnit(i):IsCombatUnit() then occupied=true end end
   if not occupied then plots[#plots+1]={p=p,d=R.Distance(enemy,p),index=p:GetPlotIndex()} end
  end
 end
 table.sort(plots,function(a,b) if a.d~=b.d then return a.d>b.d end return a.index<b.index end)
 return plots[1] and plots[1].p
end
function R.Moved(pid,id,x,y)
 if R.internal>0 then return end
 local p=Players[pid];local u=p and p:GetUnitByID(id);if not R.Alive(u) then return end
 local key=pid..':'..id;local old=R.positions[key];R.positions[key]={x=x,y=y}
 if u:IsEmbarked() then R.LaprasAuraFor(u) end
 if R.IsRed(pid) then
  local r,s=R.Record(u)
  if r then
   if old and (old.x~=x or old.y~=y) and r.quickFortify then r.quickFortify=nil;R.Set(u,'BLASTOISE_FORTIFY',false) end
   if r.identity=='SNORLAX' and old and (old.x~=x or old.y~=y) then u:FinishMoves() end
   if r.ace and u:IsDead() then r.ace=nil end
   R.Apply(u,r);R.Changed(s)
   if r.identity=='LAPRAS' then
    R.Adjacent(u,function(v) if v:IsEmbarked() then R.LaprasAuraFor(v) end end,3)
    if old then R.Adjacent({GetX=function()return old.x end,GetY=function()return old.y end},function(v) if v:IsEmbarked() then R.LaprasAuraFor(v) end end,3) end
   end
  end
 end
 -- A movement event is needed only for Snorlax's exceptional ZOC.
 if old and u:GetDomainType()==DomainTypes.DOMAIN_LAND and not u:IsEmbarked() then
  for redID,s in pairs(R.States) do if R.AtWar(pid,redID) then
   for _,r in ipairs(R.Team(s)) do local anchor=R.Unit(s,r.serial)
    if anchor and r.identity=='SNORLAX' and Map.PlotDistance(old.x,old.y,anchor:GetX(),anchor:GetY())==1 and R.Distance(u,anchor)==1 then u:FinishMoves();return end
   end
  end end
 end
end
R.positions={}
