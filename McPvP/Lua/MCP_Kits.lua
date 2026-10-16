local M=MapModData.MCPVP
function M.CanKit(s,u,kit)
 local r=M.Peek(s,u);local known=false
 for _,k in ipairs(M.kits) do if k==kit then known=true end end
 if not known or not r or not M.Land(u) or not (r.eligible or r.veteran) then return false,'Requires a Veteran or a land military unit trained in a Server Hub.' end
 if r.flag or r.mission then return false,'Finish the current flag or infiltration objective first.' end
 if r.kit==kit then return false,'This kit is already selected.' end
 if u:MovesLeft()<=0 then return false,'Requires movement remaining.' end
 if r.kit then
  local city=u:GetPlot():GetPlotCity()
  if not r.veteran or not city or city:GetOwner()~=s.pid then return false,'Only Veterans can retrain, inside a friendly city.' end
  if M.Turn()<r.changeReady then return false,'Kit change ready in '..(r.changeReady-M.Turn())..' turns.' end
 end
 return true,'Ready. Select '..M.Text(kit)..'.'
end
function M.SelectKit(s,u,kit)
 if not M.CanKit(s,u,kit) then return false end
 local r=M.Peek(s,u);local changed=r.kit~=nil
 r.kit=kit;r.changeReady=M.Turn()+M.Turns(15)
 -- Preserve an outstanding cooldown across kit swaps. The new kit also recharges.
 if changed then r.ready=math.max(r.ready or 0,M.Turn()+M.Turns(kit=='ENDERMAGE' and 7 or 5)) end
 M.Apply(s,u,r);u:SetMoves(0);M.Changed(s);return true
end
function M.VisibleEnemy(pid,u)
 return M.Military(u) and M.AtWar(pid,u:GetOwner()) and u:GetPlot():IsVisible(Players[pid]:GetTeam()) and not u:IsInvisible(Players[pid]:GetTeam(),false)
end
function M.PullPlot(u,target)
 for dir=0,5 do local plot=Map.PlotDirection(u:GetX(),u:GetY(),dir)
  if plot and plot~=target:GetPlot() and M.ValidFeast(plot) and plot:GetNumUnits()==0 and plot:IsVisible(Players[u:GetOwner()]:GetTeam()) and target:CanMoveOrAttackInto(plot,0,1) then return plot end
 end
end
function M.AbilityTargets(s,u)
 local out={};local r=M.Peek(s,u)
 if not r or not M.Land(u) or r.flag or r.mission or u:MovesLeft()<=0 or M.Turn()<(r.ready or 0) then return out end
 local kit=r.kit;if kit~='STOMPER' and kit~='THOR' and kit~='ENDERMAGE' then return out end
 if kit=='STOMPER' and not u:GetPlot():IsHills() then return out end
 local range=kit=='STOMPER' and 1 or 2
 -- Bounded radius, not a map-wide unit scan.
 for dx=-range,range do for dy=-range,range do local plot=Map.GetPlot(u:GetX()+dx,u:GetY()+dy)
  if plot and M.Distance(u,plot)<=range and not plot:IsCity() and plot:IsVisible(Players[s.pid]:GetTeam()) then
   for i=0,plot:GetNumUnits()-1 do local v=plot:GetUnit(i)
    if M.VisibleEnemy(s.pid,v) and (kit=='THOR' or (M.Land(v) and (kit~='STOMPER' or not plot:IsHills()))) then
     if kit~='ENDERMAGE' or M.PullPlot(u,v) then out[#out+1]={owner=v:GetOwner(),id=v:GetID(),born=v:GetGameTurnCreated(),key=v:GetOwner()..':'..v:GetID()..':'..v:GetGameTurnCreated(),x=v:GetX(),y=v:GetY()} end
    end
   end
  end
 end end
 table.sort(out,function(a,b) return a.key<b.key end);return out
end
function M.AbilityReason(s,u)
 local r=M.Peek(s,u)
 if not r or not r.kit then return 'Select a kit first.' end
 if not M.Land(u) then return 'Requires an unembarked land military unit.' end
 if r.flag or r.mission then return 'Unavailable while carrying a flag or infiltrating.' end
 if M.Turn()<(r.ready or 0) then return 'Cooldown: '..(r.ready-M.Turn())..' turns.' end
 if u:MovesLeft()<=0 then return 'Requires movement remaining.' end
 if r.kit=='KANGAROO' or r.kit=='VIPER' then return 'Passive kit: '..M.Text(r.kit..'_HELP') end
 if r.kit=='STOMPER' and not u:GetPlot():IsHills() then return 'Stomper must stand on a hill.' end
 if #M.AbilityTargets(s,u)==0 then return 'No valid visible enemy targets in range; Endermage also needs a legal empty landing tile.' end
 return 'Ready. Cycle targets, then use the kit ability.'
end
function M.Ability(s,u,target)
 for _,ref in ipairs(M.AbilityTargets(s,u)) do if target and target.key==ref.key then
  local r=M.Peek(s,u);local v=Players[ref.owner]:GetUnitByID(ref.id);if not M.Alive(v) then return false end
  local dest=r.kit=='ENDERMAGE' and M.PullPlot(u,v)
  if r.kit=='ENDERMAGE' and not dest then return false end
  r.ready=M.Turn()+M.Turns(r.kit=='ENDERMAGE' and 7 or 5);u:SetMoves(0);M.Save(s)
  if dest then
   -- Native legality checked with the VICTIM, no occupied plots/cities or captures.
   M.internal=M.internal+1
   local ok,err=pcall(function() v:SetXY(dest:GetX(),dest:GetY(),0,1,1) end)
   M.internal=M.internal-1
   if not ok then print('[McPvP] Endermage relocation failed: '..tostring(err));M.Notify(s.pid,'Relocation failed safely; ability remains on cooldown.') end
  else v:ChangeDamage(r.kit=='STOMPER' and 20 or 15,s.pid) end
  M.Changed(s);return true
 end end
 return false
end
function M.Poison(v,source)
 if not M.Military(v) then return end
 local poison={owner=v:GetOwner(),born=v:GetGameTurnCreated(),source=source,applied=M.Turn(),left=2,last=-1}
 local previous=M.Block(v:GetScriptData(),'MCPPOISON1')
 if previous then poison.last=previous.last end
 v:SetScriptData(M.Put(v:GetScriptData(),'MCPPOISON1',poison));M.Promo(v,'POISON',true);M.poisonOwners[v:GetOwner()]=true
end
function M.PoisonTurn(pid)
 if not M.poisonOwners[pid] then return end
 local affected={};for u in Players[pid]:Units() do if u:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_POISON) then affected[#affected+1]=u end end
 M.poisonOwners[pid]=false
 for _,u in ipairs(affected) do local poison=M.Block(u:GetScriptData(),'MCPPOISON1')
  if poison and poison.owner==pid and poison.born==u:GetGameTurnCreated() and M.Military(u) then
   if poison.last~=M.Turn() then
    poison.last=M.Turn();poison.left=poison.left-1
    u:SetScriptData(M.Put(u:GetScriptData(),'MCPPOISON1',poison.left>0 and poison or nil))
    M.Promo(u,'POISON',poison.left>0);u:ChangeDamage(5,poison.source)
   end
   if poison.left>0 and M.Alive(u) then M.poisonOwners[pid]=true end
  else u:SetScriptData(M.Put(u:GetScriptData(),'MCPPOISON1',nil));M.Promo(u,'POISON',false) end
 end
end
