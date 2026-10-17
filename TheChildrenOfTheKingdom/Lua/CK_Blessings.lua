local K=MapModData.CKPrayer
function K.City(city,s,cap)
 for _,name in ipairs(K.buildings) do
  local n=0
  if s then
   if name=='ADDRESS' and cap and K.Active(s,'address') then n=1
   elseif name=='SEEK' and K.Active(s,'seek') then n=1
   elseif name=='HOUSE_BONUS' and city:GetNumRealBuilding(K.HOUSE)>0 then n=1
   elseif cap and name:sub(1,6)=='GRACE_' then n=math.floor(s.grace/2^tonumber(name:sub(7)))%2 end
  end
  local id=GameInfoTypes['BUILDING_CK_'..name]
  if city:GetNumRealBuilding(id)~=n then city:SetNumRealBuilding(id,n,true) end
 end
end
function K.Unit(pid,u)
 if not u or u:IsDead() or u:IsDelayedDeath() then return end
 local human=K.Alive(pid)
 local military=human and (u:IsCombatUnit() or u:IsRanged())
 local s=human and K.State(pid)
 if not s then military=false end
 -- Only the persistent identity is retained on upgrade. Native FriendlyHealChange
 -- participates in normal healing eligibility; Lua never grants hit points directly.
 if not military then K.Promotion(u,K.STAND,false)
 elseif u:GetUnitType()==K.KEEPER then K.Promotion(u,K.STAND,true) end
 local plot=u:GetPlot()
 local friendly=military and plot and plot:IsFriendlyTerritory(pid) or false
 K.Promotion(u,K.DEFENDER,friendly and u:IsHasPromotion(K.STAND) or false)
 K.Promotion(u,K.SHIELD,friendly and K.Active(s,'protection') or false)
 -- Native friendliness includes open borders and city-state access. Remember only
 -- relevant units abroad so diplomacy changes never require a whole-army scan.
 K.abroad[pid]=K.abroad[pid] or {}
 local watch=military and plot and plot:GetOwner()~=pid and (u:IsHasPromotion(K.STAND) or K.Active(s,'protection'))
 K.abroad[pid][u:GetID()]=watch and u:GetGameTurnCreated() or nil
end
function K.TerritoryChanged()
 for pid,units in pairs(K.abroad) do
  local p=Players[pid]
  for id,born in pairs(units) do
   local u=p and p:GetUnitByID(id)
   if u and not u:IsDead() and not u:IsDelayedDeath() and u:GetGameTurnCreated()==born then K.Unit(pid,u)
   else units[id]=nil end
  end
 end
end
function K.Policy(p,id,value)
 -- bFree=true excludes these branchless, temporary policies from policy cost growth.
 if p:HasPolicy(id)~=value then p:SetHasPolicy(id,value,true) end
end
function K.Bread(s)
 if not K.Alive(s.pid) or s.bread<=0 or K.busy[s.pid] then return end
 local city=Players[s.pid]:GetCapitalCity();if not city then return end
 -- Never call ChangeProduction on an empty/process queue: CP sends it to overflow.
 -- Never pop an order or create objects. Fill only the uncompleted part of ONE item.
 if not (city:IsProductionUnit() or city:IsProductionBuilding() or city:IsProductionProject()) then return end
 local current,needed=city:GetProductionTimes100(),city:GetProductionNeeded()*100
 local amount=math.min(s.bread,math.max(0,math.floor((needed-current)/100)))
 if amount<=0 then return end
 K.busy[s.pid]=true;s.bread=s.bread-amount;K.Save(s)
 -- The integer delta preserves pre-existing fractional production. SetProduction
 -- would overwrite it with a truncated total. Guard above prevents its overflow path.
 city:ChangeProduction(amount)
 K.busy[s.pid]=nil
end
function K.Sync(pid,units)
 local p=Players[pid];if not p or K.syncing[pid] then return end
 K.syncing[pid]=true
 local s=K.Alive(pid) and K.State(pid) or nil
 local cap=s and p:GetCapitalCity()
 for city in p:Cities() do K.City(city,s,cap and city:GetID()==cap:GetID()) end
 K.Policy(p,K.REPENT,K.Active(s,'repent') or false)
 K.Policy(p,K.PROTECTION,K.Active(s,'protection') or false)
 if units then for u in p:Units() do K.Unit(pid,u) end end
 K.syncing[pid]=nil
 if s then K.Bread(s) end
end
function K.CanPray(pid)
 if not K.Alive(pid) or Game.GetActivePlayer()~=pid or not Players[pid]:IsTurnActive() or not Players[pid]:GetCapitalCity() then return false,'UNAVAILABLE' end
 local s=K.State(pid);if not s then return false,'DISABLED' end
 if K.busy[pid] or K.Turn()<s.ready then return false,'WAIT_HELP' end
 return true
end
function K.Pray(pid,expectedStage,expectedReady)
 local can=K.CanPray(pid);if not can then return false end
 local s=K.State(pid)
 if expectedStage~=s.stage or expectedReady~=s.ready then return false end
 local p=Players[pid];local cap=p:GetCapitalCity();local stage=s.stage
 local era=math.max(1,p:GetCurrentEra()+1);local duration=K.Duration()
 local capped=s.grace==7;local houses=0
 if stage==7 then for city in p:Cities() do if city:GetNumRealBuilding(K.HOUSE)>0 then houses=houses+1 end end end
 K.busy[pid]=true
 -- Commit the next stage and cooldown BEFORE granting any one-shot rewards.
 -- The native game cannot save halfway through this synchronous Lua callback.
 s.stage=stage%7+1;s.ready=K.Turn()+duration;s.clock=K.Turn()
 if stage==1 then s.address=s.ready
 elseif stage==3 then s.seek=s.ready
 elseif stage==4 then s.bread=s.bread+8*era
 elseif stage==5 then s.repent=s.ready
 elseif stage==6 then s.protection=s.ready
 elseif stage==7 then s.grace=math.min(7,s.grace+1) end
 K.Save(s)
 if stage==2 then p:ChangeFaith(10*era)
 elseif stage==4 then cap:ChangeFood(8*era)
 elseif stage==7 then
  p:ChangeGoldenAgeProgressMeter((20+(capped and 25 or 0))*era)
  p:ChangeFaith(10*houses)
 end
 K.busy[pid]=nil
 K.Sync(pid,true)
 local message=K.Text('CONFIRM',K.Text('STAGE_'..stage),K.Text('STAGE_'..s.stage),duration)
 if stage==7 then
  message=message..'[NEWLINE]'..(capped and K.Text('GRACE_CAP',25*era) or K.Text('GRACE_GAIN',s.grace))
  message=message..'[NEWLINE]'..K.Text('HOUSE_REWARD',houses,10*houses)
 end
 K.Notify(pid,message);LuaEvents.CKPrayer_Changed(pid)
 return true
end
