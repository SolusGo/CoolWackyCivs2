local R=MapModData.RED_Legend
local thresholds={0,15,35,65,100}
function R.Rank(r)
 local multiplier=r.ace and r.slot and 0.9 or 1
 for i=5,1,-1 do if (r.training or 0)+0.000001>=thresholds[i]*multiplier then return i-1 end end
 return 0
end
function R.AddTraining(u,amount,combat,cap)
 local r,s=R.Record(u);if not r then return end
 if combat and r.ace then amount=amount*1.5 end
 if cap then amount=math.max(0,math.min(amount,cap-r.training)) end
 if amount<=0 then return end
 r.training=math.floor((r.training+amount)*100+0.5)/100
 R.Apply(u,r);R.AutoAssign(s);R.Yields(s);R.Changed(s)
end
function R.Apply(u,r)
 for typ,expires in pairs(r.promotionExpiry or {}) do
  if expires<=Game.GetGameTurn() then local id=GameInfoTypes[typ];if id then u:SetHasPromotion(id,false) end;r.promotionExpiry[typ]=nil end
 end
 local rank=R.Rank(r)
 for i,name in ipairs(R.Ranks) do R.Set(u,name,i-1==rank) end
 R.Set(u,'TEAM',r.slot~=nil);R.Set(u,'BOND',r.ace~=nil);R.Set(u,'BOND_SIGHT',r.ace~=nil and r.slot~=nil and rank==4)
 R.Set(u,'SUMMIT',r.summit==true)
 R.Set(u,'BLASTOISE_FORTIFY',r.quickFortify==true and u:GetFortifyTurns()==0)
 for i=1,5 do R.Set(u,'RIBBON_'..i,r.ribbons==i) end
 for _,name in ipairs(R.Names) do R.Set(u,name,r.identity==name) end
 R.Set(u,'LAPRAS_OCEAN',r.identity=='LAPRAS' and u:GetDomainType()==DomainTypes.DOMAIN_SEA)
 if R.RangeBonus then R.RangeBonus(u,r) end
 if r.identity=='SNORLAX' then
  -- One tile per turn including roads: movement expenditure is capped separately.
  local limit=GameDefines.MOVE_DENOMINATOR or 60
  if r.stepTurn==Game.GetGameTurn() then u:FinishMoves()
  elseif u:MovesLeft()>limit then u:SetMoves(limit) end
 end
end
function R.Passive(s,ending)
 local p=Players[s.pid];local cap=p:GetCapitalCity();local plateau=false
 for city in p:Cities() do if city:GetNumBuilding(R.PLATEAU)>0 then plateau=true end end
 for u in p:Units() do local r=R.Record(u)
  if r then
   local inCap=cap and u:GetX()==cap:GetX() and u:GetY()==cap:GetY()
   if ending then
    if inCap and u:GetDamage()>0 then R.AddTraining(u,2*100/R.Percent,false) end
   else
    if inCap and r.slot and plateau then R.AddTraining(u,2*100/R.Percent,false) end
    local city=u:GetPlot():GetPlotCity()
    if city and city:GetOwner()==s.pid and city:GetNumBuilding(R.CENTER)>0 and r.slot then R.AddTraining(u,3*100/R.Percent,false,65) end
    if r.ace then R.Heal(u,5) end
    if r.identity=='SNORLAX' and u:GetFortifyTurns()>0 then R.Heal(u,15) end
   end
  end
 end
end
-- Native healing includes ordinary, pillage, promotion and third-party healing.
-- Only the exact Proven rank receives its mutually exclusive extra heal.
function R.NativeHeal(pid,id,damage,oldDamage)
 if not R.IsRed(pid) or damage>=oldDamage or R.internal>0 then return end
 local key=pid..':'..id;if R.healGuard[key] then return end
 local u=Players[pid]:GetUnitByID(id);if not R.Alive(u) then return end
 local r=R.Record(u);if not r or u:GetDamage()~=damage then return end
 local extra=R.Rank(r)==2 and 5 or 0
 -- Center healing territory is owned land within three hexes. Only boosts a real heal.
 for city in Players[pid]:Cities() do
  if city:GetNumBuilding(R.CENTER)>0 and u:GetPlot():GetOwner()==pid and R.Distance(u,city)<=3 and r.centerHealTurn~=Game.GetGameTurn() then
   extra=extra+15;r.centerHealTurn=Game.GetGameTurn();break
  end
 end
 if extra>0 then R.healGuard[key]=true;u:SetDamage(math.max(0,u:GetDamage()-extra));R.healGuard[key]=nil end
 r.lastDamage=u:GetDamage()
 R.Changed(R.State(pid))
end
function R.HealingFallback(s)
 for u in Players[s.pid]:Units() do local r=R.Record(u)
  if r then
   if r.lastDamage and u:GetDamage()<r.lastDamage then R.NativeHeal(s.pid,u:GetID(),u:GetDamage(),r.lastDamage) end
   r.lastDamage=u:GetDamage()
  end
 end
end
