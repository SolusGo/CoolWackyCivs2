local K=MapModData.CKPrayer
local H=K.Hook
-- One load reconciliation also strips foreign/captured remnants and never grants rewards.
for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do
 local p=Players[pid]
 if p then
  if K.Human(pid) then local s=K.State(pid);if s then K.Save(s) end end
  K.Sync(pid,true)
 end
end
H(LuaEvents,'CKPrayer_Pray',K.Pray)
H(GameEvents,'PlayerDoTurn',function(pid)
 local p=Players[pid];if not p then return end
 if K.Human(pid) or K.states[pid] then
  local s=K.states[pid] or (K.Human(pid) and K.State(pid))
  -- CP calls PlayerDoTurn AFTER city yields, before units. Keep blessings through
  -- their final economic tick; reconcile/expire before the human can act again.
  -- Existing tracked deadlines still age during temporary nonhuman control;
  -- only K.Sync's human guard can apply benefits. Never initialize an AI prayer.
  if s then s.clock=K.Turn();K.Save(s) end
  K.Sync(pid,true);LuaEvents.CKPrayer_Changed(pid)
 end
end)
H(Events,'GameplaySetActivePlayer',function()
 for pid in pairs(K.states) do K.Sync(pid,true) end
end)
H(GameEvents,'PlayerCityFounded',function(pid) if K.Human(pid) then K.Sync(pid,false) end end)
H(GameEvents,'CityConstructed',function(pid) if K.Human(pid) then K.Sync(pid,false);LuaEvents.CKPrayer_Changed(pid) end end)
H(GameEvents,'CitySoldBuilding',function(pid) if K.Human(pid) then K.Sync(pid,false) end end)
H(GameEvents,'CapitalChanged',function(pid) if K.Human(pid) then K.Sync(pid,false) end end)
H(GameEvents,'CityCaptureComplete',function(oldOwner,isCapital,x,y,newOwner)
 local plot=Map.GetPlot(x,y);local city=plot and plot:GetPlotCity()
 if city then K.City(city,nil,false) end
 -- Reassign exact capital counts on both sides, including eliminated players.
 if Players[oldOwner] then K.Sync(oldOwner,true) end
 if Players[newOwner] then K.Sync(newOwner,true) end
end)
for _,name in ipairs({'UnitCreated','CityTrained'}) do
 local trained=name=='CityTrained'
 H(GameEvents,name,function(pid,a,b)
  local id=trained and b or a;local p=Players[pid];local u=p and p:GetUnitByID(id)
  if u then K.Unit(pid,u) end
 end)
end
H(GameEvents,'UnitConverted',function(oldOwner,newOwner,oldID,newID,isUpgrade)
 local p=Players[newOwner];local u=p and p:GetUnitByID(newID);if not u then return end
 -- Preserve Stand Firm only for a same-owner upgrade. Gifts/captures cannot export it.
 if oldOwner~=newOwner or not isUpgrade then K.Promotion(u,K.STAND,false) end
 K.Unit(newOwner,u)
end)
H(GameEvents,'UnitSetXY',function(pid,id)
 local p=Players[pid];local u=p and p:GetUnitByID(id)
 if u and (K.Human(pid) or u:IsHasPromotion(K.STAND) or u:IsHasPromotion(K.SHIELD) or u:IsHasPromotion(K.DEFENDER)) then K.Unit(pid,u) end
end)
H(GameEvents,'TileOwnershipChanged',function(x,y)
 -- Only units ON the changed plot require territory reconciliation.
 local plot=Map.GetPlot(x,y);if not plot then return end
 for i=0,plot:GetNumUnits()-1 do local u=plot:GetUnit(i);if u then K.Unit(u:GetOwner(),u) end end
end)
H(Events,'WarStateChanged',K.TerritoryChanged)
-- CP dirties Score after changing open borders; minor access also has explicit hooks.
H(Events,'SerialEventScoreDirty',K.TerritoryChanged)
H(Events,'LeavingLeaderViewMode',K.TerritoryChanged)
H(GameEvents,'MinorFriendsChanged',K.TerritoryChanged)
H(GameEvents,'MinorAlliesChanged',K.TerritoryChanged)
H(GameEvents,'PlayerCanAdoptPolicy',function(pid,policy) return policy~=K.REPENT and policy~=K.PROTECTION end)
-- A finite queue chosen after ASK can immediately consume its saved credit. This
-- handler checks only players with a nonzero reserve, never all cities or units.
H(Events,'SerialEventCityInfoDirty',function()
 local pid=Game.GetActivePlayer();local s=K.states[pid]
 if s and s.bread>0 and not K.syncing[pid] then K.Bread(s) end
end)
