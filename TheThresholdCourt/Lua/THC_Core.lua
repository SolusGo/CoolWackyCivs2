-- One simulation owner: included only by THC_Transfer.xml's UI Lua context.
local previous=MapModData.ThresholdCourt
if previous and previous.active and previous.context==ContextPtr then return end
if previous then
 previous.active=false
 if previous.context and previous.context.ClearUpdate then previous.context:ClearUpdate() end
 for _,h in ipairs(previous.handlers or {}) do if h.event.Remove then h.event.Remove(h.fn) end end
end
local T={active=true,context=ContextPtr,handlers={},warnings={},busy={}}
MapModData.ThresholdCourt=T
T.CIV=GameInfoTypes.CIVILIZATION_THRESHOLD_COURT
T.HOUSE=GameInfoTypes.BUILDING_THRESHOLD_HOUSE
T.EXHAUSTED=GameInfoTypes.PROMOTION_THRESHOLD_EXHAUSTED
function T.Turn() return Game.GetGameTurn() end
function T.Text(key,...) return Locale.ConvertTextKey('TXT_KEY_THC_'..key,...) end
function T.Civ(pid)
 local p=Players[pid]
 return p and p:IsAlive() and p:IsHuman() and p:GetCivilizationType()==T.CIV
end
function T.Alive(u)
 if not u then return false end
 local ok,alive=pcall(function() return not u:IsDead() and not u:IsDelayedDeath() end)
 return ok and alive
end
include('THC_State')
function T.Hook(bus,name,fn,veto)
 local event=bus and bus[name];if not event then return end
 local wrapped=function(...)
  if not T.active then return true end
  local ok,result=pcall(fn,...)
  if not ok then T.Warn('event '..name,result);return veto and false or nil end
  return result
 end
 event.Add(wrapped);T.handlers[#T.handlers+1]={event=event,fn=wrapped}
end
function T.Cost(pid) return 50+25*Players[pid]:GetCurrentEra() end
function T.Eligible(u)
 if not T.Alive(u) or u:GetDomainType()~=DomainTypes.DOMAIN_LAND or not u:IsCombatUnit()
  or u:IsRanged() or u:IsEmbarked() or not u:IsCanAttackWithMove() or u:IsOnlyDefensive() then return false end
 local row=GameInfo.Units[u:GetUnitType()]
 -- Native combat/attack classification is authoritative. CombatClass excludes
 -- special noncombat types; IsRanged/IsCanAttackWithMove excludes siege/archers.
 return row and row.CombatClass and row.CombatClass~='UNITCOMBAT_SIEGE'
  and row.CombatClass~='UNITCOMBAT_ARCHER' and row.CombatClass~='UNITCOMBAT_HELICOPTER'
  and (row.RangedCombat or 0)==0 and (row.SendCanMoveIntoEvent==1 or row.SendCanMoveIntoEvent==true)
end
function T.Origin(pid,u)
 local plot=u:GetPlot();local c=plot and plot:GetPlotCity()
 if not c or c:GetOwner()~=pid or c:GetNumBuilding(T.HOUSE)<1
  or u:GetX()~=c:GetX() or u:GetY()~=c:GetY() then return end
 return c
end
function T.Destination(pid,u,origin,c)
 if not c or c:GetOwner()~=pid or not c:Plot() then return false,T.Text('INVALID_DEST') end
 if c:GetX()==origin:GetX() and c:GetY()==origin:GetY() then return false,T.Text('SAME_CITY') end
 if c:GetNumBuilding(T.HOUSE)<1 then return false,T.Text('NO_HOUSE') end
 local plot=c:Plot()
 for i=0,plot:GetNumUnits()-1 do
  local other=plot:GetUnit(i)
  if other and other:IsCombatUnit() then return false,T.Text('OCCUPIED') end
  if other and other:GetOwner()~=pid and Teams[Players[pid]:GetTeam()]:IsAtWar(Players[other:GetOwner()]:GetTeam()) then
   return false,T.Text('ENGINE_REJECT')
  end
 end
 -- Verified CP binding: argument 3 is unused; argument 4 is an INTEGER
 -- destination flag. This is endpoint legality only, with no pathfinding.
 if not u:CanMoveOrAttackInto(plot,0,1) then return false,T.Text('ENGINE_REJECT') end
 return true,T.Text('AVAILABLE')
end
-- Shared validator. UI convenience is never trusted by execution.
function T.Validate(pid,uid,snapshot,dest)
 if not T.active or not T.Civ(pid) or Game.GetActivePlayer()~=pid or not Players[pid]:IsTurnActive() then return false,T.Text('NOT_TURN') end
 if T.busy[pid] then return false,T.Text('BUSY') end
 local u=Players[pid]:GetUnitByID(uid)
 if not T.Alive(u) or u:GetOwner()~=pid then return false,T.Text('INVALID_UNIT') end
 if T.Locked(u) then return false,T.Text('EXHAUSTION') end
 if not T.Eligible(u) then return false,T.Text('INELIGIBLE') end
 local origin=T.Origin(pid,u)
 if not origin then return false,T.Text('ORIGIN') end
 local cityState=T.CityState(origin);local s=T.State(pid)
 if not cityState or not s or s[3]~=0 then return false,T.Text('PERSISTENCE') end
 if snapshot and (snapshot.unit~=T.UnitToken(u) or snapshot.origin~=T.CityToken(origin)) then return false,T.Text('CHANGED') end
 if s[1]==T.Turn()+1 then return false,T.Text('USED') end
 if cityState[6]>T.Turn() then return false,T.Text('COOLDOWN',cityState[6]-T.Turn()) end
 if u:MovesLeft()<=0 or u:IsBusy() then return false,T.Text('NO_MOVES') end
 local cost=T.Cost(pid)
 if Players[pid]:GetGold()<cost then return false,T.Text('GOLD',cost) end
 local context={unit=u,origin=origin,city=cityState,state=s,cost=cost}
 if dest then
  if snapshot and snapshot.destination and snapshot.destination~=T.CityToken(dest) then return false,T.Text('CHANGED') end
  local ok,reason=T.Destination(pid,u,origin,dest)
  if not ok then return false,reason end
  context.destination=dest
 else
  local found=false
  for c in Players[pid]:Cities() do if T.Destination(pid,u,origin,c) then found=true;break end end
  if not found then return false,T.Text('NO_DEST') end
 end
 return true,T.Text('AVAILABLE'),context
end
local function Restrict(u,pid,turn)
 assert(T.Write(u,'THC_U1',{pid,turn,u:GetGameTurnCreated(),u:GetUnitType()}),'exhaustion persistence')
 u:SetHasPromotion(T.EXHAUSTED,true)
 assert(u:IsHasPromotion(T.EXHAUSTED),'native attack restriction failed')
 u:FinishMoves()
 assert(u:MovesLeft()==0,'native movement restriction failed')
end
local function CityAt(x,y)
 local plot=Map.GetPlot(x,y);return plot and plot:GetPlotCity()
end
-- Receipt phases make partial native/script failures recoverable. A receipt is
-- written before relocation, but payment/cooldown/use follow confirmed arrival.
function T.Recover(pid)
 local s=T.State(pid);if not s or s[3]==0 then return s~=nil end
 local p=Players[pid];local u=p:GetUnitByID(s[4])
 if not T.Alive(u) or u:GetGameTurnCreated()~=s[5] or u:GetUnitType()~=s[14] then
  T.Warn('receipt','unit identity unavailable; preserving receipt and disabling transfers');return false
 end
 local atOrigin=u:GetX()==s[6] and u:GetY()==s[7]
 local arrived=u:GetX()==s[8] and u:GetY()==s[9] and not u:IsEmbarked()
 if s[3]==1 and atOrigin then
  assert(T.Write(u,'THC_U1',nil));u:SetHasPromotion(T.EXHAUSTED,false);u:SetMoves(s[15])
  return T.ClearReceipt(pid,s)
 end
 if not arrived then T.Warn('receipt','unexpected position; no speculative charge');return false end
 Restrict(u,pid,s[11]);u:SetMadeAttack(true)
 local origin=CityAt(s[6],s[7]);local cs=origin and T.CityState(origin)
 -- Never apply an obsolete cooldown to a replacement/captured city.
 if origin and origin:GetOwner()==pid and cs and cs[1]==s[10] then
  cs[6]=s[11]+8;assert(T.Write(origin:Plot(),'THC_C1',cs),'origin cooldown persistence')
 end
 s[1]=s[11]+1
 if s[3]==1 then
  s[3]=2;s[13]=p:GetGold();assert(T.Save(pid,s),'confirmed receipt persistence')
 end
 -- The receipt stores treasury immediately before charging. A successful
 -- charge followed by a failed final write cannot charge a second time.
 local gold=p:GetGold()
 if gold==s[13] then p:ChangeGold(-s[12])
 elseif gold~=s[13]-s[12] then T.Warn('receipt','ambiguous treasury; preserving receipt');return false end
 assert(p:GetGold()==s[13]-s[12],'Gold charge failed')
 return T.ClearReceipt(pid,s)
end
function T.Transfer(pid,uid,snapshot,dx,dy)
 if type(dx)~='number' or type(dy)~='number' or dx~=math.floor(dx) or dy~=math.floor(dy) then
  return false,T.Text('INVALID_DEST')
 end
 local destination=CityAt(dx,dy)
 local valid,reason,ctx=T.Validate(pid,uid,snapshot,destination)
 if not destination then valid=false;reason=T.Text('INVALID_DEST') end
 if not valid then T.Log('transfer rejected',reason);return false,reason end
 local expectedUnit=T.UnitToken(ctx.unit)
 local expectedOrigin=T.CityToken(ctx.origin)
 local expectedDestination=T.CityToken(destination)
 local unitName,originName,destinationName=ctx.unit:GetName(),ctx.origin:GetName(),destination:GetName()
 T.busy[pid]=true
 local moved=false
 local ok,err=pcall(function()
  local u,o,s=ctx.unit,ctx.origin,ctx.state
  s[3]=1;s[4]=uid;s[5]=u:GetGameTurnCreated();s[6]=o:GetX();s[7]=o:GetY()
  s[8]=dx;s[9]=dy;s[10]=ctx.city[1];s[11]=T.Turn();s[12]=ctx.cost
  s[13]=Players[pid]:GetGold();s[14]=u:GetUnitType();s[15]=u:MovesLeft();s[16]=ctx.city[6]
  assert(T.Save(pid,s),'prepared receipt persistence')
  local currentOrigin=T.Origin(pid,u)
  local currentDestination=CityAt(dx,dy)
  assert(currentOrigin and T.CityToken(currentOrigin)==expectedOrigin,'origin changed before relocation')
  assert(currentDestination and T.CityToken(currentDestination)==expectedDestination,'destination changed before relocation')
  assert(T.Destination(pid,u,currentOrigin,currentDestination),'destination changed before relocation')
  Restrict(u,pid,T.Turn())
  -- luaL_optint requires numeric flags, not Lua booleans.
  -- SetXY preserves identity, damage, XP, promotions and upgrade history.
  u:SetXY(dx,dy,0,1,1,0)
  local current=Players[pid]:GetUnitByID(uid)
  moved=T.Alive(current) and current:GetGameTurnCreated()==s[5] and current:GetUnitType()==s[14]
   and current:GetX()==dx and current:GetY()==dy and not current:IsEmbarked()
  assert(moved,'unit did not arrive on the destination city tile')
  assert(T.Recover(pid),'arrival finalization pending')
 end)
 T.busy[pid]=nil
 if not ok then
  T.Log('relocation/restriction error',err)
  local recovered,result=pcall(T.Recover,pid)
  if not recovered then T.Warn('recovery',result) end
  local current=Players[pid]:GetUnitByID(uid)
  moved=T.Alive(current) and T.UnitToken(current)==expectedUnit and current:GetX()==dx and current:GetY()==dy and not current:IsEmbarked()
  if not moved then return false,T.Text('FAILED') end
  if not recovered or not result then return false,T.Text('PERSISTENCE') end
 end
 local text=T.Text('SUCCESS',unitName,originName,destinationName,ctx.cost,T.Turn()+8)
 T.Log('transfer successful',text)
 local notified,noticeError=pcall(function() Players[pid]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,text,T.Text('TRANSFER'),dx,dy) end)
 if not notified then T.Warn('notification',noticeError) end
 if T.Refresh then T.Refresh() end
 return true,text
end
include('THC_Events')
