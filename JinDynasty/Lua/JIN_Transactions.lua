-- Additive save-local receipts make interrupted recruitment and partial Bribes recoverable.
local J=MapModData.JIN
local S,C=J.S,J.C
J.liveTransactions={}
local function unitAt(owner,uid,born)
 local u=Players[owner] and Players[owner]:GetUnitByID(uid or -1)
 return J.Alive(u) and u:GetGameTurnCreated()==born and u or nil
end
local function pay(id,s,total)
 local tx=s.transaction;local p=Players[id]
 if tx.intent then
  local gold=p:GetGold();local delta=tx.intent.delta
  if gold==tx.intent.gold then p:ChangeGold(-delta)
  elseif gold~=tx.intent.gold-delta then error('ambiguous transaction Treasury; receipt retained') end
  tx.paid=tx.intent.total;tx.intent=nil;J.Save(id,s)
 end
 local delta=total-(tx.paid or 0)
 if delta~=0 then
  tx.intent={gold=p:GetGold(),delta=delta,total=total};J.Save(id,s)
  p:ChangeGold(-delta);tx.paid=total;tx.intent=nil;J.Save(id,s)
 end
end
function J.NoteCreated(owner,uid)
 for id,s in pairs(J.liveTransactions) do local tx=s.transaction
  if tx then
   local u=Players[owner] and Players[owner]:GetUnitByID(uid)
   if J.Alive(u) and tx.kind=='recruit' and owner==id and not tx.unit and not tx.before[uid] and u:GetUnitType()==tx.unitType and J.Index(u:GetPlot())==tx.plot then
    tx.unit=uid;tx.born=u:GetGameTurnCreated();S.Write(u,'JIN_RECEIPT1',{owner=id,token=tx.token});u:FinishMoves();J.Save(id,s)
   elseif J.Alive(u) and tx.kind=='bribe' and owner==GameDefines.BARBARIAN_PLAYER and tx.current then
    local r=tx.targets[tx.current]
    if r and not r.clone and u:GetUnitType()==r.base and J.Index(u:GetPlot())==r.spawn then r.clone=uid;r.cloneBorn=u:GetGameTurnCreated();S.Write(u,'JIN_RECEIPT1',{owner=id,token=tx.token,slot=tx.current});u:FinishMoves();J.Save(id,s) end
   end
  end
 end
end
local function findCreated(id,tx,owner,uid,born,typ,plot,before,slot)
 local u=unitAt(owner,uid,born);if uid~=nil then return u and u:GetUnitType()==typ and u or nil end
 for candidate in Players[owner]:Units() do
  if candidate:GetUnitType()==typ and candidate:GetGameTurnCreated()==tx.turn then
   local marker=S.Read(candidate,'JIN_RECEIPT1')
   if marker and marker.owner==id and marker.token==tx.token and marker.slot==slot then return candidate end
   if plot and J.Index(candidate:GetPlot())==plot and not (before or {})[candidate:GetID()] then return candidate end
  end
 end
end
local function discard(u)
 if J.Alive(u) then J.removing[u:GetOwner()..':'..u:GetID()]=true;u:Kill(false,-1);J.removing[u:GetOwner()..':'..u:GetID()]=nil end
end
function J.RecoverTransaction(id,s)
 local tx=s.transaction;if not tx then return true end
 if tx.kind=='recruit' then
  local u=findCreated(id,tx,id,tx.unit,tx.born,tx.unitType,tx.plot,tx.before,nil)
  local g=s.grass[tx.source]
  if not u then
   if tx.horse and g and g.plot==tx.sourcePlot then g.horses=math.min(C.horseCapacity,g.horses+1) end
   pay(id,s,0);s.transaction=nil;J.Save(id,s);return false
  end
  if not tx.horse then
   if not g or g.plot~=tx.sourcePlot or g.horses<=0 or not J.GrassActive(id,tx.source,g) then discard(u);pay(id,s,0);s.transaction=nil;J.Save(id,s);return false end
   g.horses=g.horses-1;tx.horse=true;J.Save(id,s)
  end
  pay(id,s,tx.cost);u:FinishMoves();s.transaction=nil;J.Save(id,s);S.Write(u,'JIN_RECEIPT1',nil);J.SyncUnit(id,u,s,true);J.Units(id,s);return true
 elseif tx.kind=='bribe' then
  local total=0
  for i,r in ipairs(tx.targets) do
   local clone=findCreated(id,tx,GameDefines.BARBARIAN_PLAYER,r.clone,r.cloneBorn,r.base,r.spawn,r.before,i)
   local original=unitAt(r.owner,r.uid,r.born)
   if r.converted or (clone and not original) then
    r.converted=true;total=total+r.cost
    if clone then s.rebels[clone:GetID()]={born=clone:GetGameTurnCreated(),expires=r.expires};S.Write(clone,'JIN_RECEIPT1',nil) end
   elseif clone then discard(clone) end
  end
  pay(id,s,total)
  if total>0 then s.emissaryCooldown[tx.emissary]={born=tx.emissaryBorn,ready=tx.ready} end
  s.transaction=nil;J.Save(id,s);return total>0
 end
 error('unknown Jin transaction receipt; record preserved')
end
function J.Recruit(id,s,cityID,typ)
 local legal,why,source,cost=J.RecruitCheck(id,s,cityID,typ);if not legal then return false,why end
 local p=Players[id];local city=p:GetCityByID(cityID);local originalRaw=p:GetScriptData();local originalGold=p:GetGold()
 local before={};for u in p:Units() do before[u:GetID()]=true end
 s.serial=s.serial+1
 s.transaction={kind='recruit',token=s.serial,turn=J.Now(),unitType=typ,plot=J.Index(city:Plot()),source=source,sourcePlot=s.grass[source].plot,cost=cost,paid=0,before=before}
 local created
 J.liveTransactions[id]=s
 local ok,result=pcall(function()
  J.Save(id,s)
  created=p:InitUnit(typ,city:GetX(),city:GetY())
  if not J.Alive(created) or J.Index(created:GetPlot())~=J.Index(city:Plot()) then discard(created);s.transaction=nil;J.Save(id,s);return false end
  s.transaction.unit=created:GetID();s.transaction.born=created:GetGameTurnCreated();J.Save(id,s)
  return J.RecoverTransaction(id,s)
 end)
 J.liveTransactions[id]=nil
 if not ok then
  -- Recruitment has no hostile casualty to undo: restore the pre-action ledger and remove its unit.
  discard(created or findCreated(id,s.transaction or {},id,s.transaction and s.transaction.unit,s.transaction and s.transaction.born,typ,J.Index(city:Plot()),before,nil))
  local restored,err=pcall(function()
   if p:GetGold()~=originalGold then p:ChangeGold(originalGold-p:GetGold()) end
   p:SetScriptData(originalRaw);assert(p:GetScriptData()==originalRaw,'recruit rollback write failed');S.ResetCache()
  end)
  if not restored then print('JIN recruitment rollback: '..tostring(err)..'; receipt preserved for recovery') end
  return false,'Recruitment could not commit; no reinforcement retained. '..tostring(result)
 end
 return result,result and why or 'Native deployment failed; no Horse or Gold spent.'
end
function J.Bribe(id,s,uid,plotIndex)
 local legal,why,targets=J.BribeCheck(id,s,uid,plotIndex);if not legal then return false,why end
 local emissary=J.Emissary(id,uid);s.serial=s.serial+1
 local tx={kind='bribe',token=s.serial,turn=J.Now(),emissary=uid,emissaryBorn=emissary:GetGameTurnCreated(),ready=J.Now()+J.Scale(C.bribeCooldown),paid=0,targets=targets}
 s.transaction=tx;J.Save(id,s);J.liveTransactions[id]=s
 local ok,err=pcall(function()
  for i,r in ipairs(targets) do
   local original=unitAt(r.owner,r.uid,r.born);local p=J.SpawnPlot(GameDefines.BARBARIAN_PLAYER,J.Plot(r.plot),2)
   if original and J.BribeTarget(id,original) and p and J.War(GameDefines.BARBARIAN_PLAYER,r.owner) and J.War(GameDefines.BARBARIAN_PLAYER,id) then
    tx.current=i;r.spawn=J.Index(p);r.expires=J.Now()+J.Scale(C.rebelLifetime);r.before={};J.Save(id,s)
    local clone=Players[GameDefines.BARBARIAN_PLAYER]:InitUnit(r.base,p:GetX(),p:GetY())
    if J.Alive(clone) and J.Index(clone:GetPlot())==r.spawn then
     r.clone=clone:GetID();r.cloneBorn=clone:GetGameTurnCreated();clone:FinishMoves()
     local ratio=math.max(1,original:GetMaxHitPoints()-original:GetDamage())/original:GetMaxHitPoints()
     clone:SetDamage(math.min(clone:GetMaxHitPoints()-1,math.floor(clone:GetMaxHitPoints()*(1-ratio))));J.Save(id,s)
     if J.War(id,r.owner) and J.War(GameDefines.BARBARIAN_PLAYER,id) and J.War(GameDefines.BARBARIAN_PLAYER,r.owner) then
      original:Kill(false,GameDefines.BARBARIAN_PLAYER);r.converted=true
      s.rebels[clone:GetID()]={born=r.cloneBorn,expires=r.expires};J.Save(id,s)
      local total=0;for _,v in ipairs(targets) do if v.converted then total=total+v.cost end end
      pay(id,s,total)
     else discard(clone) end
    else discard(clone) end
   end
  end
 end)
 J.liveTransactions[id]=nil
 -- A partial success remains real and paid; unconverted duplicate clones are rolled back.
 local recovered,result=pcall(J.RecoverTransaction,id,s)
 if not recovered then print('JIN Bribe receipt pending: '..tostring(result));return false,'Bribe recovery pending; saved receipt blocks further purchases.' end
 if not ok then print('JIN Bribe partial failure: '..tostring(err)) end
 if J.Alive(emissary) and result then emissary:FinishMoves() end
 return result,result and 'Bribe settled for successful conversions only; rebels remain hostile to both sides.' or 'No replacements converted; no Gold or cooldown spent.'
end
