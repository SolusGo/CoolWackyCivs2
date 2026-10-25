local J=MapModData.JIN
local C,T,S=J.C,J.T,J.S
function J.War(a,b)
 return a~=b and Players[a] and Players[b] and Teams[Players[a]:GetTeam()]:IsAtWar(Players[b]:GetTeam())
end
function J.CombatTarget(id,u,postCombat)
 if not J.Alive(u) or not u:IsCombatUnit() or u:IsEmbarked() or not u:IsCanDefend() or (not postCombat and u:IsFighting()) then return false end
 local row=GameInfo.Units[u:GetUnitType()]
 return row and row.Domain=='DOMAIN_LAND' and J.War(id,u:GetOwner()) and u:GetPlot():IsVisible(Players[id]:GetTeam(),false) and not u:IsInvisible(Players[id]:GetTeam(),false)
end
function J.SpawnPlot(id,center,radius)
 for _,p in ipairs(J.Near(center,radius)) do
  local legal=not p:IsWater() and not p:IsMountain() and not p:IsImpassable() and (id==GameDefines.BARBARIAN_PLAYER or p:GetOwner()==id)
  local city=p:GetPlotCity();if city and city:GetOwner()~=id then legal=false end
  for i=0,p:GetNumUnits()-1 do local u=p:GetUnit(i);if u and (u:IsCombatUnit() or u:GetOwner()~=id) then legal=false end end
  if legal then return p end
 end
end
function J.Emissary(id,uid)
 local u=Players[id]:GetUnitByID(uid)
 return J.Alive(u) and u:GetUnitType()==J.Unit(id,'EMISSARY') and not u:IsEmbarked() and u:MovesLeft()>0 and u or nil
end
function J.TributeCheck(id,s,uid,minor)
 local u=J.Emissary(id,uid);local target=Players[minor];local cap=target and target:GetCapitalCity()
 if not u then return false,'Select a living Emissary with movement remaining.' end
 if not target or not target:IsMinorCiv() or not target:IsAlive() or not cap or J.War(id,minor) then return false,'Target City-State is ineligible or at war.' end
 if s.trib[minor] then return false,'Already a Jin Tributary.' end
 if cap:GetOriginalOwner()~=minor then return false,'City-State capital is not independent.' end
 if J.Distance(u:GetPlot(),cap:Plot())>1 then return false,'Emissary must stand beside the City-State capital.' end
 return true,'Establish Tributary: +2 capital Food, +3 Mounted Villager cap; trade bonus is +15% once.'
end
function J.Establish(id,s,uid,minor)
 local ok,why=J.TributeCheck(id,s,uid,minor);if not ok then return false,why end
 s.trib[minor]=J.CityRecord(Players[minor]:GetCapitalCity());s.serial=s.serial+1;J.Save(id,s)
 J.Emissary(id,uid):FinishMoves();J.Economy(id,s)
 return true,'Tributary established. The City-State remains independent.'
end
function J.BribeTarget(id,u)
 if not J.CombatTarget(id,u) or u:IsGreatPerson() then return nil end
 local row=GameInfo.Units[u:GetUnitType()];local cls=row and GameInfo.UnitClasses[row.Class]
 if not row or (row.Cost or 0)<=0 or J.Flag(row.Immobile) or J.Flag(row.Suicide) then return nil end
 if not cls or (cls.MaxGlobalInstances or -1)~=-1 or (cls.MaxPlayerInstances or -1)~=-1 or (cls.MaxTeamInstances or -1)~=-1 then return nil end
 if row.Special or row.LeaderPromotion or (row.LeaderExperience or 0)>0 or row.ProjectPrereq or row.SpaceshipProject then return nil end
 -- Unique heroes/custom classes without a conventional default are protected.
 local base=cls.DefaultUnit and GameInfo.Units[cls.DefaultUnit]
 if not base or (base.Combat or 0)<=0 or base.Domain~='DOMAIN_LAND' then return nil end
 return base.ID
end
function J.BribeCheck(id,s,uid,plotIndex)
 local u=J.Emissary(id,uid);local center=J.Plot(plotIndex)
 if not u or not center or J.Distance(u:GetPlot(),center)>C.bribeRange then return false,'Target must be within 2 plots of a mobile Emissary.' end
 if not J.War(GameDefines.BARBARIAN_PLAYER,id) then return false,'Barbarian rebels are not hostile to the Jin in this scenario.' end
 local cooldown=s.emissaryCooldown[uid]
 if cooldown and cooldown.born==u:GetGameTurnCreated() and J.Now()<cooldown.ready then return false,'Bribe on cooldown for '..(cooldown.ready-J.Now())..' turns.' end
 local candidates={}
 for _,p in ipairs(J.Near(center,1)) do for i=0,p:GetNumUnits()-1 do local enemy=p:GetUnit(i);local base=J.BribeTarget(id,enemy)
  if base and J.War(GameDefines.BARBARIAN_PLAYER,enemy:GetOwner()) then candidates[#candidates+1]={owner=enemy:GetOwner(),uid=enemy:GetID(),born=enemy:GetGameTurnCreated(),base=base,plot=J.Index(p),cost=J.Scale(C.bribeCost+math.max(0,GameInfo.Units[enemy:GetUnitType()].Cost or 0)*C.bribeProductionCost)} end
 end end
 if #candidates==0 then return false,'No eligible visible hostile land combatants. Civilians, heroes and limited units are protected.' end
 while #candidates>C.bribeTargets do table.remove(candidates) end
 local total=0;for _,v in ipairs(candidates) do total=total+v.cost end
 if Players[id]:GetGold()<total then return false,'Bribe requires up to '..total..' Gold for '..#candidates..' target(s).' end
 if not J.SpawnPlot(GameDefines.BARBARIAN_PLAYER,center,2) then return false,'No legal neutral rebel deployment plot.' end
 return true,'Bribe '..#candidates..' enemy unit(s) for up to '..total..' Gold; rebels attack both sides.',candidates
end
function J.Bribe(id,s,uid,plotIndex)
 local ok,why,targets=J.BribeCheck(id,s,uid,plotIndex);if not ok then return false,why end
 local barb=Players[GameDefines.BARBARIAN_PLAYER];local spawned,cost=0,0
 for _,r in ipairs(targets) do
  local enemy=Players[r.owner]:GetUnitByID(r.uid);local center=J.Plot(r.plot)
  local p=J.SpawnPlot(GameDefines.BARBARIAN_PLAYER,center,2)
  if J.Alive(enemy) and enemy:GetGameTurnCreated()==r.born and J.BribeTarget(id,enemy) and p then
   -- Never delete a target until its independent replacement is alive on legal land.
   local rebel=barb:InitUnit(r.base,p:GetX(),p:GetY())
   if J.Alive(rebel) then
    local ratio=math.max(1,enemy:GetMaxHitPoints()-enemy:GetDamage())/enemy:GetMaxHitPoints()
    rebel:SetDamage(math.min(rebel:GetMaxHitPoints()-1,math.floor(rebel:GetMaxHitPoints()*(1-ratio))))
    rebel:FinishMoves()
    s.rebels[rebel:GetID()]={born=rebel:GetGameTurnCreated(),expires=J.Now()+J.Scale(C.rebelLifetime)}
    spawned=spawned+1;cost=cost+r.cost
    -- Store replacement existence before the target's death callback can run.
    J.Save(id,s);enemy:Kill(false,GameDefines.BARBARIAN_PLAYER)
   end
  end
 end
 if spawned==0 then return false,'No replacements spawned; no Gold or cooldown spent.' end
 s.emissaryCooldown[uid]={born=J.Emissary(id,uid):GetGameTurnCreated(),ready=J.Now()+J.Scale(C.bribeCooldown)}
 s.serial=s.serial+1;J.Save(id,s);Players[id]:ChangeGold(-cost);J.Emissary(id,uid):FinishMoves()
 return true,spawned..' units rebelled. '..cost..' Gold paid; rebels are Barbarian, hostile to both armies.'
end
function J.CleanupRebels(id)
 local barb=Players[GameDefines.BARBARIAN_PLAYER]
 if not barb then return end
 for jin in pairs(J.civs) do
  local p=Players[jin];local s=p and S.Player(p)
  if s then for uid,r in pairs(s.rebels) do
   local u=barb:GetUnitByID(uid)
   if not J.Alive(u) or u:GetGameTurnCreated()~=r.born then s.rebels[uid]=nil
   elseif J.Now()>=r.expires then u:Kill(false,-1);s.rebels[uid]=nil end
  end;J.Save(jin,s) end
 end
end
function J.FreeEmissary(id,s)
 if not s.freeEmissary or J.Count(id,'EMISSARY')>=C.emissaryCap then return end
 local cap=Players[id]:GetCapitalCity()
 if not cap or not cap:CanPlaceUnitHere(J.Unit(id,'EMISSARY')) then return end
 local u=Players[id]:InitUnit(J.Unit(id,'EMISSARY'),cap:GetX(),cap:GetY())
 if J.Alive(u) then s.freeEmissary=false;J.Save(id,s);J.SyncUnit(id,u,s) end
end
function J.Emplacements(id,s)
 local out={};local dragon=J.Has(id,s,'DRAGON_PAVILION')
 for c in Players[id]:Cities() do
  local bastion=c:GetNumBuilding(J.Building('GREAT_WALL_BASTION'))>0
  if dragon or s.upgrades.MENGAN_EMPLACEMENT or bastion then
   local r=J.CityRecord(c);r.key='c'..r.plot;r.capacity=bastion and C.bastionCapacity or C.defenderCapacity;r.bastion=bastion
   out[r.key]=r
  end
 end
 if s.upgrades.MENGAN_EMPLACEMENT then for index in pairs(s.forts) do
  local p=J.Plot(index)
  if p and p:GetOwner()==id and not p:IsImprovementPillaged() and (p:GetImprovementType()==T.IMPROVEMENT_FORT or p:GetImprovementType()==T.IMPROVEMENT_CITADEL) then
   out['f'..index]={plot=index,key='f'..index,capacity=C.defenderCapacity,fort=true}
  else s.forts[index]=nil end
 end end
 return out
end
function J.RemoveDefender(id,s,uid)
 local r=s.defenders[uid];local u=Players[id]:GetUnitByID(uid)
 s.defenders[uid]=nil;J.Save(id,s)
 if r and J.Alive(u) and u:GetGameTurnCreated()==r.born then J.removing[id..':'..uid]=true;u:Kill(false,-1);J.removing[id..':'..uid]=nil end
end
function J.Defenders(id,s,respond)
 local parents=J.Emplacements(id,s);local counts={}
 for key in pairs(s.defense) do if not parents[key] then s.defense[key]=nil end end
 for uid,r in pairs(s.defenders) do
  local u=Players[id]:GetUnitByID(uid);local parent=parents[r.parent]
  if not parent or parent.founded~=r.founded or not J.Alive(u) or u:GetGameTurnCreated()~=r.born or J.Now()>=r.expires or J.Distance(u:GetPlot(),J.Plot(parent.plot))>C.defenderLeash then J.RemoveDefender(id,s,uid)
  else counts[r.parent]=(counts[r.parent] or 0)+1 end
 end
 if not respond then J.Save(id,s);return end
 local keys={};for key in pairs(parents) do keys[#keys+1]=key end;table.sort(keys)
 for _,key in ipairs(keys) do local parent=parents[key];local center=J.Plot(parent.plot)
  local state=s.defense[key] or {ready=0,shot=-1};s.defense[key]=state
  local threat
  for _,plot in ipairs(J.Near(center,C.defenseRadius)) do for i=0,plot:GetNumUnits()-1 do local u=plot:GetUnit(i);if not threat and J.CombatTarget(id,u) then threat=u end end end
  if threat then
   if (counts[key] or 0)<parent.capacity and J.Now()>=state.ready then
    local spawn=J.SpawnPlot(id,center,1)
    if spawn then
     local unitType=J.Unit(id,J.Tech(id,'TECH_CHEMISTRY') and 'GRENADIER' or 'DEFENDER')
     local unit=Players[id]:InitUnit(unitType,spawn:GetX(),spawn:GetY())
     if J.Alive(unit) then
      state.ready=J.Now()+J.Scale(C.defenderCooldown)
      s.defenders[unit:GetID()]={born=unit:GetGameTurnCreated(),parent=key,plot=parent.plot,founded=parent.founded,expires=J.Now()+J.Scale(C.defenderLifetime)}
      S.Write(unit,'JIN_D1',{owner=id,plot=parent.plot,expires=s.defenders[unit:GetID()].expires})
      counts[key]=(counts[key] or 0)+1;J.Save(id,s);J.SyncUnit(id,unit,s,true)
     end
    end
   end
   if (s.upgrades.BED_EMPLACEMENT or parent.bastion) and state.shot~=J.Now() then
    state.shot=J.Now();J.Save(id,s)
    J.Damage(id,threat,parent.bastion and C.bastionDamage or C.emplacementDamage)
   end
  end
 end
 J.Save(id,s)
end
function J.CanMoveInto(id,uid,x,y,attack,declareWar)
 local p=Players[id];local u=p and p:GetUnitByID(uid)
 local marker=u and S.Read(u,'JIN_D1')
 if not marker then return true end
 local target=Map.GetPlot(x,y);local home=J.Plot(marker.plot)
 return J.IsJin(id) and marker.owner==id and J.Now()<marker.expires and target and home and J.Distance(home,target)<=C.defenderLeash and not target:IsCity() or false
end
function J.Movement(id,uid,x,y)
 if not next(J.civs) then return end
 local u=Players[id] and Players[id]:GetUnitByID(uid);if not J.Alive(u) then return end
 if J.IsJin(id) and not J.busy[id] then local s=J.State(id);if s then J.SyncUnit(id,u,s);J.Defenders(id,s,false) end end
 local marker=S.Read(u,'JIN_D1')
 if marker and marker.owner~=id then u:Kill(false,-1);return end
 -- Only Jin cities/forts and tracked Groves are inspected, never the world map.
 for jin in pairs(J.civs) do if J.IsJin(jin) and not J.busy[jin] and J.War(jin,id) and u:IsCombatUnit() then
  local s=J.State(jin)
  if s then
   local close=false
   for _,r in pairs(J.Emplacements(jin,s)) do if J.Distance(u:GetPlot(),J.Plot(r.plot))<=C.defenseRadius then close=true;break end end
   if close then J.busy[jin]=true;J.Defenders(jin,s,true);J.busy[jin]=nil end
   local key=id..':'..uid..':'..u:GetGameTurnCreated()
   if s.slowed[key]~=J.Now() then for index in pairs(s.groves) do local grove=J.Plot(index)
    if grove and grove:GetOwner()==jin and grove:GetImprovementType()==T.IMPROVEMENT_JIN_GROVE and not grove:IsImprovementPillaged() and J.Distance(grove,u:GetPlot())<=C.groveSlowRadius then
     s.slowed[key]=J.Now();J.Save(jin,s);u:SetMoves(math.max(0,u:MovesLeft()-C.groveMoveCost));break
    end
   end end
  end
 end end
 J.Refresh()
end
function J.Karma(id,s)
 if not J.Has(id,s,'MOUNTAIN_HALL') then return end
 local centers={}
 for c in Players[id]:Cities() do if c:GetNumBuilding(J.Building('MOUNTAIN_HALL'))>0 or c:GetNumBuilding(J.Building('MONASTERY'))>0 then centers[#centers+1]=c end end
 local score,seen=0,{}
 for _,c in ipairs(centers) do for i=0,c:GetNumCityPlots()-1 do local p=c:GetCityIndexPlot(i)
  if p and not seen[J.Index(p)] and c:IsWorkingPlot(p) and J.Distance(c:Plot(),p)<=3 then
   seen[J.Index(p)]=true;score=score+C.karmaWorked+(p:GetResourceType(-1)~=-1 and C.karmaResource or 0)
  end
 end end
 for u in Players[id]:Units() do local row=GameInfo.Units[u:GetUnitType()]
  if row and (row.WorkRate or 0)>0 then for _,c in ipairs(centers) do if J.Distance(u:GetPlot(),c:Plot())<=3 then
   score=score+(u:GetUnitType()==J.Unit(id,'MOUNTED_VILLAGER') and C.karmaMounted or C.karmaWorker);break
  end end end
 end
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
 s.karma=math.min(C.karmaMax,s.karma+math.floor(score*100/(speed and speed.TrainPercent or 100)))
 if s.karma>=C.karmaMax and s.blessing<=J.Now() then s.karma=0;s.blessing=J.Now()+C.blessingDuration end
end
function J.Death(id,uid,unitType,x,y,delay,byPlayer)
 if not J.IsJin(id) or J.removing[id..':'..uid] then return end
 if J.conversions and J.conversions[id..':'..uid]==J.Now() then return end
 local s=J.State(id);if not s or not J.Has(id,s,'MOUNTAIN_HALL') then return end
 local u=Players[id]:GetUnitByID(uid)
 if not u then return end
 local key=uid..':'..u:GetGameTurnCreated()
 if s.deaths[key]==J.Now() then return end
 s.deaths[key]=J.Now();s.karma=math.max(0,s.karma-C.karmaDeath);J.Save(id,s)
end
function J.Groves(id,s)
 local count,localCounts=0,{}
 for index,r in pairs(s.groves) do local p=J.Plot(index);local c=J.City(id,r)
  if not p or p:GetOwner()~=id or p:GetImprovementType()~=T.IMPROVEMENT_JIN_GROVE or not c then s.groves[index]=nil
  else count=count+1;localCounts[r.plot]=(localCounts[r.plot] or 0)+1 end
 end
 if not J.Has(id,s,'PAGODA_FOREST') or count>=C.groveMax or J.Now()<s.groveReady then return end
 local cities={};for c in Players[id]:Cities() do cities[#cities+1]=c end
 table.sort(cities,function(a,b)return J.Index(a:Plot())<J.Index(b:Plot()) end)
 for _,c in ipairs(cities) do if (localCounts[J.Index(c:Plot())] or 0)<C.grovePerCity then
  for _,p in ipairs(J.Near(c:Plot(),3)) do if J.SiteLegal(id,p) then
   s.groves[J.Index(p)]=J.CityRecord(c);s.groveReady=J.Now()+J.Scale(C.groveInterval);J.Save(id,s)
   p:SetImprovementType(T.IMPROVEMENT_JIN_GROVE,id,false);return
  end end
 end end
end
function J.Damage(id,u,n,postCombat)
 if not J.CombatTarget(id,u,postCombat) or n<=0 then return end
 -- Secondary damage is deliberately nonlethal: avoids kill recursion/rewards and protected-unit death.
 local damage=math.min(math.floor(n),math.max(0,u:GetMaxHitPoints()-u:GetDamage()-1))
 if damage>0 then u:ChangeDamage(damage,id) end
end
function J.Combat(ap,au,attackerInflicted,attackerFinal,attackerHP,dp,du,defenderInflicted,defenderFinal,defenderHP,ip,iu,intercept,x,y)
 if not J.IsJin(ap) or J.combatBusy then return end
 local s=J.State(ap);local attacker=Players[ap]:GetUnitByID(au);local target=Map.GetPlot(x,y)
 if not s or not J.Alive(attacker) or not target or du<0 or not J.War(ap,dp) then return end
 local unitType=attacker:GetUnitType();local percent
 if unitType==J.Unit(ap,'IRON_PAGODA') then percent=C.ironSplashPercent
 elseif unitType==J.Unit(ap,'GRENADIER') then percent=C.grenadierSplashPercent
 elseif unitType==J.Unit(ap,'ERUPTOR') then percent=C.eruptorSplashPercent
 elseif unitType~=J.Unit(ap,'BED_CROSSBOW') then return end
 -- CP parameter 3 is damage inflicted BY the attacker, not its own damage received.
 if attackerInflicted<=0 then return end
 local key=table.concat({J.Now(),au,attacker:GetGameTurnCreated(),dp,du,attackerFinal,defenderFinal,x,y},':')
 s.combats=s.combats or {};if s.combats[key] then return end
 s.combats[key]=J.Now();for k,turn in pairs(s.combats) do if turn<J.Now() then s.combats[k]=nil end end
 J.Save(ap,s);J.combatBusy=true
 if not percent then
  local defender=Players[dp] and Players[dp]:GetUnitByID(du)
  J.Damage(ap,defender,attackerInflicted*C.bedSecondPercent/100,true)
 else
  if s.upgrades.HEAVEN_THUNDER and (unitType==J.Unit(ap,'ERUPTOR') or unitType==J.Unit(ap,'GRENADIER')) then percent=percent*C.thunderPercent/100 end
  local victims={}
  for _,p in ipairs(J.Near(target,1)) do if J.Index(p)~=J.Index(target) then
   for i=0,p:GetNumUnits()-1 do local u=p:GetUnit(i);if J.CombatTarget(ap,u) then victims[#victims+1]={owner=u:GetOwner(),id=u:GetID()} end end
  end end
  for i=1,math.min(C.splashTargets,#victims) do local r=victims[i];J.Damage(ap,Players[r.owner]:GetUnitByID(r.id),attackerInflicted*percent/100) end
 end
 J.combatBusy=false;J.Refresh()
end
