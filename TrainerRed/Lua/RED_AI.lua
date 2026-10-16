local R=MapModData.RED_Legend
local function role(u)
 if u:GetDomainType()==DomainTypes.DOMAIN_SEA then return 'NAVAL' end
 if u:IsRanged() then return 'RANGED' end
 if (GameInfo.Units[u:GetUnitType()].Moves or 0)>2 then return 'MOBILE' end
 return 'DEFENSIVE'
end
function R.RosterScore(s,u,r)
 local wanted=role(u);local present=false
 for _,mate in ipairs(R.Team(s)) do local v=R.Unit(s,mate.serial);if v and role(v)==wanted then present=true end end
 return r.training+(not present and 40 or 0)+R.Base(u)*0.1
end
local function nearestCity(p,u)
 local best,dist
 for city in p:Cities() do local d=R.Distance(u,city);if not dist or d<dist or (d==dist and city:GetID()<best:GetID()) then best=city;dist=d end end
 return best
end
local function safeEmpire(s)
 local p=Players[s.pid];local cap=p:GetCapitalCity();if not cap then return false end
 if cap:GetDamage()>cap:GetMaxHitPoints()/4 then return false end
 local enemy=0
 R.Adjacent(cap,function(u) if u:IsCombatUnit() and R.AtWar(s.pid,u:GetOwner()) then enemy=enemy+1 end end,5)
 return enemy<=1
end
function R.AITurn(s)
 local p=Players[s.pid];if p:IsHuman() then return end
 R.AutoAssign(s)
 local party=R.Team(s)
 -- Give the oldest scarce Ace to the most experienced unbonded partner first.
 table.sort(party,function(a,b) if a.training~=b.training then return a.training>b.training end return a.serial<b.serial end)
 for _,r in ipairs(party) do local u=R.Unit(s,r.serial)
  if u then
   if not r.ace then
    if not R.Attach(s,u) then
     for ace in p:Units() do if ace:GetUnitType()==R.ACE and ace:MovesLeft()>0 then
      if ace:GeneratePath(u:GetPlot(),1) then ace:PushMission(MissionTypes.MISSION_MOVE_TO,u:GetX(),u:GetY(),0,0,0);break end
     end end
    end
   end
   if u:GetDamage()>=25 and R.CanItem(s,u) then R.Item(s,u) end
   if u:GetDamage()>=math.floor(u:GetMaxHitPoints()*0.55) and u:MovesLeft()>0 then
    local city=nearestCity(p,u)
    if city and u:GeneratePath(city:Plot(),3) then u:PushMission(MissionTypes.MISSION_MOVE_TO,city:GetX(),city:GetY(),0,0,0)
    elseif u:CanFortify(u:GetPlot()) then u:PushMission(MissionTypes.MISSION_HEAL,-1,-1,0,0,0) end
   elseif s.silver.phase=='RETURNED' and u:MovesLeft()>0 and not R.Attacked(u) then
    -- Native tactical AI retains overall command. Take only legal visible ranged shots.
    local best,score
    if u:IsRanged() then
     R.Adjacent(u,function(v)
      if R.AtWar(s.pid,v:GetOwner()) and v:IsCombatUnit() and v:GetPlot():IsVisible(p:GetTeam()) and u:CanRangeStrikeAt(v:GetX(),v:GetY()) then
       local n=R.Base(v)+(v:GetDamage()>v:GetMaxHitPoints()*0.6 and 100 or 0)
       if not score or n>score then best={x=v:GetX(),y=v:GetY()};score=n end
      end
     end,math.min(3,u:Range()))
    end
    if best then u:PushMission(MissionTypes.MISSION_RANGE_ATTACK,best.x,best.y,0,0,0) end
   end
  end
 end
 if safeEmpire(s) then
  if R.SilverEligible(s) then
   for city in p:Cities() do
    if city:CanCreate(R.PROJECT) and city:GetProductionProject()~=R.PROJECT then city:PushOrder(OrderTypes.ORDER_CREATE,R.PROJECT,-1,0,true,false);break end
   end
  else
   for city in p:Cities() do
    if city:CanConstruct(R.PLATEAU) and city:GetProductionBuilding()~=R.PLATEAU then city:PushOrder(OrderTypes.ORDER_CONSTRUCT,R.PLATEAU,-1,0,true,false);break end
   end
  end
 end
end
