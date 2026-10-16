-- One simulation owner, loaded by MCP_ServerBrowser.xml. UI rendering is read-only.
MapModData.MCPVP={states={},pending={},poisonOwners={},internal=0}
local M=MapModData.MCPVP
M.CIV=GameInfoTypes.CIVILIZATION_MCPVP
M.HUB=GameInfoTypes.BUILDING_MCPVP_HUB
M.VETERAN=GameInfoTypes.UNIT_MCPVP_VETERAN
-- BNW names the Information Era ERA_FUTURE (CP INFORMATION_ERA define).
M.INFORMATION=GameInfoTypes.ERA_FUTURE
M.speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
M.kits={'KANGAROO','STOMPER','ENDERMAGE','THOR','VIPER'}
M.modes={'HG','CTF','SAB'}
function M.Turn() return Game.GetGameTurn() end
function M.Turns(n) return math.max(1,math.floor(n*(M.speed.TrainPercent or 100)/100+0.5)) end
function M.Reward(pid,n,kind)
 local percent=M.speed[kind=='CULTURE' and 'CulturePercent' or 'GoldPercent'] or 100
 return math.floor(n*percent/100*(1+math.max(0,Players[pid]:GetCurrentEra())*0.25)+0.5)
end
function M.IsCiv(pid) local p=Players[pid];return p and p:GetCivilizationType()==M.CIV end
function M.Alive(u) return u and not u:IsDead() and not u:IsDelayedDeath() end
function M.Military(u) return M.Alive(u) and u:IsCombatUnit() end
function M.Land(u) return M.Military(u) and u:GetDomainType()==DomainTypes.DOMAIN_LAND and not u:IsEmbarked() end
function M.AtWar(a,b) return Players[a] and Players[b] and a~=b and Teams[Players[a]:GetTeam()]:IsAtWar(Players[b]:GetTeam()) end
function M.Distance(a,b) return Map.PlotDistance(a:GetX(),a:GetY(),b:GetX(),b:GetY()) end
function M.Text(key,...) return Locale.ConvertTextKey('TXT_KEY_MCPVP_'..key,...) end
function M.Promo(u,key,on)
 local id=GameInfoTypes['PROMOTION_MCPVP_'..key]
 if id and u:IsHasPromotion(id)~=on then u:SetHasPromotion(id,on) end
end
function M.Notify(pid,message,title,plot)
 local p=Players[pid]
 if p and p:IsHuman() then p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,message,title or M.Text('BROWSER'),plot and plot:GetX() or -1,plot and plot:GetY() or -1) end
end
function M.Hook(events,name,fn) if events[name] and events[name].Add then events[name].Add(fn) end end
include('MCP_SaveData')
function M.Changed(s) M.Save(s);if LuaEvents.MCPVP_Changed then LuaEvents.MCPVP_Changed(s.pid) end end
function M.Apply(s,u,r)
 local onLand=u:GetDomainType()==DomainTypes.DOMAIN_LAND and not u:IsEmbarked()
 for _,kit in ipairs(M.kits) do M.Promo(u,kit,r.kit==kit and onLand) end
 M.Promo(u,'VETERAN',r.veteran==true)
 M.Promo(u,'FLAG',r.flag~=nil)
 if r.flag then
  -- OnlyDefensive blocks melee, but CP's ranged eligibility ignores that field.
  -- Consume available attacks while retaining movement; never restore them mid-turn.
  for _=1,64 do if u:IsOutOfAttacks() then break end;u:SetMadeAttack(true) end
 end
 M.Promo(u,'MEMORY',s.remembered==true and M.Military(u))
 M.Promo(u,'GRACE',s.mode=='HG' and M.Turn()<s.start+M.Turns(3))
 M.Promo(u,'FINAL',s.mode=='HG' and M.Turn()>=s.start+M.Turns(10) and M.Turn()<s.finish)
end
function M.Yields(s)
 local p=Players[s.pid];local cap=p:GetCapitalCity()
 local amount=math.min(8,math.floor(s.lifetime/25))+(s.remembered and math.min(10,math.floor(s.lifetime/50)) or 0)
 for city in p:Cities() do
  local n=cap and city:GetID()==cap:GetID() and amount or 0
  for bit=0,4 do local id=GameInfoTypes['BUILDING_MCPVP_LEGACY_'..bit];local value=math.floor(n/2^bit)%2
   if city:GetNumRealBuilding(id)~=value then city:SetNumRealBuilding(id,value,true) end
  end
 end
end
function M.Legacy(s,n)
 if n<=0 then return end
 s.current=s.current+n;s.lifetime=s.lifetime+n;s.earned=(s.earned or 0)+n
 M.Yields(s);M.Save(s)
end
function M.Remember(s)
 if not s.remembered and Players[s.pid]:GetCurrentEra()>=M.INFORMATION then
  s.remembered=true;M.Save(s)
  M.Notify(s.pid,M.Text('REMEMBRANCE'),M.Text('THANKS'))
 end
 M.Yields(s)
end
function M.Reconcile(s)
 local seen={}
 for u in Players[s.pid]:Units() do if M.Military(u) then
  local r=M.Record(s,u);seen[r.serial]=true
  if r.flag and (not M.Land(u) or not M.FlagCity(r.flag) or not M.AtWar(s.pid,r.flag.owner) or s.mode~='CTF') then M.DropFlag(s,r,u,'Flag lost: carrier or target is no longer eligible.') end
  M.Apply(s,u,r)
 end end
 for serial,r in pairs(s.units) do if not seen[serial] then s.units[serial]=nil end end
 M.Remember(s);M.Save(s)
end
include('MCP_Matches')
include('MCP_Kits')
include('MCP_AI')
include('MCP_Events')
