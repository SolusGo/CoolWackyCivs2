local R=MapModData.RED_Legend
function R.SilverEligible(s)
 if s.silver.phase~='READY' or Players[s.pid]:GetCurrentEra()<GameInfoTypes.ERA_MODERN then return false end
 local count,legend=0,false
 for _,r in ipairs(R.Team(s)) do if R.Unit(s,r.serial) then count=count+1;legend=legend or R.Rank(r)==4 end end
 return count>=4 and legend
end
function R.BeginSilver(s)
 if not R.SilverEligible(s) then return false end
 local silver=s.silver;silver.phase='ABSENT';silver.started=Game.GetGameTurn();silver.due=silver.started+R.Turns(8);silver.snapshots={}
 local toRemove={}
 for _,r in ipairs(R.Team(s)) do local u=R.Unit(s,r.serial)
  if u then
   silver.snapshots[r.serial]=R.Snapshot(u);toRemove[#toRemove+1]=u;r.withdrawn=true
  end
 end
 -- Entire party is recoverable BEFORE the first removal.
 R.Save(s);R.internal=R.internal+1
 for _,u in ipairs(toRemove) do u:Kill(false,-1) end
 R.internal=R.internal-1
 R.Yields(s);R.Changed(s);R.Notify(s.pid,'VANISHED');return true
end
local function roleScore(u,name)
 local info=GameInfo.Units[u:GetUnitType()];local cls=info.CombatClass or '';local sea=info.Domain=='DOMAIN_SEA';local ranged=(info.RangedCombat or 0)>0
 if name=='PIKACHU' then return (info.Moves or 2)*25+(cls=='UNITCOMBAT_MOUNTED' and 45 or 0) end
 if name=='CHARIZARD' then return (ranged and not sea and 180 or 0)+(info.Moves or 2)*15 end
 if name=='BLASTOISE' then return ((cls=='UNITCOMBAT_GUN' or cls=='UNITCOMBAT_ARMOR') and 180 or 0)+(info.Combat or 0) end
 if name=='VENUSAUR' then return ((cls=='UNITCOMBAT_GUN' or cls=='UNITCOMBAT_MELEE') and 150 or 0)+(not ranged and 40 or 0) end
 if name=='SNORLAX' then return (not ranged and not sea and 100 or 0)+(info.Combat or 0)*2 end
 if name=='LAPRAS' then return (sea and 500 or 0)+(u:IsHasPromotion(GameInfoTypes.PROMOTION_AMPHIBIOUS) and 160 or 0)+(ranged and 20 or 0) end
 return 0
end
function R.IdentityPlan(s,party)
 -- Maximum-weight one-to-one assignment, at most 720 leaves for six partners.
 table.sort(party,function(a,b)return a.serial<b.serial end)
 local best,bestScore,used,plan={},-1,{},{}
 local function solve(i,score)
  if i>#party then
   if score>bestScore then bestScore=score;best={};for n,name in pairs(plan) do best[n]=name end end
   return
  end
  local r=party[i];local u=R.Unit(s,r.serial)
  for _,name in ipairs(R.Names) do if not used[name] then used[name]=true;plan[r.serial]=name;solve(i+1,score+roleScore(u,name));used[name]=nil end end
 end
 solve(1,0);return best
end
function R.AssignIdentity(s,r,u)
 if r.identity then return end
 local best,score
 for _,name in ipairs(R.Names) do if not s.identities[name] then
  local n=roleScore(u,name);if not score or n>score then best=name;score=n end
 end end
 if best then r.identity=best;s.identities[best]=r.serial;u:SetName(best:sub(1,1)..best:sub(2):lower()) end
end
function R.AdvancedType(pid,base)
 local p=Players[pid];local queue={base};local seen={[base]=true};local best=base;local bestScore=-1
 for i=1,100 do
  local typ=queue[i];if not typ then break end
  local info=GameInfo.Units[typ]
  if typ==base or p:CanTrain(info.ID,false,false,true) then
   local score=math.max(info.Combat or 0,info.RangedCombat or 0)*100+(info.Cost or 0)
   if score>bestScore then best=typ;bestScore=score end
  end
  -- Obsolete intermediate units cannot be trained, but do not break upgrade lineage.
  for up in GameInfo.Unit_ClassUpgrades{UnitType=typ} do
   local cls=GameInfo.UnitClasses[up.UnitClassType];local nextType=cls and cls.DefaultUnit
   for override in GameInfo.Civilization_UnitClassOverrides{CivilizationType=R.CIV,UnitClassType=up.UnitClassType} do nextType=override.UnitType end
   if nextType and not seen[nextType] and GameInfo.Units[nextType].Domain==info.Domain then seen[nextType]=true;queue[#queue+1]=nextType end
  end
 end
 return best
end
function R.ResumeSilver(s)
 local silver=s.silver
 if silver.phase~='ABSENT' and silver.phase~='RETURNING' then return end
 local p=Players[s.pid]
 if not p:IsAlive() then silver.phase='ELIMINATED';R.Yields(s);R.Save(s);return end
 -- Recovery of a save taken during withdrawal: retire any still-present originals.
 if silver.phase=='ABSENT' then
  R.internal=R.internal+1
  for u in p:Units() do local n=R.Serial(u);local r=n and s.units[n]
   if r and r.withdrawn and silver.snapshots[n] then u:Kill(false,-1) end
  end
  R.internal=R.internal-1
  if Game.GetGameTurn()<silver.due then return end
  silver.phase='RETURNING';R.Save(s);R.Yields(s)
 end
 local home=p:GetCapitalCity()
 if not home then for city in p:Cities() do if not home or city:GetID()<home:GetID() then home=city end end end
 if not home then return end -- never recreate a defeated civilization
 local pending=false
 for _,r in ipairs(R.Team(s)) do local snap=silver.snapshots[r.serial]
  if snap and r.withdrawn then
   local typ=R.AdvancedType(s.pid,snap.unitType);local id=GameInfoTypes[typ]
   local plot=R.SpawnPlot(s.pid,id,home:GetX(),home:GetY())
   if plot then
    R.internal=R.internal+1
    local u=p:InitUnit(id,plot:GetX(),plot:GetY(),snap.unitAI or -1,snap.facing or -1,false)
    if u then
     r.promotionExpiry=R.Restore(u,snap);R.Tag(u,r.serial);r.id=u:GetID();r.withdrawn=nil;r.training=math.max(100,r.training);r.summit=true
     r.lineage[#r.lineage+1]=snap.unitType;r.unitType=typ;R.Apply(u,r)
     -- Original damage is preserved; no hidden full heal is added to transformation.
    else pending=true end
    R.internal=R.internal-1;R.Save(s)
   else pending=true end
  end
 end
 if pending then R.Changed(s);return end
 local party=R.Team(s);local plan=R.IdentityPlan(s,party)
 for _,r in ipairs(party) do local u=R.Unit(s,r.serial)
  if u then r.identity=plan[r.serial];s.identities[r.identity]=r.serial;u:SetName(r.identity:sub(1,1)..r.identity:sub(2):lower());R.Apply(u,r) end
 end
 silver.phase='RETURNED';silver.finished=Game.GetGameTurn()
 R.Yields(s);R.Changed(s);R.Notify(s.pid,'RETURN','RETURN_TITLE')
end
