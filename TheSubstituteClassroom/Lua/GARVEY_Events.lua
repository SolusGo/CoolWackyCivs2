local G=MapModData.Garvey
local H=G.Hook
local maxPlayers=GameDefines.MAX_CIV_PLAYERS or 64
local function sync(pid,units) G.Sync(pid,units);LuaEvents.GARVEY_Changed(pid) end
H(GameEvents,'PlayerDoTurn',function(pid)
 if not G.Human(pid) and not G.states[pid] then return end
 local s=G.State(pid)
 if s then
  local bonus,detained=G.Active(s,'bonusEnd'),G.Active(s,'detEnd')
  -- CP harvests city yields/research BEFORE this hook. Keep the old clock through
  -- the final yield tick, then expire before the player's next actions. Raw-turn
  -- deadlines are never decremented by UI, reloads, or duplicate callbacks.
  s.clock=Game.GetGameTurn()
  local notify=s.clock>=s.ready and s.notified~=s.ready
  if notify then s.notified=s.ready end
  G.Guard('save turn',function() G.Save(pid,s) end)
  if G.Human(pid) then
   if bonus and not G.Active(s,'bonusEnd') then G.Notify(pid,G.Text('BONUS_END')) end
   if detained and not G.Active(s,'detEnd') then G.Notify(pid,G.Text('DETENTION_END')) end
   if notify then G.Notify(pid,G.Text('READY_NOTICE')) end
  end
 end
 sync(pid,true)
end)
H(GameEvents,'PlayerCityFounded',function(pid) if G.Human(pid) then sync(pid,false) end end)
for _,name in ipairs({'CityConstructed','CitySoldBuilding'}) do
 H(GameEvents,name,function(pid,_,building) if building==G.OFFICE then sync(pid,false) end end)
end
H(GameEvents,'CapitalChanged',function(pid) if G.Human(pid) then sync(pid,false) end end)
H(GameEvents,'CityCaptureComplete',function(old,_,x,y,new)
 -- Includes nonconquest transfers; native reconstruction has completed.
 sync(old,true);sync(new,true)
end)
H(GameEvents,'CityRazed',function(pid) sync(pid,false) end)
H(GameEvents,'UnitCreated',function(pid,id)
 local p=Players[pid];if p then G.Unit(pid,p:GetUnitByID(id)) end
end)
H(GameEvents,'CityTrained',function(pid,_,id)
 local p=Players[pid];if p then G.Unit(pid,p:GetUnitByID(id)) end
end)
H(GameEvents,'UnitConverted',function(old,new,oldID,newID)
 local p=Players[new];if p then G.Unit(new,p:GetUnitByID(newID)) end
end)
H(GameEvents,'UnitUpgraded',function(pid,_,newID)
 local p=Players[pid];if p then G.Unit(pid,p:GetUnitByID(newID)) end
end)
H(GameEvents,'PlayerCanAdoptPolicy',function(_,id)
 return id~=GameInfoTypes.POLICY_GARVEY_PENALTY_FULL and id~=GameInfoTypes.POLICY_GARVEY_PENALTY_RELIEF
end)

-- CP CombatResult precedes native damage; CombatEnded supplies resolved totals.
-- Snapshot actual base strength and the battle tile (not the winner's old tile).
-- Do NOT also reward UnitKilledInCombat: ordinary damage emits it with killer -1.
local battles={}
local function battleKey(ap,ai,dp,di) return ap..':'..ai..':'..dp..':'..di end
local function unit(pid,id) local p=Players[pid];return p and id>=0 and p:GetUnitByID(id) or nil end
local function snapshot(pid,id)
 local u=unit(pid,id)
 if not u then return nil end
 return {pid=pid,id=id,born=u:GetGameTurnCreated(),hall=u:GetUnitType()==G.UNIT,
  strength=math.max(u:GetBaseCombatStrength(),u:GetBaseRangedCombatStrength())}
end
H(GameEvents,'CombatResult',function(ap,ai,_,af,am,dp,di,dd,df,dm,ip,ii,damage,x,y)
 if not G.Human(ap) and not G.Human(dp) then return end
 local plot=Map.GetPlot(x,y)
 battles[battleKey(ap,ai,dp,di)]={a=snapshot(ap,ai),d=snapshot(dp,di),
  afriendly=plot and G.Human(ap) and plot:IsFriendlyTerritory(ap) or false,
  dfriendly=plot and G.Human(dp) and plot:IsFriendlyTerritory(dp) or false}
end)
local function reward(pid,loser,effect)
 if not G.Human(pid) or not loser or loser.strength<=0 then return end
 local s=G.State(pid);if not s then return end
 if effect=='DETENTION' and not G.Active(s,'detEnd') then return end
 if not G.MarkKill(pid,loser,effect) then return end
 local value=math.max(G.config.KillCultureMinimum,math.floor(loser.strength*G.config.KillCulturePercent/100+0.5))
 Players[pid]:ChangeJONSCulture(value)
 -- Combat popup text, without filling the notification log after every kill.
 if pid==Game.GetActivePlayer() and Events.GameplayAlertMessage then Events.GameplayAlertMessage(G.Text('KILL',value)) end
end
-- Detention covers every attributed lethal military-damage callback, including
-- nuclear/collateral deaths that have no ordinary two-unit completion. Captures,
-- disbands and conversions are not lethal damage and cannot pay. The saved
-- lifetime/effect ledger prevents delayed/final death callbacks paying twice.
H(GameEvents,'UnitPrekill',function(owner,id,typ,x,y,delay,killer)
 if not G.Human(killer) or owner==killer then return end
 local defeated=Players[owner]
 if not defeated or not Teams[Players[killer]:GetTeam()]:IsAtWar(defeated:GetTeam()) then return end
 local u=unit(owner,id)
 if not u or not u:IsDead() then return end
 G.Guard('Detention kill reward',function() reward(killer,snapshot(owner,id),'DETENTION') end)
end)
H(GameEvents,'CombatEnded',function(ap,ai,_,af,am,dp,di,dd,df,dm)
 local key=battleKey(ap,ai,dp,di);local b=battles[key];battles[key]=nil
 if not b then return end -- Duplicate/unpaired completion cannot pay a second time.
 if df>=dm and af<am and b.a and b.a.hall and b.afriendly then
  G.Guard('Hall Monitor kill reward',function() reward(ap,b.d,'HALL') end)
 end
 if af>=am and df<dm and b.d and b.d.hall and b.dfriendly then
  G.Guard('Hall Monitor kill reward',function() reward(dp,b.a,'HALL') end)
 end
end)

-- WarStateChanged receives team IDs. Notifications are flavor only.
H(Events,'WarStateChanged',function(a,b,war)
 for pid=0,maxPlayers-1 do
  if G.Human(pid) then local t=Players[pid]:GetTeam()
   if t==a or t==b then G.Notify(pid,G.Text(war and 'WAR' or 'PEACE')) end
  end
 end
end)
-- One dirty-event repair catches scripted building edits; it detaches immediately.
-- Never keep an idle update handler or scan the map on a frame timer.
G.dirty=false
function G.Flush()
 if not G.dirty then return end;G.dirty=false
 for pid=0,maxPlayers-1 do if G.Human(pid) then G.Sync(pid,false) end end
end
H(Events,'SerialEventGameDataDirty',function() G.dirty=true;if G.QueueRefresh then G.QueueRefresh() end end)
H(Events,'GameplaySetActivePlayer',function()
 for pid=0,maxPlayers-1 do if G.states[pid] then G.Sync(pid,true) end end
end)
for pid=0,maxPlayers-1 do G.Sync(pid,true) end
