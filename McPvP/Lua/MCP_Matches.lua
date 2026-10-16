local M=MapModData.MCPVP
function M.FeastPlot(s) return s.feast and Map.GetPlotByIndex(s.feast.plot) end
function M.ValidFeast(plot)
 return plot and not plot:IsCity() and not plot:IsWater() and not plot:IsMountain() and not plot:IsImpassable()
end
function M.ChooseFeast(s)
 local p=Players[s.pid];local cap=p:GetCapitalCity();if not cap then return end
 local best,bestScore
 -- Bounded preparation searches only, never UI polling. Same area avoids islands.
 for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
  if M.ValidFeast(plot) and plot:GetArea()==cap:Plot():GetArea() and plot:IsRevealed(p:GetTeam()) then
   local d=M.Distance(plot,cap);local owner=plot:GetOwner()
   local reserved=false
   for otherID,other in pairs(M.states) do local f=other.feast
    if otherID~=s.pid and f and f.plot==i and f.status~='EXPIRED' and f.status~='CLAIMED' then reserved=true;break end
   end
   if not reserved and d>=4 and d<=16 and (owner<0 or owner==s.pid or M.AtWar(s.pid,owner)) then
    local exits=0;for dir=0,5 do if M.ValidFeast(Map.PlotDirection(plot:GetX(),plot:GetY(),dir)) then exits=exits+1 end end
    if exits>=3 then
     local nearest=30
     for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local other=Players[pid]
      if pid~=s.pid and other and other:IsAlive() and not other:IsBarbarian() and not other:IsMinorCiv() then
       for city in other:Cities() do if city:Plot():GetArea()==plot:GetArea() then nearest=math.min(nearest,M.Distance(city,plot)) end end
      end
     end
     local score=exits*3-math.abs(d-8)*2-math.abs(nearest-d)+((i+s.cycle*17+s.pid*7)%19)/19
     if not bestScore or score>bestScore then best,bestScore=plot,score end
    end
   end
  end
 end
 return best
end
function M.StartMatch(s)
 s.cycle=s.cycle+1;s.mode=s.queued or 'HG';s.start=M.Turn();s.finish=s.start+M.Turns(20)
 s.raids={};s.sabotaged={};s.killLedger={};s.kills=0;s.killLegacy=0;s.nearLegacy=0;s.captures=0;s.missions=0;s.earned=0;s.feast=nil;s.feastPending=false
 if s.mode=='HG' then local plot=M.ChooseFeast(s)
  if plot then s.feast={plot=plot:GetPlotIndex(),active=s.start+M.Turns(10),expires=s.start+M.Turns(15),status='PREPARING'}
  else
   -- Turn-zero starts normally precede the first city. Allow early exploration
   -- before abandoning the objective; never announce with insufficient lead time.
   s.feastPending=true;s.feastSearch=s.start+M.Turns(3)
   M.Notify(s.pid,'Feast preparations await an accessible explored site. Found your capital and explore beyond spawn.')
  end
  for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[pid]
   if p and p:IsAlive() and (pid==s.pid or Teams[p:GetTeam()]:IsHasMet(Players[s.pid]:GetTeam())) then M.Notify(pid,'McPvP has opened a Hardcore Games match. A contested Feast will be announced.') end
  end
 end
 M.Notify(s.pid,M.Text(s.mode)..' begins. Next match in '..M.Turns(20)..' turns.')
 M.Save(s)
end
function M.DropFlag(s,r,u,reason)
 if not r.flag then return end
 r.flag=nil;if u then M.Promo(u,'FLAG',false) end
 M.Notify(s.pid,reason or 'The flag was lost. That city has already been raided this match.');M.Save(s)
end
function M.EndMatch(s)
 local won=(s.mode=='HG' and s.feast and s.feast.claimant==s.pid) or (s.mode=='CTF' and s.captures>0) or (s.mode=='SAB' and s.missions>0)
 if won then s.wins[s.mode]=s.wins[s.mode]+1;M.Legacy(s,10) end
 s.completed=s.completed+1
 s.summary=M.Text(s.mode)..': '..(won and 'VICTORY' or 'MATCH COMPLETE')..'. Kills: '..s.kills..'; flags: '..s.captures..'; missions: '..s.missions..'; Feast: '..(s.feast and s.feast.claimant==s.pid and 'secured' or 'not secured')..'; Legacy: '..s.earned..'.'
 M.Notify(s.pid,s.summary)
 for _,r in pairs(s.units) do local u=M.Unit(s,r)
  M.DropFlag(s,r,u,'The match ended; the carried flag has returned to its city.')
  if r.mission then r.mission=nil;M.Notify(s.pid,'Infiltration interrupted: the match ended.') end
 end
 M.Save(s)
 if not Players[s.pid]:IsHuman() then s.queued=M.AIMode(s) end
 M.StartMatch(s)
end
function M.ClaimFeast(s,u)
 local f=s.feast;local plot=M.FeastPlot(s)
 if not f or f.status~='ACTIVE' or M.Turn()>=f.expires or not M.ValidFeast(plot) or not M.Land(u) or u:GetPlot()~=plot then return false end
 local owner=u:GetOwner();local p=Players[owner]
 if not p or p:IsBarbarian() then return false end
 -- Commit the claim before native yield/XP calls can reenter Lua.
 f.status='CLAIMED';f.claimant=owner;M.Save(s)
 p:ChangeGold(M.Reward(owner,75));u:ChangeExperience(20,-1,0,0,0)
 u:SetDamage(math.max(0,u:GetDamage()-25))
 if owner==s.pid then M.Legacy(s,15) end
 M.Notify(s.pid,'The Feast was secured by '..p:GetCivilizationShortDescription()..'.',nil,plot)
 if owner~=s.pid then M.Notify(owner,'Your unit secured the McPvP Feast: Gold, 20 XP and 25 HP restored.',nil,plot) end
 M.Changed(s);return true
end
function M.UpdateFeast(s)
 if s.mode~='HG' then return end
 local f=s.feast;local now=M.Turn()
 if not f and s.feastPending then
  local deadline=s.start+M.Turns(10)-M.Turns(3)
  if now>deadline then s.feastPending=false;M.Notify(s.pid,'No accessible Feast site this match. Final Battle XP and kill objectives remain.');M.Save(s)
  elseif now>=(s.feastSearch or deadline) then
   local plot=M.ChooseFeast(s)
   if plot then
    s.feast={plot=plot:GetPlotIndex(),active=s.start+M.Turns(10),expires=s.start+M.Turns(15),status='PREPARING'}
    s.feastPending=false;f=s.feast
   elseif now==deadline then s.feastPending=false;M.Notify(s.pid,'No accessible Feast site this match. Final Battle XP and kill objectives remain.')
   else s.feastSearch=math.min(deadline,now+M.Turns(4)) end
   M.Save(s)
  end
 end
 if not f then return end
 if f.status=='CLAIMED' or f.status=='EXPIRED' then return end
 if not Players[s.pid]:IsAlive() then f.status='EXPIRED';M.Save(s);return end
 local plot=M.FeastPlot(s)
 if not M.ValidFeast(plot) then f.status='EXPIRED';M.Save(s);return end
 local changed=false
 if not f.announced and now>=f.active-M.Turns(3) then
  f.announced=true
  changed=true
  for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[pid]
   if p and p:IsAlive() and (pid==s.pid or Teams[p:GetTeam()]:IsHasMet(Players[s.pid]:GetTeam())) then
    M.Notify(pid,'Feast at ('..plot:GetX()..', '..plot:GetY()..') activates in '..math.max(0,f.active-now)..' turns. Any non-barbarian land military unit can claim it.',nil,plot)
   end
  end
 end
 if now>=f.expires then f.status='EXPIRED';changed=true;M.Notify(s.pid,'The unclaimed Feast has expired.',nil,plot)
 elseif now>=f.active and f.status=='PREPARING' then f.status='ACTIVE';changed=true;M.Notify(s.pid,'The Feast is active. Secure its tile!',nil,plot) end
 if f.status=='ACTIVE' then
  -- Existing occupants are checked in native plot order; movement claims are deferred.
  for i=0,plot:GetNumUnits()-1 do if M.ClaimFeast(s,plot:GetUnit(i)) then break end end
 end
 if changed then M.Save(s) end
end
function M.FlagCity(flag) return M.City(flag) end
function M.ReturnCity(pid,plot)
 if not plot or plot:IsWater() or plot:GetOwner()~=pid then return end
 local city=plot:GetPlotCity() or plot:GetWorkingCity()
 if city and city:GetOwner()==pid and not city:IsRazing() then return city end
end
function M.EnemyCities(s,u,range)
 local out={};if not M.Land(u) then return out end
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[pid]
  if p and p:IsAlive() and not p:IsBarbarian() and M.AtWar(s.pid,pid) then
   for city in p:Cities() do if not city:IsRazing() and M.Distance(u,city)<=range and city:Plot():IsVisible(Players[s.pid]:GetTeam()) then out[#out+1]=city end end
  end
 end
 table.sort(out,function(a,b) return M.CityKey(a)<M.CityKey(b) end);return out
end
function M.Recon(u,r)
 local info=GameInfo.Units[u:GetUnitType()]
 return M.Land(u) and (r.veteran or info.CombatClass=='UNITCOMBAT_RECON' or info.Class=='UNITCLASS_SCOUT')
end
function M.ObjectiveTargets(s,u,kind)
 local out={};local r=M.Peek(s,u)
 if not r or not M.Land(u) or u:MovesLeft()<=0 or r.flag or r.mission then return out end
 if kind=='STEAL' and s.mode=='CTF' then
  for _,city in ipairs(M.EnemyCities(s,u,1)) do if not s.raids[M.CityKey(city)] then out[#out+1]=M.CityRef(city) end end
 elseif kind=='INFILTRATE' and s.mode=='SAB' and M.Recon(u,r) then
  for _,city in ipairs(M.EnemyCities(s,u,2)) do local key=M.CityKey(city);local busy=false
   for _,other in pairs(s.units) do if other.mission and other.mission.target.key==key then busy=true end end
   if not s.sabotaged[key] and not busy then out[#out+1]=M.CityRef(city) end
  end
 end
 return out
end
function M.Objective(s,u,kind,target)
 local r=M.Peek(s,u);if not r or not M.Land(u) or u:MovesLeft()<=0 then return false end
 if kind=='RETURN' then
  if not r.flag or s.mode~='CTF' or not M.FlagCity(r.flag) or not M.AtWar(s.pid,r.flag.owner) or not M.ReturnCity(s.pid,u:GetPlot()) then return false end
  r.flag=nil;s.captures=s.captures+1;M.Promo(u,'FLAG',false);u:SetMoves(0);M.Legacy(s,25)
  local p=Players[s.pid];p:ChangeJONSCulture(M.Reward(s.pid,40,'CULTURE'));p:ChangeGoldenAgeProgressMeter(M.Reward(s.pid,50,'CULTURE'));u:ChangeExperience(15,-1,0,0,0)
  M.Notify(s.pid,'Flag returned! +25 Server Legacy, Culture, Golden Age Points and 15 XP.');M.Changed(s);return true
 end
 for _,ref in ipairs(M.ObjectiveTargets(s,u,kind)) do if target and ref.key==target.key and ref.owner==target.owner then
  if kind=='STEAL' then s.raids[ref.key]=true;r.flag=ref;M.Apply(s,u,r)
   M.Notify(ref.owner,'McPvP stole a flag from '..M.City(ref):GetName()..'. Defeat the carrier to recover it.',nil,u:GetPlot())
   M.Notify(s.pid,'Flag stolen. Return to land belonging to one of your cities and use Return flag.')
  else r.mission={target=ref,started=M.Turn(),finish=M.Turn()+M.Turns(3)};M.Notify(s.pid,'Infiltration initiated. Stay within two tiles until completion.',nil,u:GetPlot()) end
  u:SetMoves(0);M.Changed(s);return true
 end end
 return false
end
function M.UpdateMissions(s)
 for _,r in pairs(s.units) do local mission=r.mission
  if mission then local u=M.Unit(s,r);local city=M.City(mission.target)
   if s.mode~='SAB' or not M.Land(u) or not city or not M.AtWar(s.pid,mission.target.owner) or M.Distance(u,city)>2 or not city:Plot():IsVisible(Players[s.pid]:GetTeam()) then
    r.mission=nil;M.Notify(s.pid,'Infiltration interrupted: unit, target, visibility or operational area became invalid.')
   elseif M.Turn()>=mission.finish then
    local ref=mission.target;r.mission=nil
    if not s.sabotaged[ref.key] then
     s.sabotaged[ref.key]=true;s.missions=s.missions+1
     s.debuffs[ref.key]={target=ref,expires=M.Turn()+M.Turns(5)}
     city:SetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE,1,true)
     M.Legacy(s,20);u:ChangeExperience(15,-1,0,0,0);Players[s.pid]:ChangeGold(M.Reward(s.pid,25))
     M.Notify(s.pid,'Sabotage successful! +20 Legacy, 15 XP and Gold.',nil,city:Plot())
     M.Notify(ref.owner,city:GetName()..' sabotaged: -20% Production and -15% Gold for '..M.Turns(5)..' turns.',nil,city:Plot())
    end
   elseif not mission.warned and M.Turn()>mission.started then
    mission.warned=true;M.Notify(mission.target.owner,'Suspicious activity near '..city:GetName()..'. Eliminate the marked infiltrator before the mission completes.',nil,u:GetPlot())
   end
  end
 end
 M.Save(s)
end
function M.Debuffs()
 local active={};local now=M.Turn()
 for _,s in pairs(M.states) do for key,d in pairs(s.debuffs) do local city=M.City(d.target)
  if now>=d.expires or not city or not Players[s.pid]:IsAlive() then
   s.debuffs[key]=nil
   if city then M.Notify(d.target.owner,'Sabotage effects expired in '..city:GetName()..'.',nil,city:Plot()) end
  else active[key]=true;city:SetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE,1,true) end
 end;M.Save(s) end
 -- Only cities with our dummy are touched; overlapping attackers never stack it.
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[pid]
  if p then for city in p:Cities() do
   if city:GetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE)>0 and not active[M.CityKey(city)] then city:SetNumRealBuilding(GameInfoTypes.BUILDING_MCPVP_SABOTAGE,0,true) end
  end end
 end
end
function M.KillReward(s,victim,plot)
 if s.mode~='HG' or M.Turn()<s.start+M.Turns(10) or M.Turn()>=s.finish then return end
 local enemy=Players[victim.pid];local info=GameInfo.Units[victim.typ]
 if not enemy or enemy:IsBarbarian() or enemy:IsMinorCiv() or not M.AtWar(s.pid,victim.pid) or not info or info.Cost<=0 or victim.temporary then return end
 s.kills=s.kills+1
 if s.killLegacy<15 then s.killLegacy=s.killLegacy+3;M.Legacy(s,3) end
 local f=s.feast;local site=M.FeastPlot(s)
 if f and f.status=='ACTIVE' and site and plot and M.Distance(site,plot)<=2 and s.nearLegacy<10 then s.nearLegacy=10;M.Legacy(s,10) end
 M.Changed(s)
end
