local R=MapModData.RED_Legend
function R.RescueAce(s,r)
 if r.ace then s.rescuedAces=s.rescuedAces or {};s.rescuedAces[r.ace.token]=r.ace;r.ace=nil end
end
function R.RecoverAces(s)
 local p=Players[s.pid];local home=p:GetCapitalCity()
 if not p:IsAlive() or not home then return end
 local keys={};for token in pairs(s.rescuedAces or {}) do keys[#keys+1]=token end;table.sort(keys)
 for _,token in ipairs(keys) do
  local plot=R.SpawnPlot(s.pid,R.ACE,home:GetX(),home:GetY())
  if plot then
   R.internal=R.internal+1;local ace=p:InitUnit(R.ACE,plot:GetX(),plot:GetY())
   if ace then R.Restore(ace,s.rescuedAces[token]);s.rescuedAces[token]=nil end
   R.internal=R.internal-1;R.Save(s)
  end
 end
end
function R.CanAttach(s,u)
 local r=R.Peek(u);if not r or r.ace or u:IsBusy() or not R.Alive(u) then return end
 local best
 for ace in Players[s.pid]:Units() do
  if ace:GetUnitType()==R.ACE and not ace:IsBusy() and R.Distance(ace,u)<=1 and ace:MovesLeft()>0 and (not best or ace:GetID()<best:GetID()) then best=ace end
 end
 return best
end
function R.Attach(s,u)
 local ace=R.CanAttach(s,u);if not ace then return false end
 local r=R.Record(u);r.ace=R.Snapshot(ace);r.ace.token=s.nextSerial;s.nextSerial=s.nextSerial+1
 R.Save(s);R.internal=R.internal+1;ace:Kill(false,-1);R.internal=R.internal-1
 R.Apply(u,r);R.Changed(s);return true
end
function R.Detach(s,u)
 local r=R.Record(u)
 if not r or not r.ace or u:IsBusy() or u:GetPlot():GetOwner()~=s.pid then return false end
 local plot=R.SpawnPlot(s.pid,R.ACE,u:GetX(),u:GetY());if not plot then return false end
 R.internal=R.internal+1
 local ace=Players[s.pid]:InitUnit(R.ACE,plot:GetX(),plot:GetY())
 if ace then R.Restore(ace,r.ace);r.ace=nil end
 R.internal=R.internal-1
 R.Apply(u,r);R.Yields(s);R.Changed(s);return ace~=nil
end
function R.CanItem(s,u)
 local r=R.Peek(u)
 return r and r.ace and not u:IsBusy() and not R.Attacked(u) and Game.GetGameTurn()>=(r.itemReady or 0)
end
function R.Item(s,u)
 if not R.CanItem(s,u) then return false end
 local r=R.Record(u);r.itemReady=Game.GetGameTurn()+R.Turns(8)
 R.Save(s) -- commit the cooldown before effects or reentrant UI events
 R.Heal(u,25);R.Set(u,'BLOOM_STATUS',false)
 u:SetMoves(u:MaxMoves());R.Apply(u,r);R.Changed(s);return true
end
-- Query-scoped CityCanAirlift enables only this explicit action, without Airport.
-- Airlift=0 prevents an unlimited native action from bypassing the allowance.
function R.CheckAirlift(s,u,city)
 if not u or not city or u:GetOwner()~=s.pid or u:GetDomainType()~=DomainTypes.DOMAIN_LAND or u:IsEmbarked() or u:IsBusy() or R.Attacked(u) or u:MovesLeft()<u:MaxMoves() then return false end
 local from=u:GetPlot():GetPlotCity()
 if not from or from:GetOwner()~=s.pid or from:GetNumBuilding(R.CENTER)==0 or from:GetID()==city:GetID() or s.airlifts[from:GetID()]==Game.GetGameTurn() then return false end
 if city:GetOwner()~=s.pid or (city:GetNumBuilding(R.CENTER)==0 and city:GetNumBuilding(GameInfoTypes.BUILDING_AIRPORT)==0) then return false end
 R.airliftQuery={pid=s.pid,from=from:GetID(),to=city:GetID()}
 local ok=u:CanAirliftAt(u:GetPlot(),city:GetX(),city:GetY())
 R.airliftQuery=nil;return ok
end
function R.Airlift(s,u,city)
 if not R.CheckAirlift(s,u,city) then return false end
 local from=u:GetPlot():GetPlotCity();local x,y=u:GetX(),u:GetY()
 R.airliftQuery={pid=s.pid,from=from:GetID(),to=city:GetID()}
 u:PushMission(MissionTypes.MISSION_AIRLIFT,city:GetX(),city:GetY(),0,0,1)
 R.airliftQuery=nil
 if u:GetX()==x and u:GetY()==y then return false end
 s.airlifts[from:GetID()]=Game.GetGameTurn();R.Changed(s);return true
end
