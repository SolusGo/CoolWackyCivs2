local M=MapModData.MCPVP
local H=M.Hook
local participating=false
for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if M.IsCiv(pid) then participating=true;M.State(pid) end end
if not participating then return end
local armed=false
-- One-shot post-native dispatch. Never leave an update loop running.
function M.After(key,fn)
 M.pending[key]=fn
 if armed then return end;armed=true
 ContextPtr:SetUpdate(function()
  ContextPtr:ClearUpdate();armed=false;local work=M.pending;M.pending={}
  local keys={};for k in pairs(work) do keys[#keys+1]=k end;table.sort(keys)
  for _,k in ipairs(keys) do local ok,err=pcall(work[k]);if not ok then print('[McPvP] '..k..': '..tostring(err)) end end
 end)
end
function M.Command(pid,kind,id,target,kit)
 local p=Players[pid]
 if not M.IsCiv(pid) or pid~=Game.GetActivePlayer() or not p:IsHuman() or not p:IsTurnActive() or Game.IsNetworkMultiPlayer() then return false end
 local s=M.State(pid);if not s.mode or M.Turn()>=s.finish then return false end
 if kind=='QUEUE' then for _,mode in ipairs(M.modes) do if mode==target then s.queued=mode;M.Changed(s);return true end end;return false end
 local u=p:GetUnitByID(id or -1)
 if not M.Land(u) or u:IsBusy() then return false end
 if kind=='KIT' then return M.SelectKit(s,u,kit)
 elseif kind=='ABILITY' then return M.Ability(s,u,target)
 elseif kind=='STEAL' or kind=='RETURN' or kind=='INFILTRATE' then return M.Objective(s,u,kind,target) end
 return false
end
H(LuaEvents,'MCPVP_Command',M.Command)
H(GameEvents,'MustAbortAttack',function(pid,id)
 if not M.IsCiv(pid) then return false end
 local r=M.Peek(M.State(pid),Players[pid]:GetUnitByID(id));return r~=nil and r.flag~=nil
end)
H(GameEvents,'CanDoCommand',function(pid,id,command)
 if not M.IsCiv(pid) then return true end
 local s=M.State(pid);local u=Players[pid]:GetUnitByID(id);local r=M.Peek(s,u)
 if not r or not r.flag then return true end
 return command~=CommandTypes.COMMAND_UPGRADE and command~=CommandTypes.COMMAND_GIFT and command~=CommandTypes.COMMAND_DELETE
end)
H(GameEvents,'UnitCanHaveAnyUpgrade',function(pid,id)
 if not M.IsCiv(pid) then return true end
 local r=M.Peek(M.State(pid),Players[pid]:GetUnitByID(id));return not r or not r.flag
end)
H(GameEvents,'CityTrained',function(pid,cityID,id)
 if not M.IsCiv(pid) then return end
 local p=Players[pid];local s=M.State(pid);local city=p:GetCityByID(cityID);local u=p:GetUnitByID(id)
 if city and M.Military(u) and city:GetNumBuilding(M.HUB)>0 then
  local r=M.Record(s,u)
  if not r.trained then r.trained=true;r.eligible=u:GetDomainType()==DomainTypes.DOMAIN_LAND;M.Legacy(s,2);M.Save(s) end
  M.After('train:'..pid..':'..id,function() local v=M.Unit(s,r);if v then M.Apply(s,v,r);M.Changed(s) end end)
 end
end)
H(GameEvents,'UnitCreated',function(pid,id)
 if not M.IsCiv(pid) then return end
 M.After('created:'..pid..':'..id,function()
  local u=Players[pid]:GetUnitByID(id)
  if M.Military(u) then local s=M.State(pid);M.Apply(s,u,M.Record(s,u));M.Changed(s) end
 end)
end)
H(GameEvents,'UnitConverted',function(oldOwner,newOwner,oldID,newID,isUpgrade)
 local old=Players[oldOwner] and Players[oldOwner]:GetUnitByID(oldID)
 local new=Players[newOwner] and Players[newOwner]:GetUnitByID(newID)
 if not new then return end
 if old and oldOwner==newOwner and isUpgrade and M.IsCiv(oldOwner) then
  local s=M.State(oldOwner);local r=M.Peek(s,old)
  if r then
   if r.flag then M.Notify(s.pid,'Flag lost: the carrier underwent a forced upgrade.') end
   if r.mission then M.Notify(s.pid,'Infiltration interrupted: the infiltrator upgraded.') end
   r.flag=nil;r.mission=nil;r.id=newID;r.born=new:GetGameTurnCreated();M.Tag(new,r.serial)
   M.Apply(s,new,r);M.Changed(s)
  end
 elseif M.IsCiv(oldOwner) or M.IsCiv(newOwner) then
  -- Gifts/captures/conversions cannot clone objective state, identity or kit rights.
  if M.IsCiv(oldOwner) and old then local s=M.State(oldOwner);local n=M.Serial(old);if n then s.units[n]=nil;M.Save(s) end end
  if M.IsCiv(newOwner) then local s=M.State(newOwner);local n=M.Serial(new);if n then s.units[n]=nil end end
  new:SetScriptData((new:GetScriptData() or ''):gsub('|MCPSID:%d+:%d+|',''):gsub('|MCPTRANSFER|','')..'|MCPTRANSFER|')
  for _,key in ipairs({'VETERAN','FLAG','GRACE','FINAL','MEMORY','KANGAROO','STOMPER','ENDERMAGE','THOR','VIPER'}) do M.Promo(new,key,false) end
 end
 if old then local poison=M.Block(old:GetScriptData(),'MCPPOISON1')
  if poison then
   if oldOwner==newOwner and isUpgrade then poison.owner=newOwner;poison.born=new:GetGameTurnCreated();new:SetScriptData(M.Put(new:GetScriptData(),'MCPPOISON1',poison));M.Promo(new,'POISON',true);M.poisonOwners[newOwner]=true
   else new:SetScriptData(M.Put(new:GetScriptData(),'MCPPOISON1',nil));M.Promo(new,'POISON',false) end
  end
 end
end)
H(GameEvents,'UnitPrekill',function(pid,id,typ,x,y,delay,killer)
 local p=Players[pid];local u=p and p:GetUnitByID(id)
 if u and u:IsCombatUnit() and M.IsCiv(killer) then
  local s=M.State(killer);local key=pid..':'..id..':'..u:GetGameTurnCreated()
  s.killLedger=s.killLedger or {}
  if not s.killLedger[key] then s.killLedger[key]=true;M.KillReward(s,{pid=pid,typ=typ,temporary=false},Map.GetPlot(x,y));M.Save(s) end
 end
 if not M.IsCiv(pid) or not u then return end
 local s=M.State(pid);local r=M.Peek(s,u)
 if r then
  if r.flag then M.Notify(r.flag.owner,'The McPvP carrier was eliminated. Your flag is recovered.',nil,Map.GetPlot(x,y));M.Notify(pid,'Flag lost: the carrier was eliminated.') end
  if r.mission then M.Notify(pid,'Infiltration interrupted: the infiltrator was eliminated.') end
  s.units[r.serial]=nil;M.Save(s)
 end
end)
H(GameEvents,'UnitSetXY',function(pid,id,x,y)
 local u=Players[pid] and Players[pid]:GetUnitByID(id);if not M.Alive(u) then return end
 local relevant=M.IsCiv(pid)
 if not relevant then for _,s in pairs(M.states) do local f=s.feast
  if f and f.status~='CLAIMED' and f.status~='EXPIRED' and M.FeastPlot(s)==u:GetPlot() then relevant=true;break end
 end end
 if not relevant then return end
 local born=u:GetGameTurnCreated()
 if M.IsCiv(pid) then local s=M.State(pid);local r=M.Peek(s,u)
  if r and r.mission then local city=M.City(r.mission.target)
   if not city or M.Distance(u,city)>2 or not M.Land(u) then r.mission=nil;M.Notify(pid,'Infiltration interrupted: the unit left its operational area.');M.Save(s) end
  end
  if r and r.flag and not M.Land(u) then r.flag=nil;M.Notify(pid,'Flag lost: carrier embarked or left land.');M.Save(s) end
 end
 M.After('move:'..pid..':'..id,function()
  local v=Players[pid]:GetUnitByID(id)
  if not M.Alive(v) or v:GetGameTurnCreated()~=born then return end
  if M.IsCiv(pid) then local s=M.State(pid);local r=M.Peek(s,v);if r then M.Apply(s,v,r);M.Changed(s) end end
  local order={};for owner in pairs(M.states) do order[#order+1]=owner end;table.sort(order)
  for _,owner in ipairs(order) do local s=M.states[owner]
   if s.mode=='HG' and s.feast and M.FeastPlot(s)==v:GetPlot() then M.UpdateFeast(s);M.ClaimFeast(s,v) end
  end
 end)
end)
local combat,sequence=nil,0
H(GameEvents,'CombatResult',function(ap,ai,damage,finalA,maxA,dp,di,retaliation,finalD,maxD)
 combat=nil
 if not M.IsCiv(ap) or damage<=0 or finalD>=maxD then return end
 local a=Players[ap]:GetUnitByID(ai);local d=Players[dp] and Players[dp]:GetUnitByID(di)
 local r=a and M.Peek(M.State(ap),a)
 if r and r.kit=='VIPER' and not r.flag and M.Military(d) and M.AtWar(ap,dp) then combat={source=ap,owner=dp,id=di,born=d:GetGameTurnCreated()} end
end)
H(GameEvents,'CombatEnded',function()
 local hit=combat;combat=nil;if not hit then return end
 sequence=sequence+1
 M.After('poison:'..sequence,function() local u=Players[hit.owner]:GetUnitByID(hit.id)
  if M.Alive(u) and u:GetGameTurnCreated()==hit.born then M.Poison(u,hit.source) end
 end)
end)
H(GameEvents,'PlayerDoTurn',function(pid)
 local p=Players[pid];if not p or not p:IsAlive() then return end
 M.PoisonTurn(pid)
 for _,s in pairs(M.states) do if s.mode=='HG' then M.UpdateFeast(s) end end
 if M.lastDebuffTurn~=M.Turn() then M.lastDebuffTurn=M.Turn();M.Debuffs() end
 if not M.IsCiv(pid) then return end
 local s=M.State(pid)
 if not s.mode then if not p:IsHuman() then s.queued=M.AIMode(s) end;M.StartMatch(s) end
 if M.Turn()>=s.finish then M.EndMatch(s) end
 M.Reconcile(s)
 if s.lastTurn~=M.Turn() then s.lastTurn=M.Turn();M.Save(s);M.UpdateMissions(s);M.AITurn(s) end
 M.Changed(s)
end)
H(GameEvents,'TeamSetEra',function(team)
 for pid,s in pairs(M.states) do if Players[pid]:GetTeam()==team then M.Remember(s);M.After('era:'..pid,function() M.Reconcile(s);M.Changed(s) end) end end
end)
H(GameEvents,'CityCaptureComplete',function() M.After('cities',function() M.Debuffs();for _,s in pairs(M.states) do M.Reconcile(s);M.UpdateMissions(s);M.Changed(s) end end) end)
function M.Bootstrap()
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[pid]
  if p then for u in p:Units() do
   if u:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_POISON) then M.poisonOwners[pid]=true end
  end end
 end
 for pid,s in pairs(M.states) do if Players[pid]:IsAlive() then
  if not s.mode then if not Players[pid]:IsHuman() then s.queued=M.AIMode(s) end;M.StartMatch(s) end
  M.Reconcile(s);M.Changed(s)
 end end
 M.Debuffs()
end
H(Events,'LoadScreenClose',function() M.After('bootstrap',M.Bootstrap) end)
M.After('bootstrap',M.Bootstrap)
