include('JIN_Config')
include('JIN_State')
local old=MapModData.JIN
if old and old.context==ContextPtr and old.active then return end
if old then
 old.active=false
 if old.context.ClearUpdate then old.context:ClearUpdate() end
 for _,h in ipairs(old.handlers or {}) do h.event.Remove(h.fn) end
end
local J={active=true,context=ContextPtr,handlers={},busy={},removing={},civs={}}
MapModData.JIN=J
local C,T,S=JINConfig,GameInfoTypes,JINState
J.C,J.T,J.S=C,T,S
J.CIV=T.CIVILIZATION_JIN_DYNASTY
function J.IsJin(id)
 local p=Players[id];return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType()==J.CIV
end
function J.Now() return Game.GetGameTurn() end
function J.State(id)
 if not J.IsJin(id) then return nil end
 local s,reason=S.Player(Players[id])
 if not s and J.ClearInvalid then J.ClearInvalid(id,reason) end
 return s
end
function J.Save(id,s) S.Write(Players[id],'JIN_P1',s) end
function J.ID(kind,key) return T[kind..'_JIN_'..key] end
function J.Flag(v) return v==true or (type(v)=='number' and v~=0) end
function J.Unit(id,key) return J.ID('UNIT',key) end
function J.Building(key) return J.ID('BUILDING',key) end
function J.Promotion(key) return J.ID('PROMOTION',key) end
function J.Plot(index) return index and index>=0 and Map.GetPlotByIndex(index) or nil end
function J.Index(plot) return plot:GetPlotIndex() end
function J.Distance(a,b) return Map.PlotDistance(a:GetX(),a:GetY(),b:GetX(),b:GetY()) end
function J.Scale(n)
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
 return math.max(1,math.floor(n*(speed and speed.TrainPercent or 100)/100+0.5))
end
function J.Tech(id,key) return not key or Teams[Players[id]:GetTeam()]:IsHasTech(T[key]) end
function J.Alive(u) return u and not u:IsDead() and not u:IsDelayedDeath() end
function J.SetPromo(u,key,on)
 local pr=J.Promotion(key);if pr and u:IsHasPromotion(pr)~=(on or false) then u:SetHasPromotion(pr,on or false) end
end
function J.Near(center,radius)
 local out,seen={},{}
 for dx=-radius,radius do for dy=-radius,radius do
  local p=Map.PlotXYWithRangeCheck(center:GetX(),center:GetY(),dx,dy,radius)
  if p and not seen[J.Index(p)] then out[#out+1]=p;seen[J.Index(p)]=true end
 end end
 table.sort(out,function(a,b)local da,db=J.Distance(center,a),J.Distance(center,b);if da==db then return J.Index(a)<J.Index(b) end return da<db end)
 return out
end
function J.City(id,record)
 local p=record and J.Plot(record.plot);local c=p and p:GetPlotCity()
 if c and c:GetOwner()==id and c:GetGameTurnFounded()==record.founded then return c end
end
function J.CityRecord(c) return {plot=J.Index(c:Plot()),founded=c:GetGameTurnFounded()} end
function J.Has(id,s,key)
 local c=J.City(id,s.landmarks[key]);return c and c:GetNumBuilding(J.Building(key))>0 or false
end
function J.Tier(s)
 local n=0;for _,l in ipairs(C.landmarks) do if s.landmarks[l.key] then n=n+1 end end;return n
end
function J.Count(id,key)
 local n=0;for u in Players[id]:Units() do if J.Alive(u) and u:GetUnitType()==J.Unit(id,key) then n=n+1 end end;return n
end
function J.Tributaries(id,s)
 local n=0
 for minor,r in pairs(s.trib) do
  local p=Players[minor];local cap=p and p:GetCapitalCity()
  if p and p:IsAlive() and p:IsMinorCiv() and cap and J.Index(cap:Plot())==r.plot and cap:GetGameTurnFounded()==r.founded and not Teams[Players[id]:GetTeam()]:IsAtWar(p:GetTeam()) then n=n+1
  else s.trib[minor]=nil end
 end
 return n
end
function J.SiteLegal(id,p)
 if not p or p:GetOwner()~=id or p:IsWater() or p:IsMountain() or p:IsImpassable() or p:IsCity() then return false end
 if p:GetResourceType(-1)~=-1 or p:GetImprovementType()~=-1 then return false end
 local feature=GameInfo.Features[p:GetFeatureType()]
 if feature and (J.Flag(feature.NaturalWonder) or J.Flag(feature.Impassable) or feature.Type=='FEATURE_ICE') then return false end
 for i=0,p:GetNumUnits()-1 do local u=p:GetUnit(i);if u and u:GetOwner()~=id then return false end end
 return true
end
function J.Candidates(id,s,tier)
 local pending=s.pending[tier];if not pending then return {} end
 local c=J.City(id,pending) or Players[id]:GetCapitalCity();if not c then return {} end
 local sites={}
 for _,index in ipairs(pending.sites or {}) do if J.SiteLegal(id,J.Plot(index)) then sites[#sites+1]=index end end
 -- Replace the entire offer only if all previously offered sites became illegal.
 if #sites==0 then
  for _,p in ipairs(J.Near(c:Plot(),C.siteRadius)) do if J.SiteLegal(id,p) then sites[#sites+1]=J.Index(p);if #sites==3 then break end end end
  pending.sites=sites;pending.plot=J.Index(c:Plot());pending.founded=c:GetGameTurnFounded();J.Save(id,s)
 end
 return sites
end
function J.GrassActive(id,key,g)
 if key=='pasture' then local c=J.City(id,g);return c and c:GetNumBuilding(J.Building('GREAT_PASTURE'))>0 or false end
 local p=J.Plot(g.plot)
 return p and p:GetOwner()==id and p:GetImprovementType()==T.IMPROVEMENT_JIN_GRASSLAND and not p:IsImprovementPillaged() or false
end
function J.Horses(id,s)
 local n,capacity=0,0
 for key,g in pairs(s.grass) do if J.GrassActive(id,key,g) then n=n+g.horses;capacity=capacity+C.horseCapacity end end
 return n,capacity
end
function J.Cavalry(u)
 local row=GameInfo.Units[u:GetUnitType()]
 return J.Alive(u) and u:IsCombatUnit() and u:GetDomainType()==DomainTypes.DOMAIN_LAND and row and (J.Flag(row.IsMounted) or row.CombatClass=='UNITCOMBAT_MOUNTED') and row.CombatClass~='UNITCOMBAT_HELICOPTER'
end
function J.SyncUnit(id,u,s,fresh,totalHorses)
 if not J.Alive(u) then return end
 local own=s and J.IsJin(id);local row=GameInfo.Units[u:GetUnitType()] or {}
 local horse=own and J.Cavalry(u) and (totalHorses or J.Horses(id,s))*(u:IsRanged() and C.rangedHP or C.meleeHP) or 0
 -- One exact native HP promotion; its full range is generated from Balance.json.
 local hpBefore=u:GetMaxHitPoints();local damage=u:GetDamage();local current=math.max(1,hpBefore-damage)
 J.hp[id]=J.hp[id] or {};local previous=J.hp[id][u:GetID()]
 if not previous or previous.born~=u:GetGameTurnCreated() or previous.kind~=u:GetUnitType() then
  -- One reconstruction scan on load/ownership/type change repairs legacy or copied banks.
  for n=1,C.horseCapacity*4*math.max(C.meleeHP,C.rangedHP) do if n~=horse then J.SetPromo(u,'HORSE_'..n,false) end end
 elseif previous.amount~=horse and previous.amount>0 then J.SetPromo(u,'HORSE_'..previous.amount,false) end
 if horse>0 then J.SetPromo(u,'HORSE_'..horse,true) end
 J.hp[id][u:GetID()]={born=u:GetGameTurnCreated(),kind=u:GetUnitType(),amount=horse}
 local garden=own and J.Plot(s.garden)
 local near=garden and garden:GetOwner()==id and garden:GetImprovementType()==T.IMPROVEMENT_JIN_GARDEN and not garden:IsImprovementPillaged() and J.Distance(garden,u:GetPlot())<=C.gardenRadius
 local worker=(row.WorkRate or 0)>0
 J.SetPromo(u,'GARDEN_WORK',near and worker)
 J.SetPromo(u,'GARDEN_COMBAT',near and u:IsCombatUnit() and row.CombatClass~='UNITCOMBAT_SIEGE' and u:GetDomainType()==DomainTypes.DOMAIN_LAND)
 local up=own and s.upgrades or {}
 J.SetPromo(u,'QUILTED_ARMOR',up.QUILTED_ARMOR and J.Cavalry(u))
 J.SetPromo(u,'PADDED_LAMELLAR',up.PADDED_LAMELLAR and J.Cavalry(u))
 J.SetPromo(u,'DRAFT_HORSES',up.DRAFT_HORSES and J.Cavalry(u))
 J.SetPromo(u,'DRAFT_WORK',up.DRAFT_HORSES and u:GetUnitType()==J.Unit(id,'MOUNTED_VILLAGER'))
 J.SetPromo(u,'MOHE_ANCESTRY',up.MOHE_ANCESTRY and u:GetUnitType()==J.Unit(id,'MOHE'))
 J.SetPromo(u,'STORM_LANCES',up.STORM_LANCES and u:GetUnitType()==J.Unit(id,'IRON_PAGODA'))
 local infantry=row.CombatClass=='UNITCOMBAT_MELEE' or row.CombatClass=='UNITCOMBAT_GUN'
 J.SetPromo(u,'TOWER_SHIELDS',up.TOWER_SHIELDS and infantry)
 J.SetPromo(u,'PORCUPINE_DEFENSE',up.PORCUPINE_DEFENSE and infantry)
 J.SetPromo(u,'FLYING_FIRE',up.FLYING_FIRE and (u:GetUnitType()==J.Unit(id,'ERUPTOR') or u:GetUnitType()==J.Unit(id,'GRENADIER')))
 J.SetPromo(u,'PILI_PAO',up.PILI_PAO and row.CombatClass=='UNITCOMBAT_SIEGE')
 -- Preserve absolute living HP on every max-HP transition; never heal by cycling Horses.
 local max=u:GetMaxHitPoints()
 if max~=hpBefore then u:SetDamage(fresh and damage==0 and 0 or math.max(0,math.min(max-1,max-current))) end
end
function J.Units(id,s)
 local horses=s and J.Horses(id,s) or 0
 for u in Players[id]:Units() do J.SyncUnit(id,u,s,false,horses) end
end
function J.SetBuilding(c,key,n)
 local b=J.Building(key);if c:GetNumRealBuilding(b)~=n then c:SetNumRealBuilding(b,n) end
end
function J.Economy(id,s)
 local p=Players[id];local cap=p:GetCapitalCity();local count=J.Tributaries(id,s)
 local dragon=J.Has(id,s,'DRAGON_PAVILION');local hall=J.Has(id,s,'MOUNTAIN_HALL')
 if p:HasPolicy(T.POLICY_JIN_TRIBUTARY_TRADE)~=(count>0) then p:SetHasPolicy(T.POLICY_JIN_TRIBUTARY_TRADE,count>0) end
 if p:HasPolicy(T.POLICY_JIN_MONASTERY)~=hall then p:SetHasPolicy(T.POLICY_JIN_MONASTERY,hall) end
 for c in p:Cities() do
  J.SetBuilding(c,'TRIBUTE',c==cap and count or 0)
  J.SetBuilding(c,'PAVILION_DISCOUNT',dragon and 1 or 0)
  J.SetBuilding(c,'BLESSING',hall and s.blessing>J.Now() and 1 or 0)
  for _,up in ipairs(C.upgrades) do J.SetBuilding(c,'UP_'..up.key,s.upgrades[up.key] and 1 or 0) end
 end
 J.Save(id,s)
end
function J.Complete(id,s)
 for _,l in ipairs(C.landmarks) do if not s.landmarks[l.key] then
  for c in Players[id]:Cities() do if c:GetNumBuilding(J.Building(l.key))>0 then
   -- Native completion, never mere selection, grants the age-up opportunity once.
   s.choices[l.tier]=l.key;s.landmarks[l.key]=J.CityRecord(c)
   s.pending[l.tier]=J.CityRecord(c);s.pending[l.tier].sites={}
   if l.key=='GREAT_PASTURE' then s.grass.pasture=J.CityRecord(c);s.grass.pasture.horses=0;s.grass.pasture.elapsed=0 end
   if l.key=='DRAGON_PAVILION' then s.freeEmissary=true end
   if l.key=='PAGODA_FOREST' then s.groveReady=J.Now()+J.Scale(C.groveInterval) end
   s.serial=s.serial+1;J.Save(id,s);J.Candidates(id,s,l.tier);break
  end end
 end end
end
function J.Start(id,s)
 if s.started then return end
 local c=Players[id]:GetCapitalCity();if not c then return end
 s.started=true;J.Save(id,s) -- mark before spawning resources or Food
 local placed=0
 for _,p in ipairs(J.Near(c:Plot(),2)) do
  if placed<2 and p:GetOwner()==id and not p:IsCity() and not p:IsWater() and not p:IsMountain() and not p:IsImpassable() and p:GetResourceType(-1)==-1 and p:GetImprovementType()==-1 then
   local terrain=GameInfo.Terrains[p:GetTerrainType()];local feature=GameInfo.Features[p:GetFeatureType()]
   if terrain and (terrain.Type=='TERRAIN_GRASS' or terrain.Type=='TERRAIN_PLAINS' or terrain.Type=='TERRAIN_TUNDRA') and (not feature or feature.Type=='FEATURE_FOREST') then p:SetResourceType(T.RESOURCE_DEER,1);placed=placed+1 end
  end
 end
 if placed<2 then c:ChangeFood(math.floor(J.Scale(C.startingFoodFallback)*(2-placed)/2)) end
end
function J.LandmarkAllowed(id,cityID,bid)
 local l
 for _,candidate in ipairs(C.landmarks) do if J.Building(candidate.key)==bid then l=candidate end end
 if not l then return true end
 local s=J.State(id);if not s then return false end
 local p=Players[id];local cap=p:GetCapitalCity()
 return cap and cap:GetID()==cityID and p:GetCurrentEra()>=l.era and not s.landmarks[l.key] and s.choices[l.tier]==l.key and (l.tier==1 or J.Tier(s)>=l.tier-1) or false
end
function J.TrainAllowed(id,cityID,uid)
 if not J.IsJin(id) then
  for _,u in ipairs(C.units) do if uid==J.Unit(id,u.key) then return false end end;return true
 end
 local s=J.State(id);if not s then return false end
 if uid==J.Unit(id,'DEFENDER') or uid==J.Unit(id,'GRENADIER') then return false end
 if uid==J.Unit(id,'MOUNTED_VILLAGER') then return J.Count(id,'MOUNTED_VILLAGER')<C.villagerCap+C.tributaryVillagers*J.Tributaries(id,s) end
 if uid==J.Unit(id,'EMISSARY') then return J.Tier(s)>=2 and J.Count(id,'EMISSARY')<C.emissaryCap end
 if uid==J.Unit(id,'BED_CROSSBOW') then local c=Players[id]:GetCityByID(cityID);return c and c:GetNumBuilding(J.Building('MACHINE_WORKSHOP'))>0 or false end
 return true
end
function J.RecruitSource(id,s,c)
 for _,key in ipairs({'pasture',1,2,3}) do local g=s.grass[key]
  if g and J.GrassActive(id,key,g) and g.horses>0 then
   local p=J.Plot(g.plot)
   if p and J.Distance(c:Plot(),p)<=C.stableRadius and (c:GetNumBuilding(J.Building('WAR_STABLE'))>0 or (key=='pasture' and J.Distance(c:Plot(),p)==0)) then return key end
  end
 end
end
function J.RecruitCheck(id,s,cityID,uid)
 local p=Players[id];local c=p:GetCityByID(cityID);local row=GameInfo.Units[uid]
 if not c or not row or not (J.Flag(row.IsMounted) or row.CombatClass=='UNITCOMBAT_MOUNTED') then return false,'Select a cavalry unit and owned city.' end
 if uid==J.Unit(id,'DEFENDER') or uid==J.Unit(id,'GRENADIER') then return false,'Automatic defenders cannot be recruited.' end
 if c:IsResistance() or c:IsRazing() then return false,'City is resisting or being razed.' end
 if not J.Tech(id,row.PrereqTech) then return false,'Unit technology not researched.' end
 if not J.TrainAllowed(id,cityID,uid) or not c:IsCanPurchase(false,true,uid,-1,-1,YieldTypes.YIELD_GOLD) then return false,'Native unit, resource, cap, building or purchase rules prohibit recruitment.' end
 if not c:CanPlaceUnitHere(uid) then return false,'No legal deployment plot in this city.' end
 local source=J.RecruitSource(id,s,c)
 if not source then return false,'No available Horse within War Stable influence (2 plots), or Grassland is pillaged.' end
 local normal=c:GetUnitPurchaseCost(uid)
 if normal<=0 then return false,'This unit cannot be purchased with Gold.' end
 local cost=math.max(1,math.ceil(normal*C.recruitPercent/100))
 if p:GetGold()<cost then return false,'Requires '..cost..' Gold.' end
 return true,'Recruit for 1 Horse + '..cost..' Gold.',source,cost
end
function J.Refresh(changed)
 if changed then J.uiRevision=(J.uiRevision or 0)+1 end
 if J.UIRefresh and J.panelOpen then J.Defer('ui',function()J.UIRefresh(false)end) end
end
function J.Action(id,serial,kind,a,b)
 if not J.active or not J.IsJin(id) or Game.GetActivePlayer()~=id or not Players[id]:IsTurnActive() or J.busy[id] then return false,'An active Jin turn is required.' end
 local s=J.State(id);if not s or s.serial~=serial then return false,'Panel state changed; refresh before retrying.' end
 if s.transaction then return false,'A saved transaction must finish recovery before another Jin action.' end
 J.busy[id]=true
 local ok,result,message=pcall(function()
  if kind=='LANDMARK' then
   local l;for _,v in ipairs(C.landmarks) do if v.key==a then l=v end end
   local cap=Players[id]:GetCapitalCity()
   if not l or not cap or s.choices[l.tier] or Players[id]:GetCurrentEra()<l.era or J.Tier(s)<l.tier-1 then return false,'Landmark choice already committed or prior tier/era required.' end
   s.choices[l.tier]=a;s.serial=s.serial+1;J.Save(id,s)
   cap:PushOrder(OrderTypes.ORDER_CONSTRUCT,J.Building(a),-1,0,false,false,0)
   return true,'Landmark selected. Complete its construction in the capital.'
  elseif kind=='SITE' then
   local found=false;for _,index in ipairs(J.Candidates(id,s,a)) do if index==b then found=true end end
   if not found or not J.SiteLegal(id,J.Plot(b)) then return false,'Grassland site is no longer legal.' end
   s.pending[a]=nil;s.grass[a]={plot=b,horses=0,elapsed=0};s.serial=s.serial+1;J.Save(id,s)
   J.Plot(b):SetImprovementType(T.IMPROVEMENT_JIN_GRASSLAND,id,false);J.Save(id,s)
   return true,'Grassland established; other proposed sites removed.'
  elseif kind=='RECRUIT' then return J.Recruit(id,s,a,b)
  elseif kind=='GARDEN' then
   if not J.Has(id,s,'FLOWER_PAGODA') or J.Now()<s.gardenReady or not J.SiteLegal(id,J.Plot(a)) then return false,'Requires Flower Pagoda, an empty owned land plot and relocation cooldown.' end
   local previous=J.Plot(s.garden);s.garden=a;s.gardenReady=J.Now()+J.Scale(C.gardenCooldown);s.serial=s.serial+1;J.Save(id,s)
   if previous and previous:GetOwner()==id and previous:GetImprovementType()==T.IMPROVEMENT_JIN_GARDEN then previous:SetImprovementType(-1,id,false) end
   J.Plot(a):SetImprovementType(T.IMPROVEMENT_JIN_GARDEN,id,false);J.Units(id,s);return true,'Flower Garden placed.'
  elseif kind=='UPGRADE' then
   local up;for _,v in ipairs(C.upgrades) do if v.key==a then up=v end end
   if not up or s.upgrades[a] or not J.Tech(id,up.tech) or Players[id]:GetGold()<J.Scale(up.cost) then return false,'Upgrade already researched, technology missing or insufficient Gold.' end
   s.upgrades[a]=true;s.serial=s.serial+1;J.Save(id,s);Players[id]:ChangeGold(-J.Scale(up.cost));J.Economy(id,s);J.Units(id,s);return true,up.name..' researched.'
  elseif kind=='TRIBUTARY' then return J.Establish(id,s,a,b)
  elseif kind=='BRIBE' then return J.Bribe(id,s,a,b)
  end
  return false,'Unknown Jin action.'
 end)
 J.busy[id]=nil
 if not ok then print('JIN action error: '..tostring(result));return false,'Action failed; inspect Lua.log.' end
 J.InvalidateSpatial(id);J.Refresh(true);return result,message
end
include('JIN_Runtime')
include('JIN_Military')
include('JIN_Autonomy')
include('JIN_Transactions')
function J.Turn(id)
 local s=J.State(id);if not s or J.busy[id] then return end
 if s.transaction then local ok,err=pcall(J.RecoverTransaction,id,s);if not ok then print('JIN transaction recovery: '..tostring(err));return end;s=J.State(id) end
 J.busy[id]=true;J.Start(id,s);J.Complete(id,s)
 local fresh=s.turn~=J.Now()
 if fresh then
  J.InvalidateSpatial(id)
  s.turn=J.Now();s.serial=s.serial+1;J.Save(id,s)
  for key,g in pairs(s.grass) do
   local p=J.Plot(g.plot)
   local destroyed=not p or p:GetOwner()~=id or (key~='pasture' and p:GetImprovementType()~=T.IMPROVEMENT_JIN_GRASSLAND) or (key=='pasture' and not J.GrassActive(id,key,g))
   if destroyed then s.grass[key]=nil
   elseif J.GrassActive(id,key,g) and g.horses<C.horseCapacity then
    g.elapsed=g.elapsed+1;local interval=J.Scale(C.horseIntervals[math.max(1,J.Tier(s))])
    if g.elapsed>=interval then g.elapsed=g.elapsed-interval;g.horses=math.min(C.horseCapacity,g.horses+1) end
   end
  end
  J.Karma(id,s);J.Groves(id,s)
  for key,turn in pairs(s.slowed) do if turn<J.Now() then s.slowed[key]=nil end end
  for key,turn in pairs(s.deaths) do if turn<J.Now() then s.deaths[key]=nil end end
  if J.conversions then for key,turn in pairs(J.conversions) do if turn<J.Now() then J.conversions[key]=nil end end end
  for uid,r in pairs(s.emissaryCooldown) do local u=Players[id]:GetUnitByID(uid);if not J.Alive(u) or u:GetGameTurnCreated()~=r.born or u:GetUnitType()~=J.Unit(id,'EMISSARY') then s.emissaryCooldown[uid]=nil end end
  J.Save(id,s)
 end
 J.FreeEmissary(id,s);J.Defenders(id,s,fresh);J.Economy(id,s);J.Units(id,s);J.Save(id,s)
 J.busy[id]=nil;J.QueuePatrol(id);J.Refresh(true)
end
function J.Hook(group,name,fn,veto)
 local event=group and group[name]
 if event and event.Add then
  local safe=function(...)
   if not J.active then return veto and true or nil end
   local ok,result=pcall(fn,...)
   if not ok then J.busy={};J.combatBusy=false;print('JIN '..name..': '..tostring(result));if veto then return false end;return nil end
   return result
  end
  event.Add(safe);J.handlers[#J.handlers+1]={event=event,fn=safe}
 end
end
J.Hook(GameEvents,'CityCanConstruct',J.LandmarkAllowed,true)
J.Hook(GameEvents,'CityCanTrain',J.TrainAllowed,true)
J.Hook(GameEvents,'PlayerDoTurn',function(id)
 if J.IsJin(id) then J.Turn(id) end
 J.CleanupRebels(id)
end)
J.Hook(GameEvents,'PlayerDoneTurn',function(id) if J.IsJin(id) then local s=J.State(id);if s then J.Economy(id,s) end end end)
J.Hook(GameEvents,'CityConstructed',function(id)
 J.InvalidateSpatial(id)
 if J.IsJin(id) and not J.busy[id] then local s=J.State(id);if s then J.Complete(id,s);J.FreeEmissary(id,s);J.Economy(id,s);J.Units(id,s) end end
 J.Refresh(true)
end)
J.Hook(GameEvents,'DeclareWar',function()
 for id in pairs(J.civs) do if J.IsJin(id) then local s=J.State(id);if s then J.Economy(id,s) end end end
 J.Refresh(true)
end)
J.Hook(GameEvents,'PlayerCityFounded',function(id) if J.IsJin(id) then J.InvalidateSpatial(id);local s=J.State(id);if s then J.Start(id,s);J.Economy(id,s) end;J.Refresh(true) end end)
J.Hook(GameEvents,'CityCaptureComplete',function(oldOwner,isCapital,x,y,newOwner)
 J.InvalidateSpatial()
 local c=Map.GetPlot(x,y):GetPlotCity()
 -- Captured native dummies must be purged before the conqueror's next harvest.
 if c and not J.IsJin(newOwner) then
  for _,key in ipairs({'TRIBUTE','PAVILION_DISCOUNT','BLESSING'}) do J.SetBuilding(c,key,0) end
  for _,up in ipairs(C.upgrades) do J.SetBuilding(c,'UP_'..up.key,0) end
 end
 for id in pairs(J.civs) do if J.IsJin(id) then local s=J.State(id);if s then J.Complete(id,s);J.Defenders(id,s,false);J.Economy(id,s);J.Units(id,s) end end end
 J.Refresh(true)
end)
J.Hook(GameEvents,'UnitCreated',function(id,unitID)
 J.NoteCreated(id,unitID)
 if J.IsJin(id) and not J.busy[id] then local s=J.State(id);local u=Players[id]:GetUnitByID(unitID);if s and u then J.SyncUnit(id,u,s,true) end end
 if J.IsJin(id) or (J.panelOpen and J.uiTab=='Emissaries') then J.Refresh(true) end
end)
J.Hook(GameEvents,'UnitConverted',function(oldOwner,newOwner,oldID,newID,isUpgrade)
 if not J.civs[oldOwner] and not J.civs[newOwner] then return end
 J.conversions=J.conversions or {};J.conversions[oldOwner..':'..oldID]=J.Now()
 if J.hp[oldOwner] then J.hp[oldOwner][oldID]=nil end
 if J.hp[newOwner] then J.hp[newOwner][newID]=nil end
 local u=Players[newOwner] and Players[newOwner]:GetUnitByID(newID)
 local s=J.civs[oldOwner] and Players[oldOwner] and S.Player(Players[oldOwner])
 if s and s.defenders[oldID] then
  s.defenders[oldID]=nil;J.Save(oldOwner,s)
  if J.Alive(u) then u:Kill(false,-1) end;return
 end
 if u then J.SyncUnit(newOwner,u,J.State(newOwner)) end
end)
J.Hook(GameEvents,'UnitSetXY',J.Movement)
J.Hook(GameEvents,'CanMoveInto',J.CanMoveInto,true)
J.Hook(GameEvents,'CanStartMission',J.CanStartMission,true)
J.Hook(GameEvents,'UnitPrekill',function(id,...)
 if J.IsJin(id) or (J.panelOpen and J.uiTab=='Emissaries') then J.Refresh(true) end
 J.Death(id,...)
end)
J.Hook(GameEvents,'PlayerPlunderedTradeRoute',J.TradePlundered)
J.Hook(GameEvents,'CombatEnded',function(...)
 J.Combat(...)
 for id in pairs(J.civs) do J.QueuePatrol(id) end
end)
J.Hook(Events,'SerialEventUnitInfoDirty',function()
 for id in pairs(J.civs) do J.QueuePatrol(id) end
end)
J.Hook(GameEvents,'TileImprovementChanged',function(x,y,owner,oldImprovement,newImprovement,pillaged)
 local plot=Map.GetPlot(x,y);if not plot then return end
 for id in pairs(J.civs) do if J.IsJin(id) and not J.busy[id] then
  local s=J.State(id)
  if s then
   J.InvalidateSpatial(id)
   for key,g in pairs(s.grass) do if key~='pasture' and g.plot==J.Index(plot) and plot:GetImprovementType()~=T.IMPROVEMENT_JIN_GRASSLAND then s.grass[key]=nil end end
   if plot:GetOwner()==id and (plot:GetImprovementType()==T.IMPROVEMENT_FORT or plot:GetImprovementType()==T.IMPROVEMENT_CITADEL) then s.forts[J.Index(plot)]=true else s.forts[J.Index(plot)]=nil end
   J.Save(id,s);J.Defenders(id,s,false);J.Units(id,s)
  end
 end end
 J.Refresh(true)
end)
J.Hook(GameEvents,'TileOwnershipChanged',function(x,y,newOwner,oldOwner)
 if newOwner~=nil and not J.civs[newOwner] and not J.civs[oldOwner] then return end
 J.InvalidateSpatial()
 for id in pairs(J.civs) do if J.IsJin(id) and not J.busy[id] then local s=J.State(id);if s then
  for key,g in pairs(s.grass) do local p=J.Plot(g.plot);if not p or p:GetOwner()~=id then s.grass[key]=nil end end
  local plot=x and Map.GetPlot(x,y)
  if plot and plot:GetOwner()==id and (plot:GetImprovementType()==T.IMPROVEMENT_FORT or plot:GetImprovementType()==T.IMPROVEMENT_CITADEL) then s.forts[J.Index(plot)]=true end
  J.Save(id,s);J.Defenders(id,s,false);J.Units(id,s)
 end end end
end)
function J.Bootstrap()
 S.ResetCache();J.InvalidateSpatial();J.hp={};J.rejected={};J.invalidPending={};J.pendingCombat=nil
 J.civs={}
 for id=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do
  local p=Players[id]
  if p and p:IsHuman() and p:GetCivilizationType()==J.CIV then J.civs[id]=true end
  if J.IsJin(id) then
  local s=J.State(id)
  if s and s.transaction then local ok,err=pcall(J.RecoverTransaction,id,s);if not ok then print('JIN transaction recovery: '..tostring(err));s=nil end end
  if s then
   J.Start(id,s);J.Complete(id,s)
   -- Local city neighborhoods discover forts in advanced starts; events index later forts.
   for c in Players[id]:Cities() do for _,p in ipairs(J.Near(c:Plot(),C.siteRadius)) do
    if p:GetOwner()==id and (p:GetImprovementType()==T.IMPROVEMENT_FORT or p:GetImprovementType()==T.IMPROVEMENT_CITADEL) then s.forts[J.Index(p)]=true end
   end end
   J.Defenders(id,s,false);J.Economy(id,s);J.Units(id,s);J.Save(id,s)
   J.QueuePatrol(id)
  end
  end
 end
 J.Refresh(true)
end
J.Hook(Events,'SequenceGameInitComplete',J.Bootstrap)
J.Hook(Events,'LoadScreenClose',J.Bootstrap)
if ContextPtr.SetShutdown then ContextPtr:SetShutdown(function()
 J.active=false;for _,h in ipairs(J.handlers) do h.event.Remove(h.fn) end
 if J.context.ClearUpdate then J.context:ClearUpdate() end;J.jobs={}
 if MapModData.JIN==J then MapModData.JIN=nil end
end) end
J.Bootstrap()
