-- Military alternatives never relax NoCapture or destroy a protected city.
local B=MapModData.BoundlessCity
local otherNoCapture={}
for promotion in GameInfo.UnitPromotions() do
 if (promotion.NoCapture==1 or promotion.NoCapture==true) and promotion.ID~=B.ID('PROMOTION_BC_NO_CAPTURE') then
  otherNoCapture[#otherNoCapture+1]=promotion.ID
 end
end
function B.OriginalIdentity(s,city)
 local c=s.capital
 return c and city and city:GetX()==c.x and city:GetY()==c.y
  and city:GetGameTurnFounded()==c.founded and city:GetOriginalOwner()==s.pid
  and city:IsOriginalCapital()
end
local function capitalIdentity(city)
 local original=Players[city:GetOriginalOwner()]
 if not original or original:IsMinorCiv() or original:IsBarbarian() or not city:IsOriginalCapital() then return false end
 local plot=original:GetOriginalCapitalPlot()
 return plot and plot:GetX()==city:GetX() and plot:GetY()==city:GetY()
end
local function recorded(s,city)
 local r=s.subjugated[Map.GetPlot(city:GetX(),city:GetY()):GetPlotIndex()]
 return r and r.founded==city:GetGameTurnFounded() and r.original==city:GetOriginalOwner()
  and r.civ==Players[r.original]:GetCivilizationType()
end
local function force(s,plot,melees,reclaim)
 local units=melees or {}
 if not melees then for unit in Players[s.pid]:Units() do units[#units+1]=unit end end
 for _,unit in ipairs(units) do
  local domain=unit:GetDomainType()
  local cannotReclaim=false
  if reclaim then for _,id in ipairs(otherNoCapture) do if unit:IsHasPromotion(id) then cannotReclaim=true;break end end end
  if unit:IsCombatUnit() and not unit:IsRanged() and not unit:IsEmbarked() and not unit:IsBusy()
   and not cannotReclaim
   and not unit:IsDead() and not unit:IsDelayedDeath() and not unit:IsOnlyDefensive() and not unit:IsOutOfAttacks()
   and unit:MovesLeft()>0 and Map.PlotDistance(unit:GetX(),unit:GetY(),plot:GetX(),plot:GetY())==1
   and (domain==DomainTypes.DOMAIN_LAND or (domain==DomainTypes.DOMAIN_SEA and plot:IsCoastalLand())) then return unit end
 end
end
function B.MilitaryCheck(s,n,melees,requested)
 local player=Players[s.pid]
 if s.incompatible or not B.IsBoundless(s.pid) or not player:IsAlive() or not player:IsTurnActive() then return false,nil,'SIEGE_INACTIVE' end
 local plot=type(n)=='number' and Map.GetPlotByIndex(n);local city=plot and plot:GetPlotCity()
 if not city or city:GetOwner()==s.pid then return false,nil,'SIEGE_INVALID' end
 if not plot:IsVisible(player:GetTeam(),false) then return false,nil,'SIEGE_NOT_VISIBLE' end
 local reclaim=B.OriginalIdentity(s,city) and player:GetNumCities()==0
 if not reclaim and not B.City(s) then return false,nil,'SIEGE_INACTIVE' end
 local owner=Players[city:GetOwner()];local original=Players[city:GetOriginalOwner()]
 if not owner or not original or city:IsRazing() then return false,nil,'SIEGE_PROTECTED' end
 if not reclaim and (owner:IsBarbarian() or original:IsBarbarian()) then return false,nil,'SIEGE_INVALID' end
 if not reclaim and (owner:IsMinorCiv() or original:IsMinorCiv()) then return false,nil,'SIEGE_CITY_STATE' end
 if not Teams[player:GetTeam()]:IsAtWar(owner:GetTeam()) then return false,nil,'SIEGE_NOT_AT_WAR' end
 if city:GetDamage()<city:GetMaxHitPoints()-1 then return false,nil,'SIEGE_DAMAGE' end
 local unit=force(s,plot,melees,reclaim);if not unit then return false,nil,'SIEGE_MELEE' end
 local action,reason='SUBJUGATE','SIEGE_SUBJUGATE'
 if reclaim then action,reason='RECLAIM','SIEGE_RECLAIM'
 elseif B.NativeRazable(city) then action,reason='DEMOLISH','SIEGE_READY'
 elseif recorded(s,city) then return false,nil,'SIEGE_SUBJUGATED'
 elseif city:IsOriginalCapital() then reason='SIEGE_SUBJUGATE_CAPITAL'
 elseif city:IsHolyCityAnyReligion() then reason='SIEGE_SUBJUGATE_HOLY'
 end
 if requested and requested~=action then return false,nil,'SIEGE_NATIVE_RULE' end
 return true,{x=city:GetX(),y=city:GetY(),owner=city:GetOwner(),original=city:GetOriginalOwner(),
  founded=city:GetGameTurnFounded(),city=city:GetID(),unit=unit:GetID(),birth=unit:GetGameTurnCreated(),action=action},reason
end
function B.ResolveMilitary(s,current)
 local plot=Map.GetPlot(current.x,current.y);local city=plot:GetPlotCity()
 local unit=Players[s.pid]:GetUnitByID(current.unit)
 unit:FinishMoves()
 if current.action=='RECLAIM' then
  -- Native conquest rebuilds the city and invokes capture hooks. Zero cities
  -- and immutable original identity were checked immediately before this call.
  -- Never retain/dereference either city object across acquireCity.
  Players[s.pid]:AcquireCity(city,true,false)
  local oldCache=B.Cache(s)
  for n in pairs(oldCache.watchKeys or {}) do if B.Watch[n] then B.Watch[n][s.pid]=nil end end
  B.Caches[s.pid]=nil;B.Cache(s).force=true;B.Initialize(s.pid)
  B.Notify(s,'RECLAIMED')
 else
  local n=plot:GetPlotIndex()
  s.subjugated[n]={x=current.x,y=current.y,founded=current.founded,original=current.original,
   civ=Players[current.original]:GetCivilizationType(),capital=capitalIdentity(city) and true or false,turn=B.Now()}
  B.Save(s);B.Notify(s,'SUBJUGATED');B.CheckDomination(s)
 end
end
function B.DominationProgress(s)
 local done,total=0,0;local valid=true;local team=Players[s.pid]:GetTeam()
 for pid=0,(GameDefines.MAX_MAJOR_CIVS or 22)-1 do local p=Players[pid]
  if p and pid~=s.pid and p:IsEverAlive() and not p:IsMinorCiv() and not p:IsBarbarian() and p:GetTeam()~=team then
   total=total+1
   local plot=p:GetOriginalCapitalPlot();local city=plot and plot:GetPlotCity()
   -- Missing/replaced originals block victory; elimination never erases a rival.
   local r=plot and s.subjugated[plot:GetPlotIndex()]
   if city and capitalIdentity(city) and city:GetOriginalOwner()==pid and r and r.capital
    and r.original==pid and r.civ==p:GetCivilizationType() and r.founded==city:GetGameTurnFounded() then done=done+1
   else valid=false end
  end
 end
 return done,total,valid and total>0
end
function B.CheckDomination(s)
 if s.incompatible or not B.Config.SubjugationDomination or not B.IsBoundless(s.pid)
  or not Players[s.pid]:IsAlive() or not B.City(s) or Players[s.pid]:GetNumCities()~=1
  or Game.GetWinner()~=-1 or Game.GetVictory()~=-1 then return false end
 local victory=B.ID('VICTORY_DOMINATION')
 if not victory or not Game.IsVictoryValid(victory) then return false end
 local done,total,valid=B.DominationProgress(s)
 if not valid or done~=total then return false end
 -- Native winner setter performs notifications, replay and game-state changes.
 -- No victory-valid flags, foreign ownership or normal victory hooks are changed.
 Game.SetWinner(Players[s.pid]:GetTeam(),victory);return true
end
function B.DevelopRemotePlots(s)
 local city=B.City(s)
 if s.incompatible or not city or s.phase~='IDLE' or s.developmentTurn==B.Now() then return end
 -- Reserve this turn before any native mutation; reload cannot advance twice.
 s.developmentTurn=B.Now();B.Save(s)
 local locals=B.LocalPlots(city);local changed={}
 local ok,err=pcall(function()
 for _,n in ipairs(B.Keys(s.assignments)) do local plot=Map.GetPlotByIndex(n)
  if B.Eligible(s,plot) and not plot:IsBeingWorked() and not locals[n] then
   local row=GameInfo.Improvements[plot:GetImprovementType()]
   local upgrade=row and row.ImprovementUpgrade and GameInfo.Improvements[row.ImprovementUpgrade]
   if upgrade then
    local rate=Players[s.pid]:GetImprovementUpgradeRate()
    local progress=plot:GetUpgradeProgress()+rate
    plot:ChangeUpgradeProgress(rate)
    if progress>=Game.GetImprovementUpgradeTime(row.ID,plot)*100 then
     plot:SetImprovementType(upgrade.ID,plot:GetPlayerThatBuiltImprovement())
     changed[n]=true
    end
   end
  end
 end
 end)
 if next(changed) then B.Trim(s,changed);B.Schedule(s.pid,true) end
 if not ok then print('[BoundlessCity] Remote development stopped this turn: '..tostring(err)) end
 return ok
end
