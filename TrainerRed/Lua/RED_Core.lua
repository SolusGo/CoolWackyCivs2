-- The UI addin creates ONE simulation owner. No UI render invokes these mutations.
MapModData.RED_Legend={States={},Index={},busy=false,internal=0,healGuard={}}
local R=MapModData.RED_Legend
R.CIV=GameInfoTypes.CIVILIZATION_RED_INDIGO_CHAMPION
R.CENTER=GameInfoTypes.BUILDING_RED_POKEMON_CENTER
R.PLATEAU=GameInfoTypes.BUILDING_RED_INDIGO_PLATEAU
R.ACE=GameInfoTypes.UNIT_RED_POKEMON_ACE
R.PROJECT=GameInfoTypes.PROJECT_RED_MT_SILVER
R.Names={'PIKACHU','CHARIZARD','BLASTOISE','VENUSAUR','SNORLAX','LAPRAS'}
R.Ranks={'CAUGHT','TRAINED','PROVEN','CHAMPION','LEGENDARY'}
R.Speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
R.Percent=R.Speed.TrainPercent or 100
function R.Turns(n) return math.max(1,math.floor(n*R.Percent/100+0.5)) end
function R.IsRed(pid) local p=Players[pid];return p and p:GetCivilizationType()==R.CIV end
function R.Eligible(u) return u and u:IsCombatUnit() end
function R.Promo(name) return GameInfoTypes['PROMOTION_RED_'..name] end
function R.Set(u,name,on)
 local id=R.Promo(name);if id and u:IsHasPromotion(id)~=on then u:SetHasPromotion(id,on) end
end
function R.Base(u) return u and math.max(u:GetBaseCombatStrength(),u:GetBaseRangedCombatStrength()) or 0 end
function R.Alive(u) return u and not u:IsDead() and not u:IsDelayedDeath() end
function R.AtWar(a,b) return a~=b and Teams[Players[a]:GetTeam()]:IsAtWar(Players[b]:GetTeam()) end
function R.Distance(a,b) return Map.PlotDistance(a:GetX(),a:GetY(),b:GetX(),b:GetY()) end
function R.Notify(pid,key,title)
 local p=Players[pid];if p:IsHuman() then p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,Locale.ConvertTextKey('TXT_KEY_RED_'..key),Locale.ConvertTextKey('TXT_KEY_RED_'..(title or 'TRAIT'))) end
end
function R.Changed(s)
 R.Save(s);if LuaEvents.RED_TeamChanged then LuaEvents.RED_TeamChanged(s.pid) end
end
function R.Heal(u,amount)
 if not R.Alive(u) or amount<=0 or u:GetDamage()<=0 then return end
 local r=R.IsRed(u:GetOwner()) and R.Record(u)
 if r and R.Rank(r)==2 then amount=amount+5 end
 local key=u:GetOwner()..':'..u:GetID();R.healGuard[key]=true
 u:SetDamage(math.max(0,u:GetDamage()-amount));R.healGuard[key]=nil
 if r then r.lastDamage=u:GetDamage() end
end
function R.Capacity(s)
 if s.full then return 6 end
 local era=Players[s.pid]:GetCurrentEra()
 if era>=GameInfoTypes.ERA_MEDIEVAL then return 4 elseif era>=GameInfoTypes.ERA_CLASSICAL then return 3 end
 return 2
end
function R.Team(s)
 local out={};for i=1,6 do local n=s.slots[i];local r=n and s.units[n];if r and not r.dead then out[#out+1]=r end end
 return out
end
function R.Slot(s,serial) for i=1,6 do if s.slots[i]==serial then return i end end end
function R.Assign(s,u,slot)
 local r=R.Record(u)
 if not r or u:GetDomainType()==DomainTypes.DOMAIN_AIR or R.Slot(s,r.serial) or R.Rank(r)<3 or (s.silver.phase~='READY' and s.silver.phase~='RETURNED') or slot<1 or slot>R.Capacity(s) or s.slots[slot] then return false end
 s.slots[slot]=r.serial;r.slot=slot
 if s.silver.phase=='RETURNED' and R.AssignIdentity then R.AssignIdentity(s,r,u) end
 R.Apply(u,r);R.Yields(s);R.Changed(s);return true
end
function R.AutoAssign(s)
 if s.manual and Players[s.pid]:IsHuman() then return end
 if s.silver.phase=='ABSENT' or s.silver.phase=='RETURNING' then return end
 local candidates={}
 for u in Players[s.pid]:Units() do local r=R.Record(u);if r and u:GetDomainType()~=DomainTypes.DOMAIN_AIR and not r.slot and R.Rank(r)>=3 then candidates[#candidates+1]={u=u,r=r} end end
 -- First eligible veteran wins. AI role balance only breaks same-training ties.
 table.sort(candidates,function(a,b)
  local as=not Players[s.pid]:IsHuman() and R.RosterScore and R.RosterScore(s,a.u,a.r) or a.r.training
  local bs=not Players[s.pid]:IsHuman() and R.RosterScore and R.RosterScore(s,b.u,b.r) or b.r.training
  if as~=bs then return as>bs end return a.r.serial<b.r.serial
 end)
 for _,c in ipairs(candidates) do for i=1,R.Capacity(s) do if not s.slots[i] then R.Assign(s,c.u,i);break end end end
end
function R.Release(s,serial)
 local r=s.units[serial];local u=R.Unit(s,serial)
 if not r or not r.slot or not u or (s.silver.phase~='READY' and s.silver.phase~='RETURNED') then return false end
 s.manual=true;s.slots[r.slot]=nil;r.slot=nil
 R.Apply(u,r);R.Yields(s);R.Changed(s);return true
end
local function bits(city,name,value,n)
 for bit=0,n-1 do local id=GameInfoTypes['BUILDING_RED_'..name..'_'..bit];local x=math.floor(value/2^bit)%2
  if city:GetNumRealBuilding(id)~=x then city:SetNumRealBuilding(id,x,true) end
 end
end
function R.Yields(s)
 local p=Players[s.pid];local plateau;local rank=0
 for city in p:Cities() do if city:GetNumBuilding(R.PLATEAU)>0 then plateau=city;break end end
 if plateau then for _,r in ipairs(R.Team(s)) do if not r.withdrawn then rank=rank+R.Rank(r) end end end
 local cap=p:GetCapitalCity()
 for city in p:Cities() do
  bits(city,'RANK',cap and city:GetID()==cap:GetID() and rank or 0,5)
  bits(city,'HALL',plateau and city:GetID()==plateau:GetID() and math.min(5,s.hall) or 0,3)
  bits(city,'ABSENCE',s.silver.phase=='ABSENT' and 1 or 0,1)
 end
end
function R.National(s)
 if s.full then return end
 for city in Players[s.pid]:Cities() do
  for b in GameInfo.Buildings() do
   if city:GetNumBuilding(b.ID)>0 then local cls=GameInfo.BuildingClasses[b.BuildingClass]
    if b.ID==R.PLATEAU or (cls and cls.MaxPlayerInstances==1 and cls.MaxGlobalInstances==-1 and cls.MaxTeamInstances==-1 and (not b.IsDummy or b.IsDummy==0)) then s.full=true;return end
   end
  end
 end
end
function R.Reconcile(s)
 local seen={};R.Index[s.pid]={}
 for u in Players[s.pid]:Units() do
  if R.Eligible(u) and R.Alive(u) then
   local r=R.Record(u)
   if seen[r.serial] then
    R.Tag(u,s.nextSerial);r={serial=s.nextSerial,training=0,ribbons=0,lineage={},itemReady=0,withdrawReady=0};s.nextSerial=s.nextSerial+1;s.units[r.serial]=r
   end
   seen[r.serial]=true;r.id=u:GetID();R.Apply(u,r)
  end
 end
 for n,r in pairs(s.units) do
  if not seen[n] and not r.withdrawn and not r.dead then R.RescueAce(s,r);r.dead=true;r.id=nil
   if r.slot then s.slots[r.slot]=nil;r.slot=nil end
  end
 end
 local used={}
 for i=1,6 do local n=s.slots[i];local r=n and s.units[n]
  if n and (used[n] or not r or r.dead) then s.slots[i]=nil else if r then r.slot=i;used[n]=true end end
 end
 R.National(s);R.Yields(s);R.Save(s)
end
-- Deterministic full-map search ONLY for return/detach, never once per unit per turn.
function R.SpawnPlot(pid,typ,x,y,ignore)
 local info=GameInfo.Units[typ];if not info then return end
 local candidates={}
 for i=0,Map.GetNumPlots()-1 do
  local p=Map.GetPlotByIndex(i)
  if p:GetOwner()==pid and not p:IsImpassable() and not p:IsMountain() and not p:IsVisibleEnemyUnit(pid)
   and ((info.Domain=='DOMAIN_SEA' and p:IsWater()) or (info.Domain=='DOMAIN_LAND' and not p:IsWater())) then
   local occupied=false
   for j=0,p:GetNumUnits()-1 do local v=p:GetUnit(j)
    if v~=ignore and ((info.Combat>0 or info.RangedCombat>0)==v:IsCombatUnit()) then occupied=true end
   end
   if not occupied then candidates[#candidates+1]={plot=p,d=Map.PlotDistance(x,y,p:GetX(),p:GetY()),i=i} end
  end
 end
 table.sort(candidates,function(a,b) if a.d~=b.d then return a.d<b.d end return a.i<b.i end)
 return candidates[1] and candidates[1].plot
end
function R.Hook(events,name,fn) if events[name] and events[name].Add then events[name].Add(fn) end end

include('RED_SaveData');include('RED_Training');include('RED_PokemonAce');include('RED_PokemonAbilities');include('RED_MtSilver');include('RED_Combat');include('RED_AI');include('RED_Events')
